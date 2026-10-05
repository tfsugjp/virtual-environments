# Ubuntu 24.04 Ansible Playbook

This directory contains the Ansible playbook used to build the x64 Ubuntu 24.04
GitHub Actions runner image on an on-premises host. Build scripts, tests,
assets, and toolsets are copied from this repository checkout; the target does
not download the runner-images source tree.

## 📁 Directory Structure

```
ansible-ubuntu2404/
├── ansible.cfg                     # Ansible configuration file
├── requirements.yml                # Required Ansible collections
├── inventories/                    # Inventory files
│   ├── production/
│   │   ├── hosts.yml              # Production host definitions
│   │   └── group_vars/
│   │       └── ubuntu2404.yml     # Ubuntu 24.04-specific variables
│   └── staging/
│       └── hosts.yml              # Staging host definitions
├── playbooks/
│   ├── ubuntu2404.yml             # Main image build playbook
│   └── azure_pipelines_agents.yml # Azure Pipelines agent deployment playbook
├── roles/                          # Ansible roles
│   ├── system_base/               # Phase 1: Base system setup
│   ├── microsoft_repos/           # Phase 2: Microsoft repositories
│   ├── powershell/                # Phase 3: PowerShell
│   ├── development_tools/         # Phase 4: Development tools (50+ tools)
│   ├── container_tools/           # Phase 5: Docker
│   ├── toolset_configuration/     # Phase 6: Toolset configuration
│   ├── post_install/              # Phase 7: Post-install and reboot
│   ├── validation/                # Phase 8: Testing and validation
│   └── azure_pipelines_agent/     # Azure Pipelines self-hosted agent role
├── group_vars/
│   ├── all.yml                    # Variables shared by all hosts
│   └── ubuntu.yml                 # Ubuntu-specific variables
└── templates/                      # Template files
```

## 🚀 Quick Start

### 1. Prerequisites

- Ansible >= 2.14
- Python >= 3.9
- Target host: x64 Ubuntu 24.04 LTS
- SSH access to the target environment

### 2. Setup

```bash
# Install Ansible
python3 -m pip install ansible

# Install required collections
cd ansible-ubuntu2404
ansible-galaxy collection install -r requirements.yml
```

### 3. Configure Inventory

Edit `inventories/production/hosts.yml`:

```yaml
ubuntu2404_builders:
  hosts:
    ubuntu2404-build-01:
      ansible_host: YOUR_VM_IP
      ansible_user: YOUR_USERNAME
      ansible_ssh_private_key_file: ~/.ssh/YOUR_KEY
```

### 4. Run

```bash
# Syntax check
ansible-playbook playbooks/ubuntu2404.yml --syntax-check

# Dry run (no changes applied)
ansible-playbook playbooks/ubuntu2404.yml --check

# Run the playbook
ansible-playbook playbooks/ubuntu2404.yml

# Run only specific roles
ansible-playbook playbooks/ubuntu2404.yml --tags "system_base,powershell"

# Skip specific roles
ansible-playbook playbooks/ubuntu2404.yml --skip-tags "development_tools"

# Deploy Azure Pipelines agents (ubuntu2404_agents group)
AZP_URL="https://dev.azure.com/myorg" AZP_CLIENT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" AZP_TENANT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" AZP_CLIENT_SECRET="your-secret-value" ansible-playbook -i inventories/production/hosts.yml playbooks/azure_pipelines_agents.yml --limit ubuntu2404_agents

# Force reinstall even when target version is already installed
AZP_URL="https://dev.azure.com/myorg" AZP_CLIENT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" AZP_TENANT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" AZP_CLIENT_SECRET="your-secret-value" ansible-playbook -i inventories/production/hosts.yml playbooks/azure_pipelines_agents.yml --limit ubuntu2404_agents -e azp_force_reinstall=true
```

## 🏗️ Role Details

### Phase 1: system_base
- Create directory structure
- Copy helper scripts, build scripts, tests, and assets from the local repository checkout
- Deploy `toolset.json`

### Phase 2: microsoft_repos
- Add Microsoft APT repositories
- Optimize APT sources
- Configure image metadata

### Phase 3: powershell
- Install PowerShell Core
- Install PowerShell modules
- Install Azure PowerShell modules

### Phase 4: development_tools
**Largest role — installs 50+ tools:**
- Cloud & Container: Azure CLI, AWS Tools, Kubernetes
- Compilers: Clang, GCC, Swift, CMake
- Languages: Java, Ruby, Rust, PHP, Python, Node.js, Go
- Databases: MySQL, PostgreSQL
- Web & Browsers: Chrome, Firefox, Edge, Selenium
- Build Tools: Bazel, Packer, Vcpkg, Ninja
- Misc: Git, GitHub CLI, Android SDK, .NET SDK

### Phase 5: container_tools
- Install and configure Docker
- Install Docker Compose

### Phase 6: toolset_configuration
- Manage Python/Node.js/Ruby/Go versions
- Install `pipx` packages

### Phase 7: post_install
- Install Homebrew
- Configure Snap
- Reboot the system
- Perform cleanup

### Phase 8: validation
- Generate software reports
- Run tests
- Apply final system configuration
- Preserve SSH access; Azure-specific deprovisioning is not performed

## 📊 Estimated Execution Time

| Phase | Estimated Time |
|-------|---------|
| Phase 1-3 | 15 min |
| Phase 4 | 60-90 min |
| Phase 5-6 | 20 min |
| Phase 7 | 10 min (+ reboot) |
| Phase 8 | 10 min |
| **Total** | **2-3 hours** |

## 🔧 Customization

### Override Variables

Override variables defined in `group_vars/ubuntu.yml`:

```bash
ansible-playbook playbooks/ubuntu2404.yml \
  -e "image_version=20251017.2" \
  -e "nodejs_default=22"
```

### Partial Execution with Tags

```bash
# Install development tools only
ansible-playbook playbooks/ubuntu2404.yml --tags "development_tools"

# Install language-related tools only
ansible-playbook playbooks/ubuntu2404.yml --tags "languages"

# Skip database-related tasks only
ansible-playbook playbooks/ubuntu2404.yml --skip-tags "databases"
```

### Tune Parallel Execution

Adjust `forks` in `ansible.cfg`:

```ini
[defaults]
forks = 10  # Default is 5
```

## 🧪 Testing

### Syntax Check
```bash
ansible-playbook playbooks/ubuntu2404.yml --syntax-check
```

### Dry-run
```bash
ansible-playbook playbooks/ubuntu2404.yml --check --diff
```

### Debug Mode
```bash
ansible-playbook playbooks/ubuntu2404.yml -vvv
```

## 📦 Output

After execution, the following files are generated:

- `./outputs/Ubuntu2404-Readme.md` - Software report (Markdown)
- `./outputs/software-report.json` - Software report (JSON)
- `/imagegeneration/tests/testResults.xml` on the target VM - Test results

## 🔒 Security

### Encrypt Passwords

```bash
# Encrypt a variable
ansible-vault encrypt_string 'your_password' --name 'ansible_become_password'

# Encrypt an entire file
ansible-vault encrypt group_vars/ubuntu.yml

# Decrypt at runtime
ansible-playbook playbooks/ubuntu2404.yml --ask-vault-pass
```

## 🐛 Troubleshooting

### APT Lock Conflicts
```bash
# Retry logic is already configured in tasks.
# If errors persist, clear lock files manually:
sudo rm /var/lib/apt/lists/lock
sudo rm /var/cache/apt/archives/lock
sudo rm /var/lib/dpkg/lock*
```

### SSH Connection Failures
```bash
# Connection test
ansible ubuntu2404_builders -m ping

# Verbose logs
ansible ubuntu2404_builders -m ping -vvv
```

### Connection Failures After Reboot
Increase `post_reboot_delay` (default: 300 seconds):

```yaml
# roles/post_install/tasks/main.yml
post_reboot_delay: 600  # Increase to 10 minutes
```

## 📚 Related Documentation

- [Ansible Documentation](https://docs.ansible.com/)
- [Packer to Ansible Migration Plan](../../docs/ansible-migration.md)
- [Azure Pipelines Agent Role](../../docs/azure-pipelines-agent-role.md)
- [Original Packer Template](../../images/ubuntu/templates/build.ubuntu-24_04.pkr.hcl)

## 🤝 Contributing

Please use Issues or pull requests for improvement ideas and bug reports.

## 📝 License

This project follows the same license as the original repository.
