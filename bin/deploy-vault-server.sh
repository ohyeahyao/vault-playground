#!/bin/bash

execute_and_echo() {
  local command="$1"
  echo -e "\$ ${command}\n"
  eval ${command}
}

# Vault Server
deploy_vault_server() {
  VAULT_CHART_PATH="hashicorp/vault"
  VAULT_VALUES_FILE_PATH="${CURRENT_PATH}/vault-values.yaml"

  execute_and_echo "kubectl config use-context ${VAULT_SERVER_K8S_CONTEXT}"

  helm status $VAULT_RELEASE_NAME -n $VAULT_RELEASE_NAMESPACE >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    command="helm diff upgrade $VAULT_RELEASE_NAME $VAULT_CHART_PATH -n $VAULT_RELEASE_NAMESPACE -f $VAULT_VALUES_FILE_PATH"
    echo -e "\$ ${command}\n"
    DIFF_OUTPUT=$($command)
    # DIFF_OUTPUT="$(${command})"
    if [ -n "$DIFF_OUTPUT" ]; then
      echo "[Helm] Vault Server upgrading..."
      helm upgrade --install $VAULT_RELEASE_NAME $VAULT_CHART_PATH -n $VAULT_RELEASE_NAMESPACE -f $VAULT_VALUES_FILE_PATH
    else
      echo "[Helm] Vault Server nothing be changed."
    fi
  else
    echo "[Helm] Vault Server installing..."
    helm install $VAULT_RELEASE_NAME $VAULT_CHART_PATH -n $VAULT_RELEASE_NAMESPACE --create-namespace -f $VAULT_VALUES_FILE_PATH
  fi
}

# Vault Configuration using Terraform
update_vault_configuration() {
  vault_server_ip=""
  retry_count=10   # Total 10 attempts
  retry_interval=3 # Retry every 3 seconds

  echo ""
  echo "--------------- Update Vault Configuration ---------------"
  command="kubectl config use-context ${VAULT_SERVER_K8S_CONTEXT}"
  execute_and_echo "$command"
  for ((i = 0; i < $retry_count; i++)); do
    vault_server_ip=$(kubectl get svc "$VAULT_RELEASE_NAME-ui" -n $VAULT_RELEASE_NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -n "$vault_server_ip" ]; then
      echo "Vault IP: $vault_server_ip"
      break
    elif [ $i -eq $((retry_count - 1)) ]; then
      echo "Unable to retrieve Vault service IP, exceeded maximum retry attempts."
      exit 1
    else
      echo "Waiting for Vault service IP..."
      sleep $retry_interval
    fi
  done
  export VAULT_ADDR=http://${vault_server_ip}:8200
  export VAULT_TOKEN=root # default
  echo -e "Vault API Host: $VAULT_ADDR \n"

  ## fetch vault client's k8s context
  execute_and_echo "kubectl config use-context ${VAULT_CLIENT_K8S_CONTEXT}"

  if [ "$VAULT_CLIENT_K8S_CONTEXT" == "$VAULT_SERVER_K8S_CONTEXT" ]; then
    VAR_K8S_HOST=https://kubernetes.default.svc.cluster.local
  else
    VAR_K8S_HOST=$(kubectl cluster-info | grep 'Kubernetes control plane' | awk '/http/ {print $NF}' | sed 's/\x1b\[[0-9;]*m//g')
  fi

  echo -e "Vault Client K8S control plane Host: $VAR_K8S_HOST \n"

  execute_and_echo "terraform -chdir=${FOLDER_PATH_IAC} init"
  execute_and_echo "terraform -chdir=${FOLDER_PATH_IAC} apply -auto-approve -var k8s_host=${VAR_K8S_HOST} -var vault_client_k8s_context=${VAULT_CLIENT_K8S_CONTEXT}"
  ## Debug
  # terraform -chdir=${FOLDER_PATH_IAC} plan -var "K8S_HOST=${VAR_K8S_HOST}"
}

function handle_option_selection() {
  local option=$1

  case "$option" in
  1)
    echo -e "You chose: current cluster\n"
    read_current_cluster_context
    ;;

  2)
    echo -e "You chose: single cluster\n"
    read_single_cluster_context
    ;;
  3)
    echo -e "You chose: cross clusters\n"
    read_cross_clusters_contexts
    ;;
  *)
    echo -e "Invalid option, please choose again.\n"
    ;;
  esac
  echo "--------------- Your cluster context info ---------------"
  echo "vault Client context: $VAULT_CLIENT_K8S_CONTEXT"
  echo "vault Server context: $VAULT_SERVER_K8S_CONTEXT"
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
}

function read_current_cluster_context() {
  cluster_context=$(kubectl config current-context)
  VAULT_CLIENT_K8S_CONTEXT=$cluster_context
  VAULT_SERVER_K8S_CONTEXT=$cluster_context
}

function read_single_cluster_context() {
  echo "Please enter a context name for the single cluster:"
  read cluster_context
  VAULT_CLIENT_K8S_CONTEXT=$cluster_context
  VAULT_SERVER_K8S_CONTEXT=$cluster_context
}

function read_cross_clusters_contexts() {
  echo "Please enter two context names for the cross clusters..."
  read -p "Input Your vault Server K8S context: " server_context
  read -p "Input Your vault Client K8S context: " client_context
  VAULT_CLIENT_K8S_CONTEXT=$client_context
  VAULT_SERVER_K8S_CONTEXT=$server_context
}

echo "Please select an option:"
options=("current cluster" "(custom) single cluster" "(custom) cross clusters")
select option in "${options[@]}"; do
  handle_option_selection "$REPLY"
  break
done

CURRENT_PATH="$PWD"
FOLDER_PATH_IAC="${CURRENT_PATH}/vault-server"
VAULT_RELEASE_NAME="vault"
VAULT_RELEASE_NAMESPACE="vault"

# # Call functions
deploy_vault_server
update_vault_configuration
