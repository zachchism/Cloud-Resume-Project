variable "location" {
  description = "Name of the location where the resources will be provisioned"
  type = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type = string
}

variable "storage_account_name" {
  description = "Name of the storage account"
  type = string
}

variable "cosmos_db_name" {
  description = "Name of the Cosmos Account"
  type = string
}

variable "cosmosdb_sql_name" {
  description = "Name of the Cosmos DB"
  type = string
}

variable "cosmosdb_cont_name" {
  description = "Name of the Cosmos container"
  type = string
}

variable "app_service_plan_name" {
  description = "Name of the application service plan"
  type = string
}

variable "app_insights_name" {
  description = "Name of the application insights"
  default = "Prod"
}

variable "function_app_name" {
  description = "Name of the function app"
  type = string
}

variable "function_name" {
  description = "Name of the function"
  type = string
}

data "archive_file" "file_function_app" {
  type        = "zip"
  source_dir  = "../function-app"
  output_path = "function-app.zip"
}