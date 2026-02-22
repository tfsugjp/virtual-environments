# Packer to Ansible Migration Plan

## 概要

このドキュメントは、virtual-environments リポジトリにおける Packer ベースのイメージビルドシステムを Ansible に移行するための包括的な計画書です。

**作成日:** 2025年10月17日  
**対象OS:** Ubuntu 24.04, Windows Server 2025  
**目的:** CI/CDランナー用イメージを宣言的・再利用可能な構成管理ツールで構築

---

## 背景と動機

### 現状のPackerアーキテクチャ

#### 長所
- イミュータブルなイメージ作成に特化
- テンプレート → VM作成 → プロビジョニング → イメージ化の一貫したフロー
- Azure/AWS/GCP など複数クラウドプロバイダー対応

#### 課題
- 1回限りの実行を前提とした設計
- べき等性の欠如（再実行が困難）
- デバッグ時に全工程を再実行する必要がある
- 段階的な更新・パッチ適用に不向き
- 構成ドリフトの検出機能がない

### Ansible移行の利点

1. **べき等性:** 同じPlaybookを何度実行しても安全
2. **段階的実行:** タグ・ロール単位での部分実行が可能
3. **エコシステム:** 豊富なモジュール・コレクション
4. **デバッグ性:** 失敗箇所から再開可能
5. **再利用性:** ロールの横展開・バージョン管理
6. **構成管理:** 既存VMへのパッチ適用も対応可能

---

## アーキテクチャ設計

### Windows Server 2025の場合

```
ansible-windows2025/
├── ansible.cfg
├── requirements.yml
├── inventories/
│   ├── production/
│   │   ├── hosts.yml
│   │   └── group_vars/
│   │       └── windows_2025.yml
│   └── development/
│       └── hosts.yml
├── playbooks/
│   ├── site.yml                          # メインプレイブック
│   ├── phase1_base_config.yml
│   ├── phase2_core_tooling.yml
│   ├── phase3_visual_studio.yml
│   ├── phase4_extended_tooling.yml
│   ├── phase5_broad_toolset.yml
│   ├── phase6_elevated_installs.yml
│   ├── phase7_tests_reports.yml
│   ├── phase8_final_config.yml
│   └── phase9_sysprep.yml
├── roles/
│   ├── windows_base/
│   │   ├── tasks/
│   │   │   ├── main.yml
│   │   │   ├── configure_defender.yml
│   │   │   ├── configure_powershell.yml
│   │   │   └── install_modules.yml
│   │   ├── defaults/
│   │   │   └── main.yml
│   │   ├── templates/
│   │   └── files/
│   ├── docker/
│   ├── visual_studio/
│   ├── kubernetes_tools/
│   ├── language_runtimes/        # Java, Ruby, Python, Node.js
│   ├── database_tools/            # MySQL, PostgreSQL, MongoDB
│   ├── cloud_tools/               # Azure CLI, AWS Tools
│   └── system_finalization/       # Sysprep, cleanup
├── group_vars/
│   ├── all.yml
│   └── windows.yml
├── host_vars/
├── files/
│   └── scripts/                   # 既存のPowerShellスクリプトを配置
└── README.md
```

### Ubuntu 24.04の場合

```
ansible-ubuntu2404/
├── ansible.cfg
├── requirements.yml
├── inventories/
│   ├── production/
│   │   ├── hosts.yml
│   │   └── group_vars/
│   │       └── ubuntu2404.yml
│   └── staging/
│       └── hosts.yml
├── playbooks/
│   └── ubuntu2404.yml              # メインプレイブック
├── roles/
│   ├── system_base/                # フェーズ1: ベース設定
│   ├── microsoft_repos/            # フェーズ2: Microsoftリポジトリ
│   ├── powershell/                 # フェーズ3: PowerShell関連
│   ├── development_tools/          # フェーズ4: 開発ツール群
│   ├── container_tools/            # フェーズ5: Docker等
│   ├── toolset_configuration/      # フェーズ6: ツールセット設定
│   ├── post_install/               # フェーズ7: 最終設定
│   └── validation/                 # フェーズ8: 検証
├── group_vars/
│   ├── all.yml
│   └── ubuntu.yml
├── templates/
│   └── toolset-2404.json.j2
└── files/
    └── scripts/                    # 既存スクリプトを配置
```

---

## Ubuntu 24.04 移行詳細

### Packerフェーズ分析

現在のPacker定義 (`build.ubuntu-24_04.pkr.hcl`) から抽出した10個の主要フェーズ:

| Phase | Packer処理 | Ansibleロール | 推定時間 |
|-------|-----------|-------------|---------|
| 1 | ディレクトリ作成・ヘルパー配置 | `system_base` | 2分 |
| 2 | APTソース設定・MSリポジトリ | `microsoft_repos` | 5分 |
| 3 | PowerShell & モジュール | `powershell` | 10分 |
| 4 | 50+開発ツールインストール | `development_tools` | 60-90分 |
| 5 | Docker | `container_tools` | 5分 |
| 6 | Toolset設定(Python/Node/Ruby) | `toolset_configuration` | 15分 |
| 7 | pipx & Homebrew | `post_install` | 10分 |
| 8 | Snap設定・再起動・cleanup | `post_install` | 10分 |
| 9 | テスト・レポート生成 | `validation` | 5分 |
| 10 | システム設定・waagent | `validation` | 3分 |

**合計推定時間:** 2-3時間

### ロール実装詳細

#### ロール1: system_base

**責務:**
- 必要なディレクトリ構造の作成
- ヘルパースクリプトの配置
- ビルドスクリプトの配置
- テスト・ドキュメントスクリプトの配置
- toolset.jsonの配置
- システム制限の設定

**主要タスク:**
```yaml
- name: Create required directories
  ansible.builtin.file:
    path: "{{ item }}"
    state: directory
    mode: '0777'
  loop:
    - "{{ image_folder }}"
    - "{{ helper_script_folder }}"
    - "{{ installer_script_folder }}"
  become: yes

- name: Copy toolset configuration
  ansible.builtin.template:
    src: toolset-2404.json.j2
    dest: "{{ installer_script_folder }}/toolset.json"
    mode: '0644'
  become: yes
```

#### ロール2: microsoft_repos

**責務:**
- Microsoft製品用APTリポジトリ追加
- APTソースの最適化
- イメージメタデータの設定
- 環境変数の設定

**主要タスク:**
```yaml
- name: Install Microsoft repositories
  ansible.builtin.shell: "{{ item }}"
  loop:
    - "{{ installer_script_folder }}/install-ms-repos.sh"
    - "{{ installer_script_folder }}/configure-apt-sources.sh"
    - "{{ installer_script_folder }}/configure-apt.sh"
  environment:
    HELPER_SCRIPTS: "{{ helper_script_folder }}"
    DEBIAN_FRONTEND: noninteractive
  become: yes
```

#### ロール3: powershell

**責務:**
- 必須APTパッケージインストール
- PowerShell Coreのインストール
- PowerShellモジュールのインストール
- Azure PowerShellモジュールのインストール

**主要タスク:**
```yaml
- name: Install PowerShell
  ansible.builtin.shell: "{{ installer_script_folder }}/install-powershell.sh"
  environment:
    HELPER_SCRIPTS: "{{ helper_script_folder }}"
    INSTALLER_SCRIPT_FOLDER: "{{ installer_script_folder }}"
  become: yes

- name: Install PowerShell modules
  ansible.builtin.shell: "pwsh -f {{ item }}"
  loop:
    - "{{ installer_script_folder }}/Install-PowerShellModules.ps1"
    - "{{ installer_script_folder }}/Install-PowerShellAzModules.ps1"
  environment:
    HELPER_SCRIPTS: "{{ helper_script_folder }}"
    INSTALLER_SCRIPT_FOLDER: "{{ installer_script_folder }}"
  become: yes
```

#### ロール4: development_tools

**責務:** 50以上の開発ツールをカテゴリ別にインストール

**カテゴリ構成:**
1. **Cloud & Container:** actions-cache, runner-package, azcopy, azure-cli, azure-devops-cli, bicep, aws-tools, container-tools, kubernetes-tools
2. **Compilers:** clang, swift, gcc-compilers, gfortran, cmake
3. **Languages:** java-tools, ruby, rust, php, kotlin, haskell, julia, nvm, nodejs, python, pypy
4. **Databases:** mysql, postgresql
5. **Web & Browsers:** apache, nginx, google-chrome, microsoft-edge, firefox, selenium
6. **Build Tools:** bazel, packer, vcpkg, ninja
7. **Misc:** apt-common, git, git-lfs, github-cli, google-cloud-cli, miniconda, android-sdk, pulumi, codeql-bundle, dotnetcore-sdk, yq, zstd

**実装パターン:**
```yaml
- name: Install development tools (batch 1 - Cloud & Container)
  ansible.builtin.shell: "{{ item }}"
  loop:
    - "{{ installer_script_folder }}/install-actions-cache.sh"
    - "{{ installer_script_folder }}/install-runner-package.sh"
    # ... 他のスクリプト
  environment:
    HELPER_SCRIPTS: "{{ helper_script_folder }}"
    INSTALLER_SCRIPT_FOLDER: "{{ installer_script_folder }}"
    DEBIAN_FRONTEND: noninteractive
  become: yes
  tags: ['cloud', 'containers']
```

#### ロール5: container_tools

**責務:**
- Dockerのインストール
- Dockerサービスの起動・有効化
- Docker動作確認

**主要タスク:**
```yaml
- name: Install Docker
  ansible.builtin.shell: "{{ installer_script_folder }}/install-docker.sh"
  environment:
    HELPER_SCRIPTS: "{{ helper_script_folder }}"
    INSTALLER_SCRIPT_FOLDER: "{{ installer_script_folder }}"
    DOCKERHUB_PULL_IMAGES: "NO"
  become: yes

- name: Start Docker service
  ansible.builtin.systemd:
    name: docker
    state: started
    enabled: yes
  become: yes
```

#### ロール6: toolset_configuration

**責務:**
- Python/Node.js/Ruby/Go等のバージョン管理ツールセットインストール
- ツールセット設定
- pipxパッケージインストール

**主要タスク:**
```yaml
- name: Install and configure toolset
  ansible.builtin.shell: "pwsh -f {{ item }}"
  loop:
    - "{{ installer_script_folder }}/Install-Toolset.ps1"
    - "{{ installer_script_folder }}/Configure-Toolset.ps1"
  environment:
    HELPER_SCRIPTS: "{{ helper_script_folder }}"
    INSTALLER_SCRIPT_FOLDER: "{{ installer_script_folder }}"
  become: yes
```

#### ロール7: post_install

**責務:**
- Homebrewインストール（一般ユーザー権限）
- Snap設定
- システム再起動
- クリーンアップ処理

**主要タスク:**
```yaml
- name: Install Homebrew
  ansible.builtin.shell: "{{ installer_script_folder }}/install-homebrew.sh"
  environment:
    HELPER_SCRIPTS: "{{ helper_script_folder }}"
    DEBIAN_FRONTEND: noninteractive
    INSTALLER_SCRIPT_FOLDER: "{{ installer_script_folder }}"
  become: no  # Homebrewは一般ユーザーでインストール

- name: Reboot system
  ansible.builtin.reboot:
    reboot_timeout: 600
    pre_reboot_delay: 0
    post_reboot_delay: 300  # 5分待機
    test_command: uptime
  become: yes
```

#### ロール8: validation

**責務:**
- ソフトウェアレポート生成
- テスト実行
- レポートダウンロード
- システム最終設定
- ビルド後検証
- waagent deprovision（Azure環境の場合）

**主要タスク:**
```yaml
- name: Generate software report
  ansible.builtin.shell: |
    pwsh -File {{ image_folder }}/SoftwareReport/Generate-SoftwareReport.ps1 -OutputDirectory {{ image_folder }}
  environment:
    IMAGE_VERSION: "{{ image_version }}"
    INSTALLER_SCRIPT_FOLDER: "{{ installer_script_folder }}"

- name: Run all tests
  ansible.builtin.shell: |
    pwsh -File {{ image_folder }}/tests/RunAll-Tests.ps1 -OutputDirectory {{ image_folder }}
  environment:
    INSTALLER_SCRIPT_FOLDER: "{{ installer_script_folder }}"
  register: test_results
  failed_when: test_results.rc != 0

- name: Download software reports
  ansible.builtin.fetch:
    src: "{{ item.src }}"
    dest: "{{ item.dest }}"
    flat: yes
  loop:
    - { src: "{{ image_folder }}/software-report.md", dest: "./outputs/Ubuntu2404-Readme.md" }
    - { src: "{{ image_folder }}/software-report.json", dest: "./outputs/software-report.json" }
```

### 変数定義

#### group_vars/ubuntu.yml
```yaml
# Directory structure
image_folder: "/imagegeneration"
helper_script_folder: "/imagegeneration/helpers"
installer_script_folder: "/imagegeneration/installers"
imagedata_file: "/imagegeneration/imagedata.json"

# Image metadata
image_version: "20251017.1"
image_os: "ubuntu24"
cloud_provider: "azure"  # azure, aws, gcp, bare-metal

# Toolset versions (from toolset-2404.json)
python_versions:
  - "3.9.*"
  - "3.10.*"
  - "3.11.*"
  - "3.12.*"
  - "3.13.*"

nodejs_versions:
  - "18.*"
  - "20.*"
  - "22.*"

nodejs_default: "20"

go_versions:
  - "1.22.*"
  - "1.23.*"
  - "1.24.*"

go_default: "1.24.*"

ruby_versions:
  - "3.2.*"
  - "3.3.*"
  - "3.4.*"

java_versions: ["8", "11", "17", "21"]
java_default: "17"

dotnet_versions: ["8.0", "9.0"]

clang_versions: ["16", "17", "18"]
clang_default: "18"

docker_version: "28.0.4"
docker_compose_version: "2.38.2"

postgresql_version: "16"
pwsh_version: "7.4"
php_version: "8.3"
```

---

## Windows Server 2025 移行詳細

### Packerフェーズ分析

現在のHyper-V Packer定義から抽出した9個のフェーズ:

| Phase | Packer処理 | Ansibleロール | 推定時間 |
|-------|-----------|-------------|---------|
| 1 | ベース設定・ファイル配置 | `windows_base` | 10分 |
| 2 | Docker & Runner | `docker` | 15分 |
| 3 | Visual Studio & K8s | `visual_studio` | 90-120分 |
| 4 | 拡張ツール群 | `language_runtimes` | 30分 |
| 5 | ブロードツールセット | `language_runtimes` | 60分 |
| 6 | 昇格インストール・Windows Update | `windows_updates` | 60-90分 |
| 7 | テスト・レポート | `system_finalization` | 15分 |
| 8 | 最終設定 | `system_finalization` | 10分 |
| 9 | Sysprep | `system_finalization` | 5分 |

**合計推定時間:** 4-6時間

### 主要な技術的課題

#### 1. WinRM通信設定
```yaml
# inventories/production/hosts.yml
windows_2025_builders:
  hosts:
    win2025-build-01:
      ansible_host: 192.168.1.100
      ansible_user: packer
      ansible_password: "{{ install_password }}"
      ansible_connection: winrm
      ansible_winrm_transport: ntlm
      ansible_winrm_server_cert_validation: ignore
      ansible_port: 5985
```

#### 2. 昇格実行
```yaml
- name: Enable test signing
  ansible.windows.win_shell: bcdedit.exe /set TESTSIGNING ON
  become: yes
  become_method: runas
  become_user: "{{ install_user }}"
  vars:
    ansible_become_password: "{{ install_password }}"
```

#### 3. 再起動処理
```yaml
- name: Reboot after Docker installation
  ansible.windows.win_reboot:
    reboot_timeout: 1800
    pre_reboot_delay: 0
    post_reboot_delay: 120
    test_command: 'powershell -command "Get-Service Docker"'
```

#### 4. Windows Update
```yaml
- name: Install Windows Updates
  ansible.windows.win_updates:
    category_names:
      - SecurityUpdates
      - CriticalUpdates
      - UpdateRollups
    state: installed
    reboot: yes
    reboot_timeout: 3600
  register: windows_updates_result
```

#### 5. Sysprep実行
```yaml
- name: Run Sysprep
  ansible.windows.win_shell: |
    if (Test-Path $env:SystemRoot\System32\Sysprep\unattend.xml) {
      Remove-Item $env:SystemRoot\System32\Sysprep\unattend.xml -Force
    }
    & $env:SystemRoot\System32\Sysprep\Sysprep.exe /oobe /generalize /mode:vm /quiet /quit
    
    # Wait for generalization
    while($true) {
      $imageState = Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State | Select-Object ImageState
      if ($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') {
        Write-Output $imageState.ImageState
        Start-Sleep -Seconds 10
      } else {
        break
      }
    }
  async: 3600
  poll: 10
```

---

## 実装戦略

### 段階的実装アプローチ

#### Phase 1: 環境準備 (1日)
```bash
# Ansible制御ノード(Linux/macOS)
python3 -m pip install ansible pywinrm

# Collections
ansible-galaxy collection install ansible.windows
ansible-galaxy collection install community.windows
ansible-galaxy collection install chocolatey.chocolatey
```

#### Phase 2: Ubuntu最小限PoC (2日)
- `system_base`ロールのみ実装
- SSH接続・sudoテスト
- ディレクトリ作成・ファイル配置・簡単なスクリプト実行

#### Phase 3: Ubuntu 1ロール完全実装 (3日)
- `development_tools`ロールの1バッチ（例: Cloud & Container）を完全実装
- エラーハンドリング強化
- べき等性確保

#### Phase 4: Ubuntu全ロール実装 (5日)
- 全8ロールの実装
- タグによる部分実行テスト
- 統合テスト

#### Phase 5: Windows最小限PoC (3日)
- WinRM接続確立
- `windows_base`ロール実装
- PowerShellスクリプト実行テスト

#### Phase 6: Windows全ロール実装 (7日)
- 全9ロールの実装
- Visual Studio等の大型インストール検証
- Windows Update統合

#### Phase 7: CI/CD統合 (5日)
- GitHub Actions / GitLab CI連携
- 自動ビルドパイプライン構築
- イメージバージョニング戦略

---

## パフォーマンス最適化

### 並列実行
```yaml
- name: Install independent tools in parallel
  ansible.builtin.shell: "{{ item }}"
  loop:
    - "{{ installer_script_folder }}/install-git.sh"
    - "{{ installer_script_folder }}/install-docker.sh"
    - "{{ installer_script_folder }}/install-nodejs.sh"
  async: 1800  # 30分タイムアウト
  poll: 0      # 並列実行
  register: parallel_installs
  become: yes

- name: Wait for parallel installs to complete
  ansible.builtin.async_status:
    jid: "{{ item.ansible_job_id }}"
  loop: "{{ parallel_installs.results }}"
  register: async_results
  until: async_results.finished
  retries: 120
  delay: 15
```

### APTキャッシュ最適化
```yaml
- name: Update apt cache
  ansible.builtin.apt:
    update_cache: yes
    cache_valid_time: 3600  # 1時間キャッシュ有効
  become: yes
```

### Fact収集の最適化
```yaml
# ansible.cfg
[defaults]
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 3600
```

---

## トラブルシューティング

### よくある問題と解決策

#### Ubuntu

| 問題 | 原因 | 解決策 |
|------|------|--------|
| APTロック競合 | 複数プロセスが同時にAPT使用 | `apt`モジュール使用、リトライ設定 |
| Homebrew権限エラー | rootでインストール試行 | `become: no`で一般ユーザー実行 |
| 再起動後の接続失敗 | SSHサービス未起動 | `post_reboot_delay`を300秒に設定 |
| スクリプト実行失敗 | 環境変数未設定 | `environment:`で明示的に設定 |

#### Windows

| 問題 | 原因 | 解決策 |
|------|------|--------|
| WinRM接続失敗 | 証明書検証エラー | `ansible_winrm_server_cert_validation: ignore` |
| 昇格実行失敗 | パスワード未設定 | `ansible_become_password`変数設定 |
| Visual Studio timeout | インストール時間超過 | `async: 7200`で2時間に延長 |
| Windows Update再起動ループ | 更新多数 | `reboot_timeout: 3600`設定 |

---

## セキュリティ考慮事項

### 認証情報管理

#### Ansible Vault使用
```bash
# パスワードの暗号化
ansible-vault encrypt_string 'PackerP@ssw0rd!' --name 'install_password'

# 変数ファイル全体を暗号化
ansible-vault encrypt group_vars/windows.yml

# 実行時に復号化
ansible-playbook playbooks/ubuntu2404.yml --ask-vault-pass
```

#### 環境変数からの読み込み
```yaml
# group_vars/all.yml
install_password: "{{ lookup('env', 'ANSIBLE_INSTALL_PASSWORD') }}"
```

### ネットワークセキュリティ

#### WinRM over HTTPS (推奨)
```yaml
ansible_connection: winrm
ansible_winrm_transport: certificate
ansible_winrm_cert_pem: /path/to/cert.pem
ansible_winrm_cert_key_pem: /path/to/key.pem
ansible_port: 5986  # HTTPS
```

#### Firewall設定の一時的無効化
```yaml
# 注意: ビルド環境でのみ使用
- name: Temporarily disable firewall for build
  ansible.windows.win_firewall:
    state: disabled
    profiles: ['Domain', 'Private', 'Public']
  when: build_environment | default(false)
```

---

## テスト戦略

### 単体テスト (ロール単位)

```yaml
# tests/test_system_base.yml
---
- name: Test system_base role
  hosts: test_ubuntu
  gather_facts: yes
  
  roles:
    - system_base
  
  post_tasks:
    - name: Verify directories exist
      ansible.builtin.stat:
        path: "{{ item }}"
      register: dir_check
      failed_when: not dir_check.stat.exists or not dir_check.stat.isdir
      loop:
        - /imagegeneration
        - /imagegeneration/helpers
        - /imagegeneration/installers
```

### 統合テスト (全体)

```yaml
# tests/test_full_build.yml
---
- name: Full build integration test
  hosts: test_ubuntu
  
  tasks:
    - name: Verify Python versions
      ansible.builtin.command: "python{{ item }} --version"
      loop: ["3.9", "3.10", "3.11", "3.12"]
      register: python_check
      changed_when: false
    
    - name: Verify Docker
      ansible.builtin.command: docker run --rm hello-world
      become: yes
      register: docker_test
      changed_when: false
    
    - name: Verify software report exists
      ansible.builtin.stat:
        path: /imagegeneration/software-report.md
      register: report_check
      failed_when: not report_check.stat.exists
```

### Molecule使用（推奨）

```yaml
# molecule/default/molecule.yml
---
dependency:
  name: galaxy
driver:
  name: docker
platforms:
  - name: ubuntu2404-test
    image: ubuntu:24.04
    pre_build_image: false
provisioner:
  name: ansible
  inventory:
    host_vars:
      ubuntu2404-test:
        ansible_user: root
verifier:
  name: ansible
```

---

## CI/CD統合

### GitHub Actions例

```yaml
# .github/workflows/build-ubuntu2404.yml
name: Build Ubuntu 24.04 Image

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      image_version:
        description: 'Image version'
        required: true
        default: 'dev'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Ansible
        run: |
          python3 -m pip install ansible
          ansible-galaxy collection install ansible.posix
      
      - name: Setup SSH key
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.BUILD_VM_SSH_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
      
      - name: Run Ansible Playbook
        run: |
          cd ansible-ubuntu2404
          ansible-playbook playbooks/ubuntu2404.yml \
            -i inventories/production/hosts.yml \
            -e "image_version=${{ github.event.inputs.image_version || 'dev' }}"
        env:
          ANSIBLE_HOST_KEY_CHECKING: false
      
      - name: Upload software reports
        uses: actions/upload-artifact@v4
        with:
          name: software-reports
          path: |
            ansible-ubuntu2404/outputs/*.md
            ansible-ubuntu2404/outputs/*.json
```

---

## メトリクスと監視

### 実行時間測定

```ini
# ansible.cfg
[defaults]
callbacks_enabled = profile_tasks, timer
```

出力例:
```
PLAY RECAP *********************************************************************
ubuntu2404-build-01        : ok=127  changed=89   unreachable=0    failed=0    skipped=12   rescued=0    ignored=0

Playbook run took 0 days, 2 hours, 34 minutes, 12 seconds
```

### リソース使用量監視

```yaml
- name: Monitor resource usage
  ansible.builtin.shell: |
    echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)"
    echo "Memory: $(free -h | awk '/^Mem:/ {print $3"/"$2}')"
    echo "Disk: $(df -h / | awk 'NR==2 {print $3"/"$2" ("$5")"}')"
  register: resource_usage
  changed_when: false

- name: Display resource usage
  ansible.builtin.debug:
    var: resource_usage.stdout_lines
```

---

## 移行チェックリスト

### Ubuntu 24.04

- [ ] ディレクトリ構造作成
- [ ] `ansible.cfg`設定
- [ ] インベントリファイル作成
- [ ] 変数ファイル作成（all.yml, ubuntu.yml）
- [ ] `system_base`ロール実装
- [ ] `microsoft_repos`ロール実装
- [ ] `powershell`ロール実装
- [ ] `development_tools`ロール実装
- [ ] `container_tools`ロール実装
- [ ] `toolset_configuration`ロール実装
- [ ] `post_install`ロール実装
- [ ] `validation`ロール実装
- [ ] メインプレイブック作成
- [ ] 単体テスト作成
- [ ] 統合テスト実行
- [ ] ドキュメント作成
- [ ] CI/CD統合

### Windows Server 2025

- [ ] ディレクトリ構造作成
- [ ] WinRM設定確認
- [ ] インベントリファイル作成（WinRM用）
- [ ] 変数ファイル作成（all.yml, windows.yml）
- [ ] `windows_base`ロール実装
- [ ] `docker`ロール実装
- [ ] `powershell_core`ロール実装
- [ ] `visual_studio`ロール実装
- [ ] `kubernetes_tools`ロール実装
- [ ] `language_runtimes`ロール実装
- [ ] `database_tools`ロール実装
- [ ] `cloud_tools`ロール実装
- [ ] `windows_updates`ロール実装
- [ ] `system_finalization`ロール実装
- [ ] メインプレイブック作成
- [ ] 単体テスト作成
- [ ] 統合テスト実行
- [ ] ドキュメント作成
- [ ] CI/CD統合

---

## 作業見積もり

### Ubuntu 24.04

| タスク | 工数(人日) | 担当 | 状態 |
|--------|----------|------|------|
| 環境構築 | 1 | - | ⏳ 未着手 |
| Phase 1 PoC | 3 | - | ⏳ 未着手 |
| Phase 2-3 実装 | 5 | - | ⏳ 未着手 |
| Phase 4-5 実装 | 10 | - | ⏳ 未着手 |
| Phase 6-9 実装 | 5 | - | ⏳ 未着手 |
| テスト・検証 | 5 | - | ⏳ 未着手 |
| ドキュメント | 3 | - | ⏳ 未着手 |
| CI/CD統合 | 5 | - | ⏳ 未着手 |
| **Ubuntu合計** | **37人日** | - | - |

### Windows Server 2025

| タスク | 工数(人日) | 担当 | 状態 |
|--------|----------|------|------|
| 環境構築 | 1 | - | ⏳ 未着手 |
| Phase 1 PoC | 4 | - | ⏳ 未着手 |
| Phase 2-3 実装 | 8 | - | ⏳ 未着手 |
| Phase 4-6 実装 | 12 | - | ⏳ 未着手 |
| Phase 7-9 実装 | 6 | - | ⏳ 未着手 |
| テスト・検証 | 7 | - | ⏳ 未着手 |
| ドキュメント | 4 | - | ⏳ 未着手 |
| CI/CD統合 | 6 | - | ⏳ 未着手 |
| **Windows合計** | **48人日** | - | - |

### プロジェクト全体

**合計工数:** 85人日（約4ヶ月、1名換算）  
**推奨体制:** 2名 × 2.5ヶ月

---

## 参考資料

### 公式ドキュメント

- [Ansible Documentation](https://docs.ansible.com/)
- [ansible.windows Collection](https://docs.ansible.com/ansible/latest/collections/ansible/windows/)
- [community.windows Collection](https://docs.ansible.com/ansible/latest/collections/community/windows/)
- [Packer Documentation](https://www.packer.io/docs)

### ベストプラクティス

- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Windows Automation with Ansible](https://www.ansible.com/blog/windows-automation)
- [Managing Windows with Ansible](https://docs.ansible.com/ansible/latest/user_guide/windows.html)

### サンプルリポジトリ

- [ansible-examples](https://github.com/ansible/ansible-examples)
- [windows-ansible-example](https://github.com/ansible/windows-ansible-example)

---

## 付録

### A. Packerとの機能比較表

| 機能 | Packer | Ansible | 備考 |
|------|--------|---------|------|
| イメージ作成 | ◎ | ○ | Ansibleは外部ツールと連携 |
| べき等性 | × | ◎ | Ansibleの主要な強み |
| 部分実行 | × | ◎ | タグ・ロール単位で可能 |
| デバッグ | △ | ◎ | 失敗箇所から再開可能 |
| マルチクラウド | ◎ | ○ | 両方とも対応 |
| 学習曲線 | 緩やか | やや急 | Ansibleの方が概念多い |
| エコシステム | 中規模 | 大規模 | Ansibleはモジュール豊富 |
| 既存VM更新 | × | ◎ | Ansibleの主要ユースケース |

### B. 用語集

- **べき等性 (Idempotency):** 同じ操作を何度実行しても同じ結果になる性質
- **ロール (Role):** Ansibleにおける再利用可能な構成単位
- **プレイブック (Playbook):** Ansibleの実行スクリプト（YAML形式）
- **インベントリ (Inventory):** 管理対象ホストのリスト
- **モジュール (Module):** Ansibleの基本的な実行単位（ファイル操作、パッケージ管理等）
- **タスク (Task):** モジュールの実行定義
- **ハンドラ (Handler):** 変更があった場合のみ実行される特殊なタスク
- **Fact:** ターゲットホストから自動収集される情報

### C. トラブルシューティングコマンド

```bash
# 構文チェック
ansible-playbook playbooks/ubuntu2404.yml --syntax-check

# Dry-run実行（変更なし）
ansible-playbook playbooks/ubuntu2404.yml --check

# 差分表示
ansible-playbook playbooks/ubuntu2404.yml --check --diff

# デバッグモード
ansible-playbook playbooks/ubuntu2404.yml -vvv

# 特定のロールのみ実行
ansible-playbook playbooks/ubuntu2404.yml --tags "system_base"

# 特定のロールをスキップ
ansible-playbook playbooks/ubuntu2404.yml --skip-tags "development_tools"

# 特定のホストのみ実行
ansible-playbook playbooks/ubuntu2404.yml --limit "ubuntu2404-build-01"

# ステップ実行（各タスクで確認）
ansible-playbook playbooks/ubuntu2404.yml --step
```

---

**文書バージョン:** 1.0  
**最終更新:** 2025年10月17日  
**作成者:** GitHub Copilot (Claude Sonnet 4.5)
