
terraform {
  required_version = ">= 1.7.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4"
    }
  }
}
