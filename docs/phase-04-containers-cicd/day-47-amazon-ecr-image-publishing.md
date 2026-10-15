# Day 47: Amazon Elastic Container Registry (ECR) & Image Lifecycle

## 1. Theoretical Foundation

### What is Amazon ECR?
Amazon Elastic Container Registry (ECR) is a fully managed, highly available, secure container image registry that makes it easy for DevOps engineers to store, manage, share, and deploy container images across AWS ECS, EKS, Lambda, and on-premises infrastructure.

### Key Capabilities
- **High Availability & Durability**: Backed by Amazon S3 storage with 99.999999999% durability.
- **IAM Authorization**: Controls image pull/push permissions using standard AWS IAM policies instead of static registry passwords.
- **Image Scanning on Push**: Automatically scans images for OS vulnerabilities upon upload using AWS Inspector / Clair.
- **Immutable Image Tags**: Prevents existing production image tags (like `v1.2.0`) from being maliciously or accidentally overwritten.
- **Lifecycle Policies**: Automatically purges untagged or old development images to prevent ballooning storage costs.

---

## 2. Pushing Docker Images to AWS ECR Step-by-Step

### 1. Authenticate Docker CLI to your ECR Registry
ECR uses temporary authentication tokens valid for 12 hours:

```bash
# Retrieve temporary token and pipe into docker login
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin 123456789012.dkr.ecr.ap-south-1.amazonaws.com
```

### 2. Create the ECR Repository with Scan-on-Push
```bash
aws ecr create-repository \
  --repository-name orders-service \
  --image-scanning-configuration scanOnPush=true \
  --image-tag-mutability IMMUTABLE \
  --region ap-south-1
```

### 3. Build, Tag & Push
```bash
# Define registry URI
ECR_REGISTRY="123456789012.dkr.ecr.ap-south-1.amazonaws.com"
IMAGE_NAME="orders-service"
TAG="v1.0.0"

# Build locally
docker build -t ${IMAGE_NAME}:${TAG} .

# Tag image with full ECR registry URL
docker tag ${IMAGE_NAME}:${TAG} ${ECR_REGISTRY}/${IMAGE_NAME}:${TAG}

# Push image to AWS ECR
docker push ${ECR_REGISTRY}/${IMAGE_NAME}:${TAG}
```

---

## 3. Production Lifecycle Policy (Cost Optimization)

Without lifecycle policies, active CI/CD pipelines push 50+ images a day, quickly consuming terabytes of storage.
Attach a lifecycle policy to keep only the last 30 tagged releases and expire untagged images within 7 days:

```json
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Expire untagged images older than 7 days",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 7
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 2,
      "description": "Retain only the latest 30 release images",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["v"],
        "countType": "imageCountMoreThan",
        "countNumber": 30
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
```

Apply via CLI:
```bash
aws ecr put-lifecycle-policy \
  --repository-name orders-service \
  --lifecycle-policy-text file://policy.json
```

---

## 4. Best Practice: Semantic Versioning vs. `:latest` Tag

**Never deploy using the `:latest` tag in production!**
- `:latest` is ambiguous. You cannot determine which Git commit is currently running.
- Kubernetes nodes cache images: if a new image is pushed under `:latest`, `imagePullPolicy: IfNotPresent` will skip pulling it, leaving cluster nodes running conflicting image builds!
- **Always use semantic versioning + Git commit SHA**:
  `orders-service:v1.4.2-a8f3b21`

---

## 5. Interview & Review Questions
1. **Why is Image Tag Immutability recommended in Amazon ECR for production repositories?**
   - *Answer*: Tag immutability ensures that once an image is pushed with a tag (such as `v1.0.0`), it can never be overwritten by a subsequent push. This prevents accidental regressions, guarantees build reproducibility across staging and production, and defends against malicious image tampering.
2. **How does an Amazon EKS Pod pull images from a private ECR repository without hardcoded docker credentials?**
   - *Answer*: EKS uses IAM Roles for Service Accounts (IRSA) or the Amazon EKS Node IAM Role attached to worker nodes. The kubelet queries AWS IAM for short-lived ECR authorization tokens to pull images automatically without storing static secrets.
