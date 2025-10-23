# Load Balancer Droplet (COMMENTED OUT - Load balancer merged into infrastructure droplet)
# resource "digitalocean_droplet" "load_balancer" {
#   name   = "${var.app_namespace}-load-balancer"
#   image  = var.do_image
#   region = var.do_region
#   size   = var.do_size_small
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
#   # Install Nginx
#   provisioner "remote-exec" {
#     inline = [
#       "apt update -y",
#       "apt install -y nginx",
#       "systemctl start nginx",
#       "systemctl enable nginx"
#     ]
#   }
# 
#   # Create Nginx configuration
#   provisioner "file" {
#     content = templatefile("${path.module}/templates/nginx.conf.tftpl", {
#       api_gateway_ip = digitalocean_droplet.infrastructure.ipv4_address
#       api_gateway_port = 8080
#     })
#     destination = "/etc/nginx/nginx.conf"
#   }
# 
#   # Reload Nginx configuration
#   provisioner "remote-exec" {
#     inline = [
#       "nginx -t",
#       "systemctl reload nginx"
#     ]
#   }
# }
# 
# # Nginx configuration template
# resource "local_file" "nginx_config" {
#   content = templatefile("${path.module}/templates/nginx.conf.tftpl", {
#     api_gateway_ip = digitalocean_droplet.infrastructure.ipv4_address
#     api_gateway_port = 8080
#   })
#   filename = "${path.module}/nginx.conf"
# }
