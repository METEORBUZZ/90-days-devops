# Day 03: Text Processing, Standard Streams & Regular Expressions

## 1. Theoretical Foundation

### The Linux Standard Streams (File Descriptors 0, 1, 2)
Every process spawned in Linux is initialized with three default I/O streams:
1. **File Descriptor 0 (`stdin`)**: Standard Input (default: keyboard or piped input).
2. **File Descriptor 1 (`stdout`)**: Standard Output (default: terminal screen).
3. **File Descriptor 2 (`stderr`)**: Standard Error (default: unbuffered terminal screen for error diagnostics).

```
   [ Command A ] --(stdout / FD 1)--> [ Pipe | ] --(stdin / FD 0)--> [ Command B ]
         |
    (stderr / FD 2)
         v
   [ error.log ]
```

### Redirection Operators
- `>` : Overwrites stdout to a file (`echo "val" > file.txt`).
- `>>` : Appends stdout to a file (`echo "val" >> file.txt`).
- `<` : Feeds a file into stdin (`mysql -u root < database.sql`).
- `2>` : Redirects stderr only (`command 2> errors.log`).
- `2>&1` : Redirects stderr into stdout (`command > output.log 2>&1`).
- `&>` or `>&` : Combined redirect of both stdout and stderr into a file (`command &> all.log`).
- `/dev/null` : The Linux black hole bit-bucket. Silences output (`command > /dev/null 2>&1`).

---

## 2. Text Processing Toolkit for DevOps

### Reading Large Files Without Memory Spikes
- **`cat`**: Dumps entire file to stdout (only for tiny files).
- **`less`**: Paginates large files without reading the entire file into RAM (press `/` to search forward, `q` to quit).
- **`head -n 20`**: Inspects first 20 lines (e.g. checking CSV/log headers).
- **`tail -n 50`**: Inspects last 50 lines.
- **`tail -f /var/log/nginx/access.log`**: Live follow of streaming logs.
- **`tail -F`**: Follow by file name (handles log rotation when the file is recreated).

### `grep` (Global Regular Expression Print)
Search patterns and regex inside text streams:
```bash
grep "ERROR" /var/log/syslog              # Simple literal search
grep -i "error" /var/log/syslog           # Case-insensitive match (Error, ERROR, error)
grep -v "DEBUG" app.log                   # Invert match (exclude DEBUG lines)
grep -r "DATABASE_URL" /etc/app/          # Recursive search in directory
grep -n "FATAL" app.log                   # Print line numbers
grep -E "(404|500|502)" access.log        # Extended regex (OR conditions)
grep -c "CRITICAL" app.log                # Count total matching lines
grep -C 3 "NullPointerException" app.log  # Show 3 lines of Context around match
```

### `awk` (Field-Oriented Processing)
`awk` splits lines into fields delimited by whitespace (or custom delimiter `-F`):
```bash
# Print first and ninth column of an Apache/Nginx log (IP and HTTP Status code)
awk '{print $1, $9}' /var/log/nginx/access.log

# Custom delimiter: Print usernames (field 1) and shells (field 7) from /etc/passwd
awk -F: '{print $1, "uses shell", $7}' /etc/passwd

# Filter lines where HTTP status (column 9) is 500
awk '$9 == "500" {print $1, $4, $9}' access.log

# Compute total bandwidth (sum of column 10 in bytes)
awk '{sum += $10} END {print "Total MB transferred:", sum / 1024 / 1024}' access.log
```

### `sed` (Stream Editor)
Non-interactive text transformations and replacements:
```bash
# Replace first occurrence of 'localhost' with 'db.internal'
sed 's/localhost/db.internal/' config.env

# Global replacement (/g) and in-place file edit (-i)
sed -i 's/DEBUG=True/DEBUG=False/g' settings.py

# Delete matching lines (e.g. remove all commented lines)
sed -i '/^#/d' config.conf

# Delete blank lines
sed -i '/^$/d' config.conf
```

### `cut`, `sort`, `uniq`, and `wc`
```bash
# Extract column 1 with custom comma delimiter
cut -d',' -f1 metrics.csv

# Sort alphanumerically or numerically (-n)
sort -k2 -n data.txt

# Count unique items (input MUST be sorted first)
sort access.log | uniq -c | sort -nr | head -n 10

# Count lines, words, bytes
wc -l access.log
```

---

## 3. Real-World DevOps Pipeline

### Top 10 IP Addresses Attacking / Accessing a Web Server
```bash
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -nr | head -n 10
```
**Explanation**:
1. `awk '{print $1}'`: Extracts IP address (column 1).
2. `sort`: Groups identical IP addresses together.
3. `uniq -c`: Counts occurrences of each unique IP.
4. `sort -nr`: Sorts numbers (`-n`) in reverse order (`-r`) so highest counts are at top.
5. `head -n 10`: Grabs top 10 suspicious IPs for firewall blocking.

---

## 4. Hands-on Lab: Nginx Log Parsing Exercise

Create a test log and extract production metrics:
```bash
#!/usr/bin/env bash
set -euo pipefail

# 1. Create realistic dummy access log
cat << 'EOF' > /tmp/access.log
192.168.1.10 - - [15/Oct/2026:10:00:01 +0000] "GET /api/v1/health HTTP/1.1" 200 120
192.168.1.15 - - [15/Oct/2026:10:00:02 +0000] "POST /api/v1/login HTTP/1.1" 401 240
192.168.1.10 - - [15/Oct/2026:10:00:03 +0000] "GET /api/v1/users HTTP/1.1" 500 890
192.168.1.20 - - [15/Oct/2026:10:00:04 +0000] "GET /api/v1/products HTTP/1.1" 200 4500
192.168.1.15 - - [15/Oct/2026:10:00:05 +0000] "POST /api/v1/login HTTP/1.1" 401 240
192.168.1.15 - - [15/Oct/2026:10:00:06 +0000] "POST /api/v1/login HTTP/1.1" 401 240
EOF

echo "--- 5xx Errors ---"
grep " 50[0-9] " /tmp/access.log

echo "--- HTTP Status Code Frequency ---"
awk '{print $9}' /tmp/access.log | sort | uniq -c | sort -nr

echo "--- Top Requesting IP ---"
awk '{print $1}' /tmp/access.log | sort | uniq -c | sort -nr | head -n 1

# Cleanup
rm -f /tmp/access.log
```

---

## 5. Common Production Pitfalls

| Mistake | What Happens | Fix |
| :--- | :--- | :--- |
| `command > file.txt < file.txt` | Truncates file.txt to 0 bytes before reading it! | Use a temporary file or `sponge` from moreutils (`command file.txt \| sponge file.txt`). |
| `sort` omitted before `uniq` | `uniq` only merges adjacent duplicate lines. Unsorted duplicates are ignored. | Always pipe through `sort | uniq -c`. |
| Running `cat file | grep text` | Unnecessary pipeline ("Useless Use of Cat"). Wastes CPU cycles and subshells. | Use `grep text file` directly. |

---

## 6. Interview & Review Questions
1. **Explain the difference between `>` and `>>`. What happens if you run `command > file` and the command errors out?**
   - *Answer*: `>` truncates and overwrites, while `>>` appends. If you run `command > file` and the command fails with an error outputting to stderr, the destination file is still truncated to 0 bytes because the shell opens and truncates the file *before* executing the command.
2. **What is the difference between `grep`, `awk`, and `sed`?**
   - *Answer*: `grep` is a search and filtering utility; `sed` is a stream editor designed for pattern replacements and transformations; `awk` is a complete field-based pattern-scanning and data processing programming language.
