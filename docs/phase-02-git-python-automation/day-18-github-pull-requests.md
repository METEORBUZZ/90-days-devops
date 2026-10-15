# Day 18: GitHub Remote Collaboration, Pull Requests & Governance

## 1. Theoretical Foundation

### Git Remotes Architecture
A **Remote** is a hosted reference to your Git repository on a central platform (such as GitHub, GitLab, or Bitbucket).
- **`origin`**: The default alias Git gives to the primary remote server repository you cloned from.
- **Remote-Tracking Branches**: Local read-only cached references representing the state of branches on the remote server (`origin/main`, `origin/feature-login`). They update only when you run `git fetch` or `git pull`.

```
  [ Local Working Tree ] <--(git checkout)---+
            |                                |
        (git commit)                         |
            |                                |
            v                                |
     [ Local Branch: main ] <-----------+    |
            |                           |    |
        (git push)                  (git merge/rebase)
            |                           |    |
            v                           |    |
 [ Remote Server (origin/main) ] --(git fetch)+
```

---

## 2. Remote Operations Commands

```bash
# View remote repositories and URLs
git remote -v

# Add a new remote (e.g. tracking original upstream repository in forks)
git remote add upstream https://github.com/upstream-org/project.git

# Download all new branches and commits from remote WITHOUT modifying working files
git fetch origin

# Fetch AND merge remote changes into current branch (equivalent to fetch + merge)
git pull origin main

# Fetch with rebase instead of merge (preserves clean linear history)
git pull --rebase origin main

# Push new local branch to remote and set tracking upstream (-u)
git push -u origin feature/order-processor

# Prune local references to branches that were deleted on GitHub
git remote prune origin
git fetch -p
```

---

## 3. Pull Request (PR) Lifecycle in Production

A **Pull Request** (or Merge Request) is a code review mechanism that proposes merging changes from a feature branch into a target branch (e.g. `main`).

```
1. Engineer branches off main (`git switch -c feature/metrics`)
2. Commits small, testable increments locally
3. Pushes branch to GitHub (`git push -u origin feature/metrics`)
4. Opens Pull Request on GitHub with context, architecture diagrams, and test evidence
5. Automated CI Checks run (Linting, Unit Tests, Security Vulnerability Scans)
6. Peer Review: Team members review diffs and suggest changes
7. Approval: Meets required peer reviews and CI status checks
8. Merge: Squash & Merge (or Rebase & Merge) into main
9. Automated CD Pipeline deploys main to Staging/Production
```

---

## 4. Production Branch Protection Rules

In enterprise DevOps environments, direct commits to `main` must be **strictly blocked**.
Configure these branch protection rules under **GitHub Settings > Branches**:

1. **Require a pull request before merging**:
   - Require approvals: Minimum 1 or 2 senior engineer reviews.
   - Dismiss stale pull request approvals when new commits are pushed.
2. **Require status checks to pass before merging**:
   - Require branches to be up to date before merging.
   - Required status checks:
     - `ci/test` (Unit and integration test suites)
     - `security/trivy` (Container vulnerability scan)
     - `lint/ruff` (Code style and syntax validation)
3. **Require signed commits**:
   - Enforce cryptographic verification via GPG or SSH commit signing.
4. **Do not allow bypassing the above settings**:
   - Enforce rules for repository administrators as well.

---

## 5. Merging Strategies on GitHub

When completing a PR on GitHub, three merge options exist:
1. **Create a merge commit (`git merge --no-ff`)**:
   - Preserves all individual feature commits and adds a merge commit.
   - Best for large features where commit history context is critical.
2. **Squash and merge (`git merge --squash`)**:
   - Condenses all 10–20 granular feature commits into **one single clean commit** on `main`.
   - *DevOps Best Practice*: Keeps the `main` branch history concise and easy to revert during production incidents!
3. **Rebase and merge (`git rebase`)**:
   - Replays individual commits onto `main` without creating a merge commit.
   - Preserves individual commit hashes without merge clutter.

---

## 6. Interview & Review Questions
1. **What is the difference between `git fetch` and `git pull`? Why do DevOps engineers prefer `git fetch` first?**
   - *Answer*: `git fetch` downloads the latest commits, tags, and branches from the remote server into your local `.git` repository and updates remote tracking branches (`origin/main`) without touching your working directory or modifying files. `git pull` runs `git fetch` and immediately attempts to merge into your currently checked-out branch. Using `git fetch` allows you to inspect remote diffs (`git diff main origin/main`) safely before deciding to merge.
2. **Why is "Squash and Merge" commonly enforced on production trunk branches?**
   - *Answer*: Developers frequently make messy intermediate commits on feature branches ("wip", "fixed typo", "debug logging"). Squashing collapses these into a single semantic commit on `main`, making release notes clear, git history readable, and rollback (`git revert`) trivial.
