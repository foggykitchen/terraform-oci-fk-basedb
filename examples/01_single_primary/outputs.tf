output "compartment_id" { value = module.compartment.compartment_id }
output "primary_vcn_id" { value = module.network_primary.vcn_id }
output "primary_bastion_public_ip" { value = module.bastion_primary.instance_public_ip }
output "primary_db_system_id" { value = module.primary.db_system_id }
output "primary_database_id" { value = module.primary.database_id }
output "primary_private_ips" { value = module.primary.private_ips }
output "primary_connection_strings" { value = module.primary.connection_strings }
