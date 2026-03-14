/**
 * Service de détection automatique d'imprimantes ESC/POS
 * Scan réseau pour trouver les imprimantes disponibles
 */

import { execSync } from "child_process";
import net from "net";
import os from "os";
import http from "http";
import https from "https";
import { promisify } from "util";
import { sendToNetworkPrinter } from "./printService.js";

// Import conditionnel USB
let usb = null;
(async () => {
  try {
    const usbModule = await import("usb");
    usb = usbModule.default || usbModule;
  } catch (e) {
    // USB non disponible
  }
})();

// Import conditionnel Bonjour/mDNS
let bonjour = null;
(async () => {
  try {
    const bonjourModule = await import("bonjour");
    bonjour = bonjourModule.default || bonjourModule;
  } catch (e) {
    // Bonjour non disponible
  }
})();

// Import conditionnel SNMP
let snmp = null;
(async () => {
  try {
    const snmpModule = await import("net-snmp");
    snmp = snmpModule.default || snmpModule;
  } catch (e) {
    // SNMP non disponible
  }
})();

const setTimeoutPromise = promisify(setTimeout);

/**
 * Scanne une plage d'adresses IP pour trouver des imprimantes ESC/POS
 * @param {string} networkBase - Base du réseau (ex: "192.168.1")
 * @param {number} startHost - Première adresse à scanner (ex: 1)
 * @param {number} endHost - Dernière adresse à scanner (ex: 254)
 * @param {number} port - Port à scanner (défaut: 9100)
 * @param {number} timeoutMs - Timeout par connexion (défaut: 1000ms)
 * @returns {Promise<Array<{ip: string, port: number, responseTime: number, type: string}>>}
 */
/**
 * Scanne une plage d'adresses IP pour trouver des imprimantes ESC/POS (amélioré)
 * Détecte maintenant RAW (9100), IPP (631), LPD (515), HTTP (80/443)
 * @param {string} networkBase - Base du réseau (ex: "192.168.1")
 * @param {number} startHost - Première adresse à scanner (ex: 1)
 * @param {number} endHost - Dernière adresse à scanner (ex: 254)
 * @param {number} port - Port à scanner (défaut: 9100, null = tous les ports)
 * @param {number} timeoutMs - Timeout par connexion (défaut: 1000ms)
 * @returns {Promise<Array<{ip: string, port: number, responseTime: number, type: string, protocol: string}>>}
 */
export async function scanNetworkForPrinters(
  networkBase = null,
  startHost = 1,
  endHost = 254,
  port = 9100,
  timeoutMs = 1000
) {
  const detectedPrinters = [];
  
  // Si networkBase n'est pas fourni, détecter automatiquement
  if (!networkBase) {
    const interfaces = os.networkInterfaces();
    for (const name of Object.keys(interfaces)) {
      const addresses = interfaces[name];
      if (!addresses) continue;
      
      for (const addr of addresses) {
        // Ignorer les adresses IPv6 et loopback
        if (addr.family !== "IPv4" || addr.internal) continue;
        
        // Extraire la base du réseau (ex: "192.168.1" depuis "192.168.1.100")
        const parts = addr.address.split(".");
        if (parts.length === 4) {
          networkBase = `${parts[0]}.${parts[1]}.${parts[2]}`;
          console.log(`🔍 Scanning network: ${networkBase}.x`);
          break;
        }
      }
      if (networkBase) break;
    }
  }
  
  if (!networkBase) {
    return { success: false, error: "Impossible de détecter le réseau local", printers: [] };
  }
  
  // Si port est null, scanner tous les ports d'imprimantes
  const portsToScan = port ? [port] : [9100, 9101, 631, 515, 80, 443];
  
  console.log(`🔍 Scanning ${networkBase}.${startHost}-${endHost} on ports ${portsToScan.join(", ")}...`);
  
  // Scanner en parallèle avec limite de concurrence
  const maxConcurrent = 20;
  const scanPromises = [];
  
  for (let host = startHost; host <= endHost; host++) {
    const ip = `${networkBase}.${host}`;
    
    // Scanner tous les ports pour chaque IP
    for (const scanPort of portsToScan) {
      // Limiter la concurrence
      if (scanPromises.length >= maxConcurrent) {
        await Promise.race(scanPromises);
        scanPromises.splice(scanPromises.findIndex(p => p === Promise.race(scanPromises)), 1);
      }
      
      const scanPromise = (async () => {
        let result;
        
        // Utiliser la méthode appropriée selon le port
        if (scanPort === 631) {
          result = await checkIPPPrinter(ip, scanPort, timeoutMs);
        } else if (scanPort === 80 || scanPort === 443) {
          result = await checkHTTPPrinter(ip, scanPort, timeoutMs);
        } else {
          result = await checkPrinterAtIP(ip, scanPort, timeoutMs);
        }
        
        if (result.found) {
          const protocol = result.protocol || (scanPort === 9100 || scanPort === 9101 ? "raw" : "unknown");
          const ipFormat = protocol === "ipp" ? `IPP:http://${result.ip}:${result.port}/ipp/print` :
                          protocol === "http" ? `HTTP:http://${result.ip}:${result.port}/print` :
                          protocol === "lpd" ? `LPD:${result.ip}:lp` :
                          result.ip;
          
          // Construire un nom intelligent
          let printerName = `Imprimante ${result.ip}`;
          if (result.vendor && result.model) {
            printerName = `${result.vendor} ${result.model} (${result.ip})`;
          } else if (result.vendor) {
            printerName = `${result.vendor} Printer (${result.ip})`;
          } else if (result.model) {
            printerName = `Printer ${result.model} (${result.ip})`;
          }
          
          detectedPrinters.push({
            ip: ipFormat,
            port: result.port,
            responseTime: result.responseTime || 0,
            type: "network",
            protocol: protocol,
            name: `${printerName} (${protocol.toUpperCase()})`,
            confidence: result.confidence || "medium",
            model: result.model,
            vendor: result.vendor,
          });
          console.log(`✅ Found ${protocol.toUpperCase()} printer: ${printerName} at ${result.ip}:${result.port}`);
        }
      })();
      
      scanPromises.push(scanPromise);
    }
  }
  
  // Attendre la fin de tous les scans
  await Promise.all(scanPromises);
  
  return {
    success: true,
    printers: detectedPrinters.sort((a, b) => (a.responseTime || 0) - (b.responseTime || 0)),
    networkScanned: `${networkBase}.${startHost}-${endHost}`,
    protocolsFound: [...new Set(detectedPrinters.map(p => p.protocol))],
  };
}

/**
 * Détecte le type d'imprimante en envoyant une commande ESC/POS de test
 * @param {string} ip
 * @param {number} port
 * @param {number} timeoutMs
 * @returns {Promise<{isEscPos: boolean, model?: string, vendor?: string}>}
 */
async function detectPrinterType(ip, port, timeoutMs) {
  return new Promise((resolve) => {
    const socket = net.createConnection({ host: ip, port, timeout: timeoutMs }, () => {
      // Envoyer une commande ESC/POS de requête d'identification
      // ESC @ = Reset, ESC v = Version, ESC i = Identification
      const testCommands = Buffer.from("\x1b@\x1dv\x1bi", "ascii");
      
      let responseData = Buffer.alloc(0);
      let responseTimeout;
      
      socket.on("data", (data) => {
        responseData = Buffer.concat([responseData, data]);
      });
      
      responseTimeout = setTimeout(() => {
        socket.destroy();
        // Analyser la réponse pour détecter si c'est une imprimante ESC/POS
        const responseStr = responseData.toString("ascii", 0, Math.min(100, responseData.length));
        const isEscPos = /epson|star|bixolon|receipt|pos|esc/i.test(responseStr) || 
                        responseData.length > 0; // Si réponse, probablement imprimante
        
        resolve({
          isEscPos: isEscPos,
          model: extractModelFromResponse(responseStr),
          vendor: extractVendorFromResponse(responseStr),
        });
      }, 500);
      
      socket.write(testCommands);
    });
    
    socket.on("error", () => {
      resolve({ isEscPos: false });
    });
    
    socket.on("timeout", () => {
      socket.destroy();
      resolve({ isEscPos: false });
    });
  });
}

/**
 * Extrait le modèle depuis la réponse de l'imprimante
 */
function extractModelFromResponse(response) {
  const modelPatterns = [
    /TM-(\w+)/i,
    /XP-(\w+)/i,
    /RP-(\w+)/i,
    /SP-(\w+)/i,
    /Model[:\s]+(\w+)/i,
  ];
  
  for (const pattern of modelPatterns) {
    const match = response.match(pattern);
    if (match) return match[1];
  }
  return null;
}

/**
 * Extrait le fabricant depuis la réponse de l'imprimante
 */
function extractVendorFromResponse(response) {
  const vendors = ["epson", "star", "bixolon", "citizen", "zebra", "xprinter"];
  const responseLower = response.toLowerCase();
  
  for (const vendor of vendors) {
    if (responseLower.includes(vendor)) {
      return vendor.charAt(0).toUpperCase() + vendor.slice(1);
    }
  }
  return null;
}

/**
 * Vérifie si une imprimante ESC/POS est disponible à une adresse IP donnée (AMÉLIORÉ)
 * @param {string} ip
 * @param {number} port
 * @param {number} timeoutMs
 * @returns {Promise<{found: boolean, ip?: string, port?: number, responseTime?: number, confidence?: string, protocol?: string, model?: string, vendor?: string}>}
 */
async function checkPrinterAtIP(ip, port, timeoutMs) {
  return new Promise((resolve) => {
    const startTime = Date.now();
    const socket = net.createConnection({ host: ip, port, timeout: timeoutMs }, () => {
      const responseTime = Date.now() - startTime;
      
      // Déterminer le protocole selon le port
      let protocol = "raw";
      if (port === 631) protocol = "ipp";
      else if (port === 515) protocol = "lpd";
      else if (port === 80 || port === 443) protocol = "http";
      
      // Pour les ports RAW (9100), essayer de détecter le type d'imprimante
      if (port === 9100 || port === 9101) {
        socket.destroy();
        // Détecter le type d'imprimante
        detectPrinterType(ip, port, timeoutMs).then((printerInfo) => {
          const confidence = printerInfo.isEscPos 
            ? (responseTime < 100 ? "high" : responseTime < 500 ? "medium" : "low")
            : "low";
          
          resolve({
            found: true,
            ip,
            port,
            responseTime,
            protocol,
            confidence,
            model: printerInfo.model,
            vendor: printerInfo.vendor,
          });
        }).catch(() => {
          // En cas d'erreur, considérer comme imprimante avec confiance moyenne
          resolve({
            found: true,
            ip,
            port,
            responseTime,
            protocol,
            confidence: responseTime < 100 ? "high" : responseTime < 500 ? "medium" : "low",
          });
        });
      } else {
        socket.destroy();
        // Pour les autres ports, confiance basée sur la réponse
        resolve({
          found: true,
          ip,
          port,
          responseTime,
          protocol,
          confidence: responseTime < 100 ? "high" : responseTime < 500 ? "medium" : "low",
        });
      }
    });
    
    socket.on("error", () => {
      resolve({ found: false });
    });
    
    socket.on("timeout", () => {
      socket.destroy();
      resolve({ found: false });
    });
  });
}

/**
 * Vérifie si une imprimante IPP est disponible
 * @param {string} ip
 * @param {number} port
 * @param {number} timeoutMs
 * @returns {Promise<{found: boolean, ip?: string, port?: number, protocol?: string, confidence?: string}>}
 */
async function checkIPPPrinter(ip, port = 631, timeoutMs = 2000) {
  return new Promise((resolve) => {
    try {
      const url = `http://${ip}:${port}/ipp/print`;
      const req = http.get(url, { timeout: timeoutMs }, (res) => {
        req.destroy();
        resolve({
          found: true,
          ip,
          port,
          protocol: "ipp",
          confidence: res.statusCode === 200 ? "high" : "medium",
        });
      });

      req.on("error", () => {
        resolve({ found: false });
      });

      req.on("timeout", () => {
        req.destroy();
        resolve({ found: false });
      });
    } catch (e) {
      resolve({ found: false });
    }
  });
}

/**
 * Vérifie si une imprimante HTTP est disponible
 * @param {string} ip
 * @param {number} port
 * @param {number} timeoutMs
 * @returns {Promise<{found: boolean, ip?: string, port?: number, protocol?: string, confidence?: string}>}
 */
async function checkHTTPPrinter(ip, port = 80, timeoutMs = 2000) {
  return new Promise((resolve) => {
    try {
      const url = `http://${ip}:${port}/`;
      const req = http.get(url, { timeout: timeoutMs }, (res) => {
        let data = "";
        res.on("data", (chunk) => {
          data += chunk.toString();
        });
        res.on("end", () => {
          req.destroy();
          // Vérifier si le contenu suggère une imprimante
          const isPrinter = /printer|print|imprimante|epson|star|bixolon|receipt/i.test(data) ||
                           res.headers["server"]?.toLowerCase().includes("printer");
          
          resolve({
            found: isPrinter,
            ip,
            port,
            protocol: "http",
            confidence: isPrinter ? "high" : "low",
          });
        });
      });

      req.on("error", () => {
        resolve({ found: false });
      });

      req.on("timeout", () => {
        req.destroy();
        resolve({ found: false });
      });
    } catch (e) {
      resolve({ found: false });
    }
  });
}

/**
 * Détecte les imprimantes via mDNS/Bonjour (AirPrint, etc.)
 * @returns {Promise<Array<{name: string, host: string, port: number, type: string}>>}
 */
export async function detectMDNSPrinters() {
  // Charger bonjour si pas encore chargé
  if (!bonjour) {
    try {
      const bonjourModule = await import("bonjour");
      bonjour = bonjourModule.default || bonjourModule;
    } catch (e) {
      return {
        success: false,
        error: "Bibliothèque Bonjour non disponible. Installer avec: npm install bonjour",
        printers: [],
      };
    }
  }

  try {
    return new Promise((resolve) => {
      const BonjourInstance = bonjour();
      const printers = [];
      const foundServices = new Set(); // Éviter les doublons

      // Chercher les services IPP (Internet Printing Protocol)
      const ippBrowser = BonjourInstance.find({ type: "ipp" }, (service) => {
        const key = `${service.name}-${service.host}-${service.port}`;
        if (!foundServices.has(key)) {
          foundServices.add(key);
          printers.push({
            name: service.name,
            host: service.host,
            port: service.port || 631,
            type: "mdns",
            ip: `MDNS:${service.name}`,
            protocol: "ipp",
            confidence: "high",
          });
          console.log(`✅ Found mDNS printer: ${service.name} at ${service.host}:${service.port}`);
        }
      });

      // Chercher les services d'impression génériques
      const printerBrowser = BonjourInstance.find({ type: "printer" }, (service) => {
        const key = `${service.name}-${service.host}-${service.port}`;
        if (!foundServices.has(key)) {
          foundServices.add(key);
          printers.push({
            name: service.name,
            host: service.host,
            port: service.port || 9100,
            type: "mdns",
            ip: `MDNS:${service.name}`,
            protocol: "raw",
            confidence: "high",
          });
          console.log(`✅ Found mDNS printer: ${service.name} at ${service.host}:${service.port}`);
        }
      });

      // Timeout après 5 secondes
      setTimeout(() => {
        try {
          ippBrowser.stop();
          printerBrowser.stop();
          BonjourInstance.destroy();
        } catch (e) {
          // Ignorer les erreurs de nettoyage
        }
        resolve({
          success: true,
          printers: printers,
          note: `${printers.length} imprimante(s) mDNS détectée(s)`,
        });
      }, 5000);
    });
  } catch (error) {
    return {
      success: false,
      error: error.message || "Erreur lors de la détection mDNS",
      printers: [],
    };
  }
}

/**
 * Détecte les imprimantes Bluetooth
 * @returns {Promise<Array<{name: string, address: string, type: string}>>}
 */
export async function detectBluetoothPrinters() {
  if (process.platform !== "linux") {
    return {
      success: false,
      error: "Détection Bluetooth uniquement sur Linux. Sur Windows/Mac, utilisez les paramètres système.",
      printers: [],
    };
  }

  try {
    // Charger bluetooth-serial-port si disponible
    let BSP;
    try {
      const bspModule = await import("bluetooth-serial-port");
      BSP = bspModule.default || bspModule;
      if (!BSP || !BSP.BluetoothSerialPort) {
        throw new Error("BluetoothSerialPort not found");
      }
    } catch (e) {
      return {
        success: false,
        error: "Bibliothèque Bluetooth non disponible. Installer avec: npm install bluetooth-serial-port (Linux uniquement, nécessite libbluetooth-dev)",
        printers: [],
      };
    }

    return new Promise((resolve) => {
      try {
        const btSerial = new BSP.BluetoothSerialPort();
        const printers = [];
        let finished = false;

        const finish = () => {
          if (!finished) {
            finished = true;
            resolve({
              success: true,
              printers: printers,
              note: `${printers.length} imprimante(s) Bluetooth détectée(s)`,
            });
          }
        };

        // Timeout après 10 secondes
        const timeout = setTimeout(() => {
          finish();
        }, 10000);

        btSerial.inquire((device) => {
          // Filtrer les périphériques qui pourraient être des imprimantes
          const deviceName = device.name || "Unknown";
          if (/printer|print|receipt|pos|esc/i.test(deviceName)) {
            printers.push({
              name: deviceName,
              address: device.address,
              type: "bluetooth",
              ip: `BT:${device.address}`,
              confidence: "medium",
            });
            console.log(`✅ Found Bluetooth printer: ${deviceName} (${device.address})`);
          }
        }, () => {
          // Fin de la recherche
          clearTimeout(timeout);
          finish();
        }, (err) => {
          clearTimeout(timeout);
          resolve({
            success: false,
            error: `Erreur recherche Bluetooth: ${err.message || err}`,
            printers: printers.length > 0 ? printers : [],
          });
        });
      } catch (error) {
        resolve({
          success: false,
          error: `Erreur initialisation Bluetooth: ${error.message}`,
          printers: [],
        });
      }
    });
  } catch (error) {
    return {
      success: false,
      error: error.message || "Erreur lors de la détection Bluetooth",
      printers: [],
    };
  }
}

/**
 * Détecte les imprimantes via SNMP (découverte et monitoring uniquement)
 * @param {string} networkBase - Base du réseau (ex: "192.168.1")
 * @param {string} community - Communauté SNMP (défaut: "public")
 * @returns {Promise<Array<{name: string, ip: string, type: string}>>}
 */
export async function detectSNMPPrinters(networkBase = null, community = "public") {
  // Charger SNMP si pas encore chargé
  if (!snmp) {
    try {
      const snmpModule = await import("net-snmp");
      snmp = snmpModule.default || snmpModule;
      if (!snmp || !snmp.createSession) {
        throw new Error("SNMP createSession not found");
      }
    } catch (e) {
      return {
        success: false,
        error: "Bibliothèque SNMP non disponible. Installer avec: npm install net-snmp (nécessite net-snmp-dev sur Linux)",
        printers: [],
      };
    }
  }

  try {
    // Si networkBase n'est pas fourni, détecter automatiquement
    if (!networkBase) {
      const interfaces = os.networkInterfaces();
      for (const name of Object.keys(interfaces)) {
        const addresses = interfaces[name];
        if (!addresses) continue;
        for (const addr of addresses) {
          if (addr.family === "IPv4" && !addr.internal) {
            const parts = addr.address.split(".");
            if (parts.length === 4) {
              networkBase = `${parts[0]}.${parts[1]}.${parts[2]}`;
              break;
            }
          }
        }
        if (networkBase) break;
      }
    }

    if (!networkBase) {
      return {
        success: false,
        error: "Impossible de détecter le réseau local",
        printers: [],
      };
    }

    const printers = [];
    const oids = {
      sysName: "1.3.6.1.2.1.1.5.0", // Nom système
      sysDescr: "1.3.6.1.2.1.1.1.0", // Description système
    };

    // Scanner les 10 premières adresses (limiter pour performance)
    const scanPromises = [];
    for (let host = 1; host <= 10; host++) {
      const ip = `${networkBase}.${host}`;
      scanPromises.push(
        new Promise((resolve) => {
          try {
            const session = snmp.createSession(ip, community, { timeout: 2000 });
            session.get([oids.sysDescr], (error, varbinds) => {
              if (!error && varbinds && varbinds[0] && varbinds[0].value) {
                const descr = varbinds[0].value.toString();
                // Vérifier si c'est une imprimante
                if (/printer|print|epson|star|bixolon|receipt/i.test(descr)) {
                  session.get([oids.sysName], (err, names) => {
                    const name = names && names[0] && names[0].value ? names[0].value.toString() : `Printer ${ip}`;
                    printers.push({
                      name: name,
                      ip: ip,
                      type: "snmp",
                      description: descr,
                      confidence: "high",
                    });
                    console.log(`✅ Found SNMP printer: ${name} at ${ip}`);
                    session.close();
                    resolve();
                  });
                } else {
                  session.close();
                  resolve();
                }
              } else {
                session.close();
                resolve();
              }
            });
          } catch (err) {
            resolve(); // Ignorer les erreurs individuelles
          }
        })
      );
    }

    await Promise.all(scanPromises);

    return {
      success: true,
      printers: printers,
      note: `${printers.length} imprimante(s) SNMP détectée(s)`,
    };
  } catch (error) {
    return {
      success: false,
      error: error.message || "Erreur lors de la détection SNMP",
      printers: [],
    };
  }
}

/**
 * Détecte les imprimantes USB connectées
 * @returns {Promise<Array<{name: string, vendorId: string, productId: string, type: string}>>}
 */
export async function detectUSBPrinters() {
  // Charger USB si pas encore chargé
  if (!usb) {
    try {
      const usbModule = await import("usb");
      usb = usbModule.default || usbModule;
    } catch (e) {
      return {
        success: false,
        error: "Bibliothèque USB non disponible. Installer avec: npm install usb",
        printers: [],
      };
    }
  }

  try {
    const devices = usb.getDeviceList();
    const printers = [];

    for (const device of devices) {
      try {
        device.open();
        const descriptor = device.deviceDescriptor;

        // Filtrer les périphériques qui pourraient être des imprimantes
        // Class code 7 = Printer selon USB spec
        const isPrinter = descriptor.bDeviceClass === 7 ||
                         descriptor.bDeviceClass === 0; // Certaines imprimantes utilisent class 0

        if (isPrinter) {
          const vendorId = `0x${descriptor.idVendor.toString(16).padStart(4, "0")}`;
          const productId = `0x${descriptor.idProduct.toString(16).padStart(4, "0")}`;

          printers.push({
            name: `USB Printer (${vendorId}:${productId})`,
            vendorId: vendorId,
            productId: productId,
            type: "usb",
            ip: `USB:${vendorId}:${productId}`,
            confidence: "high",
          });
        }
        device.close();
      } catch (e) {
        // Ignorer les erreurs d'accès (permissions)
        continue;
      }
    }

    return {
      success: true,
      printers: printers,
      note: printers.length === 0
        ? "Aucune imprimante USB détectée. Vérifiez les permissions (sudo sur Linux/Mac)."
        : `${printers.length} imprimante(s) USB détectée(s)`,
    };
  } catch (error) {
    return {
      success: false,
      error: error.message || "Erreur lors de la détection USB",
      printers: [],
    };
  }
}

/**
 * Détecte les ports série disponibles de manière intelligente (cross-platform)
 * @returns {Promise<Array<{name: string, path: string, type: string, baudRates: number[]}>>}
 */
export async function detectSerialPorts() {
  try {
    // Charger serialport si disponible
    let SerialPort;
    try {
      const serialportModule = await import("serialport");
      SerialPort = serialportModule.SerialPort || serialportModule.default?.SerialPort || serialportModule.default;
      if (!SerialPort) {
        throw new Error("SerialPort not found");
      }
    } catch (e) {
      // Fallback : retourner les ports COM standards sur Windows
      if (process.platform === "win32") {
        const ports = [];
        for (let i = 1; i <= 8; i++) {
          ports.push({
            name: `COM${i}`,
            path: `COM${i}`,
            type: "serial",
            ip: `COM:COM${i}:9600:8:N:1`,
            confidence: "low",
            baudRates: [9600, 19200, 38400, 57600, 115200],
          });
        }
        return {
          success: true,
          printers: ports,
          note: "Ports COM Windows détectés (non vérifiés). Installez serialport pour détection avancée.",
        };
      }
      return {
        success: false,
        error: "Bibliothèque SerialPort non disponible. Installer avec: npm install serialport",
        printers: [],
      };
    }

    // Lister les ports série disponibles
    const ports = await SerialPort.list();
    const detectedPorts = ports.map((port) => ({
      name: port.friendlyName || port.path,
      path: port.path,
      type: "serial",
      ip: process.platform === "win32" 
        ? `COM:${port.path}:9600:8:N:1`
        : `SERIAL:${port.path}:9600:8:N:1`,
      confidence: port.manufacturer ? "high" : "medium",
      vendorId: port.vendorId,
      productId: port.productId,
      baudRates: [9600, 19200, 38400, 57600, 115200], // Baudrates courants pour ESC/POS
      manufacturer: port.manufacturer,
    }));

    return {
      success: true,
      printers: detectedPorts,
      note: `${detectedPorts.length} port(s) série détecté(s)`,
    };
  } catch (error) {
    return {
      success: false,
      error: error.message || "Erreur lors de la détection des ports série",
      printers: [],
    };
  }
}

/**
 * Scan complet : réseau + Serial + USB + IPP + HTTP + LPD + mDNS + Bluetooth + SNMP
 * Toutes les méthodes supportent le backend distant
 * @param {object} options
 * @returns {Promise<object>}
 */
export async function fullPrinterScan(options = {}) {
  const {
    scanNetwork = true,
    scanSerial = true, // Détection intelligente des ports série
    scanUSB = true,
    scanIPP = true,
    scanHTTP = true,
    scanLPD = true,
    scanMDNS = true,
    scanBluetooth = true,
    scanSNMP = false, // SNMP désactivé par défaut (plus lent)
    networkBase = null,
    startHost = 1,
    endHost = 254,
    scanAllPorts = false, // Si true, scanne tous les ports (9100, 631, 515, 80, 443)
    snmpCommunity = "public", // Communauté SNMP
    intelligentDetection = true, // Détection intelligente (détecte modèle, vendor, etc.)
  } = options;
  
  const results = {
    network: { printers: [], error: null },
    serial: { printers: [], error: null }, // Ports série intelligents
    usb: { printers: [], error: null },
    mdns: { printers: [], error: null },
    bluetooth: { printers: [], error: null },
    snmp: { printers: [], error: null },
  };
  
  // Scan réseau (RAW TCP/IP)
  if (scanNetwork) {
    try {
      const networkResult = await scanNetworkForPrinters(
        networkBase,
        startHost,
        endHost,
        scanAllPorts ? null : 9100,
        1000
      );
      if (networkResult.success) {
        results.network.printers = networkResult.printers;
      } else {
        results.network.error = networkResult.error;
      }
    } catch (error) {
      results.network.error = error.message;
    }
  }
  
  // Scan IPP (si activé et scanAllPorts)
  if (scanIPP && scanAllPorts) {
    try {
      // IPP est déjà inclus dans scanNetworkForPrinters si scanAllPorts est true
      // Sinon, scanner séparément
      if (!scanAllPorts && networkBase) {
        const ippPrinters = [];
        for (let host = startHost; host <= Math.min(startHost + 10, endHost); host++) {
          const ip = `${networkBase}.${host}`;
          const result = await checkIPPPrinter(ip, 631, 1000);
          if (result.found) {
            ippPrinters.push({
              ip: `IPP:http://${result.ip}:${result.port}/ipp/print`,
              port: result.port,
              type: "network",
              protocol: "ipp",
              name: `IPP Printer ${result.ip}`,
              confidence: result.confidence,
            });
          }
        }
        results.network.printers.push(...ippPrinters);
      }
    } catch (error) {
      console.warn("IPP scan error:", error.message);
    }
  }
  
  // Scan ports série intelligents
  if (scanSerial) {
    try {
      const serialResult = await detectSerialPorts();
      if (serialResult.success) {
        results.serial.printers = serialResult.printers;
      } else {
        results.serial.error = serialResult.error;
      }
    } catch (error) {
      results.serial.error = error.message;
    }
  }
  
  // Scan USB
  if (scanUSB) {
    try {
      const usbResult = await detectUSBPrinters();
      if (usbResult.success) {
        results.usb.printers = usbResult.printers;
      } else {
        results.usb.error = usbResult.error;
      }
    } catch (error) {
      results.usb.error = error.message;
    }
  }

  // Scan mDNS/Bonjour
  if (scanMDNS) {
    try {
      const mdnsResult = await detectMDNSPrinters();
      if (mdnsResult.success) {
        results.mdns.printers = mdnsResult.printers;
      } else {
        results.mdns.error = mdnsResult.error;
      }
    } catch (error) {
      results.mdns.error = error.message;
    }
  }

  // Scan Bluetooth
  if (scanBluetooth) {
    try {
      const btResult = await detectBluetoothPrinters();
      if (btResult.success) {
        results.bluetooth.printers = btResult.printers;
      } else {
        results.bluetooth.error = btResult.error;
      }
    } catch (error) {
      results.bluetooth.error = error.message;
    }
  }

  // Scan SNMP
  if (scanSNMP) {
    try {
      const snmpResult = await detectSNMPPrinters(networkBase, snmpCommunity);
      if (snmpResult.success) {
        results.snmp.printers = snmpResult.printers;
      } else {
        results.snmp.error = snmpResult.error;
      }
    } catch (error) {
      results.snmp.error = error.message;
    }
  }
  
  // Combiner tous les résultats et éliminer les doublons intelligemment
  const allPrinters = [
    ...results.network.printers,
    ...results.serial.printers,
    ...results.usb.printers,
    ...results.mdns.printers,
    ...results.bluetooth.printers,
    ...results.snmp.printers,
  ];

  // Éliminer les doublons intelligemment (même IP/port ou même nom)
  const uniquePrinters = [];
  const seenKeys = new Set();
  
  for (const printer of allPrinters) {
    // Créer une clé unique basée sur IP/port ou nom
    const key = printer.ip || `${printer.host || printer.address}:${printer.port || ""}` || printer.name;
    
    if (!seenKeys.has(key)) {
      seenKeys.add(key);
      uniquePrinters.push(printer);
    } else {
      // Si doublon trouvé, garder celui avec la meilleure confiance
      const existingIndex = uniquePrinters.findIndex(p => 
        (p.ip || `${p.host || p.address}:${p.port || ""}` || p.name) === key
      );
      if (existingIndex >= 0) {
        const existing = uniquePrinters[existingIndex];
        const confidenceOrder = { high: 3, medium: 2, low: 1 };
        if ((confidenceOrder[printer.confidence] || 0) > (confidenceOrder[existing.confidence] || 0)) {
          uniquePrinters[existingIndex] = printer;
        }
      }
    }
  }
  
  return {
    success: true,
    printers: uniquePrinters,
    details: results,
    totalFound: uniquePrinters.length,
    protocolsDetected: [...new Set(uniquePrinters.map(p => p.protocol || p.type).filter(Boolean))],
    duplicatesRemoved: allPrinters.length - uniquePrinters.length,
  };
}

/**
 * Teste une imprimante détectée pour confirmer qu'elle fonctionne
 * @param {object} printer - {ip, port, type}
 * @returns {Promise<{ok: boolean, error?: string, details?: object}>}
 */
export async function testDetectedPrinter(printer) {
  try {
    if (printer.type === "network") {
      // Envoyer une commande ESC/POS de test
      const testData = Buffer.from("\x1b@\x1dV\x00", "ascii"); // Init + Cut
      const result = await sendToNetworkPrinter(printer.ip, printer.port || 9100, testData, 3000);
      
      return {
        ok: result.ok,
        error: result.error,
        details: {
          responseTime: printer.responseTime,
          confidence: printer.confidence,
        },
      };
    }
    
    return { ok: false, error: "Type d'imprimante non supporté pour le test" };
  } catch (error) {
    return { ok: false, error: error.message };
  }
}

/**
 * Suggère la configuration appropriée pour une imprimante détectée
 * @param {object} printer - Imprimante détectée
 * @param {string} restaurantId - ID du restaurant
 * @returns {object} - Configuration suggérée
 */
/**
 * Détecte automatiquement la largeur de papier selon le modèle d'imprimante
 * @param {string} model - Modèle d'imprimante
 * @param {string} vendor - Fabricant
 * @returns {number} - 58 ou 80 mm
 */
function detectPaperWidth(model, vendor) {
  if (!model && !vendor) return 80; // Par défaut
  
  const modelStr = (model || "").toLowerCase();
  const vendorStr = (vendor || "").toLowerCase();
  
  // Modèles connus 58mm
  const models58mm = ["tm-t20", "tm-t82", "tm-t88", "xp-80", "rp-80", "sp-200"];
  if (models58mm.some(m => modelStr.includes(m))) {
    return 58;
  }
  
  // Modèles connus 80mm
  const models80mm = ["tm-t70", "tm-t90", "xp-90", "rp-90"];
  if (models80mm.some(m => modelStr.includes(m))) {
    return 80;
  }
  
  // Par défaut selon le fabricant
  if (vendorStr.includes("epson")) return 80;
  if (vendorStr.includes("star")) return 58;
  
  return 80; // Par défaut
}

/**
 * Suggère le type d'imprimante (caisse, cuisine, bar) selon le nom
 * @param {string} name - Nom de l'imprimante
 * @returns {string} - "caisse", "cuisine", "bar", ou "general"
 */
function suggestPrinterType(name) {
  if (!name) return "general";
  
  const nameLower = name.toLowerCase();
  
  if (/caisse|cash|register|pos/i.test(nameLower)) {
    return "caisse";
  }
  if (/cuisine|kitchen|cook/i.test(nameLower)) {
    return "cuisine";
  }
  if (/bar|drink|boisson/i.test(nameLower)) {
    return "bar";
  }
  
  return "general";
}

export function suggestPrinterConfiguration(printer, restaurantId) {
  // Construire un nom intelligent
  let suggestedName = printer.name || `Imprimante ${printer.ip || printer.name}`;
  if (printer.vendor && printer.model) {
    suggestedName = `${printer.vendor} ${printer.model}`;
  } else if (printer.vendor) {
    suggestedName = `${printer.vendor} Printer`;
  }
  
  const suggestions = {
    name: suggestedName,
    restaurant_id: restaurantId,
    type: suggestPrinterType(printer.name || suggestedName), // Détection automatique intelligente
    ip: printer.ip,
    port: printer.port || 9100,
    is_enabled: printer.confidence === "high" || printer.confidence === "medium",
    paper_width_mm: detectPaperWidth(printer.model, printer.vendor), // Détection automatique intelligente
  };
  
  // Suggestions intelligentes basées sur le type et le protocole
  if (printer.type === "network") {
    const protocol = printer.protocol || "raw";
    if (protocol === "ipp") {
      const host = printer.ip.replace(/^IPP:/i, "").split("/")[2] || printer.host;
      suggestions.name = `${printer.vendor || "IPP"} ${host}`;
      suggestions.ip = printer.ip; // Garder le format IPP:url
    } else if (protocol === "http") {
      const host = printer.ip.replace(/^HTTP:/i, "").split("/")[2] || printer.host;
      suggestions.name = `${printer.vendor || "HTTP"} ${host}`;
      suggestions.ip = printer.ip; // Garder le format HTTP:url
    } else if (protocol === "lpd") {
      const host = printer.ip.replace(/^LPD:/i, "").split(":")[0] || printer.host;
      suggestions.name = `LPD ${host}`;
      suggestions.ip = printer.ip; // Garder le format LPD:ip:queue
    } else {
      // Réseau RAW
      if (printer.vendor && printer.model) {
        suggestions.name = `${printer.vendor} ${printer.model}`;
      } else {
        suggestions.name = `Réseau ${printer.ip}`;
      }
    }
  } else if (printer.type === "serial") {
    suggestions.name = printer.name || `Série ${printer.path}`;
    suggestions.ip = printer.ip; // Format COM:port:config ou SERIAL:path:config
    suggestions.port = 9100; // Ignoré mais requis
  } else if (printer.type === "serial") {
    suggestions.name = printer.name || `Série ${printer.path}`;
    suggestions.ip = printer.ip; // Format COM:port:config ou SERIAL:path:config
    suggestions.port = 9100; // Ignoré mais requis
  } else if (printer.type === "usb") {
    suggestions.name = printer.name || `USB ${printer.vendorId}:${printer.productId}`;
    suggestions.ip = printer.ip; // Format USB:vendorId:productId
    suggestions.port = 9100; // Ignoré pour USB mais requis par le modèle
  } else if (printer.type === "mdns") {
    suggestions.name = printer.name || `mDNS ${printer.host}`;
    suggestions.ip = printer.ip; // Format MDNS:nom
    suggestions.port = printer.port || 9100;
  } else if (printer.type === "bluetooth") {
    suggestions.name = printer.name || `Bluetooth ${printer.address}`;
    suggestions.ip = printer.ip; // Format BT:MAC
    suggestions.port = 9100; // Ignoré mais requis
  }
  
  return {
    ...suggestions,
    confidence: printer.confidence || "medium",
    detectedType: printer.type,
    protocol: printer.protocol || "raw",
    model: printer.model,
    vendor: printer.vendor,
  };
}
