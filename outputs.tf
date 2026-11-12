output "db_system_id" {
  description = "DB system OCID of this primary or standby."
  value       = local.db_system_id
}

output "database_id" {
  description = "Database OCID of this primary or standby, never the source database for standby."
  value       = local.database_id
}

output "db_home_id" {
  description = "DB Home OCID of this primary or standby."
  value       = data.oci_database_database.this.db_home_id
}

output "private_ips" {
  description = "Private IP addresses of the target DB system nodes; ordering follows the OCI node list."
  value       = data.oci_core_vnic.this[*].private_ip_address
}

output "connection_strings" {
  description = "Connection strings reported for the target database; a standby may have restricted access."
  value       = data.oci_database_database.this.connection_strings
}

output "state" {
  description = "Target database lifecycle state."
  value       = data.oci_database_database.this.state
}

output "data_guard_association_id" {
  description = "Source-side Data Guard association OCID; null for PRIMARY."
  value       = local.is_primary ? null : oci_database_data_guard_association.this[0].id
}

output "peer_data_guard_association_id" {
  description = "Target-side Data Guard association OCID; null for PRIMARY."
  value       = local.is_primary ? null : oci_database_data_guard_association.this[0].peer_data_guard_association_id
}

output "data_guard_role" {
  description = "Observed role of the standby-side peer. Null when this module does not manage an association."
  value       = local.is_primary ? null : oci_database_data_guard_association.this[0].peer_role
}
