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
locals.tf           Shared role and target ID selection
variables.tf        Typed inputs and validation
outputs.tf          Common target database outputs
datasources.tf      Target-region database and node discovery
versions.tf         Provider requirements and alias contract
examples/           Primary, same-region and cross-region examples
tests/              Offline mocked-provider module tests
SUPPORT.md          FoggyKitchen support policy
LICENSE             UPL 1.0
```

## 🚀 Usage

The examples create their full network and access infrastructure with pinned FoggyKitchen compartment, VCN, NSG and compute modules. The cross-region example adds two DRG/RPC stacks based on the FoggyKitchen landing zone pattern. Supply tenancy/parent context and credentials; no pre-existing deployment subnet IDs are needed. Examples require OpenTofu >= 1.11.

See [single primary](examples/01_single_primary/), [same-region Data Guard](examples/02_same_region_data_guard/) and [cross-region Data Guard](examples/03_cross_region_data_guard/).

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

Configure `oci` for the primary region and `oci.standby` for the destination region in the caller. Always map both provider slots. For single-region usage map both slots to the same provider. Modules contain no credentials or provider configurations. Use a published Git tag when one exists; examples use local sources during initial development.

## 🌐 Provider and Lifecycle Semantics

`oci` creates either the primary or the association in the primary region. `oci.target` reads the database and node VNICs in the region containing this module instance's DB system. For cross-region standby, mapping both providers to the destination would send the association request to the wrong region.

A standby inherits the primary database definition, SSH keys and compartment. Supply the matching primary compartment and node count for target discovery. Standby primary-only settings such as storage size, database edition and backup options are not applied. Configure Data Guard prerequisites and licensed edition on the primary. `is_active_data_guard_enabled` defaults to false.

`role` selects resource ownership at creation; changing it replaces the resource path and is not a Data Guard role transition. After an operational switchover/failover, inspect the associations and state before planning. `data_guard_role` reports the association peer role; a standalone primary instance has no association to inspect and returns null.

`delete_standby_db_home_on_delete = true` deletes the standby DB Home/system when destroying the association. [OCI provider 6.37](https://github.com/oracle/terraform-provider-oci/blob/v6.37.0/website/docs/r/database_data_guard_association.html.markdown) documents only `true` as supported; the module rejects `false`. Apply changes to that flag before a later destroy so the provider stores the intended behavior in state. Never assume deleting an association preserves data. For existing deployments, review explicit state moves/imports before replacing raw resources with module calls.

## 📋 Requirements

OpenTofu >= 1.8.0, OCI provider >= 9.12.1 and < 10.0.0, valid OCI authentication, IAM and BaseDB quotas. Offline tests use OpenTofu >= 1.11 with mocked providers. The root module has been validated with OCI 9.12.1. The examples pin provider-compatible releases: VCN v0.2.1, compartment v0.1.1 and DRG v0.4.1. All three examples passed initialization, validation and read-only plans with OCI 9.12.1 on 2026-11-12 without local dependency overrides. No infrastructure was created by these checks. BaseDB provisioning and deletion may take significant time. No live apply is performed by repository validation.

The SYS password is required and sensitive; it has no default. Supply it securely at runtime. It can still be present in state and saved plans. Keep these artifacts private. Use existing [VCN](https://github.com/foggykitchen/terraform-oci-fk-vcn) and [NSG](https://github.com/foggykitchen/terraform-oci-fk-nsg) modules for network composition.

---


### Current BaseDB provisioning boundary

These examples still use the legacy OCPU inputs from the course. Oracle has [announced retirement of OCPU-metered SKUs and Enterprise Edition Extreme Performance for new provisioning](https://docs.oracle.com/en/cloud/paas/base-database/about/index.html), effective July 31, 2026. Confirm which shapes, editions and billing model your tenancy can provision before a live apply. Passing offline tests does not establish availability of this legacy path. Example 01 now uses VM.BaseDB.x86 with 4 ECPUs. ECPU primary systems explicitly use LVM storage, as required by the launch API. Examples 02 and 03 retain legacy database defaults and require a separate live Data Guard compatibility review.

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
| `delete_standby_db_home_on_delete` | `bool` | `true` | Destroy behavior for the association: OCI supports true only; destroying the association deletes the standby DB Home/system. |
| `fault_domains` | `list(string)` | `null` | Optional fault domains for the new DB system. |
| `freeform_tags` | `map(string)` | `{}` | Free-form tags on the new DB system. |
| `defined_tags` | `map(string)` | `{}` | Defined tags on the new DB system; namespaces must exist. |

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

## ✅ Validation

```sh
tofu fmt -recursive -check
tofu init -backend=false
tofu validate
tofu test
```

Root module validation on **2026-11-09** with OCI provider **9.12.1** passed, including **7 offline tests**. All three examples also passed validation and their 7 mock tests with OCI 9.12.1 and local dependency overrides. A read-only plan against the existing example 01 infrastructure showed 1 resource to add (the missing database), 0 changes and 0 destroys; the example has since been updated to ECPU; live provisioning results are recorded separately. Example 01 was subsequently deployed successfully on 2026-11-09 with 26ai 23.26.4.0.0, VM.BaseDB.x86, 4 ECPUs and LVM. Both DB system and database reached AVAILABLE; private listener connectivity, SSH and local SQL*Plus checks passed. FOGGYDB and FKPDB1 are READ WRITE. See the example README for details and limitations.

Historical validation on **2026-11-02** with OpenTofu **1.11.6** and OCI provider **6.37.0**: root module plus all three examples passed validation, and **14 offline tests passed** (7 module tests and 7 example tests). Root module tests cover primary/standby behavior; example tests cover full module composition, trusted SSH boundaries and distinct region enforcement. That historical run performed no live OCI deployment.

See [tests](tests/README.md) for coverage and limits. Validate each example independently before configuring real inputs. Live tests must verify `AVAILABLE` state, private SQL connectivity and, for standby, Data Guard transport/apply health. Mock tests cannot establish OCI quota, version availability, licensing, region support or network connectivity.

## 🆘 Support

See [SUPPORT.md](SUPPORT.md). Contributions should include sanitized reproduction steps and relevant validation results.

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**. See [LICENSE](LICENSE).

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.

