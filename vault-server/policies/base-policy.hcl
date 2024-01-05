# Permits CRUD operation on kv-v2
path "micro-service/data/*" {
  capabilities = ["create", "read"]
}

# Encrypt data with 'payment' key
path "transit/encrypt/payment" {
  capabilities = ["update"]
}

# Decrypt data with 'payment' key
path "transit/decrypt/payment" {
  capabilities = ["update"]
}

# Read and list keys under transit secrets engine 
path "transit/*" {
  capabilities = ["read", "list"]
}

# List enabled secrets engines
path "secret/metadata/*" {
  capabilities = ["list"]
}