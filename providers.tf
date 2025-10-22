terraform {
  required_version = ">= 1.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.26.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }
  }
}

# Digital Ocean Provider
provider "digitalocean" {
  token = var.do_token
}

# Docker Provider for container management
provider "docker" {
  host = "tcp://${var.docker_host}:2376"
  cert_path = var.docker_cert_path
}

# Local Provider for file operations
provider "local" {}

# Null Provider for resource dependencies
provider "null" {}
