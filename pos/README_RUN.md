# Guide d'Exécution du POS Tawsil

Ce guide explique comment lancer le POS Tawsil avec différents scénarios pour tester tous les cas réels.

## 🚀 Lancement Rapide

### Mode Normal (Web)
```powershell
.\run_pos.ps1 normal
```
Lance l'application en mode web (Chrome) sur le port 8081.

## Deploiement VPS (chemin /pos)

Si le site est servi sur `https://votre-domaine/pos/`, le build web doit
utiliser un base href `"/pos/"`. Sinon les assets chargent en `"/"` et la
page reste blanche.

Commande:
```powershell
flutter build web --release --base-href /pos/
```

### Mode Debug
```powershell
.\run_pos.ps1 debug
```
Lance l'application avec les logs détaillés pour le débogage.

### Mode Android
```powershell
.\run_pos.ps1 android
```
Lance l'application sur un appareil ou émulateur Android connecté.

### Mode iOS (macOS uniquement)
```powershell
.\run_pos.ps1 ios
```
Lance l'application sur un appareil ou simulateur iOS.

## 🧪 Tests de Scénarios Réels

### Test de Détection Réseau
```powershell
.\test_scenarios.ps1 network-detection
```
Teste la détection du réseau local et affiche les interfaces réseau.

### Test de Scan d'Imprimantes
```powershell
.\test_scenarios.ps1 printer-scan
```
Teste le scan automatique d'imprimantes sur le réseau local.

### Test d'IP Spécifique
```powershell
.\test_scenarios.ps1 ip-test
```
Permet de tester une adresse IP d'imprimante spécifique.

### Diagnostics Complets
```powershell
.\test_scenarios.ps1 diagnostics
```
Affiche toutes les informations de diagnostic système.

### Tous les Tests
```powershell
.\test_scenarios.ps1 all
```
Exécute tous les tests de scénarios.

## 📋 Scénarios de Test Disponibles

### 1. Scénario Normal
- Réseau détecté
- WiFi connecté
- IP assignée
- Imprimantes accessibles

**Commande:**
```powershell
.\run_pos.ps1 normal
```

### 2. Scénario Sans Réseau
- Simule un problème de détection réseau
- Teste les messages d'erreur
- Teste les boutons de diagnostic

**Commande:**
```powershell
.\run_pos.ps1 no-network
```

### 3. Scénario Debug
- Logs détaillés
- Hot reload activé
- Outils de développement

**Commande:**
```powershell
.\run_pos.ps1 debug
```

## 🔍 Tests de Diagnostic dans l'Application

Une fois l'application lancée:

1. **Accéder au Diagnostic Réseau:**
   - Menu principal → "Diagnostic"
   - OU: Imprimantes → Icône "Diagnostic" (bug)

2. **Tests Disponibles:**
   - **Permissions** - Teste les permissions réseau
   - **Mode Avion** - Vérifie si le mode avion est activé
   - **WiFi** - Teste la connexion WiFi et l'assignation IP
   - **DHCP** - Vérifie l'assignation DHCP
   - **Loopback** - Vérifie les interfaces loopback
   - **Lancer tous les tests** - Exécute tous les tests automatiquement

3. **Test d'IP Manuelle:**
   - Entrez l'IP de l'imprimante
   - Le système teste automatiquement les ports: 9100, 9101, 631, 515, 80, 443
   - Affiche les résultats avec le port suggéré pour l'impression

## 🖨️ Tests d'Imprimantes

### Test d'une Imprimante Connue

1. Dans l'application, allez dans "Imprimantes"
2. Cliquez sur l'icône "Tester IP" (globe)
3. Entrez l'adresse IP de l'imprimante (ex: 192.168.1.10)
4. Le système teste automatiquement tous les ports
5. Sélectionnez l'imprimante détectée et configurez-la

### Test depuis PowerShell

```powershell
# Test d'une IP spécifique
.\test_scenarios.ps1 ip-test

# Entrez l'IP quand demandé (ex: 192.168.1.10)
```

## 📱 Exécution sur Appareils

### Android

1. **Activer le USB Debugging:**
   - Paramètres → À propos du téléphone
   - Appuyez 7 fois sur "Numéro de build"
   - Paramètres → Options développeur → USB Debugging

2. **Connecter l'appareil:**
   ```powershell
   # Vérifier la connexion
   adb devices
   
   # Lancer l'application
   .\run_pos.ps1 android
   ```

### iOS (macOS uniquement)

1. **Ouvrir Xcode:**
   - Xcode → Preferences → Accounts
   - Ajouter votre compte Apple Developer

2. **Lancer le simulateur:**
   ```powershell
   # Voir les simulateurs disponibles
   flutter emulators
   
   # Lancer l'application
   .\run_pos.ps1 ios
   ```

## 🐛 Résolution de Problèmes

### Problème: Port déjà utilisé
```powershell
# Trouver le processus utilisant le port
Get-NetTCPConnection -LocalPort 8081

# Arrêter le processus
Stop-Process -Id <PID> -Force
```

### Problème: Flutter non trouvé
```powershell
# Vérifier l'installation
flutter doctor

# Ajouter Flutter au PATH si nécessaire
```

### Problème: Aucun appareil détecté
```powershell
# Vérifier les appareils
flutter devices

# Pour Android, vérifier ADB
adb devices

# Pour iOS, vérifier les simulateurs
flutter emulators
```

## 📊 Logs et Debugging

### Voir les logs en temps réel
```powershell
# Mode debug avec logs
.\run_pos.ps1 debug
```

### Logs dans l'application
- L'écran de diagnostic affiche tous les logs en temps réel
- Les logs sont horodatés et colorés (vert = succès, rouge = erreur)

## 🔧 Configuration Avancée

### Changer le port web
Modifiez `run_pos.ps1` ligne 76:
```powershell
Start-WebMode -Port 8082  # Changez le port ici
```

### Mode Release (production)
```powershell
# Dans run_pos.ps1, changez:
$debugFlag = "--release"  # Au lieu de "--debug"
```

## 📝 Notes Importantes

1. **Première exécution:**
   - Les dépendances Flutter seront installées automatiquement
   - La première compilation peut prendre plusieurs minutes

2. **Hot Reload:**
   - En mode debug, appuyez sur `r` dans le terminal Flutter pour recharger
   - Appuyez sur `R` pour redémarrer complètement

3. **Arrêt de l'application:**
   - Appuyez sur `Ctrl+C` dans le terminal Flutter
   - OU fermez la fenêtre du navigateur/appareil

## 🆘 Aide

Pour voir toutes les options disponibles:
```powershell
.\run_pos.ps1 help
.\test_scenarios.ps1 help
```
