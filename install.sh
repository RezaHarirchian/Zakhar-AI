#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to check for errors
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: $1${NC}"
        exit 1
    fi
}

# Function to check if a command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}Error: $1 is not installed${NC}"
        return 1
    fi
    return 0
}

# Function to get user input with validation
get_user_input() {
    local prompt="$1"
    local validation="$2"
    local input
    
    while true; do
        read -p "$prompt" input
        if [[ $input =~ $validation ]]; then
            echo "$input"
            return 0
        else
            echo -e "${RED}Invalid input. Please try again.${NC}"
        fi
    done
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root${NC}"
    exit 1
fi

echo -e "${GREEN}Starting Zakhar AI Installation...${NC}"

# Check system requirements
echo -e "\n${YELLOW}Checking system requirements...${NC}"

# Check disk space
available_space=$(df / | awk 'NR==2 {print $4}')
if [ "$available_space" -lt 5000000 ]; then
    echo -e "${RED}Error: Insufficient disk space. At least 5GB free space is required.${NC}"
    exit 1
fi

# Check memory
total_mem=$(free -m | awk '/^Mem:/{print $2}')
if [ "$total_mem" -lt 4096 ]; then
    echo -e "${RED}Error: Insufficient memory. At least 4GB RAM is required.${NC}"
    exit 1
fi

# Get user inputs
echo -e "\n${YELLOW}Please provide the following information:${NC}"

# Get OpenAI API Key
OPENAI_API_KEY=$(get_user_input "Enter your OpenAI API Key: " "^sk-[a-zA-Z0-9]{32,}$")
check_error "Failed to get OpenAI API Key"

# Get Telegram Bot Token
TELEGRAM_BOT_TOKEN=$(get_user_input "Enter your Telegram Bot Token: " "^[0-9]{8,10}:[a-zA-Z0-9_-]{35,40}$")
check_error "Failed to get Telegram Bot Token"

# Get Telegram Username
TELEGRAM_USERNAME=$(get_user_input "Enter your Telegram Username (without @): " "^[a-zA-Z0-9_]{5,32}$")
check_error "Failed to get Telegram Username"

# Get Domain Name (optional)
read -p "Enter your domain name (or press Enter to use IP): " DOMAIN_NAME
if [ -z "$DOMAIN_NAME" ]; then
    DOMAIN_NAME=$(curl -s ifconfig.me)
fi

# Update system
echo -e "\n${YELLOW}Updating system...${NC}"
apt update && apt upgrade -y
check_error "Failed to update system"

# Install dependencies
echo -e "\n${YELLOW}Installing dependencies...${NC}"
apt install -y curl git wget build-essential python3 python3-pip nginx
check_error "Failed to install dependencies"

# Install Node.js
echo -e "\n${YELLOW}Installing Node.js...${NC}"
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
apt install -y nodejs
check_error "Failed to install Node.js"

# Install Docker
echo -e "\n${YELLOW}Installing Docker...${NC}"
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
check_error "Failed to install Docker"

# Install Docker Compose
echo -e "\n${YELLOW}Installing Docker Compose...${NC}"
curl -L "https://github.com/docker/compose/releases/download/v2.0.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
check_error "Failed to install Docker Compose"

# Configure firewall
echo -e "\n${YELLOW}Configuring firewall...${NC}"
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp
ufw allow 8000/tcp
ufw allow 6379/tcp
ufw --force enable
check_error "Failed to configure firewall"

# Create project directory
echo -e "\n${YELLOW}Creating project directory...${NC}"
mkdir -p /opt/zakhar
cd /opt/zakhar
check_error "Failed to create project directory"

# Create docker-compose.yml
echo -e "\n${YELLOW}Creating docker-compose.yml...${NC}"
cat > docker-compose.yml << EOL
version: '3.8'

services:
  redis:
    image: redis:latest
    command: redis-server --requirepass \${REDIS_PASSWORD}
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    restart: always
    networks:
      - zakhar_network

  backend:
    image: ghcr.io/RezaHarirchian/Zakhar-AI/backend:latest
    ports:
      - "8000:8000"
    environment:
      - OPENAI_API_KEY=\${OPENAI_API_KEY}
      - TELEGRAM_BOT_TOKEN=\${TELEGRAM_BOT_TOKEN}
      - REDIS_PASSWORD=\${REDIS_PASSWORD}
    depends_on:
      - redis
    restart: always
    networks:
      - zakhar_network

  frontend:
    image: ghcr.io/RezaHarirchian/Zakhar-AI/frontend:latest
    ports:
      - "3000:3000"
    environment:
      - REACT_APP_API_URL=http://localhost:8000
    depends_on:
      - backend
    restart: always
    networks:
      - zakhar_network

networks:
  zakhar_network:
    driver: bridge

volumes:
  redis_data:
EOL
check_error "Failed to create docker-compose.yml"

# Create Nginx configuration
echo -e "\n${YELLOW}Creating Nginx configuration...${NC}"
cat > /etc/nginx/sites-available/zakhar << EOL
server {
    listen 80;
    server_name ${DOMAIN_NAME};

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }

    location /api {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL
check_error "Failed to create Nginx configuration"

# Enable Nginx site
echo -e "\n${YELLOW}Enabling Nginx site...${NC}"
ln -sf /etc/nginx/sites-available/zakhar /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl restart nginx
check_error "Failed to enable Nginx site"

# Create systemd service
echo -e "\n${YELLOW}Creating systemd service...${NC}"
cat > /etc/systemd/system/zakhar.service << EOL
[Unit]
Description=Zakhar AI Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/zakhar
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOL
check_error "Failed to create systemd service"

# Enable and start service
echo -e "\n${YELLOW}Starting Zakhar AI service...${NC}"
systemctl daemon-reload
systemctl enable zakhar
systemctl start zakhar
check_error "Failed to start service"

# Wait for services to start
echo -e "\n${YELLOW}Waiting for services to start...${NC}"
sleep 10

# Check service status
echo -e "\n${YELLOW}Checking service status...${NC}"
systemctl status zakhar
docker-compose ps

echo -e "\n${GREEN}Installation completed successfully!${NC}"
echo -e "\n${YELLOW}Access Points:${NC}"
echo -e "Web Application: http://${DOMAIN_NAME}"
echo -e "API: http://${DOMAIN_NAME}/api"
echo -e "Telegram Bot: @${TELEGRAM_USERNAME}"
echo -e "\n${YELLOW}Important Notes:${NC}"
echo -e "1. The application will automatically start on server boot"
echo -e "2. You can view logs using: sudo docker-compose logs -f"
echo -e "3. To stop the application: sudo systemctl stop zakhar"
echo -e "4. To start the application: sudo systemctl start zakhar"
echo -e "5. To restart the application: sudo systemctl restart zakhar"

# Create .env file
echo -e "\n${YELLOW}Creating .env file...${NC}"
cat > .env << EOL
# OpenAI API Key
OPENAI_API_KEY=${OPENAI_API_KEY}

# Telegram Bot Token
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}

# Redis Configuration
REDIS_PASSWORD=$(openssl rand -base64 32)
REDIS_HOST=redis
REDIS_PORT=6379
EOL
check_error "Failed to create .env file"

# Set permissions for .env file
echo -e "\n${YELLOW}Setting permissions for .env file...${NC}"
chmod 600 .env
check_error "Failed to set permissions for .env file"

# Setup automatic backup
echo -e "${YELLOW}تنظیم سیستم بکاپ خودکار...${NC}"
mkdir -p /opt/zakhar/backups
cat > /etc/cron.d/zakhar-backup << EOL
0 0 * * * root docker-compose exec redis redis-cli SAVE && tar -czf /opt/zakhar/backups/redis_\$(date +%Y%m%d).tar.gz /opt/zakhar/redis_data
0 1 * * * root find /opt/zakhar/backups -type f -mtime +7 -delete
EOL
chmod 644 /etc/cron.d/zakhar-backup
check_error "خطا در تنظیم سیستم بکاپ خودکار"

echo -e "\n${GREEN}Installation completed successfully!${NC}"
echo -e "\n${YELLOW}Access Points:${NC}"
echo -e "Web Application: http://${DOMAIN_NAME}"
echo -e "API: http://${DOMAIN_NAME}/api"
echo -e "Telegram Bot: @${TELEGRAM_USERNAME}"
echo -e "\n${YELLOW}Important Notes:${NC}"
echo -e "1. The application will automatically start on server boot"
echo -e "2. You can view logs using: sudo docker-compose logs -f"
echo -e "3. To stop the application: sudo systemctl stop zakhar"
echo -e "4. To start the application: sudo systemctl start zakhar"
echo -e "5. To restart the application: sudo systemctl restart zakhar"
echo -e "\n${YELLOW}Please restart the service to apply changes:${NC}"
echo -e "sudo systemctl restart zakhar" 