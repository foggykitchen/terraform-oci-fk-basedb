terraform {
  required_version = ">= 1.11.0"
  required_providers {
    tls = { source = "hashicorp/tls", version = "~> 4.0" }
    oci = { source = "oracle/oci", version = ">= 9.12.1, < 10.0.0" }
  }
}
