module "client_nsg_primary" {
  source           = "git::https://github.com/foggykitchen/terraform-oci-fk-nsg.git?ref=v0.2.0"
  providers        = { oci = oci }
  compartment_ocid = module.compartment.compartment_id
  vcn_id           = module.network_primary.vcn_id
  name             = "${var.name_prefix}-primary-client-nsg"
  security_rules = [
    { name = "bastion-service-ssh", direction = "INGRESS", protocol = "6", source = "${module.bastion_service.bastion_private_endpoint_ip_address}/32", source_type = "CIDR_BLOCK", tcp_options = { destination_port_range = { min = 22, max = 22 } } },
    { name = "primary-22", direction = "EGRESS", protocol = "6", destination = local.primary_db_cidr, destination_type = "CIDR_BLOCK", tcp_options = { destination_port_range = { min = 22, max = 22 } } },
    { name = "primary-1521", direction = "EGRESS", protocol = "6", destination = local.primary_db_cidr, destination_type = "CIDR_BLOCK", tcp_options = { destination_port_range = { min = 1521, max = 1521 } } },
    { name = "https", direction = "EGRESS", protocol = "6", destination = "0.0.0.0/0", destination_type = "CIDR_BLOCK", tcp_options = { destination_port_range = { min = 443, max = 443 } } },
    { name = "pmtud", direction = "INGRESS", protocol = "1", source = local.primary_vcn_cidr, source_type = "CIDR_BLOCK", icmp_options = { type = 3, code = 4 } }
  ]
}
module "database_nsg_primary" {
  source           = "git::https://github.com/foggykitchen/terraform-oci-fk-nsg.git?ref=v0.2.0"
  providers        = { oci = oci }
  compartment_ocid = module.compartment.compartment_id
  vcn_id           = module.network_primary.vcn_id
  name             = "${var.name_prefix}-primary-database-nsg"
  security_rules = [
    { name = "client-primary-22", direction = "INGRESS", protocol = "6", source = module.client_nsg_primary.nsg_id, source_type = "NETWORK_SECURITY_GROUP", tcp_options = { destination_port_range = { min = 22, max = 22 } } },
    { name = "client-primary-1521", direction = "INGRESS", protocol = "6", source = module.client_nsg_primary.nsg_id, source_type = "NETWORK_SECURITY_GROUP", tcp_options = { destination_port_range = { min = 1521, max = 1521 } } },
    { name = "https", direction = "EGRESS", protocol = "6", destination = "0.0.0.0/0", destination_type = "CIDR_BLOCK", tcp_options = { destination_port_range = { min = 443, max = 443 } } },
    { name = "pmtud", direction = "INGRESS", protocol = "1", source = local.primary_vcn_cidr, source_type = "CIDR_BLOCK", icmp_options = { type = 3, code = 4 } }
  ]
}
