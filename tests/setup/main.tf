terraform {
  required_version = ">= 1.7"
  required_providers {
    hcloud = { source = "hetznercloud/hcloud", version = "~> 1.70" }
  }
}

resource "terraform_data" "server_id" { input = 123 }
resource "terraform_data" "subnet_id" { input = "77-10.0.1.0/24" }
resource "terraform_data" "certificate_id" { input = 11 }

module "subject" {
  source  = "../.."
  name    = "computed-balancer"
  type    = "lb11"
  network = { subnet_id = terraform_data.subnet_id.output }
  targets = { app = { type = "server", server_id = terraform_data.server_id.output, use_private_ip = true } }
  services = {
    secure = { protocol = "https", http = { certificates = [terraform_data.certificate_id.output] } }
  }
}

output "target_keys" {
  description = "Target addresses stay known while server and subnet IDs are computed."
  value       = keys(module.subject.targets)
}

output "service_keys" {
  description = "Service addresses stay known while certificate IDs are computed."
  value       = keys(module.subject.services)
}
