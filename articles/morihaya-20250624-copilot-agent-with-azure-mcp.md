---
title: "GitHub Copilot Coding AgentのAzure MCP server設定のハマりからGitHub Docs修正まで"
emoji: "📝"
type: "tech" # tech or idea
topics:
  - github
  - githubcopilot
  - azure
  - mcp
  - aeon
published: false # false OR true , スケジュール公開の場合はfalseで予約して後からtrueにFix必要
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林aka[もりはや](https://twitter.com/morihaya55)です。
当社は各種サービスのプログラムソースコードをVCSで管理しており、GitHubもそのひとつです。（他にAzure DevOps Reposも）

本記事ではGitHubのAIサービス[GitHub Copilot Coding Agent](https://docs.github.com/en/copilot/using-github-copilot/coding-agent)で[Azure MCP server](https://github.com/Azure/azure-mcp)を設定しようとしたところ、いくつかのハマりポイントがあったので紹介します。

最終的にはGitHub Docsへも修正PRを取り込んでもらいましたので、現在はハマることはないはずです。

https://docs.github.com/en/copilot/using-github-copilot/coding-agent/extending-copilot-coding-agent-with-mcp#example-azure

## TL;DR

本記事を3行に要約すると以下です。

- GitHub Copilot Coding agentにAzure MCP serverの設定を行いました
- 簡単に終わる作業と思いきや、いくつかのハマりポイントがありました...
- トライアンドエラーの末無事に設定が完了し、GitHub Docsへ修正PRを出して取り込んでもらいました

## Coding AgentへAzure MCP serverを設定するモチベーション

Coding Agentは私たちを支援してくれる強力なサービスです。GitHubにIssueを作成し、Copilotをアサインすると数分後にはPRとして作業の結果が上がってきます。
2025年5月の[Coding Agentの発表](https://github.blog/news-insights/product-news/github-copilot-meet-the-new-coding-agent/)を受けて、私たちもCopilotライセンスの整理とEnterpriseへの変更を行い、検証を進めてきました。

先日の以下の記事もその一例です。

https://zenn.dev/aeonpeople/articles/morihaya-20250612-create-multi-issues-for-copilot

こうして簡単なTerraformのdriftのキャッチアップや、シンプルなAzureリソースの追加などでCopilot Agentの良さを手応えとして掴んできた次のステップとして、Azure MCP serverとの接続を行いたいと考えました。

理由として、私たちSREチームが管理する主要なリポジトリがAzureリソースを管理する大量のTerraformコードを格納しており、Copilot Agentが実際にAzureの情報を参照することでより正確なTerraformのコードを生成してくれる期待がありました。

## 作業の概要

Coding AgentへAzure MCP serverを設定する作業は、本来は簡単なものに見えました。

https://docs.github.com/en/copilot/using-github-copilot/coding-agent/extending-copilot-coding-agent-with-mcp#example-azure

意訳しながら引用すると以下の5ステップしかありません。

1. Microsoft Entra IDのアプリケーションでOIDCを設定し、GitHub Actionsのフェデレーションを設定
2. 対象のGitHubリポジトリに`.github/workflows/copilot-setup-steps.yml`ワークフローファイルをサンプルを参考に作成
3. 2のワークフローの`copilot-setup-steps`ジョブに[Azureログイン](https://github.com/Azure/login)のステップを追加
4. 対象のGitHubリポジトリのEnvironmentの`copilot`へ、`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`シークレットを追加
5. 対象のGitHubリポジトリのCopilotのCoding agentの`MCP Configuration`に`Azure`オブジェクトを追加して、Azure MCP serverを設定

全体を通して手作業でWeb画面から行ったとしても、落ち着いてやれば1時間も必要としない作業と言えるでしょう。

以降は各手順でどのようなハマりポイントがあったかを解説します。

## ハマりポイントの紹介

繰り返しとなりますがGitHub Docsの手順については修正済みなため、現在は以降のハマりポイントの多くは解消済みです。
Azure MCP serverの設定を行いたいだけであれば、GitHub公式ドキュメントをご参照ください。

### 1. Microsoft Entra IDのアプリケーションでOIDCを設定し、GitHub Actionsのフェデレーションを設定

Coding agentはGitHub Actionのリソースとして稼働します。
そのためAzure側にAzure MCP serverがOIDC（OpenID Connect）でログインできるように、Entra IDの設定が必要です。

https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp#github-actions

手順を簡単にまとめると以下の通りです。

1. Entra IDの`App registrations`でAzure MCP serverのためのアプリを作成（既存のアプリでも可）
2. 同じく`App registrations`の画面で`Certificates & secrets`を開き`Add credential`をクリック
3. `GitHub Actions deploying Azure resources`を選択し、対象GitHubリポジトリの`Org name`, `Repo name`を入力し、`Environment`を選択し、GitHub environment nameへは`copilot`を入力する
![add_credential](/images/morihaya-20250624-copilot-agent-with-azure-mcp/2025-06-25-00-15-07.png)
4. 作成したアプリへ、Azure上で適切な権限を付与する

#### ハマりポイント: アプリケーションを開く方法が2つあり、混乱した

ここでのハマりポイントは「アプリケーションを開く方法が2つあることで混乱した」です。
手順書には明確に`App registrations`で`Certificates & secrets`とありますが、私は普段SSOなどの設定を行っている慣れから`Enterprise applications`で対象のアプリを開いていました。

下図は間違えて開いた`Enterprise applications`です。ご覧の通り`Certificates & secrets`の項目はありません。
![enterprise_application](/images/morihaya-20250624-copilot-agent-with-azure-mcp/2025-06-25-00-23-22.png)

そして下図が正しい`App registrations`で開いた状態です。目的の`Certificates & secrets`がしっかりと表示されているのがわかるでしょうか。

![app_registrations](/images/morihaya-20250624-copilot-agent-with-azure-mcp/2025-06-25-00-26-22.png)

私はこの違いになかなか気づくことができず「あれー？、Azure Portalのメニュー変わったんだろうか...どこに移動したんだろう」と十分ほど探した末にその場では別作業のために諦めました。

その後別のタイミングで開き直す時にやっと`App registrations`で開くべきことと、それによって表示されるメニューの違いに気づくことができたのです。

わかってしまえば本当に単純なことでしたが、普段2つのメニューの違いをあまり意識せずに使っていたことを反省する良い機会となりました。

### 2. 対象のGitHubリポジトリに`.github/workflows/copilot-setup-steps.yml`ワークフローファイルをサンプルを参考に作成

この手順がもっともハマりポイントが多いところでした。
本来であれば以下のように、ドキュメントのサンプルをコピーして`.github/workflows/copilot-setup-steps.yml`を作成するだけでしたが、私が参照した時のサンプルにいくつかのあやまりがあったのです。


```yaml
on:
  workflow_dispatch:
permissions:
  id-token: write
  contents: read
jobs:
  copilot-setup-steps:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    environment: copilot
    steps:
      - name: Azure login
        uses: azure/login@a457da9ea143d694b1b9c7c869ebb04ebe844ef5
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

コードの上から順に紹介します。

#### ハマりポイント: azure/loginのハッシュ値が動作しないものだった

以下は修正後の`git diff`の抜粋です。

```sh
        steps:
          - name: Azure login
-           uses: azure/login@a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0
+           uses: azure/login@a457da9ea143d694b1b9c7c869ebb04ebe844ef5
```

当初指定されていた`a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0`では以下のようなエラーが出て処理が止まりました。
> An action could not be found at the URI 'https://api.github.com/repos/Azure/login/tarball/a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0' (0400:3AD212:266505:3239A1:6850F34E)

これを受け、現在最新のバージョン[Azure Login Action v2.3.0](https://github.com/Azure/login/releases/tag/v2.3.0)のハッシュ値`a457da9ea143d694b1b9c7c869ebb04ebe844ef5`へ差し替えてエラーを回避できました。

#### ハマりポイント: secretsの変数が消えて見えた

これに関しては以下の修正前の画像を見ていただくのが良いでしょう。

![hide_variables](/images/morihaya-20250624-copilot-agent-with-azure-mcp/2025-06-25-00-58-57.png)

この状況を見た時、私は強い違和感を覚えながらも「見慣れない記法だが省略できるってことか...?」と曲解してそのまま処理を走らせ、変数が未設定であるエラーを受けて悔しい思いをしました。

どうしてこうなっていたかは修正のためのPRを作成する時にわかりました。
以下は修正時の`git diff`の抜粋です。

```sh
            with:
-             client-id: ${{ secrets.AZURE_CLIENT_ID }}
-             tenant-id: ${{ secrets.AZURE_TENANT_ID }}
-             subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
+             client-id: {% raw %}${{ secrets.AZURE_CLIENT_ID }}{% endraw %}
+             tenant-id: {% raw %}${{ secrets.AZURE_TENANT_ID }}{% endraw %}
+             subscription-id: {% raw %}${{ secrets.AZURE_SUBSCRIPTION_ID }}{% endraw %}
```

GitHub Docsでは[Liquid template](https://github.com/Shopify/liquid)を使っているようで`${{ secrets.AZURE_CLIENT_ID }}`のような変換してしまう値は`{% raw %}${{ secrets.AZURE_CLIENT_ID }}{% endraw %}`のようにRaw指定しないと意図せぬ表示となるようです。

なお今回は各secretsを個別にRaw指定しましたが、GitHub Docsの他の部分ではコードブロックの前後に`{% raw %}`, `{% endraw %}`を配置して複数行をまとめてRaw指定とする記法もありました。
今後Liquidを使用した再利用文がコードブロック内に追加されることも考慮して、今回は変数ごとの指定としています。

#### ハマりポイント: job名のcopilot-setup-stepsは固定文字

この件はドキュメントではなく私のミスですが、以下のジョブ名`copilot-setup-steps`に対して、もっとシンプルな名前でよくない？と変更をおこないました。

```sh
jobs:
-  copilot-setup-steps:
+  setup:
```

その結果以下のエラーが発生して慌てて戻しました。
> No `copilot-setup-steps` job found in your `copilot-setup-steps.yml` workflow file. Please ensure you have a single job named `copilot-setup-steps`. For more details, see https://gh.io/copilot/actions-setup-steps.

ドキュメントにも正しく[以下の記載](https://docs.github.com/en/copilot/customizing-copilot/customizing-the-development-environment-for-copilot-coding-agent#preinstalling-tools-or-dependencies-in-copilots-environment)がありますので、皆さんも勝手に変更するのはやめましょう。
> A copilot-setup-steps.yml file looks like a normal GitHub Actions workflow file, but must contain a single copilot-setup-steps job. This job will be executed in GitHub Actions before Copilot starts working.

### 4. 対象のGitHubリポジトリのEnvironmentの`copilot`へ、`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`シークレットを追加

この手順についてはとくに迷うことはありませんでした。強いてあげるなら普段設定し慣れている`Secrets and variables`ではなく、`Environments`の方で設定することに注意です。

![environment](/images/morihaya-20250624-copilot-agent-with-azure-mcp/2025-06-25-01-18-32.png)


### 5. 対象のGitHubリポジトリのCopilotのCoding agentの`MCP Configuration`に`Azure`オブジェクトを追加して、Azure MCP serverを設定

こちらも手順としては簡単で、サンプルのAzure MCP serverのJSONを、`Coding agent`の`MCP configuration`へ貼り付けるだけのはずでしたが、簡単には通りませんでした。

```json
{
  "mcpServers": {
    "Azure": {
      "command": "npx",
      "args": [
        "-y",
        "@azure/mcp@latest",
        "server",
        "start"
      ],
      "tools": ["*"]
    }
  }
}
```

### ハマりポイント: MCPサーバ名の誤り

以下は修正時の`git diff`の抜粋です。

```sh
    {
      "mcpServers": {
-       "Azure MCP server": {
+       "Azure": {
```

おそらく仕様変更があったのでしょう。本記事執筆時点で`Azure MCP server`として入力すると以下のエラーが出てMCPの設定を保存できない状態となっています。
> Schema validation failed: /mcpServers must NOT have additional properties

![mcp_server_name_errors](/images/morihaya-20250624-copilot-agent-with-azure-mcp/2025-06-25-01-24-05.png)

当初修正する方法にまったく当たりがつきませんでしたが、休憩や別作業などによってリフレッシュを行ったことでアイデアが浮かびました。

具体的には手元のVisual Studio Codeへインストール済みのMCP設定を見直したところ、`Azure`と設定されていたためトライしたところ、つぎに紹介するエラーメッセージに代わり、正しい名前が`Azure`だと気づけました。

### ハマりポイント: toolsスキーマが必要

MCPサーバ名を修正したところ以下のエラーが発生しました。
> Schema validation failed: /mcpServers/Azure must have required property 'tools'

![tools_error](/images/morihaya-20250624-copilot-agent-with-azure-mcp/2025-06-25-01-36-32.png)

これはエラーメッセージがとても親切だったため、他のMCPの定義を参考にして簡単に修正することができました。

以下は修正時の`git diff`の抜粋です。

```sh
-         ]
+         ],
+           "tools": ["*"]
```

## ついにAzure MCP serverが動いた！

こうしていくつかのトラブルシュートを乗り越え、Coding agentがAzure MCP serverを使って処理をした時は感動的で、思わず快哉を叫びました。

その時のCoding agentへお願いしたIssueの内容は「Azure MCP serverを利用して、Subscriptionの一覧を取得し、azure_subscriptions.mdに保存して」と言ったものですが、問題なく動作してくれました。

## この結果を受けてGitHub Docsの修正にとりかかる

正直な話、当日は無事にCoding agentのAzure MCP server環境がセットアップできたことで、自分としては解決とし次のタスクに移りました。

しかしながら公式ドキュメントの誤りを放置することは、自分と同じようなトラブルシュートを他の方に強いることと同義です。
私はこれまでGitHub Docにコミットしたことはありませんでしたが、”オープンと感謝のマインド”を奮い立たせてでもう一踏ん張りすることにしました。

実際に修正に取り掛かると、GitHub Docsのコントリビューションの入口はとてもわかりやすいものでした。
各ページのフッターに以下の文言が表示されており、簡単に[Contribution Guide](https://docs.github.com/en/contributing)に行き着くことができます。

私はとくに以下の文章にも勇気をもらいました。GitHub社のオープンマインドな素晴らしい姿勢を体現した文だと感じます。

> All GitHub docs are open source. See something that's wrong or unclear? Submit a pull request.

![docs_welcome](/images/morihaya-20250624-copilot-agent-with-azure-mcp/2025-06-25-01-46-53.png)

### 作成したGitHub Issue

こうして作成したのが以下のIssueです。AIや翻訳ツールの支援をうけつつ、画像を添付してわかりやすさを意識しました。

https://github.com/github/docs/issues/39016

実のところ先にPRを準備したのですが、PRテンプレートに「先にIssueを作成した方が良いよ」とあったため、PRをSubmitする前にこちらのIssueを改めて作成しました。

### 作成したGitHub Pull Request

Issueに続いて取り込んでいただいたPRがこちらです。上述したハマりポイントについて修正する旨を記載しています。

https://github.com/github/docs/pull/39017

## PRの取り込みはわずか数時間で

心底驚いた点として、上記のPRは作成からわずか4時間程度でマージしていただけました。

GitHubの公式ドキュメントは世界中に利用者がいる巨大なリポジトリです。
執筆時点でのStar数も`17.5K`と多くの方が高い関心があるリポジトリで、数時間でマージされる驚異的なスピード感に感激したことを明記します。

![github_docs](/images/morihaya-20250624-copilot-agent-with-azure-mcp/2025-06-25-01-55-19.png)

## おわりに

以上が「GitHub Copilot Coding AgentのAzure MCP server設定のハマりからGitHub Docs修正まで」の記事でした。

私たちの日常的なタスクにおいて、まだまだGitHub Copilot Coding Agentの活用範囲は限定的です。
モデル自体の進化、MCPでの外部情報の参照、そして私たち利用する人間の練度を上げながら組織やプロダクト、そしてお客様に価値を届けていければと考えています。

そして、もしみなさんもドキュメントの不備や改善点に気づいた際は、ぜひOSSの思想にのっとって一緒に貢献していきましょう！

それではみなさま Enjoy GitHub Copilot Coding Agent with MCP servers!!

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味をもった方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![イオングループエンジニア採用バナー](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recruiting.aeon.info/)
