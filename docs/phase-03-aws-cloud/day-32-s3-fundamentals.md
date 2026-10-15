# Day 32: Amazon S3 Architecture, Storage Classes & Lifecycle Management

## 1. Theoretical Foundation

### What is Amazon Simple Storage Service (S3)?
Amazon S3 is an object storage service offering industry-leading scalability, data availability, security, and performance.
Key Architectural Properties:
- **Object Storage**: Data is stored as individual Objects (files) inside Buckets (root containers).
- **Global Namespace**: Bucket names are globally unique across all AWS accounts worldwide (`my-company-prod-assets-2026`).
- **Durability**: **99.999999999% (11 9s)** durability by automatically replicating object data across a minimum of 3 Availability Zones within a region.
- **Strong Consistency**: S3 delivers strong read-after-write consistency for PUT and DELETE requests of objects in all regions without delay.

### Anatomy of an S3 Object
- **Key**: The full name/path of the object (`uploads/2026/10/report.pdf`).
- **Value**: The raw byte payload (0 bytes up to 5 TB per single object).
- **Version ID**: Unique string identifying the historical version of the object.
- **Metadata**: Key-value pairs (Content-Type, system timestamps, custom tags).
- **Access Control List (ACL)** / Bucket Policies: Security permissions.

---

## 2. Amazon S3 Storage Classes

Optimizing storage tiers is one of the highest-impact cost-saving responsibilities for DevOps engineers:

| Storage Class | Durability | Availability | Retrieval Fee | Best Use Case |
| :--- | :--- | :--- | :--- | :--- |
| **S3 Standard** | 99.999999999% | 99.99% | None | Frequently accessed data, active web assets, CI artifacts |
| **S3 Intelligent-Tiering** | 99.999999999% | 99.9% | None | Unknown or fluctuating access patterns (auto-moves objects between frequent and infrequent tiers) |
| **S3 Standard-IA (Infrequent Access)** | 99.999999999% | 99.9% | Yes (per GB) | Long-term backups, disaster recovery data accessed < once a month |
| **S3 One Zone-IA** | 99.999999999% (1 AZ) | 99.5% | Yes (per GB) | Secondary backups that can be re-created if AZ fails |
| **S3 Glacier Flexible Retrieval** | 99.999999999% | 99.9% | Yes | Archival data retrievable within minutes to hours |
| **S3 Glacier Deep Archive** | 99.999999999% | 99.9% | Yes | Lowest cost cloud storage (retrieval: 12-48 hours; regulatory compliance) |

---

## 3. S3 Bucket Versioning & MFA Delete

**Versioning** preserves, retrieves, and restores every version of every object stored in an S3 bucket.
- Protects against accidental overwrites and malicious deletions.
- When an object is deleted in a versioned bucket, S3 adds a **Delete Marker** rather than erasing the data blocks. The object can be restored instantly by deleting the marker!
- **MFA Delete**: Enforces hardware token MFA confirmation before anyone (including root) can permanently delete a version or change versioning state.

```bash
# Enable versioning on a bucket
aws s3api put-bucket-versioning \
  --bucket my-devops-backup-bucket-2026 \
  --versioning-configuration Status=Enabled
```

---

## 4. S3 Object Lifecycle Management Rules

Automate data tiering to minimize storage costs without manual intervention:

```xml
<!-- Example: Transition objects to Glacier after 90 days, delete after 365 days -->
<LifecycleConfiguration>
  <Rule>
    <ID>ArchiveOldBuildArtifacts</ID>
    <Filter>
      <Prefix>builds/</Prefix>
    </Filter>
    <Status>Enabled</Status>
    <Transition>
      <Days>30</Days>
      <StorageClass>STANDARD_IA</StorageClass>
    </Transition>
    <Transition>
      <Days>90</Days>
      <StorageClass>GLACIER</StorageClass>
    </Transition>
    <Expiration>
      <Days>365</Days>
    </Expiration>
  </Rule>
</LifecycleConfiguration>
```

---

## 5. High-Performance AWS CLI Commands

```bash
# List buckets
aws s3 ls

# Sync local directory to S3 bucket (only uploads new or changed files)
aws s3 sync ./dist s3://my-static-web-bucket/ --delete

# Fast recursive copy with parallel threads
aws s3 cp /var/log/app s3://my-log-bucket/app/ --recursive

# Enforce server-side encryption with KMS at upload time
aws s3 cp database.dump s3://secure-backups/ --sse aws:kms
```

---

## 6. Interview & Review Questions
1. **What is the difference between S3 Standard-IA and S3 Glacier Deep Archive?**
   - *Answer*: S3 Standard-IA is designed for infrequently accessed data that requires immediate, sub-millisecond retrieval when requested. S3 Glacier Deep Archive is designed for cold regulatory archives with the lowest storage price in AWS, but requires a retrieval wait time of 12 to 48 hours before data can be downloaded.
2. **What happens under the hood when a file is deleted from an S3 bucket with Versioning enabled?**
   - *Answer*: The underlying object data is not deleted. S3 places a new object called a "Delete Marker" as the current version. Subsequent GET requests return `404 Not Found`. To restore the file, an engineer simply deletes the Delete Marker.
