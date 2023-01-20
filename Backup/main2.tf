# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
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

locals {
  mime_types = jsondecode(file("${path.module}/mime.json"))
}

provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = "eastus2"

    tags = {
    Environment = "Terraform Getting Started"
    Team = "DevOps"
  }
}

# Create a storage account
resource "azurerm_storage_account" "sa"{
  name                     = var.storage_account_name
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
  name                  = "AppCode"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "Blob"
}

# Create storage blob for app deploy files
resource "azurerm_storage_blob" "appcode" {

  name                   = "${filesha256(var.archive_file.output_path)}.zip"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = "AppCode"
  type                   = "Block"
  access_tier = "Cool"
  source = var.archive_file.output_path
}

# Create a read-only SAS for appcode
data "azurerm_storage_account_blob_container_sas" "storage_account_blob_container_sas" {
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
  name                = var.cosmos_db_name 
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  enable_automatic_failover = false
  enable_free_tier = true
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
    name = var.cosmosdb_sql_name
    resource_group_name = azurerm_resource_group.rg.name
    account_name = azurerm_cosmosdb_account.db.name
}

# Create a container in CosmosDB Database above
resource "azurerm_cosmosdb_sql_container" "container" {
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

# Create a service plan for app
resource "azurerm_service_plan" "sp" {
  name                = var.app_service_plan_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_application_insights" "appinsights" {
  name                = var.app_insights_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  application_type    = "web"
}

resource "azurerm_linux_function_app" "fa" {
  name                = var.function_app_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  service_plan_id            = azurerm_service_plan.sp.id

  site_config {
    application_stack {
      python_version = "3.9"
    }
  }
}

resource "azurerm_function_app_function" "func" {
  name            = var.function_name
  function_app_id = azurerm_linux_function_app.fa.id
  language        = "Python"
  
  file {
    name    = "__init__.py"
    content = file("Function/__init__.py")
  }
  test_data = jsonencode({
    "name" : "Azure"
  })

  config_json = jsonencode({
  "scriptFile": "__init__.py",
  "bindings": [
    {
      "authLevel": "anonymous",
      "type": "httpTrigger",
      "direction": "in",
      "name": "req",
      "methods": [
        "get",
        "post"
      ]
    },
    {
      "type": "http",
      "direction": "out",
      "name": "$return"
    }
  ]
  })
}

