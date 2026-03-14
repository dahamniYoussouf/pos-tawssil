/**
 * Service de rendu de templates de tickets d'impression
 * Remplace les variables dans les templates par les valeurs réelles
 */

// Commandes ESC/POS de base
const ESC = "\x1b";
const GS = "\x1d";
const LF = "\x0a";

/**
 * Variables disponibles dans les templates :
 * {{restaurantName}} - Nom du restaurant
 * {{orderNumber}} - Numéro de commande
 * {{date}} - Date de la commande (formaté)
 * {{time}} - Heure de la commande
 * {{orderType}} - Type de commande (Livraison/A emporter)
 * {{cashierName}} - Nom du caissier
 * {{cashierCode}} - Code du caissier
 * {{items}} - Liste des items (formatée)
 * {{subtotal}} - Sous-total
 * {{deliveryFee}} - Frais de livraison
 * {{total}} - Total
 * {{paymentMethod}} - Méthode de paiement
 * {{deliveryAddress}} - Adresse de livraison
 * {{footer}} - Message de pied de page
 */

/**
 * Rend un template avec les données d'une commande
 * @param {string} templateContent - Contenu du template avec variables
 * @param {object} order - Commande complète
 * @param {object} options - Options supplémentaires
 * @returns {string} - Contenu rendu
 */
export function renderTemplate(templateContent, order, options = {}) {
  const {
    restaurantName = "Restaurant",
    cashierName = null,
    cashierCode = null,
  } = options;

  let rendered = templateContent;

  // Variables de base
  rendered = rendered.replace(/\{\{restaurantName\}\}/g, restaurantName || "Restaurant");
  rendered = rendered.replace(/\{\{orderNumber\}\}/g, order.order_number || order.id || "-");
  
  // Date et heure
  const orderDate = order.created_at ? new Date(order.created_at) : new Date();
  rendered = rendered.replace(/\{\{date\}\}/g, formatDate(orderDate));
  rendered = rendered.replace(/\{\{time\}\}/g, formatTime(orderDate));

  // Type de commande
  const orderTypeLabel = order.order_type === "delivery" ? "Livraison" : 
                         order.order_type === "pickup" ? "A emporter" : 
                         order.order_type || "Sur place";
  rendered = rendered.replace(/\{\{orderType\}\}/g, orderTypeLabel);

  // Caissier
  rendered = rendered.replace(/\{\{cashierName\}\}/g, cashierName || "-");
  rendered = rendered.replace(/\{\{cashierCode\}\}/g, cashierCode || "-");

  // Items
  const itemsText = formatItems(order.order_items || []);
  rendered = rendered.replace(/\{\{items\}\}/g, itemsText);

  // Totaux
  const subtotal = parseFloat(order.subtotal || 0);
  const deliveryFee = parseFloat(order.delivery_fee || 0);
  const total = parseFloat(order.total_amount || order.subtotal || 0);
  
  rendered = rendered.replace(/\{\{subtotal\}\}/g, formatAmount(subtotal));
  rendered = rendered.replace(/\{\{deliveryFee\}\}/g, formatAmount(deliveryFee));
  rendered = rendered.replace(/\{\{total\}\}/g, formatAmount(total));

  // Paiement
  const paymentMethodLabel = formatPaymentMethod(order.payment_method || order.paymentMethod);
  rendered = rendered.replace(/\{\{paymentMethod\}\}/g, paymentMethodLabel);

  // Adresse
  rendered = rendered.replace(/\{\{deliveryAddress\}\}/g, order.delivery_address || "-");

  // Footer par défaut
  const footer = options.footer || "Merci de votre visite !";
  rendered = rendered.replace(/\{\{footer\}\}/g, footer);

  // Gestion des conditions simples {{#if variable}}
  rendered = rendered.replace(/\{\{#if\s+(\w+)\}\}([\s\S]*?)\{\{\/if\}\}/g, (match, variable, content) => {
    let value = null;
    if (variable === 'deliveryFee') {
      value = deliveryFee > 0;
    }
    // Ajouter d'autres conditions si nécessaire
    return value ? content : '';
  });

  return rendered;
}

/**
 * Formate les items de commande pour l'affichage
 * @param {Array} items - Liste des order_items
 * @returns {string}
 */
function formatItems(items) {
  if (!items || items.length === 0) return "Aucun article";
  
  let itemsText = "";
  for (const item of items) {
    const name = item.menu_item?.nom || item.menu_item_name || "Article";
    const qty = item.quantite ?? item.quantity ?? 1;
    const unitPrice = parseFloat(item.prix_unitaire || item.prixUnitaire || 0);
    const total = parseFloat(item.prix_total || item.prixTotal || unitPrice * qty);
    
    itemsText += `${name} x${qty}\n`;
    itemsText += `  ${formatAmount(total)} DA\n`;
    
    // Instructions spéciales
    if (item.instructions_speciales || item.instructionsSpeciales) {
      itemsText += `  Note: ${item.instructions_speciales || item.instructionsSpeciales}\n`;
    }
    
    // Additions
    const additions = item.additions || [];
    for (const add of additions) {
      const addName = add.addition?.nom || add.nom || "Addition";
      const addQty = add.quantite ?? add.quantity ?? 1;
      const addTotal = parseFloat(add.prix_total || add.prixTotal || 0);
      itemsText += `  + ${addName} x${addQty} (${formatAmount(addTotal)} DA)\n`;
    }
    
    itemsText += "\n";
  }
  
  return itemsText.trim();
}

/**
 * Formate une date
 * @param {Date} date
 * @returns {string}
 */
function formatDate(date) {
  if (!date) return new Date().toLocaleDateString("fr-FR");
  const d = date instanceof Date ? date : new Date(date);
  return isNaN(d.getTime()) ? String(date) : d.toLocaleDateString("fr-FR");
}

/**
 * Formate une heure
 * @param {Date} date
 * @returns {string}
 */
function formatTime(date) {
  if (!date) return new Date().toLocaleTimeString("fr-FR", { hour: '2-digit', minute: '2-digit' });
  const d = date instanceof Date ? date : new Date(date);
  return isNaN(d.getTime()) ? String(date) : d.toLocaleTimeString("fr-FR", { hour: '2-digit', minute: '2-digit' });
}

/**
 * Formate un montant
 * @param {number} amount
 * @returns {string}
 */
function formatAmount(amount) {
  const x = Number(amount);
  return Number.isFinite(x) ? x.toFixed(2) : "0.00";
}

/**
 * Formate une méthode de paiement
 * @param {string} method
 * @returns {string}
 */
function formatPaymentMethod(method) {
  const methods = {
    cash: "Espèces",
    card: "Carte bancaire",
    mobile: "Mobile Payment",
    cash_on_delivery: "Espèces à la livraison",
    cheque: "Chèque",
  };
  return methods[method] || method || "Non spécifié";
}

/**
 * Convertit un template rendu en commandes ESC/POS
 * @param {string} renderedContent - Contenu rendu avec variables remplacées
 * @param {object} options - Options de formatage
 * @returns {Buffer} - Buffer ESC/POS
 */
export function templateToEscPos(renderedContent, options = {}) {
  const {
    paperWidth = 80,
    alignCenter = false,
    bold = false,
  } = options;

  const chunks = [];
  const lines = renderedContent.split('\n');
  
  // Commandes ESC/POS de base
  chunks.push(Buffer.from(ESC + "@", "ascii")); // Init
  
  for (const line of lines) {
    // Détection de commandes spéciales dans le template
    if (line.trim() === '[CENTER]') {
      chunks.push(Buffer.from(ESC + "a" + String.fromCharCode(1), "ascii"));
      continue;
    }
    if (line.trim() === '[LEFT]') {
      chunks.push(Buffer.from(ESC + "a" + String.fromCharCode(0), "ascii"));
      continue;
    }
    if (line.trim() === '[RIGHT]') {
      chunks.push(Buffer.from(ESC + "a" + String.fromCharCode(2), "ascii"));
      continue;
    }
    if (line.trim() === '[BOLD_ON]') {
      chunks.push(Buffer.from(ESC + "E" + String.fromCharCode(1), "ascii"));
      continue;
    }
    if (line.trim() === '[BOLD_OFF]') {
      chunks.push(Buffer.from(ESC + "E" + String.fromCharCode(0), "ascii"));
      continue;
    }
    if (line.trim() === '[HR]') {
      const lineLen = Math.min(paperWidth === 58 ? 32 : 48, 48);
      chunks.push(Buffer.from("-".repeat(lineLen) + LF, "ascii"));
      continue;
    }
    if (line.trim() === '[CUT]') {
      chunks.push(Buffer.from(GS + "V" + String.fromCharCode(0), "ascii"));
      continue;
    }
    if (line.trim() === '[FEED]') {
      chunks.push(Buffer.from(LF, "ascii"));
      continue;
    }
    
    // Ligne normale
    chunks.push(Buffer.from(line + LF, "ascii"));
  }
  
  // Coupe finale si pas déjà présente
  if (!renderedContent.includes('[CUT]')) {
    chunks.push(Buffer.from(GS + "V" + String.fromCharCode(0), "ascii"));
  }
  
  return Buffer.concat(chunks);
}

/**
 * Liste des variables disponibles pour l'aide
 * @returns {Array<{variable: string, description: string}>}
 */
export function getAvailableVariables() {
  return [
    { variable: '{{restaurantName}}', description: 'Nom du restaurant' },
    { variable: '{{orderNumber}}', description: 'Numéro de commande' },
    { variable: '{{date}}', description: 'Date de la commande (format français)' },
    { variable: '{{time}}', description: 'Heure de la commande (HH:MM)' },
    { variable: '{{orderType}}', description: 'Type de commande (Livraison/A emporter)' },
    { variable: '{{cashierName}}', description: 'Nom du caissier' },
    { variable: '{{cashierCode}}', description: 'Code du caissier' },
    { variable: '{{items}}', description: 'Liste formatée des articles avec quantités et prix' },
    { variable: '{{subtotal}}', description: 'Sous-total de la commande' },
    { variable: '{{deliveryFee}}', description: 'Frais de livraison' },
    { variable: '{{total}}', description: 'Total de la commande' },
    { variable: '{{paymentMethod}}', description: 'Méthode de paiement' },
    { variable: '{{deliveryAddress}}', description: 'Adresse de livraison' },
    { variable: '{{footer}}', description: 'Message de pied de page' },
  ];
}

/**
 * Commandes spéciales disponibles
 * @returns {Array<{command: string, description: string}>}
 */
export function getAvailableCommands() {
  return [
    { command: '[CENTER]', description: 'Centrer le texte' },
    { command: '[LEFT]', description: 'Aligner à gauche' },
    { command: '[RIGHT]', description: 'Aligner à droite' },
    { command: '[BOLD_ON]', description: 'Activer le gras' },
    { command: '[BOLD_OFF]', description: 'Désactiver le gras' },
    { command: '[HR]', description: 'Ligne horizontale' },
    { command: '[FEED]', description: 'Saut de ligne' },
    { command: '[CUT]', description: 'Couper le papier' },
  ];
}
