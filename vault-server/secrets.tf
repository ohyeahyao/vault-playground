# Enable Transit secrets engine at 'transit'
resource "vault_mount" "transit" {
  path = "demo-transit"
  type = "transit"
}

# Creating an encryption key named 'payment'
resource "vault_transit_secret_backend_key" "key" {
  depends_on       = [vault_mount.transit]
  backend          = vault_mount.transit.path
  name             = "vso-client-cache"
  deletion_allowed = true
}
