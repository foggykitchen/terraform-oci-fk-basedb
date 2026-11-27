locals {
  primary_vcn_cidr    = "10.40.0.0/16"
  primary_client_cidr = "10.40.0.0/24"
  primary_db_cidr     = "10.40.1.0/24"
  primary_ad          = coalesce(var.primary_availability_domain, data.oci_identity_availability_domains.primary.availability_domains[0].name)
}
