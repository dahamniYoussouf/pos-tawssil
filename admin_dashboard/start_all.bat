@echo off
REM Script pour lancer le backend, le dashboard et l'application Flutter en mode web

echo 🚀 Démarrage de tous les services...
echo.

REM Chemin du projet racine
set "ROOT_PATH=%~dp0.."
set "BACKEND_PATH=%ROOT_PATH%\tawssilbackyou"
set "DASHBOARD_PATH=%ROOT_PATH%\tawssilfrontyou\tawsil-admin"
set "FLUTTER_PATH=%~dp0"

REM Démarrer le backend
echo 🔧 Démarrage du backend (port 8000)...
start "Backend API" cmd /k "cd /d "%BACKEND_PATH%" && set PORT=8000 && npm start"

REM Attendre quelques secondes
timeout /t 3 /nobreak >nul

REM Démarrer le dashboard admin (Next.js)
echo 📊 Démarrage du dashboard admin Next.js (port 3000)...
start "Dashboard Admin" cmd /k "cd /d "%DASHBOARD_PATH%" && set PORT=3000 && npm run dev"

REM Attendre quelques secondes
timeout /t 3 /nobreak >nul

REM Démarrer l'application Flutter en mode web
echo 📱 Démarrage de l'application Flutter en mode web...
start "Flutter Web" cmd /k "cd /d "%FLUTTER_PATH%" && flutter run -d chrome --web-port=8080"

echo.
echo ✅ Tous les services ont été lancés!
echo.
echo 📍 URLs:
echo   - Backend API: http://localhost:8000
echo   - Dashboard Admin: http://localhost:3000
echo   - App Flutter Web: http://localhost:8080
echo.
echo 💡 Fermez les fenêtres pour arrêter les services

pause
