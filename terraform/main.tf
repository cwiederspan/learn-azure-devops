provider "azurerm" {
  version = "=1.32.1"
}

terraform {
  required_version = ">= 0.12"

  backend "azurerm" {
    environment = "public"
  }
}

variable "name_prefix" { }

variable "name_base" { }

variable "name_suffix" { }

variable "location" { }

locals {
  base_name = "${var.name_prefix}-${var.name_base}-${var.name_suffix}"

  base_name_clean = "${var.name_prefix}${var.name_base}${var.name_suffix}"
}


# *** Start Resource Group *** #

resource "azurerm_resource_group" "group" {
  name     = "${local.base_name}-rg"
  location = var.location
}


# *** Start Azure Container Registry (ACR) *** #

resource "azurerm_container_registry" "acr" {
  name                = "${local.base_name_clean}acr"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  admin_enabled       = true
  sku                 = "Basic"
}


# *** Start Application Insights *** #

resource "azurerm_application_insights" "insights" {
  name                = "${local.base_name}-ai"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  application_type    = "Web"
}


# *** Start App Service Plan *** #

resource "azurerm_app_service_plan" "plan" {
  name                = "${local.base_name}-plan"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S1"
  }
}


# *** Start App Service for the Production Web App *** #

resource "azurerm_app_service" "prod" {
  name                = "${local.base_name}-prod"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  app_service_plan_id = azurerm_app_service_plan.plan.id

  site_config {
    always_on        = true
    linux_fx_version = "DOCKER|${azurerm_container_registry.acr.name}.azurecr.io/mywebapp:latest"
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    DOCKER_REGISTRY_SERVER_URL          = "https://${azurerm_container_registry.acr.name}.azurecr.io"
    # DOCKER_CUSTOM_IMAGE_NAME            = "https://${azurerm_container_registry.acr.name}.azurecr.io/mywebapp:latest"
    DOCKER_REGISTRY_SERVER_USERNAME     = azurerm_container_registry.acr.name
    DOCKER_REGISTRY_SERVER_PASSWORD     = azurerm_container_registry.acr.admin_password
  }

  lifecycle {
    ignore_changes = [
      # app_settings.DOCKER_CUSTOM_IMAGE_NAME,
      site_config.0.linux_fx_version,
      site_config.0.scm_type
    ]
  }
}


# *** Start App Service for the Staging Web App *** #

resource "azurerm_app_service" "stage" {
  name                = "${local.base_name}-stage"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  app_service_plan_id = azurerm_app_service_plan.plan.id

  site_config {
    always_on        = true
    linux_fx_version = "DOCKER|${azurerm_container_registry.acr.name}.azurecr.io/mywebapp:latest"
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    DOCKER_REGISTRY_SERVER_URL          = "https://${azurerm_container_registry.acr.name}.azurecr.io"
    # DOCKER_CUSTOM_IMAGE_NAME            = "https://${azurerm_container_registry.acr.name}.azurecr.io/mywebapp:latest"
    DOCKER_REGISTRY_SERVER_USERNAME     = azurerm_container_registry.acr.name
    DOCKER_REGISTRY_SERVER_PASSWORD     = azurerm_container_registry.acr.admin_password
  }

  lifecycle {
    ignore_changes = [
      # app_settings.DOCKER_CUSTOM_IMAGE_NAME,
      site_config.0.linux_fx_version,
      site_config.0.scm_type
    ]
  }
}