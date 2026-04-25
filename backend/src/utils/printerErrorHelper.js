/**
 * Helper pour analyser les erreurs d'impression et fournir des messages détaillés avec solutions
 */

export function analyzePrinterError(error, printer) {
  const errorString = String(error || '').toLowerCase();
  const errorMessage = String(error || '');

  // Détecter le type d'erreur
  if (errorString.includes('timeout') || errorString.includes('timed out')) {
    return {
      type: 'timeout',
      userMessage: 'Connexion à l\'imprimante expirée',
      detailedMessage: `Impossible de se connecter à ${printer.name} (${printer.ip}:${printer.port}) dans le délai imparti.`,
      solutions: getTimeoutSolutions(printer),
    };
  }

  if (errorString.includes('connection refused') || 
      errorString.includes('connection reset') ||
      errorString.includes('refused') ||
      errorString.includes('econnrefused')) {
    return {
      type: 'connection_refused',
      userMessage: 'Connexion refusée',
      detailedMessage: `L'imprimante ${printer.name} refuse la connexion sur ${printer.ip}:${printer.port}.`,
      solutions: getConnectionRefusedSolutions(printer),
    };
  }

  if (errorString.includes('host not found') || 
      errorString.includes('no address') ||
      errorString.includes('unreachable') ||
      errorString.includes('network is unreachable') ||
      errorString.includes('enotfound') ||
      errorString.includes('ehostunreach')) {
    return {
      type: 'host_not_found',
      userMessage: 'Imprimante introuvable',
      detailedMessage: `Impossible de trouver l'imprimante ${printer.name} à l'adresse ${printer.ip}.`,
      solutions: getHostNotFoundSolutions(printer),
    };
  }

  if (errorString.includes('port') && 
      (errorString.includes('not found') || errorString.includes('unavailable'))) {
    return {
      type: 'port_not_found',
      userMessage: 'Port introuvable',
      detailedMessage: `Le port ${printer.port} n'est pas disponible sur ${printer.ip}.`,
      solutions: getPortNotFoundSolutions(printer),
    };
  }

  if (errorString.includes('socket') || 
      errorString.includes('network') ||
      errorString.includes('econnreset') ||
      errorString.includes('etimedout')) {
    return {
      type: 'network_error',
      userMessage: 'Erreur réseau',
      detailedMessage: `Erreur de communication réseau avec ${printer.name}.`,
      solutions: getNetworkErrorSolutions(printer),
    };
  }

  // Erreur générique
  return {
    type: 'unknown',
    userMessage: 'Erreur d\'impression',
    detailedMessage: `Une erreur s'est produite lors de l'impression sur ${printer.name}.`,
    solutions: getGenericSolutions(printer),
  };
}

// Fonction obsolète - toutes les méthodes supportent maintenant le backend distant
// Conservée pour compatibilité mais toujours retourne true
// @deprecated Utiliser directement les solutions sans condition
function isNetworkPrinter(ip) {
  return true;
}

function getTimeoutSolutions(printer) {
  const solutions = [];
  
  // Toutes les méthodes supportent maintenant le backend distant
  solutions.push(
    '1. Vérifiez que l\'imprimante est allumée et connectée',
    '2. Vérifiez la connexion réseau : ping ' + printer.ip + ' depuis un terminal',
    '3. Vérifiez que le port ' + printer.port + ' est ouvert (généralement 9100 pour les imprimantes réseau)',
    '4. Vérifiez les paramètres réseau de l\'imprimante (IP statique vs DHCP)',
    '5. Vérifiez que le firewall n\'bloque pas le port ' + printer.port,
    '6. Testez la connexion depuis un autre appareil sur le même réseau',
    '7. Pour les imprimantes réseau: vérifiez que le backend peut atteindre l\'IP de l\'imprimante',
    '8. Pour les imprimantes USB/Serial: vérifiez que l\'imprimante est correctement configurée'
  );
  
  return solutions;
}

function getConnectionRefusedSolutions(printer) {
  const solutions = [];
  
  // Toutes les méthodes supportent maintenant le backend distant
  solutions.push(
    '1. Vérifiez que l\'imprimante réseau est activée et prête',
    '2. Vérifiez que le service d\'impression réseau est activé sur l\'imprimante',
    '3. Vérifiez les paramètres réseau de l\'imprimante (IP: ' + printer.ip + ', Port: ' + printer.port + ')',
    '4. Vérifiez que le port ' + printer.port + ' est bien configuré (généralement 9100)',
    '5. Redémarrez l\'imprimante réseau',
    '6. Vérifiez que le backend peut atteindre l\'imprimante (même réseau ou VPN)',
    '7. Pour les imprimantes USB/Serial: vérifiez que l\'imprimante est correctement connectée au serveur backend'
  );
  
  return solutions;
}

function getHostNotFoundSolutions(printer) {
  const solutions = [];
  
  // Toutes les méthodes supportent maintenant le backend distant
  solutions.push(
    '1. Vérifiez l\'adresse IP de l\'imprimante : ' + printer.ip,
    '2. Imprimez une page de test depuis l\'imprimante pour voir son adresse IP actuelle',
    '3. Vérifiez que l\'IP n\'a pas changé (si DHCP, configurez une IP statique)',
    '4. Vérifiez la connexion réseau : ping ' + printer.ip + ' depuis le serveur backend',
    '5. Vérifiez que le backend peut atteindre l\'imprimante (même réseau ou VPN)',
    '6. Vérifiez les paramètres réseau de l\'imprimante (Wi-Fi/Ethernet)',
    '7. Pour les imprimantes USB/Serial: vérifiez que l\'imprimante est connectée au serveur backend',
    '8. Si le backend est en cloud et l\'imprimante est locale: utilisez un tunnel VPN ou une imprimante réseau accessible depuis Internet'
  );
  
  return solutions;
}

function getPortNotFoundSolutions(printer) {
  const solutions = [];
  
  // Toutes les méthodes supportent maintenant le backend distant
  solutions.push(
    '1. Vérifiez que le port ' + printer.port + ' est correct (généralement 9100 pour RAW)',
    '2. Vérifiez les paramètres réseau de l\'imprimante pour confirmer le port',
    '3. Testez avec telnet : telnet ' + printer.ip + ' ' + printer.port,
    '4. Vérifiez que le firewall n\'bloque pas le port ' + printer.port,
    '5. Essayez le port 9100 si vous utilisez un autre port'
  );
  
  return solutions;
}

function getNetworkErrorSolutions(printer) {
  const solutions = [];
  
  // Toutes les méthodes supportent maintenant le backend distant
  solutions.push(
    '1. Vérifiez votre connexion Internet/réseau',
    '2. Vérifiez que le backend peut atteindre l\'imprimante (même réseau ou VPN)',
    '3. V�rifiez les c�bles r�seau (si Ethernet) ou le signal Wi-Fi',
    '4. Redémarrez le routeur/switch réseau',
    '5. Vérifiez que l\'imprimante n\'est pas en mode veille',
    '6. Testez depuis le serveur backend: ping ' + printer.ip,
    '7. Pour les imprimantes USB/Serial: vérifiez que l\'imprimante est connectée au serveur backend',
    '8. Si le backend est en cloud et l\'imprimante est locale: utilisez un tunnel VPN ou une imprimante réseau accessible depuis Internet'
  );
  
  return solutions;
}

function getGenericSolutions(printer) {
  const solutions = [];
  
  // Toutes les méthodes supportent maintenant le backend distant
  solutions.push(
    '1. Vérifiez que l\'imprimante est allumée et connectée',
    '2. Vérifiez l\'adresse IP : ' + printer.ip + ':' + printer.port,
    '3. Testez la connexion réseau : ping ' + printer.ip,
    '4. Vérifiez les paramètres de l\'imprimante',
    '5. Redémarrez l\'imprimante',
    '6. Vérifiez que le backend peut atteindre l\'imprimante (réseau, USB, Serial, etc.)',
    '7. Contactez le support si le problème persiste'
  );
  
  return solutions;
}
