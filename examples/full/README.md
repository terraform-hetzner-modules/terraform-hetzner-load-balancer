# Full load balancer example

Supply existing `certificate_ids` for TLS termination and `dedicated_ip` for an eligible dedicated
server owned by the account. Optionally supply compatible `ipv4_id` and `ipv6_id`; null lets Hetzner
allocate the public IPs. The example creates the balancer, private network, and Cloud backends.

The network attachment uses `subnet_id`. To select the network instead, set
`network_id = hcloud_network.backend.id` and `subnet_id = null`, retaining a dependency on the subnet.
Placement uses `network_zone` with `location = null`; setting a location is the alternative.

HTTPS termination demonstrates all HTTP and health-check fields. TCP forwards encrypted traffic.
Server, label-selector, and dedicated-IP targets show the three target alternatives. IP targets omit
`use_private_ip` because the provider forbids it for that target type. Selected backends are explicit
dependencies; label selectors alone do not establish creation ordering.

Configure backend listeners and health-check responses before expecting healthy targets. This example
creates infrastructure without installing backend software. Review deletion protection before cleanup.

## Running the example

Export `HCLOUD_TOKEN`, supply the inputs described in `variables.tf`, then run:

```shell
terraform init
terraform plan
terraform apply
```

This creates real infrastructure. Review the plan and any deletion protection before cleanup.
See the [module README](../../README.md) for provider configuration and input descriptions.
