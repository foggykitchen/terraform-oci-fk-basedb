data "oci_identity_region_subscriptions" "this" {
  tenancy_id = var.tenancy_ocid
  filter {
    name   = "is_home_region"
    values = [true]
  }
}
data "oci_identity_availability_domains" "primary" { compartment_id = var.tenancy_ocid }
data "oci_identity_availability_domains" "standby" {
  provider       = oci.standby
  compartment_id = var.tenancy_ocid
}
