#!/usr/bin/env python3
from datetime import datetime, timezone
import json, shutil, socket
usage = shutil.disk_usage("/")
report = {
    "timestamp_utc": datetime.now(timezone.utc).isoformat(),
    "hostname": socket.gethostname(),
    "root_disk_percent_used": round(usage.used / usage.total * 100, 2),
}
print(json.dumps(report, indent=2))
