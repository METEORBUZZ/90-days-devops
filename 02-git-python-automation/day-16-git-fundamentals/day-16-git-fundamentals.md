# Day 16: Git Fundamentals, Architecture & Internal Object Model

## 1. Theoretical Foundation

### Git vs. Traditional Centralized VCS (SVN/CVS)
- **Centralized VCS (SVN)**: Stores deltas (diffs) of files on a central server. If the server goes down or network breaks, developers cannot commit or review history.
- **Distributed VCS (Git)**: Every developer has a complete clone of the repository history locally. Commits are instant and offline. Git stores **complete filesystem snapshots**, not diffs!

### The Three Trees of Git
```
+-------------------+       git add       +-------------------+     git commit    +-------------------+
|   Working Tree    | ------------------> |   Staging Index   | ----------------> |   Git Repository  |
|  (Local edits)    |                     |   (Next snapshot) |                   |  (Commit History) |
+-------------------+ <------------------ +-------------------+ <---------------- +-------------------+
                            git restore           git restore --staged
```

1. **Working Directory / Tree**: The physical folder on your filesystem where you edit files.
2. **Staging Area / Index**: A cache file (`.git/index`) that prepares and stages the exact files and state that will form the next commit snapshot.
3. **Commit History (`.git/objects`)**: An immutable Directed Acyclic Graph (DAG) of cryptographic snapshots.

### Inside `.git`: The Object Database
Git is a content-addressable storage database. Objects are hashed using SHA-1 (or SHA-256):
1. **Blob (Binary Large Object)**: Stores the raw file contents (does not store filename, permissions, or timestamp).
2. **Tree**: Represents a directory. Stores filenames, permissions (`100644`, `100755`), and points to child Blobs or Trees.
3. **Commit**: Points to a root Tree object, author/committer metadata, timestamp, commit message, and parent commit hash(es).
4. **Annotated Tag**: A permanent pointer to a specific commit object with GPG signature and release notes.

```bash
# Explore Git's internal objects directly:
git cat-file -t <hash>     # Prints object type (blob, tree, commit)
git cat-file -p <hash>     # Pretty-prints object content
```

---

## 2. Essential Git Commands Cheat Sheet

### Repository Initialization & Inspection
```bash
# Initialize a new Git repository
git init

# View status of working directory and staging area
git status
git status -s               # Short tabular output (M: Modified, A: Added, ??: Untracked)

# Inspect commit history
git log --oneline --graph --decorate --all
git log -n 5                # Last 5 commits
git log -p filename.py      # Show patch diffs for specific file
```

### Staging & Committing
```bash
# Stage specific file
git add server.py

# Stage all tracked and untracked changes in current directory
git add .

# Interactive staging (stage individual hunks/chunks of changes)
git add -p config.yaml

# Commit with descriptive message
git commit -m "feat(api): add health check probe endpoint"

# Amend the most recent commit (fix typo in message or add forgotten staged files)
# ONLY use if the commit has NOT been pushed to a shared remote!
git commit --amend -m "feat(api): add health check probe endpoint with unit tests"
```

### Inspecting Differences: `git diff`
```bash
# Compare Working Directory vs. Staging Area (unstaged changes)
git diff

# Compare Staging Area vs. Last Commit (staged changes about to be committed)
git diff --staged

# Compare two branches or commits
git diff main feature/auth
```

---

## 3. Best Practice: Production `.gitignore`

Committing secrets, build artifacts, virtual environments, or system clutter into Git causes security breaches and repository bloat.

### Production `.gitignore` Template for DevOps & Python
```gitignore
# Operating System artifacts
.DS_Store
Thumbs.db
*.swp

# Python Virtual Environments & Bytecode
__pycache__/
*.py[cod]
*$py.class
.venv/
venv/
env/
*.egg-info/
dist/
build/

# IDE & Editor configs
.vscode/
.idea/

# Environment Variables & Secrets (CRITICAL)
.env
.env.*
*.pem
*.key
*.pfx
secrets.yaml

# Infrastructure as Code State & Provider Caches
.terraform/
*.tfstate
*.tfstate.*
.terraform.lock.hcl
crash.log
```

### How to Untrack a File That Was Accidentally Committed
```bash
# Remove from Git tracking without deleting local file on disk:
git rm --cached .env
git commit -m "chore: stop tracking .env secret file"
```

---

## 4. Production Pitfalls & Troubleshooting

| Problem | Root Cause | Solution |
| :--- | :--- | :--- |
| Secret committed into Git history | `git rm` removes it from future commits, but secret remains in past Git commit history! | Use `git-filter-repo` or BFG Repo-Cleaner to rewrite history, then rotate the leaked secret immediately. |
| Line ending warnings (`LF will be replaced by CRLF`) | Windows vs Unix line ending mismatches. | Configure Git: `git config --global core.autocrlf input` (on Linux/macOS) or `true` (on Windows). |
| Detached HEAD state | Checked out a commit directly instead of a branch. | Create a branch to save work: `git checkout -b fix-branch`. |

---

## 5. Interview & Review Questions
1. **Explain the difference between a working directory, the staging index, and a commit.**
   - *Answer*: The working directory is the editable local filesystem. The staging index is the intermediate buffer where changes are registered to construct the exact snapshot. A commit is an immutable cryptographic node in Git's DAG referencing a tree object of that snapshot, metadata, and parent commit(s).
2. **Why does Git store full snapshots rather than incremental file deltas?**
   - *Answer*: Full snapshots make branch switching, merging, and cryptographic integrity verification extraordinarily fast and atomic. To prevent excessive disk consumption, Git uses zlib compression on blobs and performs packfile delta compression during garbage collection (`git gc`).
