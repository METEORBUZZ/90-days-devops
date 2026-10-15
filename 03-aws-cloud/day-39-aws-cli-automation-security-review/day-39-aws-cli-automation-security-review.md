# Day 39: AWS CLI Automation, JMESPath Filtering & Security Auditing

## 1. Theoretical Foundation

In enterprise cloud operations, GUI point-and-click management does not scale. DevOps engineers must query thousands of cloud resources programmatically across multiple AWS regions and accounts.
The AWS CLI features a built-in JSON query engine powered by **JMESPath** via the `--query` flag.

### Server-Side vs. Client-Side Filtering in AWS CLI
- **`--filters` (Server-Side)**: Evaluated directly on the AWS API servers before sending data across the network. Minimizes network payload and prevents client timeouts on large accounts.
- **`--query` (Client-Side JMESPath)**: Evaluated locally on your machine after the JSON response is received. Enables precise slicing, projections, multi-field formatting, and sorting.

---

## 2. Advanced JMESPath Querying Patterns

### 1. Tabular Output of Running Instances
```bash
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].[InstanceId, InstanceType, PublicIpAddress, Tags[?Key=='Name'].Value | [0]]" \
  --output table
```

### 2. Finding All Unencrypted EBS Volumes
Find volumes where encryption is disabled for security compliance audits:
```bash
aws ec2 describe-volumes \
  --query "Volumes[?!Encrypted].[VolumeId, Size, AvailabilityZone]" \
  --output table
```

### 3. Extracting IAM Users Without MFA Enabled
```bash
# Query all virtual MFA devices and compare with users
aws iam list-users --query "Users[].[UserName, CreateDate, PasswordLastUsed]" --output table
```

---

## 3. Safe Automation: The `--dry-run` Flag

Before running potentially destructive infrastructure mutations via the CLI or automated Python scripts, test permissions and syntax with `--dry-run`:

```bash
# Verify whether your IAM credentials have permission to terminate an instance:
aws ec2 terminate-instances --instance-ids i-0123456789abcdef0 --dry-run
```
- If you have permission: Returns `Request would have succeeded, but DryRun flag is set` with exit code `253` (`DryRunOperation`).
- If you lack IAM permissions: Returns `UnauthorizedOperation` with error details, without executing the command!

---

## 4. Generating the AWS IAM Credential Report

The **IAM Credential Report** lists all users in your AWS account and the status of their various credentials, including passwords, access keys, and MFA devices.

```bash
# 1. Request report generation
aws iam generate-credential-report

# 2. Download and decode base64 CSV report
aws iam get-credential-report --query "Content" --output text | base64 --decode > /tmp/iam-audit.csv

# 3. Inspect accounts with access keys older than 90 days (CIS Benchmark violation):
cat /tmp/iam-audit.csv | cut -d',' -f1,4,9,14 | head -n 10
```

---

## 5. Interview & Review Questions
1. **What is the difference between `--filters` and `--query` in the AWS CLI?**
   - *Answer*: `--filters` performs server-side filtering at the AWS API endpoint, reducing the amount of data transmitted over the wire. `--query` uses client-side JMESPath syntax to reshape, transform, and extract specific fields from the JSON payload returned to your local terminal.
2. **Why should critical automation scripts utilize `--dry-run` where supported?**
   - *Answer*: `--dry-run` checks whether the caller has the necessary IAM permissions to perform the action and validates request parameters without actually executing the mutation, preventing accidental downtime or failed mid-script operations.
