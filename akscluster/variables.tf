variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "Subscription where resources should be deployed"
  type        = string
}

variable "deployment_prefix" {
  description = "Descriptive prefix for all resource names"
  type        = string
}

variable "deployment_location" {
  description = "Geographic location for deployments"
  type        = string
}

variable "keyvault" {
  description = "Group ID allowed to access keyvault"
  type = object({
    namespaces                    = list(string)
    create_private_dns_zone       = bool
    public_network_access_enabled = bool
    access_policies = list(object({
      name                          = string
      access_policy_group_object_id = string
      key_permissions               = list(string)
      secret_permissions            = list(string)
      storage_permissions           = list(string)
      certificate_permissions       = list(string)
    }))
    network_acls = object({
      bypass         = string
      default_action = string
      ip_rules       = list(string)
    })
  })
}

variable "tags" {
  description = "Resource tags"
  type = object({
    environment = string
    projectCode = string
    invoiceCode = string
  })
}

variable "virtualnetwork" {
  description = "Virtualnetwork configuration"
  type = object({
    address_space = list(string)
    location      = string
  })
  default = {
    address_space = ["10.224.0.0/11"]
    location      = "westeurope"
  }
}

variable "cluster_user_groups" {
  description = "Data for the various groups used in the Infra and Cluster"
  type = object({
    name_prefix = string
    admins = object({
      name                       = string
    })
    operations = object({
      name                       = string
    })
    developers = object({
      name                       = string
    })
  })
}

variable "cluster" {
  description = "All cluster related information"
  type = object({
    kubernetes_version                          = string
    sku_tier                                    = string
    loadbalancer_sku                            = string
    private                                     = bool
    keyvault_secrets_management                 = bool
    vnet_integration_enabled                    = bool
    autoscale                                   = bool
    cluster_node_size                           = string
    cluster_node_os_disk_size_gb                = string
    cluster_node_enable_host_encryption         = bool
    initial_node_count                          = number
    min_node_count                              = number
    max_node_count                              = number
    zones                                       = list(string)
    run_command_enabled                         = bool
    azure_rbac_enabled                          = bool
    local_account_disabled                      = bool
    role_based_access_control_enabled           = bool
    oidc_issuer_enabled                         = bool
    workload_identity_enabled                   = bool
    keyvault_provider_secrets_rotation_enabled  = bool
    keyvault_provider_secrets_rotation_interval = string
    enable_azure_blob_storage                   = bool
    enable_azure_disk_storage                   = bool
    enable_azure_file_storage                   = bool
    azure_disk_driver_version                   = string
    network = object({
      subnet_name          = string
      subnet_address_space = list(string)
      service_endpoints    = list(string)
      allowed_access_ip    = string
      nsgrules = list(object({
        name                       = string
        priority                   = number
        direction                  = string
        access                     = string
        protocol                   = string
        source_port_range          = string
        destination_port_ranges    = list(string)
        source_address_prefix      = string
        destination_address_prefix = string
      }))
    })
  })
}


variable "bastion" {
  description = "Bastion related settings"
  type = object({
    enabled                 = bool
    publisher               = string
    offer                   = string
    sku                     = string
    size                    = string
    storage_type            = string
    admin_username          = string
    create_public_ip        = bool
    create_network          = bool
    pubip_allocation_method = string
    private_ip_allocation   = string
    ssh_kp_keyvault = object({
      keyvault_name       = string
      resource_group_name = string
    })
    network = object({
      subnet_name          = string
      subnet_address_space = list(string)
      service_endpoints    = list(string)
      nsgrules = list(object({
        name                       = string
        priority                   = number
        direction                  = string
        access                     = string
        protocol                   = string
        source_port_range          = string
        destination_port_ranges    = list(string)
        source_address_prefix      = string
        destination_address_prefix = string
      }))
    })
  })
  default = {
    enabled                 = false
    publisher               = "Debian"
    offer                   = "debian-11"
    sku                     = "11"
    size                    = "Standard_D2_v2"
    storage_type            = "Standard_LRS"
    create_public_ip        = true
    create_network          = false
    admin_username          = "admin"
    private_ip_allocation   = "Dynamic"
    pubip_allocation_method = "Dynamic"
    ssh_kp_keyvault = {
      keyvault_name       = ""
      resource_group_name = ""
    }
    network = {
      subnet_name          = "AzureBastionVMSubnet"
      subnet_address_space = ["10.245.100.0/24"]
      service_endpoints    = [""]
      nsgrules = [
        {
          name                       = null
          priority                   = null
          direction                  = null
          access                     = null
          protocol                   = null
          source_port_range          = null
          destination_port_ranges    = null
          source_address_prefix      = null
          destination_address_prefix = null
        }
      ]
    }
  }
}
variable "acr" {
  description = "ACR related info"
  type = object({
    sku                     = string
    create_private_endpoint = bool
    create_private_dns_zone = bool
  })
}

