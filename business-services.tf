# User Service
resource "digitalocean_droplet" "user_service" {
  name   = "${var.app_namespace}-user-service"
  image  = var.do_image
  region = var.do_region
  size   = "s-1vcpu-2gb"

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
      "set -e",
      "export DEBIAN_FRONTEND=noninteractive",
      "echo \"Starting Docker installation...\"",
      "apt update -y || true",
      "apt install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common",
      "echo \"Adding Docker GPG key...\"",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"Adding Docker repository...\"",
      "echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu jammy stable\" | tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "apt update -y || true",
      "echo \"Installing Docker packages...\"",
      "apt install -y docker-ce docker-ce-cli containerd.io",
      "echo \"Starting Docker service...\"",
      "systemctl start docker",
      "systemctl enable docker",
      "usermod -aG docker root",
      "sleep 5",
      "echo \"Verifying Docker installation...\"",
      "docker --version",
      "echo \"Docker installation completed successfully\""
    ]
  }

  # Deploy User Service
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-user-service --restart unless-stopped -p 8081:8081 \\",
      "  -e SPRING_PROFILES_ACTIVE=default \\",
      "  -e DB_USERNAME=yushan_user -e DB_PASSWORD=${var.db_password} -e DB_NAME=yushan_user \\",
      "  -e DB_HOST=${digitalocean_droplet.user_db.ipv4_address} -e DB_PORT=5432 \\",
      "  -e REDIS_HOST=${digitalocean_droplet.user_db.ipv4_address} -e REDIS_PORT=6379 \\",
      "  -e JWT_SECRET=${var.jwt_secret} \\",
      "  -e MAIL_HOST=${var.mail_host} -e MAIL_USERNAME=${var.mail_username} -e MAIL_PASSWORD=${var.mail_password} -e MAIL_PORT=${var.mail_port} \\",
      "  -e SPRING_KAFKA_BOOTSTRAP_SERVERS=${digitalocean_droplet.infrastructure.ipv4_address}:9092 \\",
      "  -e SERVICES_CONTENT_URL=http://${digitalocean_droplet.content_service.ipv4_address}:8082 \\",
      "  -e EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://${digitalocean_droplet.infrastructure.ipv4_address}:8761/eureka/ \\",
      "  -e CONFIG_SERVER_URI=http://${digitalocean_droplet.infrastructure.ipv4_address}:8888 \\",
      "  -e EUREKA_INSTANCE_IP_ADDRESS=${digitalocean_droplet.user_service.ipv4_address} -e EUREKA_INSTANCE_PREFER_IP_ADDRESS=true \\",
      "  ghcr.io/${var.github_username}/yushan-user-service:latest"
    ]
  }
}

# Content Service
resource "digitalocean_droplet" "content_service" {
  name   = "${var.app_namespace}-content-service"
  image  = var.do_image
  region = var.do_region
  size   = "s-1vcpu-2gb"

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
      "set -e",
      "export DEBIAN_FRONTEND=noninteractive",
      "echo \"Starting Docker installation...\"",
      "apt update -y || true",
      "apt install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common",
      "echo \"Adding Docker GPG key...\"",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"Adding Docker repository...\"",
      "echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu jammy stable\" | tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "apt update -y || true",
      "echo \"Installing Docker packages...\"",
      "apt install -y docker-ce docker-ce-cli containerd.io",
      "echo \"Starting Docker service...\"",
      "systemctl start docker",
      "systemctl enable docker",
      "usermod -aG docker root",
      "sleep 5",
      "echo \"Verifying Docker installation...\"",
      "docker --version",
      "echo \"Docker installation completed successfully\""
    ]
  }

  # Deploy Content Service
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-content-service --restart unless-stopped -p 8082:8082 \\",
      "  -e SPRING_PROFILES_ACTIVE=default \\",
      "  -e DB_USERNAME=yushan_content -e DB_PASSWORD=${var.db_password} -e DB_NAME=yushan_content \\",
      "  -e DB_HOST=${digitalocean_droplet.content_db.ipv4_address} -e DB_PORT=5432 \\",
      "  -e REDIS_HOST=${digitalocean_droplet.content_db.ipv4_address} -e REDIS_PORT=6379 \\",
      "  -e SPRING_ELASTICSEARCH_REST_URIS=http://${digitalocean_droplet.content_db.ipv4_address}:9200 \\",
      "  -e SPRING_KAFKA_BOOTSTRAP_SERVERS=${digitalocean_droplet.infrastructure.ipv4_address}:9092 \\",
      "  -e SPACES_ACCESS_KEY=${var.spaces_access_key} -e SPACES_SECRET_KEY=${var.spaces_secret_key} -e SPACES_ENDPOINT=${var.spaces_endpoint} -e SPACES_BUCKET=${var.spaces_bucket} -e SPACES_REGION=sgp1 -e STORAGE_TYPE=s3 \\",
      "  -e JWT_SECRET=${var.jwt_secret} \\",
      "  -e EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://${digitalocean_droplet.infrastructure.ipv4_address}:8761/eureka/ \\",
      "  -e CONFIG_SERVER_URI=http://${digitalocean_droplet.infrastructure.ipv4_address}:8888 \\",
      "  -e EUREKA_INSTANCE_IP_ADDRESS=${digitalocean_droplet.content_service.ipv4_address} -e EUREKA_INSTANCE_PREFER_IP_ADDRESS=true \\",
      "  ghcr.io/${var.github_username}/yushan-content-service:latest"
    ]
  }
}

# Engagement Service
resource "digitalocean_droplet" "engagement_service" {
  name   = "${var.app_namespace}-engagement-service"
  image  = var.do_image
  region = var.do_region
  size   = "s-1vcpu-2gb"

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
      "set -e",
      "export DEBIAN_FRONTEND=noninteractive",
      "echo \"Starting Docker installation...\"",
      "apt update -y || true",
      "apt install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common",
      "echo \"Adding Docker GPG key...\"",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"Adding Docker repository...\"",
      "echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu jammy stable\" | tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "apt update -y || true",
      "echo \"Installing Docker packages...\"",
      "apt install -y docker-ce docker-ce-cli containerd.io",
      "echo \"Starting Docker service...\"",
      "systemctl start docker",
      "systemctl enable docker",
      "usermod -aG docker root",
      "sleep 5",
      "echo \"Verifying Docker installation...\"",
      "docker --version",
      "echo \"Docker installation completed successfully\""
    ]
  }

  # Deploy Engagement Service
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-engagement-service --restart unless-stopped -p 8084:8084 \\",
      "  -e SPRING_PROFILES_ACTIVE=default \\",
      "  -e DB_USERNAME=yushan_engagement -e DB_PASSWORD=${var.db_password} -e DB_NAME=yushan_engagement \\",
      "  -e DB_HOST=${digitalocean_droplet.engagement_db.ipv4_address} -e DB_PORT=5432 \\",
      "  -e REDIS_HOST=${digitalocean_droplet.engagement_db.ipv4_address} -e REDIS_PORT=6379 \\",
      "  -e JWT_SECRET=${var.jwt_secret} \\",
      "  -e SPRING_KAFKA_BOOTSTRAP_SERVERS=${digitalocean_droplet.infrastructure.ipv4_address}:9092 \\",
      "  -e SERVICES_CONTENT_URL=http://${digitalocean_droplet.content_service.ipv4_address}:8082 \\",
      "  -e SERVICES_USER_URL=http://${digitalocean_droplet.user_service.ipv4_address}:8081 \\",
      "  -e SERVICES_GAMIFICATION_URL=http://${digitalocean_droplet.gamification_service.ipv4_address}:8085 \\",
      "  -e EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://${digitalocean_droplet.infrastructure.ipv4_address}:8761/eureka/ \\",
      "  -e CONFIG_SERVER_URI=http://${digitalocean_droplet.infrastructure.ipv4_address}:8888 \\",
      "  -e EUREKA_INSTANCE_IP_ADDRESS=${digitalocean_droplet.engagement_service.ipv4_address} -e EUREKA_INSTANCE_PREFER_IP_ADDRESS=true \\",
      "  ghcr.io/${var.github_username}/yushan-engagement-service:latest"
    ]
  }
}

# Gamification Service (shared with Analytics Service)
resource "digitalocean_droplet" "gamification_service" {
  name   = "${var.app_namespace}-gamification-service"
  image  = var.do_image
  region = var.do_region
  size   = "s-2vcpu-4gb"

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
      "set -e",
      "export DEBIAN_FRONTEND=noninteractive",
      "echo \"Starting Docker installation...\"",
      "apt update -y || true",
      "apt install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common",
      "echo \"Adding Docker GPG key...\"",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"Adding Docker repository...\"",
      "echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu jammy stable\" | tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "apt update -y || true",
      "echo \"Installing Docker packages...\"",
      "apt install -y docker-ce docker-ce-cli containerd.io",
      "echo \"Starting Docker service...\"",
      "systemctl start docker",
      "systemctl enable docker",
      "usermod -aG docker root",
      "sleep 5",
      "echo \"Verifying Docker installation...\"",
      "docker --version",
      "echo \"Docker installation completed successfully\""
    ]
  }

  # Deploy Gamification Service
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-gamification-service --restart unless-stopped -p 8085:8085 \\",
      "  -e SPRING_PROFILES_ACTIVE=default \\",
      "  -e DB_USERNAME=yushan_gamification -e DB_PASSWORD=${var.db_password} -e DB_NAME=yushan_gamification \\",
      "  -e DB_HOST=${digitalocean_droplet.gamification_db.ipv4_address} -e DB_PORT=5432 \\",
      "  -e REDIS_HOST=${digitalocean_droplet.gamification_db.ipv4_address} -e REDIS_PORT=6379 \\",
      "  -e JWT_SECRET=${var.jwt_secret} \\",
      "  -e SPRING_KAFKA_BOOTSTRAP_SERVERS=${digitalocean_droplet.infrastructure.ipv4_address}:9092 \\",
      "  -e EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://${digitalocean_droplet.infrastructure.ipv4_address}:8761/eureka/ \\",
      "  -e CONFIG_SERVER_URI=http://${digitalocean_droplet.infrastructure.ipv4_address}:8888 \\",
      "  -e EUREKA_INSTANCE_IP_ADDRESS=${self.ipv4_address} -e EUREKA_INSTANCE_PREFER_IP_ADDRESS=true \\",
      "  ghcr.io/${var.github_username}/yushan-gamification-service:latest"
    ]
  }

  # Deploy Analytics Service (shared droplet)
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-analytics-service --restart unless-stopped -p 8083:8083 \\",
      "  -e SPRING_PROFILES_ACTIVE=default \\",
      "  -e DB_URL=jdbc:postgresql://${digitalocean_droplet.gamification_db.ipv4_address}:5433/yushan_analytics \\",
      "  -e DB_USERNAME=yushan_analytics -e DB_PASSWORD=${var.db_password} -e DB_NAME=yushan_analytics \\",
      "  -e DB_HOST=${digitalocean_droplet.gamification_db.ipv4_address} -e DB_PORT=5433 \\",
      "  -e REDIS_HOST=${digitalocean_droplet.gamification_db.ipv4_address} -e REDIS_PORT=6380 \\",
      "  -e JWT_SECRET=${var.jwt_secret} \\",
      "  -e SERVICES_CONTENT_URL=http://${digitalocean_droplet.content_service.ipv4_address}:8082 \\",
      "  -e SERVICES_USER_URL=http://${digitalocean_droplet.user_service.ipv4_address}:8081 \\",
      "  -e SERVICES_GAMIFICATION_URL=http://${self.ipv4_address}:8085 \\",
      "  -e SPRING_KAFKA_BOOTSTRAP_SERVERS=${digitalocean_droplet.infrastructure.ipv4_address}:9092 \\",
      "  -e EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://${digitalocean_droplet.infrastructure.ipv4_address}:8761/eureka/ \\",
      "  -e CONFIG_SERVER_URI=http://${digitalocean_droplet.infrastructure.ipv4_address}:8888 \\",
      "  -e EUREKA_INSTANCE_IP_ADDRESS=${self.ipv4_address} -e EUREKA_INSTANCE_PREFER_IP_ADDRESS=true \\",
      "  ghcr.io/${var.github_username}/yushan-analytics-service:latest"
    ]
  }
}
