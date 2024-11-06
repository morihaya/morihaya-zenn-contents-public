---
title: "HCP TerraformでVCS Triggerが動かないときに強制的にキックする技"
emoji: "🦵"
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

本記事では、当社で利用しているVCSのひとつAzure DevOps Repos（以降はADO）と連携してCI/CDを実現するHCP Terraformにおいて、HCP Terraform側がなぜかADO側の変更イベントを検知せずCI/CDが実行されない状況への対策を紹介します。

:::message alert
この方法を利用することで、本来行われるべき適切なフローをスキップできる可能性があります。
「大いなる権限には、大いなる責任が伴う」ことを忘れず、非常時の適切なタイミングでのみご利用ください。
:::

## TL;DR

本記事を箇条書きでまとめると以下です。

- ADOにPRやPushを行っても、HCP TerraformでRunが自動で動作しない事象が散発した
- さらに、自動でRunが動作しないだけでなく、mainブランチの最新Commitを取得しない事象も発生した
- 対策として、HCP TerraformのVCS TriggersのVCS branchの設定を変更することで即座にRunを実行した


## 背景

当社では[ADO](https://azure.microsoft.com/ja-jp/products/devops/)の[Repos](https://azure.microsoft.com/ja-jp/products/devops/repos/)と[HCP Terraform](https://developer.hashicorp.com/terraform)を利用し、Azureの主要リソースやNew Relicなど、さまざまなプロダクトの管理をTerraformで管理し、VCSとしてADOを利用し、HCP TerraformでCI/CDを行なっています。

![雑なシーケンス図](/images/morihaya-20241107-hcp-terraform-force-run/2024-11-07-01-40-29.png)

## HCP TerraformのCIが動作しない事象

ある日、いつも通りにリソースチューニングのためのTerraformコード変更のPRを作成し、CI結果を見て追加修正のcommitをPushしたところ、HCP Terraform側のCIが動作しませんでした。

![](/images/morihaya-20241107-hcp-terraform-force-run/2024-11-07-01-48-10.png)

これに対し、ローカルのターミナルからCLIで `terraform plan` を実施すれば意図したブランチで実行することができるため、レビュワーに対してはPRメッセージに手動実行したHCP TerraformのRunのURLを記載しておくことで一応はレビューを回すことができました。

## ADO側でマージしてもHCP Terraformが最新コミットを取得しない事象

次に発生したのが、ADOでマージしたタイミングで実行されるはずの`terraform apply`を行うRunが、HCP Terraformで実行されない事象です。

この状態でさらに困ったのが、HCP Terraform側で手動でRunを実行しても最新のCommitをHCP Terraformが取得しない状態になりました。

当社は基本HCP TerraformをRemoteでの実行に限定しているため、`terraform plan`のようにローカルで実行することはできません。

具体的にはローカルのターミナルから`terraform apply`を実行すると以下のようにエラーとなります。

```sh
$ terraform apply
╷
│ Error: Apply not allowed for workspaces with a VCS connection
│ 
│ A workspace that is connected to a VCS requires the VCS-driven workflow to ensure that the VCS remains the single source of truth.
```

## 2つの回避策

この状態になり、試行錯誤した結果2つの回避策を発見しました。
本題でもあるブログタイトルの「強制キックする」方法は回避策その2になるため、回避策その1は興味がなければ飛ばしてください。

### 回避策その1 terraform applyのローカル実行を許可する

最初に行ったのがこちらの方法です。
上述したように通常はローカルのターミナルで`terraform apply`を行うとエラーになります。

しかし、HCP TerraformのWorkspace SettingのGeneralにてExecution Modeを変更してローカル実行を可能にできます。

暫定回避策として一時的にLocalに変更して`terraform apply`を行いました。

![](/images/morihaya-20241107-hcp-terraform-force-run/2024-11-07-02-01-44.png)

しかしながらこの方法には問題があります。

通常であればHCP TerraformのVariablesに設定された各種クレデンシャルや環境情報などを、ローカルのターミナルで漏れなく設定する必要があります。

もちろんTerraformのインストールも必要ですし、バージョンも適切なものを利用しなければなりません。

緊急対応としていざという時に行える準備は必要かもしれませんが、積極的に行いたいものでもありません。

### 回避策その2 VCS Trigger設定を変更して強制キックする

本題がこちらです。事象が別のリポジトリでも散発する中で、都度ローカル実行を行うには負荷が高く別の方法を模索しました。

結果わかったこととして、WEBの操作でHCP TerraformのRunを強制的にキックさせ、しかも最新のCommitを取得させる方法がわかりました。


具体的にはHCP Terraformの画面にて以下のように操作します。

1. 対象のWorkspaceの画面から[Settings]
2. Workspace Settingsの画面から[Version Control]
3. Version Controlの画面から[VCS Trigger]セクションの[VCS branch]に対し、取得させたい最新Commitを持つブランチを指定する（通常はmain）

![](/images/morihaya-20241107-hcp-terraform-force-run/2024-11-07-02-13-16.png)

当社のケースではVCS branchは通常はブランクとなっており、ADO側のデフォルトブランチであるmainが通常は利用されます。
しかし、今回のようにHCP Terraformが通常の動作でmainを取得しない状況において、VCS branchにmainを入力することで、強制的にmainブランチの最新Commitを取得させることができました。

### レビューフローを壊しかねないため、いざという時のみ使おう

冒頭でも警告した通り、この方法を使えばレビュー前の任意のブランチ選択して`terraform apply`を実行させることが可能です。

この方法を確立した際、私はローカル実行より簡易に行える回避策が見つかった喜び以上に、HCP TerraformでWorkspace Settingを変更できる権限の大いなる責任を改めて感じました。当然のこととしてHCP Terraformにおいても適切な権限の運用が必要ですし、強い権限を持ちがちな私たちSREチームはより身を正さねばなりません。

## おわりに

以上が「HCP TerraformでVCS Triggerが動かないときに強制的にキックする技」でした。

通常はADOから変更イベントをPushで受け取るHCP Terraformが、VCS Triggerの変更時はPullでADOに取得しに行くこの動きは、個人的に興味深いものでした。

また、本事象は各サポートのご支援を受けつつ根本原因の調査中です。無事に解決できましたら後日追記または別記事にてご紹介ご紹介予定です。

それではみなさまEnjoy Azure DevOps & HCP Terraform！

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味もった方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recuruiting.aeon.info/)
