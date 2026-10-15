# Day 65: Health Probes, Resource Requests/Limits & Pod Scheduling

## 1. Theoretical Foundation

### The Three Kubernetes Health Probes
The `kubelet` uses three distinct probes to monitor container health and manage traffic routing:

```
+-------------------------------------------------------------------------------+
| 1. Startup Probe                                                              |
| - Checks if slow-starting application (e.g. Java Spring Boot) has booted.     |
| - Disables Liveness and Readiness checks until startup succeeds!              |
+-------------------------------------------------------------------------------+
                                        | (Passes)
                                        v
+------------------------------------+    +------------------------------------+
| 2. Liveness Probe                  |    | 3. Readiness Probe                 |
| - Determines if container is ALIVE.|    | - Determines if container is READY |
| - If it FAILS: kubelet RESTARTS the|    |   to ACCEPT USER TRAFFIC.          |
|   container immediately!           |    | - If it FAILS: Pod is removed from |
|                                    |    |   Service Endpoints (NO restarts). |
+------------------------------------+    +------------------------------------+
```

---

## 2. Production Health Probes Configuration

```yaml
spec:
  containers:
    - name: api
      image: myapp:v1.0
      ports:
        - containerPort: 8080

      # 1. Startup Probe: Allows up to 60 seconds (12 * 5s) for legacy boot
      startupProbe:
        httpGet:
          path: /healthz
          port: 8080
        failureThreshold: 12
        periodSeconds: 5

      # 2. Liveness Probe: Detects deadlocks and restarts frozen processes
      livenessProbe:
        httpGet:
          path: /healthz
          port: 8080
        initialDelaySeconds: 10
        periodSeconds: 10
        timeoutSeconds: 3
        failureThreshold: 3

      # 3. Readiness Probe: Temporarily sheds traffic if DB connection pool saturates
      readinessProbe:
        httpGet:
          path: /ready
          port: 8080
        periodSeconds: 5
        timeoutSeconds: 2
        successThreshold: 1
        failureThreshold: 2
```

---

## 3. Resource Requests vs. Limits & QoS Classes

Every container in production **must** declare CPU and Memory requests and limits:
- **`requests`**: The guaranteed baseline resources guaranteed to the container. **The `kube-scheduler` uses requests to decide which node has enough capacity to place the Pod!**
- **`limits`**: The hard ceiling a container is allowed to consume on the node.

```yaml
resources:
  requests:
    cpu: "250m"      # 250 milli-CPUs = 0.25 CPU core
    memory: "512Mi"  # 512 Mebibytes of RAM
  limits:
    cpu: "1000m"     # 1 full CPU core
    memory: "1Gi"    # 1 Gibibyte of RAM
```

### What Happens When Limits Are Exceeded?
- **CPU Throttling**: CPU is a compressible resource. If a container exceeds its CPU limit, the Linux kernel CFS scheduler **throttles** execution cycles (performance degrades, but the process is NOT killed).
- **OOMKilled (Exit Code 137)**: Memory is non-compressible. If a container allocates more RAM than its memory limit, the Linux kernel invokes the `oom_killer` and **terminates the container immediately with Exit Code 137**!

### Quality of Service (QoS) Classes
1. **Guaranteed**: Requests == Limits for all containers. Lowest eviction priority during node memory pressure.
2. **Burstable**: Requests < Limits. Standard for web apps.
3. **BestEffort**: Zero requests and limits defined. First to be killed when node memory gets low!

---

## 4. Interview & Review Questions
1. **What is the difference between a Liveness Probe and a Readiness Probe? What happens when each fails?**
   - *Answer*: When a Liveness Probe fails, the `kubelet` assumes the container has crashed or deadlocked and restarts it. When a Readiness Probe fails, the container is **not** restarted; instead, Kubernetes immediately removes the Pod's IP from the Service EndpointSlice so it stops receiving user traffic until it recovers and passes the probe again.
2. **What does an exit code of 137 mean when inspecting a crashed Pod (`kubectl describe pod`)?**
   - *Answer*: Exit code 137 indicates that the process received signal 9 (`SIGKILL`, 128 + 9 = 137). In Kubernetes, this almost universally means the container was terminated by the Linux Out-Of-Memory (OOM) killer because it exceeded its configured memory limit or the worker node exhausted physical RAM.
