# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.1.0"
  cloud {
    organization = "ZachChism"
    workspaces {
      name = "Terraform"
    }
  }
}

data "azurerm_client_config" "current" {}

locals {
  mime_types = jsondecode(file("${path.module}/mime.json"))
}

provider "azurerm" {
  alias = "dev"

  subscription_id = var.dev_sub_id
  //tenant_id       = var.dev_tenant_id
  //client_id       = var.dev_client_id
  //client_secret   = var.dev_client_secret
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false  
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }

  }
}

provider "azurerm" {
  alias = "prod"

  subscription_id = var.prod_sub_id
  //tenant_id       = var.prod_tenant_id
  //client_id       = var.prod_client_id
  //client_secret   = var.prod_client_secret
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false  
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }

  }
}

provider "azurerm" {
  features {}
}

provider "github" {}

data "archive_file" "file_fa" {
  type        = "zip"
  //source_dir  = "${path.module}/Function"
  source_dir = "${data.null_data_source.wait_for_python_exec.outputs["source_dir"]}"
  output_path = "${path.module}/Files/function-app.zip"
  excludes = [ "${path.module}/Function//webapp/pyfile.py" ]
}

data "null_data_source" "wait_for_python_exec"{
  inputs ={
  python_id = "${null_resource.Python_secret_inject.id}"

  source_dir = "${path.module}/Function"
  }
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  provider = azurerm.dev
  name     = "${var.env_name}_${var.resource_group_name}"
  location = "eastus2"

    tags = {
    Environment = "Terraform Getting Started"
    Team = "DevOps"
  }
}

# Create a storage account
resource "azurerm_storage_account" "sa"{
  provider = azurerm.dev
  name                     = "${var.env_name}${var.storage_account_name}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind = "StorageV2"
  access_tier = "Cool"
  large_file_share_enabled = false

  static_website {
    index_document = "_index.html"
    error_404_document = "404.html"
  }

  tags = {
    environment = "Production"
  }   
}

# Create static website storage container/associated files
resource "azurerm_storage_blob" "blob" {
  for_each = fileset(path.module, "Static/*")
  provider = azurerm.dev
  name                   = trim(each.key, "Static/")
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = "$web"
  type                   = "Block"
  access_tier = "Cool"
  source = each.key
  content_type = lookup(local.mime_types, regex("\\.[^.]+$", each.value), null)
}

# Create a new container for appcode
resource "azurerm_storage_container" "appContainer" {
  provider = azurerm.dev
  name                  = "appcode"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "blob"
}

# Create storage blob for app deploy files
resource "azurerm_storage_blob" "appcode" {
  provider = azurerm.dev
  name                   = "${filesha256(data.archive_file.file_fa.output_path)}.zip"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = "appcode"
  type                   = "Block"
  access_tier = "Cool"
  source = data.archive_file.file_fa.output_path
  depends_on = [
    null_resource.Python_secret_inject
  ]
}

# Create a read-only SAS for appcode
data "azurerm_storage_account_blob_container_sas" "storage_account_blob_container_sas2" {
  connection_string = azurerm_storage_account.sa.primary_connection_string
  container_name    = azurerm_storage_container.appContainer.name

  start = "2023-01-01T00:00:00Z"
  expiry = "2024-01-01T00:00:00Z"

  permissions {
    read   = true
    add    = false
    create = false
    write  = false
    delete = false
    list   = false
  }
}

# Create a CosmosDB Account
resource "azurerm_cosmosdb_account" "db" {
  provider = azurerm.dev
  name                = "${var.env_name}-${var.cosmos_db_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  enable_automatic_failover = false
  enable_free_tier = false
  public_network_access_enabled = true
  is_virtual_network_filter_enabled = false
  analytical_storage_enabled = false
  local_authentication_disabled = false


  capabilities {
    name = "EnableServerless"
  }

  consistency_policy {
    consistency_level       = "Session"
  }

  geo_location {
    location          = "westus"
    failover_priority = 0
    zone_redundant = false
  }
  backup {
    type = "Continuous"
  }
  ip_range_filter = "73.148.169.31,104.42.195.92,40.76.54.131,52.176.6.30,52.169.50.45,52.187.184.26,0.0.0.0"
}

# Create a CosmosDB Database
resource "azurerm_cosmosdb_sql_database" "sql" {
  provider = azurerm.dev
  name = var.cosmosdb_sql_name
  resource_group_name = azurerm_resource_group.rg.name
  account_name = azurerm_cosmosdb_account.db.name
}

# Create a container in CosmosDB Database above
resource "azurerm_cosmosdb_sql_container" "container" {
  provider = azurerm.dev
  name                  = var.cosmosdb_cont_name
  resource_group_name   = azurerm_resource_group.rg.name
  account_name          = azurerm_cosmosdb_account.db.name
  database_name         = azurerm_cosmosdb_sql_database.sql.name
  partition_key_path    = "/id"

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    included_path {
      path = "/included/?"
    }

    excluded_path {
      path = "/excluded/?"
    }
  }
}

# Create a service plan for
resource "azurerm_service_plan" "sp" {
  provider = azurerm.dev
  name                = "${var.env_name}_${var.app_service_plan_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_application_insights" "appinsight" {
  provider = azurerm.dev
  name                = "${var.env_name}_${var.app_insight_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "other"
  retention_in_days = 30
}

resource "azurerm_linux_function_app" "fa" {
  provider = azurerm.dev
  name                = "${var.env_name}-${var.function_app_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  service_plan_id            = azurerm_service_plan.sp.id
  
  app_settings = {
    //"WEBSITE_RUN_FROM_PACKAGE"    = "https://${azurerm_storage_account.sa.name}.blob.core.windows.net/${azurerm_storage_container.appContainer.name}/${azurerm_storage_blob.appcode.name}${data.azurerm_storage_account_blob_container_sas.storage_account_blob_container_sas2.sas}",
    //"FUNCTIONS_WORKER_RUNTIME" = "python",
    //"AzureWebJobsDisableHomepage" = "true",
    "CosmosDBConnection"          = "AccountEndpoint=${azurerm_cosmosdb_account.db.endpoint};AccountKey=${azurerm_cosmosdb_account.db.primary_key};"
    "CosmosDbConnectionString"    = "AccountEndpoint=${azurerm_cosmosdb_account.db.endpoint};AccountKey=${azurerm_cosmosdb_account.db.primary_key};"
  }
  site_config {
    application_stack {
      python_version = 3.9
    }
    application_insights_connection_string = azurerm_application_insights.appinsight.connection_string
    application_insights_key = azurerm_application_insights.appinsight.instrumentation_key
  }
  identity {
    type = "SystemAssigned"
  }
  depends_on = [
    azurerm_application_insights.appinsight
  ]
}

resource "azurerm_key_vault" "kv" {
  provider = azurerm.dev
  name                        = "${var.env_name}-${var.keyvault_name}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

}

resource "azurerm_key_vault_access_policy" "kap" {
  provider = azurerm.dev
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = "${azurerm_linux_function_app.fa.identity.0.principal_id}"

  key_permissions = [
    "Get",
  ]

  secret_permissions = [
    "Get",
  ] 
}

resource "azurerm_key_vault_access_policy" "kap_Tenant" {
  provider = azurerm.dev
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get",
    "Delete",
    "Purge",
  ]

  secret_permissions = [
    "Get",
    "Set",
    "Delete",
    "Purge",
  ]
}

resource "azurerm_key_vault_secret" "ks" {
  provider = azurerm.dev
  name         = "cosmosdbprimary"
  value        = azurerm_cosmosdb_account.db.primary_key
  key_vault_id = azurerm_key_vault.kv.id
  depends_on = [
    azurerm_key_vault_access_policy.kap_Tenant
  ]
}

resource "null_resource" "Python_secret_inject" {
  provisioner "local-exec" {
    command = <<EOT
    $content = Get-Content -Path './Function/webapp/pyfile.py'
    $newcontent = $content -replace 'key = ''','key = ''${azurerm_key_vault_secret.ks.value}' -replace 'endpoint = ''', 'endpoint = ''${azurerm_cosmosdb_account.db.endpoint}'
    $newContent | Set-Content -Path './Function/webapp/__init__.py'
    exit
    EOT
    interpreter = ["PowerShell", "-Command"]
  }
  depends_on = [
    azurerm_key_vault_secret.ks,
    //local.publish_code_command
  ]
  triggers = {
    //python_code = local.publish_code_command
    always_run = "${timestamp()}"
  }
}

resource "null_resource" "pip" {
  triggers = {
    requirements_md5 = "${filemd5("${path.module}/Function/requirements.txt")}"
  }
  provisioner "local-exec" {    
    command = "pip install --target='.python_packages/lib/site-packages' -r requirements.txt"
    working_dir = "${path.module}/Function"
  }
  depends_on = [
    null_resource.Python_secret_inject
  ]
}


resource "null_resource" "Python_secret_remove" {
  provisioner "local-exec" {
    command = <<EOT
    Start-Sleep -Seconds 2
    Remove-Item -Path './Function/webapp/__init__.py'
    EOT
    interpreter = ["PowerShell", "-Command"]
  }
  depends_on = [
    azurerm_storage_blob.appcode,
    null_resource.Python_secret_inject
    //local.publish_code_command
  ]
  triggers = {
    //python_code = local.publish_code_command
    always_run = "${timestamp()}"
  }
}


locals {
    publish_code_command = "az functionapp deployment source config-zip --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_linux_function_app.fa.name} --src ${data.archive_file.file_fa.output_path} --build-remote true"
    python_code_secret_inject = "pwsh -file ./Python_code.ps1"
}

resource "github_actions_secret" "github_ac_secret" {
  repository       = "Cloud-Resume-Project"
  secret_name      = "KeyVaultCosmosString"
  plaintext_value  = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.kv.name};SecretName=${azurerm_key_vault_secret.ks.name})"
}