# Day 54: Deployment Automation, Smoke Testing & Automated Rollbacks

## 1. Theoretical Foundation

### The Golden Rule of Continuous Delivery:
**"If a deployment cannot be rolled back automatically within 60 seconds, it is not production-ready."**

Deploying new software to production is only half the battle. A production deployment system must include:
1. **Health Probing**: Post-deployment HTTP smoke tests that verify the application responds correctly.
2. **Failure Detection**: Automated evaluation of application status and telemetry.
3. **Automated Rollback Trigger**: An automated fallback mechanism that restores the previous known-good release if smoke tests fail.

---

## 2. Anatomy of a Post-Deployment Smoke Test Script

Create `smoke_test.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

TARGET_URL="${1:-http://localhost:8080/health}"
MAX_ATTEMPTS=12
SLEEP_INTERVAL=5

echo "Starting post-deployment smoke tests against: ${TARGET_URL}"

for ((i=1; i<=MAX_ATTEMPTS; i++)); do
    echo "Attempt ${i}/${MAX_ATTEMPTS}: Probing endpoint..."
    
    # Query HTTP status code and response body with 3-second timeout
    HTTP_CODE=$(curl -s -o /tmp/smoke_response.json -w "%{http_code}" --max-time 3 "${TARGET_URL}" || echo "000")
    
    if [[ "$HTTP_CODE" -eq 200 ]]; then
        echo "SUCCESS: Endpoint responded with HTTP 200 OK."
        # Verify JSON payload content
        STATUS=$(jq -r '.status // empty' /tmp/smoke_response.json 2>/dev/null || echo "UNKNOWN")
        if [[ "$STATUS" == "HEALTHY" || "$STATUS" == "UP" ]]; then
            echo "Smoke test PASSED: Application is healthy."
            exit 0
        fi
    fi
    
    echo "Warning: Received HTTP ${HTTP_CODE}. Retrying in ${SLEEP_INTERVAL}s..."
    sleep "$SLEEP_INTERVAL"
done

echo "CRITICAL: Smoke test FAILED after $((MAX_ATTEMPTS * SLEEP_INTERVAL)) seconds!" >&2
exit 1
```

---

## 3. GitHub Actions Automated Deployment & Rollback Workflow

```yaml
name: Deploy & Validate

on:
  push:
    branches: [main]

jobs:
  deploy-production:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Record Current Known-Good Release
        id: prev_version
        run: |
          PREV_TAG=$(curl -s https://api.mycompany.internal/version | jq -r .version)
          echo "PREV_TAG=${PREV_TAG}" >> $GITHUB_OUTPUT

      - name: Deploy New Release
        run: |
          echo "Deploying release ${{ github.sha }} to production cluster..."
          kubectl set image deployment/web-api web-api=my-ecr-repo:${{ github.sha }} -n prod
          kubectl rollout status deployment/web-api -n prod --timeout=60s

      - name: Execute Automated Smoke Tests
        id: smoke_tests
        run: |
          chmod +x ./scripts/smoke_test.sh
          ./scripts/smoke_test.sh https://api.mycompany.internal/health

      - name: Automated Rollback on Smoke Test Failure
        if: failure() && steps.smoke_tests.outcome == 'failure'
        run: |
          echo "🚨 CRITICAL: Smoke tests failed! Initiating automated rollback..."
          kubectl rollout undo deployment/web-api -n prod
          echo "Rollback initiated. Restored previous stable replica state."
          # Send emergency notification to Slack
          curl -X POST -H 'Content-type: application/json' \
            --data '{"text":"🚨 *CRITICAL*: Production deployment failed smoke tests! Automated rollback executed."}' \
            ${{ secrets.SLACK_WEBHOOK_URL }}
```

---

## 4. Database Migrations & Rollback Traps

The hardest part of deployment rollbacks is **Database Schema Changes**:
- If version 2.0 deletes a database column, and version 2.0 crashes and rolls back to version 1.0, version 1.0 will immediately crash because the column is gone!

### The Expand / Contract Pattern (Two-Phase Migration)
1. **Expand Phase (Release N)**: Add the new column/table, but keep the old column intact. Deploy code that writes to both columns.
2. **Contract Phase (Release N+1)**: Once the new version is 100% stable, safely deprecate and drop the old unused column in a subsequent release.
*Never perform breaking database schema changes in the same deployment as application code updates!*

---

## 5. Interview & Review Questions
1. **What is the "Expand / Contract" pattern and why is it critical for continuous zero-downtime deployments?**
   - *Answer*: It decouples database schema changes from application code changes. By ensuring the database schema remains backward-compatible with the previous software version, the system can be rolled back safely at any moment without crashing legacy application replicas.
2. **What should an automated deployment pipeline do immediately if post-deployment smoke tests fail?**
   - *Answer*: It should automatically halt the rollout, trigger an immediate rollback to the previous known-good release artifact, alert the on-call engineering team via Slack/PagerDuty, and log diagnostic output for post-incident root-cause analysis.
