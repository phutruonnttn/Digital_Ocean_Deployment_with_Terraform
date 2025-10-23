# Data sources
data "digitalocean_ssh_key" "main" {
  name = var.do_ssh_key_name
}

# Infrastructure Services Droplet (Eureka, Config Server, API Gateway)
resource "digitalocean_droplet" "infrastructure" {
  name   = "${var.app_namespace}-infrastructure"
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
      "export DEBIAN_FRONTEND=noninteractive",
      "apt update -y",
      "apt install -y apt-transport-https ca-certificates curl gnupg lsb-release",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "apt update -y",
      "apt install -y docker-ce docker-ce-cli containerd.io",
      "systemctl start docker",
      "systemctl enable docker",
      "usermod -aG docker root"
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
      "docker run -d --name ${var.app_namespace}-eureka --network ${var.app_namespace}-network -p 8761:8761 --restart unless-stopped ghcr.io/${var.github_username}/yushan-platform-service-registry:latest"
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
      "docker run -d --name ${var.app_namespace}-config-server --network ${var.app_namespace}-network -p 8888:8888 -e EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://${var.app_namespace}-eureka:8761/eureka/ --restart unless-stopped ghcr.io/${var.github_username}/yushan-config-server:latest"
    ]
  }

  # Wait for Config Server to start
  provisioner "remote-exec" {
    inline = [
      "sleep 30"
    ]
  }

  # Deploy API Gateway
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-api-gateway --network ${var.app_namespace}-network -p 8080:8080 -e EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://${var.app_namespace}-eureka:8761/eureka/ --restart unless-stopped ghcr.io/${var.github_username}/yushan-api-gateway:latest"
    ]
  }

  # In case deploy Nginx in same droplet with infrastructure droplet
  # Install Nginx
  provisioner "remote-exec" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt update -y",
      "apt install -y nginx",
      "systemctl start nginx",
      "systemctl enable nginx"
    ]
  }

  # Configure Nginx
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
      "ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/",
      "rm -f /etc/nginx/sites-enabled/default",
      "nginx -t",
      "systemctl reload nginx"
    ]
  }
}
