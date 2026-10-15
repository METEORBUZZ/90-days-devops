# Day 67: Kubernetes RBAC, ServiceAccounts & Pod Security Standards

## 1. Theoretical Foundation

### The Kubernetes Authentication & Authorization Stack
When a request arrives at `kube-apiserver`:
1. **Authentication (Who are you?)**: Validates identity using X.509 client certificates, OIDC tokens (AWS IAM via EKS), or ServiceAccount Bearer tokens.
2. **Authorization (Can you do this?)**: Evaluates permissions via **Role-Based Access Control (RBAC)**.
3. **Admission Control (Is it safe?)**: Enforces policies (e.g. validating images, blocking root containers).

---

## 2. RBAC Primitives Matrix

Kubernetes RBAC consists of four core objects:

```
+---------------------------------------------------------------------------------+
|                                 WHAT CAN BE DONE?                               |
+---------------------------------------------------------------------------------+
|  Role (Namespace-Scoped)                |  ClusterRole (Cluster-Wide Scoped)    |
|  - e.g. read pods in "production"       |  - e.g. list nodes, list all namespaces|
+-----------------------------------------+---------------------------------------+
                                     |
                                     v (Bound via)
+---------------------------------------------------------------------------------+
|                                 WHO CAN DO IT?                                  |
+---------------------------------------------------------------------------------+
|  RoleBinding (Namespace-Scoped)         |  ClusterRoleBinding (Cluster-Wide)    |
|  - Binds User/SA to a Role in namespace |  - Binds User/SA to ClusterRole       |
+-----------------------------------------+---------------------------------------+
```

### Complete RBAC Example: Read-Only Developer Role
`role.yaml`:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: pod-reader
rules:
  - apiGroups: [""] # Core API group
    resources: ["pods", "pods/log"]
    verbs: ["get", "list", "watch"]
```

`rolebinding.yaml`:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods-binding
  namespace: production
subjects:
  - kind: User
    name: pramod@company.com
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

Test access via CLI:
```bash
# Check if current user can delete pods in production
kubectl auth can-i delete pods -n production

# Impersonate user to test permissions
kubectl auth can-i list pods -n production --as=pramod@company.com
```

---

## 3. Pod Security Context Hardening

Never allow pods to run with root privileges or host namespaces! Enforce hardening via `securityContext`:

```yaml
spec:
  # Pod-level security context
  securityContext:
    runAsNonRoot: true
    runAsUser: 10001
    runAsGroup: 10001
    fsGroup: 10001
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: app
      image: myapp:v1.0
      # Container-level security context
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop:
            - ALL
```

---

## 4. Interview & Review Questions
1. **What is the difference between a `Role` and a `ClusterRole` in Kubernetes?**
   - *Answer*: A `Role` defines permissions scoped strictly within a single specific namespace (e.g., read pods in `staging`). A `ClusterRole` defines permissions that apply cluster-wide across all namespaces (e.g., manage cluster nodes, persistent volumes, or read pods across all namespaces).
2. **What does `allowPrivilegeEscalation: false` prevent in a container's `securityContext`?**
   - *Answer*: It prevents a child process spawned inside the container from gaining more privileges than its parent process, effectively blocking SUID-based privilege escalation exploits.
