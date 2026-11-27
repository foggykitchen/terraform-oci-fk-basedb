# Changelog

## v0.2.0 — Unreleased

- Add example 04: PRIMARY with an existing Vault/AES-256 key, metadata checks, optional scoped IAM through policy v0.2.0 and cleanup that leaves shared Vault/key/secrets outside managed state. Follows ADB lesson 7; no Vault import or secret-content retrieval. Uses private compute and OCI Bastion Service v0.2.0, three private subnets, no public IP/Internet Gateway, and staged Managed SSH sessions after plugin readiness verification.

- Document the provider 9.x cross-region standby deletion limitation. `NewDbSystem` deletion attempts whole-system termination using the association's primary-region client; missing-resource error handling can clear state without terminating the remote peer. The delete implementation is unchanged across the reviewed 9.12.1, 9.13.0 and 9.14.0 tags. The exact HTTP error in the historical failed runs remains unverified.
- Add `standby_db_system_id` and caller-supplied `standby_region_hint` outputs for pre-destroy inventory.
- Add optional `standby_cleanup = { enabled = false, oci_cli_profile = null }`. A STANDBY-only metadata resource stores the destroy hook. When enabled, it uses OCI CLI in the explicit target region, verifies the peer is still STANDBY, terminates it and verifies TERMINATED before association teardown. Errors fail the destroy. No CLI operations occur by default.
- Document cleanup registration in state, replacement/removal caveats and the manual recovery sequence. Never remove state entries to hide orphaned resources. CLI termination waits for work-request SUCCEEDED, followed by a separate DB-system TERMINATED check.
- Add optional PRIMARY `kms_key_id`, `vault_id` and `kms_key_version_id` inputs. Require a key/vault pair; reject these inputs on STANDBY. Document Data Guard key replication, BaseDB IAM and Vault v0.2.0 integration. The provider marks these nested database fields ForceNew; this is not in-place key rotation.
- Require Terraform/OpenTofu >= 1.11.0; retain OCI >= 9.12.1, < 10.0.0 and the `oci.target` alias.
- Update examples to VCN v0.3.0, NSG v0.2.0, compute v0.3.0, DRG v0.5.0 and compartment v0.2.0. Tagged inputs, outputs and changelogs were reviewed; the interfaces used by these examples remain compatible.
- Update provider 9.x lifecycle documentation and remove obsolete provider references. No GitHub Actions or test directories are introduced.

Compatibility: no existing module input/output or OCI resource address is removed or renamed. The minimum CLI version increase is a prerequisite-breaking change for callers on 1.8–1.10. Existing STANDBY configurations gain a metadata-only `terraform_data` resource on their next approved apply; cleanup remains disabled unless explicitly enabled and persisted. No live deployment or destroy verification was performed for this version. This is a release-notes draft; no v0.2.0 tag or release has been published.
