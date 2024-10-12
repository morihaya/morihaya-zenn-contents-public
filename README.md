# morihaya-zenn-contents-public

Zennの公開記事を管理するリポジトリです。

## 👤 Author Profile

[zenn.dev/morihaya](https://zenn.dev/morihaya)

## 🚀 How to Use

Zennの公式ドキュメントを参照してください：

- [GitHubリポジトリでZennのコンテンツを管理する](https://zenn.dev/zenn/articles/connect-to-github)
- [Zenn CLIをインストールする](https://zenn.dev/zenn/articles/install-zenn-cli)

## 📋 Quick Reference

### Setup

```bash
# プロジェクトをデフォルト設定で初期化
npm init --yes

# zenn-cliを導入
npm install zenn-cli

# zenn-cliをアップデート
npm install zenn-cli@latest
```

### Operations

```bash
# 新しい記事を作成する
npx zenn new:article

# 新しい本を作成する
npx zenn new:book

# 投稿をプレビューする
npx zenn preview
```

## 📁 Directory Structure

```shell
.
├── articles/     # 記事用のディレクトリ
├── books/        # 本用のディレクトリ
└── images/       # 画像用のディレクトリ
```
