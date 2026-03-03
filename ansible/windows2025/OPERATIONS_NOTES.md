# Operations Notes – Windows Server 2025 Ansible Playbook

This document records operational findings, known issues, and workarounds
discovered during development and production use of the Windows 2025 playbook.

## WinRM Configuration

### Required Transport Settings

- **Transport**: NTLM (default), switch to CredSSP if double-hop authentication
  is needed (e.g., accessing network shares during builds).
- **Port**: 5986 (HTTPS). Certificate validation is disabled by default in
  inventory files (`ansible_winrm_server_cert_validation: ignore`).
- **For production**: Configure proper TLS certificates and set
  `ansible_winrm_server_cert_validation: validate`.

### CredSSP Setup (if needed)

On the target VM:

```powershell
Enable-WSManCredSSP -Role Server -Force
```

On the controller:

```bash
pip install pywinrm[credssp]
```

In inventory:

```yaml
ansible_winrm_transport: credssp
```

## Elevated Execution

- Scripts that modify system settings (Visual Studio, Windows Updates, PostgreSQL)
  require elevated execution via `become: true` + `become_method: runas`.
- The build user (`install_user`) is created by the `windows_base` role and must
  have a password set via `vault_install_password`.
- If the build user password expires, re-run `windows_base` to reset it.

## Restart Sequencing

The playbook includes 6 strategic reboots matching the Packer build sequence:

1. After Windows Features (Containers, WSL) — wait for feature activation
2. After Docker installation — 30-minute timeout for service initialization
3. After Visual Studio — registry updates require reboot
4. After Service Fabric SDK — kernel-level changes
5. After Windows Updates — TiWorker process completion check
6. Before Sysprep — clean state for generalization

**Do not skip reboots** — many scripts depend on registry changes and service
registrations that only take effect after restart.

## Known Issues

(Add findings as they are discovered during testing)
