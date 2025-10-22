# Yushan Microservices - Terraform Deployment Guide

## 🎯 Overview
This guide will help you deploy all 8 microservices to Digital Ocean using Terraform automation.

## 📊 Architecture
- **12 Droplets Total** (~$144/month)
- **Infrastructure Services**: 1 droplet (Eureka, Config Server, API Gateway)
- **Business Services**: 5 droplets (User, Content, Analytics, Engagement, Gamification)
- **Databases**: 5 droplets (PostgreSQL + Redis for each service, Elasticsearch for Content)
- **Load Balancer**: 1 droplet (Nginx reverse proxy)

## 🚀 Quick Start

### Prerequisites
1. **Digital Ocean Account** with billing enabled
2. **SSH Key Pair** generated and added to DO
3. **DO Personal Access Token** with write permissions
4. **Ubuntu Server** (for running Terraform)

### Step 1: Setup Environment
```bash
# 1. Create Ubuntu Droplet on Digital Ocean
# - Region: Singapore (sgp1)
# - Image: Ubuntu 22.04 x64
# - Size: s-2vcpu-2gb ($12/month)
# - Add your SSH key

# 2. SSH into your server
ssh root@<your-server-ip>

# 3. Install required tools
sudo apt update
sudo apt install -y curl wget git

# Install Terraform
sudo snap install terraform --classic

# Install Docker Machine
curl -O "https://gitlab-docker-machine-downloads.s3.amazonaws.com/v0.16.2-gitlab.40/docker-machine-Linux-x86_64"
mv docker-machine-Linux-x86_64 docker-machine
chmod +x docker-machine
sudo mv docker-machine /usr/local/bin

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker root
```

### Step 2: Setup SSH Keys
```bash
# Generate SSH key pair (if not exists)
ssh-keygen -t rsa -b 4096 -C "yushan-deployment"

# Add public key to Digital Ocean
# 1. Go to Digital Ocean → Account → Security → SSH Keys
# 2. Add new SSH key with name "yushan-ssh-key"
# 3. Paste the content of ~/.ssh/id_rsa.pub

# Set environment variables
export SSH_PRIVATE_KEY_PATH="/root/.ssh/id_rsa"
```

### Step 3: Get Digital Ocean Token
```bash
# 1. Go to Digital Ocean → API → Personal Access Tokens
# 2. Generate new token with write permissions
# 3. Set environment variable
export DO_PAT="your_digital_ocean_token_here"
```

### Step 4: Clone and Deploy
```bash
# Clone the repository
git clone <your-repo-url>
cd yushan-micro/terraform-deployment

# Run deployment script
./deploy.sh
```

## 🔧 Manual Deployment

If you prefer manual deployment:

### Step 1: Create Docker Machine
```bash
docker-machine create \
    -d digitalocean \
    --digitalocean-access-token "$DO_PAT" \
    --digitalocean-image ubuntu-22-04-x64 \
    --digitalocean-region sgp1 \
    --digitalocean-backups=false \
    yushan-docker-host

# Get Docker Machine details
DOCKER_HOST_IP=$(docker-machine ip yushan-docker-host)
DOCKER_CERT_PATH=$(docker-machine inspect yushan-docker-host --format='{{.HostOptions.AuthOptions.StorePath}}')
```

### Step 2: Initialize Terraform
```bash
terraform init
```

### Step 3: Plan Deployment
```bash
terraform plan \
    -var="do_token=$DO_PAT" \
    -var="ssh_private_key=$SSH_PRIVATE_KEY_PATH" \
    -var="docker_host=$DOCKER_HOST_IP" \
    -var="docker_cert_path=$DOCKER_CERT_PATH"
```

### Step 4: Apply Deployment
```bash
terraform apply \
    -var="do_token=$DO_PAT" \
    -var="ssh_private_key=$SSH_PRIVATE_KEY_PATH" \
    -var="docker_host=$DOCKER_HOST_IP" \
    -var="docker_cert_path=$DOCKER_CERT_PATH"
```

## 📋 Configuration

### Environment Variables
```bash
# Required
export DO_PAT="your_digital_ocean_token"
export SSH_PRIVATE_KEY_PATH="/root/.ssh/id_rsa"

# Optional (with defaults)
export DO_REGION="sgp1"
export DO_IMAGE="ubuntu-22-04-x64"
export APP_NAMESPACE="yushan"
export ENVIRONMENT="production"
export DB_PASSWORD="yushan_secure_password_2024"
export JWT_SECRET="yushan_jwt_secret_key_2024_production"
```

### Custom Configuration
Edit `variables.tf` to customize:
- Droplet sizes
- Regions
- Database passwords
- JWT secrets
- Mail configuration
- S3/Spaces configuration

## 🌐 Accessing Services

After deployment, you can access:

### Public URLs
- **Application**: `http://<load-balancer-ip>`
- **Health Check**: `http://<load-balancer-ip>/health`

### Service URLs (Internal)
- **Eureka Registry**: `http://<infrastructure-ip>:8761`
- **Config Server**: `http://<infrastructure-ip>:8888`
- **API Gateway**: `http://<infrastructure-ip>:8080`

### Service Endpoints
- **User Service**: `http://<user-service-ip>:8081`
- **Content Service**: `http://<content-service-ip>:8082`
- **Analytics Service**: `http://<analytics-service-ip>:8083`
- **Engagement Service**: `http://<engagement-service-ip>:8084`
- **Gamification Service**: `http://<gamification-service-ip>:8085`

## 🗄️ Database Access

### PostgreSQL Databases
- **User DB**: `<user-db-ip>:5432`
- **Content DB**: `<content-db-ip>:5432`
- **Analytics DB**: `<analytics-db-ip>:5432`
- **Engagement DB**: `<engagement-db-ip>:5432`
- **Gamification DB**: `<gamification-db-ip>:5432`

### Redis Instances
- **User Redis**: `<user-db-ip>:6379`
- **Content Redis**: `<content-db-ip>:6379`
- **Analytics Redis**: `<analytics-db-ip>:6379`
- **Engagement Redis**: `<engagement-db-ip>:6379`
- **Gamification Redis**: `<gamification-db-ip>:6379`

### Elasticsearch
- **Content Elasticsearch**: `<content-db-ip>:9200`

## 🔍 Monitoring

### Health Checks
```bash
# Check all services
curl http://<load-balancer-ip>/health

# Check Eureka registry
curl http://<infrastructure-ip>:8761/eureka/apps

# Check individual services
curl http://<service-ip>:<port>/actuator/health
```

### Logs
```bash
# SSH into any droplet
ssh root@<droplet-ip>

# Check Docker logs
docker logs <container-name>

# Check system logs
journalctl -u docker
```

## 🛠️ Troubleshooting

### Common Issues

#### 1. Services Not Starting
```bash
# Check Docker status
docker ps -a

# Check logs
docker logs <container-name>

# Restart service
docker restart <container-name>
```

#### 2. Database Connection Issues
```bash
# Check database status
docker exec -it <db-container> pg_isready

# Check Redis status
docker exec -it <redis-container> redis-cli ping
```

#### 3. Network Issues
```bash
# Check Docker network
docker network ls
docker network inspect <network-name>

# Test connectivity
docker exec -it <container> ping <target-ip>
```

### Scaling Services
```bash
# Scale a service (example: user service)
docker run -d --name yushan-user-service-2 \
    --restart unless-stopped \
    -p 8086:8081 \
    -e SPRING_PROFILES_ACTIVE=production \
    # ... other environment variables
    yushan/user-service:latest
```

## 💰 Cost Optimization

### Current Cost Breakdown
- **Infrastructure**: $12/month (s-2vcpu-2gb)
- **Business Services**: $60/month (5 × s-2vcpu-2gb)
- **Databases**: $120/month (5 × s-2vcpu-4gb)
- **Load Balancer**: $6/month (s-1vcpu-1gb)
- **Total**: ~$198/month

### Cost Reduction Options
1. **Use smaller droplets** for non-critical services
2. **Consolidate databases** on fewer droplets
3. **Use Digital Ocean managed databases** (more expensive but less maintenance)
4. **Implement auto-scaling** based on load

## 🔒 Security

### Security Checklist
- [ ] Change default passwords
- [ ] Enable firewall rules
- [ ] Use SSL/TLS certificates
- [ ] Regular security updates
- [ ] Monitor access logs
- [ ] Backup databases regularly

### SSL Setup (Optional)
```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

## 📚 Additional Resources

- [Digital Ocean API Documentation](https://docs.digitalocean.com/reference/api/)
- [Terraform Digital Ocean Provider](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs)
- [Docker Machine Digital Ocean Driver](https://docs.docker.com/machine/drivers/digital-ocean/)
- [Nginx Configuration Guide](https://nginx.org/en/docs/)

## 🆘 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review Terraform logs: `terraform logs`
3. Check Docker logs on each droplet
4. Verify all environment variables are set correctly
5. Ensure Digital Ocean account has sufficient credits

## 📝 Notes

- **Startup Time**: Services may take 2-5 minutes to fully start
- **Health Checks**: Some services may fail initial health checks during startup
- **Database Initialization**: First-time database setup may take additional time
- **Network Connectivity**: Ensure all droplets can communicate with each other
- **Resource Usage**: Monitor CPU and memory usage, especially on database droplets
