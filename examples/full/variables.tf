variable "certificate_ids" {
  description = "Existing Hetzner certificate IDs for TLS termination."
  type        = set(number)
}

variable "dedicated_ip" {
  description = "Reachable IPv4 of an eligible dedicated server owned by the account."
  type        = string
}

variable "ipv4_id" {
  description = "Optional existing compatible Primary IPv4 ID; null lets Hetzner allocate one."
  type        = number
  default     = null
}

variable "ipv6_id" {
  description = "Optional existing compatible Primary IPv6 ID; null lets Hetzner allocate one."
  type        = number
  default     = null
}
