mock_provider "oci" {
  mock_resource "oci_database_db_system" {
    defaults = {
      id      = "ocid1.dbsystem.oc1.test.primary"
      db_home = { id = "ocid1.dbhome.oc1.test.primary", database = { id = "ocid1.database.oc1.test.primary" } }
    }
  }
  mock_resource "oci_database_data_guard_association" {
    defaults = {
      id                = "ocid1.dataguardassociation.oc1.test.source"
      peer_db_system_id = "ocid1.dbsystem.oc1.test.standby"
      peer_database_id  = "ocid1.database.oc1.test.standby"
      peer_role         = "PHYSICAL_STANDBY"
    }
  }
}
mock_provider "oci" {
  alias = "target"
  mock_data "oci_database_database" {
    defaults = {
      db_home_id = "ocid1.dbhome.oc1.test.target"
      state      = "AVAILABLE"
    }
  }
  mock_data "oci_database_db_nodes" {
    defaults = {
      # OCI exposes db_nodes as a fully typed computed object list.
      db_nodes = [{
        compute_count                 = 0
        compute_model                 = "OCPU"
        is_os_patch_reboot_required   = false
        system_tags                   = {}
        additional_details            = ""
        backup_ip_id                  = ""
        backup_ipv6id                 = ""
        backup_vnic2id                = ""
        backup_vnic_id                = ""
        cpu_core_count                = 0
        db_node_id                    = ""
        db_node_storage_size_in_gbs   = 0
        db_server_id                  = ""
        db_system_id                  = ""
        defined_tags                  = {}
        fault_domain                  = ""
        freeform_tags                 = {}
        host_ip_id                    = ""
        host_ipv6id                   = ""
        hostname                      = ""
        id                            = ""
        lifecycle_details             = ""
        maintenance_type              = ""
        memory_size_in_gbs            = 0
        software_storage_size_in_gb   = 0
        state                         = ""
        time_created                  = ""
        time_maintenance_window_end   = ""
        time_maintenance_window_start = ""
        total_cpu_core_count          = 0
        vnic2id                       = ""
        vnic_id                       = "ocid1.vnic.oc1.test.target"
      }]
    }
  }
  mock_data "oci_core_vnic" {
    defaults = { private_ip_address = "10.0.4.10" }
  }
}
variables {
  compartment_id      = "ocid1.compartment.oc1..test"
  availability_domain = "TEST:AD-1"
  subnet_id           = "ocid1.subnet.oc1.test.database"
  display_name        = "TestBaseDB"
  hostname            = "testdb"
  admin_password      = "OfflineTestOnly_123#"
}
run "primary" {
  command = apply
  variables {
    database_name    = "FOGGYDB"
    database_version = "19.0.0.0"
    ssh_public_keys  = ["ssh-ed25519 offline-test-only"]
  }
  assert {
    condition     = length(oci_database_db_system.this) == 1 && length(oci_database_data_guard_association.this) == 0
    error_message = "PRIMARY must create only the DB system."
  }
  assert {
    condition     = output.db_system_id == "ocid1.dbsystem.oc1.test.primary" && output.database_id == "ocid1.database.oc1.test.primary"
    error_message = "Primary IDs must identify the primary resources."
  }
  assert {
    condition     = output.private_ips == ["10.0.4.10"] && output.data_guard_association_id == null
    error_message = "Primary private IP must come from the target provider; association must be null."
  }
}
run "standby" {
  command = apply
  variables {
    role                = "STANDBY"
    primary_database_id = "ocid1.database.oc1.test.primary"
  }
  assert {
    condition     = length(oci_database_db_system.this) == 0 && length(oci_database_data_guard_association.this) == 1
    error_message = "STANDBY must create only the association, never a second explicit DB system."
  }
  assert {
    condition     = output.db_system_id == "ocid1.dbsystem.oc1.test.standby" && output.database_id == "ocid1.database.oc1.test.standby"
    error_message = "Standby outputs must identify the peer, not the source primary."
  }
  assert {
    condition     = oci_database_data_guard_association.this[0].database_id == "ocid1.database.oc1.test.primary" && oci_database_data_guard_association.this[0].creation_type == "NewDbSystem"
    error_message = "The association must refer to the source primary using NewDbSystem."
  }
  assert {
    condition     = output.private_ips == ["10.0.4.10"] && output.data_guard_role == "PHYSICAL_STANDBY"
    error_message = "Standby must expose target IP and observed peer role."
  }
}
run "reject_missing_primary_inputs" {
  command         = plan
  expect_failures = [oci_database_db_system.this]
}
run "reject_missing_source_database" {
  command = plan
  variables { role = "STANDBY" }
  expect_failures = [oci_database_data_guard_association.this]
}
run "reject_primary_only_standby_inputs" {
  command = plan
  variables {
    role                = "STANDBY"
    primary_database_id = "ocid1.database.oc1.test.primary"
    database_name       = "INVALID"
  }
  expect_failures = [oci_database_data_guard_association.this]
}
run "reject_sync_transport" {
  command = plan
  variables {
    role                = "STANDBY"
    primary_database_id = "ocid1.database.oc1.test.primary"
    transport_type      = "SYNC"
  }
  expect_failures = [var.transport_type]
}

run "reject_standby_retention" {
  command = plan
  variables {
    role                             = "STANDBY"
    primary_database_id              = "ocid1.database.oc1.test.primary"
    delete_standby_db_home_on_delete = false
  }
  expect_failures = [var.delete_standby_db_home_on_delete]
}

run "ecpu_primary" {
  command = apply
  variables {
    shape            = "VM.BaseDB.x86"
    compute_model    = "ECPU"
    compute_count    = 4
    database_name    = "FOGGYDB"
    database_version = "23.26.4.0.0"
    ssh_public_keys  = ["ssh-ed25519 offline-test-only"]
  }
  assert {
    condition     = oci_database_db_system.this[0].compute_model == "ECPU" && oci_database_db_system.this[0].compute_count == 4 && oci_database_db_system.this[0].db_system_options[0].storage_management == "LVM"
    error_message = "Primary must pass ECPU sizing to the provider."
  }
}
run "ecpu_standby" {
  command = apply
  variables {
    role                = "STANDBY"
    primary_database_id = "ocid1.database.oc1.test.primary"
    shape               = "VM.BaseDB.x86"
    compute_model       = "ECPU"
    compute_count       = 4
  }
  assert {
    condition     = oci_database_data_guard_association.this[0].compute_model == "ECPU" && oci_database_data_guard_association.this[0].compute_count == 4
    error_message = "Standby must pass ECPU sizing to the provider."
  }
}
run "reject_invalid_ecpu_count" {
  command = plan
  variables {
    shape            = "VM.BaseDB.x86"
    compute_model    = "ECPU"
    compute_count    = 3
    database_name    = "FOGGYDB"
    database_version = "23.26.4.0.0"
    ssh_public_keys  = ["ssh-ed25519 offline-test-only"]
  }
  expect_failures = [oci_database_db_system.this]
}
run "reject_ecpu_shape_with_ocpu" {
  command = plan
  variables {
    shape            = "VM.BaseDB.x86"
    database_name    = "FOGGYDB"
    database_version = "23.26.4.0.0"
    ssh_public_keys  = ["ssh-ed25519 offline-test-only"]
  }
  expect_failures = [oci_database_db_system.this]
}
