terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "__tfStateResourceGroup__"
    storage_account_name = "__tfStateStorageAccName__"
    container_name       = "__tfStateContainer__"
    key                  = "__tfStateKey__"
    subscription_id      = "__subscriptionId__"
  }
}

provider "azurerm" {
  tenant_id       = "__tenantId__"
  subscription_id = "__subscriptionId__"
  features {}
}

locals {
  tags = {
    environment = "__env__"
    projectCode = "__projectCode__"
    invoiceCode = "__invoiceCode__"
  }

  nsg_rules = {
    name                       = "AllowAdmin"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "__allowSourceAccessPortRange__"
    destination_port_ranges    = "__allowDestinationAccessPorts__"
    source_address_prefixes    = "__allowSourceAccessIpsCidr__"
    destination_address_prefix = "__allowDestinationAccessIpCidr__"
  }
}

resource "azurerm_resource_group" "environment_resource_group" {
  name     = "__runtimeGroupName__"
  location = "__location__"
  tags     = local.tags
}

module "network_setup" {
  source                      = "./../../../../terraform-modules/azure/network"
  resource_group_name         = azurerm_resource_group.environment_resource_group.name
  resource_group_location     = azurerm_resource_group.environment_resource_group.location
  vnet_name                   = "__deploymentPrefix__-vnet"
  vnet_address_space          = "10.10.0.0/16"
  vm_subnet_name              = "__deploymentPrefix__-subnet"
  vm_subnet_address_prefix    = "10.10.1.0/24"
  network_security_group_name = "__deploymentPrefix__-nsg"
  nsgrules                    = local.nsg_rules
  tags                        = local.tags
}

module "vm_setup" {
  source                        = "./../../../../terraform-modules/azure/virtualmachine"
  resource_group_name           = azurerm_resource_group.environment_resource_group.name
  resource_group_location       = azurerm_resource_group.environment_resource_group.location
  vm_publisher                  = "__virtualMachineOSDistribution__"
  vm_offer                      = "__virtualMachineOSOffer__"
  vm_sku                        = "__virtualMachineOSSku__"
  vm_name                       = "__deploymentPrefix__-vm"
  vm_size                       = "__virtualMachineSize__"
  admin_name                    = "__adminUserName__"
  admin_pubkey                  = "__adminSSHKey__"
  vm_storage_account_type       = "__storageAccountType__"
  vm_version                    = "latest"
  nic_name                      = "__deploymentPrefix__-nic"
  vm_nic_config                 = "__deploymentPrefix__-nic-config"
  vm_private_ip                 = "10.10.1.15"
  vm_subnet_id                  = module.network_setup.vm_subnet_id
  enable_public_ip              = "__PublicIPEnabled__"
  pubip_sku                     = "__PublicIpSku__"
  pubip_allocation_method       = "__PublicIPAllocationMethod__"
  privateip_allocation_method   = "__PrivateIPAllocationMethod__"
  tags                          = local.tags
}
