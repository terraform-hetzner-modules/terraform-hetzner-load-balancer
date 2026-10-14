variable "name" {
  description = "Name of the Load Balancer."
  type        = string
}

variable "type" {
  description = "Load Balancer type, for example lb11."
  type        = string
}

variable "location" {
  description = "Load Balancer location. Set null when selecting placement through network_zone instead."
  type        = string
  default     = "fsn1"
}

variable "network_zone" {
  description = "Network zone for placement instead of a specific location."
  type        = string
  default     = null
}

variable "algorithm" {
  description = "Balancing algorithm: round_robin or least_connections. Null delegates to the provider default."
  type        = string
  default     = null

  validation {
    condition     = var.algorithm == null ? true : contains(["round_robin", "least_connections"], var.algorithm)
    error_message = "Algorithm must be round_robin or least_connections."
  }
}

variable "labels" {
  description = "Labels attached to the Load Balancer."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "delete_protection" {
  description = "Enable deletion protection for the Load Balancer."
  type        = bool
  default     = true
  nullable    = false
}

variable "ipv4_id" {
  description = "Existing Primary IPv4 ID. Null lets Hetzner allocate one. Changing this replaces the Load Balancer."
  type        = number
  default     = null
}

variable "ipv6_id" {
  description = "Existing Primary IPv6 ID. Null lets Hetzner allocate one. Changing this replaces the Load Balancer."
  type        = number
  default     = null
}

variable "network" {
  description = "Optional private network attachment. Configure exactly one of network_id or subnet_id; prefer subnet_id for explicit subnet dependencies. Keep the object present when IDs are computed."
  type = object({
    network_id              = optional(number)
    subnet_id               = optional(string)
    ip                      = optional(string)
    enable_public_interface = optional(bool, true)
  })
  default = null

  validation {
    condition     = var.network == null ? true : (var.network.network_id != null) != (var.network.subnet_id != null)
    error_message = "Network attachment requires exactly one of network_id or subnet_id."
  }
}

variable "services" {
  description = "Services keyed by stable identifiers. All ports and HTTP/health-check settings are configurable; omitted optional fields use provider defaults. TCP services require explicit listen and destination ports."
  type = map(object({
    protocol         = string
    listen_port      = optional(number)
    destination_port = optional(number)
    proxyprotocol    = optional(bool)
    http = optional(object({
      sticky_sessions = optional(bool)
      cookie_name     = optional(string)
      cookie_lifetime = optional(number)
      certificates    = optional(set(number))
      redirect_http   = optional(bool)
      timeout_idle    = optional(number)
    }))
    health_check = optional(object({
      protocol = string
      port     = number
      interval = number
      timeout  = number
      retries  = number
      http = optional(object({
        domain       = optional(string)
        path         = optional(string)
        response     = optional(string)
        tls          = optional(bool)
        status_codes = optional(list(string))
      }))
    }))
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for service in values(var.services) : contains(["http", "https", "tcp"], service.protocol)])
    error_message = "Service protocols must be http, https, or tcp."
  }

  validation {
    condition     = alltrue([for service in values(var.services) : service.protocol == "tcp" ? service.listen_port != null && service.destination_port != null && service.http == null : true])
    error_message = "TCP services require listen_port and destination_port and cannot include an HTTP configuration."
  }
}

variable "targets" {
  description = "Targets keyed by stable identifiers. Type selects exactly one of server_id, label_selector, or ip. Omit use_private_ip for IP targets."
  type = map(object({
    type           = string
    server_id      = optional(number)
    label_selector = optional(string)
    ip             = optional(string)
    use_private_ip = optional(bool)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([for target in values(var.targets) : (
      target.type == "server" ? target.server_id != null && target.label_selector == null && target.ip == null :
      target.type == "label_selector" ? target.label_selector != null && target.server_id == null && target.ip == null :
      target.type == "ip" ? target.ip != null && target.server_id == null && target.label_selector == null && target.use_private_ip == null : false
    )])
    error_message = "Targets require type server/label_selector/ip and only the matching selector. IP targets must omit use_private_ip."
  }
}
