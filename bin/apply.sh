#!/bin/bash

CURRENT_PATH="$PWD"
FOLDER_PATH_IAC="${CURRENT_PATH}/iac"

# Vault Server
deploy_vault_server() {
  VAULT_RELEASE_NAME="vault"
  VAULT_RELEASE_NAMESPACE="vault"
  VAULT_CHART_PATH="hashicorp/vault"
  VAULT_VALUES_FILE_PATH="${CURRENT_PATH}/vault-values.yaml"

  helm status $VAULT_RELEASE_NAME -n $VAULT_RELEASE_NAMESPACE > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    DIFF_OUTPUT=$(helm diff upgrade $VAULT_RELEASE_NAME $VAULT_CHART_PATH -n $VAULT_RELEASE_NAMESPACE -f $VAULT_VALUES_FILE_PATH)
    if [ -n "$DIFF_OUTPUT" ]; then
        echo "vault upgrading..."
        helm upgrade --install $VAULT_RELEASE_NAME $VAULT_CHART_PATH -n $VAULT_RELEASE_NAMESPACE -f $VAULT_VALUES_FILE_PATH
    else
        echo "Vault server helm nothing be changed."
    fi
  else
    echo "vault installing..."
    helm install $VAULT_RELEASE_NAME $VAULT_CHART_PATH -n $VAULT_RELEASE_NAMESPACE --create-namespace -f $VAULT_VALUES_FILE_PATH
  fi
}

# Vault Secret Operator
depoly_vso(){
  OPERATOR_RELEASE_NAME="vault-secrets-operator"
  OPERATOR_RELEASE_NAMESPACE="vault-secrets-operator-system"
  OPERATOR_CHART_PATH="hashicorp/vault-secrets-operator"
  OPERATOR_VALUES_FILE_PATH="${CURRENT_PATH}/client-end/vault-operator-values.yaml"

  helm status $OPERATOR_RELEASE_NAME -n $OPERATOR_RELEASE_NAMESPACE  > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    DIFF_OUTPUT=$(helm diff upgrade $OPERATOR_RELEASE_NAME $OPERATOR_CHART_PATH -n $OPERATOR_RELEASE_NAMESPACE -f $OPERATOR_VALUES_FILE_PATH)
    if [ -n "$DIFF_OUTPUT" ]; then
        echo "vault secret operator upgrading..."
        helm upgrade $OPERATOR_RELEASE_NAME $OPERATOR_CHART_PATH -n $OPERATOR_RELEASE_NAMESPACE  -f $OPERATOR_VALUES_FILE_PATH
    else
        echo "helm vault secret operator nothing be changed."
    fi
  else
    echo "vault secret operator installing..."
    helm install $OPERATOR_RELEASE_NAME $OPERATOR_CHART_PATH -n $OPERATOR_RELEASE_NAMESPACE --create-namespace -f $OPERATOR_VALUES_FILE_PATH
  fi

}

create_namespace_if_not_exists() {
  # Vault App Namespace
  if kubectl get namespace app > /dev/null 2>&1; then
      echo "Namespace 'app' already exists."
  else
      echo "Namespace 'app' does not exist. Creating..."
      kubectl create namespace app
  fi
}

# Vault Operator's Auth
deploy_client_end(){
  CLIENT_END_AUTH_PATH="${CURRENT_PATH}/client-end/auth"
  kubectl apply -f $CLIENT_END_AUTH_PATH
}

# Vault Configuration using Terraform
update_vault_configuartion(){
  vault_server_ip=""
  retry_count=10   # Total 10 attempts
  retry_interval=3 # Retry every 3 seconds

  for ((i=0; i<$retry_count; i++)); do
      vault_server_ip=$(kubectl get svc "$VAULT_RELEASE_NAME-ui" -n $VAULT_RELEASE_NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
      if [ -n "$vault_server_ip" ]; then
          echo "Vault IP: $vault_server_ip"
          break
      elif [ $i -eq $((retry_count-1)) ]; then
          echo "Unable to retrieve Vault service IP, exceeded maximum retry attempts."
          exit 1
      else
          echo "Waiting for Vault service IP..."
          sleep $retry_interval
      fi
  done
  
  export VAULT_ADDR=http://${vault_server_ip}:8200
  export VAULT_TOKEN=root # default

  K8S_API_IP=$(kubectl get svc kubernetes -n default -o jsonpath='{.spec.clusterIP}')
  export K8S_HOST="https://$K8S_API_IP:443"
  terraform -chdir=${FOLDER_PATH_IAC} init
  # terraform -chdir=${FOLDER_PATH_IAC} plan -var "K8S_HOST=${K8S_HOST}"
  terraform -chdir=${FOLDER_PATH_IAC} apply -auto-approve -var k8s_host=${K8S_HOST}
}


# Call functions
deploy_vault_server
depoly_vso
create_namespace_if_not_exists
deploy_client_end
update_vault_configuartion