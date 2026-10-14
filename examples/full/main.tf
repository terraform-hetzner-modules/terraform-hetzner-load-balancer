resource "hcloud_network" "backend" {
  name     = "load-balancer-backends"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "backend" {
  network_id   = hcloud_network.backend.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

resource "hcloud_server" "backend" {
  for_each    = toset(["app", "worker"])
  name        = "load-balancer-${each.key}"
  server_type = "cx23"
  image       = "debian-13"
  location    = "fsn1"
  labels      = { role = each.key }
  network {
    network_id = hcloud_network.backend.id
  }
  depends_on = [hcloud_network_subnet.backend]
}

module "load_balancer" {
  source            = "../.."
  name              = "application"
  type              = "lb11"
  location          = null
  network_zone      = "eu-central"
  algorithm         = "least_connections"
  delete_protection = true
  labels            = { environment = "example" }
  network = {
    subnet_id               = hcloud_network_subnet.backend.id
    ip                      = "10.0.1.5"
    enable_public_interface = true
  }
  targets = {
    app       = { type = "server", server_id = hcloud_server.backend["app"].id, use_private_ip = true }
    workers   = { type = "label_selector", label_selector = "role=worker", use_private_ip = true }
    dedicated = { type = "ip", ip = var.dedicated_ip }
  }
  services = {
    secure = {
      protocol         = "https"
      listen_port      = 443
      destination_port = 8080
      proxyprotocol    = false
      http = {
        certificates    = var.certificate_ids
        sticky_sessions = true
        cookie_name     = "SESSION"
        cookie_lifetime = 600
        redirect_http   = true
        timeout_idle    = 120
      }
      health_check = {
        protocol = "http"
        port     = 8080
        interval = 10
        timeout  = 5
        retries  = 3
        http = {
          domain       = "example.com"
          path         = "/health"
          response     = "OK"
          tls          = false
          status_codes = ["200"]
        }
      }
    }
    passthrough = {
      protocol         = "tcp"
      listen_port      = 8443
      destination_port = 443
      proxyprotocol    = false
      health_check     = { protocol = "tcp", port = 443, interval = 10, timeout = 5, retries = 3 }
    }
  }
  # Label selectors contain no reference to the selected servers.
  depends_on = [hcloud_server.backend]
}
