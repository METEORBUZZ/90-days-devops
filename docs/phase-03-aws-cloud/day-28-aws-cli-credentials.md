# Day 28: AWS CLI v2, Named Profiles & Modern Credential Hygiene

## 1. Theoretical Foundation

### The AWS CLI (Command Line Interface)
The AWS CLI is a unified open-source tool that lets DevOps engineers manage all AWS services from shell scripts, terminals, and automated pipelines.
Version 2 (`aws-cli/2.x`) is the modern standard, written in Python/C with bundled dependencies, auto-prompting, and AWS IAM Identity Center (SSO) support.

### The AWS Credential Precedence Order
When an AWS CLI or SDK command runs, it searches for credentials in a strict hierarchy:
1. **Command Line Options**: `--region`, `--profile`.
2. **Environment Variables**: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`.
3. **AWS IAM Identity Center (SSO) token cache**.
4. **AWS Credentials File**: `~/.aws/credentials`.
5. **AWS Config File**: `~/.aws/config`.
6. **Container Credentials**: (ECS Task Role or EKS Pod Identity / IRSA).
7. **Instance Profile Credentials**: (EC2 Instance Metadata Service / IMDS).

---

## 2. Configuration & Named Profiles

### `~/.aws/credentials`
Stores sensitive access keys:
```ini
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

[production]
aws_access_key_id = AKIAI44QH8DHBEXAMPLE
aws_secret_access_key = je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY
```

### `~/.aws/config`
Stores non-sensitive default configurations (Region, Output format):
```ini
[default]
region = us-east-1
output = json

[profile production]
region = ap-south-1
output = yaml
```

### Switching Profiles
```bash
# Using explicit flag
aws s3 ls --profile production

# Using environment variable for current shell session
export AWS_PROFILE=production
aws sts get-caller-identity
```

---

## 3. The `aws sts get-caller-identity` Sanity Check

Always execute this command before running infrastructure changes:
```bash
aws sts get-caller-identity
```
Example Output:
```json
{
    "UserId": "AROA123456789EXAMPLE:session-name",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:assumed-role/DevOpsAdmin/pramod"
}
```
**Why this matters**: It proves immediately which AWS Account ID and IAM identity you are executing against, preventing catastrophic accidents (e.g. running Terraform destroy against Production instead of Staging!).

---

## 4. IMDSv2 (Instance Metadata Service Version 2)

On EC2 instances, the Instance Metadata Service (`http://169.254.169.254/latest/meta-data/`) delivers local IP addresses, AMI IDs, and IAM role credentials.
- **IMDSv1 (Legacy)**: Insecure. Used simple HTTP GET requests. Highly susceptible to SSRF (Server-Side Request Forgery) attacks where an attacker could exploit a web app vulnerability to steal host IAM credentials!
- **IMDSv2 (Modern Production Standard)**: Session-oriented. Requires a `PUT` request with a security token header (`X-aws-ec2-metadata-token-ttl-seconds`) before querying metadata.

### Querying Metadata via IMDSv2
```bash
# 1. Obtain temporary token (valid for 6 hours / 21600 seconds)
TOKEN=$(curl -s -S -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

# 2. Query instance ID securely
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
echo "Running on Instance: $INSTANCE_ID"

# 3. Query IAM Role temporary credentials
ROLE_NAME=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/)
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/iam/security-credentials/$ROLE_NAME"
```

---

## 5. Interview & Review Questions
1. **What is SSRF and how does IMDSv2 protect AWS EC2 workloads against it?**
   - *Answer*: Server-Side Request Forgery (SSRF) occurs when a vulnerable web application is tricked into sending requests to internal network endpoints, such as `http://169.254.169.254`. With IMDSv1, a simple GET request yielded temporary IAM credentials. IMDSv2 requires a preceding `PUT` request with custom headers to generate a session token; most application-layer SSRF attack vectors cannot forge arbitrary HTTP PUT headers with custom TTLs, effectively neutralizing the attack.
2. **What does the command `aws sts get-caller-identity` tell you?**
   - *Answer*: It returns the Account ID, User ID / Role ID, and ARN of the IAM entity currently authenticated by the CLI or SDK, providing a safe verification check before applying cloud mutations.
