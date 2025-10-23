# Infrastructure Services
output "infrastructure_ip" {
  description = "IP address of infrastructure services droplet"
  value       = digitalocean_droplet.infrastructure.ipv4_address
}

output "eureka_url" {
  description = "Eureka Registry URL"
  value       = "http://${digitalocean_droplet.infrastructure.ipv4_address}:8761"
}

output "config_server_url" {
  description = "Config Server URL"
  value       = "http://${digitalocean_droplet.infrastructure.ipv4_address}:8888"
}

output "api_gateway_url" {
  description = "API Gateway URL"
  value       = "http://${digitalocean_droplet.infrastructure.ipv4_address}:8080"
}

# Load Balancer
#output "load_balancer_ip" {
#  description = "IP address of load balancer"
#  value       = digitalocean_droplet.load_balancer.ipv4_address
#}

# Application URL (now served by infrastructure)
output "application_url" {
  description = "Public application URL"
  #value       = "http://${digitalocean_droplet.load_balancer.ipv4_address}"
  value       = "http://${digitalocean_droplet.infrastructure.ipv4_address}"
}

# Business Services
output "user_service_ip" {
  description = "IP address of user service"
  value       = digitalocean_droplet.user_service.ipv4_address
}

output "content_service_ip" {
  description = "IP address of content service"
  value       = digitalocean_droplet.content_service.ipv4_address
}

#output "analytics_service_ip" {
#  description = "IP address of analytics service"
#  value       = digitalocean_droplet.analytics_service.ipv4_address
#}

output "engagement_service_ip" {
  description = "IP address of engagement service"
  value       = digitalocean_droplet.engagement_service.ipv4_address
}

output "gamification_service_ip" {
  description = "IP address of gamification service"
  value       = digitalocean_droplet.gamification_service.ipv4_address
}

# Database Services
output "user_db_ip" {
  description = "IP address of user database"
  value       = digitalocean_droplet.user_db.ipv4_address
}

output "content_db_ip" {
  description = "IP address of content database"
  value       = digitalocean_droplet.content_db.ipv4_address
}

#output "analytics_db_ip" {
#  description = "IP address of analytics database"
#  value       = digitalocean_droplet.analytics_db.ipv4_address
#}

output "engagement_db_ip" {
  description = "IP address of engagement database"
  value       = digitalocean_droplet.engagement_db.ipv4_address
}

output "gamification_db_ip" {
  description = "IP address of gamification database"
  value       = digitalocean_droplet.gamification_db.ipv4_address
}

# Service Endpoints
output "service_endpoints" {
  description = "All service endpoints"
  value = {
    user_service = "${digitalocean_droplet.user_service.ipv4_address}:8081"
    content_service = "${digitalocean_droplet.content_service.ipv4_address}:8082"
    #analytics_service = "${digitalocean_droplet.analytics_service.ipv4_address}:8083"
    engagement_service = "${digitalocean_droplet.engagement_service.ipv4_address}:8084"
    gamification_service = "${digitalocean_droplet.gamification_service.ipv4_address}:8085"
  }
}

# Database Endpoints
output "database_endpoints" {
  description = "All database endpoints"
  value = {
    user_postgres = "${digitalocean_droplet.user_db.ipv4_address}:5432"
    user_redis = "${digitalocean_droplet.user_db.ipv4_address}:6379"
    content_postgres = "${digitalocean_droplet.content_db.ipv4_address}:5432"
    content_redis = "${digitalocean_droplet.content_db.ipv4_address}:6379"
    content_elasticsearch = "${digitalocean_droplet.content_db.ipv4_address}:9200"
    #analytics_postgres = "${digitalocean_droplet.analytics_db.ipv4_address}:5432"
    #analytics_redis = "${digitalocean_droplet.analytics_db.ipv4_address}:6379"
    engagement_postgres = "${digitalocean_droplet.engagement_db.ipv4_address}:5432"
    engagement_redis = "${digitalocean_droplet.engagement_db.ipv4_address}:6379"
    gamification_postgres = "${digitalocean_droplet.gamification_db.ipv4_address}:5432"
    gamification_redis = "${digitalocean_droplet.gamification_db.ipv4_address}:6379"
  }
}

# Connection file for SSH access
resource "local_file" "ssh_connection_file" {
  #filename = "root@${digitalocean_droplet.load_balancer.ipv4_address}"
  filename = "root@${digitalocean_droplet.infrastructure.ipv4_address}"
  content  = ""
  file_permission = "0444"
}
