variable "tenancy_ocid" {
  description = "Tenancy OCID for AD and home-region discovery."
  type        = string
}
variable "parent_compartment_id" {
  description = "Existing parent compartment or tenancy OCID; a child compartment is created by this example."
  type        = string
}
variable "name_prefix" {
  description = "Unique resource name prefix and child compartment name."
  type        = string
  default     = "fk-basedb-04"
}
variable "primary_region" {
  description = "Region in which the primary is created."
  type        = string
  default     = "eu-frankfurt-1"
}
variable "primary_availability_domain" {
  description = "Optional primary AD override; defaults to the first discovered AD."
  type        = string
  default     = null
}
variable "admin_cidr" {
  description = "Trusted public IPv4 CIDR allowed to SSH to the bastion, for example your public IP /32."
  type        = string
  validation {
    condition     = can(cidrhost(var.admin_cidr, 0)) && can(regex("^[0-9.]+/[0-9]+$", var.admin_cidr)) && try(tonumber(split("/", var.admin_cidr)[1]) > 0, false)
    error_message = "admin_cidr must be a valid trusted IPv4 CIDR; public 0.0.0.0/0 SSH is not allowed."
  }
}
variable "database_version" {
  description = "Explicit BaseDB version supported by the selected region(s), edition and shape."
  type        = string
}
variable "admin_password" {
  description = "Database SYS password supplied securely; no Vault secret is read by this example."
  type        = string
  sensitive   = true
}
variable "ssh_public_keys" {
  description = "Existing SSH public keys; an empty list generates a lab key stored in state."
  type        = list(string)
  default     = []
}

variable "user_ocid" {
  type    = string
  default = null
}
variable "fingerprint" {
  type    = string
  default = null
}
variable "private_key_path" {
  type    = string
  default = null
}
variable "database_shape" {
  description = "BaseDB VM shape supported in the selected region(s)."
  type        = string
  default     = "VM.BaseDB.x86"
}
variable "database_ecpus" {
  description = "ECPUs for the BaseDB system, in multiples of 4."
  type        = number
  default     = 4
}
variable "database_storage_gb" {
  description = "Primary data storage GB; standby storage is created by Data Guard."
  type        = number
  default     = 256
}
variable "license_model" {
  description = "Oracle database license model; review costs and BYOL entitlement."
  type        = string
  default     = "LICENSE_INCLUDED"
}

variable "vault_id" {
  description = "Existing Vault OCID in primary_region. Read only; never imported or destroyed by this example."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^ocid1\\.vault\\.", var.vault_id))
    error_message = "vault_id must be an OCI Vault OCID."
  }
}

variable "kms_key_id" {
  description = "Existing enabled AES-256 master key OCID in vault_id. A secret OCID is not a KMS key."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^ocid1\\.key\\.", var.kms_key_id))
    error_message = "kms_key_id must be an OCI KMS key OCID."
  }
}

variable "kms_key_version_id" {
  description = "Optional existing key version for the CDB. Null lets OCI choose the current version. Not a rotation input."
  type        = string
  default     = null
}

variable "create_vault_iam" {
  description = "Create a lab-owned dynamic group and scoped key policy. False requires equivalent pre-existing IAM; it does not adopt or alter existing policies."
  type        = bool
  default     = true
  nullable    = false
}
