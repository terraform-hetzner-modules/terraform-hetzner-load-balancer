mock_provider "hcloud" {
  mock_resource "hcloud_load_balancer" {
    defaults = { id = "42", ipv4 = "192.0.2.1", ipv6 = "2001:db8::1" }
  }
  mock_resource "hcloud_load_balancer_network" { defaults = { id = "42-77" } }
}

variables {
  name = "test-balancer"
  type = "lb11"
}

run "empty_balancer" {
  command = apply
  assert {
    condition     = length(output.services) == 0 && length(output.targets) == 0 && output.network == null && output.load_balancer.delete_protection
    error_message = "A balancer must support empty services/targets and no private network, with protection enabled."
  }
  assert {
    condition     = output.id == "42" && output.ipv4 == "192.0.2.1" && output.ipv6 == "2001:db8::1"
    error_message = "Balancer and Primary IP IDs and addresses must be exported."
  }
}

run "all_resources_and_nested_settings" {
  command = apply
  variables {
    location          = null
    network_zone      = "eu-central"
    algorithm         = "least_connections"
    delete_protection = false
    ipv4_id           = 201
    ipv6_id           = 202
    labels            = { environment = "test" }
    network           = { subnet_id = "77-10.0.1.0/24", ip = "10.0.1.5", enable_public_interface = false }
    targets = {
      app       = { type = "server", server_id = 123, use_private_ip = true }
      fleet     = { type = "label_selector", label_selector = "role=backend", use_private_ip = false }
      dedicated = { type = "ip", ip = "198.51.100.5" }
    }
    services = {
      web = { protocol = "http", listen_port = 80, destination_port = 8080, proxyprotocol = false }
      secure = {
        protocol         = "https"
        listen_port      = 443
        destination_port = 8080
        http = {
          sticky_sessions = true
          cookie_name     = "SESSION"
          cookie_lifetime = 600
          certificates    = [11, 22]
          redirect_http   = false
          timeout_idle    = 120
        }
        health_check = {
          protocol = "https"
          port     = 8443
          interval = 10
          timeout  = 5
          retries  = 2
          http     = { domain = "example.com", path = "/health", response = "OK", tls = true, status_codes = ["200", "301"] }
        }
      }
      passthrough = {
        protocol         = "tcp"
        listen_port      = 8443
        destination_port = 443
        proxyprotocol    = true
        health_check     = { protocol = "tcp", port = 443, interval = 15, timeout = 5, retries = 3 }
      }
    }
  }
  assert {
    condition     = output.load_balancer.network_zone == "eu-central" && output.load_balancer.algorithm[0].type == "least_connections" && !output.load_balancer.delete_protection && output.load_balancer.labels.environment == "test" && output.ipv4_id == 201 && output.ipv6_id == 202
    error_message = "Placement, algorithm, labels, protection, and Primary IP choices must reach the balancer."
  }
  assert {
    condition     = output.network.load_balancer_id == tonumber(output.id) && output.network.subnet_id == "77-10.0.1.0/24" && output.network.ip == "10.0.1.5" && !output.network.enable_public_interface
    error_message = "Subnet selection, private IP, and disabled public networking must be preserved."
  }
  assert {
    condition     = keys(output.targets) == ["app", "dedicated", "fleet"] && output.targets.app.server_id == 123 && output.targets.app.use_private_ip && output.targets.app.load_balancer_id == tonumber(output.id) && output.targets.fleet.label_selector == "role=backend" && !output.targets.fleet.use_private_ip && output.targets.dedicated.ip == "198.51.100.5"
    error_message = "All target types and private/public selection must be configurable."
  }
  assert {
    condition     = keys(output.services) == ["passthrough", "secure", "web"] && output.services.secure.load_balancer_id == output.id && output.services.web.listen_port == 80 && output.services.web.destination_port == 8080 && !output.services.web.proxyprotocol && output.services.passthrough.proxyprotocol && output.services.passthrough.protocol == "tcp"
    error_message = "Named services must preserve protocols, ports, proxy protocol, and parent IDs."
  }
  assert {
    condition     = output.services.secure.http[0].sticky_sessions && output.services.secure.http[0].cookie_name == "SESSION" && output.services.secure.http[0].cookie_lifetime == 600 && output.services.secure.http[0].certificates == toset([11, 22]) && !output.services.secure.http[0].redirect_http && output.services.secure.http[0].timeout_idle == 120
    error_message = "HTTPS certificate, sticky-session, redirect, and idle-timeout settings must be preserved."
  }
  assert {
    condition     = output.services.secure.health_check[0].protocol == "https" && output.services.secure.health_check[0].port == 8443 && output.services.secure.health_check[0].interval == 10 && output.services.secure.health_check[0].timeout == 5 && output.services.secure.health_check[0].retries == 2 && output.services.secure.health_check[0].http[0].domain == "example.com" && output.services.secure.health_check[0].http[0].path == "/health" && output.services.secure.health_check[0].http[0].response == "OK" && output.services.secure.health_check[0].http[0].tls && output.services.secure.health_check[0].http[0].status_codes == tolist(["200", "301"]) && output.services.passthrough.health_check[0].protocol == "tcp"
    error_message = "All nested HTTP and TCP health-check fields must reach the provider."
  }
}

run "network_id_and_remaining_targets" {
  command = apply
  variables {
    network   = { network_id = 88 }
    algorithm = "round_robin"
    targets   = { app = { type = "server", server_id = 456 } }
    services  = { web = { protocol = "http" } }
  }
  assert {
    condition     = output.network.network_id == 88 && output.network.enable_public_interface && keys(output.targets) == ["app"] && output.targets.app.server_id == 456 && keys(output.services) == ["web"] && output.load_balancer.algorithm[0].type == "round_robin"
    error_message = "Network-ID selection and per-key target/service changes must be supported."
  }
}

run "reject_missing_placement" {
  command = plan
  variables { location = null }
  expect_failures = [hcloud_load_balancer.current]
}

run "reject_invalid_algorithm" {
  command = plan
  variables { algorithm = "random" }
  expect_failures = [var.algorithm]
}

run "reject_ambiguous_network" {
  command = plan
  variables { network = { network_id = 77, subnet_id = "77-10.0.1.0/24" } }
  expect_failures = [var.network]
}

run "reject_empty_network" {
  command = plan
  variables { network = {} }
  expect_failures = [var.network]
}

run "reject_mismatched_target" {
  command = plan
  variables { targets = { bad = { type = "server", label_selector = "role=backend" } } }
  expect_failures = [var.targets]
}

run "reject_ambiguous_target" {
  command = plan
  variables { targets = { bad = { type = "server", server_id = 123, ip = "198.51.100.5" } } }
  expect_failures = [var.targets]
}

run "reject_private_flag_on_ip_target" {
  command = plan
  variables { targets = { bad = { type = "ip", ip = "198.51.100.5", use_private_ip = false } } }
  expect_failures = [var.targets]
}

run "reject_tcp_without_ports" {
  command = plan
  variables { services = { bad = { protocol = "tcp" } } }
  expect_failures = [var.services]
}

run "reject_http_settings_on_tcp" {
  command = plan
  variables { services = { bad = { protocol = "tcp", listen_port = 443, destination_port = 443, http = {} } } }
  expect_failures = [var.services]
}
