# Phase 5: Infrastructure as Code & Orchestration (Terraform & Kubernetes) (Days 56–70)

This is the crown jewel of modern cloud-native engineering. In Phase 5, you master **Terraform** for declarative cloud provisioning (Infrastructure as Code) and **Kubernetes** for enterprise container orchestration, scaling, self-healing, and networking.

---

## 📅 Daily Learning Index

| Day | Topic | In-Depth Learning Guide | Key Concepts |
| :--- | :--- | :--- | :--- |
| **56** | **Terraform Fundamentals & HCL Syntax** | [Day 56 Guide](./day-56-terraform-fundamentals.md) | Declarative vs Imperative, Providers, Resources, `terraform init/plan/apply/destroy` |
| **57** | **Variables, Outputs, Locals & Type Constraints** | [Day 57 Guide](./day-57-terraform-variables-outputs-locals.md) | `input variables`, validation blocks, `locals`, `outputs`, sensitive flags |
| **58** | **Terraform State & S3/DynamoDB Remote Backend** | [Day 58 Guide](./day-58-terraform-state-remote-backend.md) | State file schema, State Locking via DynamoDB, encryption at rest, state migration |
| **59** | **Terraform Reusable Modules & Environments** | [Day 59 Guide](./day-59-terraform-modules-environments.md) | Root vs Child modules, DRY architecture, multi-environment separation (dev/stage/prod) |
| **60** | **Terraform Drift Detection, Import & Policy as Code** | [Day 60 Guide](./day-60-terraform-security-team-workflow.md) | State drift triage (`terraform refresh`), `terraform import`, Checkov security scans |
| **61** | **Kubernetes Architecture & Control Plane Internals** | [Day 61 Guide](./day-61-kubernetes-architecture.md) | API Server, etcd (Raft), Scheduler, Controller Manager, Kubelet, Kube-Proxy |
| **62** | **Pods, ReplicaSets & Deployments** | [Day 62 Guide](./day-62-pods-deployments-replicasets.md) | Pod lifecycle, declarative reconciler loops, rolling updates, rollout revision history |
| **63** | **Kubernetes Services & Ingress Networking** | [Day 63 Guide](./day-63-kubernetes-services-networking.md) | ClusterIP, NodePort, LoadBalancer, CoreDNS, Label Selectors, Ingress Controllers |
| **64** | **ConfigMaps, Secrets & External Configuration** | [Day 64 Guide](./day-64-configmaps-secrets-configuration.md) | Decoupling config, volume mounts, env injection, SealedSecrets / External Secrets Operator |
| **65** | **Probes, Resource Limits & Pod Scheduling** | [Day 65 Guide](./day-65-probes-resources-scheduling.md) | Liveness, Readiness, Startup probes, CPU/Memory requests vs limits, OOMKilled (Exit 137) |
| **66** | **Kubernetes Storage: Volumes, PVs, PVCs & StorageClass**| [Day 66 Guide](./day-66-kubernetes-storage-stateful-workloads.md)| Static vs Dynamic provisioning, PersistentVolumes, PVC claims, EBS CSI driver, StatefulSets |
| **67** | **Kubernetes RBAC, ServiceAccounts & Pod Security** | [Day 67 Guide](./day-67-kubernetes-rbac-security.md) | Role, ClusterRole, RoleBinding, ServiceAccounts, SecurityContext (`runAsNonRoot`) |
| **68** | **Helm Package Manager & Release Lifecycle** | [Day 68 Guide](./day-68-helm-release-management.md) | Helm Charts, `values.yaml`, Go templating, `helm upgrade --install`, atomic rollbacks |
| **69** | **Kubernetes Cluster Troubleshooting Masterclass** | [Day 69 Guide](./day-69-kubernetes-troubleshooting.md) | Debugging `CrashLoopBackOff`, `ImagePullBackOff`, `Pending` scheduling, `kubectl exec/logs/events` |
| **70** | **Kubernetes Capstone Mini-Project & Review** | [Day 70 Guide](./day-70-kubernetes-mini-project-review.md) | Complete Production Workload: Deployment + Service + Ingress + HPA + Probes + Helm Chart |

---

## 🎯 Phase 5 Goals & Milestones
By the end of Phase 5, you should be able to:
1. Write production-grade Terraform code with remote state locking and modular multi-environment structure.
2. Explain every internal component of the Kubernetes Control Plane and Worker Nodes.
3. Manage zero-downtime application rollouts, service routing, external configuration, and volume claims.
4. Triage and fix production Kubernetes cluster failures within minutes using structured debugging playbooks.
