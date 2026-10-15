# Day 19: Git Recovery, Reflog, Disaster Triage & Advanced Ops

## 1. Theoretical Foundation

One of the greatest strengths of Git is that **it almost never permanently deletes data**. As long as a commit was created, it remains in the Git object database for at least 30 to 90 days before garbage collection (`git gc`) prunes unreferenced objects.

---

## 2. Undoing Changes: `revert` vs. `reset`

```
+-------------------------------------------------------------------------------+
| Feature              | git revert                        | git reset          |
+-------------------------------------------------------------------------------+
| Mechanism            | Creates a NEW commit that inverts | Moves the branch   |
|                      | the changes of an old commit.     | pointer backward.  |
| Safe for Public/Main?| YES (Safe, preserves history).    | NO (Rewrites).     |
| History Altered?     | No (Linear forward progress).     | Yes (Truncates).   |
+-------------------------------------------------------------------------------+
```

### The Three Modes of `git reset`
```bash
# 1. Soft Reset: Moves branch pointer back, leaves staging index and working directory untouched.
# (Ideal for re-bundling the last 3 commits into 1)
git reset --soft HEAD~1

# 2. Mixed Reset (Default): Moves branch pointer back and clears staging index; leaves working directory files intact.
git reset --mixed HEAD~1
git reset HEAD~1

# 3. Hard Reset (DESTRUCTIVE): Moves pointer back, wipes staging index, and overwrites working directory!
# Any uncommitted local work is permanently lost!
git reset --hard HEAD~1
```

### Safe Production Rollback: `git revert`
```bash
# Create a new commit that undoes commit abc1234
git revert abc1234

# Revert a merge commit (must specify parent mainline -m 1)
git revert -m 1 9f8e7d6
```

---

## 3. Disaster Recovery: The Power of `git reflog`

The **Reference Log (`reflog`)** records every single movement of the `HEAD` pointer on your local machine (commits, branch checkouts, resets, cherry-picks).

### Scenario: You accidentally ran `git reset --hard HEAD~5` and lost days of work!
```bash
# 1. View reflog history
git reflog

# Output:
# 3a1b2c3 (HEAD -> main) HEAD@{0}: reset: moving to HEAD~5
# 9f8e7d6 HEAD@{1}: commit: add automated terraform pipeline
# 8c7b6a5 HEAD@{2}: commit: fix kubernetes ingress config

# 2. Notice that HEAD@{1} was the commit right before your accidental reset!
# 3. Restore your branch pointer instantly:
git reset --hard HEAD@{1}
# (Or create a branch from that commit: git branch recovered-work HEAD@{1})
```
All files and commits are 100% recovered!

---

## 4. Temporary Shelving: `git stash`

When you need to switch branches urgently to fix a production hotfix without committing half-finished work:

```bash
# Save uncommitted changes to stash stack with descriptive label
git stash push -m "WIP: refactoring auth service"

# Include untracked files as well
git stash -u -m "WIP: new endpoints"

# List all saved stashes
git stash list

# Re-apply most recent stash and remove it from stash stack
git stash pop

# Apply specific stash without removing from stack
git stash apply stash@{1}

# Purge stash
git stash drop stash@{0}
git stash clear
```

---

## 5. Selective Commit Porting: `git cherry-pick`

`cherry-pick` copies an exact commit from one branch and applies it onto your current branch without merging the whole branch.

```bash
# Switch to production release branch
git switch release/v2.1

# Grab hotfix commit 4a5b6c7 from main branch
git cherry-pick 4a5b6c7
```

---

## 6. Interview & Review Questions
1. **You accidentally deleted a feature branch containing 10 commits that were never pushed to GitHub (`git branch -D feature`). How do you recover it?**
   - *Answer*: Run `git reflog`. Find the commit hash corresponding to the last commit made on that feature branch before deletion (e.g. `HEAD@{4}`). Then run `git checkout -b feature <commit-hash>`. The branch and all 10 commits are fully restored.
2. **What is the difference between `git checkout -- file.txt` and `git restore file.txt`?**
   - *Answer*: Both discard unstaged local changes in `file.txt` by overwriting it with the version from the staging index. `git restore` was introduced in Git 2.23 to disambiguate file restoration from branch switching, making checkout syntax cleaner.
