# Phase 2: Git, Python & Automation (Days 16–25)

Automation is the engine of DevOps. While Phase 1 provided the Linux operational foundation, Phase 2 equips you with version control mastery (Git/GitHub) and software engineering skills for infrastructure automation using Python.

---

## 📅 Daily Learning Index

| Day | Topic | In-Depth Learning Guide | Key Concepts |
| :--- | :--- | :--- | :--- |
| **16** | **Git Fundamentals & Architecture** | [Day 16 Guide](./day-16-git-fundamentals.md) | Working tree, staging index, commit DAG, `.git` internals, `.gitignore` |
| **17** | **Git Branching & Merges** | [Day 17 Guide](./day-17-git-branches-merges.md) | Fast-forward vs 3-way merge, rebase vs merge, merge conflict resolution |
| **18** | **GitHub & Pull Requests** | [Day 18 Guide](./day-18-github-pull-requests.md) | Remotes, PR workflows, code reviews, branch protection, CI status checks |
| **19** | **Git Recovery & Advanced Ops** | [Day 19 Guide](./day-19-git-recovery-collaboration.md) | `git revert` vs `reset` (soft/mixed/hard), reflog disaster recovery, cherry-pick, stashing |
| **20** | **Python Fundamentals for Automation** | [Day 20 Guide](./day-20-python-fundamentals-automation.md) | Data types, lists, dictionaries, comprehensions, functions, subprocess execution |
| **21** | **Python Files, JSON & Exception Handling** | [Day 21 Guide](./day-21-python-files-json-exceptions.md) | Context managers (`with`), JSON schema serialization, structured `logging`, `try/except` |
| **22** | **HTTP APIs & Python Requests** | [Day 22 Guide](./day-22-http-apis-python-requests.md) | REST APIs, authentication headers, timeouts, status codes, retry logic with backoff |
| **23** | **Automation Quality, Testing & Idempotency** | [Day 23 Guide](./day-23-automation-quality-testing.md) | Idempotent design, `unittest`/`pytest`, mocking network calls, linting with `ruff`/`flake8` |
| **24** | **Python Automation Mini-Project** | [Day 24 Guide](./day-24-python-automation-mini-project.md) | Multi-node Infrastructure Health & Slack/Discord Webhook Alerting Service |
| **25** | **Phase 1 & 2 Comprehensive Review** | [Day 25 Guide](./day-25-linux-git-python-review.md) | End-to-end integration: Linux internals, Git operational triage, and Python tooling |

---

## 🎯 Phase 2 Goals & Milestones
By the end of Phase 2, you should be able to:
1. Explain how Git represents snapshots under the hood (Blobs, Trees, Commits, Annotated Tags).
2. Triage merge conflicts, recover deleted commits via `git reflog`, and enforce production branch protection rules.
3. Write clean, idempotent Python scripts for infrastructure management, REST API querying, and structured log parsing.
4. Integrate alerting mechanisms (Webhooks/Slack) with proper timeout handling and retry exponential backoffs.
