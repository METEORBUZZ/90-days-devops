# Day 27: AWS IAM (Identities, Roles, Policies & Least Privilege)

## 1. Theoretical Foundation

### What is AWS Identity and Access Management (IAM)?
IAM is a **global** service that controls authentication (who can log in) and authorization (what permissions they have to access AWS resources).

### Critical IAM Entities
- **Root User**: The email address used to create the AWS account. Has complete, unrestricted superuser access.
  - *Golden DevOps Rule: NEVER use the root account for daily operations or CI/CD! Lock it with physical MFA and store credentials in a safe.*
- **IAM User**: A person or legacy service identity with long-lived credentials (password for AWS Console, Access Key/Secret Key for CLI).
- **IAM Group**: A collection of IAM users. Permissions applied to a group are inherited by all member users.
- **IAM Role**: An identity with specific permissions that is **not** tied to a single user. Instead of long-lived access keys, an entity (EC2 instance, Lambda function, GitHub Actions runner, or cross-account engineer) **assumes** the role and receives **temporary credentials** (valid from 15 minutes up to 12 hours) via AWS STS (Security Token Service).

---

## 2. Anatomy of an IAM Policy (JSON)

An IAM policy is a JSON document that defines permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3ReadOnlyForBuildArtifacts",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::company-build-artifacts-2026",
        "arn:aws:s3:::company-build-artifacts-2026/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "true"
        }
      }
    }
  ]
}
```

### Key Elements Explained
- **`Version`**: Always `"2012-10-17"` (the current policy language version; NOT the date the policy was written!).
- **`Effect`**: Either `"Allow"` or `"Deny"`.
- **`Action`**: List of specific API calls allowed or denied (`ec2:DescribeInstances`, `s3:PutObject`).
- **`Resource`**: The Amazon Resource Name (ARN) of the target resource:
  `arn:aws:service:region:account-id:resource-type/resource-id`
- **`Condition`**: Extra enforcement constraints (e.g., enforce HTTPS `aws:SecureTransport`, restrict source IP `aws:SourceIp`, or enforce MFA).

### The IAM Evaluation Logic
```
          [ Start: Default Implicit Deny ]
                         |
                         v
          [ Is there an Explicit DENY? ] ---- YES ----> [ Access DENIED ]
                         |
                        NO
                         v
          [ Is there an Explicit ALLOW? ] ---- NO -----> [ Access DENIED (Implicit) ]
                         |
                        YES
                         v
                 [ Access GRANTED ]
```
*Rule: An explicit `Deny` ALWAYS overrides any `Allow`!*

---

## 3. IAM Roles vs. IAM Users for Workloads

**Never store AWS Access Keys inside EC2 instances or Docker containers!**
Instead, attach an **IAM Role** to the instance via an **Instance Profile**. The AWS SDK automatically retrieves temporary, rotating credentials from the instance metadata service:

```
[ EC2 Instance / EKS Pod ]
         |
         | (Calls http://169.254.169.254/latest/meta-data/)
         v
[ AWS STS (Security Token Service) ]
         |
         | (Issues temporary AccessKey, SecretKey, Token)
         v
[ Auto-Rotating Credentials Valid for 1 Hour ]
```

---

## 4. Hands-on Lab: Creating an IAM Policy and Role via CLI

```bash
# 1. Create a trust policy document allowing EC2 to assume this role
cat << 'EOF' > /tmp/ec2-trust-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# 2. Create the IAM Role
aws iam create-role \
  --role-name EC2S3ReadOnlyRole \
  --assume-role-policy-document file:///tmp/ec2-trust-policy.json

# 3. Attach AWS Managed Policy for S3 Read Only
aws iam attach-role-policy \
  --role-name EC2S3ReadOnlyRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# 4. Create an Instance Profile and attach the role
aws iam create-instance-profile --instance-profile-name EC2S3ReadOnlyProfile
aws iam add-role-to-instance-profile \
  --instance-profile-name EC2S3ReadOnlyProfile \
  --role-name EC2S3ReadOnlyRole

# Cleanup
rm -f /tmp/ec2-trust-policy.json
```

---

## 5. Interview & Review Questions
1. **Why is it dangerous to embed hardcoded `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in application source code or Docker images? What is the alternative?**
   - *Answer*: If code is committed to GitHub or images pushed to public registries, automated bots scrape credentials within seconds, causing massive unauthorized cryptomining bills and data breaches. The cloud-native alternative is IAM Roles (via Instance Profiles on EC2, or IAM Roles for Service Accounts / IRSA on Kubernetes EKS), which provide temporary, auto-rotated STS tokens without static credentials.
2. **What does the `sts:AssumeRole` action do?**
   - *Answer*: It requests temporary security credentials from AWS Security Token Service (STS) to assume a target IAM Role. The caller's permissions are temporarily replaced by the permissions granted to that assumed role, commonly used for cross-account deployments and CI/CD pipelines.
