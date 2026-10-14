# Day 74 — AWS CloudWatch Logs & Alarms

**Phase:** Phase 6 — Monitoring, security & reliability  
**Estimated time:** 65–80 minutes  
**Status:** Not started

## Learning objectives
Understand the core concepts, use the tools safely, perform the lab, troubleshoot a failure, and explain your decisions as a DevOps engineer.

## Part A — Theory (30 minutes)
Log groups/streams, metric filters, alarm actions, retention

### Tools to explore
`CloudWatch Console`

### Explain in your own words
- What does each concept mean?
- Where is it used in a real engineering workflow?
- What can go wrong?
- How do you verify success?

## Part B — Hands-on practice (20–30 minutes)
**Practical task:** Design log retention and alarms for a sample workload.

1. Use a disposable local lab or approved cloud environment.
2. Record the initial state.
3. Perform the task in small steps.
4. Verify expected vs actual results.
5. Record one error and how you diagnosed it.
6. Clean up temporary resources.

## Part C — Three scenario-based questions
Answer with: initial checks, tools/commands, likely causes, safe remediation, verification, and prevention.

1. A teammate reports a problem related to aws cloudwatch logs & alarms. What do you inspect first, and how do you verify the cause?
2. A change involving aws cloudwatch logs & alarms works in your lab but fails in a shared environment. What evidence and checks would you collect before changing anything?
3. You must automate a repetitive aws cloudwatch logs & alarms task safely. How would you handle errors, least privilege, logging, and validation?

## Part D — Four interview questions
1. What is aws cloudwatch logs & alarms, and why is it useful in DevOps?
2. Explain the main components or workflow involved in aws cloudwatch logs & alarms.
3. What are common failure modes in aws cloudwatch logs & alarms, and how would you troubleshoot them?
4. What security or production-safety considerations matter for aws cloudwatch logs & alarms?

## Part E — Four MCQs
Choose the best answer and explain why.

1. Which approach is safest when troubleshooting aws cloudwatch logs & alarms?
   - A. Make the broadest possible change immediately
   - B. Gather evidence and isolate the cause
   - C. Ignore logs
   - D. Reboot without checking
2. What should you verify before applying a change related to aws cloudwatch logs & alarms?
   - A. Account, scope, impact, and rollback
   - B. Nothing; apply immediately
   - C. Only the command syntax
   - D. Whether the change is quick
3. Which practice improves repeatability for aws cloudwatch logs & alarms?
   - A. Manual undocumented steps only
   - B. Shared passwords
   - C. Versioned scripts/configuration and repeatable checks
   - D. Skipping tests
4. What should an automation script do when a required check fails?
   - A. Report success regardless
   - B. Hide all errors
   - C. Continue destructive steps
   - D. Fail clearly, log safely, and return a meaningful status

## Part F — Practical/coding challenge
Design log retention and alarms for a sample workload.

Write your own script, configuration, diagram, or runbook that completes this task. For cloud and infrastructure labs, review permissions, cost, and planned changes before applying anything.

## Part G — Reflection and completion
- [ ] Theory reviewed
- [ ] Lab completed and verified
- [ ] Evidence saved with secrets removed
- [ ] Three scenarios attempted
- [ ] Four interview questions answered
- [ ] Four MCQs attempted
- [ ] Reflection recorded
- [ ] `PROGRESS.md` updated

Reflection:
- What did I learn?
- What error did I troubleshoot?
- What would I do differently in production?
- What should I review tomorrow?
