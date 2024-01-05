
execute_and_echo() {
    local command="$1"
    echo -e "\$ ${command}\n"
    eval ${command}
}

init_context(){
  read -p "1) Input Your vault Client K8S context(default current-context): " client_context
  if [ -z "$client_context" ]; then
      VAULT_CLIENT_K8S_CONTEXT=$(kubectl config current-context)
  else
      VAULT_CLIENT_K8S_CONTEXT=$client_context
  fi

  echo -e "vault Client context: $VAULT_CLIENT_K8S_CONTEXT"

  while true; do
    read -p "Is the above information correct? (yes/no) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) echo "Operation cancelled."; exit;;
        * ) echo "Please enter yes or no.";;
    esac
  done

  execute_and_echo "kubectl config use-context ${VAULT_CLIENT_K8S_CONTEXT}"
}

init_context

execute_and_echo "helm upgrade --install web-app ./app/charts/web-app -f app/web-app/value.sit.yaml -n app"