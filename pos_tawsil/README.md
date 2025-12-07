# POS Tawsil – Documentation fonctionnelle

## 1. Présentation générale
- POS Flutter compilable sur PC/tablette.
- Partage le même menu que les apps Restaurant & Client via une base centralisée.
- Fonctionne offline avec stockage local + resynchronisation auto dès que la connexion revient.

## 2. Fonctionnalités principales
### A. Gestion du menu (centralisé)
- Ajouter / modifier / supprimer un item.
- Toute modification est immédiatement reflétée dans :
  - App Restaurant
  - App Client
  - POS

### B. Prise de commandes
1. Sélection du caissier avant la commande.
2. Ajout des produits (avec suppléments/additions).
3. Envoi de la commande.
4. Bonus :
   - Impression du ticket après chaque commande.
   - Ouverture du tiroir-caisse pour encaisser.

### C. Gestion des caissiers
- Chaque commande est associée à un caissier identifié.
- Choix du caissier dans une liste avant de prendre une commande.

### D. Mode Offline / Online
- **Online** : données enregistrées directement dans la base distante.
- **Offline** : données stockées localement (SQLite).
- **Sync auto** : dès que la connexion revient, toutes les données locales sont synchronisées (menu + commandes).

## 3. Résumé ultra court
1. Menu partagé : POS ↔ App Restaurant ↔ App Client.
2. Identification des caissiers : chaque commande a un caissier.
3. Mode offline : stockage local + synchro auto.
4. Tickets & caisse : impression + ouverture tiroir après commande.
