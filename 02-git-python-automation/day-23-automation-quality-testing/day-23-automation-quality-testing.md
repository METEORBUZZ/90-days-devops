# Day 23: Automation Quality, Idempotency & Unit Testing in Python

## 1. Theoretical Foundation

### The Core Principle: Idempotency
An operation is **Idempotent** if applying it once has the exact same system outcome as applying it multiple times consecutively:
$$f(f(x)) = f(x)$$

- **Non-idempotent**: `echo "10.0.0.1 db" >> /etc/hosts` (adds duplicate lines every time the script runs).
- **Idempotent**: Check if line exists first, and only append if missing (or replace line in-place).
- In DevOps, automation scripts, Terraform configurations, and Ansible playbooks must be idempotent so that running them repeatedly produces stable, predictable states without side-effects or crashes.

---

## 2. Testing Python Automation with `pytest`

Install testing tools:
```bash
pip install pytest pytest-mock
```

### Writing Testable DevOps Code
Separate side-effect code (like disk I/O or network HTTP requests) from business logic:

`health_checker.py`:
```python
def calculate_status(cpu_usage: float, memory_usage: float) -> str:
    """Pure business logic: evaluates telemetry and returns health status."""
    if cpu_usage > 90.0 or memory_usage > 90.0:
        return "CRITICAL"
    if cpu_usage > 75.0 or memory_usage > 75.0:
        return "WARNING"
    return "HEALTHY"
```

`test_health_checker.py`:
```python
import pytest
from health_checker import calculate_status

def test_calculate_status_healthy():
    assert calculate_status(45.0, 50.0) == "HEALTHY"

def test_calculate_status_warning():
    assert calculate_status(80.0, 50.0) == "WARNING"

def test_calculate_status_critical():
    assert calculate_status(95.0, 60.0) == "CRITICAL"
    assert calculate_status(30.0, 92.0) == "CRITICAL"
```

Run test suite:
```bash
pytest -v
```

---

## 3. Mocking External Services (`unittest.mock`)

In CI/CD pipelines, your unit tests must not make real HTTP calls to external APIs or format local disks! Use mocking to simulate external dependencies:

```python
from unittest.mock import patch
import requests
from my_script import fetch_github_release

@patch("requests.get")
def test_fetch_github_release_success(mock_get):
    # Configure mock return value
    mock_get.return_value.status_code = 200
    mock_get.return_value.json.return_value = {"tag_name": "v1.2.0"}

    # Call function
    release = fetch_github_release("my-org/my-repo")
    assert release == "v1.2.0"
    mock_get.assert_called_once()
```

---

## 4. Linting & Static Analysis: `ruff` and `black`

In modern DevOps teams, code formatters and linters are executed automatically inside Git pre-commit hooks and GitHub Actions PR checks:

```bash
# Ultra-fast linter written in Rust
pip install ruff black

# Run linter
ruff check .

# Automatically fix linting issues
ruff check --fix .

# Format code according to PEP 8 standards
black .
```

---

## 5. Interview & Review Questions
1. **Why is idempotency essential for automated deployment scripts?**
   - *Answer*: Networks fail, timeouts occur, and deployments get interrupted midway. An idempotent script can be safely re-executed without leaving orphaned state, generating duplicate database entries, corrupting configuration files, or crashing due to pre-existing resources.
2. **What is the difference between a Unit Test and an Integration Test in infrastructure automation?**
   - *Answer*: A Unit Test tests an isolated function in memory using mocked external dependencies (no real network or disk access; executes in milliseconds). An Integration Test validates the script against real external resources (e.g., spinning up a real Docker container or connecting to a test database).
