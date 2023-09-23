terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~>1.5"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
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

provider "azapi" {
  tenant_id       = "__tenantId__"
  subscription_id = "__subscriptionId__"
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

module "vm_setup" {
  source                          = "./../../../../terraform-modules/azure/virtualmachine"
  tenant_id                       = "__tenantId__"
  resource_group_name             = azurerm_resource_group.environment_resource_group.name
  resource_group_location         = azurerm_resource_group.environment_resource_group.location
  resource_group_id               = azurerm_resource_group.environment_resource_group.id
  vm_publisher                    = "__virtualMachineOSDistribution__"
  vm_offer                        = "__virtualMachineOSOffer__"
  vm_sku                          = "__virtualMachineOSSku__"
  vm_name                         = "__deploymentPrefix__-vm"
  vm_size                         = "__virtualMachineSize__"
  admin_name                      = "__adminUserName__"
  create_ssh_key                  = "__CreateSSHKey__"
  keyvault_access_group_object_id = "__sshKeyvaultAccessGroupId__"
  vm_storage_account_type         = "__storageAccountType__"
  vm_version                      = "latest"
  vm_private_ip                   = "10.10.1.15"
  vnet_address_space              = "10.10.0.0/16"
  vm_subnet_address_prefix        = "10.10.1.0/24"
  enable_public_ip                = "__PublicIPEnabled__"
  pubip_sku                       = "__PublicIpSku__"
  pubip_allocation_method         = "__PublicIPAllocationMethod__"
  privateip_allocation_method     = "__PrivateIPAllocationMethod__"
  nsgrules                        = local.nsg_rules
  tags                            = local.tags
}
