resource "ibm_resource_instance" "brs-instance" {
  count             = var.create_new ? 1 : 0
  name              = var.instance_name
  service           = var.name
  plan              = var.plan
  location          = var.region
  resource_group_id = var.resource_group_id
  parameters_json   = <<EOF
{
  "custom-prov-code": "${var.provision_code}"
}
EOF

  //User can increase timeouts
  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}
data "ibm_resource_instance" "brs-instance" {
  count             = var.create_new ? 0 : 1
  name              = var.instance_name
  location          = var.region
  resource_group_id = var.resource_group_id
  service           = var.name
}