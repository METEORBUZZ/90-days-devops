# Day 63: Kubernetes Services, CoreDNS & Ingress Controllers

## 1. Theoretical Foundation

### The Ephemeral Pod IP Problem
In Kubernetes, Pods are ephemeral. If a node crashes, a Pod is killed, or a deployment scales up/down:
- Old Pods are destroyed and new Pods are assigned **completely new, dynamic IP addresses**.
- How do frontend microservices reliably reach backend databases without hardcoding unstable Pod IPs?

**The Solution: Kubernetes Services!**
A **Service** provides an immutable, static virtual IP (VIP) and stable DNS hostname that automatically load-balances traffic across a dynamic set of matching Pods selected by **Labels**.

```
[ Frontend Microservice ]
            |
            | (Calls stable DNS: "order-db.production.svc.cluster.local")
            v
+-------------------------------------------------------------+
|             KUBERNETES SERVICE (ClusterIP: 10.96.0.45)      |
|  - Stable Virtual IP & DNS name                             |
|  - Selected by: app=order-db                                |
+-------------------------------------------------------------+
               /                             \
              v                               v
    [ Pod 1: 172.16.2.14 ]          [ Pod 2: 172.16.4.88 ]
    (Backend Replica)               (Backend Replica)
```

---

## 2. The 4 Kubernetes Service Types

| Service Type | Scope | How It Works | Best Use Case |
| :--- | :--- | :--- | :--- |
| **`ClusterIP` (Default)** | Internal only | Allocates an internal cluster-only virtual IP. Unreachable from outside the cluster. | Internal inter-service communication (APIs, Databases, Caches) |
| **`NodePort`** | Cluster + Node LAN | Opens a dedicated port (range: `30000–32767`) on **every worker node's physical IP**. | Legacy integrations, on-premises bare-metal setups |
| **`LoadBalancer`** | Public Internet | Integrates with cloud provider (AWS, GCP, Azure) to automatically provision an external Load Balancer (e.g. AWS NLB/ALB). | Public-facing services requiring direct L4/L7 cloud load balancing |
| **`ExternalName`** | Internal DNS redirect | Maps a Kubernetes service name directly to an external CNAME (e.g. `database.rds.amazonaws.com`). | Consuming external databases via internal DNS |

---

## 3. Production Service Definition (`service.yaml`)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: order-service
  namespace: production
  labels:
    app: order-service
spec:
  type: ClusterIP
  selector:
    app: order-api # Matches Pods having label 'app: order-api'
  ports:
    - name: http
      port: 80         # Port exposed BY THE SERVICE inside the cluster
      targetPort: 8080 # Port where the CONTAINER listens inside the Pod
      protocol: TCP
```

### CoreDNS Resolution Format
Any Pod in any namespace can reach this service via fully qualified domain name (FQDN):
`<service-name>.<namespace>.svc.cluster.local`
- From the same namespace: `http://order-service`
- From a different namespace: `http://order-service.production`

---

## 4. Kubernetes Ingress & Ingress Controllers

While `LoadBalancer` services provision one cloud load balancer per service (expensive! $25/mo per service on AWS), an **Ingress** acts as a unified L7 reverse proxy router.
A single **Ingress Controller** (e.g. Ingress-Nginx, Traefik, AWS Load Balancer Controller) routes hundreds of microservices based on HTTP hosts and paths with unified SSL/TLS termination!

```
                                  [ Internet Users ]
                                          |
                                          v
                              [ AWS Application Load Balancer ]
                                          |
                                          v
                              [ NGINX Ingress Controller ]
                                     /          \
            Path: /api/orders       /            \ Path: /api/users
                                   v              v
                          [ Order Service ]   [ User Service ]
```

### Production Ingress YAML:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: main-ingress
  namespace: production
  annotations:
    kubernetes.io/ingress.class: "nginx"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
    - hosts:
        - api.mycompany.com
      secretName: api-tls-cert
  rules:
    - host: api.mycompany.com
      http:
        paths:
          - path: /api/v1/orders
            pathType: Prefix
            backend:
              service:
                name: order-service
                port:
                  number: 80
          - path: /api/v1/users
            pathType: Prefix
            backend:
              service:
                name: user-service
                port:
                  number: 80
```

---

## 5. Interview & Review Questions
1. **What is the difference between `port` and `targetPort` in a Kubernetes Service?**
   - *Answer*: `port` is the port number on which the Service itself listens and exposes inside the cluster. `targetPort` is the port number on the container inside the Pod where application traffic is actually forwarded.
2. **How does a Kubernetes Service discover which Pods to send traffic to?**
   - *Answer*: The Service uses **Label Selectors** (e.g. `selector: { app: myapp }`). The Kubernetes EndpointSlice controller continuously tracks Pods matching those labels and populates an `Endpoints` list containing the active Pod IP addresses.
