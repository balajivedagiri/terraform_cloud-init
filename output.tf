output "vsphere_datastore_cluster" {
  value = data.vsphere_datastore_cluster.datastore_cluster.id
}

#output "vsphere_compute_cluster" {
#  value = data.vsphere_compute_cluster.compute_cluster.id
#}

output "vsphere_folder" {
  value = data.vsphere_folder.folder.id
}

output "vsphere_network" {
  value = data.vsphere_network.network.id
}

output "vsphere_template_virtual_machine" {
  value = data.vsphere_virtual_machine.template.id
}

output "vsphere_resource_pool" {
  value = data.vsphere_resource_pool.pool.id
}
