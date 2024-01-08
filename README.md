# Vault Startup Project

This project is focused on setting up and managing a Vault infrastructure within a Kubernetes Cluster. 
Below is the detailed documentation on the namespaces used, the setup instructions, and the tools involved in this project.

## Tools Used

- **Vault**: Used for managing secrets and protecting sensitive data.
- **Terraform**: An infrastructure as code software tool for building, changing, and versioning infrastructure.
- **SOPS**: Simple and flexible tool for managing secrets.
- **Kubernetes**: An open-source system for automating deployment, scaling, and management of containerized applications.

## Architecture
![vault architecture](https://github.com/ohyeahyao/vault-startup/assets/29635695/05be2380-2581-4463-a7ae-264f9bdc8e1c)


## Kubernetes Cluster Namespaces

This project utilizes several namespaces within the Kubernetes Cluster:

1. **Vault Server Namespace (`vault`)**: This namespace contains the vault server.
2. **Vault Secrets Operator Namespace (`vault-secrets-operator-system`)**: This namespace is dedicated to the Vault Secrets Operator.
3. **Application Namespace (`app`)**: The namespace used for application deployment and management.


## Installation and Setup

To install and set up the Vault infrastructure, along with the Auth configuration and SOPS integration, use the following command:

```bash
$ bash ./bin/deploy-vault-server.sh
```

## Deploy Vault Client

```bash
$ bash ./bin/deploy-vault-client.sh
```

## Deploy Web Application by Helm

```bash
$ bash ./bin/deploy-app.sh
```
