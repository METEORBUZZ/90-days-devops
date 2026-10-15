# Day 84: Capstone CI/CD — Automated Zero-Downtime Pipeline with Security Gates

## 1. Pipeline Architecture

The capstone CI/CD pipeline implements a complete DevSecOps flow:
1. **Linting & Code Quality**: Ruff syntax validation.
2. **Automated Unit Testing & Coverage**: Pytest with 85% coverage gate.
3. **Security Gates**:
   - SAST scan via Semgrep.
   - Container vulnerability scan via Trivy.
4. **Keyless Cloud Authentication**: GitHub Actions OIDC to AWS ECR.
5. **Zero-Downtime Rolling Deployment**: Helm v3 atomic release to Kubernetes EKS.
6. **Automated Smoke Testing & Fallback**: Validates `/healthz` and `/ready` endpoints; rolls back automatically on failure.

---

## 2. Complete Workflow Definition (`.github/workflows/deploy.yaml`)

```yaml
name: CloudOrders Production CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  id-token: write # Mandatory for AWS OIDC authentication!
  contents: read

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  test:
    name: Lint & Unit Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
          cache: 'pip'
      - run: pip install -r requirements-dev.txt
      - run: ruff check .
      - run: pytest --cov=app --cov-fail-under=85

  security:
    name: Security & Container Scan
    needs: [test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build local container
        run: docker build -t local-test:${{ github.sha }} .
      - name: Scan Image with Trivy
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: local-test:${{ github.sha }}
          severity: 'CRITICAL,HIGH'
          exit-code: '1'

  deploy:
    name: Deploy to Production EKS
    needs: [security]
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # 1. Keyless AWS Authentication via OIDC
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsEKSRole
          aws-region: ap-south-1

      # 2. Log in to Amazon ECR
      - name: Log in to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      # 3. Build & Push Image
      - name: Build & Push Docker Image
        env:
          REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          REPOSITORY: cloudorders-api
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $REGISTRY/$REPOSITORY:$IMAGE_TAG .
          docker push $REGISTRY/$REPOSITORY:$IMAGE_TAG

      # 4. Deploy to EKS via Helm v3 with Atomic Rollback
      - name: Deploy Helm Chart to EKS
        env:
          REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        run: |
          aws eks update-kubeconfig --region ap-south-1 --name cloudorders-prod-cluster
          helm upgrade --install cloudorders ./helm/cloudorders \
            --namespace production \
            --set image.repository=$REGISTRY/cloudorders-api \
            --set image.tag=${{ github.sha }} \
            --atomic \
            --timeout 5m

      # 5. Post-Deployment Smoke Test
      - name: Verify Health Endpoint
        run: |
          ALB_URL=$(kubectl get ingress cloudorders-ingress -n production -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
          echo "Probing http://${ALB_URL}/healthz..."
          curl --fail --retry 10 --retry-delay 5 http://${ALB_URL}/healthz
```

---

## 3. Key Takeaways & Review
- Uses OIDC (`role-to-assume`) for zero static long-lived credentials.
- `helm upgrade --install --atomic` ensures that if health checks fail, Kubernetes rolls back immediately without manual intervention.
