# Day 61: Kubernetes Architecture & Control Plane Internals

## 1. Theoretical Foundation

### What is Kubernetes (K8s)?
Kubernetes is an open-source container orchestration engine originally developed by Google (derived from their internal Borg system).
It automates:
- Container deployment across hundreds of worker nodes.
- Horizontal autoscaling (HPA) based on CPU, memory, or custom metrics.
- Automated self-healing (restarts crashed containers, replaces failed nodes).
- Load balancing and service discovery.
- Automated rolling updates and canary rollouts.

---

## 2. Complete Kubernetes Architectural Topology

```
+-----------------------------------------------------------------------------------------+
|                                KUBERNETES CONTROL PLANE                                 |
|                                                                                         |
|       +-------------------------------------------------------------------------+       |
|       |                     kube-apiserver (REST API Gateway)                   |       |
|       +-------------------------------------------------------------------------+       |
|               |                   |                             |                       |
|               v                   v                             v                       |
|      +-----------------+  +------------------+         +------------------+             |
|      |  etcd Cluster   |  |  kube-scheduler  |         |  kube-controller |             |
|      |  (State Store)  |  |  (Assigns Pods)  |         |  manager (Loops) |             |
|      +-----------------+  +------------------+         +------------------+             |
+-----------------------------------------------------------------------------------------+
                                         |
                                         | (TLS Encrypted Communication over port 6443)
                                         v
+-----------------------------------------------------------------------------------------+
|                                    WORKER NODES                                         |
|                                                                                         |
|  +----------------------------------+          +-------------------------------------+  |
|  |           WORKER NODE 1          |          |            WORKER NODE 2            |  |
|  |  [ kubelet ]       [ kube-proxy ]|          |  [ kubelet ]          [ kube-proxy ]|  |
|  |        \               /         |          |        \                  /         |  |
|  |    [ Containerd Runtime ]        |          |    [ Containerd Runtime ]           |  |
|  |              |                   |          |              |                      |  |
|  |      +-------+-------+           |          |      +-------+-------+              |  |
|  |      v               v           |          |      v               v              |  |
|  |  [ Pod 1 ]       [ Pod 2 ]       |          |  [ Pod 3 ]       [ Pod 4 ]          |  |
|  +----------------------------------+          +-------------------------------------+  |
+-----------------------------------------------------------------------------------------+
```

---

## 3. Control Plane Components Breakdown

### 1. `kube-apiserver` (The Heart)
- The central REST API gateway and only component that directly talks to `etcd`.
- Handles authentication, authorization (RBAC), admission control, and validation.
- Every other component (`scheduler`, `kubelet`, `controller-manager`, `kubectl`) communicates exclusively through the API Server!

### 2. `etcd` (The Source of Truth)
- A highly available, distributed, consistent key-value store implementing the **Raft consensus algorithm**.
- Stores the entire state and specification of the Kubernetes cluster.
- *Production Rule*: Back up `etcd` snapshots daily! If `etcd` is lost without backups, your cluster state is permanently gone.

### 3. `kube-scheduler`
- Watches for newly created Pods that have no assigned node (`nodeName: ""`).
- Evaluates worker node capacity (CPU/RAM requests, taints, tolerations, node affinity) and selects the optimal node to host each Pod.

### 4. `kube-controller-manager`
- Runs continuous control loops (Reconciliation Loops) comparing the **Desired State** (declared in YAML) against the **Actual State** (live cluster).
- Sub-controllers: `Node Lifecycle Controller`, `Replication Controller`, `EndpointSlice Controller`, `ServiceAccount Controller`.

---

## 4. Worker Node Components Breakdown

### 1. `kubelet` (The Node Agent)
- The primary agent running on each worker node.
- Registers the node with the API server.
- Watches for Pod specs assigned to its node and instructs the container runtime (`containerd`, `CRI-O`) to pull images and start/stop containers.
- Executes liveness and readiness health check probes.

### 2. `kube-proxy`
- The network proxy running on each node.
- Implements Kubernetes Service networking by programming Linux kernel `iptables` or IPVS rules to route traffic across Pod IPs.

### 3. Container Runtime (`containerd` / `CRI-O`)
- The low-level software that executes containers via the Container Runtime Interface (CRI). (Docker-in-Docker is deprecated; modern clusters use containerd directly).

---

## 5. Interview & Review Questions
1. **Can any component in Kubernetes write directly to `etcd` besides `kube-apiserver`?**
   - *Answer*: No. The `kube-apiserver` is the sole component in the cluster authorized to read or write directly to `etcd`. All other control plane daemons (`kube-scheduler`, `controller-manager`) and worker node agents (`kubelet`) must communicate with the API server over secure TLS.
2. **What happens in a Kubernetes cluster if the `kube-scheduler` crashes or becomes unresponsive?**
   - *Answer*: Existing Pods and running container workloads continue executing on worker nodes completely uninterrupted. However, any newly created Pods (from scaling events, rolling updates, or self-healing replacements) will remain stuck in the `Pending` state because no scheduler is available to bind them to nodes.
