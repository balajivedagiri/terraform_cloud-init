terraform {
  required_providers {
    vsphere = {
      source = "hashicorp/vsphere"
      version = "2.2.0"
    }
  }
}

provider "vsphere" {
  # If you use a domain, set your login like this "Domain\\User"
  user           = var.vcenter_user
  password       = var.vcenter_password
  vsphere_server = var.vcenter_url

  # If you have a self-signed cert
  allow_unverified_ssl = true
}


data "vsphere_datacenter" "mydatacenter" {
  name = "dev-dc"
}

data "vsphere_datastore_cluster" "datastore_cluster" {
  name          = "DSC_ULTRA"
  datacenter_id = "${data.vsphere_datacenter.mydatacenter.id}"
}


data "vsphere_folder" "folder" {
#  path = "tenanat43-windows-01 (98cbbd1d-4e18-40fe-8309-fb8ebe20a62b)"
  path = "/dev-dc/vm/vcddev/tenant43 (3de7c268-11e8-4bf6-b02a-046695bb7af2)/tenant43-vdc (8fe0935d-a5c8-4e45-be4c-d49fec9b1229)/tenanat43-windows-01 (98cbbd1d-4e18-40fe-8309-fb8ebe20a62b)"
}

data "vsphere_network" "network" {
  name = "tenant43-ntw-72a59d1a-398e-4018-8dbd-5afa8ca60d40"
  datacenter_id = "${data.vsphere_datacenter.mydatacenter.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "balaji-ubuntu-2004-cloud-init-without-networking1"
  datacenter_id = "${data.vsphere_datacenter.mydatacenter.id}"
}


data "vsphere_resource_pool" "pool" {
  name          = "tenant43-vdc (8fe0935d-a5c8-4e45-be4c-d49fec9b1229)"
  datacenter_id = "${data.vsphere_datacenter.mydatacenter.id}"
}


resource "vsphere_virtual_machine" "ubuntu-2004-cloud-init-testing02" {
  name             = "ubuntu-2004-cloud-init-testing02"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_cluster_id     = "${data.vsphere_datastore_cluster.datastore_cluster.id}"
  num_cpus         = 4
  memory           = 16384
  guest_id         = "${data.vsphere_virtual_machine.template.guest_id}"
  scsi_type        = "${data.vsphere_virtual_machine.template.scsi_type}"
  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }
  disk {
    label            = "disk0"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }
  disk {
    label            = "disk1"
    size             = 50
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
    unit_number  = 1
  }
  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
    customize {
      linux_options {
        host_name = "cloud-init-testing02"
        domain    = ""
      }
      network_interface {
        ipv4_address = "192.168.144.12"
        ipv4_netmask = 24
      }
      ipv4_gateway = "192.168.144.1"
      dns_server_list = [var.dns_list]
    }
  }
  # NB this extra_config data ends-up inside the VM .vmx file and will be
  #    exposed by cloud-init-vmware-guestinfo as a cloud-init datasource.
  extra_config = {
    "guestinfo.userdata"          = base64encode(file("./userdata.yaml"))
    "guestinfo.userdata.encoding" = "base64"
  }
}

