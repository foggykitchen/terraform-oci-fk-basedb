module "network_primary" {
  source                  = "git::https://github.com/foggykitchen/terraform-oci-fk-vcn.git?ref=v0.3.0"
  providers               = { oci = oci }
  compartment_ocid        = module.compartment.compartment_id
  name                    = "${var.name_prefix}-primary-vcn"
  dns_label               = "fkprimary"
  vcn_cidr_blocks         = [local.primary_vcn_cidr]
  create_internet_gateway = false
  create_nat_gateway      = true
  create_service_gateway  = true
  security_lists = {
    bastion_endpoint = {
      display_name  = "Bastion endpoint SSH egress"
      ingress_rules = []
      egress_rules = [
        { protocol = "6", destination = local.primary_client_cidr, destination_type = "CIDR_BLOCK", tcp_options = { min = 22, max = 22 } }
      ]
    }
    nsg_only = { display_name = "NSG-only", ingress_rules = [], egress_rules = [] }
  }
  route_tables = {
    private = {
      route_rules = [
        { destination = "0.0.0.0/0", network_entity_key = "nat_gateway" },
        { destination = "all-services", destination_type = "SERVICE_CIDR_BLOCK", network_entity_key = "service_gateway" },
      ]
    }
  }
  subnets = {
    bastion_endpoint = {
      cidr_block                    = local.primary_endpoint_cidr
      display_name                  = "fk-bastion-endpoint-private"
      dns_label                     = "endpoint"
      route_table_key               = "private"
      security_list_keys            = ["bastion_endpoint"]
      include_default_security_list = false
      prohibit_public_ip_on_vnic    = true
      prohibit_internet_ingress     = true
    }
    client = {
      cidr_block                    = local.primary_client_cidr
      display_name                  = "fk-client-subnet-private"
      dns_label                     = "client"
      route_table_key               = "private"
      security_list_keys            = ["nsg_only"]
      include_default_security_list = false
      prohibit_public_ip_on_vnic    = true
      prohibit_internet_ingress     = true
    }
    database = {
      cidr_block                    = local.primary_db_cidr
      display_name                  = "fk-basedb-subnet-private"
      dns_label                     = "database"
      route_table_key               = "private"
      security_list_keys            = ["nsg_only"]
      include_default_security_list = false
      prohibit_public_ip_on_vnic    = true
      prohibit_internet_ingress     = true
    }
  }
}
