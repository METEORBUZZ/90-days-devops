# Day 77: Cloud Security Auditing, IAM Hardening & KMS Envelope Encryption

## 1. Theoretical Foundation

Cloud security auditing ensures that your cloud infrastructure continuously complies with industry security baselines (such as CIS AWS Foundations Benchmark, SOC 2, and ISO 27001).

---

## 2. AWS KMS & Envelope Encryption

**AWS Key Management Service (KMS)** manages cryptographic keys used to encrypt data across S3, EBS, RDS, and Secrets Manager.

### What is Envelope Encryption?
Encrypting multi-gigabyte files directly with a KMS Master Key over the network would be slow and introduce bandwidth bottlenecks.
AWS solves this via **Envelope Encryption**:
1. You request a new **Data Key (DEK)** from KMS using your Customer Master Key (CMK / KMS Key).
2. KMS returns two keys:
   - A **Plaintext Data Key**.
   - An **Encrypted Data Key** (encrypted using the CMK).
3. Your application uses the **Plaintext Data Key** locally in memory to encrypt the large dataset fast using AES-256.
4. Your application **immediately destroys the Plaintext Data Key from RAM**!
5. The **Encrypted Data Key** is stored alongside the encrypted data ("the envelope").
6. To decrypt, you send the Encrypted Data Key back to KMS; only authorized IAM identities can request KMS to decrypt it!

```
[ Customer Master Key (KMS CMK) ] ---> Encrypts ---> [ Data Encryption Key (DEK) ] ---> Encrypts ---> [ 100GB Database ]
                                                      (Stored with data!)
```

---

## 3. Auditing with AWS CloudTrail & GuardDuty

### AWS CloudTrail (The Audit Blackbox)
Records every single API call made in your AWS account:
- Who called the API (`userIdentity`).
- What command was executed (`eventName`: e.g. `AuthorizeSecurityGroupIngress`, `DeleteBucket`).
- When it occurred (`eventTime`).
- Source IP address (`sourceIPAddress`).

*Security Rule: Enable CloudTrail Multi-Region Trail with log file validation and send logs to an encrypted, isolated audit account with S3 Object Lock.*

### Amazon GuardDuty (Intelligent Threat Detection)
An automated threat detection service that analyzes CloudTrail management logs, VPC Flow Logs, and DNS query logs using machine learning to detect compromised EC2 instances, unauthorized cryptomining, and credential exfiltration.

---

## 4. Advanced IAM Governance: Permission Boundaries

An **IAM Permission Boundary** is an advanced guardrail that sets the **maximum possible permissions** an IAM entity can have:
- Useful when delegating administrative rights to developers: developers can create their own IAM roles, but the Permission Boundary guarantees they cannot create a role with `AdministratorAccess` to elevate their own privileges!

---

## 5. Interview & Review Questions
1. **Explain Envelope Encryption and why it is used instead of direct encryption with a KMS Master Key.**
   - *Answer*: Envelope encryption uses a Customer Master Key (CMK) in KMS to encrypt a local Data Encryption Key (DEK), which in turn encrypts the actual data payload. This enables high-performance local data encryption without transmitting massive datasets over the network to KMS, while maintaining centralized key access control and auditing.
2. **What does AWS CloudTrail record, and why is it essential for incident response?**
   - *Answer*: CloudTrail records an immutable, chronological log of all API calls, CLI mutations, and console actions executed across an AWS account, including the caller identity, timestamp, source IP, and request parameters. It is essential for forensic investigations to identify how a breach occurred and what resources were compromised.
