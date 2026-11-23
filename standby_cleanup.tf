# Always retain the metadata resource for STANDBY, including when disabled.
# Toggling enabled updates input in place rather than destroying an armed hook.
# Its reference to the association orders cleanup BEFORE association destruction.
resource "terraform_data" "standby_cleanup" {
  count = local.is_primary ? 0 : 1

  input = {
    enabled             = var.standby_cleanup.enabled
    region              = var.standby_region_hint
    profile             = var.standby_cleanup.oci_cli_profile
    db_system_id        = oci_database_data_guard_association.this[0].peer_db_system_id
    database_id         = oci_database_data_guard_association.this[0].peer_database_id
    peer_association_id = oci_database_data_guard_association.this[0].peer_data_guard_association_id
    # Store the command in state so removing the module directory cannot change it.
    cleanup_command = file("${path.module}/scripts/terminate-standby.sh")
  }

  triggers_replace = [oci_database_data_guard_association.this[0].peer_db_system_id]

  provisioner "local-exec" {
    when        = destroy
    on_failure  = fail
    interpreter = ["/bin/bash", "-c"]
    command     = self.input.cleanup_command
    environment = {
      CLEANUP_ENABLED     = tostring(self.input.enabled)
      STANDBY_REGION      = self.input.region == null ? "" : self.input.region
      OCI_CLEANUP_PROFILE = self.input.profile == null ? "" : self.input.profile
      STANDBY_DB_SYSTEM   = self.input.db_system_id
      STANDBY_DATABASE    = self.input.database_id
      PEER_ASSOCIATION    = self.input.peer_association_id
    }
  }
}
