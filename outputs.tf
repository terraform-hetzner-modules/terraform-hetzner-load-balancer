output "load_balancer" {
  description = "Supported Load Balancer attributes, excluding deprecated inline targets. Network fields reflect the balancer's last refresh; use network for managed attachment state."
  value = {
    id                 = hcloud_load_balancer.current.id
    name               = hcloud_load_balancer.current.name
    load_balancer_type = hcloud_load_balancer.current.load_balancer_type
    location           = hcloud_load_balancer.current.location
    network_zone       = hcloud_load_balancer.current.network_zone
    algorithm          = hcloud_load_balancer.current.algorithm
    labels             = hcloud_load_balancer.current.labels
    delete_protection  = hcloud_load_balancer.current.delete_protection
    ipv4               = hcloud_load_balancer.current.ipv4
    ipv6               = hcloud_load_balancer.current.ipv6
    ipv4_id            = hcloud_load_balancer.current.ipv4_id
    ipv6_id            = hcloud_load_balancer.current.ipv6_id
    network_id         = hcloud_load_balancer.current.network_id
    network_ip         = hcloud_load_balancer.current.network_ip
  }
}

output "id" {
  description = "Load Balancer ID."
  value       = hcloud_load_balancer.current.id
}

output "name" {
  description = "Load Balancer name."
  value       = hcloud_load_balancer.current.name
}

output "ipv4" {
  description = "Public IPv4 address."
  value       = hcloud_load_balancer.current.ipv4
}

output "ipv6" {
  description = "Public IPv6 address."
  value       = hcloud_load_balancer.current.ipv6
}

output "ipv4_id" {
  description = "Primary IPv4 ID."
  value       = hcloud_load_balancer.current.ipv4_id
}

output "ipv6_id" {
  description = "Primary IPv6 ID."
  value       = hcloud_load_balancer.current.ipv6_id
}

output "network" {
  description = "Complete managed private network attachment, or null when disabled."
  value       = try(hcloud_load_balancer_network.current[0], null)
}

output "services" {
  description = "Complete service attributes indexed by the caller's stable keys."
  value       = hcloud_load_balancer_service.current
}

output "targets" {
  description = "Complete target attributes indexed by the caller's stable keys."
  value       = hcloud_load_balancer_target.current
}
