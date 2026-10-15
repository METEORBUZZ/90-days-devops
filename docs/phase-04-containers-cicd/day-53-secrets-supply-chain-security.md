# Day 53: Secrets Management & Software Supply Chain Security

## 1. Theoretical Foundation

### The Modern Threat: Supply Chain Attacks
Software supply chain security focuses on verifying the integrity of everything that goes into your final deployment artifact:
- Third-party open-source libraries (`npm`, `pip`, `maven`).
- CI/CD build scripts and GitHub Actions from third-party marketplaces.
- Base container images.
- Secrets used to authenticate builds to cloud providers.

Recent high-profile attacks (e.g. SolarWinds, Codecov, malicious PyPI packages) demonstrated that attackers target vulnerable CI/CD pipelines to inject backdoors into production code.

---

## 2. Keyless Cloud Authentication via OIDC (OpenID Connect)

**Eliminate Static Cloud Credentials from GitHub Secrets!**
Traditionally, engineers created static IAM access keys (`AKIA...`) and stored them in GitHub Secrets. If those keys leak or an action is compromised, attackers gain permanent cloud access.

**Modern Standard: OpenID Connect (OIDC)**:
GitHub Actions requests a short-lived OIDC JSON Web Token (JWT) directly from GitHub. AWS STS validates the cryptographic signature of the token and grants **temporary 1-hour IAM credentials** without any static keys!

```
[ GitHub Actions Runner ]
           |
           | 1. Requests OIDC JWT token from GitHub
           v
[ GitHub OIDC Identity Provider ]
           |
           | 2. Passes JWT to AWS STS AssumeRoleWithWebIdentity
           v
[ AWS STS (Security Token Service) ]
           |
           | 3. Returns temporary 1-hour credentials
           v
[ GitHub Actions Deploys to AWS S3/EC2/EKS ]
```

### GitHub Actions OIDC Workflow Example:
```yaml
name: Deploy via AWS OIDC

permissions:
  id-token: write # Mandatory to request the OIDC JWT token!
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS Credentials via OIDC (No Static Keys!)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsDeployRole
          aws-region: ap-south-1

      - name: Verify AWS Identity
        run: aws sts get-caller-identity
```

---

## 3. Pinning GitHub Actions to Full Commit SHAs

Never use mutable version tags like `@v4` or `@main` for third-party marketplace actions in production pipelines! If a developer's GitHub account is compromised, an attacker can re-tag `@v4` with malicious code that steals your environment secrets!

### Anti-Pattern:
```yaml
- uses: third-party-org/upload-action@v2 # Mutable tag! Can be overwritten!
```

### Production Security Best Practice:
```yaml
# Pin to exact 40-character commit SHA with a comment for readability:
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
```

---

## 4. Software Bill of Materials (SBOM)

An **SBOM (Software Bill of Materials)** is a formal, machine-readable inventory listing all software components, libraries, versions, and license details packed inside an application.
Use tools like **Syft** to generate an SBOM in CycloneDX or SPDX format:

```bash
# Generate SBOM for a container image
syft packages my-app:latest -o cyclonedx-json > sbom.json
```

---

## 5. Interview & Review Questions
1. **Why is OIDC (OpenID Connect) authentication superior to storing static AWS Access Keys in GitHub Secrets?**
   - *Answer*: Static AWS Access Keys are long-lived credentials that must be manually rotated and risk being leaked or exfiltrated. OIDC uses cryptographic token exchange with AWS STS to dynamically issue temporary, short-lived credentials that expire automatically, eliminating static credentials entirely.
2. **Why should enterprise CI/CD pipelines pin third-party GitHub Actions to a 40-character commit SHA instead of a version tag like `@v3`?**
   - *Answer*: Git tags are mutable pointers that can be moved or deleted by repository maintainers. If a third-party maintainer's account is compromised, an attacker can update the tag to point to malicious code that steals pipeline secrets. A 40-character commit SHA is cryptographically immutable.
