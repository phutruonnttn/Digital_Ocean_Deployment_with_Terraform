# Yushan Monitoring Infrastructure

Hệ thống Centralized Logging và Metrics & Monitoring cho Yushan Platform trên Digital Ocean.

## Tổng quan

Hệ thống monitoring này bao gồm:

### ELK Stack (Centralized Logging)
- **Elasticsearch**: Lưu trữ và tìm kiếm logs
- **Kibana**: Dashboard và visualization cho logs
- **Logstash**: Thu thập và xử lý logs
- **Filebeat**: Agent thu thập logs từ containers

### Prometheus/Grafana Stack (Metrics & Monitoring)
- **Prometheus**: Thu thập và lưu trữ metrics
- **Grafana**: Dashboard và visualization cho metrics
- **Alertmanager**: Quản lý alerts
- **Node Exporter**: System metrics
- **cAdvisor**: Container metrics

## Kiến trúc

```
┌─────────────────┐    ┌─────────────────┐
│   ELK Stack     │    │ Monitoring Stack│
│                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │Elasticsearch│ │    │ │ Prometheus  │ │
│ └─────────────┘ │    │ └─────────────┘ │
│ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │   Kibana    │ │    │ │   Grafana   │ │
│ └─────────────┘ │    │ └─────────────┘ │
│ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │  Logstash   │ │    │ │Alertmanager│ │
│ └─────────────┘ │    │ └─────────────┘ │
└─────────────────┘    └─────────────────┘
         │                       │
         └───────────────────────┘
                    │
            ┌─────────────┐
            │Load Balancer│
            └─────────────┘
```

## Yêu cầu hệ thống

### Prerequisites
- Terraform >= 1.0
- Docker
- Digital Ocean account mới (tách biệt với account chính)
- SSH key đã được thêm vào Digital Ocean

### Droplet Requirements
- **ELK Stack**: s-4vcpu-8gb ($48/tháng) - Cần RAM cao cho Elasticsearch
- **Monitoring Stack**: s-2vcpu-4gb ($24/tháng)
- **Tổng chi phí**: ~$72/tháng

## Cài đặt

### 1. Chuẩn bị Digital Ocean Account mới

1. Tạo Digital Ocean account mới
2. Tạo Personal Access Token:
   - Vào Settings > API
   - Tạo token mới với quyền Read/Write
3. Thêm SSH key:
   - Vào Settings > Security > SSH Keys
   - Upload SSH public key của bạn

### 2. Clone và cấu hình

```bash
# Clone repository
git clone <repository-url>
cd yushan-monitoring

# Copy file cấu hình
cp env.example .env

# Chỉnh sửa file .env với thông tin của bạn
nano .env
```

### 3. Cấu hình file .env

Cập nhật các thông tin sau trong file `.env`:

```bash
# Digital Ocean Personal Access Token (NEW ACCOUNT)
export DO_PAT="dop_v1_your_new_token_here"

# SSH Private Key Path
export SSH_PRIVATE_KEY_PATH="/path/to/your/private/key"

# SSH Key Name in Digital Ocean
export DO_SSH_KEY_NAME="your-ssh-key-name"

# Existing Infrastructure IPs (từ deployment chính)
export EXISTING_INFRASTRUCTURE_IP="167.172.72.189"
export EXISTING_SERVICE_IPS='{
  "user_service": "167.71.216.54",
  "content_service": "157.245.153.167",
  "engagement_service": "167.172.65.76",
  "gamification_service": "139.59.243.188"
}'
export EXISTING_DB_IPS='{
  "user_db": "165.22.253.32",
  "content_db": "188.166.254.179",
  "engagement_db": "206.189.144.116",
  "gamification_db": "178.128.83.217"
}'

# Passwords (thay đổi cho bảo mật)
export ELASTICSEARCH_PASSWORD="your_secure_password"
export KIBANA_PASSWORD="your_secure_password"
export GRAFANA_PASSWORD="your_secure_password"
```

### 4. Deploy

```bash
# Chạy script deployment
./deploy.sh
```

Script sẽ:
1. Kiểm tra prerequisites
2. Load environment variables
3. Initialize Terraform
4. Validate configuration
5. Plan deployment
6. Apply configuration
7. Wait for services to be ready
8. Configure Grafana datasources
9. Hiển thị summary

## Truy cập Services

Sau khi deploy thành công, bạn có thể truy cập:

### ELK Stack
- **Elasticsearch**: `http://<elk_ip>:9200`
- **Kibana**: `http://<elk_ip>:5601`
- **Logstash**: `http://<elk_ip>:5044`

### Monitoring Stack
- **Prometheus**: `http://<monitoring_ip>:9090`
- **Grafana**: `http://<monitoring_ip>:3000`
- **Alertmanager**: `http://<monitoring_ip>:9093`

### Load Balancer
- **Grafana**: `http://<lb_ip>:3000`
- **Prometheus**: `http://<lb_ip>:9090`
- **Kibana**: `http://<lb_ip>:5601`

## Credentials

- **Elasticsearch**: `elastic` / `<ELASTICSEARCH_PASSWORD>`
- **Kibana**: `kibana_system` / `<KIBANA_PASSWORD>`
- **Grafana**: `admin` / `<GRAFANA_PASSWORD>`

## Cấu hình Applications

### 1. Cấu hình Logging cho Spring Boot Apps

Thêm vào `application.yml` của các services:

```yaml
logging:
  config: classpath:logback-spring.xml
  level:
    com.yushan: DEBUG

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  metrics:
    export:
      prometheus:
        enabled: true
```

### 2. Cấu hình Logstash Input

Các applications sẽ gửi logs đến Logstash qua:
- **TCP**: Port 5000
- **UDP**: Port 5000
- **Beats**: Port 5044

### 3. Cấu hình Prometheus Metrics

Prometheus sẽ scrape metrics từ:
- Spring Boot Actuator endpoints (`/actuator/prometheus`)
- Node Exporter (system metrics)
- cAdvisor (container metrics)

## Monitoring Dashboards

### Grafana Dashboards
1. **Spring Boot Dashboard**: Monitor JVM, HTTP requests, database connections
2. **Infrastructure Dashboard**: CPU, Memory, Disk, Network
3. **Database Dashboard**: PostgreSQL metrics
4. **ELK Stack Dashboard**: Elasticsearch cluster health

### Kibana Dashboards
1. **Application Logs**: Filter và search logs theo service
2. **Error Tracking**: Track errors và exceptions
3. **Performance Monitoring**: Response times, throughput

## Alerting

### Prometheus Alerts
- High CPU usage
- High memory usage
- Disk space low
- Service down
- High error rate
- Slow response time

### Alertmanager Channels
- Email notifications
- Slack notifications (nếu cấu hình webhook)

## Maintenance

### Log Retention
- **Elasticsearch**: 30 ngày (có thể cấu hình)
- **Prometheus**: 15 ngày (có thể cấu hình)

### Backup
- Elasticsearch data được lưu trong Docker volumes
- Prometheus data được lưu trong Docker volumes
- Có thể backup volumes định kỳ

### Scaling
- Có thể scale ELK Stack bằng cách tăng droplet size
- Có thể thêm multiple Elasticsearch nodes
- Có thể thêm multiple Prometheus instances

## Troubleshooting

### Common Issues

1. **Elasticsearch không start**
   ```bash
   # Check logs
   docker logs yushan-monitoring-elasticsearch
   
   # Check system limits
   ulimit -n
   ```

2. **Grafana không connect được Prometheus**
   ```bash
   # Check Prometheus status
   curl http://<monitoring_ip>:9090/-/ready
   
   # Check network connectivity
   docker network ls
   ```

3. **Logs không xuất hiện trong Kibana**
   ```bash
   # Check Logstash status
   docker logs yushan-monitoring-logstash
   
   # Check Elasticsearch indices
   curl -u elastic:<password> http://<elk_ip>:9200/_cat/indices
   ```

### Useful Commands

```bash
# Check all containers
docker ps

# Check container logs
docker logs <container_name>

# Restart service
docker restart <container_name>

# Check disk usage
df -h

# Check memory usage
free -h

# Check Elasticsearch cluster health
curl -u elastic:<password> http://<elk_ip>:9200/_cluster/health
```

## Security

### Recommendations
1. Thay đổi tất cả default passwords
2. Enable SSL/TLS cho production
3. Configure firewall rules
4. Regular security updates
5. Monitor access logs

### Firewall Rules
```bash
# Allow only necessary ports
ufw allow 22    # SSH
ufw allow 80    # HTTP
ufw allow 443   # HTTPS
ufw allow 3000  # Grafana
ufw allow 9090  # Prometheus
ufw allow 5601  # Kibana
ufw enable
```

## Cost Optimization

### Tips
1. Sử dụng smaller droplets cho development
2. Configure log retention policies
3. Monitor resource usage
4. Use Digital Ocean snapshots for backup
5. Consider reserved instances for production

## Support

Nếu gặp vấn đề, hãy:
1. Check logs của containers
2. Verify network connectivity
3. Check resource usage
4. Review configuration files
5. Contact support team

---

**Lưu ý**: Đây là hệ thống monitoring production-ready với chi phí ~$72/tháng. Hãy đảm bảo bạn có đủ budget trước khi deploy.
