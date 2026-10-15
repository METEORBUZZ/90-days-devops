# Day 48: GitHub Actions Architecture, Workflows & Runners

## 1. Theoretical Foundation

### What is GitHub Actions?
GitHub Actions is an event-driven automation platform built natively into GitHub that allows you to run Continuous Integration (CI) and Continuous Deployment (CD) pipelines.

### Core Concepts & Hierarchy
```
[ Event: Trigger (push, pull_request, schedule) ]
                       |
                       v
                 [ Workflow ] (.github/workflows/*.yaml)
                       |
       +---------------+---------------+
       |                               |
       v                               v
[ Job 1: Lint & Test ]       [ Job 2: Build & Push ] (Runs in parallel by default)
  (Runner: ubuntu-latest)      (Runner: self-hosted)
       |                               |
  +----+----+                     +----+----+
  |         |                     |         |
  v         v                     v         v
Step 1    Step 2                Step 1    Step 2
(Action)  (run: script)         (Action)  (run: script)
```

1. **Workflow**: An automated configurable process stored in `.github/workflows/*.yaml`.
2. **Event**: A specific activity that triggers the workflow (e.g. `push` to `main`, `pull_request`, daily cron `schedule`, or manual `workflow_dispatch`).
3. **Jobs**: A set of steps executed on the same runner virtual machine. By default, independent jobs run **in parallel**. Use `needs: [job1]` to create sequential dependencies!
4. **Steps**: Individual sequential tasks that execute either a shell command (`run: ...`) or a reusable custom Action (`uses: ...`).
5. **Runners**: The virtual machine or container executing the job.
   - **GitHub-Hosted Runners**: Managed by GitHub (e.g. `ubuntu-latest`, `windows-latest`). Fresh, clean VM for every run.
   - **Self-Hosted Runners**: Deployed inside your private cloud VPC (EC2 / Kubernetes) for direct access to internal databases and hardware acceleration.

---

## 2. Anatomy of a Production Workflow (`.github/workflows/ci.yaml`)

```yaml
name: Continuous Integration

# 1. Triggers
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch: # Allows manual trigger from GitHub UI

# 2. Permissions (Enforce Least Privilege)
permissions:
  contents: read
  pull-requests: write

# 3. Concurrency (Cancel redundant builds on fast git pushes)
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

# 4. Jobs
jobs:
  lint-and-test:
    name: Code Quality & Unit Tests
    runs-on: ubuntu-latest
    timeout-minutes: 15

    steps:
      - name: Checkout Source Code
        uses: actions/checkout@v4

      - name: Set up Python Runtime
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
          cache: 'pip' # Automatically caches pip dependencies!

      - name: Install Dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements-dev.txt

      - name: Run Linter (Ruff)
        run: ruff check .

      - name: Execute Unit Tests (Pytest)
        run: pytest -v --junitxml=test-results.xml

      - name: Publish Test Report Artifact
        if: always() # Upload report even if unit tests failed!
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: test-results.xml
```

---

## 3. Workflow Concurrency Control

When developers push 4 quick commits to a PR in a single minute, triggering 4 parallel full CI pipeline runs wastes compute minutes.
**`concurrency: cancel-in-progress: true`** immediately terminates older runs for the same PR branch when a new commit is detected!

---

## 4. GitHub Actions Contexts & Expressions

GitHub Actions exposes dynamic context objects accessible via `${{ ... }}`:
- `${{ github.sha }}`: Full 40-character commit hash triggering the run.
- `${{ github.ref }}`: Branch or tag ref (`refs/heads/main`).
- `${{ secrets.MY_SECRET }}`: Decrypted repository secret.
- `${{ env.VARIABLE_NAME }}`: Environment variable value.

---

## 5. Interview & Review Questions
1. **How do you make Job B wait for Job A to complete successfully in GitHub Actions?**
   - *Answer*: Add the `needs` key to Job B: `needs: [job_a]`. By default, GitHub Actions executes all jobs concurrently; specifying `needs` establishes a sequential directed dependency graph.
2. **Why is `cancel-in-progress: true` recommended in PR concurrency configurations?**
   - *Answer*: It automatically cancels older, superseded workflow runs on the same branch whenever a new commit is pushed, saving significant CI/CD runner execution time and cloud billing minutes.
