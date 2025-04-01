# Zakhar AI | زاخار هوش مصنوعی

A smart chatbot with natural language processing capabilities.
یک ربات هوشمند با قابلیت‌های چت و پردازش زبان طبیعی.

## Complete Installation Guide | راهنمای کامل نصب

### System Requirements | نیازمندی‌های سیستم

1. Hardware Requirements | نیازمندی‌های سخت‌افزاری:
   - CPU: 2 cores or higher | پردازنده: 2 هسته یا بالاتر
   - RAM: 4GB or higher | حافظه: 4GB یا بالاتر
   - Storage: 20GB or higher | فضای ذخیره‌سازی: 20GB یا بالاتر
   - Free Space: 5GB or higher | فضای خالی: 5GB یا بالاتر

2. Software Requirements | نیازمندی‌های نرم‌افزاری:
   - Operating System: Ubuntu 20.04 or higher | سیستم عامل: اوبونتو 20.04 یا بالاتر
   - Docker: 20.10.0 or higher
   - Docker Compose: 2.0.0 or higher
   - Nginx: 1.18.0 or higher
   - Python: 3.8 or higher
   - Node.js: 16.x or higher
   - npm: 8.x or higher

3. Network Requirements | نیازمندی‌های شبکه:
   - Open Ports: 80, 443, 3000, 8000, 6379 | پورت‌های باز: 80، 443، 3000، 8000، 6379
   - Stable Internet Connection | اتصال اینترنت پایدار
   - Domain Name (optional) | نام دامنه (اختیاری)

4. API Requirements | نیازمندی‌های API:
   - OpenAI API Key | کلید API اپن‌ای‌آی
   - Telegram Bot Token | توکن ربات تلگرام
   - Telegram Username | نام کاربری تلگرام

### Quick Installation | نصب سریع

```bash
curl -s https://raw.githubusercontent.com/RezaHarirchian/Zakhar-AI/main/install.sh | sudo bash
```

This command will:
این دستور موارد زیر را انجام می‌دهد:
1. Install all dependencies | نصب تمام وابستگی‌ها
2. Set up Docker and Docker Compose | تنظیم Docker و Docker Compose
3. Configure Nginx | تنظیم Nginx
4. Create necessary files | ساخت فایل‌های مورد نیاز
5. Start the application | راه‌اندازی برنامه
6. Configure auto-start on server boot | تنظیم راه‌اندازی خودکار در هنگام بوت سرور

### Manual Installation | نصب دستی

#### Step 1: System Preparation | گام 1: آماده‌سازی سیستم

1. Update System | به‌روزرسانی سیستم:
```bash
sudo apt update
sudo apt upgrade -y
```

2. Install Dependencies | نصب وابستگی‌ها:
```bash
sudo apt install -y curl git wget build-essential python3 python3-pip nginx
```

3. Install Docker and Docker Compose | نصب Docker و Docker Compose:
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo curl -L "https://github.com/docker/compose/releases/download/v2.0.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

4. Configure Firewall | تنظیم فایروال:
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3000/tcp
sudo ufw allow 8000/tcp
sudo ufw allow 6379/tcp
sudo ufw enable
```

#### Step 2: Project Setup | گام 2: تنظیم پروژه

1. Create Project Directory | ساخت پوشه پروژه:
```bash
sudo mkdir -p /opt/zakhar
cd /opt/zakhar
```

2. Create .env File | ساخت فایل .env:
```bash
sudo nano .env
```

Add the following content | محتوای زیر را اضافه کنید:
```env
# OpenAI API Key
OPENAI_API_KEY=your_openai_api_key_here

# Telegram Bot Token
TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here

# Redis Configuration
REDIS_PASSWORD=your_redis_password_here
REDIS_HOST=localhost
REDIS_PORT=6379
```

3. Set File Permissions | تنظیم دسترسی‌های فایل:
```bash
sudo chmod 600 .env
```

#### Step 3: Configure Nginx | گام 3: تنظیم Nginx

1. Create Nginx Configuration | ساخت تنظیمات Nginx:
```bash
sudo nano /etc/nginx/sites-available/zakhar
```

Add this configuration | این تنظیمات را اضافه کنید:
```nginx
server {
    listen 80;
    server_name your_domain.com;

    # SSL Configuration (Recommended)
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/your_domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your_domain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location /api {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

2. Enable SSL (Recommended) | فعال‌سازی SSL (توصیه شده):
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your_domain.com
```

3. Enable the Site | فعال کردن سایت:
```bash
sudo ln -s /etc/nginx/sites-available/zakhar /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

#### Step 4: Start the Application | گام 4: راه‌اندازی برنامه

1. Start Docker Services | راه‌اندازی سرویس‌های Docker:
```bash
cd /opt/zakhar
sudo docker-compose up -d
```

2. Check Service Status | بررسی وضعیت سرویس:
```bash
sudo docker-compose ps
```

3. View Logs | مشاهده لاگ‌ها:
```bash
sudo docker-compose logs -f
```

### Security Notes | نکات امنیتی

1. File Permissions | دسترسی‌های فایل:
   - .env file should be 600 | فایل .env باید دسترسی 600 داشته باشد
   - Configuration files should be 644 | فایل‌های تنظیمات باید دسترسی 644 داشته باشند
   - Log files should be 644 | فایل‌های لاگ باید دسترسی 644 داشته باشند

2. Network Security | امنیت شبکه:
   - Use HTTPS (SSL/TLS) | از HTTPS استفاده کنید
   - Configure firewall rules | قوانین فایروال را تنظیم کنید
   - Use strong passwords | از رمزهای عبور قوی استفاده کنید

3. API Security | امنیت API:
   - Keep API keys secure | کلیدهای API را امن نگه دارید
   - Use rate limiting | از محدود کردن نرخ استفاده کنید
   - Monitor API usage | استفاده از API را نظارت کنید

### Common Issues and Solutions | مشکلات رایج و راه‌حل‌ها

1. Application won't start | برنامه شروع نمی‌شود:
   - Check logs: `sudo docker-compose logs -f`
   - Verify API keys in .env file
   - Make sure all ports are available
   - Check system resources (CPU, RAM, disk space)

2. Telegram bot doesn't respond | ربات تلگرام پاسخ نمی‌دهد:
   - Verify bot token in .env file
   - Check if bot is added to your chat
   - Make sure bot has necessary permissions
   - Check network connectivity

3. OpenAI API doesn't work | API اپن‌ای‌آی کار نمی‌کند:
   - Verify API key in .env file
   - Check API key validity
   - Make sure you have sufficient API credits
   - Check network connectivity

4. Redis Connection Issues | مشکلات اتصال Redis:
   - Verify Redis password in .env file
   - Check Redis service status
   - Make sure Redis port is available
   - Check Redis logs

### Monitoring and Backup | مانیتورینگ و پشتیبان‌گیری

1. Monitoring Dashboard | داشبورد مانیتورینگ:
   - Prometheus: http://localhost:9090
   - Grafana: http://localhost:3001
   - Default Grafana credentials | اطلاعات ورود پیش‌فرض Grafana:
     - Username: admin
     - Password: admin (change after first login)

2. Automatic Backup | پشتیبان‌گیری خودکار:
   - Redis data is backed up daily at midnight | داده‌های Redis هر روز در نیمه شب پشتیبان‌گیری می‌شوند
   - Backups are stored in /opt/zakhar/backups | پشتیبان‌ها در /opt/zakhar/backups ذخیره می‌شوند
   - Backups older than 7 days are automatically deleted | پشتیبان‌های قدیمی‌تر از 7 روز به طور خودکار حذف می‌شوند

3. Health Checks | بررسی سلامت:
   - All services have health checks configured | تمام سرویس‌ها دارای بررسی سلامت هستند
   - Health status is monitored every 30 seconds | وضعیت سلامت هر 30 ثانیه بررسی می‌شود
   - Failed health checks trigger automatic restarts | بررسی‌های سلامت ناموفق باعث راه‌اندازی مجدد خودکار می‌شوند

### Useful Commands | دستورات مفید

```bash
# View logs | مشاهده لاگ‌ها
sudo docker-compose logs -f

# Stop the application | متوقف کردن برنامه
sudo docker-compose down

# Start the application | شروع برنامه
sudo docker-compose up -d

# Restart the service | راه‌اندازی مجدد سرویس
sudo systemctl restart zakhar

# Check service status | بررسی وضعیت سرویس
sudo systemctl status zakhar

# Backup Redis data manually | پشتیبان‌گیری دستی از داده‌های Redis
sudo docker-compose exec redis redis-cli SAVE

# Monitor system resources | نظارت بر منابع سیستم
sudo docker stats

# Access monitoring dashboards | دسترسی به داشبوردهای مانیتورینگ
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3001

# View backup files | مشاهده فایل‌های پشتیبان
ls -l /opt/zakhar/backups/
```

### Support | پشتیبانی

If you encounter any issues or need help:
اگر با مشکلی مواجه شدید یا نیاز به کمک دارید:

1. Check the logs | لاگ‌ها را بررسی کنید
2. Review the documentation | مستندات را مرور کنید
3. Create an issue on GitHub | یک issue در گیت‌هاب ایجاد کنید
4. Contact support | با پشتیبانی تماس بگیرید 