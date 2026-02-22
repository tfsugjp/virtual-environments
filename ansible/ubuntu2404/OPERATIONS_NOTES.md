# Operational Notes (Ubuntu 24.04 Image Build)

This document records stability fixes and operational guidance applied to this Ansible workspace.

## Scope

These notes apply to:
- `playbooks/ubuntu2404.yml`
- `roles/system_base`
- `roles/validation`
- production and staging inventories

## Fixes Applied

### 1) Safe Ansible remote temp directory

**Problem**
- Build runs could fail with: `Failed to create temporary directory`
- Root-owned temp paths conflicted with non-root SSH user execution.

**Resolution**
- Set host `ansible_remote_tmp` to `/var/tmp` in inventories.
- Keep global default `remote_tmp = /var/tmp`.

**Why this works**
- `/var/tmp` is less likely to be aggressively cleaned by installer scripts.
- Avoids collisions with `/tmp` cleanup phases.

### 2) Prevent accidental SSH lockout

**Problem**
- Validation previously removed `authorized_keys`, causing permanent lockout in some environments.

**Resolution**
- Removed SSH key deletion step from `roles/validation/tasks/validation_run.yml`.

**Operational guidance**
- Do not remove `authorized_keys` during normal image build validation.
- If image sealing is required, implement a separate explicit pipeline stage.

### 3) Software report robustness patches

**Problem**
- Software report generation failed due to strict/ambiguous version regex handling.

**Resolution**
- Added patch tasks in `roles/system_base/tasks/main.yml` to harden SoftwareReport scripts copied from upstream runner-images.
- Relaxed strict duplicate-major-version validation and fixed regex patterns that caused collisions.

### 4) Android SDK install resilience (`JAVA_HOME`)

**Problem**
- Android SDK install/test failed when `JAVA_HOME` pointed to a non-existent Temurin path.

**Resolution**
- Patched `install-android-sdk.sh` after copy to:
  - unset invalid in-process `JAVA_HOME` before `sdkmanager` checks,
  - repair `/etc/environment` `JAVA_HOME` from the actual `java` binary if missing/invalid.

**Result**
- Android installer and Android tests pass in rerun scenarios where `JAVA_HOME` was stale.

## Staging Parity

Staging inventory now mirrors production for temp directory safety:
- `inventories/staging/hosts.yml` includes:
  - `ansible_remote_tmp: /var/tmp`

## Recommended Validation Commands

```bash
# Basic connectivity
ansible -i inventories/production/hosts.yml ubuntu2404-build-01 -m ping -vv

# Syntax check
ansible-playbook -i inventories/production/hosts.yml playbooks/ubuntu2404.yml --syntax-check

# Targeted system base + validation run
ansible-playbook -i inventories/production/hosts.yml playbooks/ubuntu2404.yml \
  --limit ubuntu2404-build-01 --tags "system_base,validation" -vv
```

## Notes for Future Updates

When upstream `actions/runner-images` scripts change, re-verify these areas first:
1. SoftwareReport behavior
2. Android SDK install + test sequence
3. Any temp-directory assumptions in cleanup logic

If upstream fixes make local patches unnecessary, remove local patch tasks deliberately and validate with a full run.
