# Create admin policy in the root namespace
resource "vault_policy" "admin-policy" {
  name   = "admins"
  policy = file("policies/admin-policy.hcl")
}

resource "vault_policy" "base-policy" {
  name   = "base-policy"
  policy = file("policies/base-policy.hcl")
}

resource "vault_policy" "developer-policy" {
  name   = "developer-policy"
  policy = file("policies/developer-policy.hcl")
}
