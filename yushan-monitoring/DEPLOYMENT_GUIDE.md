# Yushan Monitoring Deployment Guide

Hướng dẫn chi tiết để deploy hệ thống Centralized Logging và Metrics & Monitoring cho Yushan Platform.

## Bước 1: Chuẩn bị Digital Ocean Account mới

### 1.1 Tạo Account mới
1. Truy cập [Digital Ocean](https://www.digitalocean.com/)
2. Đăng ký account mới (khác với account chính)
3. Verify email và complete setup

### 1.2 Tạo Personal Access Token
1. Đăng nhập vào Digital Ocean
2. Vào **Settings** > **API**
3. Click **Generate New Token**
4. Đặt tên: `yushan-monitoring-token`
5. Chọn scope: **Full Access** hoặc **Read/Write**
6. Copy token và lưu lại (chỉ hiển thị 1 lần)

### 1.3 Thêm SSH Key
1. Vào **Settings** > **Security** > **SSH Keys**
2. Click **Add SSH Key**
3. Đặt tên: `yushan-monitoring-ssh-key`
4. Paste SSH public key của bạn
5. Click **Add SSH Key**

## Bước 2: Chuẩn bị Local Environment

### 2.1 Cài đặt Prerequisites
```bash
# Cài đặt Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Cài đặt Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Verify installations
terraform --version
docker --version
```

### 2.2 Clone Repository
```bash
# Clone monitoring infrastructure
git clone <repository-url>
cd yushan-monitoring

# Make deploy script executable
chmod +x deploy.sh
```

## Bước 3: Cấu hình Environment

### 3.1 Copy và chỉnh sửa file cấu hình
```bash
# Copy file example
cp env.example .env

# Chỉnh sửa file .env
nano .env
```

### 3.2 Cấu hình các biến môi trường

Cập nhật file `.env` với thông tin của bạn:

```bash
# Digital Ocean Personal Access Token (NEW ACCOUNT)
export DO_PAT="dop_v1_your_actual_token_here"

# SSH Private Key Path (đường dẫn đến private key)
export SSH_PRIVATE_KEY_PATH="/home/user/.ssh/id_rsa"

# SSH Key Name in Digital Ocean (tên bạn đã đặt ở bước 1.3)
export DO_SSH_KEY_NAME="yushan-monitoring-ssh-key"

# Existing Infrastructure IPs (từ deployment chính)
export EXISTING_INFRASTRUCTURE_IP="167.172.72.189"

# Existing Service IPs (từ terraform output của deployment chính)
export EXISTING_SERVICE_IPS='{
  "user_service": "167.71.216.54",
  "content_service": "157.245.153.167",
  "engagement_service": "167.172.65.76",
  "gamification_service": "139.59.243.188"
}'

# Existing Database IPs (từ terraform output của deployment chính)
export EXISTING_DB_IPS='{
  "user_db": "165.22.253.32",
  "content_db": "188.166.254.179",
  "engagement_db": "206.189.144.116",
  "gamification_db": "178.128.83.217"
}'

# Passwords (THAY ĐỔI CHO BẢO MẬT!)
export ELASTICSEARCH_PASSWORD="your_secure_elasticsearch_password"
export KIBANA_PASSWORD="your_secure_kibana_password"
export GRAFANA_PASSWORD="your_secure_grafana_password"
```

### 3.3 Verify cấu hình
```bash
# Load environment variables
source .env

# Verify các biến quan trọng
echo "DO_PAT: ${DO_PAT:0:20}..."
echo "SSH_KEY_PATH: $SSH_PRIVATE_KEY_PATH"
echo "INFRASTRUCTURE_IP: $EXISTING_INFRASTRUCTURE_IP"
```

## Bước 4: Deploy Infrastructure

### 4.1 Chạy deployment script
```bash
# Chạy script deployment
./deploy.sh
```

Script sẽ thực hiện các bước sau:
1. ✅ Kiểm tra prerequisites
2. ✅ Load environment variables
3. ✅ Initialize Terraform
4. ✅ Validate configuration
5. ✅ Plan deployment
6. ⏳ Apply configuration (có thể mất 10-15 phút)
7. ⏳ Wait for services to be ready
8. ✅ Configure Grafana datasources
9. ✅ Display summary

### 4.2 Monitor deployment
```bash
# Trong quá trình deploy, bạn có thể monitor:
# - Terraform logs
# - Digital Ocean droplets creation
# - Docker containers startup

# Check Digital Ocean dashboard
# https://cloud.digitalocean.com/droplets
```

## Bước 5: Verify Deployment

### 5.1 Check services status
```bash
# Get IP addresses
ELK_IP=$(terraform output -raw elk_stack_ip)
MONITORING_IP=$(terraform output -raw monitoring_stack_ip)

echo "ELK Stack IP: $ELK_IP"
echo "Monitoring Stack IP: $MONITORING_IP"

# Test Elasticsearch
curl -u elastic:$ELASTICSEARCH_PASSWORD http://$ELK_IP:9200/_cluster/health

# Test Kibana
curl http://$ELK_IP:5601/api/status

# Test Prometheus
curl http://$MONITORING_IP:9090/-/ready

# Test Grafana
curl http://$MONITORING_IP:3000/api/health
```

### 5.2 Access web interfaces
Mở browser và truy cập:

- **Kibana**: `http://<elk_ip>:5601`
- **Grafana**: `http://<monitoring_ip>:3000`
- **Prometheus**: `http://<monitoring_ip>:9090`
- **Elasticsearch**: `http://<elk_ip>:9200`

## Bước 6: Cấu hình Applications

### 6.1 Cấu hình Spring Boot Services

Thêm vào `application.yml` của mỗi service:

```yaml
# application.yml
logging:
  config: classpath:logback-spring.xml
  level:
    com.yushan: DEBUG
    org.springframework.web: INFO

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  metrics:
    export:
      prometheus:
        enabled: true
  endpoint:
    prometheus:
      enabled: true

# Logstash configuration
logging:
  appenders:
    logstash:
      destination: "tcp://<elk_ip>:5000"
      encoder:
        class: "net.logstash.logback.encoder.LogstashEncoder"
```

### 6.2 Cấu hình Logback

Tạo file `logback-spring.xml` trong `src/main/resources`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <include resource="org/springframework/boot/logging/logback/defaults.xml"/>
    
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>
    
    <appender name="LOGSTASH" class="net.logstash.logback.appender.LogstashTcpSocketAppender">
        <destination>${LOGSTASH_HOST:elk_ip}:5000</destination>
        <encoder class="net.logstash.logback.encoder.LogstashEncoder">
            <includeContext>true</includeContext>
            <includeMdc>true</includeMdc>
            <customFields>{"service":"${spring.application.name}","environment":"${spring.profiles.active:default}"}</customFields>
        </encoder>
    </appender>
    
    <root level="INFO">
        <appender-ref ref="STDOUT"/>
        <appender-ref ref="LOGSTASH"/>
    </root>
</configuration>
```

### 6.3 Cấu hình Docker Compose

Cập nhật `docker-compose.yml` của các services:

```yaml
version: '3.8'
services:
  user-service:
    image: ghcr.io/maugus0/yushan-user-service:latest
    environment:
      - LOGSTASH_HOST=<elk_ip>
      - SPRING_PROFILES_ACTIVE=default
      # ... other environment variables
    ports:
      - "8081:8081"
```

## Bước 7: Cấu hình Monitoring

### 7.1 Import Grafana Dashboards

1. Truy cập Grafana: `http://<monitoring_ip>:3000`
2. Login với: `admin` / `<grafana_password>`
3. Import dashboards:
   - Spring Boot Dashboard (ID: 6756)
   - Infrastructure Dashboard (ID: 1860)
   - PostgreSQL Dashboard (ID: 9628)

### 7.2 Cấu hình Kibana Index Patterns

1. Truy cập Kibana: `http://<elk_ip>:5601`
2. Login với: `elastic` / `<elasticsearch_password>`
3. Vào **Stack Management** > **Index Patterns**
4. Tạo index pattern: `yushan-logs-*`
5. Select time field: `@timestamp`

### 7.3 Cấu hình Alerting

1. Truy cập Prometheus: `http://<monitoring_ip>:9090`
2. Vào **Alerts** tab
3. Cấu hình alert rules cho:
   - High CPU usage
   - High memory usage
   - Service down
   - High error rate

## Bước 8: Testing và Validation

### 8.1 Test Logging
```bash
# Generate test logs
curl -X POST http://<user_service_ip>:8081/api/test/logs

# Check logs in Kibana
# 1. Go to Kibana
# 2. Discover tab
# 3. Select yushan-logs-* index
# 4. Filter by service name
```

### 8.2 Test Metrics
```bash
# Check Prometheus targets
curl http://<monitoring_ip>:9090/api/v1/targets

# Check Grafana dashboards
# 1. Go to Grafana
# 2. Browse dashboards
# 3. Check Spring Boot metrics
```

### 8.3 Test Alerting
```bash
# Simulate high CPU usage
stress --cpu 4 --timeout 60s

# Check alerts in Prometheus
curl http://<monitoring_ip>:9090/api/v1/alerts
```

## Bước 9: Production Hardening

### 9.1 Security Configuration
```bash
# SSH vào droplets
ssh root@<elk_ip>
ssh root@<monitoring_ip>

# Configure firewall
ufw allow 22    # SSH
ufw allow 80    # HTTP
ufw allow 443   # HTTPS
ufw allow 3000  # Grafana
ufw allow 9090  # Prometheus
ufw allow 5601  # Kibana
ufw enable

# Update system
apt update && apt upgrade -y
```

### 9.2 SSL/TLS Configuration
```bash
# Install Certbot
apt install certbot python3-certbot-nginx -y

# Get SSL certificate
certbot --nginx -d monitoring.yushan.com

# Configure automatic renewal
crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

### 9.3 Backup Configuration
```bash
# Create backup script
cat > /root/backup-monitoring.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup/monitoring"

mkdir -p $BACKUP_DIR

# Backup Elasticsearch
docker exec yushan-monitoring-elasticsearch elasticsearch-backup create snapshot_$DATE

# Backup Prometheus
docker exec yushan-monitoring-prometheus tar -czf /prometheus-backup-$DATE.tar.gz /prometheus

# Backup Grafana
docker exec yushan-monitoring-grafana tar -czf /grafana-backup-$DATE.tar.gz /var/lib/grafana
EOF

chmod +x /root/backup-monitoring.sh

# Schedule backup
crontab -e
# Add: 0 2 * * * /root/backup-monitoring.sh
```

## Troubleshooting

### Common Issues

#### 1. Elasticsearch không start
```bash
# Check logs
docker logs yushan-monitoring-elasticsearch

# Check system limits
ulimit -n
ulimit -u

# Fix limits
echo 'vm.max_map_count=262144' >> /etc/sysctl.conf
sysctl -p
```

#### 2. Prometheus không scrape được metrics
```bash
# Check targets
curl http://<monitoring_ip>:9090/api/v1/targets

# Check network connectivity
docker exec yushan-monitoring-prometheus ping <service_ip>

# Check firewall
ufw status
```

#### 3. Grafana không connect được Prometheus
```bash
# Check Prometheus status
curl http://<monitoring_ip>:9090/-/ready

# Check Grafana logs
docker logs yushan-monitoring-grafana

# Restart Grafana
docker restart yushan-monitoring-grafana
```

#### 4. Logs không xuất hiện trong Kibana
```bash
# Check Logstash status
docker logs yushan-monitoring-logstash

# Check Elasticsearch indices
curl -u elastic:<password> http://<elk_ip>:9200/_cat/indices

# Check Filebeat status
docker logs yushan-monitoring-filebeat
```

### Performance Optimization

#### 1. Elasticsearch Tuning
```bash
# Increase heap size
docker exec yushan-monitoring-elasticsearch bin/elasticsearch -Xms4g -Xmx4g

# Optimize indices
curl -X POST "http://<elk_ip>:9200/yushan-logs-*/_forcemerge?max_num_segments=1"
```

#### 2. Prometheus Tuning
```bash
# Increase retention
docker exec yushan-monitoring-prometheus prometheus --storage.tsdb.retention.time=30d

# Optimize queries
# Use recording rules for expensive queries
```

## Maintenance

### Daily Tasks
- Check service health
- Monitor resource usage
- Review alerts

### Weekly Tasks
- Review logs for errors
- Update dashboards
- Check backup status

### Monthly Tasks
- Update system packages
- Review and optimize queries
- Clean up old data
- Review costs

## Cost Management

### Current Costs
- ELK Stack: $48/month (s-4vcpu-8gb)
- Monitoring Stack: $24/month (s-2vcpu-4gb)
- Load Balancer: $12/month
- **Total: ~$84/month**

### Cost Optimization Tips
1. Use smaller droplets for development
2. Configure log retention policies
3. Monitor resource usage
4. Use Digital Ocean snapshots for backup
5. Consider reserved instances for production

## Support và Documentation

### Useful Resources
- [Elasticsearch Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Kibana Documentation](https://www.elastic.co/guide/en/kibana/current/index.html)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

### Contact Support
- Email: support@yushan.com
- Slack: #monitoring-support
- GitHub Issues: [Repository Issues](https://github.com/your-repo/issues)

---

**Lưu ý quan trọng**: 
- Đây là hệ thống production-ready với chi phí ~$84/tháng
- Hãy đảm bảo bạn có đủ budget trước khi deploy
- Luôn backup dữ liệu quan trọng
- Monitor costs định kỳ để tránh surprise bills
