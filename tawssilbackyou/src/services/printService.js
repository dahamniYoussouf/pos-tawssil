/**
 * Service d'impression ESC/POS — réseau (TCP 9100), USB Direct, IPP, HTTP, LPD, Serial Port, mDNS, Bluetooth.
 * Toutes les méthodes supportent le backend distant.
 */

import net from "net";
import os from "os";
import http from "http";
import https from "https";
import { Op } from "sequelize";
import RestaurantPrinter from "../models/RestaurantPrinter.js";
import { emit } from "../config/socket.js";
import PrinterTemplate from "../models/PrinterTemplate.js";
import { renderTemplate, templateToEscPos } from "./templateRendererService.js";

// Import conditionnel des bibliothèques optionnelles
let usb = null;
let ipp = null;

// Charger USB de manière asynchrone si disponible
(async () => {
  try {
    const usbModule = await import("usb");
    usb = usbModule.default || usbModule;
  } catch (e) {
    console.warn("[Print] Bibliothèque USB non disponible. Installer avec: npm install usb");
  }
})();

// Charger IPP de manière asynchrone si disponible
(async () => {
  try {
    const ippModule = await import("ipp");
    ipp = ippModule.default || ippModule;
  } catch (e) {
    console.warn("[Print] Bibliothèque IPP non disponible. Installer avec: npm install ipp");
  }
})();


/** true si ip est un port série amélioré (COM:COM3:9600:8:N:1 ou SERIAL:/dev/ttyUSB0:9600:8:N:1) */
export function isSerialPort(ip) {
  if (!ip || typeof ip !== "string") return false;
  return /^(COM|SERIAL):/i.test(ip.trim());
}

/** true si ip est une imprimante Bluetooth (BT:MAC_ADDRESS) */
export function isBluetoothPrinter(ip) {
  return typeof ip === "string" && /^BT:/i.test(ip.trim());
}

/** true si ip est une imprimante mDNS/Bonjour (MDNS:name ou BONJOUR:name) */
export function isMDNSPrinter(ip) {
  return typeof ip === "string" && /^(MDNS|BONJOUR):/i.test(ip.trim());
}

/** true si ip est une imprimante USB Direct (USB:vendorId:productId) */
export function isUSBPrinter(ip) {
  return typeof ip === "string" && /^USB:/i.test(ip.trim());
}

/** true si ip est une imprimante IPP (IPP:url) */
export function isIPPPrinter(ip) {
  return typeof ip === "string" && /^IPP:/i.test(ip.trim());
}

/** true si ip est une imprimante HTTP/HTTPS (HTTP:url ou HTTPS:url) */
export function isHTTPPrinter(ip) {
  return typeof ip === "string" && /^(HTTP|HTTPS):/i.test(ip.trim());
}

/** true si ip est une imprimante LPD (LPD:ip:queue) */
export function isLPDPrinter(ip) {
  return typeof ip === "string" && /^LPD:/i.test(ip.trim());
}

// Commandes ESC/POS (séquences d'octets)
const ESC = "\x1b";
const GS = "\x1d";
const LF = "\x0a";

const cmds = {
  init: () => Buffer.from(ESC + "@", "ascii"), // Réinitialiser
  cut: (partial = 0) => Buffer.from(GS + "V" + String.fromCharCode(partial), "ascii"), // 0=full, 1=partiel
  lineFeed: (n = 1) => Buffer.from(Array(n).fill(LF).join(""), "ascii"),
  alignLeft: () => Buffer.from(ESC + "a" + "\x00", "ascii"),
  alignCenter: () => Buffer.from(ESC + "a" + "\x01", "ascii"),
  alignRight: () => Buffer.from(ESC + "a" + "\x02", "ascii"),
  boldOn: () => Buffer.from(ESC + "E" + "\x01", "ascii"),
  boldOff: () => Buffer.from(ESC + "E" + "\x00", "ascii"),
  // Ligne de séparation (souligné ou tirets)
  hr: (char = "-", width = 32) => Buffer.from(char.repeat(Math.min(width, 48)) + LF, "utf8"),
  // Ouvrir le tiroir-caisse (GS p 0 m t1 t2)
  // m=0 (pin 2), t1=0x19 (25ms), t2=0x19 (25ms)
  openDrawer: () => Buffer.from(GS + "p" + "\x00" + "\x19" + "\x19", "ascii"),
};

/**
 * Encode une chaîne en buffer. Tente UTF-8 ; fallback ISO-8859-1 pour compatibilité imprimantes.
 * Beaucoup d'imprimantes thermiques gèrent l'ISO-8859-1 (Latin1) nativement.
 */
function encodeText(str) {
  if (!str || typeof str !== "string") return Buffer.alloc(0);
  try {
    return Buffer.from(str, "utf8");
  } catch {
    return Buffer.from(str, "latin1");
  }
}

/**
 * Construit le ticket ESC/POS pour une commande.
 * @param {object} order - Commande avec order_items (menu_item, additions/addition), order_number, total_amount, etc.
 * @param {string} restaurantName - Nom du restaurant
 * @param {object} [opts] - { paperWidth: 58|80 }
 */
export function buildReceiptEscPos(order, restaurantName, opts = {}) {
  const paperWidth = opts.paperWidth || 80;
  const lineLen = Math.min(paperWidth === 58 ? 32 : 48, 48);
  const chunks = [];

  chunks.push(cmds.init());
  chunks.push(cmds.alignCenter());
  chunks.push(cmds.boldOn());
  chunks.push(encodeText((restaurantName || "RESTAURANT").toUpperCase() + LF));
  chunks.push(cmds.boldOff());
  chunks.push(cmds.lineFeed(1));

  chunks.push(cmds.alignLeft());
  chunks.push(encodeText(`Commande #${order.order_number || order.id || "-"}` + LF));
  chunks.push(encodeText(`Date: ${formatDate(order.created_at)}` + LF));
  if (order.order_type) {
    chunks.push(encodeText(`Type: ${order.order_type === "delivery" ? "Livraison" : "A emporter"}` + LF));
  }
  if (order.delivery_address) {
    chunks.push(encodeText(`Adresse: ${order.delivery_address}` + LF));
  }
  chunks.push(cmds.hr("-", lineLen));

  // Articles
  const items = order.order_items || [];
  for (const oi of items) {
    const name = oi.menu_item?.nom || oi.menu_item_name || "Article";
    const qty = oi.quantite ?? oi.quantity ?? 1;
    const total = parseFloat(oi.prix_total || oi.prix_unitaire || 0) * (typeof qty === "number" ? qty : 1);
    chunks.push(encodeText(`${name} x${qty}` + LF));
    chunks.push(encodeText(`  ${formatAmount(total)} DA` + LF));
    if (oi.instructions_speciales || oi.instructionsSpeciales) {
      chunks.push(encodeText(`  Note: ${oi.instructions_speciales || oi.instructionsSpeciales}` + LF));
    }
    const adds = oi.additions || [];
    for (const a of adds) {
      const aname = a.addition?.nom || a.nom || "Addition";
      const aq = a.quantite ?? a.quantity ?? 1;
      const atot = parseFloat(a.prix_total || a.prix_unitaire || 0) * (typeof aq === "number" ? aq : 1);
      chunks.push(encodeText(`  + ${aname} x${aq} (${formatAmount(atot)} DA)` + LF));
    }
  }

  chunks.push(cmds.hr("-", lineLen));
  chunks.push(cmds.alignLeft());
  const sub = parseFloat(order.subtotal || 0);
  if (order.order_type === "delivery" && parseFloat(order.delivery_fee || 0) > 0) {
    chunks.push(encodeText(`Sous-total: ${formatAmount(sub)} DA` + LF));
    chunks.push(encodeText(`Livraison:  ${formatAmount(parseFloat(order.delivery_fee || 0))} DA` + LF));
  }
  chunks.push(cmds.boldOn());
  chunks.push(encodeText(`TOTAL: ${formatAmount(parseFloat(order.total_amount || order.subtotal || 0))} DA` + LF));
  chunks.push(cmds.boldOff());
  chunks.push(cmds.lineFeed(1));
  chunks.push(cmds.alignCenter());
  chunks.push(encodeText("Merci de votre visite !" + LF));
  chunks.push(cmds.lineFeed(2));
  chunks.push(cmds.cut(0));

  return Buffer.concat(chunks);
}

/**
 * Construit un ticket cuisine (articles + notes, sans prix).
 * @param {object} order
 * @param {string} restaurantName
 * @param {object} [opts] - { paperWidth: 58|80 }
 */
export function buildKitchenReceiptEscPos(order, restaurantName, opts = {}) {
  const paperWidth = opts.paperWidth || 80;
  const lineLen = Math.min(paperWidth === 58 ? 32 : 48, 48);
  const chunks = [];

  chunks.push(cmds.init());
  chunks.push(cmds.alignCenter());
  chunks.push(cmds.boldOn());
  chunks.push(encodeText((restaurantName || "RESTAURANT").toUpperCase() + LF));
  chunks.push(cmds.boldOff());
  chunks.push(cmds.lineFeed(1));

  chunks.push(cmds.boldOn());
  chunks.push(encodeText("TICKET CUISINE" + LF));
  chunks.push(cmds.boldOff());
  chunks.push(cmds.lineFeed(1));

  chunks.push(cmds.alignLeft());
  chunks.push(encodeText(`Commande #${order.order_number || order.id || "-"}` + LF));
  chunks.push(encodeText(`Date: ${formatDate(order.created_at)}` + LF));
  if (order.order_type) {
    chunks.push(encodeText(`Type: ${order.order_type === "delivery" ? "Livraison" : "A emporter"}` + LF));
  }
  if (order.delivery_address) {
    chunks.push(encodeText(`Adresse: ${order.delivery_address}` + LF));
  }
  chunks.push(cmds.hr("-", lineLen));

  const items = order.order_items || [];
  for (const oi of items) {
    const name = oi.menu_item?.nom || oi.menu_item_name || "Article";
    const qty = oi.quantite ?? oi.quantity ?? 1;
    chunks.push(encodeText(`${name} x${qty}` + LF));

    if (oi.instructions_speciales || oi.instructionsSpeciales) {
      chunks.push(encodeText(`  Note: ${oi.instructions_speciales || oi.instructionsSpeciales}` + LF));
    }
    const adds = oi.additions || [];
    for (const a of adds) {
      const aname = a.addition?.nom || a.nom || "Addition";
      const aq = a.quantite ?? a.quantity ?? 1;
      chunks.push(encodeText(`  + ${aname} x${aq}` + LF));
    }
    chunks.push(cmds.lineFeed(1));
  }

  chunks.push(cmds.hr("-", lineLen));
  chunks.push(cmds.lineFeed(1));
  chunks.push(cmds.cut(0));

  return Buffer.concat(chunks);
}

/**
 * Construit un ticket général (résumé).
 * @param {object} order
 * @param {string} restaurantName
 * @param {object} [opts] - { paperWidth: 58|80 }
 */
export function buildSummaryReceiptEscPos(order, restaurantName, opts = {}) {
  const paperWidth = opts.paperWidth || 80;
  const lineLen = Math.min(paperWidth === 58 ? 32 : 48, 48);
  const chunks = [];

  const items = order.order_items || [];
  const itemCount = items.reduce((sum, oi) => {
    const qty = oi.quantite ?? oi.quantity ?? 1;
    const parsed = typeof qty === "string" ? parseInt(qty, 10) : Number(qty);
    return sum + (Number.isFinite(parsed) ? parsed : 0);
  }, 0);

  chunks.push(cmds.init());
  chunks.push(cmds.alignCenter());
  chunks.push(cmds.boldOn());
  chunks.push(encodeText((restaurantName || "RESTAURANT").toUpperCase() + LF));
  chunks.push(cmds.boldOff());
  chunks.push(cmds.lineFeed(1));

  chunks.push(cmds.boldOn());
  chunks.push(encodeText("TICKET GENERAL" + LF));
  chunks.push(cmds.boldOff());
  chunks.push(cmds.lineFeed(1));

  chunks.push(cmds.alignLeft());
  chunks.push(encodeText(`Commande #${order.order_number || order.id || "-"}` + LF));
  chunks.push(encodeText(`Date: ${formatDate(order.created_at)}` + LF));
  if (order.order_type) {
    chunks.push(encodeText(`Type: ${order.order_type === "delivery" ? "Livraison" : "A emporter"}` + LF));
  }
  chunks.push(cmds.hr("-", lineLen));

  chunks.push(encodeText(`Articles: ${itemCount}` + LF));
  chunks.push(encodeText(`TOTAL: ${formatAmount(parseFloat(order.total_amount || order.subtotal || 0))} DA` + LF));
  if (order.payment_method) {
    chunks.push(encodeText(`Paiement: ${order.payment_method}` + LF));
  }
  chunks.push(cmds.lineFeed(1));
  chunks.push(cmds.cut(0));

  return Buffer.concat(chunks);
}

function formatDate(v) {
  if (!v) return new Date().toLocaleString("fr-FR");
  const d = new Date(v);
  return isNaN(d.getTime()) ? String(v) : d.toLocaleString("fr-FR");
}

function formatAmount(n) {
  const x = Number(n);
  return Number.isFinite(x) ? x.toFixed(2) : "0.00";
}

/**
 * Construit un ticket de test ESC/POS (pour le bouton Test dans l'admin).
 * @param {string} restaurantName
 * @param {object} [opts] - { paperWidth: 58|80 }
 */
export function buildTestReceiptEscPos(restaurantName, opts = {}) {
  const paperWidth = opts.paperWidth || 80;
  const lineLen = Math.min(paperWidth === 58 ? 32 : 48, 48);
  const chunks = [];

  chunks.push(cmds.init());
  chunks.push(cmds.alignCenter());
  chunks.push(cmds.boldOn());
  chunks.push(encodeText("TEST IMPRESSION" + LF));
  chunks.push(cmds.boldOff());
  chunks.push(cmds.lineFeed(1));
  chunks.push(cmds.alignLeft());
  chunks.push(encodeText((restaurantName || "Restaurant").toUpperCase() + LF));
  chunks.push(encodeText("Date: " + formatDate(new Date()) + LF));
  chunks.push(cmds.hr("-", lineLen));
  chunks.push(encodeText("Si vous voyez ceci," + LF));
  chunks.push(encodeText("l'imprimante fonctionne." + LF));
  chunks.push(cmds.lineFeed(1));
  chunks.push(cmds.alignCenter());
  chunks.push(encodeText("--- OK ---" + LF));
  chunks.push(cmds.lineFeed(2));
  chunks.push(cmds.cut(0));

  return Buffer.concat(chunks);
}

/**
 * Envoie un ticket de test à une imprimante (bouton Test admin).
 * @param {object} printer - { ip, port, paper_width_mm, is_enabled }
 * @param {string} restaurantName
 * @returns {Promise<{ ok: boolean, printerName?: string, error?: string }>}
 */
export async function printTestOnPrinter(printer, restaurantName) {
  const ip = printer?.ip?.trim();
  if (!ip) return { ok: false, error: "IP ou configuration d'imprimante manquante", printerName: printer?.name };

  // Pour les tests, utiliser toujours le template par défaut
  const buf = buildTestReceiptEscPos(restaurantName, {
    paperWidth: Number(printer.paper_width_mm) || 80,
  });
  let result;
  if (isUSBPrinter(ip)) {
    result = await sendToUSBPrinter(ip, buf);
  } else if (isIPPPrinter(ip)) {
    result = await sendToIPPPrinter(ip, buf);
  } else if (isHTTPPrinter(ip)) {
    result = await sendToHTTPPrinter(ip, buf);
  } else if (isLPDPrinter(ip)) {
    result = await sendToLPDPrinter(ip, buf);
  } else if (isBluetoothPrinter(ip)) {
    result = await sendToBluetoothPrinter(ip, buf);
  } else if (isMDNSPrinter(ip)) {
    result = await sendToMDNSPrinter(ip, buf);
  } else if (isSerialPort(ip)) {
    result = await sendToSerialPort(ip, buf, 15000);
  } else {
    result = await sendToNetworkPrinter(ip, Number(printer.port) || 9100, buf, 15000);
  }
  return {
    ok: result.ok,
    printerName: printer.name,
    error: result.error,
  };
}

/**
 * Envoie des octets à une imprimante série améliorée (cross-platform)
 * Format: COM:COM3:9600:8:N:1 ou SERIAL:/dev/ttyUSB0:9600:8:N:1
 * @param {string} portStr - Format COM:port:baudrate:databits:parity:stopbits ou SERIAL:path:baudrate:databits:parity:stopbits
 * @param {Buffer} data
 * @param {number} timeoutMs
 * @returns {Promise<{ ok: boolean, error?: string }>}
 */
async function sendToSerialPort(portStr, data, timeoutMs = 5000) {
  try {
    // Charger serialport si pas encore chargé
    let SerialPort;
    try {
      const serialportModule = await import("serialport");
      SerialPort = serialportModule.SerialPort || serialportModule.default?.SerialPort || serialportModule.default;
      if (!SerialPort) {
        throw new Error("SerialPort not found");
      }
    } catch (e) {
      return Promise.resolve({
        ok: false,
        error: "Bibliothèque SerialPort non disponible. Installer avec: npm install serialport",
      });
    }

    // Parser la configuration: COM:COM3:9600:8:N:1 ou SERIAL:/dev/ttyUSB0:9600:8:N:1
    const parts = portStr.replace(/^(COM|SERIAL):/i, "").split(":");
    if (parts.length < 2) {
      return Promise.resolve({
        ok: false,
        error: "Format série invalide. Utilisez: COM:COM3:9600:8:N:1 ou SERIAL:/dev/ttyUSB0:9600:8:N:1",
      });
    }

    const portPath = parts[0];
    const baudRate = parseInt(parts[1]) || 9600;
    const dataBits = parseInt(parts[2]) || 8;
    const parity = parts[3]?.toUpperCase() || "N"; // N=None, E=Even, O=Odd
    const stopBits = parseInt(parts[4]) || 1;

    const parityMap = { N: "none", E: "even", O: "odd" };
    const parityValue = parityMap[parity] || "none";

    return new Promise((resolve) => {
      const port = new SerialPort({
        path: portPath,
        baudRate: baudRate,
        dataBits: dataBits,
        parity: parityValue,
        stopBits: stopBits,
        autoOpen: false,
      });

      const timeout = setTimeout(() => {
        port.close();
        resolve({ ok: false, error: "Timeout série" });
      }, timeoutMs);

      port.open((err) => {
        if (err) {
          clearTimeout(timeout);
          port.close();
          return resolve({ ok: false, error: `Erreur ouverture port série: ${err.message}` });
        }

        port.write(data, (writeErr) => {
          if (writeErr) {
            clearTimeout(timeout);
            port.close();
            return resolve({ ok: false, error: `Erreur écriture série: ${writeErr.message}` });
          }

          port.drain(() => {
            clearTimeout(timeout);
            port.close();
            resolve({ ok: true });
          });
        });
      });

      port.on("error", (err) => {
        clearTimeout(timeout);
        port.close();
        resolve({ ok: false, error: `Erreur port série: ${err.message}` });
      });
    });
  } catch (error) {
    return Promise.resolve({
      ok: false,
      error: `Erreur série: ${error.message}`,
    });
  }
}

/**
 * Envoie des octets à une imprimante réseau (TCP, port RAW 9100).
 * @param {string} ip
 * @param {number} port
 * @param {Buffer} data
 * @param {number} timeoutMs
 * @returns {Promise<{ ok: boolean, error?: string }>}
 */
export function sendToNetworkPrinter(ip, port, data, timeoutMs = 5000) {
  return new Promise((resolve) => {
    const s = net.createConnection(
      { host: ip, port: Number(port) || 9100 },
      () => {
        s.write(data, (err) => {
          if (err) {
            s.destroy();
            return resolve({ ok: false, error: err.message });
          }
          s.end(resolve.bind(null, { ok: true }));
        });
      }
    );
    s.setTimeout(timeoutMs, () => {
      s.destroy();
      resolve({ ok: false, error: "Timeout" });
    });
    s.on("error", (err) => resolve({ ok: false, error: err.message }));
  });
}

/**
 * Envoie des octets à une imprimante USB Direct via libusb
 * Format IP: USB:vendorId:productId (ex: USB:0x04f9:0x2042)
 * @param {string} ip - Format USB:vendorId:productId
 * @param {Buffer} data
 * @returns {Promise<{ ok: boolean, error?: string }>}
 */
export async function sendToUSBPrinter(ip, data) {
  // Charger USB si pas encore chargé
  if (!usb) {
    try {
      const usbModule = await import("usb");
      usb = usbModule.default || usbModule;
    } catch (e) {
      return Promise.resolve({
        ok: false,
        error: "Bibliothèque USB non disponible. Installer avec: npm install usb",
      });
    }
  }

  try {
    // Extraire vendorId et productId depuis USB:vendorId:productId
    const match = ip.match(/^USB:(?:0x)?([0-9a-fA-F]+):(?:0x)?([0-9a-fA-F]+)$/i);
    if (!match) {
      return Promise.resolve({
        ok: false,
        error: `Format USB invalide. Utilisez: USB:vendorId:productId (ex: USB:0x04f9:0x2042)`,
      });
    }

    const vendorId = parseInt(match[1], 16);
    const productId = parseInt(match[2], 16);

    // Trouver le périphérique USB
    const device = usb.findByIds(vendorId, productId);
    if (!device) {
      return Promise.resolve({
        ok: false,
        error: `Imprimante USB non trouvée (Vendor: 0x${vendorId.toString(16)}, Product: 0x${productId.toString(16)})`,
      });
    }

    // Ouvrir le périphérique
    let usbInterface = null;
    let deviceOpened = false;
    
    try {
      device.open();
      deviceOpened = true;

      // Trouver l'interface et l'endpoint d'impression (généralement interface 0, endpoint 1)
      usbInterface = device.interface(0);
      if (usbInterface.isKernelDriverActive()) {
        usbInterface.detachKernelDriver();
      }
      usbInterface.claim();

      // Chercher l'endpoint OUT (généralement endpoint 1 ou 2)
      const endpoints = usbInterface.endpoints;
      let outEndpoint = null;
      for (const ep of endpoints) {
        if (ep.direction === "out") {
          outEndpoint = ep;
          break;
        }
      }

      if (!outEndpoint) {
        throw new Error("Endpoint de sortie non trouvé sur l'imprimante USB");
      }

      // Envoyer les données par chunks de 64 bytes (taille typique des endpoints USB)
      const chunkSize = 64;
      for (let i = 0; i < data.length; i += chunkSize) {
        const chunk = data.slice(i, i + chunkSize);
        await new Promise((resolve, reject) => {
          outEndpoint.transfer(chunk, (err) => {
            if (err) reject(err);
            else resolve();
          });
        });
      }

      // Libérer les ressources
      usbInterface.release();
      device.close();
      deviceOpened = false;

      return Promise.resolve({ ok: true });
    } catch (error) {
      // Libérer les ressources en cas d'erreur
      try {
        if (usbInterface) {
          try {
            usbInterface.release();
          } catch (e) {
            // Ignorer les erreurs de release
          }
        }
        if (deviceOpened) {
          try {
            device.close();
          } catch (e) {
            // Ignorer les erreurs de close
          }
        }
      } catch (cleanupError) {
        // Ignorer les erreurs de nettoyage
      }
      throw error;
    }
  } catch (error) {
    return Promise.resolve({
      ok: false,
      error: `Erreur USB: ${error.message}. Vérifiez les permissions (sudo sur Linux/Mac)`,
    });
  }
}

/**
 * Envoie des octets à une imprimante IPP (Internet Printing Protocol)
 * Format IP: IPP:http://ip:631/ipp/print ou IPP:ipp://ip:631/ipp/print
 * @param {string} ip - Format IPP:url
 * @param {Buffer} data
 * @returns {Promise<{ ok: boolean, error?: string }>}
 */
export async function sendToIPPPrinter(ip, data) {
  // Charger IPP si pas encore chargé
  if (!ipp) {
    try {
      const ippModule = await import("ipp");
      ipp = ippModule.default || ippModule;
    } catch (e) {
      return Promise.resolve({
        ok: false,
        error: "Bibliothèque IPP non disponible. Installer avec: npm install ipp",
      });
    }
  }

  try {
    // Extraire l'URL depuis IPP:url
    const url = ip.replace(/^IPP:/i, "").trim();
    if (!url) {
      return Promise.resolve({
        ok: false,
        error: "URL IPP manquante. Format: IPP:http://ip:631/ipp/print",
      });
    }

    // Normaliser l'URL
    let ippUrl = url;
    if (!ippUrl.startsWith("http://") && !ippUrl.startsWith("https://") && !ippUrl.startsWith("ipp://")) {
      ippUrl = `ipp://${ippUrl}`;
    }
    if (!ippUrl.includes("/ipp/")) {
      ippUrl = ippUrl.replace(/\/$/, "") + "/ipp/print";
    }

    const Printer = ipp.Printer || ipp;
    const printer = new Printer(ippUrl);

    // Exécuter Print-Job
    const result = await printer.execute("Print-Job", {
      "operation-attributes-tag": {
        "requesting-user-name": "tawsil",
        "job-name": "Tawsil Order",
        "document-format": "application/octet-stream",
      },
      data: data,
    });

    if (result.statusCode === "successful-ok" || result.statusCode === "successful-ok-ignored-or-substituted-attributes") {
      return Promise.resolve({ ok: true });
    } else {
      return Promise.resolve({
        ok: false,
        error: `Erreur IPP: ${result.statusCode}`,
      });
    }
  } catch (error) {
    return Promise.resolve({
      ok: false,
      error: `Erreur IPP: ${error.message}`,
    });
  }
}

/**
 * Envoie des octets à une imprimante via HTTP/HTTPS
 * Format IP: HTTP:http://ip/print ou HTTPS:https://ip/print
 * @param {string} ip - Format HTTP:url ou HTTPS:url
 * @param {Buffer} data
 * @returns {Promise<{ ok: boolean, error?: string }>}
 */
export function sendToHTTPPrinter(ip, data, timeoutMs = 10000) {
  return new Promise((resolve) => {
    try {
      // Extraire l'URL depuis HTTP:url ou HTTPS:url
      const url = ip.replace(/^(HTTP|HTTPS):/i, "").trim();
      if (!url) {
        return resolve({
          ok: false,
          error: "URL HTTP manquante. Format: HTTP:http://ip/print",
        });
      }

      // Normaliser l'URL
      let httpUrl = url;
      if (!httpUrl.startsWith("http://") && !httpUrl.startsWith("https://")) {
        httpUrl = `http://${httpUrl}`;
      }

      const urlObj = new URL(httpUrl);
      const isHttps = urlObj.protocol === "https:";
      const client = isHttps ? https : http;

      const options = {
        hostname: urlObj.hostname,
        port: urlObj.port || (isHttps ? 443 : 80),
        path: urlObj.pathname || "/print",
        method: "POST",
        headers: {
          "Content-Type": "application/octet-stream",
          "Content-Length": data.length,
        },
        timeout: timeoutMs,
      };

      const req = client.request(options, (res) => {
        let responseData = "";
        res.on("data", (chunk) => {
          responseData += chunk;
        });
        res.on("end", () => {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve({ ok: true });
          } else {
            resolve({
              ok: false,
              error: `Erreur HTTP ${res.statusCode}: ${responseData}`,
            });
          }
        });
      });

      req.on("error", (err) => {
        resolve({ ok: false, error: `Erreur HTTP: ${err.message}` });
      });

      req.on("timeout", () => {
        req.destroy();
        resolve({ ok: false, error: "Timeout HTTP" });
      });

      req.write(data);
      req.end();
    } catch (error) {
      resolve({ ok: false, error: `Erreur HTTP: ${error.message}` });
    }
  });
}

/**
 * Envoie des octets à une imprimante Bluetooth
 * Format IP: BT:MAC_ADDRESS (ex: BT:00:11:22:33:44:55)
 * @param {string} ip - Format BT:MAC_ADDRESS
 * @param {Buffer} data
 * @returns {Promise<{ ok: boolean, error?: string }>}
 */
export async function sendToBluetoothPrinter(ip, data) {
  try {
    // Extraire l'adresse MAC depuis BT:MAC_ADDRESS
    const macAddress = ip.replace(/^BT:/i, "").trim();
    if (!macAddress || !/^([0-9A-F]{2}:){5}[0-9A-F]{2}$/i.test(macAddress)) {
      return Promise.resolve({
        ok: false,
        error: "Format Bluetooth invalide. Utilisez: BT:00:11:22:33:44:55",
      });
    }

    // Essayer différentes bibliothèques Bluetooth selon la plateforme
    if (process.platform === "linux") {
      try {
        // Bluetooth Serial Port pour Linux
        const BSP = await import("bluetooth-serial-port").then(m => m.default || m);
        const btSerial = new BSP.BluetoothSerialPort();
        
        return new Promise((resolve) => {
          btSerial.findSerialPortChannel(macAddress, (channel) => {
            btSerial.connect(macAddress, channel, () => {
              btSerial.write(data, (err) => {
                if (err) {
                  btSerial.close();
                  return resolve({ ok: false, error: `Erreur Bluetooth: ${err.message}` });
                }
                btSerial.close();
                resolve({ ok: true });
              });
            }, () => {
              resolve({ ok: false, error: "Impossible de se connecter à l'imprimante Bluetooth" });
            });
          }, (err) => {
            resolve({ ok: false, error: `Erreur recherche Bluetooth: ${err.message}` });
          });
        });
      } catch (e) {
        return Promise.resolve({
          ok: false,
          error: "Bibliothèque Bluetooth non disponible. Installer avec: npm install bluetooth-serial-port (Linux uniquement)",
        });
      }
    } else {
      // Pour Windows/Mac, utiliser une approche différente ou indiquer non supporté
      return Promise.resolve({
        ok: false,
        error: `Bluetooth non supporté sur ${process.platform}. Utilisez Linux ou configurez via le système d'exploitation.`,
      });
    }
  } catch (error) {
    return Promise.resolve({
      ok: false,
      error: `Erreur Bluetooth: ${error.message}`,
    });
  }
}

/**
 * Envoie des octets à une imprimante via mDNS/Bonjour
 * Format IP: MDNS:name ou BONJOUR:name
 * @param {string} ip - Format MDNS:name ou BONJOUR:name
 * @param {Buffer} data
 * @returns {Promise<{ ok: boolean, error?: string }>}
 */
export async function sendToMDNSPrinter(ip, data) {
  try {
    // Charger bonjour si pas encore chargé
    let bonjour;
    try {
      const bonjourModule = await import("bonjour");
      bonjour = bonjourModule.default || bonjourModule;
    } catch (e) {
      return Promise.resolve({
        ok: false,
        error: "Bibliothèque Bonjour non disponible. Installer avec: npm install bonjour",
      });
    }

    const serviceName = ip.replace(/^(MDNS|BONJOUR):/i, "").trim();
    if (!serviceName) {
      return Promise.resolve({
        ok: false,
        error: "Nom de service mDNS manquant. Format: MDNS:nom-imprimante",
      });
    }

    return new Promise((resolve) => {
      const browser = bonjour();
      
      // Chercher le service d'impression
      browser.findOne({ type: "ipp", name: serviceName }, (service) => {
        if (!service) {
          browser.destroy();
          return resolve({
            ok: false,
            error: `Service mDNS '${serviceName}' non trouvé`,
          });
        }

        // Utiliser l'IP et le port trouvés pour imprimer via réseau
        const printerIP = service.host;
        const printerPort = service.port || 9100;
        
        browser.destroy();
        
        // Imprimer via réseau avec l'IP trouvée
        sendToNetworkPrinter(printerIP, printerPort, data, 10000)
          .then(resolve)
          .catch((err) => resolve({ ok: false, error: err.message }));
      });

      // Timeout après 5 secondes
      setTimeout(() => {
        browser.destroy();
        resolve({
          ok: false,
          error: "Timeout recherche mDNS",
        });
      }, 5000);
    });
  } catch (error) {
    return Promise.resolve({
      ok: false,
      error: `Erreur mDNS: ${error.message}`,
    });
  }
}

/**
 * Envoie des octets à une imprimante LPD (Line Printer Daemon)
 * Format IP: LPD:ip:queue ou LPD:ip:port:queue
 * @param {string} ip - Format LPD:ip:queue ou LPD:ip:port:queue
 * @param {Buffer} data
 * @returns {Promise<{ ok: boolean, error?: string }>}
 */
export function sendToLPDPrinter(ip, data, timeoutMs = 5000) {
  return new Promise((resolve) => {
    try {
      // Extraire ip, port et queue depuis LPD:ip:queue ou LPD:ip:port:queue
      const parts = ip.replace(/^LPD:/i, "").trim().split(":");
      if (parts.length < 2) {
        return resolve({
          ok: false,
          error: "Format LPD invalide. Utilisez: LPD:ip:queue ou LPD:ip:port:queue",
        });
      }

      let lpdIp, lpdPort, lpdQueue;
      if (parts.length === 2) {
        lpdIp = parts[0];
        lpdPort = 515; // Port par défaut LPD
        lpdQueue = parts[1];
      } else {
        lpdIp = parts[0];
        lpdPort = parseInt(parts[1]) || 515;
        lpdQueue = parts[2];
      }

      const socket = net.createConnection({ host: lpdIp, port: lpdPort, timeout: timeoutMs }, () => {
        // Protocole LPD simple
        // 1. Envoyer commande Receive job (code 02)
        socket.write(`\x02${lpdQueue}\n`);

        // 2. Envoyer control file (code 03)
        const controlFile = `H${os.hostname()}\nP${process.env.USER || "tawsil"}\nJ${lpdQueue}\nL${data.length}\n`;
        socket.write(`\x03${controlFile.length} ${lpdQueue}\n`);
        socket.write(controlFile);

        // 3. Envoyer data file (code 03)
        socket.write(`\x03${data.length} ${lpdQueue}\n`);
        socket.write(data);

        // 4. Fin de job (code 00)
        socket.write("\x00");

        socket.end();
        resolve({ ok: true });
      });

      socket.on("error", (err) => {
        resolve({ ok: false, error: `Erreur LPD: ${err.message}` });
      });

      socket.on("timeout", () => {
        socket.destroy();
        resolve({ ok: false, error: "Timeout LPD" });
      });
    } catch (error) {
      resolve({ ok: false, error: `Erreur LPD: ${error.message}` });
    }
  });
}

/**
 * Imprime une commande sur une imprimante configurée.
 * @param {object} printer - { id, ip, port, paper_width_mm, is_enabled, type, restaurant_id }
 * @param {object} order - Commande (avec order_items, etc.)
 * @param {string} restaurantName
 * @param {object} options - { cashierName?, cashierCode?, useTemplate?: boolean }
 * @returns {Promise<{ ok: boolean, printerName?: string, error?: string }>}
 */
export async function printOrderOnPrinter(printer, order, restaurantName, options = {}) {
  if (!printer?.is_enabled) {
    return { ok: false, error: "Imprimante désactivée", printerName: printer?.name };
  }
  const ip = printer.ip?.trim();
  if (!ip) return { ok: false, error: "IP ou configuration d'imprimante manquante", printerName: printer?.name };

  let buf;
  const { cashierName, cashierCode, useTemplate = true } = options;
  
  // Essayer d'utiliser un template personnalisé si disponible
  if (useTemplate && printer.id && printer.restaurant_id) {
    try {
      // Chercher un template pour cette imprimante spécifique
      let template = await PrinterTemplate.findOne({
        where: {
          printer_id: printer.id,
          is_active: true,
        },
        order: [["is_default", "DESC"], ["created_at", "ASC"]],
      });
      
      // Sinon, chercher un template par défaut pour le type d'imprimante
      if (!template) {
        template = await PrinterTemplate.findOne({
          where: {
            restaurant_id: printer.restaurant_id,
            type: printer.type || "general",
            is_default: true,
            is_active: true,
            printer_id: null,
          },
        });
      }
      
      // Sinon, chercher n'importe quel template actif pour ce type
      if (!template) {
        template = await PrinterTemplate.findOne({
          where: {
            restaurant_id: printer.restaurant_id,
            type: printer.type || "general",
            is_active: true,
            printer_id: null,
          },
          order: [["created_at", "ASC"]],
        });
      }
      
      // Si un template est trouvé, l'utiliser
      if (template) {
        const rendered = renderTemplate(template.template_content, order, {
          restaurantName,
          cashierName,
          cashierCode,
        });
        
        buf = templateToEscPos(rendered, {
          paperWidth: Number(printer.paper_width_mm) || 80,
        });
      }
    } catch (err) {
      console.warn(`[Print] Erreur lors de la récupération du template: ${err.message}`);
      // Fallback sur le template par défaut
    }
  }
  
  // Si pas de template ou erreur, utiliser le template par défaut
  if (!buf) {
    const printerType = String(printer.type || "general").toLowerCase();
    if (printerType === "cuisine" || printerType === "bar") {
      buf = buildKitchenReceiptEscPos(order, restaurantName, {
        paperWidth: Number(printer.paper_width_mm) || 80,
      });
    } else if (printerType === "general") {
      buf = buildSummaryReceiptEscPos(order, restaurantName, {
        paperWidth: Number(printer.paper_width_mm) || 80,
      });
    } else {
      buf = buildReceiptEscPos(order, restaurantName, {
        paperWidth: Number(printer.paper_width_mm) || 80,
      });
    }
  }
  
  let result;
  if (isUSBPrinter(ip)) {
    result = await sendToUSBPrinter(ip, buf);
  } else if (isIPPPrinter(ip)) {
    result = await sendToIPPPrinter(ip, buf);
  } else if (isHTTPPrinter(ip)) {
    result = await sendToHTTPPrinter(ip, buf);
  } else if (isLPDPrinter(ip)) {
    result = await sendToLPDPrinter(ip, buf);
  } else if (isBluetoothPrinter(ip)) {
    result = await sendToBluetoothPrinter(ip, buf);
  } else if (isMDNSPrinter(ip)) {
    result = await sendToMDNSPrinter(ip, buf);
  } else if (isSerialPort(ip)) {
    result = await sendToSerialPort(ip, buf);
  } else {
    result = await sendToNetworkPrinter(ip, Number(printer.port) || 9100, buf);
  }
  return {
    ok: result.ok,
    printerName: printer.name,
    error: result.error,
  };
}

/**
 * Ouvre le tiroir-caisse d'une imprimante
 * @param {object} printer - { ip, port, is_enabled }
 * @returns {Promise<{ ok: boolean, printerName?: string, error?: string }>}
 */
export async function openCashDrawer(printer) {
  if (!printer?.is_enabled) {
    return { ok: false, error: "Imprimante désactivée", printerName: printer?.name };
  }
  const ip = printer.ip?.trim();
  if (!ip) return { ok: false, error: "IP ou configuration d'imprimante manquante", printerName: printer?.name };

  // Construire la commande ESC/POS pour ouvrir le tiroir
  const drawerCmd = Buffer.concat([
    cmds.init(),
    cmds.openDrawer(),
  ]);

  let result;
  if (isUSBPrinter(ip)) {
    result = await sendToUSBPrinter(ip, drawerCmd);
  } else if (isIPPPrinter(ip)) {
    result = await sendToIPPPrinter(ip, drawerCmd);
  } else if (isHTTPPrinter(ip)) {
    result = await sendToHTTPPrinter(ip, drawerCmd);
  } else if (isLPDPrinter(ip)) {
    result = await sendToLPDPrinter(ip, drawerCmd);
  } else if (isBluetoothPrinter(ip)) {
    result = await sendToBluetoothPrinter(ip, drawerCmd);
  } else if (isMDNSPrinter(ip)) {
    result = await sendToMDNSPrinter(ip, drawerCmd);
  } else if (isSerialPort(ip)) {
    result = await sendToSerialPort(ip, drawerCmd, 5000);
  } else {
    result = await sendToNetworkPrinter(ip, Number(printer.port) || 9100, drawerCmd, 5000);
  }
  return {
    ok: result.ok,
    printerName: printer.name,
    error: result.error,
  };
}

/**
 * Déclenche l'impression sur toutes les imprimantes actives du restaurant.
 * À appeler après validation de la commande (ex: dans setImmediate).
 * Si l'impression directe échoue (réseau distant), le job est mis en file d'attente pour le POS.
 * Ne lève pas d'exception ; les erreurs sont loguées.
 * @param {string} restaurantId
 * @param {object} orderPayload - Commande avec order_items (menu_item, additions/addition), order_number, total_amount, etc.
 * @param {string} [restaurantName] - Nom du restaurant (sinon lu depuis orderPayload.restaurant?.name)
 */
export async function triggerOrderPrint(restaurantId, orderPayload, restaurantName) {
  const PrintJob = (await import("../models/PrintJob.js")).default;
  
  const printers = await RestaurantPrinter.findAll({
    where: { restaurant_id: restaurantId, is_enabled: true },
  });
  const name = restaurantName || orderPayload?.restaurant?.name || "Restaurant";
  
  // Récupérer les infos du caissier si disponibles
  const cashierName = orderPayload.cashier?.name || orderPayload.created_by_cashier?.name || null;
  const cashierCode = orderPayload.cashier?.cashier_code || orderPayload.created_by_cashier?.cashier_code || null;
  const orderId = orderPayload.id || orderPayload.order_id;

  const ensureQueuedPrintJob = async (printerId, errorMsg) => {
    if (!orderId) return null;
    const existing = await PrintJob.findOne({
      where: {
        restaurant_id: restaurantId,
        printer_id: printerId,
        order_id: orderId,
        status: { [Op.in]: ["pending", "processing"] }
      }
    });
    if (existing) {
      console.log(`[Print] Job deja en file pour printer ${printerId} (commande ${orderId})`);
      return existing;
    }
    const job = await PrintJob.create({
      restaurant_id: restaurantId,
      printer_id: printerId,
      order_id: orderId,
      status: "pending"
    });
    emit(`restaurant:${restaurantId}`, "print_job:queued", {
      restaurant_id: restaurantId,
      printer_id: printerId,
      order_id: orderId,
      error_message: errorMsg
    });
    return job;
  };
  
  for (const p of printers) {
    try {
      const r = await printOrderOnPrinter(p, orderPayload, name, {
        cashierName,
        cashierCode,
        useTemplate: true,
      });
      if (r.ok) {
        console.log(`[Print] OK "${r.printerName}" — commande ${orderPayload?.order_number || orderPayload?.id}`);
      } else {
        // Si l'impression directe échoue, mettre en file d'attente pour le POS
        const errorMsg = r.error || "Unknown error";
        const isNetworkError = errorMsg.includes("ECONNREFUSED") || 
                              errorMsg.includes("ETIMEDOUT") || 
                              errorMsg.includes("ENETUNREACH") ||
                              errorMsg.includes("Timeout") ||
                              errorMsg.includes("network");
        
        if (isNetworkError) {
          // Probablement un problème de réseau (backend distant, imprimante locale)
          // Mettre en file d'attente pour le POS
          try {
            await ensureQueuedPrintJob(p.id, errorMsg);
            console.log(`[Print] Job mis en file d'attente pour "${r.printerName}" (erreur réseau: ${errorMsg})`);
          } catch (queueError) {
            console.warn(`[Print] Échec mise en file d'attente "${p?.name}":`, queueError?.message || queueError);
          }
        } else {
          console.warn(`[Print] Échec "${r.printerName}": ${errorMsg}`);
        }
      }
    } catch (e) {
      // En cas d'exception, essayer de mettre en file d'attente
      const errorMsg = e?.message || String(e);
      const isNetworkError = errorMsg.includes("ECONNREFUSED") || 
                            errorMsg.includes("ETIMEDOUT") || 
                            errorMsg.includes("ENETUNREACH") ||
                            errorMsg.includes("Timeout") ||
                            errorMsg.includes("network");
      
      if (isNetworkError) {
        try {
          await ensureQueuedPrintJob(p.id, errorMsg);
          console.log(`[Print] Job mis en file d'attente pour "${p?.name}" (erreur réseau: ${errorMsg})`);
        } catch (queueError) {
          console.warn(`[Print] Échec mise en file d'attente "${p?.name}":`, queueError?.message || queueError);
        }
      } else {
        console.warn(`[Print] Erreur "${p?.name}":`, errorMsg);
      }
    }
  }
}
