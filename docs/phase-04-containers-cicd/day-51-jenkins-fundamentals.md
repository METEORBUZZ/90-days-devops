# Day 51: Jenkins Architecture, Controller/Agent Topology & Credential Security

## 1. Theoretical Foundation

### What is Jenkins?
Jenkins is the leading self-hosted, open-source automation server used by thousands of enterprises for orchestrating complex build, test, and deployment workflows.
While modern SaaS CI/CD tools (like GitHub Actions) are popular for public cloud workloads, Jenkins remains ubiquitous in enterprise banks, defense, and on-premises hybrid environments requiring custom hardware and complete data sovereignty.

---

## 2. Controller-Agent (Master-Worker) Architecture

```
+-------------------------------------------------------------------------+
|                       JENKINS CONTROLLER (Master)                       |
|  - Web UI & REST API Dashboard                                         |
|  - Stores Configuration & Job Definitions (JENKINS_HOME)                |
|  - Schedules Builds & Monitors Job Queues                               |
|  - Dispatches Tasks to Agents (NEVER executes heavy builds directly!)   |
+-------------------------------------------------------------------------+
                                     |
              +----------------------+----------------------+
              | (SSH / JNLP / Inbound Webhook over port 50000)      |
              v                                             v
+-----------------------------+               +-----------------------------+
|    JENKINS LINUX AGENT      |               |   DYNAMIC KUBERNETES AGENT  |
|  (Dedicated VM / EC2)       |               |  (Ephemeral Pod spawned     |
|  - Executes Docker builds   |               |   on demand; destroyed      |
|  - Runs Pytest & Linters    |               |   immediately after build)  |
+-----------------------------+               +-----------------------------+
```

### Golden Security Rule: Never Build on Controller!
Never execute builds on the Jenkins Controller (`executor count = 0`). If a malicious user commits a pipeline script with `sh 'cat /var/jenkins_home/secrets/master.key'`, they can steal all stored credentials across the enterprise! All builds must strictly run on isolated worker agents.

---

## 3. Jenkins Secure Credential Store

Jenkins stores credentials encrypted with AES-256 in its credentials manager:
- **Secret Text**: API tokens (Slack tokens, SonarQube keys).
- **Username with Password**: Docker Hub / Git credentials.
- **SSH Username with Private Key**: For deployment targets and Git clones.
- **Secret File**: `.kube/config`, AWS credential files.

### Injecting Credentials Safely into Pipelines
In Declarative Pipelines, bind credentials securely using `credentials('my-secret-id')`:
```groovy
environment {
    DOCKER_CREDS = credentials('dockerhub-deployer-token')
}
```
Jenkins **automatically masks** the credential string with `****` in console logs to prevent accidental credential leakage!

---

## 4. Hardening Jenkins in Production

1. **Enable Role-Based Access Control (RBAC)**: Use the "Role-based Authorization Strategy" plugin instead of giving all engineers full admin rights.
2. **Enforce HTTPS (TLS)**: Always place Jenkins behind a reverse proxy (Nginx or AWS Application Load Balancer).
3. **Keep Plugins Updated**: Outdated Jenkins plugins are the #1 attack vector for Jenkins breaches. Enable automated vulnerability scans.
4. **Disable Agent JNLP Port 50000** if not in use.

---

## 5. Interview & Review Questions
1. **Why should the build executor count on a Jenkins Controller be set to 0?**
   - *Answer*: To prevent build jobs from running on the controller node. If builds run on the controller, untrusted code or compromised pipeline scripts can read sensitive cryptographic keys, plugin data, and master credentials stored in `$JENKINS_HOME`, or consume all controller CPU and crash the entire CI/CD infrastructure.
2. **How does Jenkins ensure secrets are not leaked into console logs when outputting shell commands?**
   - *Answer*: Jenkins intercepts the stdout/stderr stream from the agent and replaces any occurrence of strings associated with registered credentials with asterisks (`****`) before writing the output to the build console log.
