output "load_balancer" {
  description = "Load Balancer connection details and settings."
  value       = module.load_balancer.load_balancer
}

output "services" {
  description = "Configured services by name."
  value       = module.load_balancer.services
}
