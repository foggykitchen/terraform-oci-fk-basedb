module "client_primary" {
  source                   = "git::https://github.com/foggykitchen/terraform-oci-fk-compute.git?ref=v0.3.0"
  providers                = { oci = oci }
  compartment_ocid         = module.compartment.compartment_id
  tenancy_ocid             = var.tenancy_ocid
  name                     = "${var.name_prefix}-primary-client"
  availability_domain      = local.primary_ad
  shape                    = "VM.Standard.E4.Flex"
  shape_config             = { ocpus = 1, memory_in_gbs = 8 }
  operating_system         = "Oracle Linux"
  operating_system_version = "9"
  subnet_id                = module.network_primary.subnet_ids["client"]
  nsg_ids                  = module.client_nsg_primary.nsg_ids
  assign_public_ip         = false
  ssh_authorized_keys      = local.ssh_public_keys
  agent_config = {
    are_all_plugins_disabled = false
    is_management_disabled   = false
    is_monitoring_disabled   = false
    plugins_config           = [{ name = "Bastion", desired_state = "ENABLED" }]
  }
  user_data = filebase64("${path.module}/cloud-init.yaml")
}
