---
title: "PagerDutyのユーザ棚卸しをシンプルなPythonとExcelでやりました"
emoji: "🔁"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: # タグを指定する
  - "pagerduty"
  - "python"
  - "excel"
  - "aeon"
published: false
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。

2025年も楽しんでやっていきです。
本記事ではPagerDutyの棚卸しを簡単なPythonスクリプトとExcelを使って行なった話をします。

## TL;DR

本記事を箇条書きでまとめると以下です。

- PagerDutyのユーザはAzureのMicrosoft Entra IDをIdPとしてSAMLによるSSOで認証と、初回ログイン時の作成を行っている
- Entra ID側を削除してもPagerDutyから自動削除されない
- 未使用ユーザが複数名以上おり、一覧をPythonのスクリプトで取得しExcelで社内へ展開し棚卸しをお願いできた

## 背景

当社ではPagerDutyのユーザ管理をMicrosoft Entra ID(以降はEntra ID）を利用したSSOで実現しています。

Entra IDのユーザとグループはTerraformで管理されており、PagerDutyの利用を希望するユーザはTerraformでPRを出し、SREレビュー後にマージされることでPagerDutyの利用を開始できます。
（利用希望者側にTerraformのナレッジがない場合はJiraによるチケット依頼でも対応しています）

![](/images/morihaya-20241227-pagerduty-check-users/2025-01-14-23-27-42.png)

PagerDutyにはユーザが初回ログイン時に自動で作成するための[Auto-provision users on first login](https://support.pagerduty.com/main/lang-ja/docs/sso#section-optional-attributes-for-auto-provisioning)オプションが用意されており、こちらを有効にすることで「IaCによる事前のレビューさえ通ればあとはユーザがセルフサービスで利用を開始できる」状況を実現しています。

## PagerDutyユーザが自動で消えない課題

上述したユーザ作成・認証のフローはうまく機能し、社内のPagerDuty利用者数は順調に増加してきました。
しかし「退職・異動したユーザのPagerDutyアカウントの削除」については人間によるチェックと削除処理が必要です。

最近ではSCIM（System for Cross-domain Identity Management）によるユーザの削除も含めてIdPから反映される仕組みが広がりつつありますが、現状PagerDutyが対応するSAMLによるSSOではユーザ作成と認証は対応しても、ユーザの削除まではされません。

## PagerDutyユーザの棚卸しを行う

こうして、年明けという良いタイミングでもありましたので、PagerDutyユーザの棚卸しを実施することにしました。

### PagerDutyのGUIでもある程度は可能

PagerDutyのWebコンソールから[People -> Users](https://support.pagerduty.com/main/lang-ja/docs/manage-users)を選択することで、ユーザの一覧を確認できます。

![](/images/morihaya-20241227-pagerduty-check-users/2025-01-14-23-54-48.png)

こちらは全体の状況を見たり、ドリルダウンしてユーザ個別の情報を確認する場合には便利ですが、ユーザの棚卸しのような一覧として使うには向いていません。

### Pythonで簡単なスクリプトを作成

PagerDutyには優れたAPIが用意されています。
（改めてAPIのドキュメントのChange logを見て、その更新頻度から力の入れ具合も感じ取れます）
https://developer.pagerduty.com/api-reference/f1a95bb9397ba-changelog

#### List usersを利用

今回行いたいのはPagerDutyユーザの棚卸しであるため `List users` を利用します。
https://developer.pagerduty.com/api-reference/c96e889522dd6-list-users

`List users`は名前の通りユーザの一覧を取得するためのAPIです。

ユーザに関するさまざまな情報を取得できますが、今回必要となるのは以下でした。

- ユーザ名
- メールアドレス
- ユーザが所属するチーム (複数ある場合はどれかひとつ）
- ユーザのPagerDuty上のID (オプションとして後述するAuditログ参照に使う）

#### Pythonスクリプト

これらを取得するために、AIの力を借りつつ作成したPythonコードが以下になります。

```Python
import os
import requests
import configparser

# 設定ファイルの読み込み
config = configparser.ConfigParser()
config.read('config.ini')

# API keyの取得
api_key = config['API']['SECRET_API_KEY']

def get_pagerduty_users():
    # PagerDuty APIのエンドポイント
    url = "https://api.pagerduty.com/users"

    # リクエストヘッダー
    headers = {
        "Accept": "application/json",
        "Authorization": f"Token token={api_key}",
        "Content-Type": "application/json"
    }

    # ページを処理（Pagination）しながら全件のユーザ情報を取得する
    users = []
    more = True
    offset = 0
    limit = 25
    while more:
        # ページ指定のクエリパラメータを追加
        params = {
            "limit": limit,
            "offset": offset
        }
        response = requests.get(url, headers=headers, params=params)
        if response.status_code == 200:
            response_json = response.json()
            users += response_json["users"]
            offset += limit
            more = response_json["more"]
        else:
            print(f"エラー: {response.status_code}")
            return None

    return users

# ユーザー一覧を取得して表示
users = get_pagerduty_users()
if users:
    # ヘッダーを表示
    print(f"名前,メール,ID,チーム")
    # ループでユーザー情報を表示
    for user in users:
        # teamsが空の場合は空文字列を表示
        if not user['teams']:
            print(f"{user['name']},{user['email']},{user['id']},-")
        else:
            print(f"{user['name']},{user['email']},{user['id']},{user['teams'][0]['summary']}")
```

他のスクリプトも作成する観点から、APIキーは別ファイル `config.ini` へ切り出しています。

```ini
# config.ini

[API]
# See: https://support.pagerduty.com/main/docs/api-access-keys#generate-a-user-token-rest-api-key
SECRET_API_KEY = hogefugapiyo
```

#### Pythonコードのポイント

大したコードではありませんがポイントは以下の通りです。

- ページネーションへの対応
  - [Pagination](https://developer.pagerduty.com/docs/pagination)に記載ある通り、取得結果は最大100個を超えられないためoffsetを利用して全結果を取得するようにしています
- チーム情報の取得
  - ユーザは必ずしもチームに所属していませんが、している場合は表示するようにしました。棚卸し時の参考情報であるため複数のチームに所属しても最初にHitしたチームのみを表示する割り切った仕様です


## CSVとして結果を取得し、そのままExcelへ貼り付けて各部門へ展開

上述したPythonスクリプトを実行すると以下のような結果を得られます。

```csv
名前,メール,ID,チーム
もりはや AST,morihaya@example.com,HOGEPIYO,SRE
ユーザ01 AST,user01@example.com,HOGEPIY1,-
ユーザ02 AST,user02@example.com,HOGEPIY2,Developer
...
```

この結果をMicrosoft 365のExcelへ貼り付け、確認用の列を追加し、共有用のリンクをSlackで各所に展開して棚卸しをお願いすることができました。

![](/images/morihaya-20241227-pagerduty-check-users/2025-01-15-00-24-39.png)

## 今後の展望：ユーザ削除の自動化

今回は仕切り直しの意味も込めて全PagerDutyユーザの棚卸しを行いました。
これは必要な作業ではありますが、今後は削除も自動化していきたいと考えています。

具体的には「Entra ID側のユーザの異動・削除をCIで検知し、PagerDutyのAPI経由でユーザの削除を実施する」仕組みを検討しています。

このような形で削除運用も自動化することで、ライセンスの適正化やセキュリティ向上、定時の棚卸しの労力削減などへの期待があります。

## 余談：List audit records for a userで最終Audit log時間の取得

上記のPythonスクリプトでやりかけたことに[List audit records for a user](https://developer.pagerduty.com/api-reference/57cabfee791be-list-audit-records-for-a-user)による、各ユーザの最終のAuditログの時間取得があります。

ただし、それを実装してしまうとユーザごとにAPIの呼び出しが発生してしまい、今後利用者が増えることでRate limitである `960 requests per minute` に抵触する懸念があったため辞めました。

https://developer.pagerduty.com/docs/rest-api-rate-limits

代わりにユーザのIDを渡すとそのユーザの最終のAuditログの時間を取得する簡易スクリプトを用意し、とくに知りたいユーザについては簡単に調査可能としています。

```python
import os
import requests
import configparser

# 設定ファイルの読み込み
config = configparser.ConfigParser()
config.read('config.ini')

# API keyの取得
api_key = config['API']['SECRET_API_KEY']

user_id = ""

# ユーザのIDからaudit recordの最新の時間を取得
# https://developer.pagerduty.com/api-reference/57cabfee791be-list-audit-records-for-a-user
# より "The returned records are sorted by the execution_time from newest to oldest." とあるため
# 最初の要素のみ取得すれば最新のaudit recordが取得できる
def get_audit_record(user_id):
    # ユーザIDが指定されていない場合は処理を終了
    if not user_id:
        print("ユーザIDが指定されていません。")
    else:
        print(f"ユーザID: {user_id}")

    # PagerDuty APIのエンドポイント
    url = f"https://api.pagerduty.com/users/{user_id}/audit/records"

    # リクエストヘッダー
    headers = {
        "Accept": "application/json",
        "Authorization": f"Token token={api_key}",
        "Content-Type": "application/json"
    }

    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        response_json = response.json()
        if len(response_json["records"]) == 0:
            return "audit recordが見つかりませんでした。"

        return response_json["records"][0]["execution_time"]
    else:
        print(f"エラー: {response.status_code}")
        return None

# メイン処理を実行
if __name__ == "__main__":
    user_id = input("ユーザIDを入力してください: ")
    audit_record = get_audit_record(user_id)
    if audit_record:
        print(audit_record)
    else:
        print("エラーが発生しました。")
```

## おわりに

以上が「PagerDutyのユーザ棚卸しをシンプルなPythonとExcelでやりました」の紹介でした。

簡単な運用スクリプトならAI支援でシュッと実現できる大変良い世の中になりました。
一方で「PagerDutyに優れたAPIがある」といった知識や、「APIで簡単にCSVで出力したい」といったアイデアは人間が出す必要があります。

今後も工夫を楽しみながらSREのKAIZENサイクルを回していきたいと考えています。
それではみなさまEnjoy PagerDuty！

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味をもった方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recuruiting.aeon.info/)
