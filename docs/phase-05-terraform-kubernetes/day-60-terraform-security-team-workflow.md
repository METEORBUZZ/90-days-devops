# Day 60: Terraform Drift Detection, Import & Policy as Code (Checkov)

## 1. Theoretical Foundation

### The Reality of Cloud Drift
**Configuration Drift** occurs when cloud resources managed by Terraform are manually modified, deleted, or reconfigured outside of Terraform (e.g. an on-call engineer edits a Security Group directly in the AWS Management Console during a late-night incident).
When Terraform runs again, it discovers the discrepancy between the stored state file and live cloud reality.

```
[ Terraform State: SG port 80 only ] <--- DRIFT DETECTED ---> [ AWS Live Reality: Engineer opened port 22 ]
                                                |
                                                v
               [ terraform apply overwrites & remediates manual changes! ]
```

---

## 2. Detecting & Triage Drift

```bash
# 1. Refresh state against live cloud reality without modifying local files
terraform refresh

# 2. Detailed drift check (read-only)
terraform plan -detailed-exitcode
```
- Exit code `0`: Succeeded, diff is empty (no drift).
- Exit code `1`: Error occurred.
- Exit code `2`: Succeeded, **drift detected** (infrastructure has changed).

Automated scheduled CI/CD jobs run `terraform plan -detailed-exitcode` daily to alert the security team whenever manual console changes occur!

---

## 3. Bringing Pre-Existing Resources Under Management (`import`)

When adopting Terraform in an organization that already has existing AWS infrastructure:

### Modern Declarative Import Block (Terraform 1.5+)
Instead of using manual imperative CLI commands, write an `import` block directly in your HCL code:

```hcl
# 1. Define where the cloud resource should import
import {
  to = aws_s3_bucket.legacy_data
  id = "company-legacy-archive-bucket-2023"
}

# 2. Generate the matching HCL code automatically!
# terraform plan -generate-config-out=generated_resources.tf
```
Review the generated code, remove unwanted defaults, and run `terraform apply`. The existing S3 bucket is now seamlessly tracked in `terraform.tfstate` without downtime!

---

## 4. Policy as Code & Security Scanning with Checkov

Never let Terraform apply code that creates unencrypted S3 buckets, open security groups (`0.0.0.0/0` on port 22), or root IAM privileges.
**Checkov** (by Prisma Cloud) is a static code analysis tool for scanning IaC against 1,000+ CIS security benchmarks:

```bash
# Install Checkov
pip install checkov

# Run scan against Terraform directory
checkov -d ./terraform-infrastructure

# Integrate into CI/CD pipeline to block PRs on HIGH or CRITICAL violations:
checkov -d . --framework terraform --check CKV_AWS_20,CKV_AWS_19 --hard-fail-on HIGH,CRITICAL
```

---

## 5. Interview & Review Questions
1. **What happens during `terraform apply` when live infrastructure has drifted from the state file?**
   - *Answer*: During the refresh phase, Terraform queries the cloud provider APIs to update its state representation with live reality. It then compares live state against your declarative HCL code. Any attributes modified manually in the cloud console that conflict with your code will be reverted back to match the code specification upon confirmation.
2. **What is the difference between `terraform state rm` and `terraform destroy`?**
   - *Answer*: `terraform destroy` calls the cloud provider APIs to physically delete and destroy the real-world cloud resources. `terraform state rm` removes the resource reference from the `terraform.tfstate` file only; the physical cloud resource continues running in AWS untouched, but is no longer tracked or managed by Terraform.
