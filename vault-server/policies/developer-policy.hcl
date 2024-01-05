# Permits CRUD operation on kv-v2
path "micro-service/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
