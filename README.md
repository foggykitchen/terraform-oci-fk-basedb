# terraform-oci-fk-basedb

Reusable **Terraform/OpenTofu module** for **Oracle Base Database Service (BaseDB)** VM systems, including a primary database and a new Data Guard standby. Part of the [FoggyKitchen.com](https://foggykitchen.com/) training ecosystem.

---

## 🎯 Purpose

One module instance owns one creation path: `PRIMARY` creates a DB system with DB Home, database and PDB; `STANDBY` creates a Data Guard association with `creation_type = "NewDbSystem"`, which provisions the standby system. Compose two instances for Data Guard. Autonomous Database, ExaCS and Exascale belong to separate modules.

## ✨ Features and Scope

- Private BaseDB VM deployment with explicit AD, shape, OCPUs, node count, storage, edition and licensing.
- Caller-provided subnet, NSGs, SSH public keys, password and database version.
- Same-region and cross-region Data Guard with maximum performance / asynchronous redo transport.
- Target database ID, DB Home ID, private node IPs, connection strings and association IDs.
- Optional automatic primary backups and DB-system tags.

Networking, IAM, secret generation, DNS, backup routing and guest provisioning remain caller responsibilities. This initial version supports new VM systems, not restore/clone, ExistingDbSystem, switchover/failover orchestration or Exadata. OCI decides supported shape/version/edition combinations. The module supports ECPU through compute_model/compute_count and preserves the legacy OCPU contract through cpu_core_count.

---

## 📂 Repository Structure

```text
dbsystem.tf         Primary DB system, DB Home and database
dataguard.tf        Standby creation through Data Guard association
standby_cleanup.tf  Optional destroy-time cleanup metadata and hook
scripts/            Opt-in target-region cleanup script
locals.tf           Shared role and target ID selection
variables.tf        Typed inputs and validation
outputs.tf          Common target database outputs
datasources.tf      Target-region database and node discovery
versions.tf         Provider requirements and alias contract
examples/           Primary, same-region and cross-region examples
SUPPORT.md          FoggyKitchen support policy
LICENSE             UPL 1.0
```

## 🚀 Usage

The examples create their full network and access infrastructure with pinned FoggyKitchen compartment, VCN, NSG and compute modules. The cross-region example adds two DRG/RPC stacks based on the FoggyKitchen landing zone pattern. Supply tenancy/parent context and credentials; no pre-existing deployment subnet IDs are needed. Examples require OpenTofu >= 1.11.

See [single primary](examples/01_single_primary/), [same-region Data Guard](examples/02_same_region_data_guard/), [cross-region Data Guard](examples/03_cross_region_data_guard/) and [single primary with an existing CMK](examples/04_single_primary_with_cmk/).

```hcl
module "primary" {
  source = "./terraform-oci-fk-basedb"
  providers = { oci = oci, oci.target = oci }
  compartment_id = var.compartment_id
  availability_domain = var.primary_ad
  subnet_id = var.primary_subnet_id
  display_name = "FoggyKitchenPrimary"
  hostname = "fkprimary"
  database_name = "FOGGYDB"
  database_version = var.database_version
  database_edition = "ENTERPRISE_EDITION_EXTREME_PERFORMANCE"
  ssh_public_keys = var.ssh_public_keys
  admin_password = var.admin_password
}

module "standby" {
  source = "./terraform-oci-fk-basedb"
  providers = { oci = oci, oci.target = oci.standby }
  role = "STANDBY"
  primary_database_id = module.primary.database_id
  compartment_id = var.compartment_id
  availability_domain = var.standby_ad
  subnet_id = var.standby_subnet_id
  display_name = "FoggyKitchenStandby"
  hostname = "fkstandby"
  admin_password = var.admin_password
}
```

Configure `oci` for the primary region and `oci.standby` for the destination region in the caller. Always map both provider slots. For single-region usage map both slots to the same provider. Modules contain no credentials or provider configurations. Consumers should pin a published Git tag. Repository examples use local sources to exercise this checkout.

## 🌐 Provider and Lifecycle Semantics

`oci` creates either the primary or the association in the primary region. `oci.target` reads the database and node VNICs in the region containing this module instance's DB system. For cross-region standby, mapping both providers to the destination would send the association request to the wrong region.

A standby inherits the primary database definition, SSH keys and compartment. Supply the matching primary compartment and node count for target discovery. Standby primary-only settings such as storage size, database edition and backup options are not applied. Configure Data Guard prerequisites and licensed edition on the primary. `is_active_data_guard_enabled` defaults to false.

`role` selects resource ownership at creation; changing it replaces the resource path and is not a Data Guard role transition. After an operational switchover/failover, inspect the associations and state before planning. `data_guard_role` reports the association peer role; a standalone primary instance has no association to inspect and returns null.

## Destroying a Data Guard standby

OCI provider 9.x requires `delete_standby_db_home_on_delete = true` in state. For `creation_type = "NewDbSystem"`, its [Delete implementation](https://github.com/oracle/terraform-provider-oci/blob/v9.12.1/internal/service/database/database_data_guard_association_resource.go#L924-L1010) attempts to terminate the standby **DB system**, not just its DB Home. However, it uses the association's client in the primary region, without switching to the peer region. The same implementation is present in 9.12.1, 9.13.0 and 9.14.0. The generic [missing-resource handler](https://github.com/oracle/terraform-provider-oci/blob/v9.12.1/internal/tfresource/errors.go#L187-L227) can clear state on a 404 from this path. See the historical cross-region report [oracle/terraform-provider-oci#1089](https://github.com/oracle/terraform-provider-oci/issues/1089). This explains a provider-level failure mechanism consistent with the observed orphan; the exact HTTP response from the recorded deployments was not captured.

The module already supplies `true`. This flag is a delete-time guard, not a create-time OCI option. It does not have to originate at creation, but a change must be persisted by an approved apply before destruction; editing configuration immediately before destroy does not update state. See the [provider 9.12.1 deletion documentation](https://github.com/oracle/terraform-provider-oci/blob/v9.12.1/website/docs/r/database_data_guard_association.html.markdown). Keep the flag true and verify the actual standby lifecycle.

Use this recovery sequence for an approved cleanup:

1. **Record IDs before destroy:** save `standby_db_system_id`, `standby_region_hint`, database and association IDs, compartment, names and current database roles outside the state file. Re-export the module outputs from your root configuration. The region hint is supplied by the caller and must match `oci.target`; it is not provider discovery. Decide backup retention before termination.
2. Review a destroy plan and run the approved destroy. Association removal from state does not prove that the standby was deleted.
3. If the standby remains `AVAILABLE`, verify its exact OCID, region and current STANDBY role, then terminate it explicitly in that region using the approved OCI identity:

   ```sh
   # Set these from the verified pre-destroy inventory, not from a name search.
   oci db system terminate --db-system-id "$STANDBY_DB_SYSTEM_ID" \
     --region "$STANDBY_REGION" --force \
     --wait-for-state SUCCEEDED --max-wait-seconds 7200
   oci db system get --db-system-id "$STANDBY_DB_SYSTEM_ID" \
     --region "$STANDBY_REGION" --query 'data."lifecycle-state"' --raw-output
   ```

4. Wait for the **DB system** to reach `TERMINATED`, repeating the read if necessary. The [CLI terminate waiter](https://docs.oracle.com/en-us/iaas/tools/oci-cli/latest/oci_cli_docs/cmdref/db/system/terminate.html) waits on a work request (`SUCCEEDED`), not a system lifecycle (`TERMINATED`). Do not interpret authorization errors or a wrong-region 404 as proof of deletion.
5. Generate and review a **fresh destroy plan** for the remaining infrastructure, then complete the approved cleanup. Verify the final inventory in both regions. Never remove state entries to hide surviving resources.

### Optional CLI cleanup

`standby_cleanup` is disabled by default. It can automate target-region termination **before** association destruction:

```hcl
# Add to the STANDBY module call; preserve oci in the primary region.
standby_region_hint = "eu-amsterdam-1" # Must match the caller's oci.target configuration.
standby_cleanup = {
  enabled         = true
  oci_cli_profile = null # Use the runner's default OCI CLI authentication, or a named profile.
}
```

The runner needs Bash and OCI CLI on PATH, configured authentication and permissions to read the target system/association and terminate the target system. Provider credentials are not automatically passed to the CLI. This hook deletes the entire peer DB system and its data. It checks the current peer role and refuses to terminate a peer that is now PRIMARY after switchover/failover.

A `terraform_data.standby_cleanup` metadata resource is present only for STANDBY. With cleanup disabled its hook exits without calling OCI CLI. Keeping this metadata resource when disabling cleanup avoids terminating a system merely because the option changes from true to false. Inputs, including the script, are saved in state; enabling/disabling or changing the profile/region requires an approved state update before destroy. An old v0.1.0 state has no hook until that update is applied. A destroy-only run cannot retrofit it. No OCI resource addresses are changed.

The dependency on the association orders this hook before association, primary and dependent network destruction. It resumes waiting for a `TERMINATING` system and accepts an explicitly observed `TERMINATED` system. Work-request waiting and lifecycle polling each have a two-hour limit. Every CLI error (including 404), unexpected role/state and timeout fails the destroy; errors are never ignored. Investigate permissions, region and the actual inventory before retrying. Do not remove the module block, taint the helper or use `create_before_destroy` to bypass a destroy provisioner. Replacing the helper or its peer system can also invoke cleanup, so review replacement plans carefully. This opt-in path has static and stub-CLI validation only; no live cleanup was performed for v0.2.0.

## Customer-managed encryption keys

See [example 04](examples/04_single_primary_with_cmk/) for a complete deployment with private compute and OCI Bastion Service consuming an existing Vault and key, following the ADB Vault lesson without importing shared resources into the lab state.

For PRIMARY, set both `kms_key_id` and `vault_id`, or leave both null for Oracle-managed encryption. Optional `kms_key_version_id` selects a CDB key version; it requires the pair. These map to `db_home.database` fields verified in the [provider 9.12.1 schema](https://github.com/oracle/terraform-provider-oci/blob/v9.12.1/internal/service/database/database_db_system_resource.go#L272-L335). They are creation-time (`ForceNew`) fields: changing them can replace an existing system. This interface is not an in-place key migration/rotation workflow.

Use an AES-256 key from [terraform-oci-fk-vault v0.2.0](https://github.com/foggykitchen/terraform-oci-fk-vault/tree/v0.2.0): set `kms_key_id = module.vault.key_ids["primary"]` and `vault_id = module.vault.vault_id` in the PRIMARY module call. Before provisioning, configure the DB-node dynamic group and key-management policies described in [BaseDB Required IAM Policy](https://docs.oracle.com/en/cloud/paas/base-database/guide/key-about.html) and [Vault key assignment IAM requirements](https://docs.oracle.com/en-us/iaas/Content/KeyManagement/Tasks/assigningkeys.htm). The Vault module creates keys; it does not establish BaseDB IAM or cross-region replication for you.

Do not set these PRIMARY-only inputs on STANDBY. The Data Guard association schema exposes no target `kms_key_id` or `vault_id` argument. OCI uses the primary's key in the same region, and its replicated key in the standby region for cross-region Data Guard. Establish Vault/key replication and IAM **before** creating the standby; a new unrelated target key is not a substitute. See Oracle's [cross-region BaseDB/Vault procedure](https://docs.oracle.com/en/learn/basedb-dataguard-with-ocivault/index.html) and the newer [virtual vault support announcement](https://docs.oracle.com/en-us/iaas/releasenotes/database/basedb-cross-region-dg-virtual-vault.htm). The module rejects explicit CMK inputs on STANDBY, but does not claim to validate replication readiness. The API has no target-key argument to enforce with a target-key precondition. CMK deployment has not been live-tested for this release.

## 📋 Requirements

OpenTofu >= 1.11.0, OCI provider >= 9.12.1 and < 10.0.0, valid OCI authentication, IAM and BaseDB quotas. The root module has been validated with OCI 9.12.1. The examples pin provider-compatible releases: VCN v0.3.0, compartment v0.2.0 and DRG v0.5.0. The v0.1.0 examples were verified separately; the updated pins passed backend-disabled initialization and validation with OCI 9.14.0. BaseDB provisioning and deletion may take significant time. No live apply is performed by repository validation.

The SYS password is required and sensitive; it has no default. Supply it securely at runtime. It can still be present in state and saved plans. Keep these artifacts private. Use existing [VCN](https://github.com/foggykitchen/terraform-oci-fk-vcn) and [NSG](https://github.com/foggykitchen/terraform-oci-fk-nsg) modules for network composition.

---


### Current BaseDB provisioning boundary

The examples use VM.BaseDB.x86 with 4 ECPUs per DB system. ECPU primary systems explicitly use LVM storage. Data Guard examples use Enterprise Edition. Review the runtime results and cleanup limitations in each example; configuration validation does not establish regional capacity or CMK readiness.

## 📥 Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `role` | `string` | `"PRIMARY"` | Creation mode: PRIMARY creates a BaseDB system; STANDBY creates a new system through Data Guard. This is not a switchover control. |
| `compartment_id` | `string` | required | OCID of the compartment containing the DB system (standby inherits the primary compartment). |
| `availability_domain` | `string` | required | Availability domain for the new primary or standby DB system. |
| `subnet_id` | `string` | required | OCID of the private subnet in the destination region. |
| `display_name` | `string` | required | Display name for the DB system. |
| `hostname` | `string` | required | Host name for the new DB system. |
| `shape` | `string` | `"VM.Standard.E4.Flex"` | Base Database VM shape; verify regional availability and edition compatibility. |
| `compute_model` | `string` | `"OCPU"` | Set ECPU with VM.BaseDB.x86; default preserves legacy callers. |
| `compute_count` | `number` | `null` | Required ECPU count, at least 4 in multiples of 4. Null for OCPU. |
| `cpu_core_count` | `number` | `1` | Legacy OCPU count; ignored in ECPU mode. |
| `node_count` | `number` | `1` | Number of nodes. Must match the actual target system; two-node RAC requires a supported edition and shape. |
| `domain` | `string` | `null` | Optional database host domain. Null lets OCI use the subnet DNS domain. |
| `nsg_ids` | `list(string)` | `[]` | NSG OCIDs in the destination VCN. Networking and Data Guard connectivity are managed by the caller. |
| `ssh_public_keys` | `list(string)` | `[]` | SSH public keys for PRIMARY. STANDBY inherits keys through the Data Guard API. |
| `admin_password` | `string` | required | SYS administrator password. For STANDBY supply the primary database password. Stored in state; protect state. |
| `database_name` | `string` | `null` | Database name, required for PRIMARY. |
| `database_version` | `string` | `null` | Explicit region-supported database version, required for PRIMARY. |
| `pdb_name` | `string` | `"FKPDB1"` | PDB name for PRIMARY. |
| `db_home_display_name` | `string` | `null` | Optional DB Home display name for PRIMARY. |
| `database_edition` | `string` | `"STANDARD_EDITION"` | Edition for PRIMARY. Data Guard requires a supported Enterprise Edition; standby inherits the primary edition. |
| `character_set` | `string` | `"AL32UTF8"` | Database character set for PRIMARY. |
| `ncharacter_set` | `string` | `"AL16UTF16"` | National character set for PRIMARY. |
| `database_workload` | `string` | `"OLTP"` | Database workload for PRIMARY: OLTP or DSS. |
| `data_storage_size_in_gb` | `number` | `256` | Primary data storage size in GB. Standby storage is provisioned by Data Guard. |
| `data_storage_percentage` | `number` | `40` | Primary data storage percentage. |
| `disk_redundancy` | `string` | `"HIGH"` | Primary disk redundancy. |
| `license_model` | `string` | `"LICENSE_INCLUDED"` | License model for the new DB system; confirm entitlement before selecting BYOL. |
| `auto_backup_enabled` | `bool` | `false` | Enable automatic database backups for PRIMARY; configure network access required by OCI backups. |
| `primary_database_id` | `string` | `null` | Source primary database OCID, required only for STANDBY. |
| `protection_mode` | `string` | `"MAXIMUM_PERFORMANCE"` | Data Guard protection mode. Initial scope supports MAXIMUM_PERFORMANCE with ASYNC. |
| `transport_type` | `string` | `"ASYNC"` | Data Guard redo transport. Initial scope supports ASYNC. |
| `is_active_data_guard_enabled` | `bool` | `false` | Enable licensed Active Data Guard for STANDBY when supported by the primary edition. |
| `delete_standby_db_home_on_delete` | `bool` | `true` | Destroy behavior for the association: OCI 9.x requires true in state; cross-region standby termination is not guaranteed. |
| `fault_domains` | `list(string)` | `null` | Optional fault domains for the new DB system. |
| `freeform_tags` | `map(string)` | `{}` | Free-form tags on the new DB system. |
| `defined_tags` | `map(string)` | `{}` | Defined tags on the new DB system; namespaces must exist. |
| `kms_key_id` | `string` | `null` | PRIMARY TDE master key OCID; set with vault_id. |
| `vault_id` | `string` | `null` | PRIMARY Vault OCID containing the key. |
| `kms_key_version_id` | `string` | `null` | Optional PRIMARY CDB key version; requires the key/vault pair. |
| `standby_region_hint` | `string` | `null` | Caller-supplied target region for inventory and optional cleanup. |
| `standby_cleanup` | `object` | `{ enabled = false, oci_cli_profile = null }` | Opt-in target-region CLI cleanup; see lifecycle caveats above. |

## 📤 Outputs

| Output | Description |
|---|---|
| `db_system_id` | DB system OCID of this primary or standby. |
| `database_id` | Database OCID of this primary or standby, never the source database for standby. |
| `db_home_id` | DB Home OCID of this primary or standby. |
| `private_ips` | Private IP addresses of the target DB system nodes; ordering follows the OCI node list. |
| `connection_strings` | Connection strings reported for the target database; a standby may have restricted access. |
| `state` | Target database lifecycle state. |
| `data_guard_association_id` | Source-side Data Guard association OCID; null for PRIMARY. |
| `peer_data_guard_association_id` | Target-side Data Guard association OCID; null for PRIMARY. |
| `data_guard_role` | Observed role of the standby-side peer. Null when this module does not manage an association. |
| `standby_db_system_id` | Association peer DB system OCID for inventory; null for PRIMARY. |
| `standby_region_hint` | Caller-supplied standby region, null for PRIMARY or when omitted. |

## ✅ Validation

```sh
tofu fmt -recursive -check
tofu init -backend=false
tofu validate
```

Root module validation with OCI provider **9.12.1** passed. Example 01 was subsequently deployed successfully on 2026-11-09 with 26ai 23.26.4.0.0, VM.BaseDB.x86, 4 ECPUs and LVM. Both DB system and database reached AVAILABLE; private listener connectivity, SSH and local SQL*Plus checks passed. FOGGYDB and FKPDB1 are READ WRITE. See the example README for details and limitations.


## 🆘 Support

See [SUPPORT.md](SUPPORT.md). Contributions should include sanitized reproduction steps and relevant validation results.

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**. See [LICENSE](LICENSE).

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.

