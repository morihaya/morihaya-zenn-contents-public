---
title: "GitHub Copilot Coding AgentでCODEOWNERSファイルを複数リポジトリに一気に配置した方法と課題"
emoji: "📺"
type: "tech" # tech or idea
topics:
  - github
  - githubcopilot
  - python
  - aeon
published: false # false OR true , スケジュール公開の場合はfalseで予約して後からtrueにFix必要
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林aka[もりはや](https://twitter.com/morihaya55)です。
当社は各種サービスのプログラムソースコードをVCSで管理しています。従来はAzure DevOps Repos(以降はADO)を中心に利用してきましたが、直近では少しずつGitHubへ移行を進めています。

本記事ではADOからGitHubへ移行が終わった数十のリポジトリに対して、レビュワーへSREチームを自動でアサインするための[CODEOWNERSファイル](https://docs.github.com/ja/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)を配置するチーム要件に対し、GitHub Copilot Coding Agentを利用して手作業を減らした取り組みについて紹介します。

なおタイトルにあるとおり"良かったところ"だけではなく"課題"と感じたことにについても記載します。大前提としてGitHub Copilot Coding Agentによる自動化は私にとって素晴らしい体験だったことは明記します。

## TL;DR

本記事を4行に要約すると以下です。

- ADOからGitHubへの移行後、CIの変更やCODEOWNERSファイルを配置したい
- 手動でやるにはリポジトリの数が数十あり大変
- GitHub Copilot Coding Agentに任せた体験は素晴らしかったが、課題もあった
- 課題としてIssueの作成までは自動化できたが、”レビュー”と”Copilotのアサイン”は自動化できなかった
  - なお後日”Copilotのアサイン”の課題は解決できたので方法を記載しています

## GitHubへの移行の背景

冒頭でも触れましたが、当社はADOからGitHubへの移行を進めています。
もっとも大きな理由はGitHub CopilotのAIサービス群です。

ADOはVCSとして優れたサービスですが、めまぐるしいAI機能の進化の恩恵を受けられるのはGitHubであり、今後は可能な限りそちらを利用したいと考えています。
＊ただし、既存のCIや権限制御、ユーザ管理など移行タイミングは十分に検討する必要があります

移行手段はGitHub CLIの拡張機能で”GitHub Enterprise Importer”とも呼ばれる[ADO2GH extension](https://docs.github.com/en/enterprise-cloud@latest/migrations/using-github-enterprise-importer/migrating-from-azure-devops-to-github-enterprise-cloud/migrating-repositories-from-azure-devops-to-github-enterprise-cloud)を利用しています。適切な権限のクレデンシャルをADOとGitHubそれぞれから払い出して環境変数に設定し、コマンドを実行するだけで簡単に移行できる優れたツールです。


ADO2GH extensionを利用すると以下のようなコマンドでADOリポジトリ内のファイル群だけでなく、PullRequestの履歴なども綺麗に移行してくれるため、手動による`git clone ...`, `git remot add github ...`, `git push`といった方法に比べて移行できるデータが多く重宝しています。

（例：GitHub CLIを利用したADOからGitHubへの移行コマンド）

```bash
$ gh ado2gh migrate-repo --ado-org "<ADO_ORG_NAME>" --ado-team-project "<ADO_PROJECT_NAME>" --ado-repo "<ADO_REPO_NAME>" --github-org "<GITHUB_ORG_NAME>" --github-repo "<GITHUB_REPO_NAME>" --queue-only --target-repo-visibility internal
```

なお参考として、SREチームで最も利用頻度が高いPR数が1,000を超えるリポジトリでは、およそ30分弱で移行が完了しました。

## 移行ツールだけでは完了しない

ツールによってコードやPRは移行されますが、それだけでは完了と言えません。
ツールによる処理が完了した後、いくつか必要になる作業例を挙げると以下になります。

- ブランチプロテクトルールの追加
- 適切なユーザ・チームの権限設定
- READMEファイルの修正（文言の修正、バッジ追加など）
- GitHub Actions用のCIを追加
- 自動のレビュワーアサインのためのCODEOWNERSファイルの配置

この中で最後のCODEOWNERSファイルは、ブランチプロテクトや権限設定に比べると優先度は下がるため、後回しとなっていた状態でした。

## CODEOWNERSファイルについて

[CODEOWNERSファイル](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)は、リポジトリ内の特定のファイルやディレクトリに対して、レビュアーを自動的にアサインする機能を持ちます。
移行前のADOでは[Branch policies](https://learn.microsoft.com/en-us/azure/devops/repos/git/branch-policies)機能によって自動アサインを実現していましたが、GitHubで行うにはCODEOWNERSファイルの配置が必要です。

具体的には `./github/CODEOWNERS` へ以下のようなテキストを配置します。

```txt
# SREチームをコードオーナーとし、自動でレビュワーとしてアサインする
*   @<ORGNAME>/sre
```

このファイルを配置することは単純な作業ですが、数十リポジトリに同様のCODEOWNERSファイルを配置するのは手間がかかります。

従来の私であればCLIを用いて対象リポジトリ一括cloneし、ちょっとしたシェル芸で一気にPull Requestを作成するところでしたが、今後の検証もかねてGitHub Copilot Coding Agentを利用することにしました。

## GitHub Copilot Coding Agentとは

[GitHub Copilot Coding Agent](https://github.blog/jp/2025-05-20-github-copilot-meet-the-new-coding-agent/)は、GitHub Copilot Enterpriseの機能の1つで、作成したIssueへCopilotをアサインすることで、自然言語での指示をもとにコードを生成、実行、修正してPullRequestまで作成してくれるAIアシスタントです。

VSCodeのような手元のエディタで動作するGitHub Copilot agent modeが”ペアプログラミングの頼もしい相棒”であるなら、
GitHub Copilot Coding Agentは”適切な範囲の指示をIssueとして与えることで爆速に対応してくれるチームの優秀な同僚”といったところでしょう。

## 複数リポジトリへのCODEOWNERS配置をGitHub Copilot Coding Agentで行う

さていよいよ本題です。

### 要件整理

改めて要件を整理すると以下の通りです。

1. 特定のOrganizationの複数リポジトリ（数十個）に対して操作を行う
2. 各リポジトリにCODEOWNERSファイルを作成する
3. CODEOWNERSファイルの内容は基本的に同じ（SREチームをオーナーに設定）
4. GitHub Copilot Coding Agentに任せるためにIssueを作成する
5. 作成したIssueをCopilotにアサインする
6. CopilotのPRをレビューしてマージする

### Issueを複数リポジトリにまとめて作成するスクリプトの作成

上述した要件のうち、6のレビューとマージを除いた1-5の工程は自動化したいと考えました。
GitHubには豊富なAPIが存在するため、手元のVSCodeを開きCopilot agent modeで以下のように指示しました。
（実際には何回かに分けて調整しましたが、大した内容ではないため完成品から逆生成したプロンプトを記載しています。）

長いためトグルに隠しておきます。

:::details GitHubで複数リポジトリに同一のIssueを作成するスクリプト作成プロンプト

# GitHubで複数リポジトリに同一のIssueを作成するスクリプト作成プロンプト

以下の要件を持つPythonスクリプトを作成してください：

## 要件

- 指定した複数のGitHubリポジトリに同じ内容のIssueを一括作成する
- GitHubトークンは環境変数から取得する
- Issueのタイトルと本文は外部ファイルから読み込めるようにする
- 外部ファイルが存在しない場合はデフォルト値を使用する
- Issueのアサイン先をオプションで指定できるようにする

## スクリプト仕様

- ファイル名: create-multi-issues.py
- 使用ライブラリ: PyGithub
- 環境変数:
  - GITHUB_TOKEN: GitHub APIアクセス用トークン（必須）
  - GITHUB_ASSIGNEE: Issueのアサイン先ユーザー名（任意）
- コマンドライン引数: カンマ区切りのリポジトリ名（owner/repo形式）
- 外部設定ファイル:
  - issue_header.txt: Issue タイトル
  - issue_body.txt: Issue 本文
  - サンプルファイルとして issue_header.sample.txt と issue_body.sample.txt も作成

## 動作の流れ

- 環境変数からGitHubトークンを取得
- 外部ファイルからIssueタイトルと本文を読み込み（ない場合はデフォルト値を使用）
- コマンドライン引数から処理対象リポジトリのリストを取得
- 各リポジトリに対して同じIssueを作成
- 作成結果を標準出力に表示

## エラー処理

- GitHubトークンが未設定の場合はエラーメッセージを表示して終了
- リポジトリへのアクセスエラーやIssue作成エラーは個別に表示し、処理は継続

## 実行例

```sh
# 基本的な使い方
GITHUB_TOKEN=your_token python create-multi-issues.py owner1/repo1,owner2/repo2

# アサイン先を指定する場合
GITHUB_TOKEN=your_token GITHUB_ASSIGNEE=username python create-multi-issues.py owner1/repo1,owner2/repo2
```

コード内にはエラー処理や動作確認のためのログ出力を適切に含めてください。
:::

### 作成されたスクリプト（未完成版）

こうしてできたのが以下のPythonスクリプトと外部ファイルです。
後述するようにCopilotを自動的にアサインすることはできていません。

:::details create-multi-issues.py (未完成版)

```python
from github import Github
import sys
import os

# GitHubアクセストークンを環境変数から取得
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")
if not GITHUB_TOKEN:
    print("Error: GITHUB_TOKEN environment variable is not set")
    sys.exit(1)

# ファイルから内容を読み込む関数
def read_file_content(file_path):
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            return f.read().strip()
    except FileNotFoundError:
        return None

# コマンドライン引数からカンマ区切りのリポジトリ名を取得
if len(sys.argv) < 1:
    print("Usage: python create_issues.py owner1/repo1,owner2/repo2")
    sys.exit(1)

repo_names = sys.argv[1].split(',')

# 実行ディレクトリのパスを取得
script_dir = os.path.dirname(os.path.abspath(__file__))

# Issueの件名と本文をファイルから読み込む
header_file = os.path.join(script_dir, "issue_header.txt")
body_file = os.path.join(script_dir, "issue_body.txt")

# ファイルがない場合はサンプルファイルの内容をデフォルト値として使用
default_issue_title = "Copilotのアサイン確認テスト"
default_issue_body = """
これはテスト用のIssueです。
Copilotがアサインされていることを確認してください。
"""

# ファイルから読み込むか、デフォルト値を使用
issue_title = read_file_content(header_file) or default_issue_title
issue_body = read_file_content(body_file) or default_issue_body

print(f"Using issue title: {issue_title}")
print(f"Using issue body file: {body_file if os.path.exists(body_file) else '(default)'}")

# アサインするユーザー名を環境変数から取得（指定がなければアサインしない）
assignee_username = os.environ.get("GITHUB_ASSIGNEE")

g = Github(GITHUB_TOKEN)

for repo_name in repo_names:
    try:
        repo = g.get_repo(repo_name.strip())
        # アサイン先が設定されている場合のみアサインする
        if assignee_username:
            issue = repo.create_issue(
                title=issue_title,
                body=issue_body,
                assignee=assignee_username
            )
        else:
            issue = repo.create_issue(
                title=issue_title,
                body=issue_body
            )
        print(f"Created issue in {repo_name}: {issue.html_url}")
    except Exception as e:
        print(f"Failed to create issue in {repo_name}: {e}")
```
:::

外部ファイルとしてヘッダーと本文のファイルがあり、以下のようになっています。

#### issue_header.txt

```txt
JIRAKEY-266 自動でSREチームをレビュワーにするためのCODEOWNERSファイルの追加
```

#### issue_body.txt

```txt
以下のCODEOWNERSを .github の配下に作成してください。最終行には必ず改行をいれてください。

---txt
# SREチームをコードオーナーとし、自動でレビュワーとしてアサインする
*   @<ORG_NAME>/sre
---

```

## 実行過程と課題

このスクリプトを実行する過程で、いくつかの課題が見つかりました。

### 良かった点

良かった点として、スクリプトを実行することで目的であった複数のリポジトリへIssueをまとめて作成することができました。
指定した数十のリポジトリに数秒でIssueが作成されたのを確認したときは大変気持ちの良いものでした。

### 課題

一方で以下の課題も見つかりました。それぞれ説明します。

- 結局PRを人間がレビューする必要がある
- REST APIではCopilotを直接アサインできない

#### 課題: 結局PRを人間がレビューする必要がある

前提として、これはGitHub Copilot Coding Agent固有ではなくAIを用いた作業全般に言えることです。

例え同じ内容のIssueであっても、GitHub Copilot Coding Agentが行った作業結果については、人間が責任を持ってレビューする必要があります。

結論から言えば今回のようなシンプルなタスクにおいては、同じプロンプトで作成した数十のIssueに対してGitHub Copilot Coding Agentはすべて期待していた更新内容でPRを作成しており、私は修正を一切せずにマージボタンを押すだけでした。

しかしながら生成AIにおいてハルシネーションの可能性を無視することはできず、繰り返しになりますが最後は人間が見て責任を持って受け入れる必要があります。
（これはどんな優秀な人間であってもミスするときはするのと同じです）

複数のリポジトリでレビューとApproveとMergeボタンをひたすら押し続けながら「CLIでやった方が楽では...?」と感じたのは事実です。

#### 課題: CopilotをREST APIでは直接Issueへアサインできない

もう1つの課題はREST APIの仕様です。
上述したスクリプトでは以下のように`assignee`としてIssue作成時にアサインをできるようにしています。

```python
        if assignee_username:
            issue = repo.create_issue(
                title=issue_title,
                body=issue_body,
                assignee=assignee_username
            )
```

これはassigneeがユーザである場合は問題なく動作します。

しかしながら現状、CopilotをREST APIで`create_issue`を利用して直接アサインすることはできず、以下のようなエラーが発生します。

> $ python create-multi-issues.py <OrgName>/sandbox-morihaya
Using issue title: JIRAKEY-266 自動でSREチームをレビュワーにするためのCODEOWNERSファイルの追加
Using issue body file: /Users/morihaya/ghq/(省略)/issue_body.txt
Failed to create issue in <OrgName>/sandbox-morihaya: 422 {"message": "Validation Failed", "errors": [{"value": "copilot-swe-agent", "resource": "Issue", "field": "assignee", "code": "invalid"}], "documentation_url": "https://docs.github.com/rest/issues/issues#create-an-issue", "status": "422"}

私はこのエラーをその場ですぐに解決できず、Web画面から手作業でCopilotをアサインしました。
本来の目的であったCODEOWNERSファイルの配置を早々に行いたいことと、
結局はCopilotが作成したPRを自身でレビューする必要もあるためです。

しかしリポジトリを1つずつ開き、Issueを参照しCopilotをアサインしていく作業はToil以外の何者でもなく、本ブログ執筆を機会に解決してやろうと強く決心しました。

##### GraphQLの方法であれば直接Copilotをアサインが可能

そして本記事を書きながら無事に解決することができました。

後からわかったこととして、GitHubドキュメント[Assigning an issue to Copilot](https://docs.github.com/en/copilot/using-github-copilot/coding-agent/using-copilot-to-work-on-an-issue#assigning-an-issue-to-copilot)によると、Copilotをアサインする方法は以下の4通りです。現状はREST APIは含まれていません。

- GitHubのWeb画面
- GitHubのモバイルアプリ
- GraphQLの利用
- GitHub CLI

上記の選択肢のうち、Pythonのようなスクリプトを利用する場合はGraphQLが選択肢となるでしょう。
ドキュメントのGraphQLのサンプルによると、以下のようにIssue番号とCopilotの番号を指定する必要があります。

```sql
mutation {
  replaceActorsForAssignable(input: {assignableId: "ISSUE_ID", assigneeIds: ["BOT_ID"]}) {
    assignable {
      ... on Issue {
        id
        title
        assignees(first: 10) {
          nodes {
            login
          }
        }
      }
    }
  }
}
```

Issue番号もリポジトリ内の番号ではなくGlobal IDと呼ばれるものが必要で、以下のようにIssue番号を用いて取得します。

```sql
query {
  repository(owner: "<OWNER_NAME>>", name: "<REPO_NAME>") {
    issue(number: <ISSUE_NO>) {
      id
      title
    }
  }
}
```

この仕様を踏まえた上で、完成版として複数リポジトリへIssueの作成からCopilotの自動アサインまで可能としたのが以下のスクリプトです。
Issue作成までの処理は未完成版としたREST APIの処理を維持しつつ、以下の機能を追加しています。

- GraphQLで作成したIssueのGlobal IDを取得
- GraphQLでCopilotのBot IDを取得
- GraphQLでIssueへCopilotをアサイン

:::details create-multi-issues.py (完成版)
```python
from github import Github
import sys
import os
import requests
import json

# GitHubアクセストークンを環境変数から取得
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")
if not GITHUB_TOKEN:
    print("Error: GITHUB_TOKEN environment variable is not set")
    sys.exit(1)

# GraphQLエンドポイント
GRAPHQL_URL = "https://api.github.com/graphql"

# GraphQL APIリクエスト用のヘッダー
HEADERS = {
    "Authorization": f"Bearer {GITHUB_TOKEN}",
    "Content-Type": "application/json",
    "Accept": "application/vnd.github+json"
}

# GraphQL APIを呼び出す関数
def execute_graphql(query, variables=None):
    payload = {"query": query}
    if variables:
        payload["variables"] = variables

    response = requests.post(
        GRAPHQL_URL,
        headers=HEADERS,
        json=payload
    )

    if response.status_code != 200:
        raise Exception(f"GraphQL API request failed: {response.status_code} - {response.text}")

    data = response.json()
    if "errors" in data:
        raise Exception(f"GraphQL errors: {data['errors']}")

    return data

# copilot-swe-agent のIDを取得する関数
def get_copilot_id(repo_owner, repo_name):
    # copilot-swe-agent のIDを取得するGraphQLクエリ
    query = """
    query GetCopilotId($owner: String!, $name: String!) {
      repository(owner: $owner, name: $name) {
        suggestedActors(capabilities: [CAN_BE_ASSIGNED], first: 100) {
          nodes {
            login
            __typename
            ... on User {
              id
            }
            ... on Bot {
              id
            }
            ... on Mannequin {
              id
            }
            ... on Organization {
              id
            }
          }
        }
      }
    }
    """

    variables = {
        "owner": repo_owner,
        "name": repo_name
    }

    try:
        data = execute_graphql(query, variables)
        actors = data.get("data", {}).get("repository", {}).get("suggestedActors", {}).get("nodes", [])

        for actor in actors:
            if actor.get("login") == "copilot-swe-agent":
                print(f"Found copilot-swe-agent with ID: {actor['id']}")
                return actor["id"]

        print("Warning: copilot-swe-agent not found in suggested actors")
        return None
    except Exception as e:
        print(f"Error retrieving copilot-swe-agent ID: {e}")
        return None

# Issueの現在のアサイン担当者（ID）を取得する関数
def get_current_assignees(issue_id):
    query = """
    query GetIssueAssignees($issueId: ID!) {
      node(id: $issueId) {
        ... on Issue {
          assignees(first: 10) {
            nodes {
              id
              login
            }
          }
        }
      }
    }
    """

    variables = {
        "issueId": issue_id
    }

    try:
        data = execute_graphql(query, variables)
        assignee_nodes = data.get("data", {}).get("node", {}).get("assignees", {}).get("nodes", [])

        assignee_ids = [assignee["id"] for assignee in assignee_nodes]
        assignee_logins = [assignee["login"] for assignee in assignee_nodes]

        print(f"Current assignees: {assignee_logins}")

        return assignee_ids
    except Exception as e:
        print(f"Error retrieving current assignees: {e}")
        return []

# Issueにcopilotをアサインする関数（既存のアサイン担当者を維持）
def assign_copilot_to_issue(issue_id, copilot_id):
    if not copilot_id:
        print("Cannot assign copilot: copilot ID is not available")
        return False

    # 1. 現在のアサイン担当者のIDを取得
    current_assignee_ids = get_current_assignees(issue_id)

    # 2. Copilotが既にアサインされているかをチェック
    if copilot_id in current_assignee_ids:
        print("Copilot is already assigned to this issue")
        return True

    # 3. 既存のアサイン担当者のIDリストにCopilotのIDを追加
    actor_ids = current_assignee_ids + [copilot_id]

    # 4. GitHub GraphQL APIを使用して全てのアサイン担当者を設定
    mutation = """
    mutation AssignActorsToIssue($issueId: ID!, $actorIds: [ID!]!) {
      replaceActorsForAssignable(input: {assignableId: $issueId, actorIds: $actorIds}) {
        assignable {
          ... on Issue {
            id
            assignees(first: 10) {
              nodes {
                login
              }
            }
          }
        }
      }
    }
    """

    variables = {
        "issueId": issue_id,
        "actorIds": actor_ids
    }

    try:
        data = execute_graphql(mutation, variables)
        assignees = data.get("data", {}).get("replaceActorsForAssignable", {}).get("assignable", {}).get("assignees", {}).get("nodes", [])
        assignee_logins = [assignee.get("login") for assignee in assignees]
        print(f"Successfully assigned to issue: {assignee_logins}")
        return True
    except Exception as e:
        print(f"Error assigning actors to issue: {e}")
        return False

# ファイルから内容を読み込む関数
def read_file_content(file_path):
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            return f.read().strip()
    except FileNotFoundError:
        return None

# コマンドライン引数からカンマ区切りのリポジトリ名を取得
if len(sys.argv) < 2:  # 引数のチェック修正
    print("Usage: python create_issues.py owner1/repo1,owner2/repo2")
    sys.exit(1)

repo_names = sys.argv[1].split(',')

# 実行ディレクトリのパスを取得
script_dir = os.path.dirname(os.path.abspath(__file__))

# Issueの件名と本文をファイルから読み込む
header_file = os.path.join(script_dir, "issue_header.txt")
body_file = os.path.join(script_dir, "issue_body.txt")

# ファイルがない場合はサンプルファイルの内容をデフォルト値として使用
default_issue_title = "Copilotのアサイン確認テスト"
default_issue_body = """
これはテスト用のIssueです。
Copilotがアサインされていることを確認してください。
"""

# ファイルから読み込むか、デフォルト値を使用
issue_title = read_file_content(header_file) or default_issue_title
issue_body = read_file_content(body_file) or default_issue_body

print(f"Using issue title: {issue_title}")
print(f"Using issue body file: {body_file if os.path.exists(body_file) else '(default)'}")

# アサインするユーザー名を環境変数から取得（指定がなければアサインしない）
assignee_username = os.environ.get("GITHUB_ASSIGNEE")

# Copilotをアサインするかどうかのフラグ（環境変数から取得、デフォルトはTrue）
assign_copilot = os.environ.get("ASSIGN_COPILOT", "true").lower() in ("true", "yes", "1")

g = Github(GITHUB_TOKEN)

for repo_name in repo_names:
    try:
        repo_name = repo_name.strip()
        print(f"Processing repository: {repo_name}")

        # リポジトリ名からオーナーとリポジトリ名を分離
        repo_parts = repo_name.split('/')
        if len(repo_parts) != 2:
            print(f"Invalid repository name format: {repo_name}. Expected format: owner/repo")
            continue

        repo_owner, repo_short_name = repo_parts

        # PyGithubを使用してIssueを作成（REST API）
        repo = g.get_repo(repo_name)
        # アサイン先が設定されている場合のみアサインする
        if assignee_username:
            issue = repo.create_issue(
                title=issue_title,
                body=issue_body,
                assignee=assignee_username
            )
        else:
            issue = repo.create_issue(
                title=issue_title,
                body=issue_body
            )

        print(f"Created issue in {repo_name}: {issue.html_url}")

        # Copilotのアサインが有効な場合
        if assign_copilot:
            # Issueの作成後、GraphQLを使用してCopilotにアサイン

            # 1. GraphQL用のIssueID（ノードID）を取得
            issue_node_id = issue.node_id
            print(f"Issue node ID: {issue_node_id}")

            # 2. Copilot-swe-agentのIDを取得
            copilot_id = get_copilot_id(repo_owner, repo_short_name)

            # 3. CopilotをIssueにアサイン
            if copilot_id:
                assign_copilot_to_issue(issue_node_id, copilot_id)
    except Exception as e:
        print(f"Failed to process {repo_name}: {e}")
```
:::

## 実装結果と次のステップ

このスクリプトを実行した結果、複数のリポジトリに対して自動的にIssue作成とCopilotの自動アサインを行えました。

CODEOWNERSファイルを配置できた今後の展開としては以下を考えています。

- 配置したCODEOWNERSファイルを利用したより迅速なレビューサイクルの改善
- 作成したスクリプト他ユースケースへの活用
- GitHub Copilot Coding Agentの便利さの社内展開

## おわりに

以上が「GitHub Copilot Coding AgentでCODEOWNERSファイルを複数リポジトリに一気に配置した方法と課題」の記事でした。

私たちのチームでGitHub Copilot Coding Agentを利用し始めたのはこの数週間ですが、すでにその効果は現れ今後の進化にも期待は高まるばかりです。加えてGitHub Copilot code reviewによるレビュー機能も組み合わさり、ますます開発スピードを加速していける手応えを得ています。

課題でも記載した通り、今回のようにシンプルかつ均一の処理をまとめておこなうのであれば、CLIを用いた一括処理の方が均一性の意味では信頼できると言えます。
しかし「CLI化するには複雑だが命令としては均一のようなケース」で今回のノウハウは活かせるはずで、挑戦した価値はあったと考えています。

多少課題点も書きましたが、率直な感謝の文で結びとします。
「GitHub Copilotシリーズはすでに素晴らしい体験を私たちにもたらしてくれています。今後の発展にますます期待しています！」

それではみなさま Enjoy GitHub Copilot Coding Agent!!

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味をもった方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![イオングループエンジニア採用バナー](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recruiting.aeon.info/)
