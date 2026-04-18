# Ansible Playbook for Windows Server 2025 Runner Image

This directory contains the Ansible playbook and roles for building a
Windows Server 2025 GitHub Actions runner / Azure DevOps agent image.
It mirrors the design of the Ubuntu 24.04 playbook (`ansible/ubuntu2404/`)
while orchestrating the existing PowerShell build scripts from
`images/windows/scripts/build/`.

## Prerequisites

| Requirement | Minimum Version |
| ----------- | --------------- |
| Ansible | 2.14+ |
| Python | 3.9+ |
| `pywinrm` Python package | 0.4.0+ |
| Target OS | Windows Server 2025 Datacenter |
| Target RAM | 16 GB (8 GB minimum) |
| Target Disk | 150 GB+ |
| Target CPUs | 4+ cores |
| WinRM | Configured for HTTPS (port 5986) |

### Controller Setup

```bash
pip install pywinrm
ansible-galaxy collection install -r requirements.yml
```

### Target VM WinRM Setup

On the target Windows Server 2025 VM, run in an elevated PowerShell:

```powershell
# Enable WinRM with HTTPS listener
winrm quickconfig -force
winrm set winrm/config/service '@{AllowUnencrypted="false"}'
winrm set winrm/config/service/auth '@{CredSSP="true"}'

# Create self-signed certificate for HTTPS
$cert = New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation Cert:\LocalMachine\My
winrm create winrm/config/Listener?Address=*+Transport=HTTPS "@{Hostname=`"$env:COMPUTERNAME`";CertificateThumbprint=`"$($cert.Thumbprint)`"}"

# Open firewall
New-NetFirewallRule -Name "WinRM-HTTPS" -DisplayName "WinRM HTTPS" -Protocol TCP -LocalPort 5986 -Action Allow
```

The sample inventories use `ansible_winrm_transport: ntlm`, so WinRM Basic
authentication is not required. Leave it disabled unless you intentionally
switch your inventory or controller settings to use Basic over HTTPS. If you
need the playbook to enable it on the target, set `enable_winrm_basic_auth` to
`true`.

## Quick Start

1. **Configure inventory** – edit `inventories/production/hosts.yml`
   with the target VM IP, username, and password.

2. **Verify connectivity**:

   ```bash
   ansible windows2025_builders -m ansible.windows.win_ping
   ```

3. **Syntax check**:

   ```bash
   ansible-playbook playbooks/windows2025.yml --syntax-check
   ```

4. **Run the playbook**:

   ```bash
   ansible-playbook playbooks/windows2025.yml
   ```

## Role Execution Order

| # | Role | Description | Elevated | Reboot | Est. Time |
| --- | ------ | ------------- | -------- | ------ | --------- |
| 1 | `windows_base` | Directory setup, script copy, build user | No | No | 5 min |
| 2 | `windows_config` | Defender, PowerShell, WSL, Features, Chocolatey | No | Yes | 15 min |
| 3 | `docker` | Docker Engine, Compose, PowerShell Core | No | Yes (30m timeout) | 20 min |
| 4 | `visual_studio` | VS 2022 Enterprise, Kubernetes tools | Yes | Yes | 90-120 min |
| 5 | `development_tools` | 50+ tools: languages, databases, browsers | Mixed | Yes | 60-90 min |
| 6 | `system_updates` | PostgreSQL, Windows Updates, LLVM | Yes | Yes (30m timeout) | 30-60 min |
| 7 | `validation` | Tests, software report, artifact collection | No | No | 15 min |
| 8 | `finalization` | System config, sysprep (optional) | No | Yes | 10 min |

Total estimated build time: 4-6 hours.

## Tag-Based Execution

Run a specific role:

```bash
ansible-playbook playbooks/windows2025.yml --tags "docker"
```

Skip a role:

```bash
ansible-playbook playbooks/windows2025.yml --skip-tags "visual_studio"
```

Available tags: `windows_base`, `windows_config`, `docker`, `visual_studio`,
`development_tools`, `system_updates`, `validation`, `finalization`.

## Azure Pipelines Agent Deployment

The `azure_pipelines_agent` role deploys Azure DevOps agents as Windows
services. It is not part of the main image build playbook but can be run
separately against hosts in the `windows2025_agents` group.

### Setup

1. Encrypt credentials:

   ```bash
   ansible-vault encrypt inventories/production/group_vars/windows2025_agents/vault.yml
   ```

2. Run agent deployment:

   ```bash
   ansible-playbook playbooks/windows2025.yml --limit windows2025_agents --tags azure_pipelines_agent --ask-vault-pass
   ```

## Build Artifacts

After a successful build, the following files are created in `playbooks/outputs/`:

| File | Description |
| ------ | ------------- |
| `Windows2025-Readme.md` | Software report (Markdown) |
| `software-report.json` | Software report (JSON) |
| `testResults.xml` | Pester test results |

## Troubleshooting

### WinRM Connection Failures

- Verify WinRM is listening: `winrm enumerate winrm/config/Listener`
- Check firewall rules: `Get-NetFirewallRule -Name "WinRM*"`
- Test from controller: `ansible windows2025_builders -m ansible.windows.win_ping -vvv`

### Elevated Execution Failures

- The `install_user` must exist and be in the Administrators group
- Set `vault_install_password` in vault-encrypted files
- Some scripts require `become_method: runas` (handled automatically by roles)

### Reboot Timeouts

- Windows Updates can take 30+ minutes — the playbook uses appropriate timeouts
- Check `C:\Windows\Logs\CBS\CBS.log` for Windows Update issues
- If a reboot hangs, increase `reboot_timeout` in the relevant role

### Script Execution Errors

- Build scripts are sourced from `images/windows/scripts/build/` and copied to the target
- The Windows 2025 toolset is sourced from `ansible/windows2025/toolsets/toolset-2025.json`
  and copied to `{{ image_folder }}\toolset.json`
- Ensure the repository root is accessible from the Ansible controller
- Check `{{ image_folder }}\build\` on the target for script presence
