# Use Vault provider
provider "vault" {
  # It is strongly recommended to configure this provider through the
  # environment variables:
  #    - VAULT_ADDR
  #    - VAULT_TOKEN
  #    - VAULT_CACERT
  #    - VAULT_CAPATH
  #    - etc.  
}

terraform {
  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "~> 0.5"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = var.vault_client_k8s_context
}
