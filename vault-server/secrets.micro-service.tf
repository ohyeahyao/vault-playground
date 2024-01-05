# Enable K/V v2 secrets engine at 'micro-service'
resource "vault_mount" "micro-service" {
  path = "micro-service"
  type = "kv-v2"
}

data "sops_file" "demo-secret" {
  source_file = "./secrets/web-app.json"
}

resource "vault_kv_secret_v2" "micro-service-secret" {
  mount               = vault_mount.micro-service.path
  name                = "web-app"
  cas                 = 1
  delete_all_versions = true
  data_json           = jsonencode(data.sops_file.demo-secret.data)
  custom_metadata {
    max_versions = 5
    data = {
      app = "wep-app",
    }
  }
}
