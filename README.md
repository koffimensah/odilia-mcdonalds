# Odilia Application - McDonald's Deployment

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)
![Redis](https://img.shields.io/badge/redis-%23DD0031.svg?style=flat&logo=redis&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/postgresql-%23316192.svg?style=flat&logo=postgresql&logoColor=white)

A highly available, distributed voting application built on microservices architecture with Redis Sentinel for automatic failover and PostgreSQL replication for data redundancy.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Verification & Testing](#verification--testing)
- [Monitoring Votes](#monitoring-votes)
- [High Availability Testing](#high-availability-testing)
- [Management & Maintenance](#management--maintenance)
- [Troubleshooting](#troubleshooting)
- [Backup & Recovery](#backup--recovery)
- [Advanced Topics](#advanced-topics)

---

## 🎯 Overview

The Odilia application is a production-ready, cloud-native voting system designed for McDonald's that demonstrates enterprise-grade microservices architecture with:

- **12 containerized microservices**
- **Automatic failover** with Redis Sentinel
- **Database replication** for high availability
- **Session persistence** with Redis caching
- **Zero-downtime deployment** capabilities

### Use Case
Customers access the web interface to cast votes on various restaurant options (IHOP, Chipotle, Outback, Buca di Beppo). All session data is cached in Redis and vote data is persisted in PostgreSQL with multiple replicas for data safety.

---

## 🏗️ Architecture

### System Components Diagram

```
┌─────────────┐
│  Customer   │
└──────┬──────┘
       │ [1] HTTP Request (Port 80)
       ▼
┌─────────────────┐
│   yelb-ui       │  Frontend Container
│   (Web UI)      │  Image: mreferre/yelb-ui:0.7
└────────┬────────┘
         │ [2] API Call
         ▼
┌─────────────────┐
│ yelb-appserver  │  Application Server
│   (API Layer)   │  Image: mreferre/yelb-appserver:0.5
└────┬───────┬────┘
     │       │
     │ [3]   │ [5]
     ▼       ▼
┌─────────┐ ┌──────────┐
│  Redis  │ │PostgreSQL│
│ Cluster │ │ Cluster  │
│  (3)    │ │   (4)    │
└─────────┘ └──────────┘
     ▲
     │ [4] Monitoring
┌─────────────┐
│  Sentinel   │
│   Cluster   │
│     (3)     │
└─────────────┘
```

### Microservices Breakdown

| # | Service | Purpose | Image | Port |
|---|---------|---------|-------|------|
| 1 | yelb-ui | Frontend web interface | mreferre/yelb-ui:0.7 | 80 |
| 2 | yelb-appserver | API server | mreferre/yelb-appserver:0.5 | - |
| 3 | redis-server | Primary cache (Master) | redis:4.0.2 | 6379 |
| 4 | odilia-redis01 | Cache replica (Slave) | redis:4.0.2 | 6379 |
| 5 | odilia-redis02 | Cache replica (Slave) | redis:4.0.2 | 6379 |
| 6 | odilia-redis-sentinel01 | Failover manager | redis:4.0.2 | 5000 |
| 7 | odilia-redis-sentinel02 | Failover manager | redis:4.0.2 | 5000 |
| 8 | odilia-redis-sentinel03 | Failover manager | redis:4.0.2 | 5000 |
| 9 | yelb-db | Primary database | mreferre/yelb-db:0.5 | 5432 |
| 10 | odilia-db-replication01 | Database replica | mreferre/yelb-db:0.5 | 5432 |
| 11 | odilia-db-replication02 | Database replica | mreferre/yelb-db:0.5 | 5432 |
| 12 | odilia-db-replication03 | Database replica | mreferre/yelb-db:0.5 | 5432 |

---

## 📦 Prerequisites

Before deploying Odilia, ensure you have:

- **Docker Engine**: Version 20.10 or higher
  ```bash
  docker --version
  ```

- **Docker Compose**: Version 1.29 or higher
  ```bash
  docker-compose --version
  ```

- **System Requirements**:
  - Minimum 4GB RAM
  - 20GB available disk space
  - Linux/macOS/Windows with WSL2

- **Network Requirements**:
  - Port 80 available for web interface
  - Ports 6379, 5000, 5432 available internally

---

## 🚀 Installation

### Step 1: Create Project Directory

```bash
# Create the main project folder
mkdir odilia-mcdonalds

# Enter the folder
cd odilia-mcdonalds

# Verify you're in the right place
pwd
# Should output: /path/to/odilia-mcdonalds
```

**What this does:**
- `mkdir` creates a new directory for the project
- `cd` changes into that directory
- `pwd` confirms your current location

---

### Step 2: Create docker-compose.yml

Create a file named `docker-compose.yml` with the following content:

```yaml
version: '3.8'

services:
  # Frontend Service
  yelb-ui:
    image: mreferre/yelb-ui:0.7
    container_name: mcdonalds-yelb-ui
    ports:
      - "80:80"
    networks:
      - odilia-network
    depends_on:
      - yelb-appserver
    restart: unless-stopped

  # Application Server
  yelb-appserver:
    image: mreferre/yelb-appserver:0.5
    container_name: mcdonalds-yelb-appserver
    networks:
      - odilia-network
    depends_on:
      - redis-server
      - yelb-db
    environment:
      - REDIS_SERVER=redis-server
      - DB_SERVER=yelb-db
    restart: unless-stopped

  # Redis Master
  redis-server:
    image: redis:4.0.2
    container_name: mcdonalds-redis-server
    command: >
      redis-server
      --protected-mode no
      --port 6379
      --requirepass a-very-complex-password-here
      --masterauth a-very-complex-password-here
    volumes:
      - redis-server-data:/data
    networks:
      - odilia-network
    restart: unless-stopped

  # Redis Replica 1
  odilia-redis01:
    image: redis:4.0.2
    container_name: mcdonalds-odilia-redis01
    command: >
      redis-server
      --protected-mode no
      --port 6379
      --slaveof redis-server 6379
      --requirepass a-very-complex-password-here
      --masterauth a-very-complex-password-here
    volumes:
      - odilia-redis01-data:/data
    networks:
      - odilia-network
    depends_on:
      - redis-server
    restart: unless-stopped

  # Redis Replica 2
  odilia-redis02:
    image: redis:4.0.2
    container_name: mcdonalds-odilia-redis02
    command: >
      redis-server
      --protected-mode no
      --port 6379
      --slaveof redis-server 6379
      --requirepass a-very-complex-password-here
      --masterauth a-very-complex-password-here
    volumes:
      - odilia-redis02-data:/data
    networks:
      - odilia-network
    depends_on:
      - redis-server
    restart: unless-stopped

  # Redis Sentinel 1
  odilia-redis-sentinel01:
    image: redis:4.0.2
    container_name: mcdonalds-redis-sentinel01
    command: >
      sh -c "mkdir -p /data &&
      echo 'port 5000' > /data/sentinel.conf &&
      echo 'dir /data' >> /data/sentinel.conf &&
      echo 'sentinel monitor mymaster redis-server 6379 2' >> /data/sentinel.conf &&
      echo 'sentinel auth-pass mymaster a-very-complex-password-here' >> /data/sentinel.conf &&
      echo 'sentinel down-after-milliseconds mymaster 5000' >> /data/sentinel.conf &&
      echo 'sentinel parallel-syncs mymaster 1' >> /data/sentinel.conf &&
      echo 'sentinel failover-timeout mymaster 60000' >> /data/sentinel.conf &&
      redis-sentinel /data/sentinel.conf"
    networks:
      - odilia-network
    depends_on:
      - redis-server
      - odilia-redis01
      - odilia-redis02
    restart: unless-stopped

  # Redis Sentinel 2
  odilia-redis-sentinel02:
    image: redis:4.0.2
    container_name: mcdonalds-redis-sentinel02
    command: >
      sh -c "mkdir -p /data &&
      echo 'port 5000' > /data/sentinel.conf &&
      echo 'dir /data' >> /data/sentinel.conf &&
      echo 'sentinel monitor mymaster redis-server 6379 2' >> /data/sentinel.conf &&
      echo 'sentinel auth-pass mymaster a-very-complex-password-here' >> /data/sentinel.conf &&
      echo 'sentinel down-after-milliseconds mymaster 5000' >> /data/sentinel.conf &&
      echo 'sentinel parallel-syncs mymaster 1' >> /data/sentinel.conf &&
      echo 'sentinel failover-timeout mymaster 60000' >> /data/sentinel.conf &&
      redis-sentinel /data/sentinel.conf"
    networks:
      - odilia-network
    depends_on:
      - redis-server
      - odilia-redis01
      - odilia-redis02
    restart: unless-stopped

  # Redis Sentinel 3
  odilia-redis-sentinel03:
    image: redis:4.0.2
    container_name: mcdonalds-redis-sentinel03
    command: >
      sh -c "mkdir -p /data &&
      echo 'port 5000' > /data/sentinel.conf &&
      echo 'dir /data' >> /data/sentinel.conf &&
      echo 'sentinel monitor mymaster redis-server 6379 2' >> /data/sentinel.conf &&
      echo 'sentinel auth-pass mymaster a-very-complex-password-here' >> /data/sentinel.conf &&
      echo 'sentinel down-after-milliseconds mymaster 5000' >> /data/sentinel.conf &&
      echo 'sentinel parallel-syncs mymaster 1' >> /data/sentinel.conf &&
      echo 'sentinel failover-timeout mymaster 60000' >> /data/sentinel.conf &&
      redis-sentinel /data/sentinel.conf"
    networks:
      - odilia-network
    depends_on:
      - redis-server
      - odilia-redis01
      - odilia-redis02
    restart: unless-stopped

  # Primary Database
  yelb-db:
    image: mreferre/yelb-db:0.5
    container_name: mcdonalds-yelb-db
    volumes:
      - yelb-db-data:/var/lib/postgresql/data
    networks:
      - odilia-network
    restart: unless-stopped

  # Database Replica 1
  odilia-db-replication01:
    image: mreferre/yelb-db:0.5
    container_name: mcdonalds-db-replication01
    volumes:
      - db-replication01-data:/var/lib/postgresql/data
    networks:
      - odilia-network
    depends_on:
      - yelb-db
    restart: unless-stopped

  # Database Replica 2
  odilia-db-replication02:
    image: mreferre/yelb-db:0.5
    container_name: mcdonalds-db-replication02
    volumes:
      - db-replication02-data:/var/lib/postgresql/data
    networks:
      - odilia-network
    depends_on:
      - yelb-db
    restart: unless-stopped

  # Database Replica 3
  odilia-db-replication03:
    image: mreferre/yelb-db:0.5
    container_name: mcdonalds-db-replication03
    volumes:
      - db-replication03-data:/var/lib/postgresql/data
    networks:
      - odilia-network
    depends_on:
      - yelb-db
    restart: unless-stopped

networks:
  odilia-network:
    driver: bridge
    name: mcdonalds-odilia-network

volumes:
  redis-server-data:
    driver: local
  odilia-redis01-data:
    driver: local
  odilia-redis02-data:
    driver: local
  yelb-db-data:
    driver: local
  db-replication01-data:
    driver: local
  db-replication02-data:
    driver: local
  db-replication03-data:
    driver: local
```

---

### Step 3: Deploy the Application

```bash
# Pull all Docker images
docker-compose pull
# Downloads all required images (may take 2-5 minutes)

# Start all services in detached mode
docker-compose up -d
# Creates network, volumes, and starts all 12 containers

# Wait 10 seconds for services to initialize
sleep 10

# Verify all services are running
docker-compose ps
# All services should show "Up" status
```

**What these commands do:**
- `docker-compose pull` downloads all container images
- `docker-compose up -d` starts all services in background
- `docker-compose ps` shows the status of all containers

**Expected output:**
```
NAME                           STATUS        PORTS
mcdonalds-yelb-ui              Up           0.0.0.0:80->80/tcp
mcdonalds-yelb-appserver       Up           
mcdonalds-redis-server         Up           
mcdonalds-odilia-redis01       Up           
mcdonalds-odilia-redis02       Up           
mcdonalds-redis-sentinel01     Up           
mcdonalds-redis-sentinel02     Up           
mcdonalds-redis-sentinel03     Up           
mcdonalds-yelb-db              Up           
mcdonalds-db-replication01     Up           
mcdonalds-db-replication02     Up           
mcdonalds-db-replication03     Up           
```

---

### Step 4: Access the Application

Open your web browser and navigate to:
```
http://localhost
```

**You should see:**
- The Yelb voting interface
- Four restaurant options: IHOP, Chipotle, Outback, Buca di Beppo
- Vote buttons for each restaurant
- A clean, responsive UI

---

## ✅ Verification & Testing

### Verify Container Status

```bash
# Check all containers are running
docker-compose ps

# View logs from all services
docker-compose logs

# View logs from a specific service
docker-compose logs yelb-ui
docker-compose logs yelb-appserver

# Follow logs in real-time (Ctrl+C to exit)
docker-compose logs -f

# View last 50 lines
docker-compose logs --tail=50

# View logs from multiple services
docker-compose logs yelb-appserver redis-server yelb-db
```

---

### Restart Services

```bash
# Restart a specific service
docker-compose restart yelb-appserver

# Restart all services
docker-compose restart

# Stop all services (keeps data)
docker-compose stop

# Start stopped services
docker-compose start
```

**What these do:**
- `restart` stops and starts a container
- `stop` stops without removing containers
- `start` starts previously stopped containers
- Data in volumes persists through restarts

---

### Update Services

```bash
# Pull latest images
docker-compose pull

# Update specific service without downtime
docker-compose up -d --no-deps yelb-ui

# Update all services
docker-compose up -d
```

**What `--no-deps` does:**
- Updates only the specified service
- Doesn't restart dependent services
- Useful for rolling updates

---

### Check Network

```bash
# Inspect the network
docker network inspect mcdonalds-odilia-network

# Shows:
# - All connected containers
# - IP addresses
# - Network configuration
```

---

### Check Volumes

```bash
# List all volumes
docker volume ls | grep -E "(redis|yelb|db)"

# Inspect a specific volume
docker volume inspect redis-server-data

# Shows:
# - Volume location on host
# - Mount point
# - Driver type
# - Creation date
```

---

### Enter Container Shell

```bash
# Enter a container for debugging
docker exec -it mcdonalds-yelb-appserver sh

# Inside the container:
ls                  # List files
ps aux              # View processes
env                 # View environment variables
exit                # Leave container

# For database container (uses bash)
docker exec -it mcdonalds-yelb-db bash
```

**What this does:**
- Opens an interactive shell inside the container
- Useful for debugging and troubleshooting
- Type `exit` to return to host

---

## 🔧 Troubleshooting

### Common Issues and Solutions

#### Issue 1: Port 80 Already in Use

**Error:**
```
Error: Ports are not available: listen tcp 0.0.0.0:80: bind: address already in use
```

**Solution:**
```bash
# Find what's using port 80
sudo lsof -i :80
# OR on Windows
netstat -ano | findstr :80

# Option A: Kill the process
sudo kill -9 <PID>

# Option B: Change the port in docker-compose.yml
# Change "80:80" to "8080:80"
# Then access at http://localhost:8080
```

---

#### Issue 2: Containers Keep Restarting

**Check logs:**
```bash
# View logs to see error messages
docker logs mcdonalds-yelb-ui --tail=100
docker logs mcdonalds-yelb-appserver --tail=100
docker logs mcdonalds-redis-server --tail=100
```

**Common causes:**
- Configuration error
- Missing dependencies
- Resource constraints
- Port conflicts

**Solution - Clean restart:**
```bash
# Stop all containers
docker-compose down

# Remove all volumes (WARNING: deletes data)
docker-compose down -v

# Start fresh
docker-compose up -d

# Monitor logs
docker-compose logs -f
```

---

#### Issue 3: Cannot Connect to Application

**Diagnostic steps:**
```bash
# 1. Check if containers are running
docker-compose ps
# All should show "Up" status

# 2. Check if yelb-ui is accessible
curl http://localhost
# Should return HTML

# 3. Test internal network connectivity
docker exec mcdonalds-yelb-appserver ping redis-server -c 3
# Should show successful pings

# 4. Check firewall rules
sudo ufw status
# Ensure port 80 is allowed
```

---

#### Issue 4: Redis Connection Failed

**Check Redis status:**
```bash
# Test Redis connectivity
docker exec mcdonalds-redis-server redis-cli -a a-very-complex-password-here PING
# Should return: PONG

# Check if Redis is listening
docker exec mcdonalds-redis-server netstat -tuln | grep 6379

# Verify password
docker exec mcdonalds-redis-server redis-cli -a wrong-password PING
# Should show authentication error
```

---

#### Issue 5: Database Connection Failed

**Check database status:**
```bash
# Test if database is ready
docker exec mcdonalds-yelb-db pg_isready
# Should return: accepting connections

# Check PostgreSQL logs
docker logs mcdonalds-yelb-db --tail=50

# Test connection
docker exec mcdonalds-yelb-db psql -U postgres -c "SELECT 1;"
# Should return: 1
```

---

#### Issue 6: Sentinel Not Working

**Check sentinel logs:**
```bash
# View sentinel logs
docker logs mcdonalds-redis-sentinel01 --tail=100

# Common issues:
# - Cannot connect to master
# - Wrong password
# - Network issues

# Test sentinel connectivity
docker exec mcdonalds-redis-sentinel01 redis-cli -p 5000 PING
# Should return: PONG

# Check if sentinel can reach master
docker exec mcdonalds-redis-sentinel01 redis-cli -h redis-server -a a-very-complex-password-here PING
# Should return: PONG
```

---

### Troubleshooting Script

Create `troubleshoot.sh`:

```bash
cat > troubleshoot.sh << 'EOF'
#!/bin/bash

echo "======================================"
echo "Odilia Application Troubleshooting"
echo "======================================"
echo ""

# Check Docker
echo "[1/8] Checking Docker..."
docker --version && echo "✅ Docker OK" || echo "❌ Docker not found"
echo ""

# Check Docker Compose
echo "[2/8] Checking Docker Compose..."
docker-compose --version && echo "✅ Docker Compose OK" || echo "❌ Docker Compose not found"
echo ""

# Check containers
echo "[3/8] Container Status:"
docker-compose ps
echo ""

# Check for restarting containers
echo "[4/8] Checking for issues..."
RESTARTING=$(docker ps --filter "status=restarting" --format "{{.Names}}")
if [ -z "$RESTARTING" ]; then
    echo "✅ No restarting containers"
else
    echo "❌ Restarting containers: $RESTARTING"
fi
echo ""

# Check Redis
echo "[5/8] Testing Redis..."
docker exec mcdonalds-redis-server redis-cli -a a-very-complex-password-here PING 2>/dev/null && echo "✅ Redis OK" || echo "❌ Redis error"
echo ""

# Check Database
echo "[6/8] Testing Database..."
docker exec mcdonalds-yelb-db pg_isready 2>/dev/null && echo "✅ Database OK" || echo "❌ Database error"
echo ""

# Check Network
echo "[7/8] Checking Network..."
docker network inspect mcdonalds-odilia-network >/dev/null 2>&1 && echo "✅ Network OK" || echo "❌ Network not found"
echo ""

# Check Port 80
echo "[8/8] Checking Port 80..."
if lsof -Pi :80 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️  Port 80 in use by:"
    lsof -i :80 2>/dev/null || netstat -ano | findstr :80
else
    echo "✅ Port 80 available"
fi
echo ""

echo "======================================"
echo "Troubleshooting Complete"
echo "======================================"
EOF

chmod +x troubleshoot.sh
./troubleshoot.sh
```

---

## 💾 Backup & Recovery

### Backup Strategy

#### Create Backup Script

Create `backup.sh`:

```bash
cat > backup.sh << 'EOF'
#!/bin/bash

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./backups"

mkdir -p ${BACKUP_DIR}

echo "============================================"
echo "Starting Odilia Backup - ${DATE}"
echo "============================================"
echo ""

# Backup Redis data
echo "📦 Backing up Redis..."
docker exec mcdonalds-redis-server redis-cli -a a-very-complex-password-here SAVE
docker run --rm \
  -v redis-server-data:/data \
  -v $(pwd)/${BACKUP_DIR}:/backup \
  alpine tar czf /backup/redis-${DATE}.tar.gz /data
echo "✅ Redis backup complete"
echo ""

# Backup PostgreSQL
echo "📦 Backing up Database..."
docker exec mcdonalds-yelb-db \
  pg_dump -U postgres -Fc yelbdatabase > ${BACKUP_DIR}/yelb-db-${DATE}.dump
echo "✅ Database backup complete"
echo ""

# Backup configurations
echo "📦 Backing up Configuration..."
tar czf ${BACKUP_DIR}/configs-${DATE}.tar.gz docker-compose.yml scripts/ 2>/dev/null
echo "✅ Configuration backup complete"
echo ""

# List backups
echo "📋 Backup Files:"
ls -lh ${BACKUP_DIR}/*${DATE}*
echo ""

# Cleanup old backups (keep last 30 days)
echo "🧹 Cleaning old backups..."
find ${BACKUP_DIR} -name "*.tar.gz" -mtime +30 -delete
find ${BACKUP_DIR} -name "*.dump" -mtime +30 -delete
echo "✅ Cleanup complete"
echo ""

echo "============================================"
echo "Backup completed successfully!"
echo "Location: ${BACKUP_DIR}"
echo "============================================"
EOF

chmod +x backup.sh
./backup.sh
```

**What this script does:**
- Creates timestamped backups of Redis, PostgreSQL, and configs
- Stores backups in `./backups` directory
- Automatically removes backups older than 30 days
- Provides detailed progress information

---

#### Schedule Automated Backups

```bash
# Add to crontab for daily backups at 2 AM
crontab -e

# Add this line:
0 2 * * * cd /path/to/odilia-mcdonalds && ./backup.sh >> /var/log/odilia-backup.log 2>&1
```

---

### Restore from Backup

#### Restore Redis

```bash
# Stop Redis
docker-compose stop redis-server odilia-redis01 odilia-redis02

# Restore data
docker run --rm \
  -v redis-server-data:/data \
  -v $(pwd)/backups:/backup \
  alpine sh -c "cd / && tar xzf /backup/redis-20250119_020000.tar.gz"

# Start Redis
docker-compose start redis-server odilia-redis01 odilia-redis02

# Verify
docker exec mcdonalds-redis-server redis-cli -a a-very-complex-password-here PING
```

---

#### Restore PostgreSQL

```bash
# Stop application
docker-compose stop yelb-appserver

# Restore database
docker exec -i mcdonalds-yelb-db \
  pg_restore -U postgres -d yelbdatabase -c < backups/yelb-db-20250119_020000.dump

# Restart application
docker-compose start yelb-appserver

# Verify
docker exec mcdonalds-yelb-db psql -U postgres -d yelbdatabase -c "SELECT * FROM restaurants;"
```

---

### Disaster Recovery

#### Complete System Restore

```bash
# 1. Stop all services
docker-compose down

# 2. Remove old volumes
docker volume rm redis-server-data yelb-db-data

# 3. Restore configurations
tar xzf backups/configs-20250119_020000.tar.gz

# 4. Start services
docker-compose up -d

# 5. Wait for services to be ready
sleep 30

# 6. Restore Redis
./restore-redis.sh

# 7. Restore Database
./restore-database.sh

# 8. Verify all services
docker-compose ps
./vote-dashboard.sh
```

---

## 📈 Advanced Topics

### Performance Tuning

#### Redis Optimization

Add to Redis configuration (in docker-compose.yml command section):

```yaml
command: >
  redis-server
  --protected-mode no
  --port 6379
  --requirepass a-very-complex-password-here
  --masterauth a-very-complex-password-here
  --maxmemory 2gb
  --maxmemory-policy allkeys-lru
  --save 900 1
  --save 300 10
  --save 60 10000
```

**What these settings do:**
- `maxmemory 2gb` - Limits Redis memory usage
- `maxmemory-policy allkeys-lru` - Eviction policy (removes least recently used keys)
- `save` - Persistence intervals (creates snapshots)

---

#### PostgreSQL Optimization

```bash
# Increase max connections
docker exec mcdonalds-yelb-db psql -U postgres -c "ALTER SYSTEM SET max_connections = 200;"

# Tune memory
docker exec mcdonalds-yelb-db psql -U postgres -c "ALTER SYSTEM SET shared_buffers = '256MB';"
docker exec mcdonalds-yelb-db psql -U postgres -c "ALTER SYSTEM SET effective_cache_size = '1GB';"
docker exec mcdonalds-yelb-db psql -U postgres -c "ALTER SYSTEM SET work_mem = '16MB';"

# Restart to apply changes
docker-compose restart yelb-db
```

---

### Scaling

#### Horizontal Scaling

```bash
# Scale application servers (requires load balancer)
docker-compose up -d --scale yelb-appserver=3

# Add more Redis replicas (edit docker-compose.yml)
# Copy odilia-redis02 section and rename to odilia-redis03

# Add more database replicas (edit docker-compose.yml)
# Copy odilia-db-replication03 section and rename
```

---

#### Load Balancing

Add Nginx as a load balancer:

```yaml
# Add to docker-compose.yml
nginx:
  image: nginx:alpine
  container_name: mcdonalds-nginx
  ports:
    - "80:80"
  volumes:
    - ./nginx.conf:/etc/nginx/nginx.conf:ro
  networks:
    - odilia-network
  depends_on:
    - yelb-ui
```

---

### Security Hardening

#### Change Default Passwords

```bash
# Generate strong password
NEW_PASSWORD=$(openssl rand -base64 32)
echo "New password: $NEW_PASSWORD"

# Update docker-compose.yml
# Replace all instances of "a-very-complex-password-here" with $NEW_PASSWORD
```

---

#### Use Docker Secrets (Docker Swarm)

```yaml
secrets:
  redis_password:
    external: true

services:
  redis-server:
    secrets:
      - redis_password
    command: >
      redis-server
      --requirepass $(cat /run/secrets/redis_password)
```

---

#### Enable TLS/SSL

For production, use a reverse proxy with SSL:

```bash
# Use Traefik or Nginx with Let's Encrypt
# Add HTTPS certificates
# Force HTTPS redirects
```

---

### Monitoring & Alerting

#### Prometheus Integration

```yaml
# Add to docker-compose.yml
prometheus:
  image: prom/prometheus
  container_name: mcdonalds-prometheus
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml
    - prometheus-data:/prometheus
  ports:
    - "9090:9090"
  networks:
    - odilia-network
```

---

#### Grafana Dashboard

```yaml
grafana:
  image: grafana/grafana
  container_name: mcdonalds-grafana
  ports:
    - "3000:3000"
  volumes:
    - grafana-data:/var/lib/grafana
  networks:
    - odilia-network
```

---

### Database Maintenance

#### Regular Maintenance Tasks

```bash
# Vacuum database (reclaim storage)
docker exec mcdonalds-yelb-db psql -U postgres -d yelbdatabase -c "VACUUM FULL;"

# Analyze tables (update statistics)
docker exec mcdonalds-yelb-db psql -U postgres -d yelbdatabase -c "ANALYZE;"

# Reindex database
docker exec mcdonalds-yelb-db psql -U postgres -d yelbdatabase -c "REINDEX DATABASE yelbdatabase;"

# Check database size
docker exec mcdonalds-yelb-db psql -U postgres -c "SELECT pg_size_pretty(pg_database_size('yelbdatabase'));"
```

---

#### Create Maintenance Script

Create `maintenance.sh`:

```bash
cat > maintenance.sh << 'EOF'
#!/bin/bash

echo "======================================"
echo "Odilia Maintenance - $(date)"
echo "======================================"
echo ""

echo "🔧 Running database vacuum..."
docker exec mcdonalds-yelb-db psql -U postgres -d yelbdatabase -c "VACUUM FULL;"
echo "✅ Vacuum complete"
echo ""

echo "🔧 Analyzing database..."
docker exec mcdonalds-yelb-db psql -U postgres -d yelbdatabase -c "ANALYZE;"
echo "✅ Analysis complete"
echo ""

echo "🔧 Checking database size..."
docker exec mcdonalds-yelb-db psql -U postgres -c "SELECT pg_size_pretty(pg_database_size('yelbdatabase'));"
echo ""

echo "🔧 Checking Redis memory..."
docker exec mcdonalds-redis-server redis-cli -a a-very-complex-password-here INFO memory | grep used_memory_human
echo ""

echo "======================================"
echo "Maintenance complete!"
echo "======================================"
EOF

chmod +x maintenance.sh
```

---

## 📚 Quick Reference

### Essential Commands Cheat Sheet

```bash
# DEPLOYMENT
docker-compose up -d              # Start all services
docker-compose down               # Stop all services
docker-compose down -v            # Stop and remove volumes (deletes data)
docker-compose restart            # Restart all services
docker-compose ps                 # View status

# LOGS
docker-compose logs -f            # Follow all logs
docker-compose logs yelb-ui       # View specific service logs
docker-compose logs --tail=100    # View last 100 lines

# REDIS
docker exec mcdonalds-redis-server redis-cli -a a-very-complex-password-here INFO replication
docker exec mcdonalds-redis-server redis-cli -a a-very-complex-password-here PING
docker exec mcdonalds-redis-server redis-cli -a a-very-complex-password-here KEYS '*'

# SENTINEL
docker exec mcdonalds-redis-sentinel01 redis-cli -p 5000 SENTINEL master mymaster
docker exec mcdonalds-redis-sentinel01 redis-cli -p 5000 SENTINEL sentinels mymaster
docker exec mcdonalds-redis-sentinel01 redis-cli -p 5000 SENTINEL replicas mymaster

# DATABASE
docker exec mcdonalds-yelb-db pg_isready
docker exec mcdonalds-yelb-db psql -U postgres -d yelbdatabase -c "SELECT name, count FROM restaurants;"
docker exec -it mcdonalds-yelb-db psql -U postgres

# VOTES
docker exec mcdonalds-yelb-db psql -U postgres -d yelbdatabase -c "SELECT name, count FROM restaurants ORDER BY count DESC;"
docker exec mcdonalds-yelb-db psql -U postgres -d yelbdatabase -c "SELECT SUM(count) FROM restaurants;"

# MONITORING
docker stats                      # Resource usage
docker-compose top                # Process list
docker network inspect mcdonalds-odilia-network
docker volume ls

# MAINTENANCE
./backup.sh                       # Create backup
./vote-dashboard.sh               # View vote dashboard
./troubleshoot.sh                 # Run diagnostics
```

---

## 🎓 Understanding the Data Flow

### Application Request Flow

```
1. Customer opens browser → http://localhost
   ↓
2. Browser connects to yelb-ui (Port 80)
   ↓
3. User clicks "VOTE" button
   ↓
4. yelb-ui sends POST request to yelb-appserver
   ↓
5. yelb-appserver:
   ├─ Stores session in redis-server (caching)
   │  └─ Data replicated to odilia-redis01 and odilia-redis02
   │
   └─ Stores vote in yelb-db (persistence)
      └─ Data replicated to db-replication01, 02, 03
   ↓
6. Response sent back to browser
   ↓
7. Vote count displayed to user
```

---

### High Availability Flow

```
Normal Operation:
redis-server (Master) ← Sentinels monitoring
├─ odilia-redis01 (Slave)
└─ odilia-redis02 (Slave)

Master Fails:
redis-server (Down) ✗
├─ odilia-redis01 (Slave) → Promoted to Master ✓
└─ odilia-redis02 (Slave) → Follows new master

Recovery:
redis-server (Restarted) → Becomes Slave
├─ odilia-redis01 (Master)
└─ odilia-redis02 (Slave)
```

---

## ✅ Success Checklist

Before considering your deployment complete, verify:

- [ ] All 12 containers show "Up" status
- [ ] Can access http://localhost in browser
- [ ] Can vote and see vote counts increase
- [ ] Redis shows role:master with 2 connected slaves
- [ ] All 3 sentinels can see the master
- [ ] Database accepts connections
- [ ] Failover test works (sentinel promotes replica)
- [ ] Application works during and after failover
- [ ] Resource usage is reasonable (< 2GB RAM total)
- [ ] Backup script runs successfully
- [ ] Vote monitoring scripts work
- [ ] No containers are restarting

---

## 📞 Support

### Getting Help

1. **Check logs first:**
   ```bash
   docker-compose logs --tail=200 > debug.log
   ```

2. **Run diagnostics:**
   ```bash
   ./troubleshoot.sh
   ```

3. **Check documentation:**
   - Docker: https://docs.docker.com/
   - Redis: https://redis.io/documentation
   - PostgreSQL: https://www.postgresql.org/docs/

4. **Common issues:**
   - Port conflicts → Change port in docker-compose.yml
   - Container restarts → Check logs for errors
   - Network issues → Verify Docker network settings
   - Permission denied → Check file permissions and Docker group membership

---

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🙏 Acknowledgments

- **Yelb Application**: Original application by Massimo Re Ferre (mreferre)
- **Redis**: In-memory data structure store
- **PostgreSQL**: Open source relational database
- **Docker**: Container platform
- **McDonald's**: Project sponsor

---

## 📊 Project Status

- **Version**: 1.0.0
- **Status**: Production Ready ✅
- **Last Updated**: November 19, 2025
- **Maintainer**: McDonald's DevOps Team
- **Tested On**: Docker 24.0+, Docker Compose 2.20+

---

## 🎉 Congratulations!

You've successfully deployed a **highly available, production-ready microservices application** with:

✅ **12 microservices** working together  
✅ **Automatic failover** with Redis Sentinel  
✅ **Data replication** for PostgreSQL  
✅ **Zero-downtime** capability  
✅ **Complete monitoring** and management tools  

**Happy voting!** 🗳️🍔

---

**Made with ❤️ by the McDonald's DevOps Team**-time (Ctrl+C to exit)
docker-compose logs -f
```

---

### Verify Redis Cluster

#### Check Redis Master Status

```bash
# Connect to Redis master and check replication status
docker exec mcdonalds-redis-server redis-cli -a a-very-complex-password-here INFO replication
```

**What this does:**
- Executes command inside the redis-server container
- Authenticates with password
- Shows replication information

**Expected output:**
```
# Replication
role:master
connected_slaves:2
slave0:ip=172.18.0.5,port=6379,state=online,offset=123,lag=0
slave1:ip=172.18.0.6,port=6379,state=online,offset=123,lag=0
```

**What this means:**
- ✅ This server is the MASTER
- ✅ Two replicas are connected
- ✅ Replication lag is 0 (real-time sync)

---

#### Check Redis Replica Status

```bash
# Check first replica
docker exec mcdonalds-odilia-redis01 redis-cli -a a-very-complex-password-here INFO replication
```

**Expected output:**
```
# Replication
role:slave
master_host:redis-server
master_port:6379
master_link_status:up
```

---

#### Test Redis Data Replication

```bash
# Store a test value in Redis master
docker exec mcdonalds-redis-server redis-cli -a a-very-complex-password-here SET test_key "Hello McDonald's"
# Should return: OK

# Retrieve the value from master
docker exec mcdonalds-redis-server redis-cli -a a-very-complex-password-here GET test_key
# Should return: "Hello McDonald's"

# Verify replication - check if data is on replica
docker exec mcdonalds-odilia-redis01 redis-cli -a a-very-complex-password-here GET test_key
# Should also return: "Hello McDonald's"
# This proves replication is working!
```

---

### Verify Redis Sentinel

#### Check Sentinel Status

```bash
# Connect to first sentinel and check master info
docker exec mcdonalds-redis-sentinel01 redis-cli -p 5000 SENTINEL master mymaster
```

**What this does:**
- Connects to sentinel on port 5000
- Queries information about the monitored master

**Expected output:**
```
1) "name"
2) "mymaster"
3) "ip"
4) "172.18.0.4"
5) "port"
6) "6379"
7) "flags"
8) "master"
9) "num-slaves"
10) "2"
11) "num-other-sentinels"
12) "2"
```

---

#### Check All Sentinels

```bash
# List all sentinels monitoring the master
docker exec mcdonalds-redis-sentinel01 redis-cli -p 5000 SENTINEL sentinels mymaster
# Shows sentinel02 and sentinel03 details

# List all replicas
docker exec mcdonalds-redis-sentinel01 redis-cli -p 5000 SENTINEL replicas mymaster
# Shows odilia-redis01 and odilia-redis02 details
```

---

### Verify PostgreSQL Database

#### Check Database Connection

```bash
# Test if database is accepting connections
docker exec mcdonalds-yelb-db pg_isready
```

**Expected output:**
```
/var/run/postgresql:5432 - accepting connections
```

---

#### Explore Database Structure

```bash
# Connect to PostgreSQL
docker exec -it mcdonalds-yelb-db psql -U postgres

# Inside psql:
\l                      # List all databases
\c yelbdatabase         # Connect to yelbdatabase
\dt                     # List all tables
SELECT * FROM restaurants;  # View restaurant data
\q                      # Exit psql
```

**What this does:**
- `\l` lists all databases
- `\c` connects to a specific database
- `\dt` shows all tables
- `SELECT` queries data
- `\q` quits psql

---

## 📊 Monitoring Votes

### Important Note About Column Names

The database uses `count` as the column name for vote counts (not `votecount`).

**Table structure:**
```
 Column |          Type          
--------+------------------------
 name   | character varying(100) 
 count  | integer                
```

---

### View Current Vote Counts

```bash
# View all restaurant vote counts
docker exec mcdonalds-yelb-db psql -U postgres -d yelbdatabase -c "SELECT name, count FROM restaurants ORDER BY count DESC;"
```

**Expected output:**
```
    name     | count 
-------------+-------
 ihop        |     5
 chipotle    |     3
 outback     |     1
 bucadibeppo |     0
(4 rows)
```

---

### Check Total Votes

```bash
# Get total votes across all restaurants
docker exec mcdonalds-yelb-db psql -U postgres -d yelbdatabase -c "SELECT SUM(count) AS total_votes FROM restaurants;"
```

**Expected output:**
```
 total_votes 
-------------
           9
(1 row)
```

---

### Create Vote Monitoring Script

Create `check-votes.sh`:

```bash
cat > check-votes.sh << 'EOF'
#!/bin/bash

echo "============================================"
echo "  Odilia Vote Counts - McDonald's"
echo "============================================"
echo ""

# Get votes from database
echo "📊 Current Vote Counts:"
echo "--------------------------------------------"

docker exec mcdonalds-yelb-db psql -U postgres -d yelbdatabase -t -c "
SELECT 
    RPAD(name, 20) || ' | Votes: ' || count 
FROM restaurants 
ORDER BY count DESC;
"

echo "--------------------------------------------"
echo ""

# Get total votes
TOTAL=$(docker exec mcdonalds-yelb-db psql -U postgres -d yelbdatabase -t -c "SELECT COALESCE(SUM(count), 0) FROM restaurants;" | tr -d ' ')
echo "🎯 Total Votes Cast: $TOTAL"
echo ""

# Get timestamp
echo "⏰ Checked at: $(date)"
echo "============================================"
EOF

chmod +x check-votes.sh
./check-votes.sh
```

**What this script does:**
- Queries the database for all vote counts
- Displays formatted results
- Shows total votes
- Adds timestamp

---

### Create Enhanced Vote Dashboard

Create `vote-dashboard.sh`:

```bash
cat > vote-dashboard.sh << 'EOF'
#!/bin/bash

clear

echo "╔════════════════════════════════════════════╗"
echo "║   Odilia Voting Dashboard - McDonald's     ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# Get vote data with rankings
echo "📊 Restaurant Rankings:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

docker exec mcdonalds-yelb-db psql -U postgres -d yelbdatabase -t -c "
SELECT 
    CASE 
        WHEN ROW_NUMBER() OVER (ORDER BY count DESC) = 1 THEN '🥇'
        WHEN ROW_NUMBER() OVER (ORDER BY count DESC) = 2 THEN '🥈'
        WHEN ROW_NUMBER() OVER (ORDER BY count DESC) = 3 THEN '🥉'
        ELSE '  '
    END || ' ' ||
    RPAD(UPPER(name), 18) || 
    LPAD(count::text, 5) || ' votes'
FROM restaurants 
ORDER BY count DESC;
" 2>/dev/null

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Total votes
TOTAL=$(docker exec mcdonalds-yelb-db psql -U postgres -d yelbdatabase -t -c "SELECT COALESCE(SUM(count), 0) FROM restaurants;" 2>/dev/null | tr -d ' ')
echo ""
echo "📈 Total Votes: $TOTAL"

# System status
echo ""
echo "🔧 System Status:"
REDIS_STATUS=$(docker exec mcdonalds-redis-server redis-cli -a a-very-complex-password-here PING 2>/dev/null)
DB_STATUS=$(docker exec mcdonalds-yelb-db pg_isready 2>/dev/null | grep -o "accepting connections")

if [ "$REDIS_STATUS" = "PONG" ]; then
    echo "   ✅ Redis Cache: Online"
else
    echo "   ❌ Redis Cache: Offline"
fi

if [ "$DB_STATUS" = "accepting connections" ]; then
    echo "   ✅ Database: Online"
else
    echo "   ❌ Database: Offline"
fi

echo ""
echo "⏰ Updated: $(date '+%Y-%m-%d %H:%M:%S')"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
EOF

chmod +x vote-dashboard.sh
./vote-dashboard.sh
```

**What this creates:**
- Beautiful formatted dashboard
- Rankings with medal emojis 🥇🥈🥉
- System health indicators
- Real-time updates

---

### Real-Time Vote Monitoring

```bash
# Watch votes change every 2 seconds (Ctrl+C to stop)
watch -n 2 'docker exec mcdonalds-yelb-db psql -U postgres -d yelbdatabase -t -c "SELECT RPAD(name, 20) || count::text FROM restaurants ORDER BY count DESC;"'
```

**What this does:**
- Runs the query every 2 seconds
- Shows live vote updates
- Press Ctrl+C to exit

---

### Quick Reference: Vote Commands

```bash
# 1. VIEW VOTES (most common)
docker exec mcdonalds-yelb-db psql -U postgres -d yelbdatabase -c "SELECT name, count FROM restaurants ORDER BY count DESC;"

# 2. TOTAL VOTES
docker exec mcdonalds-yelb-db psql -U postgres -d yelbdatabase -c "SELECT SUM(count) AS total FROM restaurants;"

# 3. VIEW WINNER
docker exec mcdonalds-yelb-db psql -U postgres -d yelbdatabase -c "SELECT name AS winner, count AS votes FROM restaurants ORDER BY count DESC LIMIT 1;"

# 4. RESET ALL VOTES (for testing)
docker exec mcdonalds-yelb-db psql -U postgres -d yelbdatabase -c "UPDATE restaurants SET count = 0;"

# 5. ADD VOTES TO SPECIFIC RESTAURANT (for testing)
docker exec mcdonalds-yelb-db psql -U postgres -d yelbdatabase -c "UPDATE restaurants SET count = count + 5 WHERE name = 'ihop';"

# 6. SET SPECIFIC VOTE COUNT
docker exec mcdonalds-yelb-db psql -U postgres -d yelbdatabase -c "UPDATE restaurants SET count = 10 WHERE name = 'chipotle';"
```

---

## 🔄 High Availability Testing

### Test Redis Automatic Failover

This test demonstrates how Sentinel automatically promotes a replica when the master fails.

#### Step 1: Check Current Master

```bash
# Identify the current Redis master
docker exec mcdonalds-redis-sentinel01 redis-cli -p 5000 SENTINEL get-master-addr-by-name mymaster
```

**Output example:**
```
1) "172.18.0.4"
2) "6379"
```

**Note the IP address** - this is the current master.

---

#### Step 2: Simulate Master Failure

```bash
# Stop the Redis master (simulates server crash)
docker stop mcdonalds-redis-server
```

**What this does:**
- Stops the master container immediately
- Simulates a production server failure
- Triggers sentinel failover process

---

#### Step 3: Monitor Failover Process

```bash
# Watch sentinel logs in real-time
docker logs -f mcdonalds-redis-sentinel01
```

**What to look for in logs:**
```
+sdown master mymaster         # Subjectively down
+odown master mymaster         # Objectively down (quorum)
+vote-for-leader               # Sentinels voting
+elected-leader                # Leader elected
+failover-state-select-slave   # Selecting new master
+selected-slave                # New master chosen
+failover-state-send-slaveof-noone  # Promoting slave
+failover-end                  # Failover complete
+switch-master mymaster        # Master switched
```

**Press Ctrl+C to exit logs**

---

#### Step 4: Verify New Master

```bash
# Wait 10-15 seconds, then check new master
sleep 15

docker exec mcdonalds-redis-sentinel01 redis-cli -p 5000 SENTINEL get-master-addr-by-name mymaster
```

**Output example:**
```
1) "172.18.0.5"  # Different IP - this is the new master!
2) "6379"
```

**What happened:**
1. ✅ Sentinel detected master failure (after 5 seconds)
2. ✅ Quorum reached (2 out of 3 sentinels agreed)
3. ✅ Replica promoted to new master
4. ✅ Other replica reconfigured to follow new master

---

#### Step 5: Verify Application Still Works

```bash
# Test that the application is still functioning
curl http://localhost

# Open browser and test voting
# The application should work normally despite master failure!
```

**This proves:**
- ✅ Zero downtime during failover
- ✅ Automatic recovery
- ✅ No manual intervention required

---

#### Step 6: Restart Original Master

```bash
# Restart the original master
docker start mcdonalds-redis-server

# Wait 5 seconds
sleep 5

# Check its new role
docker exec mcdonalds-redis-server redis-cli -a a-very-complex-password-here INFO replication
```

**Expected output:**
```
# Replication
role:slave                      # Now a REPLICA, not master!
master_host:172.18.0.5          # Following the new master
master_port:6379
master_link_status:up
```

**What happened:**
- The original master rejoined the cluster
- Sentinel automatically configured it as a replica
- It now follows the new master
- No data was lost during failover

---

### Failover Timeline

```
Time    Event
─────────────────────────────────────────────────────────
0s      Master crashes (docker stop)
5s      Sentinels detect failure (down-after-milliseconds)
6s      Quorum reached (2/3 sentinels agree)
7s      Leader sentinel starts failover
8s      New master selected from replicas
9s      Replica promoted to master
10s     Other replica reconfigured
11s     Failover complete
        Application continues working
```

**Total Downtime: ~10 seconds**

---

## 🛠️ Management & Maintenance

### View Resource Usage

```bash
# Monitor CPU and memory usage of all containers
docker stats

# Shows real-time:
# - CPU percentage
# - Memory usage
# - Network I/O
# - Block I/O

# Press Ctrl+C to exit
```

---

### View Logs

```bash
# View logs from all services
docker-compose logs

# View logs from specific service
docker-compose logs yelb-ui
docker-compose logs yelb-appserver
docker-compose logs redis-server

# Follow logs in real# odilia-mcdonalds