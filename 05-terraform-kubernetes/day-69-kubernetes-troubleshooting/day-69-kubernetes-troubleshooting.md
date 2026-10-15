# Day 69: Kubernetes Production Troubleshooting Masterclass

## 1. The Structured Troubleshooting Mental Model

When a Kubernetes incident occurs, do not panic or make arbitrary changes. Follow the **Bottom-Up Diagnostic Funnel**:

```
+-------------------------------------------------------------------------------+
|  1. Pod Status Inspection                                                     |
|     kubectl get pods -n <ns>                                                  |
+-------------------------------------------------------------------------------+
                                 |
                                 v
+-------------------------------------------------------------------------------+
|  2. Cluster Events Analysis                                                   |
|     kubectl describe pod <pod-name> -n <ns> (Look at "Events:" section!)      |
+-------------------------------------------------------------------------------+
                                 |
                                 v
+-------------------------------------------------------------------------------+
|  3. Application Log Inspection                                                |
|     kubectl logs <pod-name> -n <ns> --previous                                |
+-------------------------------------------------------------------------------+
                                 |
                                 v
+-------------------------------------------------------------------------------+
|  4. Live Interactive Inspection                                               |
|     kubectl exec -it <pod-name> -n <ns> -- sh                                 |
+-------------------------------------------------------------------------------+
```

---

## 2. Top 5 Kubernetes Failure Modes & Instant Solutions

### 1. `CrashLoopBackOff`
- **Symptom**: Pod boots, crashes, and Kubernetes attempts to restart it with exponential backoff (10s, 20s, 40s...).
- **Root Causes**:
  - Application exception or missing environment variable.
  - Database connection failed.
  - Entrypoint command exited with non-zero code.
- **Triage**:
  ```bash
  # Check logs of the PREVIOUS crashed container instance!
  kubectl logs <pod-name> -n <ns> --previous
  ```

### 2. `ImagePullBackOff` / `ErrImagePull`
- **Symptom**: Pod cannot pull the specified container image.
- **Root Causes**:
  - Typo in image name or tag (`myimage:v1.0.0-typo`).
  - Private registry authentication failed (missing `imagePullSecrets` or ECR token expired).
  - Registry rate limit reached.
- **Triage**:
  ```bash
  kubectl describe pod <pod-name> -n <ns> | grep -A 5 Events:
  ```

### 3. `Pending` State (Pod Won't Schedule)
- **Symptom**: Pod remains in `Pending` indefinitely with zero containers running.
- **Root Causes**:
  - **Insufficient CPU / Memory**: Node requests exceed cluster capacity!
  - **Taints & Tolerations**: Node has a taint that the Pod does not tolerate.
  - **PVC Unbound**: PVC cannot find a matching PV or StorageClass.
- **Triage**:
  ```bash
  kubectl describe pod <pod-name> -n <ns>
  # Look for: "0/3 nodes are available: 3 Insufficient memory."
  ```

### 4. `OOMKilled` (Exit Code 137)
- **Symptom**: Pod was killed by the OS kernel.
- **Root Cause**: Container memory consumption exceeded its configured `resources.limits.memory`.
- **Solution**: Increase memory limit in Deployment YAML or profile the application for memory leaks.

### 5. Service Endpoint Connection Refused
- **Symptom**: Traffic hits Service IP or Ingress, but returns 502/503.
- **Triage**:
  ```bash
  # Verify if the Service actually found matching healthy Pods!
  kubectl get endpoints <service-name> -n <ns>
  ```
  - If `ENDPOINTS` is `<none>`, your Service `selector` labels do **NOT** match the Pod's labels!
  - If endpoints exist, the Pod's **Readiness Probe** is failing.

---

## 3. Essential Troubleshooting Commands

```bash
# Get events sorted by timestamp (see cluster problems across all resources)
kubectl get events -n production --sort-by='.metadata.creationTimestamp'

# Stream logs across all pods sharing a label
kubectl logs -f -l app=order-api -n production --all-containers=true

# Temporary debug container attached to a pod's network namespace
kubectl debug -it pod/order-api-xxx -n production --image=nicolaka/netshoot -- bash
```

---

## 4. Interview & Review Questions
1. **How do you diagnose why a Pod is stuck in `CrashLoopBackOff` if `kubectl logs <pod>` returns empty?**
   - *Answer*: When a pod crashes and restarts, `kubectl logs` by default queries the *new* (restarting) container instance. You must pass the `--previous` flag (`kubectl logs <pod> --previous`) to view the stdout/stderr emitted by the container right before it crashed.
2. **If `kubectl get endpoints <service-name>` returns `<none>`, what is the most likely cause?**
   - *Answer*: There is a mismatch between the `spec.selector` key-value labels defined on the Service and the `metadata.labels` declared on the Pod template in the Deployment, or all matching Pods are currently failing their Readiness Probes.
