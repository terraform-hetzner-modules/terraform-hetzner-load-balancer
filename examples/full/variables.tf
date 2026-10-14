variable "certificate_ids" {
  description = "Existing Hetzner certificate IDs for TLS termination."
  type        = set(number)
}

variable "dedicated_ip" {
  description = "Reachable IPv4 of an eligible dedicated server owned by the account."
  type        = string
}
