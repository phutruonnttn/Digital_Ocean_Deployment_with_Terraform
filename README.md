# Yushan Microservices - Terraform Deployment

## Architecture Overview

### Infrastructure Services (1 Droplet)
- Eureka Registry (server-register)
- Config Server (yushan-config-server) 
- API Gateway (yushan-api-gateway)

### Business Services (5 Droplets)
- User Service
- Content Service
- Analytics Service
- Engagement Service
- Gamification Service

### Databases (5 Droplets)
- User PostgreSQL
- Content PostgreSQL + Redis + Elasticsearch
- Analytics PostgreSQL + Redis
- Engagement PostgreSQL + Redis
- Gamification PostgreSQL + Redis

### Load Balancer (1 Droplet)
- Nginx Reverse Proxy

## Total: 12 Droplets (~$144/month)

## Prerequisites
1. Digital Ocean Account
2. DO Personal Access Token
3. SSH Key Pair
4. Docker Machine setup

## Quick Start
```bash
# 1. Setup environment
export DO_PAT="your_digital_ocean_token"
export SSH_PRIVATE_KEY_PATH="/path/to/your/private/key"

# 2. Initialize Terraform
terraform init

# 3. Plan deployment
terraform plan -var="do_token=${DO_PAT}" -var="ssh_private_key=${SSH_PRIVATE_KEY_PATH}"

# 4. Deploy
terraform apply -var="do_token=${DO_PAT}" -var="ssh_private_key=${SSH_PRIVATE_KEY_PATH}"
```

## Directory Structure
```
terraform-deployment/
├── main.tf                 # Main Terraform configuration
├── variables.tf           # Variable definitions
├── outputs.tf            # Output definitions
├── providers.tf          # Provider configurations
├── infrastructure/       # Infrastructure services
├── business-services/    # Business services
├── databases/           # Database configurations
├── load-balancer/       # Nginx configuration
└── scripts/            # Deployment scripts
```
