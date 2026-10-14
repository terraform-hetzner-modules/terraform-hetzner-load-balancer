resource "hcloud_load_balancer" "current" {
  name               = var.name
  load_balancer_type = var.type
  location           = var.location
  network_zone       = var.network_zone
  labels             = var.labels
  delete_protection  = var.delete_protection
  ipv4_id            = var.ipv4_id
  ipv6_id            = var.ipv6_id

  dynamic "algorithm" {
    for_each = var.algorithm == null ? [] : [var.algorithm]
    content {
      type = algorithm.value
    }
  }

  lifecycle {
    precondition {
      condition     = var.location != null || var.network_zone != null
      error_message = "Configure location or network_zone for Load Balancer placement."
    }
  }
}

resource "hcloud_load_balancer_network" "current" {
  count = var.network == null ? 0 : 1

  load_balancer_id        = hcloud_load_balancer.current.id
  network_id              = var.network.network_id
  subnet_id               = var.network.subnet_id
  ip                      = var.network.ip
  enable_public_interface = var.network.enable_public_interface
}

resource "hcloud_load_balancer_service" "current" {
  for_each = var.services

  load_balancer_id = hcloud_load_balancer.current.id
  protocol         = each.value.protocol
  listen_port      = each.value.listen_port
  destination_port = each.value.destination_port
  proxyprotocol    = each.value.proxyprotocol

  dynamic "http" {
    for_each = each.value.http == null ? [] : [each.value.http]
    content {
      sticky_sessions = http.value.sticky_sessions
      cookie_name     = http.value.cookie_name
      cookie_lifetime = http.value.cookie_lifetime
      certificates    = http.value.certificates
      redirect_http   = http.value.redirect_http
      timeout_idle    = http.value.timeout_idle
    }
  }

  dynamic "health_check" {
    for_each = each.value.health_check == null ? [] : [each.value.health_check]
    content {
      protocol = health_check.value.protocol
      port     = health_check.value.port
      interval = health_check.value.interval
      timeout  = health_check.value.timeout
      retries  = health_check.value.retries

      dynamic "http" {
        for_each = health_check.value.http == null ? [] : [health_check.value.http]
        content {
          domain       = http.value.domain
          path         = http.value.path
          response     = http.value.response
          tls          = http.value.tls
          status_codes = http.value.status_codes
        }
      }
    }
  }
}

resource "hcloud_load_balancer_target" "current" {
  for_each = var.targets

  load_balancer_id = hcloud_load_balancer.current.id
  type             = each.value.type
  server_id        = each.value.server_id
  label_selector   = each.value.label_selector
  ip               = each.value.ip
  use_private_ip   = each.value.use_private_ip

  # Private targets must be added after the Load Balancer joins the network.
  depends_on = [hcloud_load_balancer_network.current]
}
