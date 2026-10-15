# Day 57: Terraform Variables, Outputs, Locals & Validation

## 1. Theoretical Foundation

Hardcoding IP addresses, instance types, and region names directly inside resource definitions creates brittle code.
Production Terraform architectures parameterize configurations using:
1. **Input Variables (`variable`)**: Dynamic parameters passed into modules from external callers or `.tfvars` files.
2. **Local Values (`locals`)**: Internal computed intermediate expressions used to keep code DRY (Don't Repeat Yourself).
3. **Outputs (`output`)**: Values exported from a module for consumption by other modules, CI/CD pipelines, or engineers.

---

## 2. Input Variables with Type Constraints & Validation

`variables.tf`:
```hcl
variable "aws_region" {
  type        = string
  description = "The target AWS region for deployment"
  default     = "ap-south-1"
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev, stage, prod)"

  # Enforce strict input validation
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "The environment variable must be one of: dev, stage, prod."
  }
}

variable "instance_count" {
  type        = number
  description = "Number of worker nodes to provision"
  default     = 2

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "db_password" {
  type        = string
  description = "Master database password"
  sensitive   = true # Prevents value from displaying in CLI logs or console output!
}
```

### Passing Variable Values
Order of precedence (highest to lowest):
1. CLI flag: `terraform apply -var="environment=prod"`
2. Environment variable: `export TF_VAR_environment=prod`
3. Variable definition file: `terraform.tfvars` or `*.auto.tfvars`
4. Default value in `variable` block.

---

## 3. Local Values (`locals`)

Use `locals` to compute standardized naming conventions, tags, or common expressions:

`locals.tf`:
```hcl
locals {
  name_prefix = "${var.environment}-payment-service"

  common_tags = {
    Project     = "FintechAPI"
    Environment = var.environment
    ManagedBy   = "Terraform"
    CreatedAt   = timestamp()
  }
}

# Consuming locals in resources:
resource "aws_security_group" "api_sg" {
  name   = "${local.name_prefix}-sg"
  vpc_id = aws_vpc.main.id
  tags   = local.common_tags
}
```

---

## 4. Outputs & the `sensitive` Flag

`outputs.tf`:
```hcl
output "vpc_id" {
  description = "The ID of the provisioned VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "database_connection_string" {
  description = "Internal database connection endpoint"
  value       = "postgres://${aws_db_instance.db.username}:${aws_db_instance.db.password}@${aws_db_instance.db.endpoint}"
  sensitive   = true # Masks output in terminal!
}
```

View sensitive output on demand:
```bash
terraform output -json database_connection_string
```

---

## 5. Interview & Review Questions
1. **What is the difference between a `variable` and a `local` in Terraform?**
   - *Answer*: `variable` defines an input parameter that can be customized from outside the module (via CLI flags, `.tfvars` files, or caller module arguments). `local` defines a private internal variable scoped strictly inside the current module, typically used to simplify repetitive or computed expressions.
2. **What does setting `sensitive = true` on a Terraform variable or output do? Does it encrypt the value in `terraform.tfstate`?**
   - *Answer*: `sensitive = true` prevents the value from being printed in plain text in the terminal during `terraform plan`, `terraform apply`, and `terraform output`. **However, it does NOT encrypt the value in the `terraform.tfstate` file!** The raw secret remains stored in plain text inside the state file, which is why remote state storage must always be encrypted at rest.
