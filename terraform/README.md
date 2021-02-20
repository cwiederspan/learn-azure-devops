# Terraform IaC

## Setup

### Remote Terraform State

Assuming you want to use remote cloud storage for you Terraform state files,
create a file called **backend-secrets.tfvars**, and add information that looks like this:

```hcl
storage_account_name = "mystorageaccount"
container_name       = "learnazdo"
key                  = "state.tfstate"
access_key           = "access-key-from-azure-storage"
```

### Terraform Execution

```bash
az storage account create --resource-group myresourcegroup --name mystorageaccount

az storage container create --account-name mystorageaccount --name learnazdo --public-access off

terraform init -backend-config=backend-secrets.tfvars

terraform apply
```
