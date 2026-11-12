mock_provider "oci" {
  mock_data "oci_identity_region_subscriptions" {
    defaults = {
      region_subscriptions = [{
        is_home_region = true
        region_key     = ""
        region_name    = "eu-frankfurt-1"
        state          = ""
        tenancy_id     = ""
      }]
    }
  }
  mock_data "oci_identity_availability_domains" {
    defaults = {
      availability_domains = [{
        compartment_id = ""
        id             = ""
        name           = "TEST:AD-1"
        }, {
        compartment_id = ""
        id             = ""
        name           = "TEST:AD-2"
      }]
    }
  }
  mock_data "oci_core_images" {
    defaults = {
      images = [{
        agent_features       = []
        base_image_id        = ""
        billable_size_in_gbs = ""
        compartment_id       = ""
        create_image_allowed = false
        defined_tags = {

        }
        display_name = ""
        freeform_tags = {

        }
        id                       = "ocid1.image.oc1.test.ol9"
        image_source_details     = []
        instance_id              = ""
        launch_mode              = ""
        launch_options           = []
        listing_type             = ""
        operating_system         = "Oracle Linux"
        operating_system_version = "9"
        size_in_mbs              = ""
        state                    = ""
        time_created             = ""
      }]
    }
  }
  mock_data "oci_core_services" {
    defaults = {
      services = [{
        cidr_block  = "all-test-services-in-oracle-services-network"
        description = ""
        id          = "ocid1.service.oc1.test.osn"
        name        = "All TEST Services In Oracle Services Network"
      }]
    }
  }
  mock_data "oci_database_db_nodes" {
    defaults = {
      db_nodes = [{
        compute_count               = 0
        compute_model               = "OCPU"
        is_os_patch_reboot_required = false
        system_tags                 = {}
        additional_details          = ""
        backup_ip_id                = ""
        backup_ipv6id               = ""
        backup_vnic2id              = ""
        backup_vnic_id              = ""
        cpu_core_count              = 0
        db_node_id                  = ""
        db_node_storage_size_in_gbs = 0
        db_server_id                = ""
        db_system_id                = ""
        defined_tags = {

        }
        fault_domain = ""
        freeform_tags = {

        }
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
        vnic_id                       = "ocid1.vnic.oc1.test.database"
      }]
    }
  }
  mock_data "oci_database_database" {
    defaults = {
      state      = "AVAILABLE"
      db_home_id = "ocid1.dbhome.oc1.test.database"
    }
  }
  mock_data "oci_core_vnic_attachments" {
    defaults = { vnic_attachments = [{ "availability_domain" : "", "compartment_id" : "", "create_vnic_details" : [], "display_name" : "", "id" : "", "instance_id" : "", "nic_index" : 0, "state" : "", "subnet_id" : "", "time_created" : "", "vlan_id" : "", "vlan_tag" : 0, "vnic_id" : "ocid1.vnic.oc1.test.bastion" }] }
  }
  mock_data "oci_core_vnic" {
    defaults = {
      private_ip_address = "10.30.1.10"
    }
  }
  mock_resource "oci_identity_compartment" {
    defaults = { id = "ocid1.compartment.oc1..offline" }
  }
  mock_resource "oci_core_subnet" {
    defaults = { id = "ocid1.subnet.oc1.test.database" }
  }
  mock_resource "oci_database_db_system" {
    defaults = {
      id      = "ocid1.dbsystem.oc1.test.primary"
      db_home = { id = "ocid1.dbhome.oc1.test.primary", database = { id = "ocid1.database.oc1.test.primary" } }
    }
  }
  mock_resource "oci_database_data_guard_association" {
    defaults = {
      id                = "ocid1.dataguardassociation.oc1.test.primary"
      peer_database_id  = "ocid1.database.oc1.test.standby"
      peer_db_system_id = "ocid1.dbsystem.oc1.test.standby"
    }
  }
}
mock_provider "oci" {
  alias = "home"
  mock_data "oci_identity_region_subscriptions" {
    defaults = {
      region_subscriptions = [{
        is_home_region = true
        region_key     = ""
        region_name    = "eu-frankfurt-1"
        state          = ""
        tenancy_id     = ""
      }]
    }
  }
  mock_data "oci_identity_availability_domains" {
    defaults = {
      availability_domains = [{
        compartment_id = ""
        id             = ""
        name           = "TEST:AD-1"
        }, {
        compartment_id = ""
        id             = ""
        name           = "TEST:AD-2"
      }]
    }
  }
  mock_data "oci_core_images" {
    defaults = {
      images = [{
        agent_features       = []
        base_image_id        = ""
        billable_size_in_gbs = ""
        compartment_id       = ""
        create_image_allowed = false
        defined_tags = {

        }
        display_name = ""
        freeform_tags = {

        }
        id                       = "ocid1.image.oc1.test.ol9"
        image_source_details     = []
        instance_id              = ""
        launch_mode              = ""
        launch_options           = []
        listing_type             = ""
        operating_system         = "Oracle Linux"
        operating_system_version = "9"
        size_in_mbs              = ""
        state                    = ""
        time_created             = ""
      }]
    }
  }
  mock_data "oci_core_services" {
    defaults = {
      services = [{
        cidr_block  = "all-test-services-in-oracle-services-network"
        description = ""
        id          = "ocid1.service.oc1.test.osn"
        name        = "All TEST Services In Oracle Services Network"
      }]
    }
  }
  mock_data "oci_database_db_nodes" {
    defaults = {
      db_nodes = [{
        compute_count               = 0
        compute_model               = "OCPU"
        is_os_patch_reboot_required = false
        system_tags                 = {}
        additional_details          = ""
        backup_ip_id                = ""
        backup_ipv6id               = ""
        backup_vnic2id              = ""
        backup_vnic_id              = ""
        cpu_core_count              = 0
        db_node_id                  = ""
        db_node_storage_size_in_gbs = 0
        db_server_id                = ""
        db_system_id                = ""
        defined_tags = {

        }
        fault_domain = ""
        freeform_tags = {

        }
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
        vnic_id                       = "ocid1.vnic.oc1.test.database"
      }]
    }
  }
  mock_data "oci_database_database" {
    defaults = {
      state      = "AVAILABLE"
      db_home_id = "ocid1.dbhome.oc1.test.database"
    }
  }
  mock_data "oci_core_vnic_attachments" {
    defaults = { vnic_attachments = [{ "availability_domain" : "", "compartment_id" : "", "create_vnic_details" : [], "display_name" : "", "id" : "", "instance_id" : "", "nic_index" : 0, "state" : "", "subnet_id" : "", "time_created" : "", "vlan_id" : "", "vlan_tag" : 0, "vnic_id" : "ocid1.vnic.oc1.test.bastion" }] }
  }
  mock_data "oci_core_vnic" {
    defaults = {
      private_ip_address = "10.30.1.10"
    }
  }
  mock_resource "oci_identity_compartment" {
    defaults = { id = "ocid1.compartment.oc1..offline" }
  }
  mock_resource "oci_core_subnet" {
    defaults = { id = "ocid1.subnet.oc1.test.database" }
  }
  mock_resource "oci_database_db_system" {
    defaults = {
      id      = "ocid1.dbsystem.oc1.test.primary"
      db_home = { id = "ocid1.dbhome.oc1.test.primary", database = { id = "ocid1.database.oc1.test.primary" } }
    }
  }
  mock_resource "oci_database_data_guard_association" {
    defaults = {
      id                = "ocid1.dataguardassociation.oc1.test.primary"
      peer_database_id  = "ocid1.database.oc1.test.standby"
      peer_db_system_id = "ocid1.dbsystem.oc1.test.standby"
    }
  }
}
variables {
  tenancy_ocid          = "ocid1.tenancy.oc1..offline"
  parent_compartment_id = "ocid1.compartment.oc1..offline"
  primary_region        = "eu-frankfurt-1"
  admin_cidr            = "203.0.113.10/32"
  database_version      = "19.0.0.0"
  admin_password        = "OfflineTestOnly_123#"
  ssh_public_keys       = ["ssh-ed25519 offline-only"]
}
run "end_to_end_composition" {
  command = apply
  assert {
    condition     = output.primary_private_ips == ["10.30.1.10"] && output.primary_database_id == "ocid1.database.oc1.test.primary"
    error_message = "The composed primary must expose its database and private IP."
  }
}
run "reject_public_ssh" {
  command = plan
  variables { admin_cidr = "0.0.0.0/0" }
  expect_failures = [var.admin_cidr]
}
