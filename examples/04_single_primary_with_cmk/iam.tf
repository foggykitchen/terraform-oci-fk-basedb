module "vault_group" {
  source    = "git::https://github.com/foggykitchen/terraform-oci-fk-policy.git?ref=v0.2.0"
  providers = { oci = oci.home }

  enabled      = var.create_vault_iam
  tenancy_ocid = var.tenancy_ocid
  dynamic_group = {
    name          = "${var.name_prefix}-cmk-dg"
    description   = "BaseDB CMK access for the dedicated example compartment"
    matching_rule = "ALL {resource.compartment.id = '${module.compartment.compartment_id}'}"
  }
}

# The policy module does not order its own group and policy resources.
# Referencing the group OCID across module instances establishes that ordering.
module "vault_iam" {
  source       = "git::https://github.com/foggykitchen/terraform-oci-fk-policy.git?ref=v0.2.0"
  providers    = { oci = oci.home }
  enabled      = var.create_vault_iam
  tenancy_ocid = var.tenancy_ocid
  policies = var.create_vault_iam ? [{
    name        = "${var.name_prefix}-cmk-policy"
    description = "Access to the selected existing Vault and BaseDB TDE key only"
    statements = [
      "Allow dynamic-group id ${module.vault_group.dynamic_group_id} to use vaults in compartment id ${data.oci_kms_vault.existing.compartment_id} where target.vault.id = '${var.vault_id}'",
      "Allow dynamic-group id ${module.vault_group.dynamic_group_id} to manage keys in compartment id ${data.oci_kms_key.existing.compartment_id} where target.key.id = '${var.kms_key_id}'",
    ]
  }] : []
}

# Preserve the dynamic group from deployments made before the ordering correction.
moved {
  from = module.vault_iam.oci_identity_dynamic_group.this[0]
  to   = module.vault_group.oci_identity_dynamic_group.this[0]
}
