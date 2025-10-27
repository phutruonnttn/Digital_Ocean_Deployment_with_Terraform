#!/bin/bash

# Yushan Monitoring Infrastructure Deployment Script
# This script deploys centralized logging and metrics monitoring on Digital Ocean

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists terraform; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if [ ! -f ".env" ]; then
        print_error ".env file not found. Please copy .env.example to .env and configure it."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to load environment variables
load_env() {
    print_status "Loading environment variables..."
    source .env
    
    # Validate required variables
    required_vars=(
        "DO_PAT"
        "SSH_PRIVATE_KEY_PATH"
        "EXISTING_INFRASTRUCTURE_IP"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            print_error "Required environment variable $var is not set"
            exit 1
        fi
    done
    
    print_success "Environment variables loaded"
}

# Function to initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    terraform init
    print_success "Terraform initialized"
}

# Function to validate Terraform configuration
validate_terraform() {
    print_status "Validating Terraform configuration..."
    terraform validate
    print_success "Terraform configuration is valid"
}

# Function to plan Terraform deployment
plan_terraform() {
    print_status "Planning Terraform deployment..."
    terraform plan -out=tfplan
    print_success "Terraform plan created"
}

# Function to apply Terraform configuration
apply_terraform() {
    print_status "Applying Terraform configuration..."
    terraform apply tfplan
    print_success "Terraform configuration applied"
}

# Function to wait for services to be ready
wait_for_services() {
    print_status "Waiting for services to be ready..."
    
    # Get ELK stack IP
    ELK_IP=$(terraform output -raw elk_stack_ip)
    MONITORING_IP=$(terraform output -raw monitoring_stack_ip)
    
    print_status "ELK Stack IP: $ELK_IP"
    print_status "Monitoring Stack IP: $MONITORING_IP"
    
    # Wait for Elasticsearch
    print_status "Waiting for Elasticsearch to be ready..."
    until curl -s -u elastic:${ELASTICSEARCH_PASSWORD} "http://$ELK_IP:9200/_cluster/health" > /dev/null; do
        sleep 10
        echo -n "."
    done
    echo ""
    print_success "Elasticsearch is ready"
    
    # Wait for Kibana
    print_status "Waiting for Kibana to be ready..."
    until curl -s "http://$ELK_IP:5601/api/status" > /dev/null; do
        sleep 10
        echo -n "."
    done
    echo ""
    print_success "Kibana is ready"
    
    # Wait for Prometheus
    print_status "Waiting for Prometheus to be ready..."
    until curl -s "http://$MONITORING_IP:9090/-/ready" > /dev/null; do
        sleep 10
        echo -n "."
    done
    echo ""
    print_success "Prometheus is ready"
    
    # Wait for Grafana
    print_status "Waiting for Grafana to be ready..."
    until curl -s "http://$MONITORING_IP:3000/api/health" > /dev/null; do
        sleep 10
        echo -n "."
    done
    echo ""
    print_success "Grafana is ready"
}

# Function to configure Grafana datasources
configure_grafana() {
    print_status "Configuring Grafana datasources..."
    
    MONITORING_IP=$(terraform output -raw monitoring_stack_ip)
    ELK_IP=$(terraform output -raw elk_stack_ip)
    
    # Wait a bit more for Grafana to be fully ready
    sleep 30
    
    # Add Prometheus datasource
    curl -X POST "http://$MONITORING_IP:3000/api/datasources" \
        -H "Content-Type: application/json" \
        -u admin:${GRAFANA_PASSWORD} \
        -d '{
            "name": "Prometheus",
            "type": "prometheus",
            "url": "http://prometheus:9090",
            "access": "proxy",
            "isDefault": true
        }' || print_warning "Failed to add Prometheus datasource"
    
    # Add Elasticsearch datasource
    curl -X POST "http://$MONITORING_IP:3000/api/datasources" \
        -H "Content-Type: application/json" \
        -u admin:${GRAFANA_PASSWORD} \
        -d '{
            "name": "Elasticsearch",
            "type": "elasticsearch",
            "url": "http://'$ELK_IP':9200",
            "access": "proxy",
            "database": "yushan-logs-*",
            "user": "elastic",
            "password": "'${ELASTICSEARCH_PASSWORD}'"
        }' || print_warning "Failed to add Elasticsearch datasource"
    
    print_success "Grafana datasources configured"
}

# Function to display deployment summary
show_summary() {
    print_success "Deployment completed successfully!"
    echo ""
    echo "=========================================="
    echo "           DEPLOYMENT SUMMARY"
    echo "=========================================="
    echo ""
    
    # Get outputs
    ELK_IP=$(terraform output -raw elk_stack_ip)
    MONITORING_IP=$(terraform output -raw monitoring_stack_ip)
    LB_IP=$(terraform output -raw monitoring_lb_ip)
    
    echo "ELK Stack Services:"
    echo "  - Elasticsearch: http://$ELK_IP:9200"
    echo "  - Kibana: http://$ELK_IP:5601"
    echo "  - Logstash: http://$ELK_IP:5044"
    echo ""
    
    echo "Monitoring Services:"
    echo "  - Prometheus: http://$MONITORING_IP:9090"
    echo "  - Grafana: http://$MONITORING_IP:3000"
    echo "  - Alertmanager: http://$MONITORING_IP:9093"
    echo ""
    
    echo "Load Balancer:"
    echo "  - URL: http://$LB_IP"
    echo ""
    
    echo "Credentials:"
    echo "  - Elasticsearch: elastic / ${ELASTICSEARCH_PASSWORD}"
    echo "  - Kibana: kibana_system / ${KIBANA_PASSWORD}"
    echo "  - Grafana: admin / ${GRAFANA_PASSWORD}"
    echo ""
    
    echo "SSH Access:"
    echo "  - ELK Stack: ssh root@$ELK_IP"
    echo "  - Monitoring: ssh root@$MONITORING_IP"
    echo ""
    
    echo "Next Steps:"
    echo "  1. Configure your applications to send logs to Logstash"
    echo "  2. Import Grafana dashboards for monitoring"
    echo "  3. Set up alerting rules in Prometheus"
    echo "  4. Configure log retention policies"
    echo ""
}

# Function to cleanup on error
cleanup() {
    print_error "Deployment failed. Cleaning up..."
    if [ -f "tfplan" ]; then
        rm -f tfplan
    fi
    exit 1
}

# Set trap for cleanup
trap cleanup ERR

# Main deployment function
main() {
    echo "=========================================="
    echo "    YUSHAN MONITORING DEPLOYMENT"
    echo "=========================================="
    echo ""
    
    check_prerequisites
    load_env
    init_terraform
    validate_terraform
    plan_terraform
    
    # Ask for confirmation
    echo ""
    print_warning "This will deploy monitoring infrastructure on Digital Ocean."
    print_warning "Estimated cost: ~$72/month (ELK: $48/month + Monitoring: $24/month)"
    echo ""
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Deployment cancelled"
        exit 0
    fi
    
    apply_terraform
    wait_for_services
    configure_grafana
    show_summary
}

# Run main function
main "$@"
