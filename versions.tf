terraform {
  required_version = ">= 1.9.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.81.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9.1"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.6.2"
    }
  }
}