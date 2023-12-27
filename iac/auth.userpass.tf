resource "vault_auth_backend" "userpass" {
  type = "userpass"
}

resource "vault_generic_endpoint" "devops" {
  depends_on           = [vault_auth_backend.userpass]
  path                 = "auth/userpass/users/devops"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": ["admins", "base-policy", "developer-policy"],
  "password": "changeme"
}
EOT
}
