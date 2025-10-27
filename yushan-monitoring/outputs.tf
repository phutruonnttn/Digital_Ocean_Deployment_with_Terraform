# ELK Stack Outputs
output "elk_stack_ip" {
  description = "IP address of ELK Stack droplet"
  value       = digitalocean_droplet.elk_stack.ipv4_address
}

output "elasticsearch_url" {
  description = "Elasticsearch URL"
  value       = "http://${digitalocean_droplet.elk_stack.ipv4_address}:9200"
}

output "kibana_url" {
  description = "Kibana URL"
  value       = "http://${digitalocean_droplet.elk_stack.ipv4_address}:5601"
}

output "logstash_url" {
  description = "Logstash URL"
  value       = "http://${digitalocean_droplet.elk_stack.ipv4_address}:5044"
}

# Monitoring Stack Outputs
output "monitoring_stack_ip" {
  description = "IP address of Monitoring Stack droplet"
  value       = digitalocean_droplet.monitoring_stack.ipv4_address
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = "http://${digitalocean_droplet.monitoring_stack.ipv4_address}:9090"
}

output "grafana_url" {
  description = "Grafana URL"
  value       = "http://${digitalocean_droplet.monitoring_stack.ipv4_address}:3000"
}

output "alertmanager_url" {
  description = "Alertmanager URL"
  value       = "http://${digitalocean_droplet.monitoring_stack.ipv4_address}:9093"
}

# Load Balancer Outputs
output "monitoring_lb_ip" {
  description = "IP address of monitoring load balancer"
  value       = digitalocean_loadbalancer.monitoring_lb.ip
}

output "monitoring_lb_url" {
  description = "Monitoring load balancer URL"
  value       = "http://${digitalocean_loadbalancer.monitoring_lb.ip}"
}

# Service Endpoints
output "monitoring_endpoints" {
  description = "Map of monitoring service endpoints"
  value = {
    "grafana"       = "${digitalocean_droplet.monitoring_stack.ipv4_address}:3000"
    "prometheus"    = "${digitalocean_droplet.monitoring_stack.ipv4_address}:9090"
    "alertmanager"  = "${digitalocean_droplet.monitoring_stack.ipv4_address}:9093"
    "kibana"        = "${digitalocean_droplet.elk_stack.ipv4_address}:5601"
    "elasticsearch" = "${digitalocean_droplet.elk_stack.ipv4_address}:9200"
    "logstash"      = "${digitalocean_droplet.elk_stack.ipv4_address}:5044"
  }
}

# Credentials (sensitive)
output "elasticsearch_credentials" {
  description = "Elasticsearch credentials"
  value = {
    username = "elastic"
    password = var.elasticsearch_password
  }
  sensitive = true
}

output "kibana_credentials" {
  description = "Kibana credentials"
  value = {
    username = "kibana_system"
    password = var.kibana_password
  }
  sensitive = true
}

output "grafana_credentials" {
  description = "Grafana credentials"
  value = {
    username = var.grafana_admin_user
    password = var.grafana_password
  }
  sensitive = true
}

# Connection Information
output "connection_info" {
  description = "SSH connection information"
  value = {
    elk_ssh = "ssh root@${digitalocean_droplet.elk_stack.ipv4_address}"
    monitoring_ssh = "ssh root@${digitalocean_droplet.monitoring_stack.ipv4_address}"
  }
}

# Resource Summary
output "resource_summary" {
  description = "Summary of deployed resources"
  value = {
    elk_droplet_size = var.do_size_logging
    monitoring_droplet_size = var.do_size_monitoring
    total_droplets = 2
    load_balancer = "enabled"
    ssl_enabled = var.enable_ssl
  }
}
