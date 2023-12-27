resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = "single-k8s-cluster-auth-mount"
}

resource "vault_kubernetes_auth_backend_config" "single-k8s-cluster-config" {
  backend         = vault_auth_backend.kubernetes.path
  kubernetes_host = var.k8s_host
}

resource "vault_kubernetes_auth_backend_role" "single-k8s-cluster-role" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "vso-auth-role"
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = ["app"]
  token_ttl                        = 3600
  token_policies                   = ["admins", "base-policy"]
  audience                         = "vault"
}
