# Day 66: Kubernetes Storage Architecture (PV, PVC, StorageClass) & StatefulSets

## 1. Theoretical Foundation

### The Storage Abstraction Layer
In Kubernetes, storage is decoupled from Pods using three primary primitives:
1. **`PersistentVolume` (PV)**: A piece of physical or cloud storage (e.g. AWS EBS volume, Azure Disk, NFS) provisioned in the cluster.
2. **`PersistentVolumeClaim` (PVC)**: A developer's request for storage (e.g. "I need 50GB of ReadWriteOnce SSD storage").
3. **`StorageClass`**: A dynamic provisioning template that tells cloud CSI drivers (Container Storage Interface) how to automatically create underlying cloud disks on the fly when a PVC is submitted!

```
[ Developer creates PVC ]
          |
          v
[ StorageClass: "gp3" ] ---> Calls [ AWS EBS CSI Driver ] ---> Provisions [ AWS EBS Volume: 50GB ]
                                                                             |
                                                                             v
[ PersistentVolume (PV) Created Automatically in Cluster ] <-----------------+
          |
          | (Bound 1-to-1)
          v
[ PersistentVolumeClaim (PVC: Bound) ]
          |
          v
[ Mounted into Pod: /var/lib/postgresql/data ]
```

---

## 2. Dynamic Volume Provisioning Example

### 1. StorageClass Definition
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-gp3-sc
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer # Defers provisioning until Pod is scheduled to an AZ!
allowVolumeExpansion: true
parameters:
  type: gp3
  encrypted: "true"
```

### 2. PersistentVolumeClaim (PVC)
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: db-data-pvc
  namespace: production
spec:
  accessModes:
    - ReadWriteOnce # Mounted as read-write by a single node at a time
  storageClassName: ebs-gp3-sc
  resources:
    requests:
      storage: 50Gi
```

### Access Modes:
- **`ReadWriteOnce` (RWO)**: Mounted as read-write by a single node (Standard for AWS EBS block storage).
- **`ReadOnlyMany` (ROX)**: Mounted read-only by many nodes simultaneously.
- **`ReadWriteMany` (RWX)**: Mounted read-write by many nodes concurrently (Requires shared network storage like Amazon EFS, NFS, or Ceph).

---

## 3. Deployments vs. StatefulSets for Databases

Why should you **never** run databases (PostgreSQL, MongoDB, Kafka) inside standard Deployments?
- Deployments treat Pods as identical, interchangeable, and disposable.
- Pods have random names (`api-7f89d4c-x8k2p`).
- Scaling up shares the same PVC, leading to filesystem corruption.

**The Solution: `StatefulSet`**:
- **Predictable Network Identity**: Pods are named sequentially: `db-0`, `db-1`, `db-2`.
- **Dedicated Storage**: Each Pod gets its own independent PVC automatically via **`volumeClaimTemplates`**:
  - `data-db-0` binds exclusively to `db-0`.
  - If `db-0` crashes and moves to another node, it reattaches strictly to `data-db-0`!
- **Ordered Startup and Shutdown**: Boots `db-0` first (Master), waits until healthy, then boots `db-1` (Replica).

---

## 4. Interview & Review Questions
1. **What is `volumeBindingMode: WaitForFirstConsumer` in a StorageClass and why is it mandatory for cloud block storage (AWS EBS)?**
   - *Answer*: EBS volumes are locked to a specific Availability Zone (e.g. `ap-south-1a`). If `Immediate` binding is used, AWS might provision the volume in AZ-a before the Pod is scheduled. If the Pod is later scheduled onto a node in AZ-b, it cannot attach to the volume! `WaitForFirstConsumer` delays disk creation until the `kube-scheduler` assigns the Pod to a specific AZ, ensuring the volume is provisioned in the matching AZ.
2. **What is the difference between a Deployment and a StatefulSet?**
   - *Answer*: Deployments manage stateless applications where Pods are completely interchangeable and lack sticky storage identities. StatefulSets manage stateful applications, providing stable sequential network hostnames (`db-0`, `db-1`), dedicated per-pod storage volumes (`volumeClaimTemplates`), and ordered graceful scaling/termination.
