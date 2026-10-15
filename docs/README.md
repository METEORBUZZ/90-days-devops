# 📚 90 Days of DevOps — Comprehensive Knowledge Base

Welcome to the central learning documentation for the **90 Days of DevOps** roadmap. This repository contains structured, in-depth technical guides, architecture explanations, command cheat sheets, production troubleshooting scenarios, and interview preparation for every phase of DevOps engineering.

---

## 🗺️ Roadmap & Phases Overview

| Phase | Topic | Days | Status |
| :--- | :--- | :--- | :--- |
| **Phase 1** | [Linux, Networking & Scripting](./phase-01-linux-fundamentals/README.md) | Days 01–15 | ✅ Completed |
| **Phase 2** | [Git, Python & Automation](./phase-02-git-python-automation/README.md) | Days 16–25 | ✅ Completed |
| **Phase 3** | [AWS Cloud Engineering](./phase-03-aws-cloud/README.md) | Days 26–40 | ✅ Completed |
| **Phase 4** | [Containers & CI/CD (Docker, Jenkins, GitHub Actions)](./phase-04-containers-cicd/README.md) | Days 41–55 | ✅ Completed |
| **Phase 5** | [Infrastructure as Code & Orchestration (Terraform, K8s)](./phase-05-terraform-kubernetes/README.md) | Days 56–70 | ✅ Completed |
| **Phase 6** | [Monitoring, Security & Reliability (Prometheus, Grafana)](./phase-06-monitoring-security/README.md) | Days 71–80 | ✅ Completed |
| **Phase 7** | [Production Capstone Project & Career Transition](./phase-07-production-project/README.md) | Days 81–90 | ✅ Completed |

---

## 📁 Documentation Structure

```text
docs/
├── README.md                                 # Knowledge Base Index
└── phase-01-linux-fundamentals/              # Phase 1: Linux, Networking & Bash
    ├── README.md                             # Phase 1 Overview & Quick Navigation
    ├── day-01-linux-introduction-devops-workflow.md
    ├── day-02-filesystem-hierarchy-file-commands.md
    ├── day-03-reading-searching-text-processing.md
    ├── day-04-users-groups-sudo.md
    ├── day-05-permissions-ownership.md
    ├── day-06-processes-resource-usage.md
    ├── day-07-services-systemd.md
    ├── day-08-packages-software-installation.md
    ├── day-09-storage-disk-filesystems.md
    ├── day-10-logs-troubleshooting-basics.md
    ├── day-11-networking-fundamentals.md
    ├── day-12-ssh-secure-remote-access.md
    ├── day-13-bash-fundamentals.md
    ├── day-14-bash-conditions-loops-functions.md
    └── day-15-linux-automation-mini-project.md
├── phase-02-git-python-automation/           # Phase 2: Git & Python Automation
    ├── README.md                             # Phase 2 Overview & Quick Navigation
    ├── day-16-git-fundamentals.md
    ├── day-17-git-branches-merges.md
    ├── day-18-github-pull-requests.md
    ├── day-19-git-recovery-collaboration.md
    ├── day-20-python-fundamentals-automation.md
    ├── day-21-python-files-json-exceptions.md
    ├── day-22-http-apis-python-requests.md
    ├── day-23-automation-quality-testing.md
    ├── day-24-python-automation-mini-project.md
    └── day-25-linux-git-python-review.md
├── phase-03-aws-cloud/                       # Phase 3: AWS Cloud Engineering
    ├── README.md                             # Phase 3 Overview & Quick Navigation
    ├── day-26-aws-fundamentals-shared-responsibility.md
    ├── day-27-iam-users-roles-policies.md
    ├── day-28-aws-cli-credentials.md
    ├── day-29-ec2-linux-cloud-instances.md
    ├── day-30-ec2-security-troubleshooting.md
    ├── day-31-ebs-amis-instance-storage.md
    ├── day-32-s3-fundamentals.md
    ├── day-33-s3-security-static-hosting.md
    ├── day-34-vpc-fundamentals.md
    ├── day-35-routing-igw-nat.md
    ├── day-36-security-groups-network-acls.md
    ├── day-37-aws-monitoring-cloudwatch.md
    ├── day-38-aws-cost-management-tagging.md
    ├── day-39-aws-cli-automation-security-review.md
    └── day-40-aws-mini-project-review.md
├── phase-04-containers-cicd/                # Phase 4: Containers & CI/CD
    ├── README.md                             # Phase 4 Overview & Quick Navigation
    ├── day-41-containers-docker-concepts.md
    ├── day-42-docker-images-dockerfiles.md
    ├── day-43-docker-run-ports-logs.md
    ├── day-44-docker-volumes-networking.md
    ├── day-45-docker-compose.md
    ├── day-46-container-security-image-scanning.md
    ├── day-47-amazon-ecr-image-publishing.md
    ├── day-48-github-actions-fundamentals.md
    ├── day-49-ci-pipelines-build-test.md
    ├── day-50-cd-concepts-deployment-strategies.md
    ├── day-51-jenkins-fundamentals.md
    ├── day-52-jenkins-pipeline-as-code.md
    ├── day-53-secrets-supply-chain-security.md
    ├── day-54-deployment-automation-rollback.md
    └── day-55-cicd-mini-project.md
├── phase-05-terraform-kubernetes/           # Phase 5: Terraform & Kubernetes
    ├── README.md                             # Phase 5 Overview & Quick Navigation
    ├── day-56-terraform-fundamentals.md
    ├── day-57-terraform-variables-outputs-locals.md
    ├── day-58-terraform-state-remote-backend.md
    ├── day-59-terraform-modules-environments.md
    ├── day-60-terraform-security-team-workflow.md
    ├── day-61-kubernetes-architecture.md
    ├── day-62-pods-deployments-replicasets.md
    ├── day-63-kubernetes-services-networking.md
    ├── day-64-configmaps-secrets-configuration.md
    ├── day-65-probes-resources-scheduling.md
    ├── day-66-kubernetes-storage-stateful-workloads.md
    ├── day-67-kubernetes-rbac-security.md
    ├── day-68-helm-release-management.md
    ├── day-69-kubernetes-troubleshooting.md
    └── day-70-kubernetes-mini-project-review.md
├── phase-06-monitoring-security/             # Phase 6: Monitoring, Security & Reliability
    ├── README.md                             # Phase 6 Overview & Quick Navigation
    ├── day-71-monitoring-metrics-observability.md
    ├── day-72-prometheus-fundamentals.md
    ├── day-73-grafana-dashboards.md
    ├── day-74-aws-cloudwatch-logs-alarms.md
    ├── day-75-alerting-incident-response.md
    ├── day-76-devsecops-vulnerability-management.md
    ├── day-77-iam-secrets-cloud-security-review.md
    ├── day-78-backups-disaster-recovery-rto-rpo.md
    ├── day-79-performance-capacity-troubleshooting.md
    └── day-80-reliability-review-game-day.md
├── phase-07-production-project/              # Phase 7: Production Capstone & Transition
    ├── README.md                             # Phase 7 Overview & Quick Navigation
    ├── day-81-capstone-design-requirements.md
    ├── day-82-capstone-app-container.md
    ├── day-83-capstone-terraform-aws-deployment.md
    ├── day-84-capstone-ci-cd-security-gates.md
    ├── day-85-capstone-monitoring-runbooks.md
    ├── day-86-incident-simulation-linux-networking.md
    ├── day-87-incident-simulation-aws-containers.md
    ├── day-88-resume-github-project-documentation.md
    ├── day-89-mock-interview-technical-review.md
    └── day-90-final-assessment-next-90-days.md
```

---

## 🎯 How to Use These Notes
Each learning module is designed around real engineering standards:
1. **Theory & Architecture**: Why it matters and how it works under the hood.
2. **Commands & Practical Syntax**: Real-world CLI examples with flags and output.
3. **Production Use Cases**: Real DevOps scenarios in containers, cloud servers, and CI/CD pipelines.
4. **Troubleshooting & Failure Modes**: Error messages, root cause analysis, and fixes.
5. **Interview & SRE Ready**: High-yield interview questions and conceptual explanations.
