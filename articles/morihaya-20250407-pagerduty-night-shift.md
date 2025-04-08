---
title: "PagerDutyのスケジュール機能で朝会司会担当者の通知を自動化する方法"
emoji: "☀️"
type: "tech"
topics:
  - "pagerduty"
  - "インシデント"
  - "slack"
  - "オンコール運用"
  - "aeon"
published: false # false or true , スケジュール公開の場合はfalseで予約して後からtrueにFix必要
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。

本記事では、PagerDutyのスケジュール機能とSlackを活用して、毎朝のチームMTG担当者通知を自動化した事例を紹介します。これにより、朝会の開始時に誰が司会をするかの担当者の混乱が解消され、休暇などの不在時に簡単に司会を交代できるようになりました。

## TL;DR

- SREチームでは毎朝MTGで状態共有やタスク整理などを行っています
- 朝会の司会はローテーション制ですが、当日の担当者が不明になることが課題でした
- PagerDutyとSlack連携で担当者の通知を自動化してスムーズな朝会進行を実現しました

![Slack-Notify-from-PagerDuty-schedule-white](/images/morihaya-20250407-pagerduty-night-shift/2025-04-08-02-12-10.png)

## 背景

私たちのチームでは朝会が重要なコミュニケーションの場となっていますが、担当者確認や進行準備に時間がかかることが課題でした。このToil（面倒な手作業）を解消するため、自動化に取り組みました。

朝会の進行はMarkdown形式のドキュメントで整理されているため、初めてのメンバーでも簡単に進行できます。課題となったのはローテーションの順番もそこに書いていながらも、休日やメンバー不在などで当日の司会担当がわからなくなることがありました。

本記事の工夫を導入するまでは朝会開始時に「えーと今日の担当ってだれでしたっけ...?昨日はもりはやだったから◯◯？」「おっと、朝会のページどこでしたっけ...」となるケースが多くありました。

毎日の朝会でこのようなやりとりが交わされることは間違いなくToilです。担当者を回す仕組みといえばPagerDutyが身近にあると気づいた私は、そのAPIを活用しSlackへの通知を自動化する仕組みを構築しました。

## PagerDutyのScheduleの優れたUI

PagerDutyには基本機能としてオンコールの当番をコントロールするためのScheduleがあります。
これはPagerDutyがサービス開始当初から備えた成熟された機能で、Web画面上からもオンコール当番を管理できるものです。

以下はSchedule画面の添付ですが、触ったことのない方でも直感的に編集できる気配を感じられるでしょうか。

このScheduleにチーム朝会の司会担当を設定し、その結果をAPIで取得すれば良いのです。
![pagerduty-schedule](/images/morihaya-20250407-pagerduty-night-shift/2025-04-06-23-17-32.png)

## PagerDutyのAPIドキュメントは充実している

PagerDutyは開発者向けにAPIのサイトを公開しています。

https://developer.pagerduty.com/api-reference/

API Referenceを見ると各機能の情報を取得できるAPIが豊富に用意されており、この中から今回は[Get a schedule](https://developer.pagerduty.com/api-reference/3f03afb2c84a4-get-a-schedule)のAPIを利用することにしました。

## 現在の担当者を取得するためのAPIクエリパラメータの指定

当初テスト用のScheduleを利用した時は自分1人だけだったため気づくことはできませんでしたが、Scheduleから現在のオンコール担当を取得するためにはいくつかのクエリパラメータを付与する必要があります。

以下は実際のPythonコードの抜粋です。

```python
def fetch_schedule_data(pagerduty_schedule_id, api_key):
    """
    PagerDuty APIからスケジュールデータを取得する関数。

    参考: コマンドで行う場合
        curl --request GET \
        --url "https://api.pagerduty.com/schedules/${SCHEDULE_ID}?time_zone=Asia/Tokyo&since=2025-04-07T09:00:00+09:00&until=2025-04-07T09:00:00+09:00" \
        --header 'Accept: application/json' \
        --header "Authorization: Token token=${PAGERDUTY_API_KEY}" \
        --header 'Content-Type: application/json'
    """

    time_zone = "Asia/Tokyo"
    JST = timezone(timedelta(hours=9))
    now = datetime.now(JST).isoformat()

    url = f"https://api.pagerduty.com/schedules/{pagerduty_schedule_id}?time_zone={time_zone}&since={now}&until={now}"
    headers = {
        "Authorization": f"Token token={api_key}",
        "Accept": "application/json"
    }

    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        return response.json()
    else:
        print(f"PagerDuty APIエラー: {response.status_code} - {response.text}")
        return None
```

＊ブログ化にあたりDebugコードは削除していますが、実際にはStep単位でprintデバッグを行っています。

現在の担当者を取得するために必要となるのは以下のパラメータです。

- `time_zone`: タイムゾーン。日本であるため"Asia/Tokyo"を指定する
- `since`: 現在の担当を取得するため現在時刻を指定。フォーマットは`datetime.now(JST).isoformat()` (ex: `2025-04-07T09:00:00+09:00`)
- `until`: `since`を同じ値を指定

このAPIへのリクエストによって、以下のようなJSONの結果を得ることができ`.schedule.final_schedule.rendered_schedule_entries[].user.id`のような形で現在のオンコール担当者のPagerDutyのユーザIDと`（同じなため省略）.user.summary`より名前を取得できます。

```json
＊ドキュメントのサンプルより抜粋
{
  "schedule": {
    "id": "PI7DH85",
    "type": "schedule",
    "summary": "Daily Engineering Rotation",
    ...(省略)...
    "final_schedule": {
      "name": "Final Schedule",
      "rendered_schedule_entries": [
        {
          "start": "2015-11-10T08:00:00-05:00",
          "end": "2015-11-10T17:00:00-05:00",
          "user": {
            "id": "PXPGF42",              <--PagerDutyのユーザID
            "type": "user_reference",
            "summary": "Regina Phalange", <--PagerDutyのユーザ表示名
            "self": "https://api.pagerduty.com/users/PXPGF42",
            "html_url": "https://subdomain.pagerduty.com/users/PXPGF42"
          }
        }
      ],
      "rendered_coverage_percentage": 37.5
    }
  }
}
```

## SlackでメンションするためにPagerDutyのユーザIDとEmail AddressとSlackのユーザIDを紐づける

PagerDutyから現在の担当を取得することはできましたが、そのままではただテキストメッセージをSlackへ通知するだけになります。
当日の司会担当にしっかり通知するすためにもSlack上で本人にメンションを行いたくなりました。

Slack上でメンションを行うためにはSlackユーザIDが必要ですが、PagerDutyのユーザIDとは当然異なります。
そのため以下の3つをマッチさせる必要がありました。

- PagerDutyのユーザID
- Email Address（PagerDutyの通知を行うためにほぼすべてのユーザが設定しているし、Slackのユーザも持っている）
- SlackのユーザID

上述の通り紐づけるためのキーは`Email Address`です。

[![](https://mermaid.ink/img/pako:eNqNUU1Lw0AQ_SthTgqxbBOTtLmJehARCuJFArJ01zS0TcomAWtbMC2ioIKIHvSigl8giIh4UfDHLFr7L9xNrEhFcC67--bNm7czLSgHhIINlM142GW47viKiBJ2BRJHzaWQslBpZaiMMGKe7yqxwFc8opTmFQe-2Ty5470r3nvh3ae5GQd-ldE69mormBBGw1BUDjZO-qeX_cMbnlx_XGy9H92nEudSonfLuwf94-fB7oPI8mSPd3eGkp3sWKzhcvUvi6FMfntMqUL8X7beXjcHZ9uia54nF9JR8jrSeWRA7fbERLv9048tZPqP-zy5FM6VsVnZQZnKOoxLMVChTpmAiRh_6t6BqELr1AFZSzCrSlpH8HAcBYtNvwx2xGKqQtwgOKJfCwN7FddCgVLiRQFbyPaZrlWFBvbBbsEa2Hmk5fIFpOmWrhVMZCJDhSbYujWZQxqaRPmCaRi6ZnVUWA8CoYpyRtGwkFnUi2bR0kzDVIEFsVsZuhDayykze7pM_iS7M-oTyqaD2I_ANozOJypb4R0?type=png)](https://mermaid.live/edit#pako:eNqNUU1Lw0AQ_SthTgqxbBOTtLmJehARCuJFArJ01zS0TcomAWtbMC2ioIKIHvSigl8giIh4UfDHLFr7L9xNrEhFcC67--bNm7czLSgHhIINlM142GW47viKiBJ2BRJHzaWQslBpZaiMMGKe7yqxwFc8opTmFQe-2Ty5470r3nvh3ae5GQd-ldE69mormBBGw1BUDjZO-qeX_cMbnlx_XGy9H92nEudSonfLuwf94-fB7oPI8mSPd3eGkp3sWKzhcvUvi6FMfntMqUL8X7beXjcHZ9uia54nF9JR8jrSeWRA7fbERLv9048tZPqP-zy5FM6VsVnZQZnKOoxLMVChTpmAiRh_6t6BqELr1AFZSzCrSlpH8HAcBYtNvwx2xGKqQtwgOKJfCwN7FddCgVLiRQFbyPaZrlWFBvbBbsEa2Hmk5fIFpOmWrhVMZCJDhSbYujWZQxqaRPmCaRi6ZnVUWA8CoYpyRtGwkFnUi2bR0kzDVIEFsVsZuhDayykze7pM_iS7M-oTyqaD2I_ANozOJypb4R0)

メールアドレスでの紐付けをどのように行ったかの説明は、細かい話になるためトグルに隠しておきました。気になる方は開いてください。

:::details SlackのIDとEmail Addressの一覧をDailyでGitHubリポジトリに格納しておく

Slackのユーザは以下の特性を持っています。

- Slack独自のユーザIDがある（メンション時にはこれを利用する）
- Email Addressを持っている
- ユーザは人事異動時に増減するため変更頻度は低い

今回のようなメールアドレスからSlackのユーザIDを取得したいケースが今後も想定されることと、Slackユーザの変化の証跡を残す観点でユーザの一覧をCSVとして取得し、DailyでGitHubのリポジトリに記録する仕組みを作りました。


具体的にはGitHub Actionsを利用し以下のようなコードで取得を行っています。

```Python
import requests
import csv
import os

def fetch_slack_users(slack_token):
    """
    Slack APIを使用してユーザー情報を取得する関数。
    """
    url = "https://slack.com/api/users.list"
    headers = {
        "Authorization": f"Bearer {slack_token}",
        "Content-Type": "application/json"
    }

    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        data = response.json()
        if data.get("ok"):
            return data.get("members", [])
        else:
            print(f"Slack APIエラー: {data.get('error')}")
            return []
    else:
        print(f"Slack APIエラー: {response.status_code} - {response.text}")
        return []

def save_users_to_csv(users, filepath):
    """
    ユーザー情報をCSVファイルに保存する関数。
    """
    # メールアドレスでソート（大文字小文字を無視）
    sorted_users = sorted(users, key=lambda user: user.get("profile", {}).get("email", "").lower())

    with open(filepath, mode='w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(["email", "slack_user_id"])
        for user in sorted_users:
            profile = user.get("profile", {})
            email = profile.get("email")
            slack_user_id = user.get("id")
            if email:
                writer.writerow([email, slack_user_id])

if __name__ == "__main__":
    SLACK_TOKEN = os.getenv("SLACK_TOKEN")
    if not SLACK_TOKEN:
        print("環境変数 'SLACK_TOKEN' が設定されていません。")
        exit(1)

    users = fetch_slack_users(SLACK_TOKEN)
    save_users_to_csv(users, "slack_users.csv")
```

Dailyで実行するGitHub ActionsのWorkflowコードは以下の通りです。リポジトリの肥大化を防ぐために変更があった時のみCommitを行う仕様にしています。

```yaml
name: Update Slack Users

on:
  schedule:
    # 日本時間(JST)の毎日08:00に実行
    - cron: '0 23 * * *'
  workflow_dispatch:
    inputs:
      trigger:
        description: '手動実行によるトリガー'
        required: true
        default: '簡単な理由を記入してください'

permissions:
  contents: write # commit push するために必要

jobs:
  fetch-slack-users:
    runs-on: ubuntu-latest
    timeout-minutes: 10

    steps:
      - name: Diplay input
        run: |
          echo "### Trigger: ${{ github.event.inputs.trigger }}"

      - name: Checkout repository
        uses: actions/checkout@hogehogehash #v4
        with:
          fetch-depth: 0
#          persist-credentials: false # この行を有効にするとpush時にエラーが発生する

      - name: Set up Python
        uses: actions/setup-python@hogehogehash # v5
        with:
          python-version: '3.x'

      - name: Install dependencies
        run: |
          echo "## Install dependencies"
          python -m pip install --upgrade pip
          pip install requests

      - name: Run script to update Slack users
        env:
          SLACK_TOKEN: ${{ secrets.SLACK_TOKEN }}
        run: |
          echo "## Run script to update Slack users"
          python ./slack_user_info.py

      - name: Commit and push changes
        uses: stefanzweifel/git-auto-commit-action@hogehogehash #v5
        with:
          commit_message: 'Update Slack users'
          branch: main
          file_pattern: slack_users.csv
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

これらのコードによって、リポジトリには当日朝08:00時点の最新のSlackユーザの一覧がCSVファイルとして記録されます。
参考としてCSVファイルは以下のようになっています。

```csv
email,slack_user_id
morihaya@example.com,SLACKUSERID
...（以下同様にメールアドレスとSlackのユーザIDが並ぶ）
```

:::

:::details PagerDutyのユーザIDからユーザのEmail Addressを取得する

Slack側のユーザ一IDとメールアドレスの一覧が取得できる状態となりましたので、続いてPagerDutyのユーザIDからメールアドレスを取得します。

上述したPagerDutyの[Get a schedule](https://developer.pagerduty.com/api-reference/3f03afb2c84a4-get-a-schedule)APIですが、Slackユーザと紐づけるキーとなるメールアドレスは取得できません。
そのため別のAPIである[Get a user](https://developer.pagerduty.com/api-reference/2395ca1feb25e-get-a-user)APIを利用して担当者のメールアドレスを取得しました。

PagerDutyの通知方法は電話、アプリプッシュ、SNS、メール、Slackなど複数存在していますがメールは複数のメールアドレスを指定でき、これは通常はログインIDでもある会社用のメールアドレスを設定しつつも、緊急時には別のアドレスにも通知するような設定が考慮されているためです。

それら複数の通知用メールアドレスを以下のコードの様にユーザの`contact_methods`から取得しています。

```python
def fetch_user_mail(user_id, api_key):
    """
    PagerDuty APIからユーザのメールアドレスを取得する関数。
    """
    url = f"https://api.pagerduty.com/users/{user_id}/contact_methods"
    headers = {
        "Authorization": f"Token token={api_key}",
        "Accept": "application/json"
    }

    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        contact_methods = response.json().get("contact_methods", [])
        # メールアドレスのみを抽出
        email_addresses = [
            method["address"] for method in contact_methods if method["type"] == "email_contact_method"
        ]
        return email_addresses
    else:
        print(f"Error: {response.status_code}, {response.text}")
        return []
```

:::

:::details PagerDutyのemail_contact_methodから設定されたすべてのメールアドレスとSlackユーザのメールアドレスをパターンマッチさせる


別のリポジトリに格納されているSlackのユーザ一覧CSVファイルのメールアドレスと、PagerDutyの複数の通知先メールアドレスを紐づけるためには以下のような形でマッチさせています。

```python
def get_slack_id_from_emails(repo_name, file_path, github_token, email_addresses):
    """
    指定されたGitHubリポジトリからCSVファイルを読み込み、
    複数のメールアドレスを基にSlack IDを検索する。

    Args:
        repo_name (str): GitHubリポジトリ名 (例: "morihaya/slack-user-mapping")
        file_path (str): CSVファイルのパス (例: "slack_users.csv")
        github_token (str): GitHub ActionsのトークンまたはPersonal Access Token
        email_addresses (str): 検索するメールアドレス

    Returns:
        str: 一致するSlack ID。見つからない場合はNone。
    """
    try:
        # GitHubオブジェクトの作成
        g = Github(github_token)

        # リポジトリの取得
        repo = g.get_repo(repo_name)

        # ファイルの取得
        file_content = repo.get_contents(file_path)
        file_content_str = file_content.decoded_content.decode('utf-8')

        # CSVファイルの読み込み
        csv_reader = csv.reader(file_content_str.splitlines())
        next(csv_reader)  # ヘッダー行をスキップ

        # 複数のメールアドレスを基にSlack IDを検索する、一つでもHitすればOK
        for row in csv_reader:
            slack_email = row[0]
            slack_id = row[1]

            for email in email_addresses:

                if email==slack_email:
                    return slack_id

        return None  # 見つからない場合はNoneを返す

    except Exception as e:
        print(f"エラーが発生しました: {e}")
        return None
```

なお仮にマッチするメールアドレスがない場合はSlack上でのメンションは行わず、[Get a schedule](https://developer.pagerduty.com/api-reference/3f03afb2c84a4-get-a-schedule)APIで取得したPagerDuty上の表示名を利用します。

:::

## 通知はGitHub Actionsで行い、引数を変更すればコピペで似たような通知が簡単にできる

こうして作成したPythonスクリプトを実行するのはGitHub Actionsで行なっています。

ポイントは最後のstepのrunの部分です。このYAMLファイルをコピーしPythonを実行する引数を変更すれば簡単にPagerDutyのScheduleを利用したSlack通知が可能となりました。
今回はチームの朝会の通知に利用していますが、実際のオンコール通知を明示的にSlackへ通知させるような用途にも簡単に転用できます。

```yaml
name: Notify SRE Teams Morning Meeting

on:
  workflow_dispatch:
  schedule:
    - cron: "30 0 * * 1-5"  # Weekdayの朝09:30に実行 (UTC時間で設定)

jobs:
  notify:
    runs-on: ubuntu-latest
    timeout-minutes: 10

    steps:
      - name: Create GitHub App Token
        uses: actions/create-github-app-token@hogehogehash #v1
        id: app-token
        with:
          app-id: ${{ vars.GITHUBAPP_ID }}
          private-key: ${{ secrets.GITHUBAPP_PRIVATE_KEY }}
          repositories: "<自分のリポジトリ名＞, ＜SlackユーザのCSVが格納されたリポジトリ名＞" # これを指定しないとエラーになった(throw new Error("Input required and not supplied: app-id");)

      - name: Checkout repository
        uses: actions/checkout@hogehogehash #v4
        with:
          fetch-depth: 0
          persist-credentials: false

      - name: Set up Python
        uses: actions/setup-python@hogehogehash #v5
        with:
          python-version: '3.10' # 3.x, 3.11, だと最新が利用されエラー

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install requests PyGithub slack_sdk

      - name: Run notify script
        env:
          PAGERDUTY_API_KEY: ${{ secrets.PAGERDUTY_API_KEY }}
          SLACK_BOT_TOKEN: ${{ secrets.SLACK_BOT_TOKEN }}
          GITHUB_TOKEN: ${{ steps.app-token.outputs.token }}
        run: |
          python ./pagerduty/notify-sre-teams-morningmtg.py \
            --pagerduty_schedule_id ＜PagerDutyのスケジュールID＞ \
            --pre_message '本日の<https://朝会の記事が書かれたドキュメントページへのリンク|SREチームの朝会>担当者は' \
            --post_message 'さんです。<https://github.com/＜このGitHub Actions.ymlへのリンク＞|通知元> \n 順番を変更する場合は<https://＜PagerDutyのScheduleへのリンク＞|PagerDutyのSchedule>から操作してください' \
            --slack_channel_id ＜SlackのチャンネルID＞
```

このGitHub Actionsが実行されることで、その時点のPagerDutyのScheduleでOn-Call担当者が取得されSlackに通知が行われます。

通知には以下のURLリンクを設定することで利便性を向上させました。

- 朝会ドキュメントへのリンク
- この通知自体のGitHub ActionsのYAMLファイルへリンク
- PagerDutyのScheduleへのリンク


![Slack-Notify-from-PagerDuty-schedule-white](/images/morihaya-20250407-pagerduty-night-shift/2025-04-08-02-12-10.png)

## 余談：細かくて省いたところ

上述した内容の他に、この仕組みが動くためにはいくつかのセットアップが必要となります。一般的であることと細かい内容となってしまうため詳細は述べませんが、以下に項目だけ挙げておきます。

- Slack appsの設定
  - token発行
  - install
  - 通知先チャンネルへのSlack appsのinvite
- GitHubの設定
  - 各種Secrets、Varsの設定
  - リポジトリ間のアクセス設定

## おわりに

以上が「PagerDutyのスケジュール機能で朝会司会担当者の通知を自動化する方法」の記事でした。Toilの撲滅と遊び心で実装しましたがCopilotでサクサクPythonコーディングとはいかず、APIドキュメントの把握、Slack appsの設定、GitHubリポジトリ間の参照など多くの学びを得ることができました。なんでもやってみるものですね。（タスクの優先度は考慮しつつ）

それではみなさまEnjoy PagerDuty!

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味をもった方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recuruiting.aeon.info/)
