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
  default     = "fk-basedb-03"
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
  description = "Database SYS password supplied securely, shared by primary and standby."
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
  description = "ECPUs per primary and standby system, in multiples of 4."
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

variable "standby_availability_domain" {
  description = "Optional standby AD override; defaults to the first discovered AD in the standby region."
  type        = string
  default     = null
}

variable "standby_region" {
  description = "A second subscribed OCI region; must differ from primary_region."
  type        = string
  default     = "eu-amsterdam-1"
  validation {
    condition     = var.standby_region != var.primary_region
    error_message = "Cross-region Data Guard requires two different OCI regions."
  }
}
