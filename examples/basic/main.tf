module "load_balancer" {
  source = "../.."
  name   = "web"
  type   = "lb11"

  services = { web = { protocol = "http" } }
  targets  = { web = { type = "label_selector", label_selector = "role=web" } }
}
