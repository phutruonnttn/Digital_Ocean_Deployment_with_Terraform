# Digital Ocean Configuration
variable "do_token" {
  description = "Digital Ocean Personal Access Token"
  type        = string
  sensitive   = true
}

variable "do_region" {
  description = "Digital Ocean region"
  type        = string
  default     = "sgp1"
}

variable "do_image" {
  description = "Digital Ocean image"
  type        = string
  default     = "ubuntu-22-04-x64"
}

variable "do_size_logging" {
  description = "Droplet size for ELK Stack"
  type        = string
  default     = "s-4vcpu-8gb"  # $48/month - cần RAM cao cho Elasticsearch
}

variable "do_size_monitoring" {
  description = "Droplet size for Prometheus/Grafana"
  type        = string
  default     = "s-2vcpu-4gb"  # $24/month
}

variable "do_ssh_key_name" {
  description = "SSH key name in Digital Ocean"
  type        = string
  default     = "yushan-monitoring-ssh-key"
}

# SSH Configuration
variable "ssh_private_key" {
  description = "Path to SSH private key"
  type        = string
  default     = "~/.ssh/id_rsa"
}

# Application Configuration
variable "app_namespace" {
  description = "Application namespace prefix"
  type        = string
  default     = "yushan-monitoring"
}

variable "environment" {
  description = "Environment (dev, staging, production)"
  type        = string
  default     = "production"
}

# Existing Infrastructure Configuration (from main deployment)
variable "existing_infrastructure_ip" {
  description = "IP address of existing infrastructure droplet"
  type        = string
}

variable "existing_service_ips" {
  description = "Map of existing service IPs"
  type = map(string)
  default = {}
}

variable "existing_db_ips" {
  description = "Map of existing database IPs"
  type = map(string)
  default = {}
}

# Logging Configuration
variable "elasticsearch_password" {
  description = "Elasticsearch password"
  type        = string
  sensitive   = true
  default     = "yushan_elasticsearch_password_2024"
}

variable "kibana_password" {
  description = "Kibana password"
  type        = string
  sensitive   = true
  default     = "yushan_kibana_password_2024"
}

variable "logstash_password" {
  description = "Logstash password"
  type        = string
  sensitive   = true
  default     = "yushan_logstash_password_2024"
}

# Monitoring Configuration
variable "prometheus_password" {
  description = "Prometheus password"
  type        = string
  sensitive   = true
  default     = "yushan_prometheus_password_2024"
}

variable "grafana_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "yushan_grafana_password_2024"
}

variable "grafana_admin_user" {
  description = "Grafana admin username"
  type        = string
  default     = "admin"
}

# Alerting Configuration
variable "alertmanager_slack_webhook" {
  description = "Slack webhook URL for alerts"
  type        = string
  sensitive   = true
  default     = ""
}

variable "alertmanager_email" {
  description = "Email for alerts"
  type        = string
  default     = "admin@yushan.com"
}

# Retention Configuration
variable "elasticsearch_retention_days" {
  description = "Elasticsearch data retention in days"
  type        = number
  default     = 30
}

variable "prometheus_retention_days" {
  description = "Prometheus data retention in days"
  type        = number
  default     = 15
}

# Security Configuration
variable "enable_ssl" {
  description = "Enable SSL/TLS for monitoring services"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Domain name for monitoring services"
  type        = string
  default     = ""
}
