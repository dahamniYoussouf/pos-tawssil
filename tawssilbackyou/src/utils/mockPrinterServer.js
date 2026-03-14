/**
 * Serveur Mock d'Imprimante ESC/POS pour les tests
 * Simule une imprimante réseau sur le port 9100
 * Affiche les tickets reçus dans la console et les sauvegarde dans un fichier
 */

import net from "net";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const PORT = 9100;
const RECEIPTS_DIR = path.join(__dirname, "..", "..", "mock-receipts");

// Créer le dossier de sauvegarde s'il n'existe pas
if (!fs.existsSync(RECEIPTS_DIR)) {
  fs.mkdirSync(RECEIPTS_DIR, { recursive: true });
}

/**
 * Parse les commandes ESC/POS et convertit en texte lisible
 */
function parseEscPos(buffer) {
  let text = "";
  let i = 0;
  let isBold = false;
  let align = "left"; // left, center, right

  while (i < buffer.length) {
    const byte = buffer[i];

    // ESC @ - Initialize printer
    if (byte === 0x1b && i + 1 < buffer.length && buffer[i + 1] === 0x40) {
      i += 2;
      continue;
    }

    // ESC a - Select justification
    if (byte === 0x1b && i + 1 < buffer.length && buffer[i + 1] === 0x61) {
      if (i + 2 < buffer.length) {
        const justify = buffer[i + 2];
        if (justify === 0) align = "left";
        else if (justify === 1) align = "center";
        else if (justify === 2) align = "right";
        i += 3;
      } else {
        i++;
      }
      continue;
    }

    // ESC E - Bold
    if (byte === 0x1b && i + 1 < buffer.length && buffer[i + 1] === 0x45) {
      if (i + 2 < buffer.length) {
        isBold = buffer[i + 2] === 1;
        i += 3;
      } else {
        i++;
      }
      continue;
    }

    // GS V - Cut paper
    if (byte === 0x1d && i + 1 < buffer.length && buffer[i + 1] === 0x56) {
      text += "\n---[COUPE]---\n";
      i += 2;
      continue;
    }

    // LF - Line feed
    if (byte === 0x0a) {
      text += "\n";
      i++;
      continue;
    }

    // Caractère imprimable (ASCII 32-126)
    if (byte >= 32 && byte <= 126) {
      text += String.fromCharCode(byte);
    } else if (byte === 0x09) {
      // Tab
      text += "  ";
    }

    i++;
  }

  return text;
}

/**
 * Démarre le serveur mock d'imprimante
 */
export function startMockPrinterServer(port = PORT) {
  const server = net.createServer((socket) => {
    const clientAddress = socket.remoteAddress;
    const clientPort = socket.remotePort;
    console.log(`\n🖨️  [Mock Printer] Client connecté: ${clientAddress}:${clientPort}`);

    let dataBuffer = Buffer.alloc(0);
    const startTime = Date.now();

    socket.on("data", (chunk) => {
      dataBuffer = Buffer.concat([dataBuffer, chunk]);
    });

    socket.on("end", () => {
      const duration = Date.now() - startTime;
      console.log(`📄 [Mock Printer] Données reçues (${dataBuffer.length} bytes, ${duration}ms)`);

      if (dataBuffer.length > 0) {
        // Sauvegarder les données brutes
        const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
        const rawFile = path.join(RECEIPTS_DIR, `receipt-${timestamp}.raw`);
        fs.writeFileSync(rawFile, dataBuffer);

        // Parser et afficher le texte
        const text = parseEscPos(dataBuffer);
        const textFile = path.join(RECEIPTS_DIR, `receipt-${timestamp}.txt`);
        fs.writeFileSync(textFile, text, "utf8");

        console.log("\n" + "=".repeat(50));
        console.log("📋 TICKET REÇU:");
        console.log("=".repeat(50));
        console.log(text);
        console.log("=".repeat(50));
        console.log(`\n💾 Fichiers sauvegardés:`);
        console.log(`   RAW: ${rawFile}`);
        console.log(`   TXT: ${textFile}`);
        console.log("");
      }

      socket.destroy();
    });

    socket.on("error", (err) => {
      console.error(`❌ [Mock Printer] Erreur socket:`, err.message);
    });

    socket.on("close", () => {
      console.log(`🔌 [Mock Printer] Client déconnecté: ${clientAddress}:${clientPort}`);
    });
  });

  server.on("error", (err) => {
    if (err.code === "EADDRINUSE") {
      console.error(`❌ Port ${port} déjà utilisé. Arrêtez l'autre processus ou utilisez un autre port.`);
    } else {
      console.error(`❌ Erreur serveur:`, err.message);
    }
    process.exit(1);
  });

  server.listen(port, () => {
    console.log(`\n✅ Serveur Mock Imprimante ESC/POS démarré`);
    console.log(`   📍 Port: ${port}`);
    console.log(`   🌐 Adresse: localhost:${port} ou 127.0.0.1:${port}`);
    console.log(`   💾 Reçus sauvegardés dans: ${RECEIPTS_DIR}`);
    console.log(`\n   Pour tester, configurez une imprimante avec:`);
    console.log(`   - IP: 127.0.0.1`);
    console.log(`   - Port: ${port}`);
    console.log(`\n   Appuyez sur Ctrl+C pour arrêter\n`);
  });

  return server;
}

/**
 * Arrête le serveur mock
 */
export function stopMockPrinterServer(server) {
  if (server) {
    server.close(() => {
      console.log("\n🛑 Serveur Mock Imprimante arrêté");
    });
  }
}

// Si exécuté directement (node mockPrinterServer.js)
// Vérifier si le fichier est exécuté directement en comparant les chemins
const currentFile = fileURLToPath(import.meta.url);
const executedFile = process.argv[1] ? path.resolve(process.argv[1]) : null;

if (executedFile && currentFile === executedFile) {
  const port = process.argv[2] ? parseInt(process.argv[2], 10) : PORT;
  const server = startMockPrinterServer(port);
  
  process.on("SIGINT", () => {
    console.log("\n\n⏹️  Arrêt du serveur...");
    stopMockPrinterServer(server);
    process.exit(0);
  });

  process.on("SIGTERM", () => {
    stopMockPrinterServer(server);
    process.exit(0);
  });
}
