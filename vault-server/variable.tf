variable "k8s_host" {
  type    = string
  default = null
}

variable "vault_client_k8s_context" {
  type    = string
  default = "local-context"
}
