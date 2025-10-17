# Ubuntu 24.04 Ansible Playbook

このディレクトリには、Ubuntu 24.04 GitHub Actions Runnerイメージを構築するためのAnsible Playbookが含まれています。

## 📁 ディレクトリ構造

```
ansible-ubuntu2404/
├── ansible.cfg                     # Ansible設定ファイル
├── requirements.yml                # 必要なAnsibleコレクション
├── inventories/                    # インベントリファイル
│   ├── production/
│   │   ├── hosts.yml              # 本番環境ホスト定義
│   │   └── group_vars/
│   │       └── ubuntu2404.yml     # Ubuntu 24.04固有の変数
│   └── staging/
│       └── hosts.yml              # ステージング環境ホスト定義
├── playbooks/
│   └── ubuntu2404.yml             # メインプレイブック
├── roles/                          # Ansibleロール
│   ├── system_base/               # Phase 1: ベースシステム設定
│   ├── microsoft_repos/           # Phase 2: Microsoftリポジトリ
│   ├── powershell/                # Phase 3: PowerShell
│   ├── development_tools/         # Phase 4: 開発ツール (50+ tools)
│   ├── container_tools/           # Phase 5: Docker
│   ├── toolset_configuration/     # Phase 6: ツールセット設定
│   ├── post_install/              # Phase 7: 後処理・再起動
│   └── validation/                # Phase 8: テスト・検証
├── group_vars/
│   ├── all.yml                    # 全ホスト共通変数
│   └── ubuntu.yml                 # Ubuntu固有変数
└── templates/                      # テンプレートファイル
```

## 🚀 クイックスタート

### 1. 前提条件

- Ansible >= 2.14
- Python >= 3.9
- ターゲットVM: Ubuntu 24.04 LTS
- SSH接続可能な環境

### 2. セットアップ

```bash
# Ansibleのインストール
python3 -m pip install ansible

# 必要なコレクションのインストール
cd ansible-ubuntu2404
ansible-galaxy collection install -r requirements.yml
```

### 3. インベントリの設定

`inventories/production/hosts.yml`を編集:

```yaml
ubuntu2404_builders:
  hosts:
    ubuntu2404-build-01:
      ansible_host: YOUR_VM_IP
      ansible_user: YOUR_USERNAME
      ansible_ssh_private_key_file: ~/.ssh/YOUR_KEY
```

### 4. 実行

```bash
# 構文チェック
ansible-playbook playbooks/ubuntu2404.yml --syntax-check

# Dry-run実行（変更なし）
ansible-playbook playbooks/ubuntu2404.yml --check

# 実際に実行
ansible-playbook playbooks/ubuntu2404.yml

# 特定のロールのみ実行
ansible-playbook playbooks/ubuntu2404.yml --tags "system_base,powershell"

# 特定のロールをスキップ
ansible-playbook playbooks/ubuntu2404.yml --skip-tags "development_tools"
```

## 🏗️ ロール詳細

### Phase 1: system_base
- ディレクトリ構造の作成
- ヘルパースクリプトの配置
- ビルドスクリプトの配置
- toolset.jsonの配置

### Phase 2: microsoft_repos
- Microsoft APTリポジトリの追加
- APTソースの最適化
- イメージメタデータの設定

### Phase 3: powershell
- PowerShell Coreのインストール
- PowerShellモジュールのインストール
- Azure PowerShellモジュールのインストール

### Phase 4: development_tools
**最大のロール - 50以上のツールをインストール:**
- Cloud & Container: Azure CLI, AWS Tools, Kubernetes
- Compilers: Clang, GCC, Swift, CMake
- Languages: Java, Ruby, Rust, PHP, Python, Node.js, Go
- Databases: MySQL, PostgreSQL
- Web & Browsers: Chrome, Firefox, Edge, Selenium
- Build Tools: Bazel, Packer, Vcpkg, Ninja
- Misc: Git, GitHub CLI, Android SDK, .NET SDK

### Phase 5: container_tools
- Dockerのインストールと設定
- Docker Composeのインストール

### Phase 6: toolset_configuration
- Python/Node.js/Ruby/Goのバージョン管理
- pipxパッケージのインストール

### Phase 7: post_install
- Homebrewのインストール
- Snap設定
- システム再起動
- クリーンアップ

### Phase 8: validation
- ソフトウェアレポート生成
- テスト実行
- システム最終設定
- waagent deprovision (Azure環境)

## 📊 推定実行時間

| Phase | 推定時間 |
|-------|---------|
| Phase 1-3 | 15分 |
| Phase 4 | 60-90分 |
| Phase 5-6 | 20分 |
| Phase 7 | 10分 (+ 再起動) |
| Phase 8 | 10分 |
| **合計** | **2-3時間** |

## 🔧 カスタマイズ

### 変数のオーバーライド

`group_vars/ubuntu.yml`で定義されている変数を上書き:

```bash
ansible-playbook playbooks/ubuntu2404.yml \
  -e "image_version=20251017.2" \
  -e "nodejs_default=22"
```

### タグを使った部分実行

```bash
# 開発ツールのみインストール
ansible-playbook playbooks/ubuntu2404.yml --tags "development_tools"

# 言語系ツールのみ
ansible-playbook playbooks/ubuntu2404.yml --tags "languages"

# データベースのみスキップ
ansible-playbook playbooks/ubuntu2404.yml --skip-tags "databases"
```

### 並列実行の調整

`ansible.cfg`の`forks`を調整:

```ini
[defaults]
forks = 10  # デフォルトは5
```

## 🧪 テスト

### 構文チェック
```bash
ansible-playbook playbooks/ubuntu2404.yml --syntax-check
```

### Dry-run
```bash
ansible-playbook playbooks/ubuntu2404.yml --check --diff
```

### デバッグモード
```bash
ansible-playbook playbooks/ubuntu2404.yml -vvv
```

## 📦 出力

実行後、以下のファイルが生成されます:

- `./outputs/Ubuntu2404-Readme.md` - ソフトウェアレポート (Markdown)
- `./outputs/software-report.json` - ソフトウェアレポート (JSON)
- ターゲットVM上の`/imagegeneration/tests/testResults.xml` - テスト結果

## 🔒 セキュリティ

### パスワードの暗号化

```bash
# 変数を暗号化
ansible-vault encrypt_string 'your_password' --name 'ansible_become_password'

# ファイル全体を暗号化
ansible-vault encrypt group_vars/ubuntu.yml

# 実行時に復号化
ansible-playbook playbooks/ubuntu2404.yml --ask-vault-pass
```

## 🐛 トラブルシューティング

### APTロック競合
```bash
# タスクにリトライ設定を追加済み
# エラーが続く場合は手動でロックを解除:
sudo rm /var/lib/apt/lists/lock
sudo rm /var/cache/apt/archives/lock
sudo rm /var/lib/dpkg/lock*
```

### SSH接続失敗
```bash
# 接続テスト
ansible ubuntu2404_builders -m ping

# 詳細ログ
ansible ubuntu2404_builders -m ping -vvv
```

### 再起動後の接続失敗
`post_reboot_delay`を増やす (デフォルト: 300秒):

```yaml
# roles/post_install/tasks/main.yml
post_reboot_delay: 600  # 10分に延長
```

## 📚 関連ドキュメント

- [Ansible Documentation](https://docs.ansible.com/)
- [Packer to Ansible Migration Plan](../../docs/ansible-migration.md)
- [Original Packer Template](../../images/ubuntu/templates/build.ubuntu-24_04.pkr.hcl)

## 🤝 コントリビューション

改善提案やバグ報告は、Issueまたはプルリクエストでお願いします。

## 📝 ライセンス

このプロジェクトは元のリポジトリと同じライセンスに従います。
