# Lab Safety & Security

- Use a disposable VM, local container, or explicitly approved training account.
- Before AWS changes, confirm account, region, scope, and expected cost.
- Budget alerts do not necessarily stop charges; inspect and clean up resources.
- Never commit passwords, access keys, tokens, private keys, `.env` files, Terraform state, or sensitive logs.
- Avoid `chmod 777` as a general fix and avoid broad SSH/RDP ingress.
- Review Terraform plans before applying; never destroy shared or production resources.
- Test destructive scripts on mock data and include a dry-run mode.
- Redact sensitive information from screenshots and logs.
