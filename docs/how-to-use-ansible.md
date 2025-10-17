# Ansible Playbook 使用ガイド

Ubuntu 24.04 GitHub Actions Runnerイメージを構築するためのAnsible Playbookの詳細な使用方法です。

**作成日:** 2025年10月17日  
**対象:** Ubuntu 24.04  
**想定読者:** インフラエンジニア、DevOpsエンジニア

---

## 📋 目次

1. [前提条件](#前提条件)
2. [初期セットアップ](#初期セットアップ)
3. [基本的な使い方](#基本的な使い方)
4. [高度な使い方](#高度な使い方)
5. [トラブルシューティング](#トラブルシューティング)
6. [ベストプラクティス](#ベストプラクティス)
7. [FAQ](#faq)

---

## 前提条件

### 必須環境

#### 制御ノード（Ansibleを実行するマシン）
- **OS:** Linux, macOS, WSL2
- **Python:** 3.9以上
- **Ansible:** 2.14以上
- **SSH:** OpenSSH クライアント

#### ターゲットノード（イメージを構築するVM）
- **OS:** Ubuntu 24.04 LTS (新規インストール推奨)
- **メモリ:** 最低8GB、推奨16GB以上
- **ディスク:** 最低100GB、推奨200GB以上
- **CPU:** 最低4コア、推奨8コア以上
- **ネットワーク:** インターネット接続必須（多数のパッケージダウンロード）

#### ネットワーク要件
- 制御ノード → ターゲットノード: SSH (TCP/22)
- ターゲットノード → インターネット: HTTP/HTTPS (TCP/80, 443)

### 推奨スキル
- Linuxコマンドラインの基本操作
- SSH接続の基礎知識
- YAMLファイルの編集経験
- 基本的なAnsibleの知識（推奨）

---

## 初期セットアップ

### ステップ1: Ansibleのインストール

#### macOS
```bash
# Homebrewを使用
brew install ansible

# または pip
python3 -m pip install --user ansible
```

#### Ubuntu/Debian
```bash
# システムパッケージ
sudo apt update
sudo apt install ansible

# または pip (最新版)
python3 -m pip install --user ansible
```

#### RHEL/CentOS/Rocky Linux
```bash
# EPEL有効化後
sudo dnf install ansible

# または pip
python3 -m pip install --user ansible
```

### ステップ2: バージョン確認

```bash
ansible --version
# 出力例:
# ansible [core 2.16.0]
#   python version = 3.11.6
```

**重要:** Ansible 2.14以上であることを確認してください。

### ステップ3: 必要なコレクションのインストール

```bash
cd /path/to/virtual-environments/ansible-ubuntu2404

# 必要なコレクションをインストール
ansible-galaxy collection install -r requirements.yml

# インストール確認
ansible-galaxy collection list
```

**インストールされるコレクション:**
- `ansible.posix` (>= 1.5.0) - POSIX系システム用モジュール
- `community.general` (>= 8.0.0) - 汎用モジュール集

### ステップ4: ターゲットVMの準備

#### 4.1 Ubuntu 24.04のインストール
- クリーンインストールを推奨
- OpenSSH Serverを必ずインストール
- ユーザーアカウント作成（例: `azureuser`, `ubuntu`）

#### 4.2 SSH設定

**ターゲットVM側:**
```bash
# SSH接続確認
sudo systemctl status ssh
sudo systemctl enable ssh
sudo systemctl start ssh

# ファイアウォール設定（UFWを使用している場合）
sudo ufw allow 22/tcp
```

**制御ノード側:**
```bash
# SSH鍵生成（まだない場合）
ssh-keygen -t ed25519 -C "ansible-build-key"

# 公開鍵をターゲットVMにコピー
ssh-copy-id -i ~/.ssh/id_ed25519.pub azureuser@TARGET_VM_IP

# 接続テスト
ssh azureuser@TARGET_VM_IP
```

#### 4.3 sudo設定

ターゲットVM上で、パスワードなしsudoを設定（推奨）:

```bash
# visudoで編集
sudo visudo

# 以下を追加（azureuserを実際のユーザー名に置き換え）
azureuser ALL=(ALL) NOPASSWD:ALL
```

---

## 基本的な使い方

### ステップ1: インベントリの設定

`inventories/production/hosts.yml`を編集:

```bash
cd /path/to/virtual-environments/ansible-ubuntu2404
vim inventories/production/hosts.yml
```

```yaml
---
all:
  children:
    ubuntu:
      children:
        ubuntu2404_builders:
          hosts:
            ubuntu2404-build-01:
              ansible_host: 192.168.1.100          # ← 実際のIPに変更
              ansible_user: azureuser               # ← 実際のユーザー名に変更
              ansible_ssh_private_key_file: ~/.ssh/id_ed25519  # ← 実際の鍵パスに変更
              ansible_become_method: sudo
```

**重要なパラメータ:**
- `ansible_host`: ターゲットVMのIPアドレスまたはホスト名
- `ansible_user`: SSH接続用ユーザー名
- `ansible_ssh_private_key_file`: SSH秘密鍵のパス
- `ansible_become_method`: 権限昇格方法（通常は`sudo`）

### ステップ2: 接続確認

```bash
# Pingテスト
ansible ubuntu2404_builders -m ping

# 期待される出力:
# ubuntu2404-build-01 | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }
```

**エラーが出た場合:**
- SSH接続が可能か確認: `ssh azureuser@192.168.1.100`
- ホスト名、IPアドレスが正しいか確認
- SSH鍵のパスが正しいか確認
- ファイアウォール設定を確認

### ステップ3: 構文チェック

```bash
# Playbookの構文をチェック
ansible-playbook playbooks/ubuntu2404.yml --syntax-check

# 期待される出力:
# playbook: playbooks/ubuntu2404.yml
```

### ステップ4: Dry-run実行

実際に変更を加えずにシミュレーション:

```bash
ansible-playbook playbooks/ubuntu2404.yml --check --diff

# --check: 実際には変更しない（Dry-run）
# --diff: 変更される内容を表示
```

**注意:** 一部のタスクはDry-runモードで正しく動作しない場合があります。

### ステップ5: 実際の実行

```bash
# 全フェーズを実行
ansible-playbook playbooks/ubuntu2404.yml

# 実行時間: 約2-3時間
```

**実行中の出力例:**
```
PLAY [Build Ubuntu 24.04 Runner Image] *****************************************

TASK [Gathering Facts] *********************************************************
ok: [ubuntu2404-build-01]

TASK [system_base : Create required directories] ******************************
changed: [ubuntu2404-build-01] => (item=/imagegeneration)
changed: [ubuntu2404-build-01] => (item=/imagegeneration/helpers)
...
```

### ステップ6: 実行結果の確認

実行完了後、以下を確認:

```bash
# ローカルの出力ディレクトリ
ls -lh ./outputs/
# Ubuntu2404-Readme.md
# software-report.json

# ソフトウェアレポートを確認
cat ./outputs/Ubuntu2404-Readme.md

# JSON形式でも確認可能
jq . ./outputs/software-report.json
```

---

## 高度な使い方

### タグを使った部分実行

#### 特定のフェーズのみ実行

```bash
# Phase 1のみ（ベースシステム設定）
ansible-playbook playbooks/ubuntu2404.yml --tags "system_base"

# Phase 3のみ（PowerShell）
ansible-playbook playbooks/ubuntu2404.yml --tags "powershell"

# Phase 4のみ（開発ツール）
ansible-playbook playbooks/ubuntu2404.yml --tags "development_tools"
```

#### 複数のタグを指定

```bash
# PowerShellとDockerのみ
ansible-playbook playbooks/ubuntu2404.yml --tags "powershell,container_tools"

# ベースシステムから検証まで（開発ツールをスキップ）
ansible-playbook playbooks/ubuntu2404.yml --skip-tags "development_tools"
```

#### 利用可能なタグ一覧

| タグ | 対応ロール | 内容 |
|------|----------|------|
| `system_base` | system_base | ディレクトリ・スクリプト配置 |
| `microsoft_repos` | microsoft_repos | Microsoftリポジトリ設定 |
| `powershell` | powershell | PowerShell・モジュール |
| `development_tools` | development_tools | 開発ツール全体 |
| `cloud` | development_tools | クラウドツール（Azure, AWS） |
| `containers` | development_tools | コンテナツール |
| `compilers` | development_tools | コンパイラ（Clang, GCC） |
| `languages` | development_tools | 言語ランタイム |
| `databases` | development_tools | データベース |
| `web` | development_tools | Webサーバー |
| `browsers` | development_tools | ブラウザ |
| `build_tools` | development_tools | ビルドツール |
| `misc` | development_tools | その他ツール |
| `container_tools` | container_tools | Docker |
| `toolset_configuration` | toolset_configuration | ツールセット設定 |
| `post_install` | post_install | 後処理・再起動 |
| `validation` | validation | テスト・検証 |

#### カテゴリ別実行の例

```bash
# クラウドツールとコンテナツールのみ
ansible-playbook playbooks/ubuntu2404.yml --tags "cloud,containers"

# 言語ランタイムとデータベースのみ
ansible-playbook playbooks/ubuntu2404.yml --tags "languages,databases"

# Webサーバーとブラウザのみ
ansible-playbook playbooks/ubuntu2404.yml --tags "web,browsers"
```

### 変数のオーバーライド

#### コマンドライン引数で変数を上書き

```bash
# イメージバージョンを指定
ansible-playbook playbooks/ubuntu2404.yml \
  -e "image_version=20251017.2"

# Node.jsのデフォルトバージョンを変更
ansible-playbook playbooks/ubuntu2404.yml \
  -e "nodejs_default=22"

# クラウドプロバイダーを変更
ansible-playbook playbooks/ubuntu2404.yml \
  -e "cloud_provider=aws"

# 複数の変数を同時に指定
ansible-playbook playbooks/ubuntu2404.yml \
  -e "image_version=20251017.2" \
  -e "nodejs_default=22" \
  -e "cloud_provider=aws"
```

#### 変数ファイルで指定

`custom_vars.yml`を作成:
```yaml
---
image_version: "20251017.2"
nodejs_default: "22"
python_versions:
  - "3.11.*"
  - "3.12.*"
  - "3.13.*"
```

実行時に読み込み:
```bash
ansible-playbook playbooks/ubuntu2404.yml -e "@custom_vars.yml"
```

### デバッグモード

#### 詳細ログ出力

```bash
# レベル1: 基本情報
ansible-playbook playbooks/ubuntu2404.yml -v

# レベル2: タスク実行の詳細
ansible-playbook playbooks/ubuntu2404.yml -vv

# レベル3: 接続情報含む
ansible-playbook playbooks/ubuntu2404.yml -vvv

# レベル4: 全詳細（最大）
ansible-playbook playbooks/ubuntu2404.yml -vvvv
```

#### ステップ実行

各タスクで実行確認を行う:
```bash
ansible-playbook playbooks/ubuntu2404.yml --step

# 各タスクで以下の選択肢が表示される:
# Perform task: TASK: system_base : Create required directories (N)o/(y)es/(c)ontinue:
```

#### 特定のタスクから開始

```bash
# タスク名を指定して途中から開始
ansible-playbook playbooks/ubuntu2404.yml --start-at-task="Install PowerShell"
```

### 並列実行の調整

#### Forks数の変更

デフォルトは5並列。複数ホストがある場合に調整:

```bash
# 10並列に増やす
ansible-playbook playbooks/ubuntu2404.yml --forks 10

# または ansible.cfg で設定
# [defaults]
# forks = 10
```

### リミット指定

複数ホストがある場合、特定ホストのみ実行:

```bash
# 特定ホストのみ
ansible-playbook playbooks/ubuntu2404.yml --limit "ubuntu2404-build-01"

# パターンマッチ
ansible-playbook playbooks/ubuntu2404.yml --limit "ubuntu2404-build-*"

# 複数ホスト指定
ansible-playbook playbooks/ubuntu2404.yml --limit "ubuntu2404-build-01,ubuntu2404-build-02"
```

---

## トラブルシューティング

### よくあるエラーと解決方法

#### 1. SSH接続エラー

**エラーメッセージ:**
```
fatal: [ubuntu2404-build-01]: UNREACHABLE! => {
    "changed": false,
    "msg": "Failed to connect to the host via ssh",
    "unreachable": true
}
```

**解決方法:**

```bash
# 1. 手動でSSH接続を確認
ssh -i ~/.ssh/id_ed25519 azureuser@192.168.1.100

# 2. SSH設定をデバッグ
ansible ubuntu2404_builders -m ping -vvv

# 3. known_hostsをクリア（ホストキー変更の場合）
ssh-keygen -R 192.168.1.100

# 4. SSH Agentに鍵を追加
eval $(ssh-agent)
ssh-add ~/.ssh/id_ed25519
```

#### 2. sudo権限エラー

**エラーメッセージ:**
```
fatal: [ubuntu2404-build-01]: FAILED! => {
    "msg": "Missing sudo password"
}
```

**解決方法:**

```bash
# オプション1: パスワードを入力
ansible-playbook playbooks/ubuntu2404.yml --ask-become-pass

# オプション2: sudoersでパスワードなしに設定（推奨）
# ターゲットVM上で:
sudo visudo
# 追加: azureuser ALL=(ALL) NOPASSWD:ALL
```

#### 3. APTロック競合

**エラーメッセージ:**
```
E: Could not get lock /var/lib/dpkg/lock-frontend
```

**解決方法:**

```bash
# ターゲットVM上で実行
sudo killall apt apt-get
sudo rm /var/lib/apt/lists/lock
sudo rm /var/cache/apt/archives/lock
sudo rm /var/lib/dpkg/lock*
sudo dpkg --configure -a
sudo apt update
```

Ansibleでリトライ:
```bash
# 数分待ってから再実行
ansible-playbook playbooks/ubuntu2404.yml --start-at-task="Install vital APT packages"
```

#### 4. ディスク容量不足

**エラーメッセージ:**
```
fatal: [ubuntu2404-build-01]: FAILED! => {
    "msg": "No space left on device"
}
```

**解決方法:**

```bash
# ターゲットVM上でディスク使用量確認
df -h

# 不要なパッケージ削除
sudo apt autoremove
sudo apt clean

# Dockerイメージ・コンテナクリーンアップ
sudo docker system prune -a

# ログファイル削除
sudo journalctl --vacuum-time=3d
```

#### 5. タイムアウトエラー

**エラーメッセージ:**
```
fatal: [ubuntu2404-build-01]: FAILED! => {
    "msg": "Timeout (12s) waiting for privilege escalation prompt"
}
```

**解決方法:**

`ansible.cfg`でタイムアウトを延長:
```ini
[defaults]
timeout = 60
```

または実行時に指定:
```bash
ANSIBLE_TIMEOUT=60 ansible-playbook playbooks/ubuntu2404.yml
```

#### 6. PowerShellスクリプト実行エラー

**エラーメッセージ:**
```
pwsh: command not found
```

**解決方法:**

```bash
# PowerShellロールのみ再実行
ansible-playbook playbooks/ubuntu2404.yml --tags "powershell"

# 手動インストール（ターゲットVM上）
wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
sudo apt install -y powershell
```

#### 7. メモリ不足

**症状:**
- ビルドが途中で停止
- プロセスがKillされる

**解決方法:**

```bash
# ターゲットVMのメモリを確認
free -h

# スワップを追加（緊急対応）
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 永続化
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

**推奨:** VMのメモリを16GB以上に増やす

### ログの確認

#### Ansibleログ

```bash
# 標準出力をファイルに保存
ansible-playbook playbooks/ubuntu2404.yml 2>&1 | tee build.log

# 特定のタスクのログを検索
grep "TASK \[development_tools" build.log

# エラーのみ抽出
grep "fatal\|ERROR\|FAILED" build.log
```

#### ターゲットVM上のログ

```bash
# システムログ
sudo journalctl -xe

# APTログ
cat /var/log/apt/history.log
cat /var/log/apt/term.log

# インストールスクリプトのログ（ある場合）
ls -lh /imagegeneration/*.log
```

### タスク実行時間の確認

`ansible.cfg`で`profile_tasks`と`timer`を有効化済み:

```bash
# 実行後に表示される
ansible-playbook playbooks/ubuntu2404.yml

# 出力例:
# Thursday 17 October 2025  10:45:23 +0900 (0:15:32.456)       0:15:32.456 *****
# ===============================================================================
# development_tools : Install development tools (batch 3) ---------- 932.45s
# development_tools : Install development tools (batch 4) ---------- 567.23s
# ...
```

---

## ベストプラクティス

### 1. バージョン管理

```bash
# 実行前にGitで管理
cd /path/to/virtual-environments
git checkout -b ansible-build-$(date +%Y%m%d)

# 変更をコミット
git add ansible-ubuntu2404/
git commit -m "Ubuntu 24.04 build configuration for $(date +%Y-%m-%d)"
```

### 2. 実行履歴の記録

```bash
# 実行ログを日付付きで保存
ansible-playbook playbooks/ubuntu2404.yml 2>&1 | \
  tee logs/build-$(date +%Y%m%d-%H%M%S).log
```

### 3. Dry-run必須

```bash
# 本番実行前に必ずDry-runを実施
ansible-playbook playbooks/ubuntu2404.yml --check --diff

# 問題なければ本番実行
ansible-playbook playbooks/ubuntu2404.yml
```

### 4. ステージング環境でテスト

```bash
# まずステージング環境で実行
ansible-playbook playbooks/ubuntu2404.yml \
  -i inventories/staging/hosts.yml

# 成功したら本番環境
ansible-playbook playbooks/ubuntu2404.yml \
  -i inventories/production/hosts.yml
```

### 5. 変数の暗号化

パスワードなどの機密情報はAnsible Vaultで暗号化:

```bash
# 新規ファイルを暗号化
ansible-vault create inventories/production/group_vars/vault.yml

# 既存ファイルを暗号化
ansible-vault encrypt inventories/production/group_vars/ubuntu2404.yml

# 暗号化されたファイルを含むPlaybook実行
ansible-playbook playbooks/ubuntu2404.yml --ask-vault-pass

# または Vault パスワードファイルを使用
echo "your_vault_password" > .vault_pass
chmod 600 .vault_pass
ansible-playbook playbooks/ubuntu2404.yml --vault-password-file .vault_pass
```

### 6. エラー時の自動リトライ

`ansible.cfg`に追加:
```ini
[defaults]
retry_files_enabled = True
retry_files_save_path = ./retry
```

失敗時に`.retry`ファイルが生成され、再実行時に失敗したホストのみ実行可能。

### 7. 並列実行の最適化

```bash
# ホストが複数ある場合
ansible-playbook playbooks/ubuntu2404.yml --forks 10

# タスク内での並列実行（async）は既にロールに組み込み済み
```

### 8. 定期的なアップデート

```bash
# Ansibleコレクションを最新化
ansible-galaxy collection install -r requirements.yml --upgrade

# Ansible本体を更新
python3 -m pip install --upgrade ansible
```

---

## FAQ

### Q1: 実行時間を短縮する方法は?

**A:** 以下の方法があります:

1. **不要なツールをスキップ**
   ```bash
   ansible-playbook playbooks/ubuntu2404.yml --skip-tags "browsers,misc"
   ```

2. **Forks数を増やす**（複数ホストの場合）
   ```bash
   ansible-playbook playbooks/ubuntu2404.yml --forks 10
   ```

3. **APTキャッシュプロキシを使用**
   - `apt-cacher-ng`などのキャッシュサーバーを設置
   
4. **並列ダウンロード有効化**
   ターゲットVM上で:
   ```bash
   echo 'Acquire::Queue-Mode "host";' | sudo tee /etc/apt/apt.conf.d/99parallel
   ```

### Q2: 複数のVMに同時実行できる?

**A:** 可能です。インベントリに複数ホストを定義:

```yaml
ubuntu2404_builders:
  hosts:
    ubuntu2404-build-01:
      ansible_host: 192.168.1.100
    ubuntu2404-build-02:
      ansible_host: 192.168.1.101
    ubuntu2404-build-03:
      ansible_host: 192.168.1.102
```

```bash
# 全ホストに対して実行（デフォルト5並列）
ansible-playbook playbooks/ubuntu2404.yml

# 並列度を上げる
ansible-playbook playbooks/ubuntu2404.yml --forks 10
```

### Q3: 特定のソフトウェアバージョンを変更したい

**A:** `group_vars/ubuntu.yml`を編集するか、コマンドラインで指定:

```bash
# Node.jsのバージョンを変更
ansible-playbook playbooks/ubuntu2404.yml \
  -e "nodejs_default=22" \
  -e 'nodejs_versions=["20.*","22.*","23.*"]'

# Pythonのバージョンを限定
ansible-playbook playbooks/ubuntu2404.yml \
  -e 'python_versions=["3.11.*","3.12.*"]'
```

### Q4: エラーで止まった場合、途中から再開できる?

**A:** できます:

```bash
# 特定のタスクから再開
ansible-playbook playbooks/ubuntu2404.yml \
  --start-at-task="Install Docker"

# 特定のロールから再開
ansible-playbook playbooks/ubuntu2404.yml \
  --tags "container_tools,toolset_configuration,post_install,validation"
```

### Q5: ローカルマシン（localhost）で実行できる?

**A:** できますが推奨しません。専用VMの使用を強く推奨します。

どうしても実行する場合:
```yaml
# inventories/local/hosts.yml
all:
  hosts:
    localhost:
      ansible_connection: local
      ansible_python_interpreter: /usr/bin/python3
```

```bash
ansible-playbook playbooks/ubuntu2404.yml -i inventories/local/hosts.yml
```

**警告:** システムに大幅な変更が加わります。

### Q6: Windows上で実行できる?

**A:** WSL2（Windows Subsystem for Linux）を使用すれば可能:

```powershell
# PowerShellで
wsl --install
wsl --set-default-version 2
wsl --install -d Ubuntu-24.04

# WSL内で
sudo apt update
sudo apt install ansible
cd /mnt/c/path/to/virtual-environments/ansible-ubuntu2404
ansible-playbook playbooks/ubuntu2404.yml
```

### Q7: クラウドVM（Azure/AWS/GCP）で実行する際の注意点は?

**A:** 以下に注意:

1. **セキュリティグループ/ネットワークセキュリティグループ**
   - SSH (TCP/22) を制御ノードから許可

2. **インスタンスタイプ/VMサイズ**
   - 最低: 4vCPU, 16GB RAM
   - 推奨: 8vCPU, 32GB RAM
   - ディスク: 200GB以上

3. **コスト**
   - 実行時間: 2-3時間
   - インスタンスを停止し忘れないよう注意

4. **waagent deprovision**
   - Azureの場合、最後に自動実行される
   - 他のクラウドでは`cloud_provider`変数を変更

```bash
ansible-playbook playbooks/ubuntu2404.yml -e "cloud_provider=aws"
```

### Q8: 作成したイメージをどう使う?

**A:** クラウドプロバイダーによって異なります:

**Azure:**
```bash
# VMをシャットダウン
ssh azureuser@TARGET_VM "sudo shutdown -h now"

# Azure CLIでイメージ作成
az vm deallocate --resource-group myRG --name myVM
az vm generalize --resource-group myRG --name myVM
az image create \
  --resource-group myRG \
  --name Ubuntu2404-Runner-20251017 \
  --source myVM
```

**AWS:**
```bash
# EC2インスタンスからAMI作成
aws ec2 create-image \
  --instance-id i-1234567890abcdef0 \
  --name "Ubuntu2404-Runner-20251017" \
  --description "GitHub Actions Runner Ubuntu 24.04"
```

**GCP:**
```bash
# インスタンスからイメージ作成
gcloud compute images create ubuntu2404-runner-20251017 \
  --source-disk=my-instance-disk \
  --source-disk-zone=us-central1-a
```

### Q9: どのくらいの頻度で更新すべき?

**A:** 推奨頻度:

- **月次:** セキュリティアップデート対応
- **四半期:** メジャーバージョンアップデート
- **重大な脆弱性発見時:** 即座に対応

```bash
# 元のPackerリポジトリから最新を取得
cd /path/to/virtual-environments
git fetch upstream
git merge upstream/main

# Ansibleで再構築
cd ansible-ubuntu2404
ansible-playbook playbooks/ubuntu2404.yml -e "image_version=$(date +%Y%m%d).1"
```

### Q10: カスタムスクリプトを追加したい

**A:** 新しいロールを作成するか、既存ロールに追加:

**方法1: 新しいロールを作成**
```bash
mkdir -p roles/custom_tools/tasks
cat > roles/custom_tools/tasks/main.yml << 'EOF'
---
- name: Install custom tool
  ansible.builtin.apt:
    name: mytool
    state: present
  become: yes
EOF

# playbooks/ubuntu2404.yml に追加
# roles:
#   ...
#   - role: custom_tools
#     tags: ['custom']
```

**方法2: 既存ロールに追加**
```bash
# roles/development_tools/tasks/main.yml に追加
vim roles/development_tools/tasks/main.yml
```

---

## サポート

### 問題が解決しない場合

1. **ログを確認**
   ```bash
   ansible-playbook playbooks/ubuntu2404.yml -vvv 2>&1 | tee debug.log
   ```

2. **Issue作成**
   - リポジトリにIssueを作成
   - エラーメッセージ全文を添付
   - 実行環境の情報を記載

3. **ドキュメント参照**
   - [Ansible公式ドキュメント](https://docs.ansible.com/)
   - [移行計画書](./ansible-migration.md)

---

## 関連リンク

- **プロジェクト:** [tfsugjp/virtual-environments](https://github.com/tfsugjp/virtual-environments)
- **元のPacker定義:** `images/ubuntu/templates/build.ubuntu-24_04.pkr.hcl`
- **Ansible移行計画:** `docs/ansible-migration.md`
- **README:** `ansible-ubuntu2404/README.md`

---

**最終更新:** 2025年10月17日  
**バージョン:** 1.0  
**メンテナー:** GitHub Copilot (Claude Sonnet 4.5)
