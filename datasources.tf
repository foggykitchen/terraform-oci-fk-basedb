# Target-region reads are separate from the primary-region Data Guard API call.
data "oci_database_database" "this" {
  provider    = oci.target
  database_id = local.database_id
}
data "oci_database_db_nodes" "this" {
  provider       = oci.target
  compartment_id = var.compartment_id
  db_system_id   = local.db_system_id
  lifecycle {
    postcondition {
      condition     = length(self.db_nodes) == var.node_count
      error_message = "Target node discovery does not match node_count. Verify the target provider region, compartment and expected node count."
    }
  }
}
data "oci_core_vnic" "this" {
  provider = oci.target
  count    = var.node_count
  vnic_id  = data.oci_database_db_nodes.this.db_nodes[count.index].vnic_id
}
