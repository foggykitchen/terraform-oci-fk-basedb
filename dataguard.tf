# The provider must point to the SOURCE primary region, including cross-region deployments.
resource "oci_database_data_guard_association" "this" {
  count                            = local.is_primary ? 0 : 1
  creation_type                    = "NewDbSystem"
  database_id                      = var.primary_database_id
  database_admin_password          = var.admin_password
  availability_domain              = var.availability_domain
  display_name                     = var.display_name
  hostname                         = var.hostname
  domain                           = var.domain
  shape                            = var.shape
  cpu_core_count                   = var.compute_model == "OCPU" ? var.cpu_core_count : null
  compute_model                    = var.compute_model == "ECPU" ? "ECPU" : null
  compute_count                    = var.compute_model == "ECPU" ? var.compute_count : null
  node_count                       = var.node_count
  subnet_id                        = var.subnet_id
  nsg_ids                          = var.nsg_ids
  license_model                    = var.license_model
  fault_domains                    = var.fault_domains
  db_system_freeform_tags          = var.freeform_tags
  db_system_defined_tags           = var.defined_tags
  protection_mode                  = var.protection_mode
  transport_type                   = var.transport_type
  is_active_data_guard_enabled     = var.is_active_data_guard_enabled
  delete_standby_db_home_on_delete = var.delete_standby_db_home_on_delete
  lifecycle {
    precondition {
      condition     = var.compute_model == "ECPU" ? try(var.compute_count >= 4 && var.compute_count % 4 == 0 && var.shape == "VM.BaseDB.x86", false) : var.compute_count == null && var.shape != "VM.BaseDB.x86"
      error_message = "ECPU requires VM.BaseDB.x86 and compute_count >= 4 in multiples of 4; OCPU requires a legacy shape and no compute_count."
    }
    precondition {
      condition     = var.primary_database_id != null
      error_message = "STANDBY requires primary_database_id from the source primary database."
    }
    precondition {
      condition     = length(var.ssh_public_keys) == 0 && var.database_name == null && var.database_version == null
      error_message = "STANDBY inherits SSH keys, database name and database version; do not set these primary-only inputs."
    }
  }
}
