# Phase 4: Containers & CI/CD (Docker, Jenkins, GitHub Actions) (Days 41–55)

Containers revolutionized modern software delivery by packaging code together with all runtime dependencies into standardized, immutable artifacts that execute identically everywhere. Pair containerization with automated CI/CD pipelines (GitHub Actions, Jenkins), and you have the core heartbeat of modern DevOps.

---

## 📅 Daily Learning Index

| Day | Topic | In-Depth Learning Guide | Key Concepts |
| :--- | :--- | :--- | :--- |
| **41** | **Containers & Docker Architecture** | [Day 41 Guide](./day-41-containers-docker-concepts.md) | VMs vs Containers, Linux Namespaces (PID, Net, Mount), cgroups, containerd, Docker daemon |
| **42** | **Dockerfiles & Image Layering** | [Day 42 Guide](./day-42-docker-images-dockerfiles.md) | Multi-stage builds, layer caching optimization, `.dockerignore`, build contexts, minimal base images |
| **43** | **Container Lifecycle, Ports & Telemetry** | [Day 43 Guide](./day-43-docker-run-ports-logs.md) | `docker run`, port forwarding (`-p`), detached mode (`-d`), environment variables, log drivers |
| **44** | **Docker Storage & Networking** | [Day 44 Guide](./day-44-docker-volumes-networking.md) | Bind mounts vs Named Volumes, Bridge vs Host vs Overlay networks, embedded container DNS |
| **45** | **Multi-Container Apps with Docker Compose** | [Day 45 Guide](./day-45-docker-compose.md) | `docker-compose.yml`, multi-tier stacks (App + Redis + Postgres), health checks, network dependencies |
| **46** | **Container Security & Vulnerability Scanning** | [Day 46 Guide](./day-46-container-security-image-scanning.md) | Rootless containers, non-root users (`USER 1001`), Trivy / Docker Scout scanning, distroless images |
| **47** | **Amazon ECR & Image Registry Management** | [Day 47 Guide](./day-47-amazon-ecr-image-publishing.md) | AWS ECR private repositories, docker login authentication via AWS CLI, semantic tagging, lifecycle policies |
| **48** | **GitHub Actions Fundamentals** | [Day 48 Guide](./day-48-github-actions-fundamentals.md) | Workflow YAML syntax, triggers (`push`, `pull_request`, `workflow_dispatch`), jobs, steps, runners |
| **49** | **Continuous Integration (CI): Build & Test** | [Day 49 Guide](./day-49-ci-pipelines-build-test.md) | Automated testing matrices, artifact caching (`actions/cache`), build status checks, branch quality gates |
| **50** | **Continuous Deployment (CD) Strategies** | [Day 50 Guide](./day-50-cd-concepts-deployment-strategies.md) | Rolling vs Blue/Green vs Canary deployments, automated health validation, zero-downtime cutover |
| **51** | **Jenkins Fundamentals & Architecture** | [Day 51 Guide](./day-51-jenkins-fundamentals.md) | Controller vs Agent architecture, credential management, plugin ecosystem, secure setup |
| **52** | **Jenkins Declarative Pipeline as Code** | [Day 52 Guide](./day-52-jenkins-pipeline-as-code.md) | `Jenkinsfile`, declarative stages, steps, `post` execution blocks (always, failure), parameters |
| **53** | **Secrets & Software Supply Chain Security** | [Day 53 Guide](./day-53-secrets-supply-chain-security.md) | OIDC (Keyless authentication), GitHub Secrets, software bill of materials (SBOM), dependency pinning |
| **54** | **Deployment Automation & Automated Rollbacks** | [Day 54 Guide](./day-54-deployment-automation-rollback.md) | Environment gates, manual approval interventions, post-deployment smoke tests, automated rollback triggers |
| **55** | **CI/CD Capstone Mini-Project** | [Day 55 Guide](./day-55-cicd-mini-project.md) | End-to-End Enterprise Pipeline: Lint -> Unit Test -> Security Scan -> Docker Build -> ECR Push -> CD Notification |

---

## 🎯 Phase 4 Goals & Milestones
By the end of Phase 4, you should be able to:
1. Explain how the Linux kernel isolates containers using Namespaces and cgroups.
2. Build minimal, secure, multi-stage Docker images running as non-root users.
3. Manage multi-container microservice stacks using Docker Compose.
4. Author production-grade GitHub Actions and Jenkins Declarative Pipelines.
5. Implement zero-downtime deployment strategies (Blue/Green, Canary) with automated rollback triggers.
