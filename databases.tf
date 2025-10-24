# User Service Database
resource "digitalocean_droplet" "user_db" {
  name   = "${var.app_namespace}-user-db"
  image  = var.do_image
  region = var.do_region
  size   = "s-1vcpu-1gb"

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

  # Deploy PostgreSQL
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-user-postgres --restart unless-stopped -e POSTGRES_USER=yushan_user -e POSTGRES_PASSWORD=${var.db_password} -e POSTGRES_DB=yushan_user -p 5432:5432 -v ${var.app_namespace}-user-pg-data:/var/lib/postgresql/data postgres:16-alpine"
    ]
  }

  # Deploy Redis
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-user-redis --restart unless-stopped -p 6379:6379 -v ${var.app_namespace}-user-redis-data:/data redis:7-alpine redis-server --appendonly yes"
    ]
  }
}

# Content Service Database (PostgreSQL + Redis + Elasticsearch)
resource "digitalocean_droplet" "content_db" {
  name   = "${var.app_namespace}-content-db"
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

  # Deploy PostgreSQL
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-content-postgres --restart unless-stopped -e POSTGRES_USER=yushan_content -e POSTGRES_PASSWORD=${var.db_password} -e POSTGRES_DB=yushan_content -p 5432:5432 -v ${var.app_namespace}-content-pg-data:/var/lib/postgresql/data postgres:16-alpine"
    ]
  }

  # Deploy Redis
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-content-redis --restart unless-stopped -p 6379:6379 -v ${var.app_namespace}-content-redis-data:/data redis:7-alpine redis-server --appendonly yes"
    ]
  }

  # Deploy Elasticsearch
  provisioner "remote-exec" {
    inline = [
      "sysctl -w vm.max_map_count=262144",
      "echo 'vm.max_map_count=262144' >> /etc/sysctl.conf",
      "docker run -d --name ${var.app_namespace}-content-elasticsearch --restart unless-stopped -e discovery.type=single-node -e xpack.security.enabled=false -e \"ES_JAVA_OPTS=-Xms512m -Xmx512m\" -p 9200:9200 -p 9300:9300 -v ${var.app_namespace}-content-es-data:/usr/share/elasticsearch/data docker.elastic.co/elasticsearch/elasticsearch:7.17.9"
    ]
  }
}

# Analytics Service Database
# resource "digitalocean_droplet" "analytics_db" {
#   name   = "${var.app_namespace}-analytics-db"
#   image  = var.do_image
#   region = var.do_region
#   size   = var.do_size_large
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
#   # Deploy PostgreSQL
#   provisioner "remote-exec" {
#     inline = [
#       "docker run -d --name ${var.app_namespace}-analytics-postgres --restart unless-stopped -e POSTGRES_USER=yushan_analytics -e POSTGRES_PASSWORD=${var.db_password} -e POSTGRES_DB=yushan_analytics -p 5432:5432 -v ${var.app_namespace}-analytics-pg-data:/var/lib/postgresql/data postgres:16-alpine"
#     ]
#   }
# 
#   # Deploy Redis
#   provisioner "remote-exec" {
#     inline = [
#       "docker run -d --name ${var.app_namespace}-analytics-redis --restart unless-stopped -p 6379:6379 -v ${var.app_namespace}-analytics-redis-data:/data redis:7-alpine redis-server --appendonly yes"
#     ]
#   }
# }

# Engagement Service Database
resource "digitalocean_droplet" "engagement_db" {
  name   = "${var.app_namespace}-engagement-db"
  image  = var.do_image
  region = var.do_region
  size   = "s-1vcpu-1gb"

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

  # Deploy PostgreSQL
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-engagement-postgres --restart unless-stopped -e POSTGRES_USER=yushan_engagement -e POSTGRES_PASSWORD=${var.db_password} -e POSTGRES_DB=yushan_engagement -p 5432:5432 -v ${var.app_namespace}-engagement-pg-data:/var/lib/postgresql/data postgres:16-alpine"
    ]
  }

  # Deploy Redis
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-engagement-redis --restart unless-stopped -p 6379:6379 -v ${var.app_namespace}-engagement-redis-data:/data redis:7-alpine redis-server --appendonly yes"
    ]
  }
}

# Gamification Service Database
resource "digitalocean_droplet" "gamification_db" {
  name   = "${var.app_namespace}-gamification-db"
  image  = var.do_image
  region = var.do_region
  size   = "s-1vcpu-1gb"

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

  # Deploy PostgreSQL
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-gamification-postgres --restart unless-stopped -e POSTGRES_USER=yushan_gamification -e POSTGRES_PASSWORD=${var.db_password} -e POSTGRES_DB=yushan_gamification -p 5432:5432 -v ${var.app_namespace}-gamification-pg-data:/var/lib/postgresql/data postgres:16-alpine"
    ]
  }

  # Deploy Redis
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-gamification-redis --restart unless-stopped -p 6379:6379 -v ${var.app_namespace}-gamification-redis-data:/data redis:7-alpine redis-server --appendonly yes"
    ]
  }
}
