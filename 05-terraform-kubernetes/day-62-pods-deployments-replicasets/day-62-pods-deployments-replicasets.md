# Day 62: Pods, ReplicaSets, Deployments & Rollout Management

## 1. Theoretical Foundation

### What is a Pod?
A **Pod** is the smallest, atomic deployable unit of computing in Kubernetes:
- A Pod represents a single instance of a running process in your cluster.
- A Pod can contain one container (most common) or multiple tightly coupled co-located containers (the **Sidecar Pattern**, e.g., an Envoy proxy sidecar or a log shipper).
- All containers inside the same Pod share:
  - The exact same **Network Namespace** (same IP address, can talk to each other via `localhost`!).
  - Shared storage **Volumes**.
  - Shared IPC namespace.

### The Deployment Hierarchy
You almost **never** deploy raw naked Pods in production. If a naked Pod dies, it is gone forever.
Instead, you use higher-level controllers:
```
+-------------------------------------------------------------+
|                      DEPLOYMENT                             |
|  - Manages Declarative Rollouts, Updates & Version Rollbacks|
+-------------------------------------------------------------+
                               |
                               v
+-------------------------------------------------------------+
|                      REPLICASET                             |
|  - Ensures exact desired count of identical Pods run        |
+-------------------------------------------------------------+
                               |
                               v
+-------------------------------------------------------------+
|                        PODS                                 |
|  [ Pod 1 ]               [ Pod 2 ]               [ Pod 3 ]  |
+-------------------------------------------------------------+
```

---

## 2. Production Deployment Specification (`deployment.yaml`)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-api
  namespace: production
  labels:
    app: order-api
    tier: backend
spec:
  replicas: 3
  revisionHistoryLimit: 10 # Retain 10 historical ReplicaSets for rollback
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Can spin up 1 extra pod above replica count during rollout
      maxUnavailable: 0  # Zero pods can be down during rollout (Guarantees zero-downtime!)
  selector:
    matchLabels:
      app: order-api
  template:
    metadata:
      labels:
        app: order-api
        tier: backend
    spec:
      containers:
        - name: api-server
          image: 123456789012.dkr.ecr.ap-south-1.amazonaws.com/order-api:v1.2.0
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 8080
              name: http
          resources:
            requests:
              cpu: "250m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
```

---

## 3. Deployment Lifecycle & Rollout Commands

```bash
# Apply deployment to cluster
kubectl apply -f deployment.yaml

# Inspect running pods with node assignments and IP addresses
kubectl get pods -n production -o wide

# Watch a rolling update in real-time
kubectl rollout status deployment/order-api -n production

# Update the container image to trigger a zero-downtime rolling update
kubectl set image deployment/order-api api-server=order-api:v1.3.0 -n production

# View the deployment revision history
kubectl rollout history deployment/order-api -n production

# Roll back to the immediately previous release
kubectl rollout undo deployment/order-api -n production

# Roll back to a specific historical revision number (e.g. revision 2)
kubectl rollout undo deployment/order-api --to-revision=2 -n production
```

---

## 4. How Kubernetes Executes a Zero-Downtime Rolling Update

When you update the image from `v1.2.0` to `v1.3.0` with `maxSurge: 1` and `maxUnavailable: 0`:
1. The Deployment creates a **new ReplicaSet** for `v1.3.0`.
2. It spins up 1 new Pod (`v1.3.0`). Total pods = 4 (3 old + 1 new surge).
3. Kubernetes waits until the new Pod passes its **Readiness Probe**.
4. Once healthy, traffic starts routing to the new Pod.
5. The Deployment terminates 1 old Pod (`v1.2.0`). Total pods = 3 (2 old + 1 new).
6. The process repeats sequentially until all 3 Pods are running `v1.3.0`.
7. The old ReplicaSet is scaled to 0 replicas, but **retained in memory** for instant rollback!

---

## 5. Interview & Review Questions
1. **Can two containers inside the same Kubernetes Pod communicate with each other over `localhost`?**
   - *Answer*: Yes. All containers within a single Pod share the same network namespace and IP address. Container A listening on port 8080 can be reached by Container B inside the same Pod via `http://localhost:8080`.
2. **What happens under the hood when you execute `kubectl rollout undo deployment/myapp`?**
   - *Answer*: The Deployment controller inspects its historical ReplicaSets. It scales up the previous ReplicaSet corresponding to the prior revision and scales down the current faulty ReplicaSet, triggering an inverted zero-downtime rolling update.
