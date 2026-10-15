# Day 64: ConfigMaps, Secrets & External Configuration Management

## 1. Theoretical Foundation

### Decoupling Configuration from Container Images (12-Factor App)
The third factor of the Twelve-Factor App methodology states: **"Store config in the environment."**
- Never hardcode database URLs, logging levels, or API keys into Docker images.
- An identical container image should run seamlessly in Development, Staging, and Production by simply changing external configuration objects.

### ConfigMaps vs. Secrets
- **ConfigMap**: For non-confidential configuration data (log levels, database hostnames, Nginx configs, feature flags). Stored as UTF-8 plaintext.
- **Secret**: For confidential data (passwords, TLS certificates, OAuth tokens).
  - *Standard K8s Secret Warning*: By default in Kubernetes, Secrets are **only Base64-encoded, NOT cryptographically encrypted** in `etcd` unless encryption-at-rest is enabled on the API server!

---

## 2. Defining & Mounting ConfigMaps

`configmap.yaml`:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: production
data:
  LOG_LEVEL: "INFO"
  DB_HOST: "postgres-cluster.internal"
  DB_PORT: "5432"
  # Multiline configuration files can be embedded directly!
  nginx.conf: |
    server {
        listen 80;
        location / {
            proxy_pass http://localhost:8080;
        }
    }
```

---

## 3. Defining & Mounting Secrets

`secret.yaml`:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: production
type: Opaque
stringData: # Use stringData to avoid manual base64 encoding!
  DB_PASSWORD: "SuperSecretProductionPassword2026!"
  API_KEY: "live_pk_9948210492"
```

---

## 4. Consuming Configurations inside Pods

Kubernetes supports two primary methods to consume ConfigMaps and Secrets inside Pods:

### Method A: As Environment Variables (`envFrom`)
```yaml
spec:
  containers:
    - name: api
      image: myapp:v1.0
      envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: app-secrets
```
All keys in the ConfigMap and Secret are automatically exposed as environment variables (`$LOG_LEVEL`, `$DB_PASSWORD`) inside the container process.

### Method B: As Mounted Files in a Volume (`volumes`)
Best for complex configuration files (`nginx.conf`, SSL certs, properties files):
```yaml
spec:
  containers:
    - name: web
      image: nginx:alpine
      volumeMounts:
        - name: config-volume
          mountPath: /etc/nginx/conf.d
          readOnly: true
  volumes:
    - name: config-volume
      configMap:
        name: app-config
        items:
          - key: nginx.conf
            path: default.conf
```
*Advantage of Volume Mounts: When you update the ConfigMap, Kubernetes automatically updates the mounted file on disk inside the container without restarting the Pod! (Environment variables require a Pod restart).*

---

## 5. Enterprise Secret Governance: External Secrets Operator (ESO)

Never commit raw Kubernetes `secret.yaml` files to Git!
In production, use the **External Secrets Operator (ESO)**:
- Connects Kubernetes directly to enterprise secret stores (**AWS Secrets Manager**, HashiCorp Vault, Azure Key Vault).
- Automatically synchronizes secrets into native Kubernetes Secret objects.
- Git repository contains only safe pointer manifests (`ExternalSecret`), keeping secrets 100% out of version control.

---

## 6. Interview & Review Questions
1. **Are native Kubernetes Secrets encrypted by default?**
   - *Answer*: No. By default, Kubernetes Secrets are simply stored as Base64-encoded plaintext strings. Any user with read access to the namespace or direct access to `etcd` can decode them (`echo <val> | base64 -d`). To make them secure, administrators must enable encryption-at-rest with KMS in `kube-apiserver` or use external secret operators like HashiCorp Vault or AWS Secrets Manager.
2. **What is the difference between injecting a ConfigMap as an environment variable versus mounting it as a volume?**
   - *Answer*: Environment variables are injected only at process initialization time; updating the ConfigMap does not update running processes until Pods are restarted. Volume-mounted ConfigMaps are updated dynamically in near real-time on the container's filesystem by the kubelet without requiring Pod restarts.
