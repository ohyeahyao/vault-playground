#!/bin/bash

execute_and_echo() {
  local command="$1"
  echo -e "\$ ${command}\n"
  eval ${command}
}

# Vault Secret Operator
depoly_vso() {
  OPERATOR_RELEASE_NAME="vault-secrets-operator"
  OPERATOR_RELEASE_NAMESPACE="vault-secrets-operator-system"
  OPERATOR_CHART_PATH="hashicorp/vault-secrets-operator"
  OPERATOR_VALUES_FILE_PATH="${CURRENT_PATH}/vault-client/vault-operator-values.yaml"

  var_vault_connection_addr="--set defaultVaultConnection.address=$VAULT_CONNECTION_ADDR"

  helm status $OPERATOR_RELEASE_NAME -n $OPERATOR_RELEASE_NAMESPACE >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    command="helm diff upgrade $OPERATOR_RELEASE_NAME $OPERATOR_CHART_PATH -n $OPERATOR_RELEASE_NAMESPACE -f $OPERATOR_VALUES_FILE_PATH $var_vault_connection_addr"
    DIFF_OUTPUT=$(execute_and_echo "${command}")
    if [ -n "$DIFF_OUTPUT" ]; then
      echo "[Helm] Vault Secret Operator upgrading..."
      helm upgrade $OPERATOR_RELEASE_NAME $OPERATOR_CHART_PATH -n $OPERATOR_RELEASE_NAMESPACE -f $OPERATOR_VALUES_FILE_PATH $var_vault_connection_addr
    else
      echo "[Helm] Vault Secret Operator nothing be changed."
    fi
  else
    echo "[Helm] Vault Secret Operator installing..."
    helm install $OPERATOR_RELEASE_NAME $OPERATOR_CHART_PATH -n $OPERATOR_RELEASE_NAMESPACE --create-namespace -f $OPERATOR_VALUES_FILE_PATH $var_vault_connection_addr
  fi

  ## Debug
  # helm upgrade --debug --dry-run $OPERATOR_RELEASE_NAME $OPERATOR_CHART_PATH -n $OPERATOR_RELEASE_NAMESPACE  -f $OPERATOR_VALUES_FILE_PATH $var_vault_connection_addr
}

create_namespace_if_not_exists() {
  # Vault App Namespace
  if kubectl get namespace app >/dev/null 2>&1; then
    echo "Namespace 'app' already exists."
  else
    echo "Namespace 'app' does not exist. Creating..."
    kubectl create namespace app
  fi
}

# Vault Operator's Auth
deploy_auth() {
  CLIENT_END_AUTH_PATH="${CURRENT_PATH}/vault-client/auth"
  kubectl apply -f $CLIENT_END_AUTH_PATH
}

init_context() {
  CURRENT_PATH="$PWD"
  VAULT_RELEASE_NAME="vault"
  VAULT_RELEASE_NAMESPACE="vault"

  read -p "1) Input Your vault Client K8S context(default current-context): " client_context
  if [ -z "$client_context" ]; then
    VAULT_CLIENT_K8S_CONTEXT=$(kubectl config current-context)
  else
    VAULT_CLIENT_K8S_CONTEXT=$client_context
  fi

  echo "2) Input vault Server Address"
  read -p "(default: http://vault.vault.svc.cluster.local:8200): " vault_server_addr
  VAULT_CONNECTION_ADDR=${vault_server_addr:-http://vault.vault.svc.cluster.local:8200}
  echo -e "\n--------------- Your cluster context info ---------------"
  echo -e "vault Client context: $VAULT_CLIENT_K8S_CONTEXT"
  echo -e "vault connection address: $VAULT_CONNECTION_ADDR\n"
  while true; do
    read -p "Is the above information correct? (yes/no) " yn
    case $yn in
    [Yy]*) break ;;
    [Nn]*)
      echo "Operation cancelled."
      exit
      ;;
    *) echo "Please enter yes or no." ;;
    esac
  done

  execute_and_echo "kubectl config use-context ${VAULT_CLIENT_K8S_CONTEXT}"
}

# Call functions
init_context
depoly_vso
create_namespace_if_not_exists
# deploy_auth
