module "primary" {
  source                  = "../.."
  providers               = { oci = oci, oci.target = oci }
  compartment_id          = module.compartment.compartment_id
  availability_domain     = local.primary_ad
  fault_domains           = ["FAULT-DOMAIN-1"]
  subnet_id               = module.network_primary.subnet_ids["database"]
  nsg_ids                 = module.database_nsg_primary.nsg_ids
  display_name            = "${var.name_prefix}-primary-dbsystem"
  hostname                = "fkprimary"
  shape                   = var.database_shape
  compute_model           = "ECPU"
  compute_count           = var.database_ecpus
  data_storage_size_in_gb = var.database_storage_gb
  license_model           = var.license_model
  database_name           = "FOGGYDB"
  database_version        = var.database_version
  database_edition        = "STANDARD_EDITION"
  admin_password          = var.admin_password
  ssh_public_keys         = local.ssh_public_keys
  vault_id                = data.oci_kms_vault.existing.id
  kms_key_id              = data.oci_kms_key.existing.id
  kms_key_version_id      = var.kms_key_version_id
  depends_on              = [module.database_nsg_primary, module.vault_iam]
}
