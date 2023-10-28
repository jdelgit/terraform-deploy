output "secrets_provider_secret_identity" {
  value = module.k8scluster.secrets_provider_secret_identity
}

output "groups" {
  value = module.cluster_groups.group_ids
}

output "vm_ip" {
  value =length(module.vm_setup) > 0 ? module.vm_setup[0].vm_public_ip : null
}

output "keyvault_data" {
  value = module.keyvault
}

output "tenant_id" {
  value = var.tenant_id
}

output "private_key_name" {
  value = module.ssh_key.private_key_name
}
