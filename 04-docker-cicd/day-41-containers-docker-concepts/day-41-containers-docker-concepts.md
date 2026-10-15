# Day 41: Containers vs. VMs, Linux Namespaces & Docker Architecture

## 1. Theoretical Foundation

### Virtual Machines vs. Containers
```
+------------------------------------+    +------------------------------------+
|          Virtual Machines          |    |             Containers             |
+------------------------------------+    +------------------------------------+
|  [App A]      [App B]      [App C] |    |  [App A]      [App B]      [App C] |
|  [Libs/Deps]  [Libs/Deps]  [Libs]  |    |  [Libs/Deps]  [Libs/Deps]  [Libs]  |
|  [Guest OS]   [Guest OS]   [Guest] |    +------------------------------------+
+------------------------------------+    |      Container Runtime (Docker)    |
|        Hypervisor (Type 1 or 2)    |    +------------------------------------+
+------------------------------------+    |      Host Operating System (Linux) |
|        Physical Host Hardware      |    +------------------------------------+
+------------------------------------+    |      Physical Host Hardware        |
                                          +------------------------------------+
```

| Dimension | Virtual Machine (VM) | Container (Docker) |
| :--- | :--- | :--- |
| **Virtualization Level** | Hardware-level virtualization (Hypervisor emulates virtual CPU, RAM, NIC) | OS-level virtualization (Shares host Linux Kernel) |
| **Guest OS Required?** | **YES** (Each VM runs full 2–10 GB OS kernel and system daemons) | **NO** (Zero guest OS overhead; executes as native host process) |
| **Startup Time** | Minutes (boots full OS kernel) | Milliseconds (executes process immediately) |
| **Resource Efficiency** | Heavy memory and CPU overhead | Extremely lightweight (run hundreds of containers on 1 host) |
| **Isolation** | Strong hardware-enforced isolation | Process-level isolation via Linux kernel primitives |

---

## 2. Under the Hood: Linux Kernel Primitives

Containers are **not** magical boxes. A container is simply a standard Linux process isolated by three kernel features:

### 1. Linux Namespaces (What a Process Can SEE)
Namespaces partition system resources so that a process believes it has its own dedicated operating system:
- **`pid`**: Process ID isolation. The container process sees itself as **PID 1**, isolated from the thousands of processes on the host.
- **`net`**: Network isolation. Container gets its own private IP address, routing table, port range, and `eth0` network interface.
- **`mnt`**: Mount isolation. Provides a completely independent root filesystem (`/`) view.
- **`ipc`**: Inter-Process Communication isolation (shared memory, semaphores).
- **`uts`**: Hostname and domain name isolation.
- **`user`**: User ID mapping. UID 0 (root) inside the container can map to unprivileged UID 10001 on the host node!

### 2. Control Groups / cgroups (What a Process Can USE)
`cgroups` allocate, measure, and enforce resource limits:
- **Memory limit**: Prevents a rogue container from consuming all host RAM (`--memory=512m`). If it exceeds, the kernel OOM killer terminates it.
- **CPU quota**: Restricts CPU utilization (`--cpus=1.5`).
- **Disk I/O & Network bandwidth**.

### 3. Union Filesystem (Overlay2)
Layers container filesystem diffs on top of read-only image layers without duplicating common files on disk.

---

## 3. The Docker Engine Architecture

```
[ Docker CLI (Client) ]
         |
         | (REST API over /var/run/docker.sock or TCP)
         v
[ dockerd (Docker Daemon) ]
         |
         v
[ containerd (OCI Compliant Container Runtime) ]
         |
         v
[ runc (Low-level CLI tool that configures Namespaces & cgroups) ]
         |
         v
[ Isolated Container Process ]
```

---

## 4. Essential Docker Discovery Commands

```bash
# Verify Docker daemon is running and view host architecture
docker version
docker info

# List active containers
docker ps

# List all containers (including stopped/exited)
docker ps -a

# List downloaded container images
docker images

# Inspect container low-level JSON metadata (IP address, mounts, environment)
docker inspect <container_id_or_name>
```

---

## 5. Interview & Review Questions
1. **Do Docker containers run their own Linux kernel?**
   - *Answer*: No. Docker containers share the host machine's Linux kernel. They only package the user-space applications, libraries, and binaries. This is why you cannot run a native Windows kernel container on a Linux host (unless using virtualization).
2. **What is the difference between Linux Namespaces and Control Groups (cgroups)?**
   - *Answer*: Namespaces control **visibility and isolation** (what system resources a process can see, such as PIDs, network interfaces, and mounts). cgroups control **resource limits and throttling** (how much CPU, memory, and I/O a process group is allowed to consume).
