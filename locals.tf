locals {
  is_primary   = var.role == "PRIMARY"
  db_system_id = local.is_primary ? oci_database_db_system.this[0].id : oci_database_data_guard_association.this[0].peer_db_system_id
  database_id  = local.is_primary ? oci_database_db_system.this[0].db_home[0].database[0].id : oci_database_data_guard_association.this[0].peer_database_id
}
