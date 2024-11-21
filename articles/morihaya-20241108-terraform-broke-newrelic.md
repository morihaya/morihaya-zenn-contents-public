---
title: "私はNew RelicのDashboardをTerraformで吹っ飛ばしました、あなたは気をつけて"
emoji: "🔨"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: # タグを指定する
  - "NewRelic"
  - "Terraform"
  - "aeon"
published: true
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。

本記事では、私が引き起こしてしまったNew RelicのDashboardをTerraformで吹っ飛ばした（デグレさせた）話を紹介します。
当社と同じようにNew RelicのDashboardをTerraformで管理されている皆様が同じ過ちを起こさないための一助となれば幸いです。

## TL;DR

本記事を箇条書きでまとめると以下です。

- 当社では一部の環境のNew RelicのDashboardをTerraformで管理している
- ただしDashboardはWeb画面での変更が手動で行われる状況
- 今回、Azureの新しいSubscriptionを既存のNew Relicアカウントに追加しようとした
- `terraform plan`の結果は`+`のみで `-` がないため問題ないと判断して `terraform apply`してしまった

この流れによって、Web画面から手動で行われた変更でTerraform側に未反映の設定がロールバックされることになり、せっかくDashboardを育ててくれた担当者に作り直していただく必要が発生しました。

## 背景

当社では[Azure DevOps](https://azure.microsoft.com/ja-jp/products/devops/)の[Repos](https://azure.microsoft.com/ja-jp/products/devops/repos/)と[HCP Terraform](https://developer.hashicorp.com/terraform)を利用し、Azureの主要リソースやNew Relicなど、さまざまなプロダクトの管理をTerraformで管理し、VCSとしてADOを利用し、HCP TerraformでCI/CDを行なっています。

ここ数週間かけて、私は負荷試験を行うための環境を新しいAzure Subscription上に構築してきました。
Azureリソースの構築がひと段落し、次はオブザバビリティのためのNew Relicのセットアップに着手しました。
Azureリソース管理のTerraformコードには慣れてきていた私は、New RelicのTerraformコードの変更にも果敢に挑戦しましたが、コードの理解が浅い状態で作業を進めてしまい今回の「New RelicのDashboardをTerraformで吹っ飛す」ことに繋がってしまいました。

## New RelicのDashboardをTerraformで管理する場合の選択肢

もちろんHCP TerraformによるCIで`terraform plan`の結果は確認していましたが、New RelicのDashboardのplan結果はAzureリソースとは仕様が異なっていたのです。

前提として、New RelicのDashboardをTerraformで管理する場合、以下の3つのResourceを選択できます。

- [newrelic_one_dashboard](https://registry.terraform.io/providers/newrelic/newrelic/latest/docs/resources/one_dashboard)
- [newrelic_one_dashboard_json](https://registry.terraform.io/providers/newrelic/newrelic/latest/docs/resources/one_dashboard_json)
- [newrelic_one_dashboard_raw](https://registry.terraform.io/providers/newrelic/newrelic/latest/docs/resources/one_dashboard_raw) *最新に対応していないため `_json` を推奨

当社の場合、2点目のnewrelic_one_dashboard_jsonを利用していました。

## newrelic_one_dashboard_jsonは差分ではなく洗い替えする

newrelic_one_dashboard_jsonはその名前の通り、Dashboardの定義を通常のTerraformのパラメタとして指定するのではなく、定義済みのJSONファイルを指定します。

```hcl
resource "newrelic_one_dashboard_json" "foo" {
   json = file("dashboard.json")
}
```

`terraform plan`実行時、Terraformに指定したJSONファイルの内容と実際のDashboardとの間に差異があった場合、パラメタ個別の比較は行われず単純に洗い替えとしてすべて追加として表示される仕様となっています。

具体的には以下のように

> "~ json       = "The dashboard has been changed: updating" -> jsonencode("
 
として全ての値が`+`として表示されるのです。

```
 # module.dashboards.newrelic_one_dashboard_json.rocketmq[0] will be updated in-place
  ~ resource "newrelic_one_dashboard_json" "rocketmq" {
        id         = "hogehoge"
      ~ json       = "The dashboard has been changed: updating" -> jsonencode(
            {
              + description = null
              + name        = "RocketMQ"
              + pages       = [
                  + {
                      + description = null
                      + name        = "RocketMQ"
                      + widgets     = [
                          + {
                              + layout            = {
                                  + column = 1
                                  + height = 3
                                  + row    = 1
                                  + width  = 4
                                }
                              + linkedEntityGuids = null
                              + rawConfiguration  = {
                                  + facet           = {
                                      + showOtherSeries = false
                                    }
                                  + legend          = {
                                      + enabled = true
                                    }
                                  + nrqlQueries     = [
                                      + {
                                          + accountIds = [
                                              + 1234567,
                                            ]
                                          + query      = "SELECT latest(rocketmq_producer_offset) - latest(rocketmq_consumer_offset) FROM Metric FACET topic WHERE cluster LIKE 'prod%' TIMESERIES 5 minutes LIMIT MAX"
                                        },
                                    ]
                                  + platformOptions = {
                                      + ignoreTimeRange = false
                                    }
(途中略)
        )
        # (4 unchanged attributes hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

これをapplyした結果、planとしては`+`しか表示されていなくても、Dashboardに手動で追加してくれていた複数枚のグラフが消失する結果となりました。

つまり、実態としては`-`されるグラフがいくつもありましたが、洗い替えのため上記のように`+`表示で不足したダッシュボードのパラメタが表示されていたのです。この大量の`+`結果を見て既存のDashboardからグラフが減ることを目視で検知するのは容易ではありません...

## どのように対策していくのか

この反省を受けて、チームで対策を検討していかねばなりません。

具体的には以下のような案を考えていますが、多くのプロダクトが存在する中でどの案を選択し、共通方針とするのか個別化するのかは今後の相談となります。

- New RelicのDashboardはWeb画面から変更しがちであるため、Terraform管理をやめてしまう
- 固い意志でWeb画面からの変更を禁止し、Terraformでのみ変更を行う
- newrelic_one_dashboard_jsonは洗い替えになってしまうため、newrelic_one_dashboardのパラメタ指定のリソースへ移行する

折衷案として、Web画面からの変更を禁止するのは環境によっては困難に感じますが、「TerraformではあくまでテンプレートとしてのDashboardを作成しそれは変更を禁止するが、コピーしたDashboardは好きにWeb画面から変更して良い」などの運用も考えられます。

## おわりに

以上が「私はNew RelicのDashboardをTerraformで吹っ飛ばしました、あなたは気をつけて」の紹介でした。

今回`terraform plan`の結果をざっとみて「`+`しか出てないし、新しいSubscription用に作成される差分だと思うからヨシッ！」と軽はずみな判断をしたことを大変悔やんでいます。類似の状況におられる皆様はぜひ気をつけてください。

それではみなさまEnjoy New Relic & HCP Terraform！

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味もった方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![AEON TECH HUB](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recuruiting.aeon.info/)
