tenant_id       = "__tenant_id__"
subscription_id = "__subscription_id__"

deployment_location = "__location__"
deployment_prefix   = "__deployment_prefix__"

tags = {
  environment = "prod"
  projectCode = "__project_code__"
  invoiceCode = "__invoice_code__"
}

keyvault = {
  namespaces                    = ["default"]
  create_private_dns_zone       = true
  public_network_access_enabled = true
  access_policies = [
    {
      name                          = "default"
      access_policy_group_object_id = "__keyvault_access_aad_group_id__"
      key_permissions               = ["Get", "List", "Create", "Update"]
      secret_permissions            = ["Get", "List", "Set"]
      storage_permissions           = ["Get", "List", "Update"]
      certificate_permissions       = ["Get", "List", "Create", "Update"]
    }
  ]
  network_acls = {
    bypass         = "None"
    default_action = "Deny"
    ip_rules       = ["__allowed_public_cidr__"]
  }
}

virtualnetwork = {
  address_space = ["10.224.0.0/16", "10.10.0.0/16"]
  location      = "westeurope"
}

acr = {
  sku                     = "Standard" # Standard / Premium
  create_private_endpoint = false      # Only possible with Premium sku
  create_private_dns_zone = true
}

cluster_user_groups = {
  admins = {
    name                       = "prod-cluster-admins"
    description                = "Admins with full access to cluster, present in Dev & Prod"
    security_enabled           = true
    types                      = null
    assignable_to_role         = true
    mail_enabled               = false
    dynamic_membership_enabled = false
    dynamic_membership_rule    = ""
    owners                     = ["__group_owner__"]
    members                    = []
  }
  operations = {
    name                       = "prod-cluster-ops"
    description                = "Operation can execute basic debug commands, present in Dev & Prod"
    security_enabled           = true
    types                      = null
    assignable_to_role         = true
    mail_enabled               = false
    dynamic_membership_enabled = false
    dynamic_membership_rule    = ""
    owners                     = ["__group_owner__"]
    members                    = []
  }
  developers = {
    name                       = "prod-cluster-devs"
    description                = "Allow for deploying apps, not present in Prod"
    security_enabled           = true
    types                      = null
    assignable_to_role         = true
    mail_enabled               = false
    dynamic_membership_enabled = false
    dynamic_membership_rule    = ""
    owners                     = ["__group_owner__"]
    members                    = []
  }
}

cluster = {
  private                                     = true
  keyvault_secrets_management                 = true
  kubernetes_version                          = "1.27.3"
  sku_tier                                    = "Free"
  loadbalancer_sku                            = "standard"
  vnet_integration_enabled                    = false
  autoscale                                   = true
  cluster_node_size                           = "Standard_DS2_v2"
  cluster_node_os_disk_size_gb                = "100"
  cluster_node_enable_host_encryption         = true
  initial_node_count                          = 2
  min_node_count                              = 2
  max_node_count                              = 4
  zones                                       = null
  keyvault_provider_secrets_rotation_enabled  = false
  keyvault_provider_secrets_rotation_interval = null
  run_command_enabled                         = false
  azure_rbac_enabled                          = false
  local_account_disabled                      = false
  role_based_access_control_enabled           = true
  oidc_issuer_enabled                         = true
  workload_identity_enabled                   = true
  enable_azure_blob_storage                   = true
  enable_azure_disk_storage                   = true
  enable_azure_file_storage                   = true
  azure_disk_driver_version                   = "v1"
  network = {
    subnet_name          = "AzureAKSClusterSubnet"
    subnet_address_space = ["10.224.0.0/16"]
    service_endpoints    = ["Microsoft.KeyVault"]
    allowed_access_ip    = "__allowed_public_cidr__"
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

bastion = {
  enabled        = true
  publisher      = "Debian"
  offer          = "debian-11"
  sku            = "11"
  size           = "Standard_D2_v2"
  storage_type   = "Premium_LRS"
  admin_username = "__admin_username__"
  ssh_kp_keyvault = {
    keyvault_name       = "__admin_sshkey_keyvault_name__"
    resource_group_name = "__admin_sshkey_keyvault_group_name__"
  }
  create_public_ip        = false
  create_network          = false
  private_ip_allocation   = "Static"
  pubip_allocation_method = "Static"
  network = {
    subnet_name          = "AzureBastionVMSubnet"
    subnet_address_space = ["10.10.100.0/24"]
    service_endpoints    = null
    nsgrules = [
      {
        name                       = "AllowAdmin"
        priority                   = 105
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["22"]
        source_address_prefix      = "__allowed_public_cidr__"
        destination_address_prefix = "*"
      }
  ] }
}

