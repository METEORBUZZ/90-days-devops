# Day 11: Linux Networking Fundamentals for DevOps

## 1. Theoretical Foundation

### The TCP/IP & OSI Model in Cloud Infrastructure
```
OSI Layer           TCP/IP Layer    DevOps Protocol / Examples
----------------------------------------------------------------------
7. Application   \  Application     HTTP/HTTPS, gRPC, DNS, SSH, TLS
6. Presentation   |
5. Session       /
4. Transport        Transport       TCP (Reliable, Handshake), UDP (Fast, DNS/VoIP)
3. Network          Internet        IPv4, IPv6, ICMP (ping), Routing
2. Data Link     \  Network Access  Ethernet, MAC Address, ARP, Linux Bridge
1. Physical      /                  Physical cables, Fiber, Wi-Fi
```

### TCP Three-Way Handshake & Teardown
```
Client                              Server
  |                                   |
  | ------------ SYN ---------------> |  (Client initiates connection)
  | <--------- SYN-ACK -------------- |  (Server acknowledges & syncs)
  | ------------ ACK ---------------> |  (Client acknowledges - ESTABLISHED)
  |                                   |
  | === Full-Duplex Data Transfer === |
  |                                   |
  | ------------ FIN ---------------> |  (Client initiates teardown)
  | <----------- ACK ---------------- |
  | <----------- FIN ---------------- |  (Server agrees to close)
  | ------------ ACK ---------------> |  (Client enters TIME_WAIT)
```
- **TIME_WAIT**: Socket remains open for 2x Maximum Segment Lifetime (MSL) (~60s) to guarantee final ACK was received. High `TIME_WAIT` sockets can exhaust ephemeral ports on busy reverse proxies (Nginx/HAProxy)!

### IP Addresses, CIDR & Subnetting
- **IPv4**: 32-bit address represented in dotted decimal (`192.168.1.1`).
- **CIDR (Classless Inter-Domain Routing)**: Indicates subnet mask length.
  - `/32`: Exactly 1 IP address (`10.0.0.1/32` - single host).
  - `/24`: 256 addresses ($2^{32-24} = 2^8 = 256$, with 254 usable for hosts).
  - `/16`: 65,536 addresses (standard for AWS VPCs).
- **Private RFC 1918 Ranges**:
  - `10.0.0.0/8` (`10.0.0.0` - `10.255.255.255`)
  - `172.16.0.0/12` (`172.16.0.0` - `172.31.255.255` - Docker default bridge)
  - `192.168.0.0/16` (`192.168.0.0` - `192.168.255.255`)

---

## 2. Linux Network Diagnostic Commands

### Socket & Port Inspection: `ss` (Modern `netstat` Replacement)
`ss` (Socket Statistics) reads socket information directly from the kernel `netlink` interface, making it orders of magnitude faster than legacy `netstat`.

```bash
# List all TCP listening sockets with PID and process name
# -t (TCP) -u (UDP) -l (Listening) -p (Process/PID) -n (Numeric ports/no DNS lookup)
sudo ss -tulpn

# Filter for specific port (e.g. port 80 or 443)
sudo ss -tulpn | grep -E "(:80|:443)"

# View all ESTABLISHED outbound TCP connections
ss -t -state established

# Count connections per state (detect connection leaks)
ss -s
```

### IP Configuration & Routing: `ip` (Modern `ifconfig` / `route` Replacement)
```bash
# View all network interfaces and assigned IP addresses
ip addr show
ip -br addr show             # Brief tabular view

# View the kernel routing table and default gateway
ip route show

# View ARP cache (IP-to-MAC address mapping)
ip neigh show
```

### DNS Diagnostics: `dig` and `nslookup`
In modern Linux, `/etc/resolv.conf` directs queries to local stub resolvers (like `systemd-resolved` on `127.0.0.53:53`).
```bash
# Standard DNS A-record query
dig api.github.com

# Short answer only (IP address)
dig +short api.github.com

# Query specific nameserver directly (e.g. Google Public DNS 8.8.8.8)
dig @8.8.8.8 api.github.com

# Trace complete DNS resolution from root servers down
dig +trace api.github.com

# Reverse DNS lookup (IP to domain)
dig -x 8.8.8.8 +short
```

### Testing Connectivity: `curl`, `nc` (Netcat), and `traceroute`
```bash
# Test HTTP status and headers without downloading body
curl -Iv https://example.com

# Measure HTTP response timing breakdown (DNS, TCP Handshake, TLS, TTFB)
curl -w "DNS: %{time_namelookup}s | Connect: %{time_connect}s | TLS: %{time_appconnect}s | TTFB: %{time_starttransfer}s | Total: %{time_total}s\n" -o /dev/null -s https://example.com

# Test raw TCP port reachability through firewalls
nc -zv 10.0.1.50 3306         # Test if MySQL port 3306 is open
nc -zvw 3 10.0.1.50 443       # With 3-second timeout

# Inspect network hops and packet drops
traceroute 8.8.8.8
mtr 8.8.8.8                  # Interactive real-time trace
```

---

## 3. DevOps Production Scenarios

### 1. "Connection Refused" vs. "Connection Timed Out"
This is one of the most common production issues in cloud infrastructure:
- **`Connection Refused`**:
  - The packet successfully reached the destination IP.
  - The destination host actively responded with a TCP **RST (Reset)** packet.
  - **Cause**: No service is actively listening on that port, or the service bound only to `127.0.0.1` (localhost) instead of `0.0.0.0` (all interfaces).
- **`Connection Timed Out`**:
  - The client sent TCP SYN packets but received zero response until timeout.
  - **Cause**: A network firewall, AWS Security Group, or iptables rule silently dropped the packets.

### 2. Service Bound to `127.0.0.1` vs. `0.0.0.0`
- `127.0.0.1` (Loopback): The process can **only** be accessed from within the same host/container. External requests cannot reach it!
- `0.0.0.0` (INADDR_ANY): The process listens on all network interfaces (public, private, docker bridges).

---

## 4. Interview & Review Questions
1. **A microservice running inside a Docker container cannot be reached from other VMs. `curl http://vm-ip:8080` gives "Connection Refused". What is your step-by-step diagnostic process?**
   - *Answer*:
     1. Verify port publishing on the container (`docker ps` - check host port mapping `0.0.0.0:8080->8080/tcp`).
     2. On the host, run `sudo ss -tulpn | grep 8080` to see if docker-proxy is listening.
     3. Check if the application inside the container is bound to `0.0.0.0:8080` or mistakenly to `localhost:8080`.
     4. Check host firewall rules (`sudo ufw status` or `iptables -L`).
2. **What does `curl -I` and TTFB (Time To First Byte) indicate when diagnosing web application latency?**
   - *Answer*: `curl -I` fetches HTTP response headers without the payload. TTFB measures the duration from the client sending the HTTP request until receiving the first byte of response data from the server. A high TTFB indicates application-layer bottlenecks (slow database queries, backend computation, or upstream proxy stalls), whereas high connect time points to network or TLS handshake latency.
