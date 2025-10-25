# Data sources
data "digitalocean_ssh_key" "main" {
  name = var.do_ssh_key_name
}

# Infrastructure Services Droplet (Eureka, Config Server, API Gateway)
resource "digitalocean_droplet" "infrastructure" {
  name   = "${var.app_namespace}-infrastructure"
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

  # Create Docker network
  provisioner "remote-exec" {
    inline = [
      "docker network create ${var.app_namespace}-network || true"
    ]
  }

  # Deploy Eureka Registry
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-eureka --network ${var.app_namespace}-network \\",
      "  -p 8761:8761 \\",
      "  -e SPRING_PROFILES_ACTIVE=docker \\",
      "  --restart unless-stopped \\",
      "  ghcr.io/${var.github_username}/yushan-platform-service-registry:latest"
    ]
  }

  # Wait for Eureka to start
  provisioner "remote-exec" {
    inline = [
      "sleep 30"
    ]
  }

  # Deploy Config Server
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-config-server --network ${var.app_namespace}-network \\",
      "  -p 8888:8888 \\",
      "  -e SPRING_PROFILES_ACTIVE=native \\",
      "  -e EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://${var.app_namespace}-eureka:8761/eureka/ \\",
      "  -e ELASTICSEARCH_URL=http://${digitalocean_droplet.content_db.ipv4_address}:9200 \\",
      "  --restart unless-stopped \\",
      "  ghcr.io/${var.github_username}/yushan-config-server:latest"
    ]
  }

  # Wait for Config Server to start
  provisioner "remote-exec" {
    inline = [
      "sleep 30"
    ]
  }

  # Deploy Kafka
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-kafka --network ${var.app_namespace}-network --user root \\",
      "  -p 9092:9092 \\",
      "  -v ${var.app_namespace}-kafka-data:/var/lib/kafka/data \\",
      "  -e KAFKA_NODE_ID=1 \\",
      "  -e KAFKA_PROCESS_ROLES=broker,controller \\",
      "  -e KAFKA_CONTROLLER_QUORUM_VOTERS=1@${var.app_namespace}-kafka:29093 \\",
      "  -e KAFKA_CONTROLLER_LISTENER_NAMES=CONTROLLER \\",
      "  -e KAFKA_INTER_BROKER_LISTENER_NAME=PLAINTEXT_INTERNAL \\",
      "  -e KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092,PLAINTEXT_INTERNAL://0.0.0.0:29092,CONTROLLER://0.0.0.0:29093 \\",
      "  -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://${digitalocean_droplet.infrastructure.ipv4_address}:9092,PLAINTEXT_INTERNAL://${var.app_namespace}-kafka:29092 \\",
      "  -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,PLAINTEXT_INTERNAL:PLAINTEXT,CONTROLLER:PLAINTEXT \\",
      "  -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \\",
      "  -e KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1 \\",
      "  -e KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=1 \\",
      "  -e KAFKA_AUTO_CREATE_TOPICS_ENABLE=true \\",
      "  -e KAFKA_LOG_DIRS=/var/lib/kafka/data \\",
      "  -e CLUSTER_ID=MkU3OEVBNTcwNTJENDM2Qk \\",
      "  --restart unless-stopped \\",
      "  confluentinc/cp-kafka:7.4.0"
    ]
  }

  # Deploy Zookeeper for Kafka
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-zookeeper --network ${var.app_namespace}-network \\",
      "  -p 2181:2181 \\",
      "  -e ZOOKEEPER_CLIENT_PORT=2181 \\",
      "  -e ZOOKEEPER_TICK_TIME=2000 \\",
      "  --restart unless-stopped \\",
      "  confluentinc/cp-zookeeper:latest"
    ]
  }

  # Wait for Kafka to start
  provisioner "remote-exec" {
    inline = [
      "sleep 30"
    ]
  }

  # Deploy API Gateway
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-api-gateway --network ${var.app_namespace}-network \\",
      "  -p 8080:8080 \\",
      "  -e SPRING_PROFILES_ACTIVE=docker \\",
      "  -e EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://${var.app_namespace}-eureka:8761/eureka/ \\",
      "  --restart unless-stopped \\",
      "  ghcr.io/${var.github_username}/yushan-api-gateway:latest"
    ]
  }

  # In case deploy Nginx in same droplet with infrastructure droplet
  # Install Nginx and SSL
  provisioner "remote-exec" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt update -y || true",
      "apt install -y nginx openssl",
      "systemctl start nginx",
      "systemctl enable nginx"
    ]
  }

  # Generate SSL Certificate
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /etc/ssl/private /etc/ssl/certs",
      "openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -subj '/C=US/ST=State/L=City/O=Organization/CN=localhost'"
    ]
  }

  # Configure Nginx main config with rate limiting
  provisioner "remote-exec" {
    inline = [
      "cat > /etc/nginx/nginx.conf << 'EOF'",
      "user www-data;",
      "worker_processes auto;",
      "pid /run/nginx.pid;",
      "include /etc/nginx/modules-enabled/*.conf;",
      " ",
      "events {",
      "    worker_connections 768;",
      "}",
      " ",
      "http {",
      "    sendfile on;",
      "    tcp_nopush on;",
      "    types_hash_max_size 2048;",
      "    include /etc/nginx/mime.types;",
      "    default_type application/octet-stream;",
      "    ssl_protocols TLSv1.2 TLSv1.3;",
      "    ssl_prefer_server_ciphers on;",
      "    access_log /var/log/nginx/access.log;",
      "    error_log /var/log/nginx/error.log;",
      "    gzip on;",
      "    gzip_vary on;",
      "    gzip_min_length 1024;",
      "    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;",
      " ",
      "    # Rate limiting zones",
      "    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;",
      "    limit_req_zone $binary_remote_addr zone=auth:10m rate=5r/s;",
      " ",
      "    include /etc/nginx/conf.d/*.conf;",
      "    include /etc/nginx/sites-enabled/*;",
      "}",
      "EOF"
    ]
  }

  # Configure Nginx site config
  provisioner "file" {
    content = templatefile("${path.module}/templates/nginx.conf.tftpl", {
      api_gateway_ip = self.ipv4_address
      api_gateway_port = 8080
    })
    destination = "/etc/nginx/sites-available/default"
  }

  # Enable Nginx config
  provisioner "remote-exec" {
    inline = [
      "ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default",
      "nginx -t",
      "systemctl reload nginx"
    ]
  }
}
