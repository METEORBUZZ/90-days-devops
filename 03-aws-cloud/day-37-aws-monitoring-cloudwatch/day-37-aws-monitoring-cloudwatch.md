# Day 37: AWS Observability with Amazon CloudWatch (Metrics, Logs & Alarms)

## 1. Theoretical Foundation

### The Three Pillars of CloudWatch Observability
Amazon CloudWatch is the native monitoring and observability service for AWS resources and applications.
1. **Metrics**: Time-series numeric measurements (CPU, Network In/Out, Disk I/O, 4xx/5xx errors).
2. **Logs**: Centralized collection, filtering, and indexing of text and structured JSON logs.
3. **Alarms & Actions**: Threshold-based automated triggers that alert on-call engineers via SNS (email/SMS/PagerDuty) or trigger EC2 Auto Scaling.

```
[ EC2 / Containers / Lambda ]
         |
         | (CloudWatch Unified Agent: sends metrics & logs over HTTPS)
         v
+-------------------------------------------------------------------------+
|                           Amazon CloudWatch                             |
|                                                                         |
|  [ Metrics Engine ]          [ Logs Insights ]      [ Alarms Engine ]   |
|  (CPUUtilization,            (Queries /var/log/     (Triggers if CPU    |
|   DiskSpaceUtilization)       syslog & nginx.log)    > 80% for 5 mins)  |
+-------------------------------------------------------------------------+
                                                              |
                                                              v
                                                [ Amazon SNS / PagerDuty ]
```

---

## 2. Basic vs. Detailed EC2 Monitoring

- **Basic Monitoring (Default / Free)**:
  - Metric data points delivered every **5 minutes**.
- **Detailed Monitoring (Paid)**:
  - Metric data points delivered every **1 minute**.
  - Essential for fast Auto Scaling Group scaling policies during sudden traffic spikes.

### The Missing Metrics in Standard CloudWatch
By default, the AWS hypervisor can only see virtual hardware metrics:
- CPU Utilization (`CPUUtilization`)
- Network In/Out bytes
- EBS Read/Write ops
- Status checks

**What standard CloudWatch CANNOT see**:
- **Operating System Memory Usage** (RAM % used).
- **Disk Free Space inside the OS** (`df -h`).
- **Running processes and swap memory**.
- **Why?** Because the hypervisor does not have access inside the guest OS memory space!
- **Solution**: Install the **Unified CloudWatch Agent (`amazon-cloudwatch-agent`)** inside the EC2 instance or container!

---

## 3. Configuring the Unified CloudWatch Agent

Create `/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json`:

```json
{
  "metrics": {
    "metrics_collected": {
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "/"
        ]
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "/aws/ec2/prod/nginx-errors",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 14
          }
        ]
      }
    }
  }
}
```

---

## 4. Metric Filters & CloudWatch Alarms

### Metric Filter (Extracting Metrics from Plain Text Logs)
Count how many HTTP 500 errors occur inside `/var/log/nginx/access.log`:
- Filter Pattern: `[host, ident, auth, timestamp, request, status_code = 5*, size]`
- Metric Name: `Nginx5xxErrors`
- Metric Value: `1`

### Creating an Alarm via AWS CLI
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "HighCPUUtilization-ProdWeb" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80.0 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=InstanceId,Value=i-0123456789abcdef0 \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:us-east-1:123456789012:devops-oncall-alerts \
  --unit Percent
```

---

## 5. Log Analysis with CloudWatch Logs Insights

Logs Insights queries terabytes of logs in seconds using a dedicated SQL-like syntax:

```text
fields @timestamp, @message
| filter @message like /ERROR/ or @message like /FATAL/
| parse @message "* [*] *" as date, level, log_msg
| stats count(*) by level
| sort @timestamp desc
| limit 50
```

---

## 6. Interview & Review Questions
1. **Can CloudWatch monitor memory (RAM) usage on an EC2 instance out of the box? Why or why not?**
   - *Answer*: No. Standard CloudWatch metrics are collected externally by the AWS physical hypervisor, which cannot inspect the guest operating system's internal kernel memory allocations. To capture RAM utilization, you must install and configure the AWS Unified CloudWatch Agent inside the OS with appropriate IAM permissions.
2. **What are the three states of a CloudWatch Alarm?**
   - *Answer*:
     - `OK`: The metric is within the defined target threshold.
     - `ALARM`: The metric has breached the threshold for the specified number of evaluation periods.
     - `INSUFFICIENT_DATA`: The alarm has just started, the metric is not available, or not enough data has arrived to determine status.
