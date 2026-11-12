locals {
  primary_vcn_cidr     = "10.30.0.0/16"
  primary_bastion_cidr = "10.30.0.0/24"
  primary_db_cidr      = "10.30.1.0/24"
  primary_ad           = coalesce(var.primary_availability_domain, data.oci_identity_availability_domains.primary.availability_domains[0].name)
}
locals {
  standby_ad = coalesce(var.standby_availability_domain, data.oci_identity_availability_domains.primary.availability_domains[(index([for ad in data.oci_identity_availability_domains.primary.availability_domains : ad.name], local.primary_ad) + 1) % length(data.oci_identity_availability_domains.primary.availability_domains)].name)
}
