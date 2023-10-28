output "tenant_id" {
  value = var.tenant_id
}

output "groups" {
  value = module.cluster_groups.group_ids
}

output "bastion_vm_ip" {
  value = length(module.vm_setup) > 0 ? module.vm_setup[0].vm_public_ip : null
}

output "keyvault_managed_id_data" {
  value = module.keyvault
}

output "admin_ssh_private_key_name" {
  value = length(module.ssh_key) > 0 ? module.ssh_key[0].private_key_name : null
}
