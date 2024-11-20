---
title: "HCP TerraformでVCS Triggerが動かない問題が解決できました"
emoji: "✌️"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: # タグを指定する
  - "Hashicorp"
  - "AzureDevOps"
  - "Terraform"
  - "CICD"
  - "aeon"
published: false
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。

本記事は、以前公開した[HCP TerraformでVCS Triggerが動かないときに強制的にキックする技](https://zenn.dev/aeonpeople/articles/morihaya-20241107-hcp-terraform-force-run)で起きていた問題のアンサー記事（解決方法の紹介）になります。

前記事で発生していた問題は「当社で利用しているVCSのひとつAzure DevOps Repos（以降はADO）と連携してCI/CDを実現するHCP Terraform（以降はHCPt）において、HCPt側がなぜかADO側の変更イベントを検知せずCI/CDが実行されない」問題でした。

さらに具体的に記述すると「ADOでPull Request（以降はPR）を作成し、そのPRに追加でCommitをPushした際、HCPtのRunが実行されない状況が頻発」していました。

前記事では暫定対策の「`VCS branch`を一時的に変更する技」を紹介しましたが、本記事では解決策をご紹介します。

:::message
なお解決にはHashiCorp社のサポートチームに多大なご協力をいただきましたことに、心から感謝申し上げます。
:::

## TL;DR

本記事を箇条書きでまとめると以下です。

- ADOのPRに追加CommitをPushしても、HCPtでRunが自動で動作しない事象が発生
- 原因は発生するHCPtのWorkspaceの設定で`Patterns`指定をしているのに`Path`が未入力だった
- 対策として`Path`に`Terraform Working Directory`と同等の文字列を設定して解決


## 背景
＊背景はほぼ前記事の引用です。

当社では[ADO](https://azure.microsoft.com/ja-jp/products/devops/)の[Repos](https://azure.microsoft.com/ja-jp/products/devops/repos/)と[HCPt](https://developer.hashicorp.com/terraform)を利用し、Azureの主要リソースやNew Relicなど、さまざまなプロダクトの管理をTerraformで管理し、VCSとしてADOを利用し、HCP TerraformでCI/CDを行なっています。

![雑なシーケンス図](/images/morihaya-20241107-hcp-terraform-force-run/2024-11-07-01-40-29.png)

## HCP TerraformのCIが動作しない事象

ある日、いつも通りにリソースチューニングのためのTerraformコード変更のPRを作成し、CI結果を見て追加修正のcommitをPushしたところ、HCP Terraform側のCIが動作しませんでした。

![](/images/morihaya-20241107-hcp-terraform-force-run/2024-11-07-01-48-10.png)

## HashiCorpの頼れるサポートチームへ支援要請

HashiCorp社の製品は[Help Center](https://support.hashicorp.com/hc/en-us)のページからサポートチケットを作成できます。

＊チケットの起票の言語について、記事を執筆している2024-11-21時点では英語対応のみとのことですが、翻訳手段の充実した今日ではさほど問題ではありませんでした。

![](/images/morihaya-20241121-hcp-terraform-fix-run/2024-11-21-01-42-55.png)

チケット作成はシンプルなフォームで好感が持てます。
個人的な推奨として `CC(optional)` にメーリングリストやSlackチャンネル向けのアドレスを入れておくことをオススメします。
作成したチケットは基本自分のみ参照が可能で、チームへの連携をする場合は現状`CC(optional)`しか直接的な手段がないためです。

![](/images/morihaya-20241121-hcp-terraform-fix-run/2024-11-21-01-49-45.png)

## 原因：Patternsを指定しつつPathに何も入力していない状態

数度のサポートポータルでのやりとりではなかなか解決に至らず、オンラインMTGで調査・切り分けを行ったところ原因と思われる設定を特定できました。

具体的にはWorkspaceの[Settings]->[Version Control]->[VCS Triggers]->[Automatic Run triggering]セクションにおいて、"Only trigger runs when files in specified paths change"を指定し、"Patterns"を選択している状態で、Pathに何も入力していない状態だったのです。

![](/images/morihaya-20241121-hcp-terraform-fix-run/2024-11-21-01-59-58.png)

### どうしてこんな設定が行われていたのかの推測

このような「"Patterns"を指定しながら"Path"に何も入力しない」状況は一見不思議に思えるかもしれません。
実を言えば数多くあるHCPtのWorkspaceにおいてすべてのPathが未入力ではなく、多くのWorkspaceでは"Terraform Working Directory"と同等の値を入力していました。

具体的には以下のような入力です。

- ex)
  - Terraform Working Directory: systems/morihaya/production
  - Patterns Path: /systems/morihaya/production/*.tf

### コード管理すると気付きづらい状況だったのでは？

Pathが未入力な理由について、当時の担当者が不在なため私個人の推測になりますが、おそらくWorkspaceの設定をWebコンソールからではなくTerraformで行っていたことで違和感に気付きづらい状況だった可能性があります。

SREチームではHCPtの設定も[tfe_workspace](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/workspace)を利用してTerraformで管理しています。

そして実際のTerraformのコードは以下のようになります。

#### Module

まずは呼び出されるmoduleです。

```hcl
## Resource
resource "tfe_workspace" "main" {
  for_each = var.workspaces_map_info

  name                  = each.value.name != null ? each.value.name : each.key
  project_id            = var.project_id
  allow_destroy_plan    = each.value.allow_destroy_plan
  auto_apply            = each.value.auto_apply
  queue_all_runs        = each.value.queue_all_runs
  file_triggers_enabled = each.value.file_triggers_enabled
  speculative_enabled   = each.value.speculative_enabled
  terraform_version     = each.value.terraform_version
  working_directory     = each.value.working_directory
  trigger_patterns      = each.value.trigger_patterns
  tag_names             = each.value.tag_names
  description           = each.value.description != null ? each.value.description : ""
  vcs_repo {
    identifier     = each.value.vcs_repo.identifier
    branch         = each.value.vcs_repo.branch
    oauth_token_id = var.oauth_token_id
  }
}

## Variables
variable "workspaces_map_info" {
  description = "Workspaces Information"

  type = map(object({
    # Workspace Settings
    name                  = optional(string, null)
    allow_destroy_plan    = optional(bool, false)
    auto_apply            = optional(bool, false)
    queue_all_runs        = optional(bool, false)
    file_triggers_enabled = optional(bool, true)
    speculative_enabled   = optional(bool, true)
    terraform_version     = string
    working_directory     = string
    trigger_patterns      = optional(list(string), null)
    tag_names             = optional(list(string), null)
    vcs_repo = optional(object({
      identifier = string
      branch     = optional(string, null)
    }))
    description = optional(string, null)

    # Notification Settings
    notification_name             = optional(string, "Slack - notify-terraform")
    notification_destination_type = optional(string, "slack")
    notification_url              = optional(string, "https://hooks.slack.com/services/hoge/fuga/piyo")
    notification_triggers = optional(list(string),
      [
        "run:created",
        "run:planning",
        "run:needs_attention",
        "run:applying",
        "run:completed",
        "run:completed",
        "run:errored",
        "assessment:drifted",
        "assessment:failed",
      ]
    )
    notification_enabled = optional(bool, true)
  }))
}
```

#### Root directory

Moduleを呼び出すルートディレクトリの例です。

```hcl
## Variables
variable "morihaya_workspaces_map_info" {
  description = "morihaya Workspaces Information"

  default = {
    Azure_RM-morihaya-Test-Common_Resources = {
      terraform_version = "latest"
      working_directory = "systems/morihaya/test/"
      trigger_patterns = [
        "/systems/morihaya/test/*.tf",
      ]
      tag_names = [
        "azurerm",
        "morihaya",
        "test",
      ]
      vcs_repo = {
        identifier = "hoge/SRE/_git/morihaya"
      }
      notification_name = "Slack - notify-terraform-morihaya"
      notification_url  = "https://hooks.slack.com/services/hoge/fuga/piyo"
    }
  }
}

## Call module
module "morihaya" {
  source = "hoge/piyo/modules/workspace"

  project_id          = tfe_project.main["morihaya"].id
  oauth_token_id      = var.ado_oauth_token_id
  workspaces_map_info = var.morihaya_workspaces_map_info
}
```

### 気付きづらいポイント

ルートディレクトリ側のVariableの以下の部分に注目です。以下の部分で1つのHCPtのWorkspaceの設定が表現されています。

```hcl
(...略...)
    Azure_RM-morihaya-Test-Common_Resources = {
      terraform_version = "latest"
      working_directory = "systems/morihaya/test/"
      trigger_patterns = [
        "/systems/morihaya/test/*.tf",
      ]
      tag_names = [
        "azurerm",
        "morihaya",
        "test",
      ]
      vcs_repo = {
        identifier = "hoge/SRE/_git/morihaya"
      }
      notification_name = "Slack - notify-terraform-morihaya"
      notification_url  = "https://hooks.slack.com/services/hoge/fuga/piyo"
    }
  }
(...略...)
```

そして問題が発生していたPathが未入力だったWorkspaceでは以下のようになっていました。

```hcl
(...略...)
    Azure_RM-morihaya-Test-Common_Resources = {
      terraform_version = "latest"
      working_directory = "systems/morihaya/test/"
      tag_names = [
        "azurerm",
        "morihaya",
        "test",
      ]
      vcs_repo = {
        identifier = "hoge/SRE/_git/morihaya"
      }
      notification_name = "Slack - notify-terraform-morihaya"
      notification_url  = "https://hooks.slack.com/services/hoge/fuga/piyo"
    }
  }
(...略...)
```

そう、`trigger_patterns = [`の部分が記述されていませんでした。
そしてこのコードで`terraform apply`を行ってもエラーは発生せずに、結果として「"Patterns"を指定しながら"Path"に何も入力しない」Workspaceが作成されるのです。

### HCPt側の内部仕様にも変更があったかもしれない（可能性）

原因としては「"Patterns"を指定しながら"Path"に何も入力しない」状態と特定できましたが、一方この状態で2年近く運用できていたことを考えるとHCPt側になんらかの変更があった可能性があります。（あくまで可能性であり、サポート回答をいただいたものではなく推測になります）

しかし、”Path”が入力されていないのは違和感のある状態であり、今回の発見を前向きに捉え適切な値を”Path”に入力していくことにしました。

## 対策：Patternsを指定しPathも指定する

対策はシンプルに「"Patterns"を指定した場合、"Path"も指定する」です。

多くの場合ひとつのリポジトリに複数のディレクトリがあるため、以下のようにPathはWorking Directoryとほぼ同様の記述となります。

- ex)
  - Terraform Working Directory: systems/morihaya/production
  - Patterns Path: /systems/morihaya/production/*.tf

Webコンソールでは以下のようになります。

[Settings]->[Version Control]->[VCS Triggers]->[Automatic Run triggering]->"Only trigger runs when files in specified paths change"->"Patterns"->Path
![](/images/morihaya-20241121-hcp-terraform-fix-run/2024-11-21-02-41-07.png)

Terraformで管理するなら`trigger_patterns`を記載します。

```hcl
(...略...)
    Azure_RM-morihaya-Test-Common_Resources = {
      terraform_version = "latest"
      working_directory = "systems/morihaya/test/"
      trigger_patterns = [     # <- ⭐️⭐️⭐️⭐️⭐️ patternsを絶対忘れるな！
        "/systems/morihaya/test/*.tf",
      ]
      tag_names = [
        "azurerm",
        "morihaya",
        "test",
      ]
      vcs_repo = {
        identifier = "hoge/SRE/_git/morihaya"
      }
      notification_name = "Slack - notify-terraform-morihaya"
      notification_url  = "https://hooks.slack.com/services/hoge/fuga/piyo"
    }
  }
(...略...)
```

こうして無事に恒久対応を行えました。

## おわりに

以上が「HCP TerraformでVCS Triggerが動かない問題が解決できました」の内容です。
同じ事象にハマる方がそうそういるとは思えませんが、ひとつの事例として紹介いたしました。

また、[HCP TerraformでVCS Triggerが動かないときに強制的にキックする技](https://zenn.dev/aeonpeople/articles/morihaya-20241107-hcp-terraform-force-run)の問題を無事に解決できたのでホッとしています。

最後に、協力いただいたHashiCorpのサポートチームに改めて感謝をお伝えいたします！！

それではみなさまEnjoy Azure DevOps & HCP Terraform！

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味もった方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recuruiting.aeon.info/)
