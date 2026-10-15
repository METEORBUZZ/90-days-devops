# Day 05: Linux Permissions, Ownership & Special Bits

## 1. Theoretical Foundation

### The Linux Permission Matrix
Every file and directory in Linux has permissions assigned across three distinct scopes:
1. **User (`u`)**: The owner of the file.
2. **Group (`g`)**: Members of the group assigned to the file.
3. **Others (`o`)**: All other users on the system ("world").

```
  -   r w x   r - x   r - -
  ^   \___/   \___/   \___/
Type   User   Group   Others
```

### Permission Meanings on Files vs. Directories
| Permission | On a File | On a Directory |
| :--- | :--- | :--- |
| **Read (`r`)** | Can view file contents (`cat`, `less`) | Can list filenames inside the directory (`ls`) |
| **Write (`w`)** | Can modify file contents (`nano`, `>>`) | Can create, delete, or rename files inside the directory |
| **Execute (`x`)** | Can run the file as a program or script | Can enter (`cd`) and access files inside the directory |

*Critical Insight: Even if a file has `rwx` permissions, if the directory containing it lacks `x` permission, you cannot access or execute the file!*

### Octal (Numeric) Representation
Each permission has a numeric weight based on binary bits ($2^2=4$, $2^1=2$, $2^0=1$):
- **Read (`r`)** = 4
- **Write (`w`)** = 2
- **Execute (`x`)** = 1
- **None (`-`)** = 0

Common Production Modes:
- `755` (`rwxr-xr-x`): Standard for executable binaries, scripts, and public directories.
- `644` (`rw-r--r--`): Standard for configuration files, source code, and assets.
- `600` (`rw-------`): Private keys, SSH keys, credentials (only owner can read/write).
- `700` (`rwx------`): Private directories (`~/.ssh`).

---

## 2. Managing Ownership & Permissions

### `chmod` (Change Mode)
```bash
# Symbolic mode
chmod u+x deploy.sh          # Add execute for owner
chmod g-w config.json        # Remove write for group
chmod o=r public.txt         # Set others to read-only
chmod -R 755 /var/www/html   # Recursive mode change

# Octal mode
chmod 600 id_rsa             # Secure private SSH key
chmod 644 nginx.conf
```

### `chown` (Change Owner & Group)
```bash
chown nginx /var/www/html/index.html            # Change user owner only
chown :www-data /var/www/html/index.html         # Change group owner only
chown nginx:www-data /var/www/html/index.html   # Change both user and group
chown -R appuser:appgroup /opt/application      # Recursive ownership change
```

### The `umask` (User Mask)
When a process creates a new file or directory, the kernel calculates initial permissions by subtracting `umask` from maximum permissions:
- Maximum default for **files**: `666` (`rw-rw-rw-`)
- Maximum default for **directories**: `777` (`rwxrwxrwx`)
- Default system `umask`: `022`
  - New File: `666 - 022 = 644` (`rw-r--r--`)
  - New Directory: `777 - 022 = 755` (`rwxr-xr-x`)
- High-security `umask`: `027`
  - New File: `666 - 027 = 640` (others have zero access)

---

## 3. Special Permission Bits: SUID, SGID, and Sticky Bit

```
Special Bits:
- SUID (4): Run executable with owner's privileges (e.g. /usr/bin/passwd)
- SGID (2): Inherit directory group for new files / run with group privileges
- Sticky Bit (1): Prevent users from deleting others' files in shared directory (/tmp)
```

### 1. SUID (Set User ID — Numeric 4xxx)
When applied to an executable file, any user who runs the binary executes it with the privileges of the **file owner** rather than the calling user.
- Example: `/usr/bin/passwd` needs SUID root (`-rwsr-xr-x`) because ordinary users must update `/etc/shadow` when changing their password.
- Syntax: `chmod u+s /usr/local/bin/custom_binary` or `chmod 4755 ...`

### 2. SGID (Set Group ID — Numeric 2xxx)
- **On executable**: Runs with permissions of the file group.
- **On directory**: Any new file created inside this directory automatically inherits the **group of the directory**, rather than the primary group of the user creating the file.
- DevOps Use Case: Shared developer deployment folders!
- Syntax: `chmod g+s /var/www/shared` or `chmod 2775 ...`

### 3. Sticky Bit (Numeric 1xxx)
When applied to a directory, users can only delete or rename files that **they own**, even if the directory has full `777` write permissions for others.
- Canonical Example: `/tmp` permissions are `drwxrwxrwt` (`1777`).
- Syntax: `chmod +t /shared_directory` or `chmod 1777 /shared_directory`

---

## 4. Hands-on Lab: Shared Team Directory with SGID and Sticky Bit

```bash
#!/usr/bin/env bash
set -euo pipefail

# 1. Setup shared directory
DIR="/tmp/team-collab"
mkdir -p "$DIR"

# 2. Assign group and permissions with SGID
# 2770 = SGID (2) + Owner rwx (7) + Group rwx (7) + Others none (0)
sudo chmod 2770 "$DIR"
echo "Directory permissions:"
ls -ld "$DIR"

# 3. Create file inside directory and observe inherited group
touch "$DIR/app-config.yaml"
ls -l "$DIR/app-config.yaml"

# Cleanup
rm -rf "$DIR"
```

---

## 5. Common Production Pitfalls

| Mistake | Consequence | Safe Fix |
| :--- | :--- | :--- |
| `chmod 777 /var/www` | Security vulnerability; any process or local attacker can overwrite files or inject web shells. | Use `755` for directories, `644` for files, and manage write access via groups (`chown -R www-data:www-data`). |
| `chmod -R 755 ~/.ssh` | SSH client refuses to authenticate (`Permissions 0755 for 'id_rsa' are too open`). | SSH keys must strictly be `chmod 600 ~/.ssh/id_rsa` and `chmod 700 ~/.ssh`. |
| Unintended SUID binaries | Privilege escalation vector (LinPEAS checks this first). | Search for dangerous SUID files: `find / -perm -4000 -type f 2>/dev/null`. |

---

## 6. Interview & Review Questions
1. **Why does SSH reject a private key if its permissions are `644` or `777`?**
   - *Answer*: SSH enforces strict security hygiene. A private key must remain confidential. If readable by group or others (`world`), another local process or user could steal the key. The SSH client actively aborts connection attempts until permissions are restricted (`0600`).
2. **What is the SGID bit on directories, and how does it solve multi-user file permission conflicts?**
   - *Answer*: When SGID is set on a directory, files created within it automatically inherit the directory's group ownership rather than the user's default group. This ensures all team members in that group can collaborate on files without manual permission updates.
