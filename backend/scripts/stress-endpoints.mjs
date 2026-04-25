import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { performance } from "node:perf_hooks";
import request from "supertest";

process.env.NODE_ENV = "test";
process.env.RATE_LIMIT_MAX = process.env.RATE_LIMIT_MAX || "100000";
process.env.AUTH_RATE_LIMIT_MAX = process.env.AUTH_RATE_LIMIT_MAX || "100000";
process.env.OTP_RATE_LIMIT_MAX = process.env.OTP_RATE_LIMIT_MAX || "100000";
process.env.ROUTING_MODE = process.env.ROUTING_MODE || "direct";

const nativeSetTimeout = global.setTimeout;
const nativeClearTimeout = global.clearTimeout;
const ignoredTimeouts = new Set();

global.setTimeout = (callback, delay = 0, ...args) => {
  const numericDelay = Number(delay) || 0;

  // Ignore long business timers so the stress runner can shut down cleanly.
  if (numericDelay >= 30_000) {
    const fakeTimer = {
      hasRef: () => false,
      ref: () => fakeTimer,
      unref: () => fakeTimer
    };
    ignoredTimeouts.add(fakeTimer);
    return fakeTimer;
  }

  return nativeSetTimeout(callback, numericDelay, ...args);
};

global.clearTimeout = (timer) => {
  if (ignoredTimeouts.has(timer)) {
    ignoredTimeouts.delete(timer);
    return;
  }

  return nativeClearTimeout(timer);
};

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const backendDir = path.resolve(__dirname, "..");
const uploadsDir = path.join(backendDir, "public", "uploads");
const resultsDir = path.join(backendDir, "stress-results");

const percentile = (values, p) => {
  if (!values.length) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const index = Math.min(sorted.length - 1, Math.max(0, Math.ceil((p / 100) * sorted.length) - 1));
  return sorted[index];
};

const round = (value, digits = 2) => Number.parseFloat(Number(value).toFixed(digits));

const buildPoint = (lng, lat) => ({ type: "Point", coordinates: [lng, lat] });

const safeListFiles = async (dir) => {
  try {
    return await fs.readdir(dir);
  } catch {
    return [];
  }
};

const nowIso = () => new Date().toISOString();

const startServer = async (server) => {
  if (server.listening) {
    const address = server.address();
    return `http://127.0.0.1:${address.port}`;
  }

  await new Promise((resolve, reject) => {
    const onError = (error) => {
      server.off("error", onError);
      reject(error);
    };

    server.on("error", onError);
    server.listen(0, "127.0.0.1", () => {
      server.off("error", onError);
      resolve();
    });
  });

  const address = server.address();
  return `http://127.0.0.1:${address.port}`;
};

const stopServer = async (server) => {
  if (!server.listening) {
    return;
  }

  await new Promise((resolve) => {
    server.close(() => resolve());
  });
};

const main = async () => {
  const [
    { sequelize },
    { default: server },
    { default: User },
    { default: Client },
    { default: Restaurant },
    { default: Cashier },
    { default: Driver },
    { default: Admin },
    { default: FoodCategory },
    { default: MenuItem },
    { default: Order },
    { default: OrderItem },
    { default: Announcement }
  ] = await Promise.all([
    import("../src/config/database.js"),
    import("../src/app.js"),
    import("../src/models/User.js"),
    import("../src/models/Client.js"),
    import("../src/models/Restaurant.js"),
    import("../src/models/Cashier.js"),
    import("../src/models/Driver.js"),
    import("../src/models/Admin.js"),
    import("../src/models/FoodCategory.js"),
    import("../src/models/MenuItem.js"),
    import("../src/models/Order.js"),
    import("../src/models/OrderItem.js"),
    import("../src/models/Announcement.js")
  ]);

  await fs.mkdir(resultsDir, { recursive: true });
  await fs.mkdir(uploadsDir, { recursive: true });

  const uploadsBefore = new Set(await safeListFiles(uploadsDir));
  const baseUrl = await startServer(server);
  const api = request(baseUrl);

  const cleanupUploads = async () => {
    const uploadsAfter = await safeListFiles(uploadsDir);
    const created = uploadsAfter.filter((name) => !uploadsBefore.has(name));
    await Promise.all(
      created.map((name) =>
        fs.rm(path.join(uploadsDir, name), { force: true }).catch(() => {})
      )
    );
    return created.length;
  };

  const createUser = async ({ email, password, role, emailVerified = true }) =>
    User.create({
      email,
      password,
      role,
      ...(emailVerified ? { email_verified_at: new Date() } : {})
    });

  const createOrderWithItems = async ({
    clientId,
    restaurantId,
    menuItems,
    status,
    orderType = "delivery",
    driverId = null,
    cashierId = null,
    deliveryAddress = "Rue stress test 01",
    deliveryLocation = buildPoint(3.06, 36.76),
    paymentMethod = "cash_on_delivery"
  }) => {
    const order = await Order.create({
      client_id: clientId,
      restaurant_id: restaurantId,
      created_by_cashier_id: cashierId,
      order_type: orderType,
      delivery_address: orderType === "delivery" ? deliveryAddress : null,
      delivery_location: orderType === "delivery" ? deliveryLocation : null,
      status,
      payment_method: paymentMethod,
      subtotal: 0,
      delivery_fee: orderType === "delivery" ? 150 : 0,
      total_amount: 0,
      livreur_id: driverId,
      estimated_delivery_time: new Date(Date.now() + 45 * 60 * 1000)
    });

    let subtotal = 0;
    for (const menuItem of menuItems) {
      const quantity = 1 + (subtotal % 2);
      await OrderItem.create({
        order_id: order.id,
        menu_item_id: menuItem.id,
        quantite: quantity,
        prix_unitaire: menuItem.prix
      });
      subtotal += Number.parseFloat(menuItem.prix) * quantity;
    }

    order.subtotal = subtotal;
    order.calculateTotal();
    await order.save();
    return order;
  };

  const login = async ({ email, password, type }) => {
    const response = await api.post("/auth/login").send({ email, password, type });
    if (response.status !== 200 || !response.body?.access_token) {
      throw new Error(`Login failed for ${email}: ${response.status} ${JSON.stringify(response.body)}`);
    }
    return response.body.access_token;
  };

  const authedGet = (token, url) => api.get(url).set("Authorization", `Bearer ${token}`);
  const authedPost = (token, url) => api.post(url).set("Authorization", `Bearer ${token}`);

  const runScenario = async ({
    name,
    totalRequests,
    concurrency,
    successStatuses,
    execute
  }) => {
    const latencies = [];
    const statusCounts = {};
    const samples = [];
    let index = 0;
    const startedAt = performance.now();

    const worker = async () => {
      while (true) {
        const current = index;
        index += 1;
        if (current >= totalRequests) {
          return;
        }

        const reqStartedAt = performance.now();
        try {
          const response = await execute(current);
          const elapsed = performance.now() - reqStartedAt;
          latencies.push(elapsed);

          const statusKey = String(response.status);
          statusCounts[statusKey] = (statusCounts[statusKey] || 0) + 1;

          if (!successStatuses.includes(response.status) && samples.length < 5) {
            samples.push({
              index: current,
              status: response.status,
              body: response.body
            });
          }
        } catch (error) {
          const elapsed = performance.now() - reqStartedAt;
          latencies.push(elapsed);
          statusCounts.NETWORK_ERROR = (statusCounts.NETWORK_ERROR || 0) + 1;
          if (samples.length < 5) {
            samples.push({
              index: current,
              status: "NETWORK_ERROR",
              body: error?.message || String(error)
            });
          }
        }
      }
    };

    await Promise.all(
      Array.from({ length: concurrency }, () => worker())
    );

    const durationMs = performance.now() - startedAt;
    const successCount = successStatuses.reduce(
      (sum, status) => sum + (statusCounts[String(status)] || 0),
      0
    );

    return {
      name,
      total_requests: totalRequests,
      concurrency,
      duration_ms: round(durationMs),
      requests_per_second: round((totalRequests / durationMs) * 1000),
      success_count: successCount,
      success_rate: round((successCount / totalRequests) * 100, 1),
      latency_ms: {
        min: round(Math.min(...latencies)),
        avg: round(latencies.reduce((sum, value) => sum + value, 0) / latencies.length),
        p50: round(percentile(latencies, 50)),
        p95: round(percentile(latencies, 95)),
        max: round(Math.max(...latencies))
      },
      status_counts: statusCounts,
      error_samples: samples
    };
  };

  try {
    await sequelize.sync({ force: true });

    const restaurantUser = await createUser({
      email: "stress.restaurant@example.com",
      password: "secret123",
      role: "restaurant"
    });
    const restaurant = await Restaurant.create({
      user_id: restaurantUser.id,
      name: "Stress Restaurant",
      address: "1 Stress Street",
      phone_number: "0557000001",
      email: "stress.restaurant@example.com",
      location: buildPoint(3.05, 36.75),
      status: "approved",
      is_active: true,
      availability_status: "open"
    });

    const cashierUser = await createUser({
      email: "stress.cashier@example.com",
      password: "secret123",
      role: "cashier"
    });
    const cashier = await Cashier.create({
      user_id: cashierUser.id,
      restaurant_id: restaurant.id,
      cashier_code: "CSH-9100",
      first_name: "Stress",
      last_name: "Cashier",
      phone: "0557000002",
      email: "stress.cashier@example.com"
    });

    const driverUser = await createUser({
      email: "stress.driver@example.com",
      password: "secret123",
      role: "driver"
    });
    const driver = await Driver.create({
      user_id: driverUser.id,
      driver_code: "DRV-9100",
      first_name: "Stress",
      last_name: "Driver",
      phone: "0557000003",
      email: "stress.driver@example.com",
      vehicle_type: "scooter",
      status: "available",
      is_active: true,
      is_verified: true,
      current_location: buildPoint(3.055, 36.755)
    });

    const adminUser = await createUser({
      email: "stress.admin@example.com",
      password: "secret123",
      role: "admin"
    });
    await Admin.create({
      user_id: adminUser.id,
      first_name: "Stress",
      last_name: "Admin",
      phone: "0557000004",
      email: "stress.admin@example.com"
    });

    const clientUser = await createUser({
      email: "stress.client@example.com",
      password: "secret123",
      role: "client"
    });
    const client = await Client.create({
      user_id: clientUser.id,
      first_name: "Stress",
      last_name: "Client",
      email: "stress.client@example.com",
      phone_number: "213557000005",
      address: "2 Client Street",
      location: buildPoint(3.07, 36.77),
      is_active: true
    });

    const category = await FoodCategory.create({
      restaurant_id: restaurant.id,
      nom: "Stress Category",
      description: "Stress category"
    });

    const menuItems = await Promise.all(
      Array.from({ length: 6 }, (_, idx) =>
        MenuItem.create({
          restaurant_id: restaurant.id,
          category_id: category.id,
          nom: `Stress Item ${idx + 1}`,
          description: `Stress item ${idx + 1}`,
          prix: 350 + idx * 25,
          is_available: true,
          temps_preparation: 15
        })
      )
    );

    const generalOrders = [];
    const acceptOrderIds = [];
    const driverActiveOrderIds = [];
    let trackingOrderId = null;

    for (let idx = 0; idx < 18; idx += 1) {
      const status = idx % 4 === 0 ? "pending" : idx % 4 === 1 ? "accepted" : idx % 4 === 2 ? "preparing" : "delivered";
      const order = await createOrderWithItems({
        clientId: client.id,
        restaurantId: restaurant.id,
        menuItems: menuItems.slice(0, 2),
        status,
        orderType: "delivery"
      });
      generalOrders.push(order.id);
    }

    for (let idx = 0; idx < 12; idx += 1) {
      const status = idx === 0 ? "delivering" : idx % 2 === 0 ? "assigned" : "delivering";
      const order = await createOrderWithItems({
        clientId: client.id,
        restaurantId: restaurant.id,
        menuItems: menuItems.slice(0, 3),
        status,
        orderType: "delivery",
        driverId: driver.id,
        cashierId: cashier.id,
        deliveryAddress: `Driver route ${idx + 1}`,
        deliveryLocation: buildPoint(3.06 + idx * 0.001, 36.76 + idx * 0.001)
      });
      driverActiveOrderIds.push(order.id);
      generalOrders.push(order.id);
      if (idx === 0) {
        trackingOrderId = order.id;
      }
    }

    driver.active_orders = driverActiveOrderIds;
    driver.status = "busy";
    await driver.save();

    for (let idx = 0; idx < 24; idx += 1) {
      const order = await createOrderWithItems({
        clientId: client.id,
        restaurantId: restaurant.id,
        menuItems: menuItems.slice(0, 2),
        status: "pending",
        orderType: "pickup",
        cashierId: cashier.id,
        paymentMethod: "cash_on_delivery"
      });
      acceptOrderIds.push(order.id);
      generalOrders.push(order.id);
    }

    await Promise.all(
      Array.from({ length: 12 }, (_, idx) =>
        Announcement.create({
          title: `Stress Announcement ${idx + 1}`,
          content: `Announcement ${idx + 1}`,
          type: idx % 2 === 0 ? "info" : "warning",
          is_active: true
        })
      )
    );

    const restaurantToken = await login({
      email: "stress.restaurant@example.com",
      password: "secret123",
      type: "restaurant"
    });
    const driverToken = await login({
      email: "stress.driver@example.com",
      password: "secret123",
      type: "driver"
    });
    const adminToken = await login({
      email: "stress.admin@example.com",
      password: "secret123",
      type: "admin"
    });

    const scenarios = [
      {
        name: "GET /health",
        totalRequests: 120,
        concurrency: 24,
        successStatuses: [200],
        execute: () => api.get("/health")
      },
      {
        name: "POST /auth/login (restaurant)",
        totalRequests: 60,
        concurrency: 12,
        successStatuses: [200],
        execute: () =>
          api.post("/auth/login").send({
            email: "stress.restaurant@example.com",
            password: "secret123",
            type: "restaurant"
          })
      },
      {
        name: "GET /auth/profile (restaurant)",
        totalRequests: 120,
        concurrency: 24,
        successStatuses: [200],
        execute: () => authedGet(restaurantToken, "/auth/profile")
      },
      {
        name: "GET /restaurant/details",
        totalRequests: 120,
        concurrency: 24,
        successStatuses: [200],
        execute: () => authedGet(restaurantToken, "/restaurant/details")
      },
      {
        name: "GET /order (all orders)",
        totalRequests: 100,
        concurrency: 20,
        successStatuses: [200],
        execute: () => authedGet(adminToken, "/order?limit=20&page=1")
      },
      {
        name: "GET /order/restaurant/orders",
        totalRequests: 100,
        concurrency: 20,
        successStatuses: [200],
        execute: () => authedGet(restaurantToken, "/order/restaurant/orders?limit=20&page=1")
      },
      {
        name: "GET /order/:id",
        totalRequests: 100,
        concurrency: 20,
        successStatuses: [200],
        execute: (idx) => authedGet(restaurantToken, `/order/${generalOrders[idx % generalOrders.length]}`)
      },
      {
        name: "GET /order/:id/tracking",
        totalRequests: 100,
        concurrency: 20,
        successStatuses: [200],
        execute: () => authedGet(restaurantToken, `/order/${trackingOrderId}/tracking`)
      },
      {
        name: "GET /driver/active-orders",
        totalRequests: 80,
        concurrency: 16,
        successStatuses: [200],
        execute: () => authedGet(driverToken, "/driver/active-orders")
      },
      {
        name: "GET /order/:id/route-preview",
        totalRequests: 80,
        concurrency: 16,
        successStatuses: [200],
        execute: () =>
          authedGet(
            driverToken,
            `/order/${trackingOrderId}/route-preview?driver_lng=3.055&driver_lat=36.755`
          )
      },
      {
        name: "POST /order/:id/accept (pickup unique orders)",
        totalRequests: acceptOrderIds.length,
        concurrency: 8,
        successStatuses: [200],
        execute: (idx) =>
          authedPost(restaurantToken, `/order/${acceptOrderIds[idx]}/accept`).send({
            preparation_time: 15
          })
      },
      {
        name: "GET /orderitem/getall",
        totalRequests: 120,
        concurrency: 24,
        successStatuses: [200],
        execute: () => api.get("/orderitem/getall")
      },
      {
        name: "GET /announcement/getactive",
        totalRequests: 120,
        concurrency: 24,
        successStatuses: [200],
        execute: () => api.get("/announcement/getactive")
      },
      {
        name: "POST /announcement/create",
        totalRequests: 40,
        concurrency: 10,
        successStatuses: [201],
        execute: (idx) =>
          api.post("/announcement/create").send({
            title: `Load Created ${idx}`,
            content: "stress announcement",
            type: "info",
            is_active: true
          })
      },
      {
        name: "POST /api/upload",
        totalRequests: 25,
        concurrency: 5,
        successStatuses: [200],
        execute: (idx) =>
          api
            .post("/api/upload")
            .attach("file", Buffer.from(`stress-file-${idx}`), `stress-${idx}.txt`)
      }
    ];

    const scenarioResults = [];
    for (const scenario of scenarios) {
      const result = await runScenario(scenario);
      scenarioResults.push(result);
      console.log(
        `${result.name}: ${result.success_rate}% success | avg ${result.latency_ms.avg}ms | p95 ${result.latency_ms.p95}ms | ${result.requests_per_second} req/s`
      );
    }

    const uploadsCreated = await cleanupUploads();

    const report = {
      generated_at: nowIso(),
      mode: "application-level local stress test",
      environment: {
        node_env: process.env.NODE_ENV,
        database: "sqlite-memory",
        routing_mode: process.env.ROUTING_MODE,
        rate_limits_overridden: true
      },
      dataset: {
        orders: generalOrders.length,
        driver_active_orders: driverActiveOrderIds.length,
        pickup_accept_orders: acceptOrderIds.length,
        menu_items: menuItems.length,
        announcements: await Announcement.count()
      },
      cleanup: {
        uploads_removed: uploadsCreated
      },
      results: scenarioResults
    };

    const outputPath = path.join(resultsDir, "stress-endpoints-report.json");
    await fs.writeFile(outputPath, JSON.stringify(report, null, 2), "utf8");

    console.log(`\nReport written to ${outputPath}`);
  } finally {
    await stopServer(server).catch(() => {});
    await sequelize.close().catch(() => {});
    await cleanupUploads().catch(() => {});
  }
};

main().catch((error) => {
  console.error("Stress test failed:", error);
  process.exitCode = 1;
});
