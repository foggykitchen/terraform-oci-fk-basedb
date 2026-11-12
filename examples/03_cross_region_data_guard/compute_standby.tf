module "bastion_standby" {
  source                   = "git::https://github.com/foggykitchen/terraform-oci-fk-compute.git?ref=v0.2.2"
  providers                = { oci = oci.standby }
  compartment_ocid         = module.compartment.compartment_id
  tenancy_ocid             = var.tenancy_ocid
  name                     = "${var.name_prefix}-standby-bastion"
  availability_domain      = local.standby_ad
  shape                    = "VM.Standard.E4.Flex"
  shape_config             = { ocpus = 1, memory_in_gbs = 8 }
  operating_system         = "Oracle Linux"
  operating_system_version = "9"
  subnet_id                = module.network_standby.subnet_ids["bastion"]
  nsg_ids                  = module.bastion_nsg_standby.nsg_ids
  assign_public_ip         = true
  ssh_authorized_keys      = local.ssh_public_keys
  user_data                = filebase64("${path.module}/cloud-init.yaml")
}
