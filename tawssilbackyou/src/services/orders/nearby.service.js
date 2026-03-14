import { Op, literal } from "sequelize";
import Order from "../../models/Order.js";
import Restaurant from "../../models/Restaurant.js";
import Client from "../../models/Client.js";
import Driver from "../../models/Driver.js";
import OrderItem from "../../models/OrderItem.js";
import OrderItemAddition from "../../models/OrderItemAddition.js";
import Addition from "../../models/Addition.js";
import MenuItem from "../../models/MenuItem.js";
import SystemConfig from "../../models/SystemConfig.js";
import calculateRouteTime from "../routingService.js";
import { hydrateOrderItemsWithActivePromotions } from "./orderEnrichment.helper.js";

export const getNearbyOrders = async (driverId, filters = {}) => {
  const { radius, status = ["preparing", "accepted"], page = 1, pageSize = 20, min_fee, max_distance } = filters;

  const driver = await Driver.findByPk(driverId);
  if (!driver) throw { status: 404, message: "Driver not found" };
  if (!driver.is_verified) throw { status: 400, message: "Driver account is not verified" };

  const configuredRadius = await SystemConfig.get('driver_nearby_search_radius', 5000);
  const rawRadius = radius ?? configuredRadius;
  const parsedRadius = Number.parseInt(String(rawRadius), 10);
  const searchRadius = Number.isFinite(parsedRadius) ? parsedRadius : 5000;

  if (!driver.canAcceptMoreOrders()) {
    return {
      orders: [],
      pagination: { current_page: parseInt(page, 10), total_pages: 0, total_items: 0, items_in_page: 0 },
      driver_location: driver.getCurrentCoordinates(),
      search_radius_km: (searchRadius / 1000).toFixed(2),
      message: `You have reached maximum capacity (${driver.active_orders.length}/${driver.max_orders_capacity} orders)`
    };
  }

  if (!driver.current_location) throw { status: 400, message: "Driver location not available. Please enable GPS." };

  const coords = driver.getCurrentCoordinates();
  if (!coords) throw { status: 400, message: "Invalid driver location" };

  const { longitude, latitude } = coords;
  const routeMode = "direct";
  const shouldLogRoutes = process.env.LOG_NEARBY_ROUTES === "true";

  const whereConditions = {
    [Op.and]: [
      { order_type: "delivery" },
      { livreur_id: null },
      literal(`ST_DWithin((SELECT location FROM restaurants WHERE id = "Order"."restaurant_id"), ST_GeogFromText('POINT(${longitude} ${latitude})'), ${searchRadius})`)
    ]
  };

  if (status) {
    const statusArray = Array.isArray(status) ? status : [status];
    whereConditions[Op.and].push({ status: { [Op.in]: statusArray } });
  }

  if (min_fee) {
    whereConditions[Op.and].push({ delivery_fee: { [Op.gte]: parseFloat(min_fee) } });
  }

  const limit = parseInt(pageSize, 10);
  const offset = (parseInt(page, 10) - 1) * limit;

  const { count, rows } = await Order.findAndCountAll({
    distinct: true,
    attributes: {
      include: [
        [literal(`ST_Distance((SELECT location FROM restaurants WHERE id = "Order"."restaurant_id"), ST_GeogFromText('POINT(${longitude} ${latitude})'))`), "distance"]
      ]
    },
    where: whereConditions,
    include: [
      {
        model: OrderItem,
        as: "order_items",
        include: [
          { model: MenuItem, as: "menu_item" },
          {
            model: OrderItemAddition,
            as: "additions",
            include: [{ model: Addition, as: "addition" }],
          },
        ],
      },
      { model: Restaurant, as: "restaurant", attributes: ["id", "name", "address", "location", "image_url", "email"] },
      { model: Client, as: "client", attributes: ["id", "first_name", "last_name", "phone_number"] },
    ],
    order: [[literal("distance"), "ASC"], ["created_at", "DESC"]],
    limit,
    offset
  });

  await hydrateOrderItemsWithActivePromotions(rows);

  // ✅ CALCULER LES ROUTES POUR CHAQUE COMMANDE
  const formatted = await Promise.all(rows.map(async (order) => {
    const restaurantCoords = order.restaurant.location?.coordinates || [];
    const deliveryCoords = order.delivery_location?.coordinates || [];
    const distanceDriverToRestaurant = parseFloat(order.dataValues.distance);

    // Filtrer par distance maximale si spécifiée
    if (max_distance && distanceDriverToRestaurant > max_distance) return null;

    // ✅ 1. Calculer route Driver → Restaurant
    let driverToRestaurant = null;
    if (restaurantCoords.length === 2) {
      try {
        const route = await calculateRouteTime(
          longitude, // Driver longitude
          latitude,  // Driver latitude
          restaurantCoords[0], // Restaurant longitude
          restaurantCoords[1], // Restaurant latitude
          40, // Vitesse moyenne: 40 km/h
          { mode: routeMode }
        );

        driverToRestaurant = {
          distance_km: parseFloat(route.distanceKm.toFixed(2)),
          distance_meters: Math.round(route.distanceKm * 1000),
          estimated_time_min: route.timeMax
        };

        if (shouldLogRoutes) {
          console.log(`Route Driver→Restaurant (Order ${order.order_number}): ${route.distanceKm.toFixed(2)} km, ~${route.timeMax} min`);
        }
      } catch (error) {
        console.error(`⚠️ Route calculation failed (Driver→Restaurant) for order ${order.id}:`, error.message);
      }
    }

    // ✅ 2. Calculer route Restaurant → Delivery
    let restaurantToDelivery = null;
    if (restaurantCoords.length === 2 && deliveryCoords.length === 2) {
      try {
        const route = await calculateRouteTime(
          restaurantCoords[0], // Restaurant longitude
          restaurantCoords[1], // Restaurant latitude
          deliveryCoords[0],   // Delivery longitude
          deliveryCoords[1],   // Delivery latitude
          40, // Vitesse moyenne: 40 km/h
          { mode: routeMode }
        );

        restaurantToDelivery = {
          distance_km: parseFloat(route.distanceKm.toFixed(2)),
          distance_meters: Math.round(route.distanceKm * 1000),
          estimated_time_min: route.timeMax
        };

        if (shouldLogRoutes) {
          console.log(`Route Restaurant→Delivery (Order ${order.order_number}): ${route.distanceKm.toFixed(2)} km, ~${route.timeMax} min`);
        }
      } catch (error) {
        console.error(`⚠️ Route calculation failed (Restaurant→Delivery) for order ${order.id}:`, error.message);
      }
    }

    // ✅ Format uniforme compatible avec getOrderById
    return {
      // Tous les champs de l'ordre
      id: order.id,
      order_number: order.order_number,
      client_id: order.client_id,
      restaurant_id: order.restaurant_id,
      order_type: order.order_type,
      status: order.status,
      livreur_id: order.livreur_id,
      
      // Montants
      subtotal: parseFloat(order.subtotal || 0),
      delivery_fee: parseFloat(order.delivery_fee || 0),
      total_amount: parseFloat(order.total_amount || 0),
      delivery_distance: order.delivery_distance ? parseFloat(order.delivery_distance) : null,
      
      // Adresses et localisation
      delivery_address: order.delivery_address,
      delivery_location: deliveryCoords.length === 2 ? {
        type: 'Point',
        coordinates: deliveryCoords,
        lat: deliveryCoords[1],
        lng: deliveryCoords[0]
      } : null,
      
      delivery_instructions: order.delivery_instructions,
      payment_method: order.payment_method,
      preparation_time: order.preparation_time,
      
      // Timestamps
      estimated_delivery_time: order.estimated_delivery_time,
      created_at: order.created_at,
      updated_at: order.updated_at,
      accepted_at: order.accepted_at,
      preparing_started_at: order.preparing_started_at,
      assigned_at: order.assigned_at,
      delivering_started_at: order.delivering_started_at,
      delivered_at: order.delivered_at,
      
      // Rating
      rating: order.rating ? parseFloat(order.rating) : null,
      restaurant_review_comment: order.restaurant_review_comment,
      driver_review_comment: order.driver_review_comment,
      review_comment: order.restaurant_review_comment ?? order.driver_review_comment ?? null,
      decline_reason: order.decline_reason,
      
      // Relations complètes (comme getOrderById)
      restaurant: {
        id: order.restaurant.id,
        name: order.restaurant.name,
        address: order.restaurant.address,
        image_url: order.restaurant.image_url,
        email: order.restaurant.email || null,
        location: restaurantCoords.length === 2 ? {
          type: 'Point',
          coordinates: restaurantCoords,
          lat: restaurantCoords[1],
          lng: restaurantCoords[0]
        } : null
      },

      client: {
        id: order.client.id,
        first_name: order.client.first_name,
        last_name: order.client.last_name,
        phone_number: order.client.phone_number,
        full_name: `${order.client.first_name} ${order.client.last_name}`
      },

      // Order items complets
      order_items: order.order_items.map(item => ({
        id: item.id,
        order_id: item.order_id,
        menu_item_id: item.menu_item_id,
        quantite: item.quantite,
        prix_unitaire: parseFloat(item.prix_unitaire),
        prix_total: parseFloat(item.prix_total),
        instructions_speciales: item.instructions_speciales,
        created_at: item.created_at,
        updated_at: item.updated_at,
        additions: (item.additions || []).map((add) => ({
          id: add.id,
          order_item_id: add.order_item_id,
          addition_id: add.addition_id,
          quantite: add.quantite,
          prix_unitaire: parseFloat(add.prix_unitaire),
          prix_total: parseFloat(add.prix_total),
          addition: add.addition
            ? {
                id: add.addition.id,
                nom: add.addition.nom,
                description: add.addition.description,
                prix: parseFloat(add.addition.prix),
                is_available: add.addition.is_available,
                menu_item_id: add.addition.menu_item_id
              }
            : null
        })),
        menu_item: item.menu_item ? {
          id: item.menu_item.id,
          nom: item.menu_item.nom,
          description: item.menu_item.description,
          prix: parseFloat(item.menu_item.prix),
          photo_url: item.menu_item.photo_url,
          temps_preparation: item.menu_item.temps_preparation,
          is_available: item.menu_item.is_available,
          category_id: item.menu_item.category_id,
          primary_promotions: item.menu_item.primary_promotions || [],
          promotions: item.menu_item.promotions || []
        } : null
      })),

      // ✅ Informations spécifiques aux nearby orders (route calculée)
      route_details: {
        driver_to_restaurant: driverToRestaurant || {
          distance_km: null,
          distance_meters: null,
          estimated_time_min: null
        },
        
        restaurant_to_delivery: restaurantToDelivery || {
          distance_km: null,
          distance_meters: null,
          estimated_time_min: null
        }
      }
    };
  }));

  // Filtrer les null (commandes au-delà de max_distance)
  const validOrders = formatted.filter(Boolean);

  return {
    orders: validOrders,
    pagination: {
      current_page: parseInt(page, 10),
      total_pages: Math.ceil(count / limit),
      total_items: count,
      items_in_page: validOrders.length
    },
    driver_location: { lat: latitude, lng: longitude },
    search_radius_km: (searchRadius / 1000).toFixed(2)
  };
};
