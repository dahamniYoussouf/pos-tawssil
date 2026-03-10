#!/bin/bash

# VPS Configuration
VPS_HOST="197.140.29.107"
VPS_USER="root"
VPS_PASSWORD="M$$SLA%#7L5H"
APP_PATH="/var/www/tawssilbackyou"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Starting deployment to VPS...${NC}"

# Install sshpass if not available
if ! command -v sshpass &> /dev/null; then
    echo "Installing sshpass..."
    sudo apt-get install -y sshpass
fi

# Create SSH key for passwordless login
echo -e "${BLUE}Setting up SSH connection...${NC}"
sshpass -p "$VPS_PASSWORD" ssh-copy-id -o StrictHostKeyChecking=no $VPS_USER@$VPS_HOST 2>/dev/null || true

# Sync code to VPS
echo -e "${BLUE}Syncing code to VPS...${NC}"
sshpass -p "$VPS_PASSWORD" rsync -avz --delete \
  --exclude 'node_modules' \
  --exclude '.git' \
  --exclude '.env' \
  --exclude 'mock-receipts' \
  --exclude 'public/uploads' \
  ./ $VPS_USER@$VPS_HOST:$APP_PATH/

# Deploy on VPS
echo -e "${BLUE}Running deployment commands on VPS...${NC}"
sshpass -p "$VPS_PASSWORD" ssh -o StrictHostKeyChecking=no $VPS_USER@$VPS_HOST << 'EOF'
cd /var/www/tawssilbackyou

# Install dependencies
npm install

# Restart application
pm2 restart tawssilbackyou || pm2 start index.js --name tawssilbackyou

# Show status
pm2 status

echo "Deployment completed!"
EOF

echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo -e "${GREEN}Application URL: http://197.140.29.107${NC}"
