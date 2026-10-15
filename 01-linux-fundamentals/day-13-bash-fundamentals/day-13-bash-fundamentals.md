# Day 13: Bash Scripting Fundamentals & Defensive Coding

## 1. Theoretical Foundation

### What is Bash?
Bash (Bourne Again SHell) is the standard command language and shell interpreter for GNU/Linux systems.
In DevOps, Bash scripts are used for:
- Container entrypoints (`entrypoint.sh`).
- CI/CD build scripts (`build.sh`, `deploy.sh`).
- Cloud instance provisioning (`user-data.sh` / Cloud-Init).
- Automated health checks and backup cron jobs.

### The Shebang (`#!`)
The first line of any executable script must be the **Shebang**:
```bash
#!/usr/bin/env bash
```
- **Why `#!/usr/bin/env bash` instead of `#!/bin/bash`?**: Portable across different distributions, macOS, and BSD systems where bash might reside in `/usr/local/bin/bash` or `/opt/homebrew/bin/bash`.

---

## 2. Defensive Bash: Strict Mode (`set -euo pipefail`)

By default, Bash continues executing subsequent lines even if previous commands crash with fatal errors. In production automation, this leads to catastrophic failures (e.g. `cd /nonexistent/dir; rm -rf *`).

**Always put this line at the top of every production script:**
```bash
set -euo pipefail
IFS=$'\n\t'
```

### Breakdown of Strict Mode Flags
1. **`set -e` (Exit on Error)**:
   - Immediately exits the script if any command returns a non-zero exit code.
2. **`set -u` (Nounset / Unbound Variables)**:
   - Treats uninitialized variables as fatal errors rather than silently substituting an empty string (`$STALE_VAR` won't wipe `/` if unset!).
3. **`set -o pipefail` (Pipeline Failure)**:
   - If any command in a pipeline (`cmd1 | cmd2 | cmd3`) fails, the entire pipeline returns the exit code of the failing command instead of just the last one.
4. **`IFS=$'\n\t'` (Internal Field Separator)**:
   - Splits loops only on newlines and tabs, avoiding whitespace splitting bugs on files with spaces.

---

## 3. Variables, Quoting & Exit Codes

### Variables and Quoting Rules
```bash
#!/usr/bin/env bash
set -euo pipefail

# Defining variables (NO spaces around =)
APP_NAME="orders-service"
PORT=8080
RELEASE_DIR="/opt/${APP_NAME}/releases"

# ALWAYS quote variable expansions to prevent word-splitting and glob expansion:
echo "Deploying to: ${RELEASE_DIR}"

# Single vs Double quotes:
echo '$APP_NAME'   # Prints literal: $APP_NAME
echo "$APP_NAME"   # Prints expanded: orders-service
```

### Command Substitution (`$(...)`)
Capture command stdout into a variable:
```bash
# Recommended modern syntax:
CURRENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Legacy syntax (AVOID):
# CURRENT_TIME=`date`
```

### Exit Codes (`$?`)
Every Linux command returns an exit code between 0 and 255:
- **`0`**: Success.
- **`1–255`**: Failure (e.g. `1`: General error, `2`: Misuse of shell builtins, `127`: Command not found).

```bash
grep -q "root" /etc/passwd
if [[ $? -eq 0 ]]; then
    echo "Found root user"
fi
```

---

## 4. Arithmetic Operations

```bash
# Using $(( ... ))
COUNT=5
TOTAL=$((COUNT + 10))
echo "Total: $TOTAL"

# Division and remainder
REMAINDER=$((10 % 3))    # 1
```

---

## 5. Signal Trapping: Safe Resource Cleanup (`trap`)

In automated workflows, scripts create temporary files, lock files, or mount points. If the script gets interrupted by `Ctrl+C` (`SIGINT`) or exits unexpectedly, those resources must be cleaned up!

```bash
#!/usr/bin/env bash
set -euo pipefail

# Create temporary directory
TMP_DIR=$(mktemp -d /tmp/app-deploy.XXXXXX)

# Register cleanup trap to execute whenever script exits (NORMAL, ERROR, or SIGNAL)
cleanup() {
    echo "Executing cleanup trap: purging $TMP_DIR..."
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "Working inside temporary directory $TMP_DIR..."
# Do work... when script finishes or fails, cleanup() is guaranteed to run!
```

---

## 6. Interview & Review Questions
1. **Why is `set -o pipefail` critical in CI/CD pipeline scripts?**
   - *Answer*: By default in Bash, the exit status of a pipeline (`cmdA | cmdB`) is the exit status of the *last* command (`cmdB`). If `cmdA` fails (e.g. `curl -f https://internal/binary | tar -xz`), but `tar` simply outputs empty and exits 0, the script would believe the download succeeded. `pipefail` ensures any failure in the pipe aborts the script.
2. **What does `${VAR:-default}` and `${VAR:?error_message}` mean in Bash?**
   - *Answer*: `${VAR:-default}` assigns a fallback default value if `VAR` is unset or empty. `${VAR:?error_message}` tests if `VAR` is set; if not, it outputs `error_message` to stderr and immediately terminates the script with a non-zero exit code.
