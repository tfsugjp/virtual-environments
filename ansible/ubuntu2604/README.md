# Ubuntu 26.04 Ansible Playbook

Builds an x64 Ubuntu 26.04 runner image on an on-premises Linux host. This
playbook shares its Ansible roles with `ansible/ubuntu2404/` and copies scripts,
tests, assets, and toolsets from this repository checkout; it does not fetch the
runner-images source tree from a cloud service.

## Prerequisites

- Ansible 2.14 or later and Python 3.9 or later on the controller
- An x64 Ubuntu 26.04 target reachable over SSH
- A sudo-capable SSH user
- Network access from the target to the package repositories and upstream tool
  download endpoints used by the runner-images installers
- Enough target disk space for the installed toolset and temporary downloads

Install the required collections:

```bash
cd ansible/ubuntu2604
ansible-galaxy collection install -r requirements.yml
```

Edit `inventories/production/hosts.yml` and replace the documentation address
with your target host. Then validate and run the build:

```bash
ansible-playbook -i inventories/production/hosts.yml \
  playbooks/ubuntu2604.yml --syntax-check
ansible-playbook -i inventories/production/hosts.yml \
  playbooks/ubuntu2604.yml
```

The default image version is `local`. Override it when a release identifier is
needed:

```bash
ansible-playbook -i inventories/production/hosts.yml \
  playbooks/ubuntu2604.yml -e image_version=YOUR_RELEASE_VERSION
```

Build artifacts are written to `outputs/` relative to the current working
directory, including `Ubuntu2604-Readme.md` and `software-report.json`.

The toolset is x64-only. This playbook does not add Azure Pipelines agent
deployment or perform Azure-specific image deprovisioning.
