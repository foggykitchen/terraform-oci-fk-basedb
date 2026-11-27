# 04 — Single Primary with an Existing Vault and Customer-Managed Key

Create a private BaseDB primary using an **existing OCI Vault and AES-256 KMS key**. This follows [ADB lesson 7 at v2.0.0](https://github.com/foggykitchen/terraform-oci-fk-adb/tree/v2.0.0/training/lesson7_adb_with_oci_vault): the caller supplies `vault_id` and `kms_key_id`, and the lab composes database, networking and IAM resources. That ADB lesson neither creates nor imports a Vault and does not retrieve a Vault secret.

A secret containing an ADB password is not a TDE master key. This example never reads secret contents and does not reuse the ADB password. Supply the BaseDB SYS password separately through `TF_VAR_admin_password`.

## Architecture

![Private BaseDB with an existing Vault key and OCI Bastion Service](04_single_primary_with_cmk_architecture.jpg)

*Figure 1. Single-region BaseDB with an existing Vault key, private client and database subnets, and access through OCI Bastion Service.*

- A dedicated lab compartment and VCN with two private subnets: client and Bastion endpoint `10.40.0.0/24`, and database `10.40.1.0/24`.
- An Oracle Linux 9 client with no public IP, reached through OCI Bastion Service from `admin_cidr`. No Internet Gateway; NAT and Service Gateway provide outbound connectivity.
- The client subnet security list allows TCP/22 egress within that subnet for the Bastion endpoint. This additive rule also applies to the client VNIC. Client NSG ingress allows SSH only from the endpoint's /32. Database NSG ingress allows TCP/22 and TCP/1521 only from the client NSG.
- One VM.BaseDB.x86 primary, 4 ECPUs, 256 GB data storage, Standard Edition and LVM by default.
- Read-only Vault/key metadata lookups in `primary_region`; no Vault, key, key-version or secret resources in this state.
- An optional lab-owned dynamic group and scoped IAM policy in the tenancy home region.

| Module | Source |
|---|---|
| BaseDB | Local `../..` checkout |
| Compartment | v0.2.0 |
| VCN | v0.3.0 |
| NSG | v0.2.0 |
| Compute | v0.3.0 |
| Policy | v0.2.0 |
| Bastion Service | v0.2.0 |

If the shared Vault is managed using [terraform-oci-fk-vault v0.2.0](https://github.com/foggykitchen/terraform-oci-fk-vault/tree/v0.2.0), consume its `vault_id` and `key_ids` outputs. Any import into that module belongs in its separate shared-resource state, not this lab. Do not assign two states ownership of the same Vault/key.

## Existing key and IAM prerequisites

Use OpenTofu >= 1.11.0 and OCI >= 9.12.1, < 10.0.0. The Vault must be ACTIVE in `primary_region`. The key must belong to that Vault, be ENABLED and use AES-256 with HSM or SOFTWARE protection. Metadata data sources check those properties during a real plan. The deployment identity needs read access to the existing Vault/key, in addition to normal database/network permissions and IAM administration when `create_vault_iam = true`.

By default, `iam.tf` creates a uniquely named dynamic group matching resources in the dedicated lab compartment. Its policy grants `use vaults` for the selected Vault and `manage keys` for the selected key, constrained by compartment and resource OCID. There are no secret or secret-bundle grants. Unlike the ADB lesson's `use keys`, BaseDB needs key-management permissions; see [BaseDB key prerequisites](https://docs.oracle.com/en/cloud/paas/base-database/guide/key-about.html), [DB-node key access](https://docs.oracle.com/en-us/iaas/Content/KeyManagement/Tasks/assigningkeys.htm), and [supported Vault policy conditions](https://docs.oracle.com/en-us/iaas/Content/Identity/policyreference/keypolicyreference.htm).

The group covers the lab compartment, not only one resource OCID. Keep unrelated workloads out of this compartment. A dedicated existing BaseDB key in the shared Vault is preferable to reusing the key that encrypts unrelated secrets: database operations may create key versions, and `manage keys` is broader than encrypt/decrypt. This configuration does not itself rotate or schedule deletion of the shared key.

Set `create_vault_iam = false` only when equivalent IAM for the lab compartment is already administered externally. No existing policies are adopted or edited. Do not switch this flag off after deployment unless equivalent permissions are already effective: doing so plans deletion of the lab-owned IAM resources. Separate instances of policy v0.2.0 create the dynamic group first and then bind policy statements to its OCID. This establishes an explicit dependency and avoids creating a name-based policy before the group exists. A `moved` block preserves the existing dynamic group in state. `depends_on` orders policy creation before BaseDB, but does not guarantee IAM propagation has completed. Confirm effective permissions before provisioning; a successful static validation cannot establish that.

## Files and inputs

The private-access layout follows the [orchestrator BaseDB private-access example at v2.2.1](https://github.com/foggykitchen/foggykitchen-landing-zone-orchestrator/blob/v2.2.1/examples/oci/database/basedb/private_access/basic/README.md). `bastion.tf` creates the service and an optional temporary session. The service is separate from the session so its endpoint IP can restrict client ingress without a dependency cycle. `vault.tf` reads the existing Vault/key, `iam.tf` composes the policy module, and `dbsystem.tf` passes the CMK IDs into the BaseDB module.

| Additional input | Default | Meaning |
|---|---|---|
| `vault_id` | Required | Existing Vault OCID in the primary region |
| `kms_key_id` | Required | Existing AES-256 key OCID in that Vault |
| `kms_key_version_id` | `null` | Optional existing key version for the CDB |
| `create_vault_iam` | `true` | Create lab-owned dynamic group and policy |
| `create_session` | `false` | Create Managed SSH session after plugin readiness is verified |
| `session_ttl_in_seconds` | `3600` | Temporary session lifetime: 1800–10800 seconds |
| `admin_cidr` | Required | Trusted public IPv4 CIDR in the Bastion Service allow list; /0 forbidden |

The remaining inputs match [example 01](../01_single_primary/README.md), with `name_prefix = "fk-basedb-04"` and VCN CIDR `10.40.0.0/16`. Use a unique prefix and non-overlapping CIDRs when deploying multiple labs.

```sh
cp terraform.tfvars.example terraform.tfvars
# Replace placeholders with your tenancy, existing Vault/key and trusted admin CIDR.
# Supply TF_VAR_admin_password securely through the environment.
tofu init -backend=false
tofu validate
tofu plan -out=example.tfplan
```

Review the plan before an explicitly approved `tofu apply example.tfplan`. It must contain no managed Vault, key or secret resources. BaseDB compute/storage, the private client and NAT incur charges; the existing Vault/key retain their existing lifecycle and costs. With no supplied SSH keys the lab generates a private key in state; protect state and plans.

The root module's nested CMK fields are `ForceNew` in the provider. Changing the Vault, key or explicit key version may replace the primary system. This example is not an in-place migration or rotation workflow.

## Private access through OCI Bastion Service

The access path is `administrator → OCI Bastion Service → private client → private BaseDB`. There is no public SSH address on the client or database. The Bastion endpoint shares the client subnet. Its security list supplies SSH egress because the service endpoint is not attached to the client NSG. Security-list and NSG rules are additive: the shared list also permits client SSH egress within that subnet, but grants no ingress. Client SSH ingress remains restricted to the endpoint /32 in its NSG. Default security lists are excluded from both subnets. HTTPS egress allows client updates and agent communication through NAT/Service Gateway.

1. Deploy only after approval, initially keeping `create_session = false`. The compute configuration requests the Oracle Cloud Agent **Bastion** plugin to be ENABLED. In OCI Console, open the client instance's Oracle Cloud Agent tab and wait until that plugin actually reports **RUNNING**. ENABLED is desired configuration, not readiness. The deployment identity also needs Bastion/session permissions; see [OCI Bastion prerequisites](https://docs.oracle.com/en-us/iaas/Content/Bastion/Tasks/managingbastions.htm).
2. Once RUNNING, set `create_session = true`, review a fresh plan and apply it only with deployment approval. This example uses explicit staging instead of the orchestrator's fixed 600-second wait: a delay alone cannot prove plugin readiness. The session targets the private client as `opc` using the first supplied SSH key (or the generated lab key).
3. Read `tofu output -raw session_ssh_command`. Substitute your matching local private-key path in the OCI-generated command and run it from the allowed public CIDR. If a lab key was generated, save the sensitive `ssh_private_key_pem` output to a local file with mode 600. Do not commit it or copy it onto the client.
4. On the client, test `nc -zv <primary-private-ip> 1521`. For SQL/DB-host checks, use SSH ProxyJump through the client with your key kept locally, or an installed Oracle SQL client and the private connection string. Do not use direct public SSH or enable unrestricted agent forwarding. Confirm `v$database` reports PRIMARY / READ WRITE, the PDB is open, and inspect `v$encryption_wallet`.

Sessions expire after their configured TTL (one hour by default, at most three hours); expiry does not delete the service, client or database. Inspect a refreshed plan before recreating an expired session. With `create_session = false`, session outputs are null; use `bastion_id`, `primary_client_id` and `primary_client_private_ip` to identify the access resources. Setting the flag back to false plans deletion of the managed session.

## Runtime verification after an approved deployment

1. Confirm the DB system and database are AVAILABLE. Record the database OCID and inspect the database's encryption fields using the existing OCI authentication:

   ```sh
   DATABASE_ID=$(tofu output -raw primary_database_id)
   oci db database get --database-id "$DATABASE_ID" --region "$PRIMARY_REGION" \
     --query 'data.{state:"lifecycle-state",key:"kms-key-id",vault:"vault-id",version:"kms-key-version-id"}'
   ```

   Set `PRIMARY_REGION` to the configured region. Compare the returned key/Vault with the chosen inputs. `cmk_vault_id`, `cmk_key_id` and `cmk_requested_key_version_id` outputs describe the selected inputs; they are not proof that the database uses them. If the API omits a field, inspect the database Encryption section in OCI Console rather than inferring success from configuration.

2. Perform the private-access and SQL checks above. Inspect the database Encryption section and record the evidence without passwords or key material.
3. Run `tofu plan` again and inspect any differences. If an explicit CDB key version was supplied, compare it separately. Oracle may use a different/new version for the PDB; see [BaseDB encryption-key behavior](https://docs.oracle.com/en/cloud/paas/base-database/guide/key-about.html).

## Cleanup and shared resources

After explicit cleanup approval, review `tofu plan -destroy` and run the approved destroy. It removes the lab database, private client, Bastion session/service, network and lab-owned IAM resources. The child compartment is retained (`enable_delete = false`). Existing Vault/key metadata entries are data sources, not managed resources: the lab does not schedule Vault/key deletion or delete the existing ADB secret.

Keep the key available for any retained database backups and other consumers. Verify the shared Vault/key remain ACTIVE/ENABLED and that unrelated ADB resources still have their own IAM access. No key disable/delete/rotation or secret-content reads are part of this lab's cleanup.

## 🖥️ OCI Console and Runtime Verification

Validated with OpenTofu 1.11.6 and OCI provider 9.15.0. Initialization, validation and recursive formatting passed.

Live checks on 2026-11-27:

| Check | Result |
|---|---|
| Initial DB creation | FAILED after approximately 37.5 minutes: DCS-10353 / DBT-16015, KMS validation |
| Initial KMS audit | GetKey by the DB System principal returned HTTP 404 at 10:46:55 UTC; the deployment identity could read the same enabled AES-256 key |
| IAM correction | Policy references the dynamic-group OCID; explicit dependency orders group before policy. Existing group preserved using a moved block; policy updated in place |
| Approved replacement | Previous DB System TERMINATED; removal took 5m36s, replacement creation took 45m26s; apply succeeded with 1 added / 1 destroyed |
| Replacement KMS audit | GetKey returned HTTP 200 at 11:37:59 UTC; CreateKeyVersion returned HTTP 200 at 11:39:35 UTC |
| DB System / database | Both AVAILABLE; database API returned the selected existing Vault and key OCIDs |
| Private client | RUNNING, no public IP; Bastion plugin RUNNING |
| Bastion access | Managed SSH session ACTIVE; SSH to the private client passed |
| Private listener | TCP/1521 reachable from client to DB node |
| SQL | FOGGYDB PRIMARY / READ WRITE; FKPDB1 READ WRITE; PDB$SEED READ ONLY |
| Wallet inspection | OKV rows OPEN for CON_ID 1, 2 and 3; accompanying FILE/AUTOLOGIN rows report OPEN_NO_MASTER_KEY |
| Final plan | No changes. Your infrastructure matches the configuration. |

The successful retry confirms KMS access and CMK assignment with the corrected IAM configuration. It does not isolate name binding/creation ordering from IAM propagation as the sole cause of the first failure. OCI created key versions during database provisioning, as expected; the key itself remains outside lab-managed state.

The initial generated SYS password was also rejected before DB provisioning because OCI required at least two special characters; the locally supplied password was corrected before the first DB System creation. Passwords and runtime state/plan artifacts are not included in this repository.

SQL checks used `sudo -iu oracle sqlplus -s / as sysdba` on the private DB node, reached through the client and OCI Bastion Service. This verifies local OS authentication; it does not establish password-based application authentication over the listener. Observed SQL results (spacing normalized):

```text
NAME     DATABASE_ROLE  OPEN_MODE
FOGGYDB  PRIMARY        READ WRITE

NAME      OPEN_MODE
PDB$SEED  READ ONLY
FKPDB1    READ WRITE

CON_ID  STATUS              WALLET_TYPE  WRL_TYPE
1       OPEN_NO_MASTER_KEY   AUTOLOGIN    FILE
1       OPEN                 OKV          OKV
2       OPEN_NO_MASTER_KEY   AUTOLOGIN    FILE
2       OPEN                 OKV          OKV
3       OPEN_NO_MASTER_KEY   AUTOLOGIN    FILE
3       OPEN                 OKV          OKV
```

The owner-approved full lab cleanup completed on 2026-11-27. OpenTofu reported 27 resources destroyed and the state contains zero resources; the compartment remains ACTIVE because `enable_delete = false`. A fresh destroy plan reports no changes. OCI inventory confirms the DB System and client are TERMINATED, the Bastion is DELETED, and no active DB systems, compute instances, VCNs, block/boot volumes (all three Frankfurt ADs), database backups, lab policy or dynamic group remain. The existing Vault is ACTIVE and its key ENABLED.

Cleanup exposed a client-NSG ordering hazard: the original configuration allowed client rules to be deleted before the Managed SSH session finished. During this run, the former HTTPS egress and endpoint-only SSH ingress were temporarily restored through OCI CLI; both were removed with the NSG at final teardown. The session completed deletion after 17m36s. This recovery does not prove that rule removal was the sole cause of the delay. `compute_primary.tf` now explicitly depends on the complete client NSG module, preserving its rules until the session and client are destroyed. The dependency correction passes validation, but a fresh deployment/destroy cycle with that correction has not been repeated. No automatic CLI cleanup hook was added for Bastion.

This scenario does not test cross-region key replication or Data Guard with CMK.

## 📸 OCI Console Screenshots

Captured from the verified example 04 deployment in Frankfurt on **2026-11-27**. These screenshots show the successful replacement DB System and the existing shared Vault/key. Runtime checks above provide the SSH, listener and SQL evidence.

![Private regional subnets — example 04](04_single_primary_with_cmk_vcn_subnets.jpg)

*Figure 2. VCN subnets. Both regional subnets are private and Available: client/Bastion endpoint `10.40.0.0/24` and database `10.40.1.0/24`.*

![Private compute client — example 04](04_single_primary_with_cmk_private_client.jpg)

*Figure 3. Private client. The instance is Running in the lab compartment on VM.Standard.E4.Flex; OCI Console confirms that it cannot be accessed directly from the Internet because it resides in a private subnet.*

![Active OCI Bastion Managed SSH session — example 04](04_single_primary_with_cmk_bastion_session.jpg)

*Figure 4. Bastion session. The Active Managed SSH session targets the private client on TCP/22 as `opc`, with a one-hour TTL. This is a point-in-time capture; sessions expire independently of the client and database.*

![Available BaseDB system — example 04](04_single_primary_with_cmk_db_system.jpg)

*Figure 5. DB System. The successful replacement is Available in Frankfurt AD-1, using VM.BaseDB.x86, 4 ECPUs, Standard Edition and 256 GB data storage, with the private database subnet and database NSG.*

![Database encryption with the existing Vault key — example 04](04_single_primary_with_cmk_database_encryption.jpg)

*Figure 6. Database encryption. FOGGYDB is Available on version 23.26.4.0.0 and references the existing `FoggyKitchenMasterEnryptionKey` in its Encryption section. Automatic backups and Data Guard are disabled in this standalone lab.*

![Existing enabled AES-256 Vault key — example 04](04_single_primary_with_cmk_vault_key.jpg)

*Figure 7. Existing key. The Enabled AES-256 key uses Software protection in `FoggyKitchenVault`; its 2023 creation date confirms that the key predates this lab. The Vault and key are not managed by the lab state.*

![Vault key versions after BaseDB provisioning — example 04](04_single_primary_with_cmk_vault_key_versions.jpg)

*Figure 8. Key versions. The existing 2023 version remains Enabled alongside two versions created during the successful database provisioning at 11:39 and 11:40 UTC. KMS audit independently records successful CreateKeyVersion activity by the DB System principal.*

![CMK IAM policy referencing the dynamic-group OCID — example 04](04_single_primary_with_cmk_iam_policy.jpg)

*Figure 9. IAM policy. The Active `fk-basedb-04-cmk-policy` references the dynamic-group OCID and grants `use vaults` and `manage keys`. The console clips the ends of these long statements; [iam.tf](iam.tf) contains the complete conditions restricting access to the selected Vault/key.*

## License

Universal Permissive License (UPL), Version 1.0. See [LICENSE](../../LICENSE).

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
