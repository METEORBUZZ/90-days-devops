# Day 12: SSH Architecture, Key Management & Secure Remote Access

## 1. Theoretical Foundation

### How SSH (Secure Shell) Works
SSH (port 22) provides an encrypted communication channel over an insecure network using public-key cryptography.

```
       Client Machine                                Server Machine
+--------------------------+                   +--------------------------+
|  Private Key (id_ed25519)|                   |  ~/.ssh/authorized_keys  |
|      [ KEEP SECRET ]     |                   |  (Stores Public Key)     |
+--------------------------+                   +--------------------------+
             |                                              |
             +-------------- Diffie-Hellman ----------------+
             |           Key Exchange (Session Key)         |
             |                                              |
             | ---- Challenge encrypted with Public Key --> |
             | <-- Response decrypted with Private Key ---- |
             |                                              |
             +================ Secure Encrypted Tunnel =====+
```

### Key Algorithms: RSA vs. ED25519
- **RSA (Legacy standard)**: Requires large keys (minimum 2048-bit, recommended 4096-bit) to be secure. Slower key generation.
- **Ed25519 (Modern standard)**: Elliptic curve algorithm (Curve25519). Shorter key length (256-bit), faster cryptographic operations, and mathematically immune to known side-channel attacks.
- *Modern DevOps Recommendation: Always use `ed25519` for modern servers!*

---

## 2. Generating & Managing SSH Keys

```bash
# Generate modern Ed25519 key pair with descriptive comment
ssh-keygen -t ed25519 -C "pramod@devops-laptop" -f ~/.ssh/id_ed25519

# Generate 4096-bit RSA key (if connecting to legacy enterprise systems)
ssh-keygen -t rsa -b 4096 -C "legacy-access"

# Copy public key to remote server automatically
ssh-copy-id -i ~/.ssh/id_ed25519.pub ubuntu@3.85.120.40

# Manually appending public key on the remote server
cat id_ed25519.pub >> ~/.ssh/authorized_keys
```

### Strict Permissions Requirement
The OpenSSH client and daemon enforce strict file permission checks:
```bash
# On local client machine:
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 600 ~/.ssh/config

# On remote server machine:
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

---

## 3. Productivity: Client Configuration (`~/.ssh/config`)

Instead of typing verbose commands like `ssh -i ~/.ssh/prod-key.pem -p 2222 ubuntu@ec2-54-12-34-56.compute-1.amazonaws.com`, create a client config profile in `~/.ssh/config`:

```text
# Bastion / Jump Host configuration
Host bastion
    HostName 34.200.10.15
    User ubuntu
    IdentityFile ~/.ssh/bastion_key.ed25519

# Private Production Database Server behind Bastion
Host prod-db
    HostName 10.0.2.45
    User postgres
    IdentityFile ~/.ssh/prod_internal.ed25519
    ProxyJump bastion

# Staging Kubernetes Master
Host staging-k8s
    HostName 198.51.100.22
    Port 2202
    User devops
    IdentityFile ~/.ssh/staging.ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

Now connect with a single command:
```bash
ssh prod-db
```
OpenSSH automatically establishes the tunnel through the Bastion host!

---

## 4. Hardening the OpenSSH Server Daemon (`/etc/ssh/sshd_config`)

To protect public-facing cloud servers (EC2, Droplets) against brute-force botnets, apply these production hardening rules:

```ini
# /etc/ssh/sshd_config or /etc/ssh/sshd_config.d/99-hardened.conf

# 1. Disable root password and direct root login
PermitRootLogin prohibit-password

# 2. Disable password authentication entirely (FORCE SSH KEY ONLY)
PasswordAuthentication no
ChallengeResponseAuthentication no

# 3. Disable empty passwords
PermitEmptyPasswords no

# 4. Limit idle session timeout (disconnect after 5 mins of inactivity)
ClientAliveInterval 300
ClientAliveCountMax 0

# 5. Disable legacy protocol and insecure ciphers
X11Forwarding no
MaxAuthTries 3
```

**Validate and reload daemon safely**:
```bash
# Test sshd syntax before restarting!
sudo sshd -t

# Reload sshd daemon
sudo systemctl reload sshd
```
*CRITICAL: Never close your current active SSH session before verifying you can open a second connection in another terminal window!*

---

## 5. SSH Tunneling & Port Forwarding

### Local Port Forwarding (`ssh -L`)
Access an internal database listening on private port 5432 from your local machine:
```bash
# Syntax: ssh -L <local_port>:<remote_target_ip>:<remote_target_port> user@bastion
ssh -L 5432:10.0.2.45:5432 ubuntu@bastion
```
Now connect your local database GUI (DBeaver/pgAdmin) to `localhost:5432`!

### Remote Port Forwarding (`ssh -R`)
Expose a local test web server (`localhost:3000`) through a public server for remote testing (like ngrok):
```bash
ssh -R 8080:localhost:3000 user@public-server.com
```

---

## 6. Interview & Review Questions
1. **How does SSH key authentication work without transmitting the private key over the wire?**
   - *Answer*: During authentication, the server encrypts a randomly generated challenge number using the client's public key (retrieved from `authorized_keys`). Only the holder of the matching private key can decrypt the challenge and return the cryptographic proof to the server. The private key never leaves the client machine.
2. **What does `Host * ProxyJump bastion` do in `~/.ssh/config`?**
   - *Answer*: It instructs the SSH client to automatically establish an end-to-end encrypted connection to the target server through an intermediate jump/bastion host, removing the need to store internal private keys on the bastion.
