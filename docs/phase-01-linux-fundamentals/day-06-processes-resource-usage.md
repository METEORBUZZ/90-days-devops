# Day 06: Linux Processes, Signals & Resource Monitoring

## 1. Theoretical Foundation

### What is a Process?
A process is an executing instance of a program in memory. Every process has:
- A unique **PID (Process Identifier)**.
- A parent process identified by **PPID (Parent Process ID)**.
- Allocated virtual memory addresses (Stack, Heap, Code, Data).
- Open file descriptors (stdin, stdout, stderr, sockets).
- An execution state tracked by the Linux kernel scheduler.

### PID 1 (The Init System)
When the Linux kernel boots, it initializes hardware and mounts the root filesystem. It then spawns the very first user-space process: **PID 1** (usually `systemd`, or `/sbin/init`, or `tini` in Docker containers).
PID 1:
- Adopts orphaned child processes when their parent dies.
- Reaps "zombie" processes to prevent process table exhaustion.
- Manages all other system daemons.

### Process States
```
       +-----------------> [ R: Running / Runnable ] <----------------+
       |                               |                                |
  [ Fork / Exec ]                      v                                |
       |                 [ S: Interruptible Sleep ]                     |
       |                 [ D: Uninterruptible Sleep (Disk I/O) ]        |
       |                               |                                |
       |                               v                                |
       +--------------------> [ T: Stopped / Paused ]                   |
                                       |                                |
                                       v                                |
                             [ Z: Zombie / Defunct ] -------------------+
                             (Waiting for parent wait() call)
```
- **R (Running/Runnable)**: Currently using the CPU or waiting in the run queue.
- **S (Interruptible Sleep)**: Waiting for an event or network/user I/O.
- **D (Uninterruptible Sleep)**: Waiting on direct hardware I/O (e.g. disk read, NFS). Cannot be killed by `kill -9`!
- **Z (Zombie/Defunct)**: The process finished execution, but its parent hasn't read its exit status via `wait()`. Consumes no RAM or CPU, but holds an entry in the PID table.
- **T (Stopped)**: Suspended via signal (e.g. `Ctrl+Z` / `SIGSTOP`).

---

## 2. Process Inspection Commands

### `ps` (Process Snapshot)
```bash
# Standard BSD format (all processes on system)
ps aux

# Standard System V format (with parent PID PPID and full command line)
ps -ef

# Search for specific application process
ps aux | grep nginx

# View process hierarchy tree
pstree -p
```

### Real-Time Monitoring: `top` & `htop`
```bash
# Launch standard top
top

# Interactive keys in top:
# P : Sort by CPU usage (%)
# M : Sort by Memory usage (%)
# k : Kill a PID interactively
# 1 : Toggle multi-core CPU view
# q : Quit
```

### System Load Average Explained
The load average values shown in `uptime` and `top`:
```text
load average: 1.15, 0.85, 0.50  (1-minute, 5-minute, 15-minute averages)
```
- **What it represents**: The average number of processes in **Runnable (`R`)** or **Uninterruptible Disk Sleep (`D`)** state.
- **Threshold rule**:
  - Check your CPU core count: `nproc`.
  - If a 4-core machine has a load average of `4.0`, CPU capacity is at 100%.
  - If load average is `8.0` on a 4-core machine, processes are queuing and latency is spiking.
  - If load average is high but CPU usage is low, the system is blocked on **Disk/NFS I/O** (processes stuck in `D` state)!

---

## 3. Linux Signals & Process Termination

Signals are asynchronous notifications sent to processes by the kernel or users.

| Signal Number | Signal Name | Description | Catchable by Application? |
| :--- | :--- | :--- | :--- |
| **1** | **SIGHUP** | Hangup / Reload configuration file (used by Nginx) | Yes |
| **2** | **SIGINT** | Interrupt (`Ctrl+C` from terminal) | Yes |
| **9** | **SIGKILL** | Immediate, forced kernel termination | **NO** (Kernel kills immediately) |
| **15** | **SIGTERM** | Graceful termination request (Default of `kill`) | Yes (Application flushes buffers) |
| **19** | **SIGSTOP** | Pause / Suspend process (`Ctrl+Z`) | **NO** |
| **18** | **SIGCONT** | Resume execution of paused process | Yes |

```bash
# Graceful termination (always try this FIRST in DevOps)
kill -15 <PID>
kill <PID>

# Forced kill (only if process is unresponsive to SIGTERM)
kill -9 <PID>

# Kill processes by name
killall -15 node
pkill -f "python worker.py"
```

---

## 4. Background and Foreground Jobs

```bash
# Run command in background immediately
python long_job.py &

# List background jobs in current shell session
jobs

# Bring background job to foreground
fg %1

# Send suspended job to background
bg %1

# Run process immune to terminal hangup (disconnect without killing process)
nohup python server.py > server.log 2>&1 &
```

---

## 5. DevOps Production Scenarios

### 1. Graceful Shutdown in Kubernetes & Docker
When Kubernetes scales down a Pod or performs a rolling update:
1. Kubernetes sends **`SIGTERM`** (`kill -15`) to the container's PID 1.
2. The application has `terminationGracePeriodSeconds` (default: 30s) to finish processing active HTTP requests and close database connections.
3. If the process does not terminate within 30s, Kubernetes sends **`SIGKILL`** (`kill -9`).
4. *DevOps takeaway: Always ensure your microservice traps `SIGTERM` to prevent truncated user transactions!*

### 2. Zombie Process Buildup in Containers
In containers lacking an init system, child processes spawned by language runtimes (Node.js, Python) can become zombies if PID 1 does not implement `wait()`.
- **Solution**: Use `tini` as entrypoint (`ENTRYPOINT ["/usr/bin/tini", "--", "node", "app.js"]`) or Docker `--init` flag.

---

## 6. Interview & Review Questions
1. **Why should you never use `kill -9` as your first troubleshooting step?**
   - *Answer*: `SIGKILL` cannot be handled or caught by the application. The kernel abruptly terminates the process without allowing it to flush memory caches to disk, finish writing transaction logs, close socket connections, or release locks, which can cause database corruption or broken state.
2. **What does a high Load Average with low CPU utilization indicate?**
   - *Answer*: It indicates processes are blocked in the uninterruptible sleep state (`D`), waiting on disk I/O, slow network-attached storage (NFS/EBS), or hardware locks rather than computational processing.
