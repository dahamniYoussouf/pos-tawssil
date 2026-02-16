#!/bin/bash

# Script Bash pour lancer le backend, le dashboard et l'application Flutter en mode web

echo "🚀 Démarrage de tous les services..."
echo ""

# Chemin du projet racine
ROOT_PATH=$(cd "$(dirname "$0")/.." && pwd)
BACKEND_PATH="$ROOT_PATH/tawssilbackyou"
DASHBOARD_PATH="$ROOT_PATH/tawssilfrontyou/tawsil-admin"
FLUTTER_PATH="$(cd "$(dirname "$0")" && pwd)"

# Fonction pour vérifier si un port est utilisé
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        echo "⚠️  Port $port est déjà utilisé"
    else
        echo "✅ Port $port disponible"
    fi
}

# Vérifier les ports
echo "📋 Vérification des ports..."
check_port 8000
check_port 3000
echo ""

# Démarrer le backend
echo "🔧 Démarrage du backend (port 8000)..."
cd "$BACKEND_PATH"
PORT=8000 npm start > /dev/null 2>&1 &
BACKEND_PID=$!
sleep 3

# Démarrer le dashboard admin (Next.js)
echo "📊 Démarrage du dashboard admin Next.js (port 3000)..."
cd "$DASHBOARD_PATH"
PORT=3000 npm run dev > /dev/null 2>&1 &
DASHBOARD_PID=$!
sleep 3

# Démarrer l'application Flutter en mode web
echo "📱 Démarrage de l'application Flutter en mode web..."
cd "$FLUTTER_PATH"
flutter run -d chrome --web-port=8080 &
FLUTTER_PID=$!

echo ""
echo "✅ Tous les services ont été lancés!"
echo ""
echo "📍 URLs:"
echo "  - Backend API: http://localhost:8000"
echo "  - Dashboard Admin: http://localhost:3000"
echo "  - App Flutter Web: http://localhost:8080"
echo ""
echo "💡 Pour arrêter tous les services, appuyez sur Ctrl+C"

# Fonction de nettoyage
cleanup() {
    echo ""
    echo "🛑 Arrêt des services..."
    kill $BACKEND_PID 2>/dev/null
    kill $DASHBOARD_PID 2>/dev/null
    kill $FLUTTER_PID 2>/dev/null
    exit 0
}

trap cleanup SIGINT SIGTERM

# Attendre indéfiniment
wait
