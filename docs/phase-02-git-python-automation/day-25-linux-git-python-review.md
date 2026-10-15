# Day 25: Phase 1 & 2 Comprehensive Review & Troubleshooting Scenarios

## 1. Cross-Domain Synergy: How Linux, Git & Python Connect

In real-world DevOps environments, these three disciplines constantly interact:
- **Git** versions your infrastructure configurations, Dockerfiles, and Python automation code.
- **Python** automates cloud provisioning, calls APIs, parses logs, and coordinates CI/CD pipelines.
- **Linux** is the runtime operating system hosting your services, running your cron/systemd jobs, and orchestrating containers.

```
       +-----------------------------------------------------------+
       |                  Developer Workstation                    |
       |  [ Writes Python Script ] ---> [ Git Commit & Push ]      |
       +-----------------------------------------------------------+
                                     |
                                     v
       +-----------------------------------------------------------+
       |                  GitHub CI/CD Runner                      |
       |  [ Pulls Code ] ---> [ Runs Pytest & Linters ]            |
       +-----------------------------------------------------------+
                                     |
                                     v (SSH / Deploy)
       +-----------------------------------------------------------+
       |                  Linux Production Node                    |
       |  [ systemd Service ] runs [ Python Daemon ]               |
       |  Logged in [ journalctl ] / Scraped by [ Prometheus ]     |
       +-----------------------------------------------------------+
```

---

## 2. Realistic Production Incident Simulations

### Incident 1: Accidental Git Hard Reset in Production Workspace
- **Scenario**: An automated deployment job ran `git reset --hard` to the wrong tag on the build node, wiping unpushed release artifacts.
- **Diagnosis & Fix**:
  ```bash
  # 1. Run git reflog to view HEAD movements
  git reflog -n 10
  # 2. Locate the commit hash before the reset (e.g. HEAD@{1})
  # 3. Recover by branching or resetting:
  git reset --hard HEAD@{1}
  ```

### Incident 2: Python Webhook Automation Freezing Under Network Partition
- **Scenario**: An internal Python monitoring script stopped generating reports. Process status in `ps aux` shows state `S` (interruptible sleep) for hours.
- **Diagnosis**: The script used `requests.post()` without specifying `timeout=...`. When the internal corporate proxy dropped packets, the socket blocked waiting for an ACK that never came.
- **Fix**: Always enforce explicit connect and read timeouts: `requests.post(url, timeout=(3.05, 10.0))`.

### Incident 3: Disk Full Alert Triggered by Stale Python Caches & Unrotated Logs
- **Scenario**: Production server root partition `/` hits 99% capacity.
- **Triage**:
  ```bash
  # Check disk space vs inodes
  df -h
  df -ih

  # Find largest directories
  du -ahx / | sort -rh | head -n 20

  # Clean python build clutter & systemd journals
  find /opt -name "__pycache__" -type d -exec rm -rf {} +
  sudo journalctl --vacuum-size=200M
  ```

---

## 3. High-Yield Interview Technical Review

| Question | Core Concept Tested | Target Answer |
| :--- | :--- | :--- |
| **What is the difference between `git merge` and `git rebase`?** | Version Control Architecture | Merge creates a 3-way merge commit preserving exact history; rebase replays feature commits linearly on top of base, rewriting commit hashes. |
| **What does `SIGTERM` vs `SIGKILL` mean to a Python daemon?** | Operating System Signals | Python can catch `SIGTERM` via `signal.signal(signal.SIGTERM, handler)` to flush logs and close DB connections; `SIGKILL` cannot be trapped and terminates immediately. |
| **Why is `subprocess.run(["cmd", "arg"])` preferred over `os.system("cmd arg")`?** | Security & Process Isolation | Avoids invoking a shell interpreter (`/bin/sh`), preventing command injection and enabling direct stdin/stdout stream capture with return code validation. |
| **How does `chmod 2775` differ from `chmod 0775`?** | Linux Permissions | Numeric `2` sets the **SGID** bit. On a directory, files created inside inherit the group ownership of that directory rather than the primary group of the user creating the file. |

---

## 4. Milestone Checkpoint: Ready for Phase 3!

Congratulations on completing **Phase 2 (Days 16–25)**!
You now have mastery over:
- Git internal DAG, conflict resolution, reflog, and branch protection.
- Python systems automation, file handling, JSON serialization, and structured logging.
- Resilient HTTP REST API integration with retry backoffs.
- Unit testing with mocks, linters, and idempotent engineering design.

Next: **Phase 3 — AWS Cloud Engineering (Days 26–40)**!
