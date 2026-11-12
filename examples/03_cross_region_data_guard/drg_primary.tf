# Based on the FoggyKitchen Landing Zone Orchestrator drg_cross_region pattern.
module "drg_primary" {
  source           = "git::https://github.com/foggykitchen/terraform-oci-fk-drg.git?ref=v0.4.1"
  providers        = { oci = oci }
  compartment_ocid = module.compartment.compartment_id
  name             = "${var.name_prefix}-primary-drg"
  vcn_attachments  = { database = { vcn_id = module.network_primary.vcn_id, drg_route_table_key = "from-vcn" } }
  remote_peering_connections = {
    peer = {
      display_name = "${var.name_prefix}-primary-rpc"
    }
  }
  drg_route_tables = {
    from-vcn = {
      route_rules = [{ destination = local.standby_vcn_cidr, next_hop_rpc_attachment_management_key = "peer" }]
    }
    from-rpc = {
      route_rules = [{ destination = local.primary_vcn_cidr, next_hop_attachment_key = "database" }]
    }
  }
  rpc_attachment_managements = {
    peer = { rpc_key = "peer", drg_route_table_key = "from-rpc" }
  }
}
