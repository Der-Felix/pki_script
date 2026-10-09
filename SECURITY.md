# Security Policy

## 🔒 Security Best Practices

When managing an internal Public Key Infrastructure (PKI):

1. **Protect the Root CA Private Key**:
   - The Root CA private key (`pki/root/private/ca.key`) should ideally be kept **offline** or encrypted with a strong AES-256 passphrase.
   - Never issue leaf (end-entity) certificates directly from the Root CA in production; always use dedicated Intermediate CAs (e.g. `server-ca`, `client-ca`).

2. **File Permissions**:
   - `pki.sh` enforces `umask 077` by default, ensuring all private keys and directories are readable only by the issuing user.
   - Verify that your backup archives (`pki-backup-*.tar.gz`) are stored in restricted locations.

3. **Passphrase Protection**:
   - For unattended daemons (Nginx, Traefik, HAProxy), certificates should be unencrypted or have passphrases managed securely via systemd credential managers or secret stores.
   - For client and VPN certificates, export with PKCS#12 (`--p12`) and require a password upon import.

---

## 🛡️ Reporting a Vulnerability

If you discover a security vulnerability within this repository, please do **NOT** open a public issue.

Instead, please report it privately via GitHub Security Advisories or contact the maintainers directly.
Please include:
- A description of the vulnerability and its potential impact.
- Step-by-step instructions or proof-of-concept script to reproduce the issue.
- Your proposed fix or remediation (if available).

We will review and address the report promptly.
