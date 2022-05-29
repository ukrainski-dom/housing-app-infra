# housing-app-infra

```shell
cd environments/prod
# create config files: backend.conf terraform.tfvars
terraform init -backend-config=backend.conf

# provision GKE
terraform plan -target="module.gke"
terraform apply -target="module.gke"

# deploy GKE services
terraform plan
terraform apply
```