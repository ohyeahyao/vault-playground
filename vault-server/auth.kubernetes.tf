resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = "single-k8s-cluster-auth-mount"
}

resource "vault_kubernetes_auth_backend_config" "single-k8s-cluster-config" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = var.k8s_host
  disable_iss_validation = true
  disable_local_ca_jwt   = true
  kubernetes_ca_cert     = kubernetes_secret.vault-auth-secret.data["ca.crt"]
  token_reviewer_jwt     = kubernetes_secret.vault-auth-secret.data["token"]
}

resource "vault_kubernetes_auth_backend_role" "single-k8s-cluster-role" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "vso-auth-role"
  bound_service_account_names      = ["vault-auth-service-account"]
  bound_service_account_namespaces = ["app"]
  token_ttl                        = 3600
  token_policies                   = ["admins", "base-policy", "developer-policy"]
  audience                         = "vault"
}
