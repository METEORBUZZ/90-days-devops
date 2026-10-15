# Day 33: S3 Security, Bucket Policies, Block Public Access & CloudFront Integration

## 1. Theoretical Foundation

### The S3 Security Paradigm
Leaked Amazon S3 buckets are among the most common causes of corporate data breaches. AWS enforces multiple defense-in-depth security layers to prevent accidental data exposure:

```
+-----------------------------------------------------------------------------------------+
|                                  INCOMING S3 REQUEST                                    |
+-----------------------------------------------------------------------------------------+
                                             |
                                             v
                 [ Layer 1: S3 Block Public Access (Account & Bucket Level) ]
                                             | (Passes only if public access not blocked)
                                             v
                 [ Layer 2: IAM Identity Policies (User / Role ARN) ]
                                             |
                                             v
                 [ Layer 3: S3 Bucket Policy (Resource-Based JSON) ]
                                             |
                                             v
                 [ Layer 4: Access Control Lists (ACLs - Legacy / Disabled) ]
                                             |
                                             v
                 [ Layer 5: KMS Encryption Keys (Decryption Authorization) ]
                                             |
                                             v
                                  [ ACCESS GRANTED ]
```

---

## 2. S3 Block Public Access (BPA)

Introduced by AWS to act as a global override switch preventing public leaks:
1. `BlockPublicAcls`: Rejects new public ACLs on buckets and objects.
2. `IgnorePublicAcls`: Ignores all existing public ACLs.
3. `BlockPublicPolicy`: Rejects bucket policies granting public access.
4. `RestrictPublicBuckets`: Restricts access to existing public buckets strictly to authorized users.

**Best Practice**: Keep all 4 Block Public Access settings set to **`true`** across every AWS account and bucket unless specifically building a public static website!

---

## 3. S3 Bucket Policies

A **Bucket Policy** is a resource-based JSON policy attached directly to the bucket.

### 1. Enforce TLS/HTTPS Encryption in Transit (Deny Insecure HTTP)
This is an industry-standard CIS benchmark compliance requirement:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EnforceTLSRequestsOnly",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::my-secure-company-data",
        "arn:aws:s3:::my-secure-company-data/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
```

---

## 4. Modern Static Website Hosting: S3 + CloudFront CDN + OAC

In legacy architectures, engineers enabled "S3 Static Website Hosting" and made the bucket completely public to the internet.
**Modern Production Standard (2026)**:
- Keep the S3 Bucket **100% PRIVATE** with all Block Public Access enabled!
- Place an **Amazon CloudFront Distribution** in front of the bucket.
- Use **Origin Access Control (OAC)** to permit ONLY CloudFront to fetch objects from S3.
- End users connect to CloudFront via custom HTTPS domain with free AWS ACM SSL/TLS certificates and DDoS protection via AWS Shield Standard.

```
[ User Browser ] --(HTTPS via CDN)--> [ Amazon CloudFront (Edge PoP) ]
                                                   |
                                     (Authenticated via OAC / SigV4)
                                                   v
                                     [ Private S3 Bucket (No Public Access) ]
```

### OAC Bucket Policy Example
```json
{
  "Version": "2012-10-17",
  "Statement": {
    "Sid": "AllowCloudFrontServicePrincipalReadOnly",
    "Effect": "Allow",
    "Principal": {
      "Service": "cloudfront.amazonaws.com"
    },
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::my-web-frontend-bucket/*",
    "Condition": {
      "StringEquals": {
        "AWS:SourceArn": "arn:aws:cloudfront::123456789012:distribution/EDFDVBD6EXAMPLE"
      }
    }
  }
}
```

---

## 5. Interview & Review Questions
1. **Why should you never make an S3 bucket public when hosting a modern production single-page application (React/Vue/Angular)?**
   - *Answer*: Public S3 websites only support plain unencrypted HTTP (no custom HTTPS without a proxy), lack global edge caching (resulting in high latency for global users), cannot attach Web Application Firewalls (AWS WAF), and leave raw storage infrastructure directly exposed to the internet. The modern architecture keeps the bucket private and routes all traffic through CloudFront with Origin Access Control (OAC).
2. **What does the condition `"aws:SecureTransport": "false"` do in an S3 bucket policy?**
   - *Answer*: When combined with `Effect: "Deny"`, it matches any incoming request sent over unencrypted plaintext HTTP and explicitly rejects it, enforcing TLS/HTTPS encryption in transit.
