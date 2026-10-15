# Day 36: Security Groups vs. Network ACLs (NACLs) & Defense-in-Depth

## 1. Theoretical Foundation

AWS provides two distinct layers of virtual network filtering inside a VPC:
1. **Network Access Control Lists (NACLs)**: Protect the **Subnet** boundary.
2. **Security Groups (SGs)**: Protect the **Instance / ENI** boundary.

Together, they form a two-tier defense-in-depth perimeter:

```
[ Incoming Internet Packet ]
             |
             v
+------------------------------------------+
|  Layer 1: Network ACL (NACL)             | ---> Evaluates Subnet Rules (Numbered, Stateless)
|  [ Subnet Boundary ]                     |
+------------------------------------------+
             | (If Allowed)
             v
+------------------------------------------+
|  Layer 2: Security Group (SG)            | ---> Evaluates Instance Rules (Stateful)
|  [ ENI / Instance Boundary ]             |
+------------------------------------------+
             | (If Allowed)
             v
    [ EC2 Instance OS ]
```

---

## 2. Comparison Matrix: Security Groups vs. NACLs

| Feature | Security Group (SG) | Network ACL (NACL) |
| :--- | :--- | :--- |
| **Operates At** | Instance / ENI Level | Subnet Level |
| **State Tracking** | **Stateful**: Return traffic is automatically allowed, regardless of rules. | **Stateless**: Inbound and outbound traffic must be explicitly allowed separately. |
| **Rule Types** | **ALLOW rules only** (Implicit deny for everything else). | **ALLOW and DENY rules** supported. |
| **Rule Evaluation** | All rules are evaluated simultaneously before deciding. | Evaluated sequentially in **numerical rule order** (lowest number first; e.g. rule 100 before 200). |
| **Ephemeral Return Ports** | Automatically handled by state connection tracking. | **Must explicitly open outbound ephemeral ports** (1024–65535)! |

---

## 3. The NACL Ephemeral Port Gotcha

Because NACLs are **stateless**, the most common pitfall that stumps junior cloud engineers is forgetting outbound ephemeral ports.

### Scenario: Client sends an HTTP request to your web server on port 80:
1. Client connects from ephemeral port `49152` to Server port `80`.
2. **Inbound NACL**: Must allow port `80` inbound.
3. Server processes request and responds from port `80` back to Client's ephemeral port `49152`.
4. **Outbound NACL**: **MUST explicitly allow outbound TCP traffic to ports `1024–65535`!** If outbound rules only allow port 80, the response packet is dropped by the NACL, and the client times out!

### Recommended Production NACL Rules
```text
Inbound:
Rule #    Type        Protocol   Port Range   Source         Allow/Deny
100       HTTP        TCP        80           0.0.0.0/0      ALLOW
110       HTTPS       TCP        443          0.0.0.0/0      ALLOW
120       SSH         TCP        22           Corporate-IP   ALLOW
*         ALL         ALL        ALL          0.0.0.0/0      DENY (Default)

Outbound:
Rule #    Type        Protocol   Port Range   Destination    Allow/Deny
100       Custom TCP  TCP        1024-65535   0.0.0.0/0      ALLOW (Ephemeral Return Ports!)
*         ALL         ALL        ALL          0.0.0.0/0      DENY (Default)
```

---

## 4. When to Use NACLs vs. Security Groups

- **Security Groups** are your day-to-day workhorse. Define granular application access between microservice tiers (e.g. `Allow SG-ALB -> SG-App on 8080`, `Allow SG-App -> SG-DB on 5432`).
- **NACLs** are reserved for broad, subnet-wide security enforcements:
  - **Blocking malicious IP addresses / botnets**: Because Security Groups cannot deny specific IPs, use NACL Rule #10: `DENY 203.0.113.55/32`.
  - Creating strict DMZ or compliance boundaries across entire subnets.

---

## 5. Interview & Review Questions
1. **You want to block a specific malicious IP address (`198.51.100.4`) that is attacking your web application. Can you do this in a Security Group?**
   - *Answer*: No. Security Groups only support `Allow` rules; they do not have `Deny` rules. You must add an explicit `Deny` rule for `198.51.100.4/32` at the Network ACL (NACL) level with a lower rule number than the general allow rules.
2. **Why does an SSH connection work through a Security Group without configuring an outbound rule for the client's port, but fails in a custom NACL?**
   - *Answer*: Security Groups are stateful; when an inbound SSH packet on port 22 is permitted, the state table automatically tracks the connection and permits the outbound return packets to the client's ephemeral port. NACLs are stateless and evaluate inbound and outbound packets completely independently; without an explicit outbound rule permitting ports 1024–65535, the SSH handshake response is dropped at the subnet boundary.
