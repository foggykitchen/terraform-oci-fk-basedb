# Read existing metadata only. No Vault, key, key version or secret is owned here.
data "oci_kms_vault" "existing" {
  vault_id = var.vault_id
  lifecycle {
    postcondition {
      condition     = self.state == "ACTIVE"
      error_message = "The existing Vault must be ACTIVE in primary_region."
    }
  }
}

data "oci_kms_key" "existing" {
  key_id              = var.kms_key_id
  management_endpoint = data.oci_kms_vault.existing.management_endpoint
  lifecycle {
    postcondition {
      condition     = self.vault_id == var.vault_id && self.state == "ENABLED"
      error_message = "The key must be ENABLED and belong to the supplied Vault."
    }
    postcondition {
      condition     = self.key_shape[0].algorithm == "AES" && self.key_shape[0].length == 32 && contains(["HSM", "SOFTWARE"], self.protection_mode)
      error_message = "This example requires an AES-256 key with HSM or SOFTWARE protection."
    }
  }
}
