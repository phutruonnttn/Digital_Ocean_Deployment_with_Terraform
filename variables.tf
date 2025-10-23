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

variable "do_size_small" {
  description = "Small droplet size for infrastructure services"
  type        = string
  default     = "s-1vcpu-512mb-10gb"  # $4/month
}

variable "do_size_medium" {
  description = "Medium droplet size for business services"
  type        = string
  default     = "s-1vcpu-512mb-10gb"  # $4/month
}

variable "do_size_large" {
  description = "Large droplet size for databases"
  type        = string
  default     = "s-1vcpu-512mb-10gb"  # $4/month
}

variable "do_ssh_key_name" {
  description = "SSH key name in Digital Ocean"
  type        = string
  default     = "yushan-ssh-key"
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
  default     = "yushan"
}

# GitHub Container Registry Configuration
variable "github_username" {
  description = "GitHub username for container registry"
  type        = string
  default     = "maugus0"
}

variable "environment" {
  description = "Environment (dev, staging, production)"
  type        = string
  default     = "production"
}

# Database Configuration
variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "yushan_secure_password_2024"
}

variable "redis_password" {
  description = "Redis password"
  type        = string
  sensitive   = true
  default     = "yushan_redis_password_2024"
}

# JWT Configuration
variable "jwt_secret" {
  description = "JWT secret key"
  type        = string
  sensitive   = true
  default     = "yushan_jwt_secret_key_2024_production"
}

# Mail Configuration
variable "mail_host" {
  description = "Mail server host"
  type        = string
  default     = "smtp.gmail.com"
}

variable "mail_username" {
  description = "Mail username"
  type        = string
  default     = "noreply@yushan.com"
}

variable "mail_password" {
  description = "Mail password"
  type        = string
  sensitive   = true
  default     = ""
}

# S3/Spaces Configuration
variable "spaces_access_key" {
  description = "Digital Ocean Spaces access key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "spaces_secret_key" {
  description = "Digital Ocean Spaces secret key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "spaces_bucket" {
  description = "Digital Ocean Spaces bucket name"
  type        = string
  default     = "yushan-content"
}

variable "spaces_endpoint" {
  description = "Digital Ocean Spaces endpoint"
  type        = string
  default     = "https://sgp1.digitaloceanspaces.com"
}
