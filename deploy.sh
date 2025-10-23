#!/bin/bash

# Yushan Microservices - Terraform Deployment Script
# This script automates the deployment of all microservices to Digital Ocean

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

# Check if required environment variables are set
check_environment() {
    print_status "Checking environment variables..."
    
    if [ -z "$DO_PAT" ]; then
        print_error "DO_PAT environment variable is not set"
        print_status "Please set your Digital Ocean Personal Access Token:"
        print_status "export DO_PAT='your_digital_ocean_token'"
        exit 1
    fi
    
    if [ -z "$SSH_PRIVATE_KEY_PATH" ]; then
        print_warning "SSH_PRIVATE_KEY_PATH not set, using default: ~/.ssh/id_rsa"
        export SSH_PRIVATE_KEY_PATH="~/.ssh/id_rsa"
    fi
    
    if [ -z "$GITHUB_USERNAME" ]; then
        print_error "GITHUB_USERNAME environment variable is not set"
        print_status "Please set your GitHub username for container registry:"
        print_status "export GITHUB_USERNAME='your-github-username'"
        exit 1
    fi
    
    print_success "Environment variables checked"
}

# Check if Terraform is installed
check_terraform() {
    print_status "Checking Terraform installation..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed"
        print_status "Please install Terraform first:"
        print_status "sudo snap install terraform --classic"
        exit 1
    fi
    
    print_success "Terraform is installed: $(terraform --version | head -n1)"
}

# Check if Docker Machine is installed (Optional)
check_docker_machine() {
    print_status "Checking Docker Machine installation..."
    
    print_warning "Skipping Docker Machine setup for cost optimization"
    print_status "Using direct Terraform deployment without Docker Machine"
    export SKIP_DOCKER_MACHINE=true
    return 0
}

# Create Docker Machine for container management (Optional)
create_docker_machine() {
    if [ "$SKIP_DOCKER_MACHINE" = "true" ]; then
        print_status "Skipping Docker Machine creation..."
        export DOCKER_HOST_IP=""
        export DOCKER_CERT_PATH=""
        return 0
    fi
    
    print_status "Creating Docker Machine for container management..."
    
    if docker-machine ls | grep -q "yushan-docker-host"; then
        print_warning "Docker Machine 'yushan-docker-host' already exists"
        print_status "Using existing Docker Machine..."
    else
        print_status "Creating new Docker Machine..."
        docker-machine create \
            -d digitalocean \
            --digitalocean-access-token "$DO_PAT" \
            --digitalocean-image ubuntu-22-04-x64 \
            --digitalocean-region sgp1 \
            --digitalocean-backups=false \
            yushan-docker-host
    fi
    
    # Get Docker Machine IP
    DOCKER_HOST_IP=$(docker-machine ip yushan-docker-host)
    DOCKER_CERT_PATH=$(docker-machine inspect yushan-docker-host --format='{{.HostOptions.AuthOptions.StorePath}}')
    
    print_success "Docker Machine created/configured"
    print_status "Docker Host IP: $DOCKER_HOST_IP"
    print_status "Docker Cert Path: $DOCKER_CERT_PATH"
}

# Initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    
    terraform init
    
    print_success "Terraform initialized"
}

# Plan Terraform deployment
plan_terraform() {
    print_status "Planning Terraform deployment..."
    
    if [ "$SKIP_DOCKER_MACHINE" = "true" ]; then
        terraform plan \
            -var="do_token=$DO_PAT" \
            -var="ssh_private_key=$SSH_PRIVATE_KEY_PATH" \
            -var="github_username=$GITHUB_USERNAME"
    else
        terraform plan \
            -var="do_token=$DO_PAT" \
            -var="ssh_private_key=$SSH_PRIVATE_KEY_PATH" \
            -var="docker_host=$DOCKER_HOST_IP" \
            -var="docker_cert_path=$DOCKER_CERT_PATH" \
            -var="github_username=$GITHUB_USERNAME"
    fi
    
    print_success "Terraform plan completed"
}

# Apply Terraform deployment
apply_terraform() {
    print_status "Applying Terraform deployment..."
    
    if [ "$SKIP_DOCKER_MACHINE" = "true" ]; then
        terraform apply -auto-approve \
            -var="do_token=$DO_PAT" \
            -var="ssh_private_key=$SSH_PRIVATE_KEY_PATH" \
            -var="github_username=$GITHUB_USERNAME"
    else
        terraform apply -auto-approve \
            -var="do_token=$DO_PAT" \
            -var="ssh_private_key=$SSH_PRIVATE_KEY_PATH" \
            -var="docker_host=$DOCKER_HOST_IP" \
            -var="docker_cert_path=$DOCKER_CERT_PATH" \
            -var="github_username=$GITHUB_USERNAME"
    fi
    
    print_success "Terraform deployment completed"
}

# Show deployment results
show_results() {
    print_status "Deployment Results:"
    echo ""
    
    print_status "Application URL:"
    terraform output -raw application_url
    echo ""
    
    print_status "Service Endpoints:"
    terraform output service_endpoints
    echo ""
    
    print_status "Database Endpoints:"
    terraform output database_endpoints
    echo ""
    
    print_status "Infrastructure Services:"
    print_status "Eureka Registry: $(terraform output -raw eureka_url)"
    print_status "Config Server: $(terraform output -raw config_server_url)"
    print_status "API Gateway: $(terraform output -raw api_gateway_url)"
    echo ""
}

# Test deployment
test_deployment() {
    print_status "Testing deployment..."
    
    # LOAD_BALANCER_IP=$(terraform output -raw load_balancer_ip)  # Commented out - load balancer merged into infrastructure
    
    INFRASTRUCTURE_IP=$(terraform output -raw infrastructure_ip)
    print_status "Testing health endpoint..."
    if curl -f -s "http://$INFRASTRUCTURE_IP/health" > /dev/null; then
        print_success "Health check passed"
    else
        print_error "Health check failed"
    fi
    
    print_status "Testing API Gateway..."
    if curl -f -s "http://$INFRASTRUCTURE_IP/api/v1/health" > /dev/null; then
        print_success "API Gateway is responding"
    else
        print_warning "API Gateway might not be ready yet (this is normal during startup)"
    fi
    
    print_success "Deployment testing completed"
}

# Main deployment function
main() {
    print_status "Starting Yushan Microservices Deployment..."
    echo ""
    
    check_environment
    check_terraform
    check_docker_machine
    create_docker_machine
    init_terraform
    plan_terraform
    
    echo ""
    print_warning "This will create 12 Digital Ocean droplets (~$48/month)"
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        apply_terraform
        show_results
        test_deployment
        
        echo ""
        print_success "🎉 Deployment completed successfully!"
        print_status "Your application is available at: $(terraform output -raw application_url)"
        print_status "Eureka Dashboard: $(terraform output -raw eureka_url)"
    else
        print_status "Deployment cancelled"
        exit 0
    fi
}

# Run main function
main "$@"
