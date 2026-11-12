locals {
  primary_vcn_cidr     = "10.30.0.0/16"
  primary_bastion_cidr = "10.30.0.0/24"
  primary_db_cidr      = "10.30.1.0/24"
  primary_ad           = coalesce(var.primary_availability_domain, data.oci_identity_availability_domains.primary.availability_domains[0].name)
}
locals {
  standby_ad = coalesce(var.standby_availability_domain, data.oci_identity_availability_domains.standby.availability_domains[0].name)
}
locals {
  standby_vcn_cidr     = "10.40.0.0/16"
  standby_bastion_cidr = "10.40.0.0/24"
  standby_db_cidr      = "10.40.1.0/24"
}
