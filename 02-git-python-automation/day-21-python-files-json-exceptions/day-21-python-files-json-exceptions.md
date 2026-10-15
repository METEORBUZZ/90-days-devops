# Day 21: Python File Handling, JSON Serialization & Structured Logging

## 1. Theoretical Foundation

In cloud automation, DevOps engineers spend significant time reading configurations (`.json`, `.yaml`, `.env`), processing log files, and outputting machine-readable metrics.

### Context Managers (`with` statement)
Always open files using Python's `with` statement. The context manager guarantees that the underlying file descriptor is automatically closed when the code block exits, even if an unhandled exception or crash occurs.

```python
# Safe, idiomatic file reading
with open("/var/log/app.log", "r", encoding="utf-8") as f:
    for line in f:
        if "ERROR" in line:
            print(line.strip())
# File descriptor is guaranteed to be closed here!
```

---

## 2. JSON Processing (`json` module)

JSON (JavaScript Object Notation) is the ubiquitous data format for cloud APIs (AWS, GitHub, Kubernetes).

```python
import json

# 1. Parsing JSON string into Python Dictionary (Deserialization)
json_payload = '{"cluster": "k8s-prod", "replicas": 3, "healthy": true}'
data = json.loads(json_payload)
print(data["cluster"])  # Output: k8s-prod

# 2. Reading JSON directly from a file
with open("config.json", "r", encoding="utf-8") as f:
    config = json.load(f)

# 3. Converting Python Dictionary to JSON string (Serialization)
payload = {
    "deployment_id": "dep-8821",
    "status": "SUCCESS",
    "timestamp": 1729000000,
    "services_updated": ["auth", "billing"]
}

# Pretty-print with 2 spaces indent
json_string = json.dumps(payload, indent=2)

# 4. Writing JSON directly to a file
with open("deployment_report.json", "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2)
```

---

## 3. Robust Exception Handling (`try / except / else / finally`)

```python
import json
import logging

def parse_server_manifest(filepath: str) -> dict:
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            data = json.load(f)
            return data
    except FileNotFoundError:
        logging.error(f"Configuration file {filepath} does not exist.")
        raise
    except json.JSONDecodeError as err:
        logging.error(f"Malformed JSON syntax in {filepath}: line {err.lineno}, col {err.colno}")
        raise
    except PermissionError:
        logging.error(f"Access denied: cannot read {filepath}. Check file permissions.")
        raise
    finally:
        logging.info("Completed file access attempt.")
```

---

## 4. Production Structured Logging (`logging` module)

Never use `print()` statements in production services! `print()` lacks timestamps, log levels, and cannot be routed to syslog or files easily.

```python
import logging
import sys

# Configure structured logging format
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] [%(name)s:%(lineno)d] %(message)s',
    datefmt='%Y-%m-%dT%H:%M:%SZ',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler("/tmp/devops-automation.log")
    ]
)

logger = logging.getLogger("Deployer")

logger.debug("Parsing environment variables...")
logger.info("Starting deployment of release v2.4.0...")
logger.warning("Database connection pool is at 82% capacity!")
logger.error("Failed to connect to Redis cache at 10.0.1.50:6379!")
```

---

## 5. Interview & Review Questions
1. **What is the difference between `json.load()` and `json.loads()`?**
   - *Answer*: `json.load(file_object)` reads and parses JSON data directly from a file stream/descriptor. `json.loads(string_data)` (load-string) parses a JSON formatted string or bytes in memory.
2. **Why is it bad practice to write `except Exception: pass` in automation scripts?**
   - *Answer*: Catching and silencing generic exceptions swallows critical runtime errors, syntax errors, and signals (such as `KeyboardInterrupt` if catching `BaseException`). This creates silent failures where automation reports success despite failed operations, leading to corrupted state.
