output "vm_public_ip" {
  value = module.vm_setup.vm_public_ip
}

output "ssh_public_key" {
  value = module.vm_setup.ssh_public_key
}

output "ssh_private_key_name" {
  value = module.vm_setup.ssh_private_key_name
}

output "ssh_private_key_keyvault_name" {
  value = module.vm_setup.ssh_private_key_keyvault_name
}
