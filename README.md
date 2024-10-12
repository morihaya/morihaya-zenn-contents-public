# morihaya-zenn-contents-public

Zennの公開記事を管理するリポジトリです。

## 👤 Author Profile

[zenn.dev/morihaya](https://zenn.dev/morihaya)

## 🚀 How to Use

Zennの公式ドキュメントを参照してください：

- [GitHubリポジトリでZennのコンテンツを管理する](https://zenn.dev/zenn/articles/connect-to-github)
- [Zenn CLIをインストールする](https://zenn.dev/zenn/articles/install-zenn-cli)

### 記事の画像もリポジトリで管理する方法

画像はZennにアップしてそれを参照する方法と、リポジトリ内で管理する方法がある。Zennが壊れても大丈夫なように積極的にリポジトリ内での管理を進めていく。以下のブログが大変参考になった。

[スクリーンショット画像を便利に画像管理する方法](https://zenn.dev/eguchi244_dev/articles/github-zenn-img-mgmt-20230511#%E3%82%B9%E3%82%AF%E3%83%AA%E3%83%BC%E3%83%B3%E3%82%B7%E3%83%A7%E3%83%83%E3%83%88%E7%94%BB%E5%83%8F%E3%82%92%E4%BE%BF%E5%88%A9%E3%81%AB%E7%94%BB%E5%83%8F%E7%AE%A1%E7%90%86%E3%81%99%E3%82%8B%E6%96%B9%E6%B3%95)

上記を参考に[Paste Image](https://marketplace.visualstudio.com/items?itemName=mushan.vscode-paste-image) ExtentionをVSCodeにインストールし、`.vscode/setting.json`へ以下を記述している。

```json
{
    "pasteImage.insertPattern": "${imageSyntaxPrefix}/images/${currentFileNameWithoutExt}/${imageFileName}${imageSyntaxSuffix}",
    "pasteImage.path": "${projectRoot}/images/${currentFileNameWithoutExt}"
}
```

これによって画像をクリップボードにコピーした後に`Command + Alt + v`で記事内に直接貼り付けると、`images/`配下に記事のファイル名のディレクトリが作られて、画像ファイルが配置される。

## 📋 Quick Reference

### Setup

```bash
# プロジェクトをデフォルト設定で初期化
npm init --yes

# zenn-cliを導入
npm install zenn-cli

# zenn-cliをアップデート
npm install zenn-cli@latest

# zen用のディレクトリを作成
npx zenn init
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
