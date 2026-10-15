# Day 20: Python Fundamentals for DevOps & Systems Automation

## 1. Theoretical Foundation

### Why Python in DevOps?
While Bash is supreme for quick 10-line CLI glue scripts, Python is the premier language for:
- Interacting with Cloud SDKs (AWS `boto3`, Google Cloud Python Client, Azure SDK).
- Parsing complex structured data (JSON, YAML, XML).
- Writing Kubernetes operators and custom Prometheus metric exporters.
- Building robust CI/CD integration tools with proper error handling and unit tests.

### Virtual Environments (`venv`)
Never install third-party packages globally into the system Python (`/usr/lib/python3`). In modern Linux distros (Ubuntu 24.04+, Debian 12+), PEP 668 enforces `externally-managed-environment` to protect system packages.

```bash
# Create dedicated virtual environment
python3 -m venv .venv

# Activate virtual environment
source .venv/bin/activate

# Install dependencies inside isolated venv
pip install --upgrade pip
pip install requests pyyaml boto3

# Save and freeze dependencies
pip freeze > requirements.txt

# Deactivate venv
deactivate
```

---

## 2. Core Python Data Structures for DevOps

```python
# 1. Lists (Ordered, mutable sequences)
regions = ["us-east-1", "us-west-2", "eu-central-1"]
regions.append("ap-south-1")

# List Comprehension (DevOps filtering pattern)
us_regions = [r for r in regions if r.startswith("us-")]

# 2. Dictionaries (Key-Value mappings - perfect for JSON/YAML config)
server_config = {
    "hostname": "prod-k8s-worker-01",
    "ip_address": "10.0.1.25",
    "cpu_cores": 8,
    "memory_gb": 32,
    "tags": {"Environment": "Production", "Owner": "SRE"}
}

# Safe dictionary access with fallback default:
owner = server_config.get("tags", {}).get("Owner", "Unassigned")
```

---

## 3. Interacting with the Operating System: `subprocess` and `os`

DevOps scripts often need to invoke system CLI binaries (like `docker`, `kubectl`, `git`, or `df`).

### The Modern `subprocess.run` Standard
Never use deprecated `os.system` or `os.popen` (vulnerable to shell injection and lack error control)!

```python
import subprocess
import sys

def run_command(cmd_list: list[str]) -> str:
    """Executes a command safely without shell expansion."""
    try:
        result = subprocess.run(
            cmd_list,
            check=True,          # Raises CalledProcessError if returncode != 0
            capture_output=True, # Captures stdout and stderr
            text=True            # Decodes bytes to string automatically
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"ERROR: Command {' '.join(cmd_list)} failed with code {e.returncode}:", file=sys.stderr)
        print(e.stderr.strip(), file=sys.stderr)
        raise

# Example: Check Docker version
try:
    docker_version = run_command(["docker", "--version"])
    print(f"Detected: {docker_version}")
except Exception:
    print("Docker is not installed or daemon is not running.")
```

---

## 4. Hands-on Lab: Automated Disk Space Alert Script in Python

Create `disk_checker.py`:

```python
#!/usr/bin/env python3
"""
Disk usage alert monitor in pure Python.
"""
import shutil
import sys

THRESHOLD_PERCENT = 85.0

def audit_filesystem(path: str = "/") -> None:
    total, used, free = shutil.disk_usage(path)
    used_pct = (used / total) * 100
    
    total_gb = total / (1024 ** 3)
    free_gb = free / (1024 ** 3)
    
    print(f"Path: {path}")
    print(f"Total: {total_gb:.2f} GB | Free: {free_gb:.2f} GB | Used: {used_pct:.1f}%")
    
    if used_pct >= THRESHOLD_PERCENT:
        print(f"CRITICAL: Disk usage on {path} exceeded threshold ({THRESHOLD_PERCENT}%)!", file=sys.stderr)
        sys.exit(1)
    else:
        print("Disk capacity is healthy.")

if __name__ == "__main__":
    audit_filesystem("/")
```

---

## 5. Interview & Review Questions
1. **Why should you pass a list of strings (`["ls", "-l"]`) to `subprocess.run` instead of a string with `shell=True`?**
   - *Answer*: `shell=True` spawns an intermediate system shell (`/bin/sh -c`). If any parameter contains unsanitized user or external input (such as filenames or HTTP parameters), it introduces critical command injection vulnerabilities (e.g. `; rm -rf /`). Passing a list directly invokes the `execve` system call with explicit arguments, completely eliminating shell injection risks.
2. **What is PEP 668 and why do modern Linux distributions block `pip install` outside a virtual environment?**
   - *Answer*: PEP 668 prevents conflicts between system package managers (`apt`, `dnf`) and Python package managers (`pip`). Installing pip packages globally can overwrite core OS Python dependencies used by essential system services.
