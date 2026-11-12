variable "role" {
  description = "Creation mode: PRIMARY creates a BaseDB system; STANDBY creates a new system through Data Guard. This is not a switchover control."
  type        = string
  default     = "PRIMARY"
  nullable    = false
  validation {
    condition     = contains(["PRIMARY", "STANDBY"], var.role)
    error_message = "role must be PRIMARY or STANDBY."
  }
}

variable "compartment_id" {
  description = "OCID of the compartment containing the DB system (standby inherits the primary compartment)."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^ocid1\\.compartment\\.", var.compartment_id))
    error_message = "compartment_id must be a compartment OCID."
  }
}

variable "availability_domain" {
  description = "Availability domain for the new primary or standby DB system."
  type        = string
  nullable    = false
  validation {
    condition     = length(trimspace(var.availability_domain)) > 0
    error_message = "availability_domain must not be empty."
  }
}

variable "subnet_id" {
  description = "OCID of the private subnet in the destination region."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^ocid1\\.subnet\\.", var.subnet_id))
    error_message = "subnet_id must be a subnet OCID."
  }
}

variable "display_name" {
  description = "Display name for the DB system."
  type        = string
  nullable    = false
  validation {
    condition     = length(trimspace(var.display_name)) > 0
    error_message = "display_name must not be empty."
  }
}

variable "hostname" {
  description = "Host name for the new DB system."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9-]{0,62}$", var.hostname))
    error_message = "hostname must begin with a letter and contain at most 63 letters, numbers or hyphens."
  }
}

variable "shape" {
  description = "Base Database VM shape; verify regional availability and edition compatibility."
  type        = string
  default     = "VM.Standard.E4.Flex"
  nullable    = false
  validation {
    condition     = startswith(var.shape, "VM.")
    error_message = "This module supports BaseDB VM systems; Exadata and Exascale are outside its scope."
  }
}

variable "compute_model" {
  description = "ECPU for VM.BaseDB.x86; OCPU preserves the legacy cpu_core_count contract."
  type        = string
  default     = "OCPU"
  nullable    = false
  validation {
    condition     = contains(["OCPU", "ECPU"], var.compute_model)
    error_message = "compute_model must be OCPU or ECPU."
  }
}

variable "compute_count" {
  description = "ECPU count for VM.BaseDB.x86; required for ECPU, null for OCPU."
  type        = number
  default     = null
}

variable "cpu_core_count" {
  description = "Legacy OCPU count; ignored for ECPU. Verify supported values for the selected shape and edition."
  type        = number
  default     = 1
  nullable    = false
  validation {
    condition     = var.cpu_core_count > 0 && floor(var.cpu_core_count) == var.cpu_core_count
    error_message = "cpu_core_count must be a positive integer."
  }
}

variable "node_count" {
  description = "Number of nodes. Must match the actual target system; two-node RAC requires a supported edition and shape."
  type        = number
  default     = 1
  nullable    = false
  validation {
    condition     = contains([1, 2], var.node_count)
    error_message = "node_count must be 1 or 2."
  }
}

variable "domain" {
  description = "Optional database host domain. Null lets OCI use the subnet DNS domain."
  type        = string
  default     = null
}

variable "nsg_ids" {
  description = "NSG OCIDs in the destination VCN. Networking and Data Guard connectivity are managed by the caller."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "ssh_public_keys" {
  description = "SSH public keys for PRIMARY. STANDBY inherits keys through the Data Guard API."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "admin_password" {
  description = "SYS administrator password. For STANDBY supply the primary database password. Stored in state; protect state."
  type        = string
  nullable    = false
  sensitive   = true
  validation {
    condition     = length(var.admin_password) >= 12 && length(var.admin_password) <= 30
    error_message = "admin_password must contain 12 to 30 characters; OCI also checks password complexity."
  }
}

variable "database_name" {
  description = "Database name, required for PRIMARY."
  type        = string
  default     = null
  validation {
    condition     = var.database_name == null ? true : can(regex("^[A-Za-z][A-Za-z0-9]{0,7}$", var.database_name))
    error_message = "database_name must start with a letter and contain at most 8 alphanumeric characters."
  }
}

variable "database_version" {
  description = "Explicit region-supported database version, required for PRIMARY."
  type        = string
  default     = null
  validation {
    condition     = var.database_version == null ? true : length(trimspace(var.database_version)) > 0
    error_message = "database_version must not be empty when supplied."
  }
}

variable "pdb_name" {
  description = "PDB name for PRIMARY."
  type        = string
  default     = "FKPDB1"
  nullable    = false
}

variable "db_home_display_name" {
  description = "Optional DB Home display name for PRIMARY."
  type        = string
  default     = null
}

variable "database_edition" {
  description = "Edition for PRIMARY. Data Guard requires a supported Enterprise Edition; standby inherits the primary edition."
  type        = string
  default     = "STANDARD_EDITION"
  nullable    = false
  validation {
    condition     = contains(["STANDARD_EDITION", "ENTERPRISE_EDITION", "ENTERPRISE_EDITION_HIGH_PERFORMANCE", "ENTERPRISE_EDITION_EXTREME_PERFORMANCE"], var.database_edition)
    error_message = "database_edition must be a supported BaseDB edition."
  }
}

variable "character_set" {
  description = "Database character set for PRIMARY."
  type        = string
  default     = "AL32UTF8"
  nullable    = false
}

variable "ncharacter_set" {
  description = "National character set for PRIMARY."
  type        = string
  default     = "AL16UTF16"
  nullable    = false
}

variable "database_workload" {
  description = "Database workload for PRIMARY: OLTP or DSS."
  type        = string
  default     = "OLTP"
  nullable    = false
  validation {
    condition     = contains(["OLTP", "DSS"], var.database_workload)
    error_message = "database_workload must be OLTP or DSS."
  }
}

variable "data_storage_size_in_gb" {
  description = "Primary data storage size in GB. Standby storage is provisioned by Data Guard."
  type        = number
  default     = 256
  nullable    = false
  validation {
    condition     = var.data_storage_size_in_gb >= 256 && floor(var.data_storage_size_in_gb) == var.data_storage_size_in_gb
    error_message = "data_storage_size_in_gb must be an integer of at least 256 GB."
  }
}

variable "data_storage_percentage" {
  description = "Primary data storage percentage."
  type        = number
  default     = 40
  nullable    = false
  validation {
    condition     = var.data_storage_percentage > 0 && var.data_storage_percentage < 100
    error_message = "data_storage_percentage must be between 0 and 100, exclusive."
  }
}

variable "disk_redundancy" {
  description = "Primary disk redundancy."
  type        = string
  default     = "HIGH"
  nullable    = false
  validation {
    condition     = contains(["HIGH", "NORMAL"], var.disk_redundancy)
    error_message = "disk_redundancy must be HIGH or NORMAL."
  }
}

variable "license_model" {
  description = "License model for the new DB system; confirm entitlement before selecting BYOL."
  type        = string
  default     = "LICENSE_INCLUDED"
  nullable    = false
  validation {
    condition     = contains(["LICENSE_INCLUDED", "BRING_YOUR_OWN_LICENSE"], var.license_model)
    error_message = "license_model must be LICENSE_INCLUDED or BRING_YOUR_OWN_LICENSE."
  }
}

variable "auto_backup_enabled" {
  description = "Enable automatic database backups for PRIMARY; configure network access required by OCI backups."
  type        = bool
  default     = false
  nullable    = false
}

variable "primary_database_id" {
  description = "Source primary database OCID, required only for STANDBY."
  type        = string
  default     = null
}

variable "protection_mode" {
  description = "Data Guard protection mode. Initial scope supports MAXIMUM_PERFORMANCE with ASYNC."
  type        = string
  default     = "MAXIMUM_PERFORMANCE"
  nullable    = false
  validation {
    condition     = var.protection_mode == "MAXIMUM_PERFORMANCE"
    error_message = "Initial module scope supports MAXIMUM_PERFORMANCE only."
  }
}

variable "transport_type" {
  description = "Data Guard redo transport. Initial scope supports ASYNC."
  type        = string
  default     = "ASYNC"
  nullable    = false
  validation {
    condition     = var.transport_type == "ASYNC"
    error_message = "Initial module scope supports ASYNC only."
  }
}

variable "is_active_data_guard_enabled" {
  description = "Enable licensed Active Data Guard for STANDBY when supported by the primary edition."
  type        = bool
  default     = false
  nullable    = false
}

variable "delete_standby_db_home_on_delete" {
  description = "Destroy behavior for the association. OCI 6.37 supports true only: destroying the association deletes the standby DB Home/system."
  type        = bool
  default     = true
  nullable    = false
  validation {
    condition     = var.delete_standby_db_home_on_delete
    error_message = "OCI supports only delete_standby_db_home_on_delete = true. Destroying the association deletes the standby DB Home/system."
  }
}

variable "fault_domains" {
  description = "Optional fault domains for the new DB system."
  type        = list(string)
  default     = null
}

variable "freeform_tags" {
  description = "Free-form tags on the new DB system."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "defined_tags" {
  description = "Defined tags on the new DB system; namespaces must exist."
  type        = map(string)
  default     = {}
  nullable    = false
}
