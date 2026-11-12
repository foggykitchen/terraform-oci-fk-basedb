resource "oci_database_db_system" "this" {
  count                   = local.is_primary ? 1 : 0
  availability_domain     = var.availability_domain
  compartment_id          = var.compartment_id
  display_name            = var.display_name
  hostname                = var.hostname
  domain                  = var.domain
  shape                   = var.shape
  cpu_core_count          = var.compute_model == "OCPU" ? var.cpu_core_count : null
  compute_model           = var.compute_model == "ECPU" ? "ECPU" : null
  compute_count           = var.compute_model == "ECPU" ? var.compute_count : null
  node_count              = var.node_count
  subnet_id               = var.subnet_id
  nsg_ids                 = var.nsg_ids
  ssh_public_keys         = [for key in var.ssh_public_keys : trimspace(key)]
  database_edition        = var.database_edition
  data_storage_size_in_gb = var.data_storage_size_in_gb
  data_storage_percentage = var.data_storage_percentage
  disk_redundancy         = var.disk_redundancy
  license_model           = var.license_model
  fault_domains           = var.fault_domains
  freeform_tags           = var.freeform_tags
  defined_tags            = var.defined_tags
  dynamic "db_system_options" {
    for_each = var.compute_model == "ECPU" ? [1] : []
    content {
      storage_management = "LVM"
    }
  }
  db_home {
    db_version   = var.database_version
    display_name = var.db_home_display_name
    database {
      admin_password = var.admin_password
      db_name        = var.database_name
      pdb_name       = var.pdb_name
      character_set  = var.character_set
      ncharacter_set = var.ncharacter_set
      db_workload    = var.database_workload
      db_backup_config {
        auto_backup_enabled = var.auto_backup_enabled
      }
    }
  }
  lifecycle {
    precondition {
      condition     = var.compute_model == "ECPU" ? try(var.compute_count >= 4 && var.compute_count % 4 == 0 && var.shape == "VM.BaseDB.x86", false) : var.compute_count == null && var.shape != "VM.BaseDB.x86"
      error_message = "ECPU requires VM.BaseDB.x86 and compute_count >= 4 in multiples of 4; OCPU requires a legacy shape and no compute_count."
    }
    precondition {
      condition     = var.database_name != null && var.database_version != null && length(var.ssh_public_keys) > 0
      error_message = "PRIMARY requires database_name, database_version and at least one ssh_public_keys entry."
    }
    precondition {
      condition     = var.primary_database_id == null
      error_message = "primary_database_id is only applicable to STANDBY."
    }
  }
}
