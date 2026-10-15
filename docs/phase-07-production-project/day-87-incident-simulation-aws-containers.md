# Day 87: Incident Simulation 2 — AWS & Kubernetes Production Outages

## 1. Scenario 1: Kubernetes `OOMKilled` (Exit Code 137) Crash Loop

### Incident Report
- **Alert**: P1: Pod `checkout-api-68f4d9c-z8q2w` in namespace `prod` has restarted 14 times in 10 minutes.
- **Symptom**: `kubectl get pods -n prod` shows status: `CrashLoopBackOff`.

### Step-by-Step Triage & Resolution:
1. **Inspect Pod Description**:
   ```bash
   kubectl describe pod checkout-api-68f4d9c-z8q2w -n prod
   ```
   **Output**:
   ```text
   Last State:     Terminated
     Reason:       OOMKilled
     Exit Code:    137
   Limits:
     memory:       256Mi
   ```
2. **Root Cause Analysis**:
   The application memory usage exceeded the configured 256Mi limit due to a large batch data serialization in memory. The Linux kernel terminated the container with `SIGKILL` (Exit 137).
3. **Remediation**:
   - Immediate fix: Update deployment memory limit to `512Mi`:
     ```bash
     kubectl set resources deployment/checkout-api --limits=memory=512Mi -n prod
     ```
   - Long-term fix: Stream database cursor results instead of loading 50,000 records into memory simultaneously.

---

## 2. Scenario 2: EKS Pods Stuck in `ImagePullBackOff` After ECR Token Expiry

### Incident Report
- **Alert**: Deployment rollout of new release `v2.1.0` is stuck at 0/3 replicas available.
- **Symptom**: `kubectl get pods` shows `ImagePullBackOff`.

### Step-by-Step Triage & Resolution:
1. **Inspect Events**:
   ```bash
   kubectl describe pod <pod-name> -n prod | grep -A 4 Events:
   # Output: Failed to pull image: 401 Unauthorized (authorization token has expired)
   ```
2. **Root Cause Analysis**:
   The Kubernetes cluster was using a static `imagePullSecret` generated with `aws ecr get-login-password`, which has a hard maximum TTL of **12 hours**. The secret expired overnight!
3. **Remediation**:
   - Eliminate static Docker pull secrets!
   - Attach the `AmazonEC2ContainerRegistryReadOnly` IAM policy to the EKS Node IAM Role (or configure AWS IAM Roles for Service Accounts / IRSA).
   - Kubelet now authenticates to ECR automatically via IAM credentials with zero manual tokens!

---

## 3. Scenario 3: Broken Service Routing (Empty Endpoints)

### Incident Report
- **Alert**: Ingress returns `503 Service Temporarily Unavailable` to all web users.

### Step-by-Step Triage & Resolution:
1. **Check Service Endpoints**:
   ```bash
   kubectl get endpoints order-service -n prod
   # Output:
   # NAME            ENDPOINTS   AGE
   # order-service   <none>      42d
   ```
   Notice that `ENDPOINTS` is completely empty `<none>`!
2. **Compare Labels**:
   - Check Service selector: `kubectl get svc order-service -n prod -o yaml | grep -A 3 selector`
     `selector: { app: order-api }`
   - Check Pod labels: `kubectl get pods -n prod --show-labels`
     `labels: { app: order-service-api }`
3. **Root Cause**: A typo in the Deployment YAML label caused the Service selector to match zero Pods!
4. **Remediation**: Correct the Deployment labels to match the Service selector. Endpoints immediately populate and traffic resumes.

---

## 4. Key Takeaways
- `OOMKilled` (Exit 137) means the container exceeded memory limits.
- Never use static 12-hour Docker credentials for Amazon ECR in Kubernetes; always use IAM Roles for Service Accounts (IRSA).
- A 503 error on Kubernetes Services almost always means empty Endpoints caused by mismatched label selectors or failing Readiness Probes.
