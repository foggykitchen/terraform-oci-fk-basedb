# Based on the FoggyKitchen Landing Zone Orchestrator drg_cross_region pattern.
module "drg_standby" {
  source           = "git::https://github.com/foggykitchen/terraform-oci-fk-drg.git?ref=v0.4.1"
  providers        = { oci = oci.standby }
  compartment_ocid = module.compartment.compartment_id
  name             = "${var.name_prefix}-standby-drg"
  vcn_attachments  = { database = { vcn_id = module.network_standby.vcn_id, drg_route_table_key = "from-vcn" } }
  remote_peering_connections = {
    peer = {
      display_name     = "${var.name_prefix}-standby-rpc"
      peer_id          = module.drg_primary.remote_peering_connection_ids["peer"]
      peer_region_name = var.primary_region
    }
  }
  drg_route_tables = {
    from-vcn = {
      route_rules = [{ destination = local.primary_vcn_cidr, next_hop_rpc_attachment_management_key = "peer" }]
    }
    from-rpc = {
      route_rules = [{ destination = local.standby_vcn_cidr, next_hop_attachment_key = "database" }]
    }
  }
  rpc_attachment_managements = {
    peer = { rpc_key = "peer", drg_route_table_key = "from-rpc" }
  }
}
