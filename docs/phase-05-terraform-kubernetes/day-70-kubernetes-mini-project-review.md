# Day 70: Kubernetes Capstone Mini-Project — Production Microservice Deployment

## 1. Project Overview & Architecture

In this Phase 5 capstone project, you will deploy a complete, production-grade cloud-native microservice architecture featuring:
1. **Multi-Replica Deployment** with zero-downtime rolling update strategy.
2. **Startup, Liveness & Readiness Probes**.
3. **Resource Requests & Limits** to prevent noisy-neighbor node crashes.
4. **Decoupled ConfigMap & Secret** injection.
5. **ClusterIP Service** with label selector binding.
6. **Horizontal Pod Autoscaler (HPA)** automatically scaling replicas between 2 and 10 based on CPU load.
7. **Pod Disruption Budget (PDB)** guaranteeing high availability during cluster node maintenance.

```
                                  [ Ingress Controller ]
                                            |
                                            v
                                 [ ClusterIP Service ]
                                            |
                                            v
+-----------------------------------------------------------------------------------------+
|                                    DEPLOYMENT FLEET                                     |
|                                                                                         |
|  +--------------------+     +--------------------+     +--------------------+           |
|  |       Pod 1        |     |       Pod 2        |     |       Pod 3        |           |
|  |  - ConfigMap / Env |     |  - ConfigMap / Env |     |  - ConfigMap / Env |           |
|  |  - Secret / Env    |     |  - Secret / Env    |     |  - Secret / Env    |           |
|  |  - Health Probes   |     |  - Health Probes   |     |  - Health Probes   |           |
|  +--------------------+     +--------------------+     +--------------------+           |
|                                       ^                                                 |
|                                       | (Autoscales based on 70% CPU target)           |
|                        [ Horizontal Pod Autoscaler (HPA) ]                              |
+-----------------------------------------------------------------------------------------+
```

---

## 2. Complete Production Manifest (`production-app.yaml`)

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: production-fleet

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: order-api-config
  namespace: production-fleet
data:
  APP_ENV: "production"
  PORT: "8080"
  LOG_LEVEL: "info"

---
apiVersion: v1
kind: Secret
metadata:
  name: order-api-secrets
  namespace: production-fleet
type: Opaque
stringData:
  DB_PASSWORD: "ProdMasterSecurePassword2026!"

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-api
  namespace: production-fleet
  labels:
    app.kubernetes.io/name: order-api
    app.kubernetes.io/tier: backend
spec:
  replicas: 3
  revisionHistoryLimit: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 0
  selector:
    matchLabels:
      app.kubernetes.io/name: order-api
  template:
    metadata:
      labels:
        app.kubernetes.io/name: order-api
        app.kubernetes.io/tier: backend
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001
        runAsGroup: 10001
        fsGroup: 10001
      containers:
        - name: order-api
          image: nginxdemos/hello:plain-text
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 80
              name: http
          envFrom:
            - configMapRef:
                name: order-api-config
            - secretRef:
                name: order-api-secrets
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 256Mi
          startupProbe:
            httpGet:
              path: /
              port: 80
            failureThreshold: 10
            periodSeconds: 3
          livenessProbe:
            httpGet:
              path: /
              port: 80
            periodSeconds: 10
            timeoutSeconds: 2
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /
              port: 80
            periodSeconds: 5
            timeoutSeconds: 2
            failureThreshold: 2

---
apiVersion: v1
kind: Service
metadata:
  name: order-api-service
  namespace: production-fleet
spec:
  type: ClusterIP
  selector:
    app.kubernetes.io/name: order-api
  ports:
    - name: http
      port: 80
      targetPort: 80
      protocol: TCP

---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: order-api-hpa
  namespace: production-fleet
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: order-api
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70

---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: order-api-pdb
  namespace: production-fleet
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: order-api
```

---

## 3. Verification & Chaos Testing

```bash
# Apply full stack
kubectl apply -f production-app.yaml

# Verify all pods are running and healthy
kubectl get pods -n production-fleet

# Verify HPA is tracking CPU utilization
kubectl get hpa -n production-fleet

# Simulate traffic spike to trigger autoscaling
kubectl run -it --rm load-generator --image=busybox -n production-fleet -- /bin/sh -c \
  "while true; do wget -q -O- http://order-api-service; done"
```

---

## 4. Phase 5 Milestone Completed!

🎉 **Congratulations! You have mastered Phase 5: Infrastructure as Code & Orchestration.**
You now possess industry-grade expertise in:
- Declarative Terraform syntax, provider plugins, and DAG dependency graphs.
- Parameterized modules, type validation, locals, and outputs.
- S3 + DynamoDB remote state locking and disaster recovery.
- Multi-environment directory layout and Checkov security scanning.
- Kubernetes Control Plane internals (`kube-apiserver`, `etcd`, `scheduler`, `controller-manager`).
- Pod lifecycle, ReplicaSets, and zero-downtime rolling updates.
- ClusterIP, NodePort, LoadBalancer services, CoreDNS, and Ingress routing.
- ConfigMaps, Secrets, External Secrets Operator, and volume mounts.
- Liveness, Readiness, and Startup probes, CPU/Memory QoS, and OOMKilled resolution.
- Dynamic storage provisioning via StorageClasses, PersistentVolumes, and StatefulSets.
- Kubernetes RBAC authorization and Pod security contexts.
- Helm v3 charts, templating, and atomic rollbacks.
- Structured Kubernetes troubleshooting for `CrashLoopBackOff`, `ImagePullBackOff`, and service routing.

Next: **Phase 6 — Monitoring, Security & Reliability (Days 71–80)**!
