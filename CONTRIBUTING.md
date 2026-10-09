# Contributing to OpenSSL Homelab PKI Suite

Thank you for your interest in contributing! This project aims to provide a reliable, modular, and easy-to-use PKI manager for homelabs and enterprise environments.

---

## 🛠️ Development Guidelines

1. **Bash Portability**:
   - The code requires Bash 4.x or 5.x. Avoid non-standard bashisms or external dependencies outside standard coreutils (`awk`, `sed`, `date`, `tar`, `tr`).
   - Use strict error handling (`set -o errexit -o pipefail -o errtrace`) and safe umask (`umask 077`).

2. **OpenSSL 3.x Support**:
   - OpenSSL 3.0+ is the primary target. Avoid deprecated parameters or flags removed in modern OpenSSL releases.

3. **Line Endings**:
   - All shell scripts (`.sh`), bash completion files (`.bash`), and configuration files (`.conf`) must use **Unix LF** line endings.

4. **Modular Architecture**:
   - Place new functionality in the appropriate `lib/*.sh` module rather than bloating the main entrypoint.
   - Run `./build.sh` after updating library files to verify that the standalone bundle builds cleanly.

5. **Security First**:
   - Never commit private keys, passphrases, or real certificates into Git.
   - Always ensure private keys are generated with `chmod 600` or `umask 077`.

---

## 🧪 Testing Your Changes

Before submitting a Pull Request, run the pre-flight checks:

```bash
# 1. Run environment diagnostics
./pki.sh doctor

# 2. Test presets display
./pki.sh presets

# 3. Test compilation of standalone build
./build.sh

# 4. Test issuing in an isolated directory
./pki.sh --dir /tmp/test-pki init --org "Test" --intermediate server-ca --no-pass
./pki.sh --dir /tmp/test-pki batch examples/webserver.conf
./pki.sh --dir /tmp/test-pki verify web01
rm -rf /tmp/test-pki
```

---

## 🚀 Submitting a Pull Request

1. Fork the repository and create your feature branch:
   ```bash
   git checkout -b feature/my-new-feature
   ```
2. Commit your changes with clear, descriptive commit messages.
3. Push to your branch and open a Pull Request against `main`.
