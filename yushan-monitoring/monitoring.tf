# Data sources
data "digitalocean_ssh_key" "main" {
  name = var.do_ssh_key_name
}

# ELK Stack Droplet (Elasticsearch + Kibana + Logstash)
resource "digitalocean_droplet" "elk_stack" {
  name   = "${var.app_namespace}-elk-stack"
  image  = var.do_image
  region = var.do_region
  size   = var.do_size_logging

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

  # Configure system for Elasticsearch
  provisioner "remote-exec" {
    inline = [
      "echo 'vm.max_map_count=262144' >> /etc/sysctl.conf",
      "echo 'fs.file-max=65536' >> /etc/sysctl.conf",
      "sysctl -p",
      "echo '* soft nofile 65536' >> /etc/security/limits.conf",
      "echo '* hard nofile 65536' >> /etc/security/limits.conf",
      "echo '* soft nproc 4096' >> /etc/security/limits.conf",
      "echo '* hard nproc 4096' >> /etc/security/limits.conf"
    ]
  }

  # Create Docker network
  provisioner "remote-exec" {
    inline = [
      "docker network create ${var.app_namespace}-elk-network || true"
    ]
  }

  # Deploy Elasticsearch
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-elasticsearch --network ${var.app_namespace}-elk-network \\",
      "  -p 9200:9200 -p 9300:9300 \\",
      "  -e discovery.type=single-node \\",
      "  -e xpack.security.enabled=true \\",
      "  -e ELASTIC_PASSWORD=${var.elasticsearch_password} \\",
      "  -e \"ES_JAVA_OPTS=-Xms2g -Xmx2g\" \\",
      "  -v ${var.app_namespace}-elasticsearch-data:/usr/share/elasticsearch/data \\",
      "  --restart unless-stopped \\",
      "  docker.elastic.co/elasticsearch/elasticsearch:8.11.0"
    ]
  }

  # Wait for Elasticsearch to start
  provisioner "remote-exec" {
    inline = [
      "sleep 60",
      "echo \"Waiting for Elasticsearch to be ready...\"",
      "until curl -u elastic:${var.elasticsearch_password} -X GET \"localhost:9200/_cluster/health?wait_for_status=yellow&timeout=50s\"; do sleep 5; done"
    ]
  }

  # Deploy Kibana
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-kibana --network ${var.app_namespace}-elk-network \\",
      "  -p 5601:5601 \\",
      "  -e ELASTICSEARCH_HOSTS=http://${var.app_namespace}-elasticsearch:9200 \\",
      "  -e ELASTICSEARCH_USERNAME=elastic \\",
      "  -e ELASTICSEARCH_PASSWORD=${var.elasticsearch_password} \\",
      "  -e KIBANA_SYSTEM_PASSWORD=${var.kibana_password} \\",
      "  --restart unless-stopped \\",
      "  docker.elastic.co/kibana/kibana:8.11.0"
    ]
  }

  # Deploy Logstash
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-logstash --network ${var.app_namespace}-elk-network \\",
      "  -p 5044:5044 -p 5000:5000/tcp -p 5000:5000/udp -p 9600:9600 \\",
      "  -e ELASTICSEARCH_HOSTS=http://${var.app_namespace}-elasticsearch:9200 \\",
      "  -e ELASTICSEARCH_USERNAME=elastic \\",
      "  -e ELASTICSEARCH_PASSWORD=${var.elasticsearch_password} \\",
      "  -v ${var.app_namespace}-logstash-data:/usr/share/logstash/data \\",
      "  --restart unless-stopped \\",
      "  docker.elastic.co/logstash/logstash:8.11.0"
    ]
  }

  # Configure Logstash pipeline
  provisioner "file" {
    content = templatefile("${path.module}/templates/logstash.conf.tftpl", {
      elasticsearch_host = "${var.app_namespace}-elasticsearch"
      elasticsearch_username = "elastic"
      elasticsearch_password = var.elasticsearch_password
    })
    destination = "/tmp/logstash.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "docker cp /tmp/logstash.conf ${var.app_namespace}-logstash:/usr/share/logstash/pipeline/logstash.conf",
      "docker restart ${var.app_namespace}-logstash"
    ]
  }

  # Deploy Filebeat for log collection
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-filebeat --network ${var.app_namespace}-elk-network \\",
      "  --user root \\",
      "  -v /var/lib/docker/containers:/var/lib/docker/containers:ro \\",
      "  -v /var/run/docker.sock:/var/run/docker.sock:ro \\",
      "  -v ${var.app_namespace}-filebeat-data:/usr/share/filebeat/data \\",
      "  --restart unless-stopped \\",
      "  docker.elastic.co/beats/filebeat:8.11.0"
    ]
  }

  # Configure Filebeat
  provisioner "file" {
    content = templatefile("${path.module}/templates/filebeat.yml.tftpl", {
      logstash_host = "${var.app_namespace}-logstash"
      logstash_port = 5044
    })
    destination = "/tmp/filebeat.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "docker cp /tmp/filebeat.yml ${var.app_namespace}-filebeat:/usr/share/filebeat/filebeat.yml",
      "docker restart ${var.app_namespace}-filebeat"
    ]
  }
}

# Prometheus/Grafana Droplet
resource "digitalocean_droplet" "monitoring_stack" {
  name   = "${var.app_namespace}-monitoring"
  image  = var.do_image
  region = var.do_region
  size   = var.do_size_monitoring

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
      "docker network create ${var.app_namespace}-monitoring-network || true"
    ]
  }

  # Deploy Prometheus
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-prometheus --network ${var.app_namespace}-monitoring-network \\",
      "  -p 9090:9090 \\",
      "  -v ${var.app_namespace}-prometheus-data:/prometheus \\",
      "  -v ${var.app_namespace}-prometheus-config:/etc/prometheus \\",
      "  --restart unless-stopped \\",
      "  prom/prometheus:latest"
    ]
  }

  # Configure Prometheus
  provisioner "file" {
    content = templatefile("${path.module}/templates/prometheus.yml.tftpl", {
      infrastructure_ip = var.existing_infrastructure_ip
      service_ips = var.existing_service_ips
      db_ips = var.existing_db_ips
      elk_ip = digitalocean_droplet.elk_stack.ipv4_address
      monitoring_ip = self.ipv4_address
    })
    destination = "/tmp/prometheus.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "docker cp /tmp/prometheus.yml ${var.app_namespace}-prometheus:/etc/prometheus/prometheus.yml",
      "docker restart ${var.app_namespace}-prometheus"
    ]
  }

  # Deploy Grafana
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-grafana --network ${var.app_namespace}-monitoring-network \\",
      "  -p 3000:3000 \\",
      "  -e GF_SECURITY_ADMIN_USER=${var.grafana_admin_user} \\",
      "  -e GF_SECURITY_ADMIN_PASSWORD=${var.grafana_password} \\",
      "  -e GF_USERS_ALLOW_SIGN_UP=false \\",
      "  -v ${var.app_namespace}-grafana-data:/var/lib/grafana \\",
      "  --restart unless-stopped \\",
      "  grafana/grafana:latest"
    ]
  }

  # Deploy Alertmanager
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-alertmanager --network ${var.app_namespace}-monitoring-network \\",
      "  -p 9093:9093 \\",
      "  -v ${var.app_namespace}-alertmanager-data:/alertmanager \\",
      "  -v ${var.app_namespace}-alertmanager-config:/etc/alertmanager \\",
      "  --restart unless-stopped \\",
      "  prom/alertmanager:latest"
    ]
  }

  # Configure Alertmanager
  provisioner "file" {
    content = templatefile("${path.module}/templates/alertmanager.yml.tftpl", {
      slack_webhook = var.alertmanager_slack_webhook
      email = var.alertmanager_email
    })
    destination = "/tmp/alertmanager.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "docker cp /tmp/alertmanager.yml ${var.app_namespace}-alertmanager:/etc/alertmanager/alertmanager.yml",
      "docker restart ${var.app_namespace}-alertmanager"
    ]
  }

  # Deploy Node Exporter for system metrics
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-node-exporter --network ${var.app_namespace}-monitoring-network \\",
      "  -p 9100:9100 \\",
      "  -v /proc:/host/proc:ro \\",
      "  -v /sys:/host/sys:ro \\",
      "  -v /:/rootfs:ro \\",
      "  --restart unless-stopped \\",
      "  prom/node-exporter:latest"
    ]
  }

  # Deploy cAdvisor for container metrics
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-cadvisor --network ${var.app_namespace}-monitoring-network \\",
      "  -p 8080:8080 \\",
      "  -v /:/rootfs:ro \\",
      "  -v /var/run:/var/run:ro \\",
      "  -v /sys:/sys:ro \\",
      "  -v /var/lib/docker/:/var/lib/docker:ro \\",
      "  -v /dev/disk/:/dev/disk:ro \\",
      "  --restart unless-stopped \\",
      "  gcr.io/cadvisor/cadvisor:latest"
    ]
  }

  # Deploy JMX Exporter for Java applications
  provisioner "remote-exec" {
    inline = [
      "docker run -d --name ${var.app_namespace}-jmx-exporter --network ${var.app_namespace}-monitoring-network \\",
      "  -p 5555:5555 \\",
      "  --restart unless-stopped \\",
      "  quay.io/prometheus/jmx-exporter:latest"
    ]
  }
}

# Load Balancer for monitoring services
resource "digitalocean_loadbalancer" "monitoring_lb" {
  name   = "${var.app_namespace}-monitoring-lb"
  region = var.do_region

  forwarding_rule {
    entry_protocol  = "http"
    entry_port      = 80
    target_protocol = "http"
    target_port     = 3000
  }

  forwarding_rule {
    entry_protocol  = "http"
    entry_port      = 9090
    target_protocol = "http"
    target_port     = 9090
  }

  forwarding_rule {
    entry_protocol  = "http"
    entry_port      = 5601
    target_protocol = "http"
    target_port     = 5601
  }

  droplet_ids = [
    digitalocean_droplet.monitoring_stack.id,
    digitalocean_droplet.elk_stack.id
  ]

  healthcheck {
    protocol               = "http"
    port                   = 3000
    path                   = "/api/health"
    check_interval_seconds = 10
    response_timeout_seconds = 5
    unhealthy_threshold    = 3
    healthy_threshold      = 2
  }
}
