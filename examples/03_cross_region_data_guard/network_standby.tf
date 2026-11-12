module "network_standby" {
  source                   = "git::https://github.com/foggykitchen/terraform-oci-fk-vcn.git?ref=v0.2.1"
  providers                = { oci = oci.standby }
  compartment_ocid         = module.compartment.compartment_id
  name                     = "${var.name_prefix}-standby-vcn"
  dns_label                = "fkstandby"
  vcn_cidr_blocks          = [local.standby_vcn_cidr]
  create_internet_gateway  = true
  create_nat_gateway       = true
  create_service_gateway   = true
  extra_network_entity_ids = { drg = module.drg_standby.drg_id }
  security_lists = {
    nsg_only = { display_name = "NSG-only", ingress_rules = [], egress_rules = [] }
  }
  route_tables = {
    public = {
      route_rules = [
        { destination = "0.0.0.0/0", network_entity_key = "internet_gateway" },
        { destination = local.primary_vcn_cidr, network_entity_key = "drg" }
      ]
    }
    private = {
      route_rules = [
        { destination = "0.0.0.0/0", network_entity_key = "nat_gateway" },
        { destination = "all-services", destination_type = "SERVICE_CIDR_BLOCK", network_entity_key = "service_gateway" },
        { destination = local.primary_vcn_cidr, network_entity_key = "drg" },
      ]
    }
  }
  subnets = {
    bastion = {
      cidr_block                    = local.standby_bastion_cidr
      display_name                  = "fk-bastion-subnet-public"
      dns_label                     = "bastion"
      route_table_key               = "public"
      security_list_keys            = ["nsg_only"]
      include_default_security_list = false
      prohibit_public_ip_on_vnic    = false
      prohibit_internet_ingress     = false
    }
    database = {
      cidr_block                    = local.standby_db_cidr
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
