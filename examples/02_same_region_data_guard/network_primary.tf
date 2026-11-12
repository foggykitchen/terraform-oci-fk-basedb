module "network_primary" {
  source                  = "git::https://github.com/foggykitchen/terraform-oci-fk-vcn.git?ref=v0.2.1"
  providers               = { oci = oci }
  compartment_ocid        = module.compartment.compartment_id
  name                    = "${var.name_prefix}-primary-vcn"
  dns_label               = "fkprimary"
  vcn_cidr_blocks         = [local.primary_vcn_cidr]
  create_internet_gateway = true
  create_nat_gateway      = true
  create_service_gateway  = true
  security_lists = {
    nsg_only = { display_name = "NSG-only", ingress_rules = [], egress_rules = [] }
  }
  route_tables = {
    public = {
      route_rules = [{ destination = "0.0.0.0/0", network_entity_key = "internet_gateway" }]
    }
    private = {
      route_rules = [
        { destination = "0.0.0.0/0", network_entity_key = "nat_gateway" },
        { destination = "all-services", destination_type = "SERVICE_CIDR_BLOCK", network_entity_key = "service_gateway" },
      ]
    }
  }
  subnets = {
    bastion = {
      cidr_block                    = local.primary_bastion_cidr
      display_name                  = "fk-bastion-subnet-public"
      dns_label                     = "bastion"
      route_table_key               = "public"
      security_list_keys            = ["nsg_only"]
      include_default_security_list = false
      prohibit_public_ip_on_vnic    = false
      prohibit_internet_ingress     = false
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
