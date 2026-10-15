# Day 68: Helm Package Manager, Templating & Release Management

## 1. Theoretical Foundation

### What is Helm?
Helm is the package manager for Kubernetes (equivalent to `apt` for Debian or `npm` for Node.js).
Instead of maintaining 10 disparate raw YAML manifests (`deployment.yaml`, `service.yaml`, `ingress.yaml`, `hpa.yaml`, `pvc.yaml`) with hardcoded values, Helm bundles them into a reusable, versioned **Helm Chart**.

### Helm Architecture (Helm v3)
- **Tiller is Dead**: In legacy Helm v2, an insecure server-side daemon called `Tiller` ran inside the cluster with cluster-admin privileges. **Helm v3 completely removed Tiller!**
- Helm v3 is a purely client-side CLI tool that interacts directly with the Kubernetes API server using the user's existing `kubeconfig` credentials.
- Release state is stored securely inside native Kubernetes Secrets in the target namespace.

---

## 2. Structure of a Helm Chart

```text
my-chart/
├── Chart.yaml          # Metadata: chart version, app version, description
├── values.yaml         # Default configuration values (can be overridden by user)
├── templates/          # Go-templated Kubernetes YAML manifests
│   ├── _helpers.tpl    # Reusable template snippets
│   ├── deployment.yaml # {{ .Values.image.repository }}:{{ .Values.image.tag }}
│   ├── service.yaml
│   ├── ingress.yaml
│   └── NOTES.txt       # Post-installation instructions printed to terminal
└── charts/             # Dependency sub-charts
```

### Go-Templating in `templates/deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "mychart.fullname" . }}
spec:
  replicas: {{ .Values.replicaCount }}
  template:
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
```

---

## 3. Helm CLI Operations Cheat Sheet

```bash
# Add third-party Helm repository (e.g. Prometheus / Ingress-Nginx)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Search for available charts
helm search repo ingress-nginx

# Install or Upgrade a release idempotently (Standard CI/CD command!)
helm upgrade --install order-api ./charts/order-api \
  --namespace production \
  --create-namespace \
  --values ./environments/prod-values.yaml \
  --set image.tag="v2.4.0" \
  --atomic \
  --timeout 5m

# List all installed Helm releases
helm list -A

# View the release revision history
helm history order-api -n production

# Instant atomic rollback to previous revision
helm rollback order-api 2 -n production

# Render and test template YAML locally without applying to cluster (Dry-run)
helm template order-api ./charts/order-api --values prod-values.yaml
```

---

## 4. The Power of `helm upgrade --atomic`

In automated CI/CD pipelines, always pass **`--atomic`**:
- If any Pod crashes during deployment, or readiness probes fail within `--timeout 5m`, Helm **automatically rolls back the entire release** to the previous working revision!
- Prevents your cluster from getting stuck in half-deployed, corrupted states.

---

## 5. Interview & Review Questions
1. **Why was Tiller removed in Helm v3, and how does Helm v3 manage release state?**
   - *Answer*: Tiller was removed because it introduced major security vulnerabilities by requiring broad cluster-admin permissions that bypassed Kubernetes RBAC user auditing. Helm v3 operates purely client-side, respecting the caller's RBAC credentials, and stores release state directly inside encrypted Kubernetes Secrets within the release's target namespace.
2. **What does the `--atomic` flag do during `helm upgrade --install`?**
   - *Answer*: `--atomic` ensures transactional release behavior. If the deployment fails (e.g. pods fail health checks or image pull errors occur), Helm automatically purges failed resources and rolls the release back to the previous stable revision.
