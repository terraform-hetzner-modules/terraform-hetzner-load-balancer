<p align="center">
    <!-- terraform-hetzner-load-balancer -->
<img src="https://cdn.simpleicons.org/terraform/844FBA" alt="Terraform Logo" align="center" width="128">
<img src="https://avatars.githubusercontent.com/u/30047064?s=200&v=4" alt="Hetzner Logo" align="center" width="128">
    <h1 align="center">Hetzner Cloud</h1>
    <h2 align="center"><code>load-balancer</code></h2>
</p>

[![License](https://img.shields.io/github/license/terraform-hetzner-modules/terraform-hetzner-load-balancer?label=License)](https://opensource.org/licenses/MIT)
[![Terraform](https://img.shields.io/badge/Terraform-_>=_1.7-brightgreen?logo=terraform&logoColor=623CE4)][terraform]
[![Opentofu](https://img.shields.io/badge/OpenTofu-_>=_1.8-brightgreen?logo=opentofu)][opentofu]
[![CI Status](https://github.com/terraform-hetzner-modules/terraform-hetzner-load-balancer/actions/workflows/testing.yaml/badge.svg)](https://github.com/terraform-hetzner-modules/terraform-hetzner-load-balancer/blob/main/.github/workflows/testing.yaml)
[![GitHub Release](https://img.shields.io/github/v/release/terraform-hetzner-modules/terraform-hetzner-load-balancer?label=Release)][github_releases]
[![GitHub Activity](https://img.shields.io/github/commit-activity/m/terraform-hetzner-modules/terraform-hetzner-load-balancer?label=Commits)][github_commits]
[![Renovate](https://img.shields.io/badge/Renovate-enabled-brightgreen?logo=renovate&logoColor=1A1F6C)][renovate]
[![Pre-Commit](https://img.shields.io/badge/PreCommit-enabled-brightgreen?logo=precommit&logoColor=FAB040)][pre-commit]

A [Terraform module][module] to manage a [Hetzner Cloud][hetzner] Load Balancer, its services, targets, and private network attachment.

## ✨ TL;DR

```hcl
module "load_balancer" {
  source = "terraform-hetzner-modules/load-balancer/hetzner"
  name   = "web"
  type   = "lb11"

  services = {
    web = { protocol = "http", destination_port = 8080 }
  }
  targets = {
    app   = { type = "server", server_id = module.server.id }
    fleet = { type = "label_selector", label_selector = "role=web" }
  }
}
```

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

## Compatibility and examples

Requires Terraform >= 1.7 (OpenTofu >= 1.8 tested) and hcloud ~> 1.70.
See [basic](examples/basic) and [full](examples/full) examples; configure credentials through `HCLOUD_TOKEN`.
The full example expects existing certificate IDs and an eligible dedicated-server IPv4. It provisions
infrastructure; configure applications on the backends before expecting healthy targets.
The generated [schema report](docs/SCHEMA.md) records provider fields and module mappings.
See the [maintenance and upgrade guide](docs/UPGRADING.md) for validation and coverage checks.
Run `terraform init -backend=false`, `terraform validate`, and `terraform test`
for credential-free validation and mocked tests.

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_hcloud"></a> [hcloud](#provider\_hcloud) | ~> 1.70 |

## Modules

No modules.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_algorithm"></a> [algorithm](#input\_algorithm) | Balancing algorithm: round\_robin or least\_connections. Null delegates to the provider default. | `string` | `null` | no |
| <a name="input_delete_protection"></a> [delete\_protection](#input\_delete\_protection) | Enable deletion protection for the Load Balancer. | `bool` | `true` | no |
| <a name="input_ipv4_id"></a> [ipv4\_id](#input\_ipv4\_id) | Existing Primary IPv4 ID. Null lets Hetzner allocate one. Changing this replaces the Load Balancer. | `number` | `null` | no |
| <a name="input_ipv6_id"></a> [ipv6\_id](#input\_ipv6\_id) | Existing Primary IPv6 ID. Null lets Hetzner allocate one. Changing this replaces the Load Balancer. | `number` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels attached to the Load Balancer. | `map(string)` | `{}` | no |
| <a name="input_location"></a> [location](#input\_location) | Load Balancer location. Set null when selecting placement through network\_zone instead. | `string` | `"fsn1"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the Load Balancer. | `string` | n/a | yes |
| <a name="input_network"></a> [network](#input\_network) | Optional private network attachment. Configure exactly one of network\_id or subnet\_id; prefer subnet\_id for explicit subnet dependencies. Keep the object present when IDs are computed. | ```object({ network_id = optional(number) subnet_id = optional(string) ip = optional(string) enable_public_interface = optional(bool, true) })``` | `null` | no |
| <a name="input_network_zone"></a> [network\_zone](#input\_network\_zone) | Network zone for placement instead of a specific location. | `string` | `null` | no |
| <a name="input_services"></a> [services](#input\_services) | Services keyed by stable identifiers. All ports and HTTP/health-check settings are configurable; omitted optional fields use provider defaults. TCP services require explicit listen and destination ports. | ```map(object({ protocol = string listen_port = optional(number) destination_port = optional(number) proxyprotocol = optional(bool) http = optional(object({ sticky_sessions = optional(bool) cookie_name = optional(string) cookie_lifetime = optional(number) certificates = optional(set(number)) redirect_http = optional(bool) timeout_idle = optional(number) })) health_check = optional(object({ protocol = string port = number interval = number timeout = number retries = number http = optional(object({ domain = optional(string) path = optional(string) response = optional(string) tls = optional(bool) status_codes = optional(list(string)) })) })) }))``` | `{}` | no |
| <a name="input_targets"></a> [targets](#input\_targets) | Targets keyed by stable identifiers. Type selects exactly one of server\_id, label\_selector, or ip. Omit use\_private\_ip for IP targets. | ```map(object({ type = string server_id = optional(number) label_selector = optional(string) ip = optional(string) use_private_ip = optional(bool) }))``` | `{}` | no |
| <a name="input_type"></a> [type](#input\_type) | Load Balancer type, for example lb11. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_id"></a> [id](#output\_id) | Load Balancer ID. |
| <a name="output_ipv4"></a> [ipv4](#output\_ipv4) | Public IPv4 address. |
| <a name="output_ipv4_id"></a> [ipv4\_id](#output\_ipv4\_id) | Primary IPv4 ID. |
| <a name="output_ipv6"></a> [ipv6](#output\_ipv6) | Public IPv6 address. |
| <a name="output_ipv6_id"></a> [ipv6\_id](#output\_ipv6\_id) | Primary IPv6 ID. |
| <a name="output_load_balancer"></a> [load\_balancer](#output\_load\_balancer) | Supported Load Balancer attributes, excluding deprecated inline targets. Network fields reflect the balancer's last refresh; use network for managed attachment state. |
| <a name="output_name"></a> [name](#output\_name) | Load Balancer name. |
| <a name="output_network"></a> [network](#output\_network) | Complete managed private network attachment, or null when disabled. |
| <a name="output_services"></a> [services](#output\_services) | Complete service attributes indexed by the caller's stable keys. |
| <a name="output_targets"></a> [targets](#output\_targets) | Complete target attributes indexed by the caller's stable keys. |
<!-- END_TF_DOCS -->

### 🔃 Contributing

Refer to our [documentation for contributors][contributing] for contributing guidelines, commit message
formats and versioning tips.

### 📥 Maintainers

This project is owned and maintained by [Terraform Hetzner Modules][org]. Refer to the [`AUTHORS`][authors] or [`CODEOWNERS`][owners]
for more information. You may also use the linked contact details to reach out directly.

### ©️ Copyright

- _Assets provided by:_ **[HashiCorp][hashicorp]**
- _Sources provided by:_ **[Terraform Hetzner Modules][org]** under the **[MIT License][license]**

<!-- INTERNAL REFERENCES -->

<!-- Project references -->

<!-- File references -->

[license]: LICENSE
[contributing]: docs/CONTRIBUTING.md
[authors]: .github/AUTHORS
[owners]: .github/CODEOWNERS

<!-- General links -->

[org]: https://github.com/terraform-hetzner-modules
[terraform]: https://terraform.io
[opentofu]: https://opentofu.org/
[hashicorp]: https://www.hashicorp.com/
[hetzner]: https://hetzner.com
[github_releases]: https://github.com/terraform-hetzner-modules/terraform-hetzner-load-balancer/releases
[github_commits]: https://github.com/terraform-hetzner-modules/terraform-hetzner-load-balancer/commits/main/

<!-- Third-party -->

[module]: https://registry.terraform.io/modules/terraform-hetzner-modules/load-balancer/hetzner/latest
[renovate]: https://renovatebot.com/
[pre-commit]: https://pre-commit.com/
