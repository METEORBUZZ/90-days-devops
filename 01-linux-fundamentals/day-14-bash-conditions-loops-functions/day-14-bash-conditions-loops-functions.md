# Day 14: Conditions, Loops & Functions in Bash

## 1. Theoretical Foundation

To build robust automation scripts, you need structured control flow:
- **Conditionals**: `if/elif/else`, `case` statements.
- **Loops**: `for`, `while`, `until`.
- **Functions**: Reusable blocks of logic with local variable scoping and return codes.
- **Positional Arguments**: Handling CLI flags and parameters (`$1`, `$@`, `$#`).

---

## 2. Conditionals: `[[ ... ]]` vs. `[ ... ]`

Always prefer double brackets **`[[ ... ]]`** in Bash scripts:
- Native Bash keyword (faster execution).
- Prevents errors on unquoted empty variables.
- Supports pattern matching, regular expressions (`=~`), and logical operators (`&&`, `||`) directly.

### File & Directory Tests
```bash
[[ -f "$FILE" ]]    # True if file exists and is a regular file
[[ -d "$DIR" ]]     # True if directory exists
[[ -e "$PATH" ]]    # True if path exists (any type)
[[ -s "$FILE" ]]    # True if file exists and size > 0 bytes (non-empty)
[[ -r "$FILE" ]]    # True if readable
[[ -w "$FILE" ]]    # True if writable
[[ -x "$FILE" ]]    # True if executable
```

### String & Integer Comparisons
```bash
# Strings (Use == and !=)
[[ -z "$STR" ]]           # True if string is EMPTY (length 0)
[[ -n "$STR" ]]           # True if string is NOT empty
[[ "$ENV" == "prod" ]]    # String equality
[[ "$VERSION" =~ ^v[0-9]+\.[0-9]+ ]] # Regex match!

# Integers (Use -eq, -ne, -lt, -le, -gt, -ge)
[[ "$HTTP_CODE" -eq 200 ]]
[[ "$DISK_USED" -ge 85 ]]
```

### Complete `if/elif/else` Example
```bash
if [[ "$ENV" == "production" ]]; then
    echo "Applying strict production configuration..."
elif [[ "$ENV" == "staging" ]]; then
    echo "Applying staging settings..."
else
    echo "Applying local developer defaults..."
fi
```

### Clean Branching: `case` Statements
Ideal for handling commands or environment variables:
```bash
case "$ACTION" in
    start)
        systemctl start "$SERVICE"
        ;;
    stop)
        systemctl stop "$SERVICE"
        ;;
    restart|reload)
        systemctl restart "$SERVICE"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}" >&2
        exit 1
        ;;
esac
```

---

## 3. Loops in DevOps Automation

### The `for` Loop
Iterating over lists or arrays:
```bash
# List of server hosts
SERVERS=("web-01" "web-02" "db-01")

for SERVER in "${SERVERS[@]}"; do
    echo "Pinging node: ${SERVER}..."
done

# Iterating over files safely (avoids word-splitting)
for CONF in /etc/nginx/conf.d/*.conf; do
    [[ -e "$CONF" ]] || continue   # Handle empty glob case
    echo "Validating syntax for: $CONF"
    nginx -t -c "$CONF"
done
```

### The `while` Loop & Reading Files Line-by-Line
```bash
# Safely reading lines from a CSV or log file without trailing newline bugs:
while IFS= read -r LINE || [[ -n "$LINE" ]]; do
    echo "Processing entry: $LINE"
done < /tmp/servers.txt
```

### Polling Loop with Timeout (Wait for Service to be Healthy)
```bash
ATTEMPTS=0
MAX_ATTEMPTS=30
URL="http://localhost:8080/health"

echo "Waiting for service to become healthy..."
until curl -fs "$URL" > /dev/null; do
    ATTEMPTS=$((ATTEMPTS + 1))
    if [[ "$ATTEMPTS" -ge "$MAX_ATTEMPTS" ]]; then
        echo "ERROR: Service failed to start within 30 seconds!" >&2
        exit 1
    fi
    sleep 1
done
echo "Service is healthy and ready to accept traffic."
```

---

## 4. Reusable Bash Functions

Functions in Bash:
- Should declare internal variables with `local` to avoid leaking state into the global script.
- Return exit codes (`0` for success, non-zero for error) via `return`.
- Access arguments via `$1`, `$2`, `$@`.

```bash
#!/usr/bin/env bash
set -euo pipefail

# Structured logging function
log_info() {
    local MSG="$1"
    echo -e "[\e[32mINFO\e[0m] $(date -u +"%Y-%m-%dT%H:%M:%SZ"): ${MSG}"
}

log_error() {
    local MSG="$1"
    echo -e "[\e[31mERROR\e[0m] $(date -u +"%Y-%m-%dT%H:%M:%SZ"): ${MSG}" >&2
}

# Function to check if a binary exists
require_tool() {
    local TOOL="$1"
    if ! command -v "$TOOL" &> /dev/null; then
        log_error "Required tool '${TOOL}' is not installed or not in PATH."
        return 1
    fi
    log_info "Tool '${TOOL}' is installed."
    return 0
}

# Usage:
require_tool "curl"
require_tool "jq"
require_tool "docker"
```

---

## 5. Parsing CLI Flags: `getopts`

```bash
#!/usr/bin/env bash
set -euo pipefail

ENV="dev"
PORT=8080

usage() {
    echo "Usage: $0 [-e <env>] [-p <port>]" >&2
    exit 1
}

while getopts ":e:p:h" OPT; do
    case "$OPT" in
        e) ENV="$OPTARG" ;;
        p) PORT="$OPTARG" ;;
        h) usage ;;
        \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
        :)  echo "Option -$OPTARG requires an argument." >&2; usage ;;
    esac
done

echo "Starting server in environment: $ENV on port: $PORT"
```

---

## 6. Interview & Review Questions
1. **What is the difference between `local VAR=...` and standard `VAR=...` inside a Bash function?**
   - *Answer*: By default, all variables in Bash are global across the script. If a function modifies `VAR` without the `local` keyword, it overwrites the variable in the caller's scope, leading to subtle state bugs. `local` confines the variable strictly to that function execution.
2. **Why should you never use `for line in $(cat file.txt)` to read a file?**
   - *Answer*: Command substitution `$(cat file.txt)` subject to word splitting splits not only on newlines, but also on spaces and tabs (based on `IFS`). Any line containing whitespace will be split into multiple iterations. The correct pattern is `while IFS= read -r line; do ... done < file.txt`.
