# Day 55: Phase 4 Capstone Mini-Project — Production CI/CD Pipeline Suite

## 1. Project Overview & Architecture

In this Phase 4 capstone project, you will build an end-to-end, enterprise-grade Continuous Integration and Continuous Deployment pipeline suite using GitHub Actions, Docker, and Trivy security scanning.

### Complete Pipeline Workflow
```
[ Git Push to Main / PR ]
           |
           v
+---------------------------------------------------------------------------------+
|  Stage 1: Lint & Code Quality                                                   |
|  - Check Python / Node.js syntax with Ruff / ESLint                            |
+---------------------------------------------------------------------------------+
           | (Pass)
           v
+---------------------------------------------------------------------------------+
|  Stage 2: Automated Unit Testing & Coverage Gate                               |
|  - Execute Pytest test suites                                                  |
|  - Enforce code coverage threshold                                             |
+---------------------------------------------------------------------------------+
           | (Pass)
           v
+---------------------------------------------------------------------------------+
|  Stage 3: Security & Vulnerability Gate                                         |
|  - Scan dependencies with Trivy / Safety                                       |
|  - Scan Dockerfile for CIS security misconfigurations                           |
+---------------------------------------------------------------------------------+
           | (Pass)
           v
+---------------------------------------------------------------------------------+
|  Stage 4: Multi-Stage Docker Build & Cache                                     |
|  - Build lean, non-root runtime container                                       |
|  - Cache layers with GitHub Actions Cache                                       |
+---------------------------------------------------------------------------------+
           | (Pass)
           v
+---------------------------------------------------------------------------------+
|  Stage 5: Publish Image to Container Registry (ECR / GHCR)                     |
|  - Tag with immutable Semantic Version + Git Commit SHA                         |
+---------------------------------------------------------------------------------+
           | (Pass)
           v
+---------------------------------------------------------------------------------+
|  Stage 6: Deploy & Automated Health Validation                                  |
|  - Deploy container to staging / production                                    |
|  - Execute automated HTTP smoke test with rollback fallback                     |
+---------------------------------------------------------------------------------+
```

---

## 2. Complete Enterprise GitHub Actions Pipeline (`.github/workflows/pipeline.yaml`)

```yaml
name: Enterprise CI/CD Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read
  packages: write
  security-events: write

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  # ============================================================
  # JOB 1: Code Quality & Testing
  # ============================================================
  test:
    name: Lint & Unit Tests
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Source Code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
          cache: 'pip'

      - name: Install Dependencies
        run: |
          python -m pip install --upgrade pip
          pip install ruff pytest pytest-cov

      - name: Lint Code
        run: ruff check .

      - name: Run Unit Tests with Coverage Gate
        run: pytest --cov=app --cov-report=term-missing --cov-fail-under=80

  # ============================================================
  # JOB 2: Container Security & Vulnerability Scanning
  # ============================================================
  security-scan:
    name: Container Security Audit
    needs: [test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build Local Container for Scanning
        run: docker build -t local-audit-image:${{ github.sha }} .

      - name: Scan Image with Trivy
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: local-audit-image:${{ github.sha }}
          format: 'table'
          exit-code: '1' # Fails build if CRITICAL vulnerability found!
          ignore-unfixed: true
          severity: 'CRITICAL,HIGH'

  # ============================================================
  # JOB 3: Build & Publish to Container Registry
  # ============================================================
  build-and-push:
    name: Build & Publish Image
    needs: [security-scan]
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: actions/setup-buildx-action@v3

      - name: Log in to GitHub Container Registry (GHCR)
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Generate Image Metadata & Tags
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/${{ github.repository }}
          tags: |
            type=sha,prefix=,format=short
            type=raw,value=latest,enable=${{ github.ref == 'refs/heads/main' }}

      - name: Build and Push Docker Image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  # ============================================================
  # JOB 4: Deploy & Verify Health
  # ============================================================
  deploy:
    name: Deploy to Production
    needs: [build-and-push]
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Deploy Container
        run: |
          echo "Simulating production deployment with tag: ${{ github.sha }}"
          # Real command would be: kubectl set image ... or terraform apply ...

      - name: Post-Deployment Smoke Test
        run: |
          echo "Probing service health..."
          # Simulating smoke test pass
          exit 0

      - name: Slack Notification
        if: always()
        run: |
          STATUS="${{ job.status }}"
          echo "Pipeline finished with status: ${STATUS}"
```

---

## 3. Phase 4 Milestone Completed!

🎉 **Congratulations! You have mastered Phase 4: Containers & CI/CD.**
You now possess industry-grade expertise in:
- Linux kernel primitives powering containers (Namespaces, cgroups, Overlay2).
- Writing hardened multi-stage Dockerfiles running as non-root users.
- Orchestrating multi-tier microservices with Docker Compose and health dependencies.
- Scanning container images for CVE vulnerabilities with Trivy.
- Pushing semantic container releases to Amazon ECR.
- Authoring production GitHub Actions and Jenkins Declarative Pipelines.
- Zero-downtime deployment strategies (Blue/Green, Canary) and automated rollback triggers.

Next: **Phase 5 — Terraform & Kubernetes (Days 56–70)**!
