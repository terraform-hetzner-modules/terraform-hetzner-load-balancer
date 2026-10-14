# Maintenance and upgrade guide

This module starts with Terraform >= 1.7 and `hetznercloud/hcloud ~> 1.70`.
The test matrix covers Terraform 1.7.5/1.16.6 and OpenTofu 1.8.8/1.13.1.
These are module compatibility tests; older engines are not necessarily in the provider's own supported test matrix.

## Before upgrading

Back up your root configuration's state and commit its dependency lock file. Update the module version,
run `terraform init -upgrade` (or `tofu init -upgrade`), and review the plan before applying it.
Child module lock files do not constrain a consuming root configuration.
Keep caller-supplied map keys stable to retain resource addresses.
Unknown object properties may be discarded by Terraform's object conversion; check input property names.

## Checks

Run `terraform init -backend=false`, `terraform validate`, and `terraform test` (or equivalent `tofu`
commands). Initialize and validate each example and submodule separately. Tests use mock providers;
no cloud credentials are needed and no real infrastructure is created.
Before release, check creation, a second no-change plan, updates, and teardown in a disposable Hetzner
project. Mocks do not verify live API behavior, quotas, or capacity.

## Provider coverage maintenance

Formr generates the [schema report](SCHEMA.md). With the module initialized,
run `formr schema . -o docs/SCHEMA.md` and `formr check . --report docs/SCHEMA.md`.
Use the same engine and provider selections recorded in the report's provenance.
The default policy checks inventory completeness and unresolved analysis. Strict interface coverage
and exception annotations are not yet implemented, so a passing check does not approve omitted fields.
Provider configuration belongs in the consuming root configuration; IDs and other computed attributes
are provider-managed rather than creation inputs.

Regenerate README inputs/outputs with `terraform-docs -c .github/linters/.terraform-docs.yml .`.

## Load Balancer resource coverage

This module manages `hcloud_load_balancer`, `hcloud_load_balancer_service`, `hcloud_load_balancer_target`,
and `hcloud_load_balancer_network`. The child resources derive their parent ID from the managed balancer.
All supported input fields, including nested HTTP and health checks, are exposed. SDK `id` attributes are
provider-managed, not creation inputs. The deprecated inline `target` block is intentionally omitted
in favor of the dedicated target resource, including for private IP selection.

Keep service and target map keys stable. A key rename changes a Terraform resource address; use a moved
block in the consuming configuration or a deliberate state migration when renaming existing entries.
Changing a service's protocol or listening port can replace the service; target selector changes can
replace targets. Network selection and private IP changes can replace the attachment.

Use the `network` output to observe the separately managed attachment, and `targets` for target state.
Do not mix these resources with separate owners of the same services, targets, or network attachment.
For adoption, import each child into its module resource address using the provider's documented ID format.
Review resulting plans before applying them; the module does not automatically migrate externally managed resources.

Live testing should cover HTTP and HTTPS health, certificate changes, TCP passthrough, private target
ordering, public-interface changes, a second no-change plan, child-resource removal, and teardown.
Mocks cannot verify routing, target eligibility, certificate validity, or service health.
