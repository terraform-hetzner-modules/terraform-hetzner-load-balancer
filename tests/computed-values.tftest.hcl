mock_provider "hcloud" {
  mock_resource "hcloud_load_balancer" {
    defaults = { id = "42", ipv4 = "192.0.2.1", ipv6 = "2001:db8::1" }
  }
  mock_resource "hcloud_load_balancer_network" { defaults = { id = "42-77" } }
}

run "computed_ids_are_plannable" {
  command = plan
  module { source = "./tests/setup" }
  assert {
    condition     = output.target_keys == ["app"] && output.service_keys == ["secure"]
    error_message = "Computed server, subnet, and certificate IDs must not make resource addresses unknown."
  }
}
