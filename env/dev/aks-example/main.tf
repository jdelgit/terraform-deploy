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

}

# resource "azurerm_resource_group" "environment_resource_group" {
#   name     = "__runtimeGroupName__"
#   location = "__location__"
#   tags     = local.tags
# }

# module "k8scluster" {
#   source                          = "./../../../../terraform-modules/azure/aks"
#   resource_group_name             = azurerm_resource_group.environment_resource_group.name
#   resource_group_location         = azurerm_resource_group.environment_resource_group.location
#   cluster_name                    = "__clusterName__"
#   cluster_admin_group_ids         = ["__clusterAdminGroupAADId__"]
#   cluster_dns_prefix              = "__clusterDnsPrefix__"
#   enable_auto_scaling             = "__clusterAutoScale__"
#   node_count                      = "__clusterNodeCount__"
#   min_count                       = "__clusterMinNodeCount__"
#   max_count                       = "__clusterMaxModeCount__"
#   private_cluster_enabled         = "__clusterPrivateNetwork__"
#   public_network_access_enabled   = "__clusterPubNetAccessEnabled__"
#   load_balancer_sku               = "__clusterLoadBalancerSku___"
#   cluster_sku_tier                = "__clusterSkuTier___"
#   api_server_authorized_ip_ranges = "__clusterAuthorizedIps__"
#   kubernetes_version              = "__clusterKubernetesVersion__"
#   tags                            = local.tags
# }
