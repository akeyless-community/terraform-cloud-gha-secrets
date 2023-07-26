terraform {
  required_providers {
    akeyless = {
      version = ">= 1.0.0"
      source  = "akeyless-community/akeyless"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }

  cloud {
    organization = "work-demos"

    workspaces {
      name = "terraform-cloud-gha-secrets"
    }
  }
}

# Configure the Akeyless Provider
provider "akeyless" {
  api_gateway_address = "https://api.akeyless.io"

  jwt_login {
    access_id = var.AKEYLESS_ACCESS_ID
    jwt       = var.AKEYLESS_AUTH_JWT
  }
}

# Configure the GitHub Provider
provider "github" {
  owner = "akeyless-community"
  token = var.GITHUB_TOKEN
}

variable "GITHUB_TOKEN" {
  type        = string
  description = "GitHub token with repo scope."
}

variable "AKEYLESS_ACCESS_ID" {
  type        = string
  description = "Access ID for the JWT Auth Method for Terraform cloud. Provided by Terraform Cloud through a terraform variable added to the workspace."
}

variable "GITHUB_REPO" {
  type        = string
  description = "GitHub org/repository full name. Provided by Terraform Cloud through a terraform variable added to the workspace."
}

variable "AKEYLESS_AUTH_JWT" {
  type        = string
  description = "Terraform Cloud Workload Identity JWT for authentication into Akeyless. Provided by Terraform Cloud through an agent pool and hooks."
}

variable "AKEYLESS_DYNAMIC_SECRET_FULL_PATH" {
  type        = string
  description = "Full path to the azure dynamic secret in Akeyless. Provided by Terraform Cloud through a terraform variable added to the workspace."
}

data "akeyless_dynamic_secret" "secret" {
  path = var.AKEYLESS_DYNAMIC_SECRET_FULL_PATH
}

output "github_repository" {
  value = var.GITHUB_REPO
}

output "akeyless_secret" {
  value     = data.akeyless_dynamic_secret.secret.value
  sensitive = true
}

output "akeyless_secret_json" {
  value     = jsondecode(jsondecode(data.akeyless_dynamic_secret.secret.value).secret)
  sensitive = true
}

resource "github_actions_secret" "subscription_id" {
  repository      = var.GITHUB_REPO
  secret_name     = "ARM_SUBSCRIPTION_ID"
  plaintext_value = "07f75d77-80cc-46a1-b821-22dc487c154e"
}


resource "github_actions_secret" "tenant_id" {
  repository      = var.GITHUB_REPO
  secret_name     = "ARM_TENANT_ID"
  plaintext_value = jsondecode(jsondecode(data.akeyless_dynamic_secret.secret.value).secret).tenantId
}

resource "github_actions_secret" "client_id" {
  repository      = var.GITHUB_REPO
  secret_name     = "ARM_CLIENT_ID"
  plaintext_value = jsondecode(jsondecode(data.akeyless_dynamic_secret.secret.value).secret).appId
}

resource "github_actions_secret" "client_secret" {
  repository      = var.GITHUB_REPO
  secret_name     = "ARM_CLIENT_SECRET"
  plaintext_value = jsondecode(jsondecode(data.akeyless_dynamic_secret.secret.value).secret).secretText
}
