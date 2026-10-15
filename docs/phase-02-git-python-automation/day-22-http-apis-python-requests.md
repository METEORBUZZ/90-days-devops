# Day 22: Consuming REST APIs with Python Requests & Resilient Networking

## 1. Theoretical Foundation

### REST APIs in Infrastructure Engineering
Virtually all cloud and DevOps tools expose HTTP REST APIs:
- **GitHub API**: Trigger workflows, merge PRs, query release tags.
- **Kubernetes API**: Inspect Pod health, scale deployments.
- **AWS API / Cloudflare**: Manage DNS records, query EC2 instances.
- **Monitoring (Datadog/PagerDuty/Slack)**: Send incident alerts and notifications.

### HTTP Methods & Status Codes Cheat Sheet
- **Methods**:
  - `GET`: Retrieve resource.
  - `POST`: Create new resource.
  - `PUT`: Replace resource entirely (idempotent).
  - `PATCH`: Partially update resource.
  - `DELETE`: Remove resource.
- **Status Codes**:
  - `2xx (Success)`: `200 OK`, `201 Created`, `204 No Content`.
  - `3xx (Redirection)`: `301 Moved Permanently`, `304 Not Modified`.
  - `4xx (Client Error)`: `400 Bad Request`, `401 Unauthorized` (missing/bad token), `403 Forbidden` (insufficient IAM role), `404 Not Found`, `429 Too Many Requests` (Rate Limited).
  - `5xx (Server Error)`: `500 Internal Error`, `502 Bad Gateway`, `503 Service Unavailable`, `504 Gateway Timeout`.

---

## 2. The Python `requests` Library

Install via:
```bash
pip install requests
```

### 1. Making Authenticated GET & POST Requests
```python
import requests

GITHUB_API_URL = "https://api.github.com/repos/METEORBUZZ/90-days-devops/commits"
HEADERS = {
    "Accept": "application/vnd.github+json",
    "Authorization": "Bearer ghp_YourPersonalAccessTokenExample123",
    "X-GitHub-Api-Version": "2022-11-28"
}

# ALWAYS set explicit timeouts! Unset timeouts cause scripts to hang indefinitely if network drops!
try:
    response = requests.get(GITHUB_API_URL, headers=HEADERS, timeout=(5.0, 10.0)) # (connect_timeout, read_timeout)
    response.raise_for_status()  # Raises HTTPError if status code is 4xx or 5xx
    
    commits = response.json()
    print(f"Total commits returned: {len(commits)}")
    print(f"Latest commit message: {commits[0]['commit']['message']}")

except requests.exceptions.HTTPError as http_err:
    print(f"HTTP Error: {http_err} (Status Code: {response.status_code})")
except requests.exceptions.Timeout:
    print("Connection timed out while waiting for GitHub API.")
except requests.exceptions.RequestException as err:
    print(f"Network error occurred: {err}")
```

---

## 3. Resilient Retries & Exponential Backoff

In production cloud environments, network glitches and API rate limits (`429 Too Many Requests`, `503 Service Unavailable`) are routine. Never let a single transient failure break your pipeline!

```python
import requests
from requests.adapters import HTTPAdapter
from urllib3.util import Retry

def create_resilient_session() -> requests.Session:
    """Configures a requests session with automatic retry and exponential backoff."""
    session = requests.Session()
    
    retries = Retry(
        total=4,                         # Total number of retries
        backoff_factor=1.5,              # Wait: 1.5s, 3s, 6s...
        status_forcelist=[429, 500, 502, 503, 504], # Retry on these status codes
        allowed_methods=["GET", "POST", "PUT"]
    )
    
    adapter = HTTPAdapter(max_retries=retries)
    session.mount("https://", adapter)
    session.mount("http://", adapter)
    return session

# Usage:
session = create_resilient_session()
res = session.get("https://api.example.com/health", timeout=5)
```

---

## 4. Sending Slack / Discord Incident Alerts

```python
import json
import requests

def send_slack_alert(webhook_url: str, message: str, severity: str = "danger") -> None:
    payload = {
        "text": f"🚨 *DevOps Alert* ({severity.upper()}): {message}",
        "attachments": [
            {
                "color": "#ff0000" if severity == "danger" else "#36a64f",
                "fields": [
                    {"title": "Environment", "value": "Production", "short": True},
                    {"title": "Host", "value": "k8s-node-01", "short": True}
                ]
            }
        ]
    }
    
    response = requests.post(
        webhook_url,
        data=json.dumps(payload),
        headers={"Content-Type": "application/json"},
        timeout=5
    )
    if response.status_code != 200:
        raise ValueError(f"Slack webhook failed: {response.status_code}, {response.text}")
```

---

## 5. Interview & Review Questions
1. **Why must you ALWAYS specify a `timeout` argument in Python `requests`?**
   - *Answer*: By default, `requests` does not set a timeout. If the remote server accepts the TCP handshake but hangs indefinitely without sending response bytes (or if an intermediate firewall drops packets silently), the Python script will block forever, freezing CI/CD runners or microservice worker threads.
2. **What does `response.raise_for_status()` do and why is it recommended?**
   - *Answer*: If the HTTP status code was 4xx (Client Error) or 5xx (Server Error), `raise_for_status()` raises an `HTTPError` exception immediately, allowing your error-handling logic to catch and handle API failures instead of attempting to parse empty or error-page payloads as valid JSON.
