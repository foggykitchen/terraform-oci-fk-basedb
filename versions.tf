terraform {
  required_version = ">= 1.8.0"
  required_providers {
    oci = {
      source                = "oracle/oci"
      version               = ">= 9.12.1, < 10.0.0"
      configuration_aliases = [oci.target]
    }
  }
}
