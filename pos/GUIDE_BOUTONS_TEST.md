# 📍 Guide : Où trouver les boutons et fonctions de test

## 🖨️ Écran des Imprimantes

### Accès
**Menu principal → "Imprimantes"** (icône imprimante dans la sidebar)

### Boutons dans la barre d'outils (en haut à droite) :

1. **🔍 Diagnostic Réseau** (icône bug)
   - **Emplacement** : Barre d'outils, premier bouton à droite
   - **Fonction** : Ouvre l'écran de diagnostic réseau complet
   - **Tooltip** : "Diagnostic réseau"

2. **▶️ Test Rapide** (icône play)
   - **Emplacement** : Barre d'outils, deuxième bouton
   - **Fonction** : Lance le scan automatique du réseau
   - **Tooltip** : "Test rapide (Scan réseau)"

3. **🔎 Scanner** (icône search)
   - **Emplacement** : Barre d'outils, troisième bouton
   - **Fonction** : Scanner le réseau pour trouver des imprimantes
   - **Tooltip** : "Scanner le réseau"

4. **🌐 Tester IP** (icône language) ⭐ **CELUI MENTIONNÉ DANS L'ERREUR**
   - **Emplacement** : Barre d'outils, quatrième bouton
   - **Fonction** : Tester une adresse IP d'imprimante spécifique
   - **Tooltip** : "Tester une IP spécifique"
   - **Comment l'utiliser** :
     1. Cliquez sur l'icône globe (🌐)
     2. Une fenêtre s'ouvre
     3. Entrez l'IP de l'imprimante (ex: 192.168.1.10)
     4. Cliquez sur "Tester"
     5. Le système teste automatiquement les ports 9100, 9101, 80, etc.

---

## 🔧 Écran de Diagnostic Réseau

### Accès
**Menu principal → "Diagnostic"** (icône bug dans la sidebar)
**OU** **Imprimantes → Icône Diagnostic** (icône bug dans la barre d'outils)

### Boutons disponibles :

#### 1. **Bouton "Test Rapide"** (Grand bouton en haut) ⭐
   - **Emplacement** : En haut de l'écran, carte bleue/verte avec icône play
   - **Fonction** : Lance TOUS les tests automatiquement
   - **Tests exécutés** :
     - ✅ Permissions réseau
     - ✅ Mode avion
     - ✅ WiFi
     - ✅ DHCP
     - ✅ Loopback
     - ✅ Détection réseau
   - **Résultat** : Affiche un résumé dans les logs

#### 2. **Boutons de test individuels** (Dans la carte "Détection Réseau")
   - **Emplacement** : Carte "Détection Réseau" → Section "Tests de diagnostic"
   - **Boutons disponibles** :
     - **🔒 Permissions** - Teste les permissions réseau
     - **✈️ Mode Avion** - Vérifie si le mode avion est activé
     - **📶 WiFi** - Teste la connexion WiFi et l'assignation IP
     - **🌐 DHCP** - Vérifie l'assignation DHCP
     - **🔄 Loopback** - Vérifie les interfaces loopback
   - **Fonction** : Chaque bouton teste un composant spécifique
   - **Indicateurs visuels** :
     - 🟢 Vert = Test réussi
     - 🔴 Rouge = Test échoué
     - 🔵 Bleu = Test en cours

#### 3. **Bouton "Lancer tous les tests"**
   - **Emplacement** : Sous les boutons individuels
   - **Fonction** : Lance tous les tests séquentiellement

#### 4. **Champ "Test d'Adresse IP"**
   - **Emplacement** : Carte "Test d'Adresse IP"
   - **Fonction** : Tester une IP d'imprimante spécifique
   - **Comment l'utiliser** :
     1. Entrez l'IP dans le champ (ex: 192.168.1.10)
     2. Cliquez sur l'icône search ou appuyez sur Entrée
     3. Le système teste automatiquement tous les ports
     4. Les résultats s'affichent dans la carte "Résultats du Test"

#### 5. **Boutons dans la barre d'outils** (en haut à droite)
   - **▶️ Play** - Lance tous les tests (même fonction que le grand bouton)
   - **🔄 Refresh** - Actualise l'état de connectivité et la détection réseau

---

## 📋 Résumé des emplacements

### Pour tester une IP d'imprimante spécifique :

**Option 1 : Depuis l'écran des Imprimantes**
1. Menu → "Imprimantes"
2. Cliquez sur l'icône **🌐 (globe)** dans la barre d'outils
3. Entrez l'IP et testez

**Option 2 : Depuis l'écran de Diagnostic**
1. Menu → "Diagnostic"
2. Dans la carte "Test d'Adresse IP"
3. Entrez l'IP et cliquez sur l'icône search

### Pour lancer tous les tests de diagnostic :

**Option 1 : Grand bouton "Test Rapide"**
1. Menu → "Diagnostic"
2. Cliquez sur le **grand bouton bleu/vert "Test Rapide"** en haut

**Option 2 : Bouton Play dans la barre d'outils**
1. Menu → "Diagnostic"
2. Cliquez sur l'icône **▶️ Play** en haut à droite

### Pour scanner le réseau :

1. Menu → "Imprimantes"
2. Cliquez sur l'icône **🔎 (search)** dans la barre d'outils
3. OU cliquez sur **▶️ (play)** pour le test rapide

---

## 🎯 Cas d'usage

### Si vous voyez l'erreur "Impossible de détecter le réseau local" :

1. **Solution rapide** : Utilisez "Tester IP"
   - Imprimantes → Icône **🌐 (globe)**
   - Entrez l'IP de l'imprimante
   - Cette fonction fonctionne même sans détection automatique du réseau

2. **Diagnostic complet** : Allez dans Diagnostic
   - Menu → "Diagnostic"
   - Cliquez sur "Test Rapide"
   - Utilisez les boutons individuels pour identifier le problème

---

## 💡 Astuces

- Le bouton **🌐 "Tester IP"** fonctionne **MÊME** si le réseau n'est pas détecté automatiquement
- Les tests individuels vous permettent d'identifier précisément le problème
- Les logs en bas de l'écran de diagnostic montrent tous les détails en temps réel
- Vous pouvez tester plusieurs IPs d'imprimantes rapidement depuis l'écran de diagnostic
