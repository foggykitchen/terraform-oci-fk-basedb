# OCI BaseDB with Terraform/OpenTofu - Training Examples

This directory contains three deployment examples for the **terraform-oci-fk-basedb** module. They progress from a single private database to same-region Data Guard and then cross-region Data Guard with private network peering.

These examples are part of the **[FoggyKitchen.com training ecosystem](https://foggykitchen.com/courses-2/)** and focus on database infrastructure, private access, availability and regional disaster recovery.

Each example creates its own child compartment, networking, security groups, Oracle Linux 9 bastion and BaseDB resources. You provide tenancy and parent-compartment context, OCI authentication, SSH public keys, a trusted administrator CIDR, a database version and the SYS password.

---

## Published Examples

| Example | Title | Key Topics |
|:-------:|:------|:-----------|
| 01 | [**Single Primary**](01_single_primary/README.md) | Private BaseDB system, DB Home, database and PDB; public bastion; private listener access |
| 02 | [**Same-Region Data Guard**](02_same_region_data_guard/README.md) | Primary and physical standby in one VCN; AD/FD placement; asynchronous redo transport |
| 03 | [**Cross-Region Data Guard**](03_cross_region_data_guard/README.md) | Two regional VCNs; DRGs and RPC peering; bidirectional routes; provider aliases; remote standby |

Read them in order to build on the concepts. **Deploy each independently**: example 02 does not reuse resources or state from example 01, and example 03 does not upgrade example 02.

### Topology at a glance

| Component | 01: Single primary | 02: Same-region Data Guard | 03: Cross-region Data Guard |
|---|---|---|---|
| Regions | One | One | Two distinct subscribed regions |
| BaseDB systems | One primary | Primary and standby | Primary and standby |
| VCNs / bastions | One / one | One / one | Two / two |
| Database subnets | One private subnet | One shared private subnet | One private subnet per region |
| DRGs / RPCs | None | None | Two / two |
| Database edition configured | Standard Edition | Enterprise Edition | Enterprise Edition |
| Active Data Guard | Not applicable | Disabled | Disabled |

---

## Before You Start

Use **OpenTofu >= 1.11.0** and **OCI provider >= 9.12.1, < 10.0.0**. Install Git for module downloads, plus an SSH client and `jq` for the runtime verification commands. Configure OCI credentials and ensure your identity has permissions and quotas for compartment, network, compute and database resources.

These examples use **ECPU-based VM.BaseDB.x86** systems. Review the provisioning boundary and verified deployment results in each example before deployment. Offline validation cannot confirm whether OCI will accept the selected shape, edition and database version in your tenancy.

BaseDB, bastions, NAT gateways and storage incur charges; example 03 also introduces cross-region traffic. Automatic primary backups are disabled by default. Each example retains its child compartment on destroy.

---

## How to Use

Each directory contains:

- Service-specific Terraform/OpenTofu configuration (`.tf`).
- A README with architecture, inputs, outputs, deployment and verification steps.
- A `terraform.tfvars.example` input template.
- A `cloud-init.yaml` payload that installs `nmap-ncat` on the bastion.
- Mocked-provider tests under `tests/`.

From the repository root, select **one** example:

```sh
cd examples/01_single_primary
```

Or choose `examples/02_same_region_data_guard` or `examples/03_cross_region_data_guard` from the repository root. Then prepare and deploy it:

```sh
cp terraform.tfvars.example terraform.tfvars
# Replace every placeholder with your own deployment inputs.
# Supply TF_VAR_admin_password securely through your local environment.
tofu init
tofu validate
tofu plan -out=example.tfplan
# Review the planned resources, placement and network permissions.
tofu apply example.tfplan
```

Use a unique `name_prefix` for each deployment. No pre-existing VCN, subnet or NSG IDs are needed. The primary region defaults to `eu-frankfurt-1`; example 03 uses `eu-amsterdam-1` as the standby region by default. Both regions must be subscribed for example 03.

Keep the SYS password, state and saved plans private. Follow the chosen example's runtime checks after deployment: a reachable TCP/1521 listener does not establish successful SQL authentication or healthy Data Guard replication.

---

## Offline Validation

Run these commands separately in each example directory:

```sh
tofu init -backend=false
tofu validate
tofu test
```

Tests mock the OCI providers and create no infrastructure. Initialization still downloads providers and modules. The tests check module composition and input validation, including trusted SSH CIDRs and distinct regions for example 03. They do not verify live OCI capacity, provisioning, network connectivity or Data Guard health.

See the [test coverage and limitations](../tests/README.md). Live deployment results must be checked separately using the instructions in each example.

---

## Design Principles

- One example teaches one deployment scenario and owns its own state.
- Each deployment composes dedicated FoggyKitchen modules for compartment, VCN, NSGs, compute and BaseDB; example 03 also uses the DRG module.
- Public access is limited to bastion SSH from a trusted administrator CIDR. Database nodes use private addressing.
- Configuration is separated by service and, where applicable, region.
- External modules use release tags; the BaseDB source is local (`../..`) so the examples exercise this checkout.
- Runtime verification distinguishes network access, database login and replication health.

---

## Cleanup

From the directory used for deployment, with its original state and inputs available:

```sh
tofu plan -destroy
tofu destroy
```

Copy any required database data first. Destroy deletes the lab databases and infrastructure. In examples 02 and 03, deleting the Data Guard association also deletes the standby DB Home/system. The child compartment is retained because `enable_delete = false`.

---

## Related Resources

- [FoggyKitchen OCI BaseDB module](../README.md)
- [FoggyKitchen OCI Compute module](https://github.com/foggykitchen/terraform-oci-fk-compute)
- [FoggyKitchen OCI VCN module](https://github.com/foggykitchen/terraform-oci-fk-vcn)
- [FoggyKitchen OCI NSG module](https://github.com/foggykitchen/terraform-oci-fk-nsg)
- [FoggyKitchen OCI DRG module](https://github.com/foggykitchen/terraform-oci-fk-drg)
- [FoggyKitchen OCI Compartment module](https://github.com/foggykitchen/terraform-oci-fk-compartment)
- [Cross-region DRG/RPC landing zone example](https://github.com/foggykitchen/foggykitchen-landing-zone-orchestrator/tree/main/examples/oci/networking/drg_cross_region/basic)
- [Support policy](../SUPPORT.md)

---

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](../LICENSE) for details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
