# Hetzner Load Balancer Terraform module

Manage a Load Balancer with multiple services and targets, health checks, and optional private networking.

## Usage

Copy this configuration into `main.tf`.

```hcl
module "load_balancer" {
  source = "terraform-hetzner-modules/load-balancer/hetzner"

  name = "web"
  type = "lb11"
  services = {
    http = { protocol = "http", destination_port = 8080 }
  }
  targets = {
    web = { type = "label_selector", label_selector = "role=web" }
  }
}
```

Servers labeled `role=web` must serve HTTP on port 8080 and accept health checks from the balancer.
This configuration creates the infrastructure; backend software is configured separately.

## Examples

- [Basic](examples/basic): a service and server target.
- [Full](examples/full): every input and nested setting, HTTPS and TCP services, and all target types.

## Services and targets

One invocation creates one Load Balancer and any number of named `services` and `targets`, subject to
Hetzner's limits for the selected plan. Map keys are stable resource addresses; keep them stable when
editing settings. Empty maps create no child resources. Values such as server IDs and certificate IDs
may be computed, while map keys must be known during planning. The `services` and `targets` outputs
return complete resource attributes using those same keys.

Services expose protocol, listening and destination ports, proxy protocol, all HTTP settings, and nested
health checks. Optional values delegate to provider defaults. TCP services require explicit ports and
cannot use HTTP settings. HTTP health checks, including HTTPS checks, can configure domain, path,
response matching, TLS checking, and accepted status codes. Explicit health-check objects require
protocol, port, interval, timeout, and retries.

Use HTTPS with certificate IDs for TLS termination, or TCP to forward encrypted traffic to backends.
Choose distinct listening ports, including ports reserved by HTTP-to-HTTPS redirection.
Certificates are managed separately and supplied through `services.<key>.http.certificates`.
See the [provider's service reference](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/load_balancer_service)
for protocol-specific behavior and limits.

Each target supplies a type and exactly its matching `server_id`, `label_selector`, or `ip`.
Server and selector targets may enable `use_private_ip`; IP targets must omit that field, even when false.
The deprecated inline target block is intentionally excluded. Use the dedicated target resources managed
by this module and avoid managing the same targets outside it.

## Networking and placement

`location` defaults to `fsn1`. To select placement by `network_zone`, set `location = null`.
The `algorithm` input selects `round_robin` or `least_connections`; null uses the provider default.
`ipv4_id` and `ipv6_id` accept existing Primary IP IDs; null lets Hetzner allocate them.
Deletion protection defaults to true. Changes to location, network zone, or Primary IP IDs can replace
the balancer; review the plan before applying changes.

The optional `network` object manages a private network attachment. Provide exactly one of `network_id`
or `subnet_id`; prefer `subnet_id` so Terraform waits for the subnet to exist. You can select the private
`ip` and set `enable_public_interface = false` for private access. Keep the object present when its IDs
are computed. Omitting it creates no network attachment.

Targets wait for the managed network attachment before they are added. Ensure private backend servers
also finish joining that network before they are selected; label selectors do not establish Terraform
dependencies on the servers they match. The [full example](examples/full) shows explicit dependency ordering.
See [Hetzner's target requirements](https://docs.hetzner.com/networking/load-balancers/faq/) for eligible
backends and private networking constraints.

The `load_balancer` output includes supported balancer attributes, excluding deprecated inline targets.
Use the `network` output for managed attachment state; the balancer's own `network_id` and `network_ip`
may reflect its last refresh before the separate attachment was created. Convenience outputs expose
`id`, `name`, public addresses, and Primary IP IDs.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.7 |
| hcloud | ~> 1.70 |

## Providers

| Name | Version |
| ---- | ------- |
| hcloud | ~> 1.70 |

## Resources

| Name | Type |
| ---- | ---- |
| [hcloud_load_balancer.current](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/load_balancer) | resource |
| [hcloud_load_balancer_network.current](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/load_balancer_network) | resource |
| [hcloud_load_balancer_service.current](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/load_balancer_service) | resource |
| [hcloud_load_balancer_target.current](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/load_balancer_target) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| algorithm | Balancing algorithm: round\_robin or least\_connections. Null delegates to the provider default. | `string` | `null` | no |
| delete\_protection | Enable deletion protection for the Load Balancer. | `bool` | `true` | no |
| ipv4\_id | Existing Primary IPv4 ID. Null lets Hetzner allocate one. Changing this replaces the Load Balancer. | `number` | `null` | no |
| ipv6\_id | Existing Primary IPv6 ID. Null lets Hetzner allocate one. Changing this replaces the Load Balancer. | `number` | `null` | no |
| labels | Labels attached to the Load Balancer. | `map(string)` | `{}` | no |
| location | Load Balancer location. Set null when selecting placement through network\_zone instead. | `string` | `"fsn1"` | no |
| name | Name of the Load Balancer. | `string` | n/a | yes |
| network | Optional private network attachment. Configure exactly one of network\_id or subnet\_id; prefer subnet\_id for explicit subnet dependencies. Keep the object present when IDs are computed. | ```object({ network_id = optional(number) subnet_id = optional(string) ip = optional(string) enable_public_interface = optional(bool, true) })``` | `null` | no |
| network\_zone | Network zone for placement instead of a specific location. | `string` | `null` | no |
| services | Services keyed by stable identifiers. All ports and HTTP/health-check settings are configurable; omitted optional fields use provider defaults. TCP services require explicit listen and destination ports. | ```map(object({ protocol = string listen_port = optional(number) destination_port = optional(number) proxyprotocol = optional(bool) http = optional(object({ sticky_sessions = optional(bool) cookie_name = optional(string) cookie_lifetime = optional(number) certificates = optional(set(number)) redirect_http = optional(bool) timeout_idle = optional(number) })) health_check = optional(object({ protocol = string port = number interval = number timeout = number retries = number http = optional(object({ domain = optional(string) path = optional(string) response = optional(string) tls = optional(bool) status_codes = optional(list(string)) })) })) }))``` | `{}` | no |
| targets | Targets keyed by stable identifiers. Type selects exactly one of server\_id, label\_selector, or ip. Omit use\_private\_ip for IP targets. | ```map(object({ type = string server_id = optional(number) label_selector = optional(string) ip = optional(string) use_private_ip = optional(bool) }))``` | `{}` | no |
| type | Load Balancer type, for example lb11. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| id | Load Balancer ID. |
| ipv4 | Public IPv4 address. |
| ipv4\_id | Primary IPv4 ID. |
| ipv6 | Public IPv6 address. |
| ipv6\_id | Primary IPv6 ID. |
| load\_balancer | Supported Load Balancer attributes, excluding deprecated inline targets. Network fields reflect the balancer's last refresh; use network for managed attachment state. |
| name | Load Balancer name. |
| network | Complete managed private network attachment, or null when disabled. |
| services | Complete service attributes indexed by the caller's stable keys. |
| targets | Complete target attributes indexed by the caller's stable keys. |
<!-- END_TF_DOCS -->

## Contributing

See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for local checks and contribution guidelines, and
[UPGRADING.md](docs/UPGRADING.md) for compatibility and live acceptance checks. The generated
[schema report](docs/SCHEMA.md) documents provider coverage and intentional omissions.

## Authors

Maintained by [Terraform Hetzner Modules](https://github.com/terraform-hetzner-modules).
See [AUTHORS](.github/AUTHORS) and [CODEOWNERS](.github/CODEOWNERS).

## License

MIT. See [LICENSE](LICENSE).
