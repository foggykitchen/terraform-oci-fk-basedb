# Keep the service independent of the client: its endpoint IP restricts client ingress.
module "bastion_service" {
  source                       = "git::https://github.com/foggykitchen/terraform-oci-fk-bastion-service.git?ref=v0.2.0"
  compartment_ocid             = module.compartment.compartment_id
  name                         = "${replace(var.name_prefix, "-", "")}bastion"
  target_subnet_id             = module.network_primary.subnet_ids["bastion_endpoint"]
  client_cidr_block_allow_list = [var.admin_cidr]
  max_session_ttl_in_seconds   = 10800
  create_session               = false
}

# Create only after the client Bastion plugin reports RUNNING (see README).
resource "oci_bastion_session" "client" {
  count                  = var.create_session ? 1 : 0
  bastion_id             = module.bastion_service.bastion_id
  display_name           = "${var.name_prefix}-client"
  session_ttl_in_seconds = var.session_ttl_in_seconds
  key_details {
    public_key_content = local.ssh_public_keys[0]
  }
  target_resource_details {
    session_type                               = "MANAGED_SSH"
    target_resource_id                         = module.client_primary.instance_id
    target_resource_private_ip_address         = module.client_primary.instance_private_ip
    target_resource_operating_system_user_name = "opc"
    target_resource_port                       = 22
  }
}
