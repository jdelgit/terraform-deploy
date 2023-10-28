terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
  }
  backend "azurerm" {
  }
}

provider "azurerm" {
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

locals {
  deployment_name          = "${var.deployment_prefix}-${var.tags.environment}"
  stripped_deployment_name = replace("${local.deployment_name}", "-", "")
  groups_data = flatten([
    for group_name, group in var.cluster_user_groups :
    {
      name                       = group.name,
      owners                     = group.owners
      members                    = group.members
      description                = group.description,
      security_enabled           = group.security_enabled,
      mail_enabled               = group.mail_enabled,
      types                      = group.types,
      assignable_to_role         = group.assignable_to_role,
      dynamic_membership_enabled = group.dynamic_membership_enabled,
      dynamic_membership_rule    = group.dynamic_membership_rule
    } if((var.tags.environment == "prod" && (group_name == "admins" || group_name == "operations")) || (var.tags.environment == "dev"))
  ])
  group_ids = flatten([
    for group in module.cluster_groups.group_ids :
    group
  ])
  cluster = {
    name = "aks-${local.deployment_name}"
  }
}


resource "azurerm_resource_group" "deployment_rg" {
  name     = "rg-${local.deployment_name}"
  location = var.deployment_location
  tags     = var.tags
}

##########################################################################

# Networking
module "cluster_network" {
  source              = "./../../terraform-modules/azure/virtual_network"
  resource_group_name = azurerm_resource_group.deployment_rg.name
  location            = var.virtualnetwork.location
  vnet_name           = "${local.deployment_name}-vnet"
  address_space       = var.virtualnetwork.address_space
  tags                = var.tags

  subnets = [
    {
      name : var.cluster.network.subnet_name
      address_prefixes : var.cluster.network.subnet_address_space
      service_endpoints : var.cluster.network.service_endpoints
      private_endpoint_network_policies_enabled : true
    },
    {
      name : var.bastion.network.subnet_name
      address_prefixes : var.bastion.network.subnet_address_space
      service_endpoints : var.bastion.network.service_endpoints
      private_endpoint_network_policies_enabled : true
    }
  ]
}
data "azuread_client_config" "current" {}

resource "azurerm_role_assignment" "k8s_groups_admin" {
  scope                = module.k8scluster.aks_cluster_id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = module.cluster_groups.group_ids[var.cluster_user_groups.admins.name]
}

resource "azurerm_role_assignment" "k8s_groups_admin_user" {
  scope                = module.k8scluster.aks_cluster_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = module.cluster_groups.group_ids[var.cluster_user_groups.admins.name]
}

resource "azurerm_role_assignment" "k8s_groups_ops" {
  scope                = module.k8scluster.aks_cluster_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = module.cluster_groups.group_ids[var.cluster_user_groups.operations.name]
}

resource "azurerm_role_assignment" "k8s_groups_devs" {
  count                = var.tags.environment == "prod" ? 0 : 1
  scope                = module.k8scluster.aks_cluster_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = module.cluster_groups.group_ids[var.cluster_user_groups.developers.name]
}

module "cluster_groups" {
  source      = "../../terraform-modules/azure/aad_group"
  groups_data = local.groups_data
}

##########################################################################
# AKS cluster
module "k8scluster" {
  source                                      = "./../../terraform-modules/azure/aks"
  resource_group_name                         = azurerm_resource_group.deployment_rg.name
  location                                    = azurerm_resource_group.deployment_rg.location
  vnet_integration_enabled                    = var.cluster.vnet_integration_enabled
  cluster_name                                = local.cluster.name
  cluster_dns_prefix                          = "${local.deployment_name}-dns"
  cluster_admin_group_ids                     = [module.cluster_groups.group_ids[var.cluster_user_groups.admins.name]]
  enable_auto_scaling                         = var.cluster.autoscale
  default_node_size                           = var.cluster.cluster_node_size
  default_node_os_disk_size_gb                = var.cluster.cluster_node_os_disk_size_gb
  default_node_pool_node_count                = var.cluster.initial_node_count
  default_node_pool_min_count                 = var.cluster.min_node_count
  default_node_pool_max_count                 = var.cluster.max_node_count
  default_node_pool_enable_host_encryption    = var.cluster.cluster_node_enable_host_encryption
  oidc_issuer_enabled                         = var.cluster.oidc_issuer_enabled
  private_cluster_enabled                     = var.cluster.private
  load_balancer_sku                           = var.cluster.loadbalancer_sku
  cluster_sku_tier                            = var.cluster.sku_tier
  authorized_ip_ranges                        = [var.cluster.network.allowed_access_ip]
  local_account_disabled                      = var.cluster.local_account_disabled
  kubernetes_version                          = var.cluster.kubernetes_version
  cluster_azure_rbac_enabled                  = var.cluster.azure_rbac_enabled
  enable_azure_blob_storage                   = var.cluster.enable_azure_blob_storage
  enable_azure_disk_storage                   = var.cluster.enable_azure_disk_storage
  enable_azure_file_storage                   = var.cluster.enable_azure_file_storage
  azure_disk_driver_version                   = var.cluster.azure_disk_driver_version
  workload_identity_enabled                   = var.cluster.workload_identity_enabled
  keyvault_provider_secrets_rotation_enabled  = var.cluster.keyvault_provider_secrets_rotation_enabled
  keyvault_provider_secrets_rotation_interval = var.cluster.keyvault_provider_secrets_rotation_interval
  vnet_subnet_id                              = module.cluster_network.subnet_ids["AzureAKSClusterSubnet"] != null ? module.cluster_network.subnet_ids["AzureAKSClusterSubnet"] : null
  tags                                        = var.tags
}


##########################################################################
# VM subnet in private-cluster vnet

# Get data from existing keyvault
data "azurerm_key_vault" "ssh_keyvault" {
  name                = var.bastion.ssh_kp_keyvault.keyvault_name
  resource_group_name = var.bastion.ssh_kp_keyvault.resource_group_name
}

data "azurerm_resource_group" "ssh_keyvault" {
  name = var.bastion.ssh_kp_keyvault.resource_group_name
}

module "ssh_key" {
  count             = var.bastion.enabled == true ? 1 : 0
  source            = "./../../terraform-modules/azure/sshkey"
  ssh_key_name      = "${local.deployment_name}-kp"
  keyvault_store_id = data.azurerm_key_vault.ssh_keyvault.id
  location          = data.azurerm_key_vault.ssh_keyvault.location
  resource_group_id = data.azurerm_resource_group.ssh_keyvault.resource_group_id
}

# Only create VM in production environment
# Virtualmachine accessed by bastion
module "vm_setup" {
  count               = var.bastion.enabled == true ? 1 : 0
  source              = "./../../terraform-modules/azure/virtualmachine"
  vm_name             = "${local.deployment_name}-bastion-vm"
  resource_group_name = azurerm_resource_group.deployment_rg.name
  location            = azurerm_resource_group.deployment_rg.location
  resource_group_id   = azurerm_resource_group.deployment_rg.id
  vm_subnet_id        = module.cluster_network.subnet_ids[var.bastion.network.subnet_name]
  create_public_ip    = var.bastion.create_public_ip
  create_network      = var.bastion.create_network
  vm_publisher        = var.bastion.publisher
  vm_offer            = var.bastion.offer
  vm_sku              = var.bastion.sku
  vm_size             = var.bastion.size
  admin_ssh_data = [
    {
      username   = var.bastion.admin_username
      public_key = module.ssh_key.public_key
    }
  ]
  vm_storage_account_type     = var.bastion.storage_type
  vm_version                  = "latest"
  privateip_allocation_method = var.bastion.private_ip_allocation
  pubip_allocation_method     = var.bastion.pubip_allocation_method
  tags                        = var.tags
}

# Create bastion NSG only if VM is created
module "bastion_nsg" {
  count               = length(module.vm_setup) > 0 ? 1 : 0
  source              = "./../../terraform-modules/azure/network_security_group"
  nsg_name            = "${local.deployment_name}-bastion-nsg"
  resource_group_name = azurerm_resource_group.deployment_rg.name
  location            = azurerm_resource_group.deployment_rg.location
  nsgrules            = var.bastion.network.nsgrules
  subnets = [
    {
      name = var.bastion.network.subnet_name
      id   = module.cluster_network.subnet_ids[var.bastion.network.subnet_name]
    }
  ]
  tags = var.tags
}

resource "null_resource" "provision" {
  count = length(module.vm_setup) > 0 ? 1 : 0
  connection {
    type        = "ssh"
    user        = var.bastion.admin_ssh_data[0].username
    private_key = module.ssh_key.private_key
    host        = module.vm_setup[0].vm_public_ip
    port        = 22
  }

  provisioner "file" {
    source      = "scripts/script.sh"
    destination = "/tmp/script.sh"
  }

  provisioner "file" {
    source      = "manifests"
    destination = "/tmp/"
  }

  provisioner "remote-exec" {
    inline = ["chmod +x /tmp/script.sh", "/tmp/script.sh"]
  }

}

#########################################################################
# Keyvault resources
# One keyvault per namespace
module "keyvault" {
  for_each                      = { for namespace in var.keyvault.namespaces : namespace => namespace }
  source                        = "./../../terraform-modules/azure/keyvault"
  keyvault_name                 = "${local.deployment_name}-${each.value}-aks"
  keyvault_sku                  = "standard"
  location                      = azurerm_resource_group.deployment_rg.location
  resource_group_name           = azurerm_resource_group.deployment_rg.name
  public_network_access_enabled = var.keyvault.public_network_access_enabled
  tenant_id                     = var.tenant_id
  enabled_for_disk_encryption   = true
  access_policies = [
    {
      name                          = var.keyvault.access_policies[0].name
      access_policy_group_object_id = var.keyvault.access_policies[0].access_policy_group_object_id == null ? module.cluster_groups.group_ids[var.cluster_user_groups.admins.name] : var.keyvault.access_policies.access_policy_group_object_id
      key_permissions               = var.keyvault.access_policies[0].key_permissions
      secret_permissions            = var.keyvault.access_policies[0].secret_permissions
      storage_permissions           = var.keyvault.access_policies[0].storage_permissions
      certificate_permissions       = var.keyvault.access_policies[0].certificate_permissions
    }
  ]
  purge_protection_enabled                        = false
  soft_delete_retention_days                      = 7
  create_private_dns_zone                         = var.keyvault.create_private_dns_zone
  private_dns_zone_ids                            = null
  network_acls                                    = var.keyvault.network_acls
  virtual_network_subnet_ids                      = [module.cluster_network.subnet_ids[var.cluster.network.subnet_name]]
  private_endpoint_subnet_id                      = module.cluster_network.subnet_ids[var.bastion.network.subnet_name]
  create_managed_identity                         = true
  managed_identity_fed_credential_oidc_issuer_url = module.k8scluster.oidc_issuer_url
  managed_identity_fed_credential_audience        = ["api://AzureADTokenExchange"]
  managed_identity_fed_credential_subject         = "system:serviceaccount:${each.value}:workload-identity-sa"
  tags                                            = var.tags
}


#########################################################################
# Container registry resources
module "acr" {
  count                      = var.tags.environment == "prod" ? 1 : 0
  source                     = "./../../terraform-modules/azure/acr"
  acr_name                   = "${local.stripped_deployment_name}acr"
  acr_sku                    = var.acr.sku
  resource_group_name        = azurerm_resource_group.deployment_rg.name
  location                   = azurerm_resource_group.deployment_rg.location
  create_private_endpoint    = var.acr.create_private_endpoint
  create_private_dns_zone    = var.acr.create_private_dns_zone
  private_dns_zone_id        = null
  private_endpoint_subnet_id = module.cluster_network.subnet_ids[var.bastion.network.subnet_name]
  aks_cluster_id             = module.k8scluster.aks_cluster_id
  kublet_object_id           = module.k8scluster.kublet_object_id
  tags                       = var.tags
}


