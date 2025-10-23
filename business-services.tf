# User Service
resource "digitalocean_droplet" "user_service" {
  name   = "${var.app_namespace}-user-service"
  image  = var.do_image
  region = var.do_region
  size   = var.do_size_medium

  ssh_keys = [data.digitalocean_ssh_key.main.id]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.ssh_private_key)
    host        = self.ipv4_address
  }

  # Install Docker
  provisioner "remote-exec" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt update -y",
      "apt install -y apt-transport-https ca-certificates curl gnupg lsb-release",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "apt update -y",
      "apt install -y docker-ce docker-ce-cli containerd.io",
      "systemctl start docker",
      "systemctl enable docker"
    ]
  }

  # Deploy User Service
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-user-service --restart unless-stopped -p 8081:8081 -e SPRING_PROFILES_ACTIVE=production -e DB_USERNAME=yushan_user -e DB_PASSWORD=${var.db_password} -e DB_NAME=yushan_user -e DB_HOST=${digitalocean_droplet.user_db.ipv4_address} -e DB_PORT=5432 -e REDIS_HOST=${digitalocean_droplet.user_db.ipv4_address} -e REDIS_PORT=6379 -e JWT_SECRET=${var.jwt_secret} -e MAIL_HOST=${var.mail_host} -e MAIL_USERNAME=${var.mail_username} -e MAIL_PASSWORD=${var.mail_password} -e EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://${digitalocean_droplet.infrastructure.ipv4_address}:8761/eureka/ -e CONFIG_SERVER_URI=http://${digitalocean_droplet.infrastructure.ipv4_address}:8888 ghcr.io/${var.github_username}/yushan-user-service:latest"
    ]
  }
}

# Content Service
resource "digitalocean_droplet" "content_service" {
  name   = "${var.app_namespace}-content-service"
  image  = var.do_image
  region = var.do_region
  size   = var.do_size_medium

  ssh_keys = [data.digitalocean_ssh_key.main.id]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.ssh_private_key)
    host        = self.ipv4_address
  }

  # Install Docker
  provisioner "remote-exec" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt update -y",
      "apt install -y apt-transport-https ca-certificates curl gnupg lsb-release",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "apt update -y",
      "apt install -y docker-ce docker-ce-cli containerd.io",
      "systemctl start docker",
      "systemctl enable docker"
    ]
  }

  # Deploy Content Service
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-content-service --restart unless-stopped -p 8082:8082 -e SPRING_PROFILES_ACTIVE=production -e DB_USERNAME=yushan_content -e DB_PASSWORD=${var.db_password} -e DB_NAME=yushan_content -e DB_HOST=${digitalocean_droplet.content_db.ipv4_address} -e DB_PORT=5432 -e REDIS_HOST=${digitalocean_droplet.content_db.ipv4_address} -e REDIS_PORT=6379 -e ELASTICSEARCH_HOST=${digitalocean_droplet.content_db.ipv4_address} -e ELASTICSEARCH_PORT=9200 -e ELASTICSEARCH_SCHEME=http -e AWS_ACCESS_KEY_ID=${var.spaces_access_key} -e AWS_SECRET_ACCESS_KEY=${var.spaces_secret_key} -e AWS_S3_ENDPOINT=${var.spaces_endpoint} -e AWS_S3_BUCKET=${var.spaces_bucket} -e EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://${digitalocean_droplet.infrastructure.ipv4_address}:8761/eureka/ -e CONFIG_SERVER_URI=http://${digitalocean_droplet.infrastructure.ipv4_address}:8888 ghcr.io/${var.github_username}/yushan-content-service:latest"
    ]
  }
}

# Analytics Service
# resource "digitalocean_droplet" "analytics_service" {
#   name   = "${var.app_namespace}-analytics-service"
#   image  = var.do_image
#   region = var.do_region
#   size   = var.do_size_medium
# 
#   ssh_keys = [data.digitalocean_ssh_key.main.id]
# 
#   connection {
#     type        = "ssh"
#     user        = "root"
#     private_key = file(var.ssh_private_key)
#     host        = self.ipv4_address
#   }
# 
#   # Install Docker
#   provisioner "remote-exec" {
#     inline = [
#       "apt update -y",
#       "apt install -y apt-transport-https ca-certificates curl gnupg lsb-release",
#       "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
#       "echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | tee /etc/apt/sources.list.d/docker.list > /dev/null",
#       "apt update -y",
#       "apt install -y docker-ce docker-ce-cli containerd.io",
#       "systemctl start docker",
#       "systemctl enable docker"
#     ]
#   }
# 
#   # Deploy Analytics Service
#   provisioner "remote-exec" {
#     inline = [
#       "docker run -d --name ${var.app_namespace}-analytics-service --restart unless-stopped -p 8083:8083 -e SPRING_PROFILES_ACTIVE=production -e DB_USERNAME=yushan_analytics -e DB_PASSWORD=${var.db_password} -e DB_NAME=yushan_analytics -e DB_HOST=${digitalocean_droplet.analytics_db.ipv4_address} -e DB_PORT=5432 -e REDIS_HOST=${digitalocean_droplet.analytics_db.ipv4_address} -e REDIS_PORT=6379 -e EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://${digitalocean_droplet.infrastructure.ipv4_address}:8761/eureka/ -e CONFIG_SERVER_URI=http://${digitalocean_droplet.infrastructure.ipv4_address}:8888 ghcr.io/${var.github_username}/yushan-analytics-service:latest"
#     ]
#   }
# }

# Engagement Service
resource "digitalocean_droplet" "engagement_service" {
  name   = "${var.app_namespace}-engagement-service"
  image  = var.do_image
  region = var.do_region
  size   = var.do_size_medium

  ssh_keys = [data.digitalocean_ssh_key.main.id]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.ssh_private_key)
    host        = self.ipv4_address
  }

  # Install Docker
  provisioner "remote-exec" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt update -y",
      "apt install -y apt-transport-https ca-certificates curl gnupg lsb-release",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "apt update -y",
      "apt install -y docker-ce docker-ce-cli containerd.io",
      "systemctl start docker",
      "systemctl enable docker"
    ]
  }

  # Deploy Engagement Service
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-engagement-service --restart unless-stopped -p 8084:8084 -e SPRING_PROFILES_ACTIVE=production -e DB_USERNAME=yushan_engagement -e DB_PASSWORD=${var.db_password} -e DB_NAME=yushan_engagement -e DB_HOST=${digitalocean_droplet.engagement_db.ipv4_address} -e DB_PORT=5432 -e REDIS_HOST=${digitalocean_droplet.engagement_db.ipv4_address} -e REDIS_PORT=6379 -e EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://${digitalocean_droplet.infrastructure.ipv4_address}:8761/eureka/ -e CONFIG_SERVER_URI=http://${digitalocean_droplet.infrastructure.ipv4_address}:8888 ghcr.io/${var.github_username}/yushan-engagement-service:latest"
    ]
  }
}

# Gamification Service
resource "digitalocean_droplet" "gamification_service" {
  name   = "${var.app_namespace}-gamification-service"
  image  = var.do_image
  region = var.do_region
  size   = var.do_size_medium

  ssh_keys = [data.digitalocean_ssh_key.main.id]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.ssh_private_key)
    host        = self.ipv4_address
  }

  # Install Docker
  provisioner "remote-exec" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt update -y",
      "apt install -y apt-transport-https ca-certificates curl gnupg lsb-release",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "apt update -y",
      "apt install -y docker-ce docker-ce-cli containerd.io",
      "systemctl start docker",
      "systemctl enable docker"
    ]
  }

  # Deploy Gamification Service
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-gamification-service --restart unless-stopped -p 8085:8085 -e SPRING_PROFILES_ACTIVE=production -e DB_USERNAME=yushan_gamification -e DB_PASSWORD=${var.db_password} -e DB_NAME=yushan_gamification -e DB_HOST=${digitalocean_droplet.gamification_db.ipv4_address} -e DB_PORT=5432 -e REDIS_HOST=${digitalocean_droplet.gamification_db.ipv4_address} -e REDIS_PORT=6379 -e EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://${digitalocean_droplet.infrastructure.ipv4_address}:8761/eureka/ -e CONFIG_SERVER_URI=http://${digitalocean_droplet.infrastructure.ipv4_address}:8888 ghcr.io/${var.github_username}/yushan-gamification-service:latest"
    ]
  }
}
