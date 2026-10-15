# Day 17: Git Branching Strategies, Merging & Conflict Resolution

## 1. Theoretical Foundation

### What is a Git Branch?
In Git, a branch is **not** a copy of your files. A branch is simply an 8-byte pointer file (stored in `.git/refs/heads/<branch-name>`) containing the 40-character SHA-1 hash of the latest commit on that line of development.
Creating a branch in Git is virtually instantaneous and consumes zero storage overhead!

```
                    Feature Branch
                 C3 <--- C4 (feature/payment-api)
                /
  C0 <--- C1 <--- C2 (main, HEAD)
```

### Merge Types: Fast-Forward vs. 3-Way Merge

#### 1. Fast-Forward Merge (`git merge --ff`)
Occurs when the target branch (`main`) has had **no new commits** since the feature branch was created. Git simply moves the `main` pointer forward to match the tip of the feature branch. No new merge commit is created.

```
Before Merge:
main:     C1
feature:  C1 <--- C2 <--- C3

After Fast-Forward Merge:
main, feature: C1 <--- C2 <--- C3
```

#### 2. Three-Way Merge (`git merge --no-ff`)
Occurs when both branches have diverged with independent commits. Git finds the **Common Ancestor** (Base), compares the two branch tips, and creates a new **Merge Commit** with two parent pointers ($P_1, P_2$).

```
        C3 <--- C4 (feature)
       /          \
C1 <--- C2 <------- C5 (main - Merge Commit)
```

### Git Merge vs. Git Rebase

| Operation | Mechanism | Pros | Cons |
| :--- | :--- | :--- | :--- |
| **`git merge`** | Preserves complete chronological history by adding a merge commit. | Non-destructive; maintains exact historical truth and context. | Creates cluttered, non-linear commit history ("railroad tracks"). |
| **`git rebase`** | Replays your feature commits on top of the latest target branch base. | Clean, perfectly linear commit history; easy `git bisect`. | Rewrites commit SHAs; dangerous if performed on public/shared branches! |

---

## 2. Branch Management Commands

```bash
# List local branches (* indicates currently checked-out branch)
git branch

# List all local and remote tracking branches
git branch -a

# Create a new branch and switch to it immediately
git switch -c feature/auth-jwt
# (Legacy alternative: git checkout -b feature/auth-jwt)

# Switch between existing branches
git switch main

# Rename current branch
git branch -m feature/auth-oauth2

# Delete a merged branch safely
git branch -d feature/auth-oauth2

# Force delete an unmerged branch
git branch -D feature/stale-experiment
```

---

## 3. Resolving Merge Conflicts Step-by-Step

A merge conflict occurs when two branches modify the **exact same line** of a file differently, or one branch deletes a file that another modified.

### 1. Identify the Conflict
```bash
git switch main
git merge feature/new-database
# Output:
# Auto-merging config.yaml
# CONFLICT (content): Merge conflict in config.yaml
# Automatic merge failed; fix conflicts and then commit the result.
```

### 2. Inspect Conflict Markers
Open `config.yaml` in your editor. Git demarcates the disputed code:
```yaml
database:
<<<<<<< HEAD
  host: "prod-db.internal"
  pool_size: 20
=======
  host: "db-cluster-v2.internal"
  pool_size: 50
>>>>>>> feature/new-database
  timeout: 5s
```
- `<<<<<<< HEAD`: The version on your currently checked-out branch (`main`).
- `=======`: The separator dividing the competing changes.
- `>>>>>>> feature/new-database`: The version coming from the branch being merged.

### 3. Resolve & Finalize
Edit the file to the desired state, removing all marker lines (`<<<<<<<`, `=======`, `>>>>>>>`):
```yaml
database:
  host: "db-cluster-v2.internal"
  pool_size: 50
  timeout: 5s
```
Stage the resolved file and commit:
```bash
git add config.yaml
git commit -m "merge: resolve database configuration conflict between main and feature/new-database"
```

To abort a merge in progress at any point without saving changes:
```bash
git merge --abort
```

---

## 4. Industry Branching Strategies

### 1. Trunk-Based Development (DevOps & CI/CD Standard)
- All engineers work on short-lived feature branches (lifespan < 1–2 days).
- Branches merge frequently into a single `main` (or `trunk`) branch via small, automated Pull Requests.
- Feature flags decouple deployment from feature release.
- Maximizes CI/CD speed and eliminates painful merge conflicts.

### 2. GitFlow (Legacy / Scheduled Release Cycles)
- Uses long-lived branches: `main`, `develop`, `release/*`, `hotfix/*`, `feature/*`.
- Complex; often creates merge bottlenecks in high-velocity microservices teams.

---

## 5. Interview & Review Questions
1. **What is the "Golden Rule of Rebasing"?**
   - *Answer*: Never rebase a branch that is shared with other developers (such as `main` or a collaborative team branch). Rebasing rewrites commit hashes; if others have based work on those commits, rebasing creates duplicate conflicting histories and broken tracking branches.
2. **How does Git find the base commit during a 3-way merge?**
   - *Answer*: Git traverses the Directed Acyclic Graph (DAG) backwards from the tips of both branches to find their Lowest Common Ancestor (LCA) commit. It then compares LCA to Branch A, and LCA to Branch B, to construct the merged tree.
