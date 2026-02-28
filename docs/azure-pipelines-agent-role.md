# Azure Pipelines Agent – Ansible Role

Automatically deploy, configure, and update self-hosted Azure Pipelines agents on
Ubuntu 24.04 hosts using the `azure_pipelines_agent` Ansible role.

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Architecture](#architecture)
- [Role Variables](#role-variables)
- [Inventory Configuration](#inventory-configuration)
- [Runtime Secret Injection](#runtime-secret-injection)
- [Usage](#usage)
  - [Full Deployment](#full-deployment)
  - [Agent-Only Deployment](#agent-only-deployment)
  - [Pin a Specific Version](#pin-a-specific-version)
  - [Force Reinstall (Same Version)](#force-reinstall-same-version)
  - [Dry Run (Check Mode)](#dry-run-check-mode)
  - [Update Agents to the Latest Version](#update-agents-to-the-latest-version)
- [Multi-Instance Configuration](#multi-instance-configuration)
- [How It Works](#how-it-works)
- [Tags](#tags)
- [Handlers](#handlers)
- [Troubleshooting](#troubleshooting)
- [Design Decisions](#design-decisions)

---

## Overview

The `azure_pipelines_agent` role performs the following:

1. **Version resolution** – Queries the [microsoft/azure-pipelines-agent](https://github.com/microsoft/azure-pipelines-agent) GitHub Releases API to find the latest (or a pinned) version, optionally including pre-release builds.
2. **Download with integrity check** – Downloads the agent tarball from `download.agent.dev.azure.com` and verifies its SHA-256 checksum against the `assets.json` published in the GitHub release.
3. **Per-instance configuration** – Deploys one or more agent instances on each host, each with its own directory, systemd service, and (optionally) a different agent pool.
4. **Service Principal authentication** – Registers agents using Azure AD Service Principal credentials (`--auth sp`).
5. **Idempotent updates** – On subsequent runs the role compares the installed version (read from the `.agent` JSON file) against the resolved target; only instances that differ are stopped, unconfigured, re-extracted, and re-configured.

Use the dedicated playbook `ansible/ubuntu2404/playbooks/azure_pipelines_agents.yml` to deploy agents to the `ubuntu2404_agents` host group.

---

## Prerequisites

| Requirement | Details |
|---|---|
| **Ansible** | >= 2.15 |
| **Collections** | `ansible.posix >= 1.5.0`, `community.general >= 8.0.0` (see `requirements.yml`) |
| **Target OS** | Ubuntu 24.04 (other Linux distributions may work but are untested) |
| **Network access** | Outbound HTTPS to `api.github.com`, `github.com`, and `download.agent.dev.azure.com` |
| **Azure DevOps** | An organisation URL (e.g. `https://dev.azure.com/myorg`) with at least one agent pool |
| **Service Principal** | An Azure AD App Registration with the _Agent Pools (Read & manage)_ scope granted in the target Azure DevOps organisation |
| **SSH access** | The Ansible control node must be able to SSH into target hosts with `become` (sudo) privileges |

> [!TIP]
> To avoid GitHub API rate-limiting (60 requests/hour for unauthenticated calls), set a `GITHUB_TOKEN` or `GH_TOKEN` environment variable on the control node, or pass `azp_github_token` in your inventory.

---

## Architecture

```
ansible/ubuntu2404/roles/azure_pipelines_agent/
├── defaults/
│   └── main.yml                  # Default variables
├── handlers/
│   └── main.yml                  # restart / stop handlers
└── tasks/
    ├── main.yml                  # Entry point – validation, orchestration
    ├── resolve_version.yml       # GitHub Releases API version resolution
    ├── download.yml              # Tarball download with SHA-256 verification
    └── configure_instance.yml    # Per-instance install / update / service
```

### Workflow

```
main.yml
  ├─ assert required variables
  ├─ include: resolve_version.yml
  │    ├─ detect host architecture (x86_64 → x64, aarch64 → arm64)
  │    ├─ build GitHub API headers (optional Bearer token)
  │    └─ fetch releases → filter by prerelease flag → extract version
  ├─ include: download.yml
  │    ├─ compute tarball name & download URL
  │    ├─ fetch assets.json → extract SHA-256
  │    └─ download tarball (with or without checksum)
  └─ loop over azp_agent_instances:
       └─ include: configure_instance.yml
            ├─ read .agent JSON → compare versions
            ├─ (if update) stop → uninstall → unconfigure existing agent
            ├─ create system user & instance directory
            ├─ extract tarball
            ├─ config.sh --unattended (SP auth, no_log: true)
            ├─ svc.sh install / start
            ├─ write version marker
            └─ verify service status
```

---

## Role Variables

All variables are defined in `ansible/ubuntu2404/roles/azure_pipelines_agent/defaults/main.yml`.

### Required Variables

These must be provided at runtime using `-e`, `-e @file`, or environment variables (`AZP_URL`, `AZP_CLIENT_ID`, `AZP_TENANT_ID`, `AZP_CLIENT_SECRET`):

| Variable | Description | Example |
|---|---|---|
| `azp_url` | Azure DevOps organisation URL | `https://dev.azure.com/myorg` |
| `azp_client_id` | Azure AD Application (client) ID | `00000000-0000-0000-0000-000000000000` |
| `azp_tenant_id` | Azure AD Directory (tenant) ID | `00000000-0000-0000-0000-000000000000` |
| `azp_client_secret` | Service Principal client secret | _(runtime-injected secret)_ |

### Optional Variables

| Variable | Default | Description |
|---|---|---|
| `azp_auth_type` | `sp` | Authentication type. Currently only `sp` (Service Principal) is implemented. |
| `azp_pool` | `Default` | Default agent pool. Can be overridden per-instance. |
| `azp_agent_base_dir` | `/opt/azure-pipelines-agent` | Base directory under which instance directories are created. |
| `azp_agent_user` | `azpagent` | System user that owns the agent files and runs the service. Automatically created if absent. |
| `azp_agent_work_dir` | `_work` | Working directory name (relative to instance directory). |
| `azp_replace_existing` | `true` | Pass `--replace` to `config.sh` to overwrite a previously registered agent with the same name. |
| `azp_agent_instances` | `[{name: "agent-1"}]` | List of agent instances to deploy. See [Multi-Instance Configuration](#multi-instance-configuration). |
| `azp_agent_version` | `latest` | Set to `latest` for auto-resolution or a specific version string (e.g. `4.269.0`) to pin. |
| `azp_include_prerelease` | `true` | When `azp_agent_version` is `latest`, include pre-release versions in resolution. |
| `azp_force_reinstall` | `false` | Force reinstall/update flow even when installed and target versions are the same. |
| `azp_github_token` | `""` | GitHub Personal Access Token for API calls. Falls back to `GITHUB_TOKEN` / `GH_TOKEN` environment variables. |

---

## Inventory Configuration

### Production inventory

The role expects hosts in the `ubuntu2404_agents` group. Edit `ansible/ubuntu2404/inventories/production/hosts.yml`:

```yaml
all:
  children:
    ubuntu:
      children:
        ubuntu2404_agents:
          hosts:
            agent-vm-01:
              ansible_host: 10.0.2.10
              ansible_user: ansible
              ansible_ssh_private_key_file: ~/.ssh/id_rsa
              ansible_become_method: sudo
              azp_agent_instances:
                - { name: "agent-01" }
                - { name: "agent-02" }
            agent-vm-02:
              ansible_host: 10.0.2.11
              ansible_user: ansible
              azp_agent_instances:
                - { name: "agent-03", pool: "GPU-Pool" }
```

### Staging inventory

A staging inventory with the same structure is available at `ansible/ubuntu2404/inventories/staging/hosts.yml`. Use it for testing before rolling out to production.

---

## Runtime Secret Injection

Sensitive credentials are expected at execution time.
The dedicated playbook reads values from either runtime `-e` variables or these environment variables:

- `AZP_URL`
- `AZP_CLIENT_ID`
- `AZP_TENANT_ID`
- `AZP_CLIENT_SECRET`

### Option A: Environment variables (recommended)

```bash
export AZP_URL="https://dev.azure.com/myorg"
export AZP_CLIENT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export AZP_TENANT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export AZP_CLIENT_SECRET="your-secret-value"
```

### Option B: Ephemeral runtime vars file

```bash
cat > /tmp/azp-runtime-vars.yml <<'YAML'
azp_url: "https://dev.azure.com/myorg"
azp_client_id: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
azp_tenant_id: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
azp_client_secret: "your-secret-value"
YAML
```

Use `-e @/tmp/azp-runtime-vars.yml` when running the playbook, then delete the file immediately after deployment.

> [!WARNING]
> Do not commit secrets to inventory or `group_vars`. Inject them only at runtime.

---

## Usage

All commands are run from the repository root. Adjust the inventory path (`-i`) as needed.

### Full Deployment

Run the dedicated agent deployment playbook:

```bash
ansible-playbook \
  -i ansible/ubuntu2404/inventories/production/hosts.yml \
  ansible/ubuntu2404/playbooks/azure_pipelines_agents.yml
```

### Agent-Only Deployment

Use tags to run only the agent role:

> [!IMPORTANT]
> The `agent` tag is applied to the `azure_pipelines_agent` role **only** in the dedicated playbook
> `ansible/ubuntu2404/playbooks/azure_pipelines_agents.yml`.
>
> The image build playbook `ansible/ubuntu2404/playbooks/ubuntu2404.yml` does **not** include the
> `azure_pipelines_agent` role, so running `ubuntu2404.yml --tags agent` will **not** install the
> Azure Pipelines agent. You may still see some tasks run due to Ansible's special `always` tag
> (e.g., the `system_base` role has `tags: ['always', ...]`).

```bash
ansible-playbook \
  -i ansible/ubuntu2404/inventories/production/hosts.yml \
  ansible/ubuntu2404/playbooks/azure_pipelines_agents.yml \
  --tags agent
```

### Pin a Specific Version

Override the version at runtime:

```bash
ansible-playbook \
  -i ansible/ubuntu2404/inventories/production/hosts.yml \
  ansible/ubuntu2404/playbooks/azure_pipelines_agents.yml \
  -e azp_agent_version=4.268.0
```

### Force Reinstall (Same Version)

Force stop/uninstall/reconfigure even when the installed version already matches the target version:

```bash
ansible-playbook \
  -i ansible/ubuntu2404/inventories/production/hosts.yml \
  ansible/ubuntu2404/playbooks/azure_pipelines_agents.yml \
  -e azp_force_reinstall=true
```

### Dry Run (Check Mode)

Preview changes without applying them:

```bash
ansible-playbook \
  -i ansible/ubuntu2404/inventories/production/hosts.yml \
  ansible/ubuntu2404/playbooks/azure_pipelines_agents.yml \
  --check --diff
```

> [!NOTE]
> Check mode cannot fully simulate shell tasks (`config.sh`, `svc.sh`), so some tasks will report "skipped". Use it primarily to verify version resolution and download decisions.

### Update Agents to the Latest Version

Simply re-run the playbook. The role reads the currently installed version from each instance's `.agent` file and performs an update when the resolved version differs.
If you need to redeploy while keeping the same version, set `-e azp_force_reinstall=true`:

```bash
ansible-playbook \
  -i ansible/ubuntu2404/inventories/production/hosts.yml \
  ansible/ubuntu2404/playbooks/azure_pipelines_agents.yml
```

The update flow is:

1. Stop the systemd service (`svc.sh stop`).
2. Uninstall the service (`svc.sh uninstall`).
3. Unconfigure the agent (`config.sh remove`).
4. Extract the new tarball over the instance directory.
5. Re-run `config.sh --unattended` and `svc.sh install/start`.

---

## Multi-Instance Configuration

You can deploy multiple agent instances on a single host. Each instance gets its own
directory under `azp_agent_base_dir`, its own systemd unit, and its own agent
registration in Azure DevOps.

Define instances in `host_vars` or directly in your inventory:

```yaml
agent-vm-01:
  ansible_host: 10.0.2.10
  azp_agent_instances:
    - name: "build-agent-1"
    - name: "build-agent-2"
    - name: "deploy-agent-1"
      pool: "Deploy-Pool"   # Override the default pool
```

This creates three agent directories:

```
/opt/azure-pipelines-agent/
├── build-agent-1/    → registered in "Default" pool
├── build-agent-2/    → registered in "Default" pool
└── deploy-agent-1/   → registered in "Deploy-Pool"
```

Each instance runs as an independent systemd service.

---

## Tags

The role and its playbook entry use the following Ansible tags:

| Tag | Scope |
|---|---|
| `deploy` | Playbook-level – includes the agent role |
| `agent` | Playbook-level – includes the agent role |
| `azure_agent` | Role-level – applied to all tasks within the role |

Examples:

```bash
# Run only agent-related tasks
ansible-playbook ... --tags agent

# Run all tasks in the dedicated agent playbook (no tag filter)
ansible-playbook ...
```

> [!NOTE]
> If you run `--tags agent` against a playbook that doesn't include the agent role (for example
> `playbooks/ubuntu2404.yml`), the agent will not be deployed and the install directory (default:
> `/opt/azure-pipelines-agent`) will not be created.

---

## Handlers

Two handlers are available and can be triggered with `notify`:

| Handler Name | Action |
|---|---|
| `restart azure pipelines agent` | Stops and starts all agent instances via `svc.sh` |
| `stop azure pipelines agent` | Stops all agent instances via `svc.sh` |

---

## Troubleshooting

### GitHub API rate limit exceeded

**Symptom:** The `Fetch recent releases from GitHub` task fails with HTTP 403.

**Solution:** Provide a GitHub token using one of these methods:

- Set the `GITHUB_TOKEN` or `GH_TOKEN` environment variable on the control node.
- Pass `-e azp_github_token=ghp_xxxx` at the command line.
- Add `azp_github_token` to your runtime vars file (`-e @file`).

### Agent registration fails

**Symptom:** The `Run config.sh` task fails.

**Possible causes:**

- The Service Principal does not have the _Agent Pools (Read & manage)_ permission in Azure DevOps.
- `azp_url` is incorrect or unreachable from the target host.
- The specified pool does not exist.

**Debugging:** Re-run with increased verbosity:

```bash
ansible-playbook ... --tags agent -vvv
```

> [!IMPORTANT]
> The `config.sh` task uses `no_log: true` to protect credentials. Temporarily set `no_log: false` in `configure_instance.yml` if you need to see the full command output during debugging. **Revert this change immediately afterward.**

### Agent service does not start

**Symptom:** The `Verify agent service status` task shows the service is inactive.

**Steps:**

1. SSH into the target host.
2. Check the systemd journal:

   ```bash
   sudo journalctl -u vsts.agent.*.svc -n 50 --no-pager
   ```

3. Verify the instance directory permissions:

   ```bash
   ls -la /opt/azure-pipelines-agent/<instance-name>/
   ```

### Checksum verification fails

**Symptom:** The download task fails with a checksum mismatch.

**Possible causes:**

- Corrupted download – the role retries up to 5 times automatically.
- The `assets.json` in the GitHub release does not match the tarball on the download server (rare).

**Workaround:** Manually verify the checksum and, if necessary, clear the cached tarball:

```bash
sudo rm /tmp/vsts-agent-linux-x64-*.tar.gz
```

Then re-run the playbook.

---

## Design Decisions

| Decision | Rationale |
|---|---|
| **GitHub Releases API for version resolution** | The official `microsoft/azure-pipelines-agent` repository publishes all releases (including pre-release) with `assets.json` containing SHA-256 checksums. This allows fully automated, verifiable downloads. |
| **Download from `download.agent.dev.azure.com`** | This is the official Microsoft-hosted CDN for agent tarballs. GitHub release assets only contain `assets.json` (checksums), not the tarballs themselves. |
| **Service Principal authentication** | SP auth enables fully non-interactive, unattended configuration. PAT-based auth requires token rotation; SP credentials can be managed via Azure AD with longer lifetimes and automated rotation. |
| **`svc.sh` for service management** | The agent ships with its own `svc.sh` script that generates proper systemd unit files. Using it (rather than writing custom units) ensures compatibility across agent versions. |
| **Dedicated `azure_pipelines_agents.yml` playbook** | Keeps image build and agent deployment as separate workflows, reducing accidental agent installation during image creation. |
| **Pre-release included by default** | Azure Pipelines agent pre-releases are generally stable and allow early access to fixes. The `azp_include_prerelease` variable lets you opt out. |
| **Multi-instance support** | Running multiple agents per host maximises hardware utilisation for parallel pipeline jobs without requiring additional VMs. |
| **Idempotent update flow** | The role reads the `.agent` JSON file to detect the installed version and skips instances that are already at the target version. This makes repeated playbook runs safe and efficient. |
| **`no_log: true` on credential tasks** | Prevents Service Principal secrets from appearing in Ansible output or logs. |
