# Day 04: Users, Groups & sudo Privilege Management

## 1. Theoretical Foundation

### The Linux Security Model: Authentication & Authorization
Linux enforces multi-user access control through:
- **UID (User Identifier)**: Integer identifying an account.
  - `UID 0`: The `root` superuser (unrestricted kernel access).
  - `UID 1–999`: System / Service accounts (e.g. `nginx`, `systemd-resolve`, `docker`, `postgres`) that do not have interactive login shells.
  - `UID 1000+`: Regular human users.
- **GID (Group Identifier)**: Integer identifying a group for collaborative resource sharing.

### Critical System Files
1. **`/etc/passwd`** (Publicly readable): Contains account metadata.
   Format: `username:password_flag:UID:GID:comment_gecos:home_directory:login_shell`
   Example: `jenkins:x:1001:1001:Jenkins CI User:/var/lib/jenkins:/bin/bash`
2. **`/etc/shadow`** (Only readable by root): Stores salted password hashes and expiration policies.
   Format: `username:$id$salt$hashed_password:last_changed:min:max:warn:inactive:expire`
3. **`/etc/group`** (Publicly readable): Maps group names to GIDs and member user lists.
4. **`/etc/sudoers`** (Configured via `visudo`): Defines privilege delegation rules.

---

## 2. User & Group Management Commands

### Creating & Managing Users
```bash
# Create a dedicated system user for an application (no interactive shell, no home directory)
useradd -r -s /usr/sbin/nologin -d /opt/myapp myappuser

# Create standard user with home directory and bash shell
useradd -m -s /bin/bash devops_intern

# Set or change password
passwd devops_intern

# Lock an account (prevent login)
usermod -L devops_intern

# Unlock account
usermod -U devops_intern

# Delete user and remove their home directory
userdel -r devops_intern
```

### Managing Groups
```bash
# Create a new group
groupadd devops-team

# Add a user to a supplementary group (CRITICAL: always use -aG to APPEND, not overwrite!)
usermod -aG docker,devops-team devops_intern

# View all groups the current user belongs to
groups
id
```

### `sudo` & Least Privilege Administration
`sudo` (SuperUser DO) allows authorized users to execute specific commands with elevated privileges without sharing the root password.

Always edit `/etc/sudoers` using `visudo` to prevent syntax errors that lock you out of root privileges!

```bash
# Sudoers configuration syntax:
# USER/GROUP    HOST=(RUN_AS_USER:RUN_AS_GROUP)    COMMANDS

# 1. Allow user 'alice' to run ANY command with password
alice ALL=(ALL:ALL) ALL

# 2. Allow group 'wheel' or 'sudo' full sudo access
%sudo ALL=(ALL:ALL) ALL

# 3. Allow deployer to restart nginx without a password (Least Privilege)
deployer ALL=(ALL) NOPASSWD: /bin/systemctl restart nginx, /bin/systemctl reload nginx

# 4. Drop-in configuration directory:
# Always place custom rules in /etc/sudoers.d/app-deployers instead of editing /etc/sudoers directly!
```

---

## 3. DevOps Production Best Practices

### 1. Dedicated Service Accounts for Microservices
**Never run production applications or Docker containers as `root`!**
If an attacker compromises an application running as `root`, they gain full control over the host node.
In Dockerfiles:
```dockerfile
# Create non-privileged system user
RUN groupadd -r appgroup && useradd -r -g appgroup -s /usr/sbin/nologin appuser
USER appuser
```

### 2. Passwordless Automation in CI/CD Runners
When Jenkins or GitHub Actions runners run commands via sudo, grant minimal explicit command permissions in `/etc/sudoers.d/runner`:
```text
runner ALL=(root) NOPASSWD: /usr/bin/docker, /usr/bin/apt-get update
```

---

## 4. Hands-on Lab: Provisioning an Isolated Service Account

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "--- 1. Create devops-engineers group ---"
sudo groupadd -f devops-engineers

echo "--- 2. Create isolated service account ---"
if ! id "svc-monitor" &>/dev/null; then
    sudo useradd -r -m -d /opt/svc-monitor -s /bin/bash -g devops-engineers svc-monitor
fi

echo "--- 3. Verify user details ---"
id svc-monitor
grep "^svc-monitor:" /etc/passwd

echo "--- 4. Configure least-privilege sudo rule ---"
# Create safe drop-in rule verified by visudo syntax checker
echo "svc-monitor ALL=(ALL) NOPASSWD: /bin/systemctl status *" | sudo tee /etc/sudoers.d/svc-monitor-rule
sudo chmod 0440 /etc/sudoers.d/svc-monitor-rule
sudo visudo -cf /etc/sudoers.d/svc-monitor-rule

echo "--- 5. Clean up lab resources ---"
sudo rm -f /etc/sudoers.d/svc-monitor-rule
sudo userdel -r svc-monitor 2>/dev/null || true
sudo groupdel devops-engineers 2>/dev/null || true
echo "Lab completed successfully."
```

---

## 5. Common Production Pitfalls

| Mistake | What Happens | Fix |
| :--- | :--- | :--- |
| `usermod -G group user` (omitted `-a`) | Removes the user from all previous secondary groups (including `sudo`, `docker`)! | Always use `usermod -aG group user` (append flag). |
| Directly editing `/etc/sudoers` with `nano` | A single typo or syntax error breaks `sudo` for all users on the machine. | Always use `sudo visudo`, which validates syntax before saving. |
| Assigning `/bin/bash` to service accounts | Opens unnecessary interactive login attack surfaces. | Set shell to `/usr/sbin/nologin` or `/bin/false`. |

---

## 6. Interview & Review Questions
1. **What is the difference between `/etc/passwd` and `/etc/shadow`? Why are they separated?**
   - *Answer*: `/etc/passwd` must be world-readable so programs can resolve UIDs to usernames. If password hashes were stored there, any unprivileged user could copy them for offline dictionary attacks. Therefore, salted password hashes are stored in `/etc/shadow`, which is readable only by the root user (`0600` or `0640` root:shadow).
2. **What does `visudo` do and why is it mandatory when modifying sudo privileges?**
   - *Answer*: `visudo` locks the sudoers file against concurrent edits and checks the configuration for syntax errors prior to writing changes to disk, preventing syntax corruption that could lock administrators out of root access.
