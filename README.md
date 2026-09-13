https://registry.terraform.io/providers/hashicorp/aws/latest/docs


# Terraform AWS EKS Infrastructure

This project provisions an **Amazon EKS (Elastic Kubernetes Service) cluster** on AWS using **Terraform**.

The infrastructure is organized into reusable Terraform modules for the **VPC** and **EKS** components, with a separate **S3 remote backend** for Terraform state.

## Architecture

```text
                         AWS
                          │
                          ▼
                    ┌───────────┐
                    │    VPC    │
                    │  Module   │
                    └─────┬─────┘
                          │
                          ▼
                    ┌───────────┐
                    │    EKS    │
                    │  Module   │
                    └─────┬─────┘
                          │
                          ▼
                  ┌────────────────┐
                  │  EKS Cluster   │
                  │  + Node Group  │
                  └────────────────┘

Terraform State
      │
      ▼
┌──────────────────┐
│   Amazon S3      │
│ Remote Backend   │
└────────┬─────────┘
         │
         ▼
 Terraform State Lock
```

## Project Structure

```text
.
├── backend/
│   ├── .terraform/
│   ├── .terraform.lock.hcl
│   ├── main.tf
│   ├── terraform.tfvars
│   └── terraform.tfstate*
│
├── modules/
│   ├── eks/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   │
│   └── vpc/
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
│
├── main.tf
├── outputs.tf
├── variables.tf
├── .gitignore
└── README.md
```

> `terraform.tfstate`, `.terraform/`, and other generated/local files should not be committed to Git.

## Prerequisites

Install/configure the following:

- AWS Account
- AWS CLI
- Terraform
- Git
- kubectl
- IAM permissions to create EKS, VPC, IAM, EC2 and related resources

Verify the installations:

```bash
terraform version
aws --version
kubectl version --client
git --version
```

## AWS Configuration

Configure your AWS credentials before running Terraform:

```bash
aws configure
```

Verify the active AWS identity:

```bash
aws sts get-caller-identity
```

Make sure the configured AWS user/role has sufficient permissions for the resources defined in this project.

## Remote Backend

Terraform state is stored remotely in an **Amazon S3 bucket**.

The backend configuration should contain values similar to:

```hcl
terraform {
  backend "s3" {
    bucket         = "<your-terraform-state-bucket>"
    key            = "terraform.tfstate"
    region         = "<your-aws-region>"
    encrypt        = true
    dynamodb_table = "<your-state-lock-table>"
  }
}
```

The S3 bucket and state-locking resource should exist before initializing the main Terraform configuration.

### Important

Do not commit AWS credentials, secrets, `.tfvars` files containing secrets, or Terraform state files to Git.

## Terraform Workflow

Run the commands from the project root.

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Format Terraform files

```bash
terraform fmt -recursive
```

### 3. Validate configuration

```bash
terraform validate
```

### 4. Review the execution plan

```bash
terraform plan
```

### 5. Create the infrastructure

```bash
terraform apply
```

Type:

```text
yes
```

when Terraform asks for confirmation.

### 6. View outputs

```bash
terraform output
```

## Configure kubectl for EKS

After the EKS cluster is created, update your local kubeconfig:

```bash
aws eks update-kubeconfig --region <your-aws-region> --name <your-cluster-name>
```

Check the cluster:

```bash
kubectl get nodes
```

You should see the worker nodes associated with your EKS cluster.

## Destroy Infrastructure

When the infrastructure is no longer required:

```bash
terraform destroy
```

> `terraform destroy` removes the AWS resources managed by this Terraform configuration. Use it carefully.

## Modules

### VPC Module

The `modules/vpc` directory contains reusable Terraform code for creating the networking layer.

Typical resources include:

- VPC
- Public/private subnets
- Internet/NAT gateways
- Route tables
- Availability zones

### EKS Module

The `modules/eks` directory contains the Kubernetes infrastructure.

Typical resources include:

- EKS cluster
- EKS node group
- IAM roles/policies
- Security configuration
- Worker nodes

The root `main.tf` connects the modules and passes required variables between them.

## Useful Commands

```bash
# Initialize
terraform init

# Format
terraform fmt -recursive

# Validate
terraform validate

# Check changes
terraform plan

# Apply changes
terraform apply

# Show state
terraform show

# List resources
terraform state list

# Show outputs
terraform output

# Destroy resources
terraform destroy
```

## Git Best Practices

Before pushing the project:

```bash
git status
git add .
git commit -m "Add Terraform EKS infrastructure"
git push
```

The `.gitignore` file prevents generated Terraform files, state files, editor files, logs, and local secrets from being committed.

## Security Notes

- Never commit AWS access keys or secret keys.
- Never commit Terraform state if it contains sensitive values.
- Keep `.tfvars` files containing secrets out of Git.
- Use IAM roles with least-privilege permissions.
- Enable encryption for remote Terraform state.
- Use state locking to prevent concurrent Terraform operations.

## Future Improvements

Possible improvements for this project:

- Add separate `dev`, `stage`, and `prod` environments.
- Use Terraform workspaces or environment-specific configurations.
- Add Kubernetes/Helm deployment resources.
- Add CI/CD with GitHub Actions.
- Add AWS Load Balancer Controller.
- Add monitoring with Prometheus and Grafana.
- Add autoscaling for EKS worker nodes.
- Store sensitive values in AWS Secrets Manager or SSM Parameter Store.

## Author

**Aman Kumar**

Terraform • AWS • EKS • Kubernetes • DevOps
