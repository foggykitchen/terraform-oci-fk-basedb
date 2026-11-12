# The association request goes to the PRIMARY region; discovery goes to the target region.
module "standby" {
  source              = "../.."
  providers           = { oci = oci, oci.target = oci.standby }
  role                = "STANDBY"
  primary_database_id = module.primary.database_id
  compartment_id      = module.compartment.compartment_id
  availability_domain = local.standby_ad
  fault_domains       = ["FAULT-DOMAIN-2"]
  subnet_id           = module.network_standby.subnet_ids["database"]
  nsg_ids             = module.database_nsg_standby.nsg_ids
  display_name        = "${var.name_prefix}-standby-dbsystem"
  hostname            = "fkstandby"
  shape               = var.database_shape
  compute_model       = "ECPU"
  compute_count       = var.database_ecpus
  license_model       = var.license_model
  admin_password      = var.admin_password
  depends_on          = [module.database_nsg_standby, module.drg_primary, module.drg_standby]
}
