---
title: "HCP TerraformのRegistryのmoduleが更新されなかったので再Publishで解決しました"
emoji: "🔮"
type: "tech"
topics:
  - "terraform"
  - "terraformcloud"
  - "aeon"
  - "hcpterraform"
published: true
published_at: "2024-05-23 09:00"
publication_name: "aeonpeople"
---

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。

本記事ではHCP TerraformのRegistryのmoduleが、突然module自体のコードを格納するレポジトリ側を更新しても反映されなかった問題について紹介します。

![](https://storage.googleapis.com/zenn-user-upload/5f61799d50da-20240523.png)



## TL;DR
本記事の要点です。

- ある日、突然HCP TerraformのRegistryのバージョン更新が行われなくなった
- タイミング的にHCP Terraformの整備を行っていたメンバの退職によるアカウント削除後...？
    - つまりアカウント削除した個人に紐づいた認証情報が残っていて動かなくなっている？
- どうにもならないので、該当moduleを一度削除し、再度Publishして復旧

## 背景
当社ではAzureやNew RelicをはじめSREチームが管理する様々なSaaSやクラウド環境をIaC(Infrastructure as Code)で管理しています。（一部の例外はたくさんあります...）

IaCツールとしてはTerraformを採用しており、リポジトリにAzure (DevOps) Reposを利用し、CIおよびCDをHCP Terraformで行っています。

https://engineer-recuruiting.aeon.info/aeon-tech-hub/event-report_CloudNativeWeek2024W

Terraformのコードの基本方針として、Resourceの作成は自社製moduleにまとめておき、各プロダクトは自社製moduleをvariables.tfで呼び出す形になっています。

自社製moduleもAzure Reposで管理しており、Tagによってバージョン管理をしていました。
しかしある日、突然Tagによるバージョン更新がAzure ReposからHCP Terraform Registryに連携されない事象が発生しました。

## 調査
正直言って当初は調査のとっかかりに困りました。
強調しておきたい点として、HCP TerraformのWeb画面はシンプルで感覚的に操作が行える素敵な仕様です。（感想は個人差があります）

しかし今回のような問題が発生した時に、エラーや状況を調べるための"Diagnostic"機能は"VCS Event"と呼ばれるものが用意されていますが、そこに何も出ていない場合に打つ手がなくなります。

「Supportに起票するしかないか」と考えたところで、念の為社内Slackを検索したところ、同僚氏が同様の問題に過去遭遇しており、moduleのHCP Terraform上での削除と再Publishによって復旧していたことがわかりました。

## 対策
上述したように、対策はシンプルにmoduleの削除と再Publishです。

1. HCP Terraformにログイン
2. 該当のOrganizationへログイン
3. "Registry"をクリック
4. ”Modules”をクリック
5. 対応したいModuleをクリック
6. 右側にある”Manage Module for Organization”をクリック
7. "Delete module"をクリック
8. ポップアップが表示されるため `delete` と入力してDeleteをクリック
    - "Delete all providers and versions for this module"の選択も複数Verは必要
9. あとは通常のPublishの手順で再度Publishを行う

参考までにいくつかスクリーンショットを記載します。

### 参考：7. "Delete module"をクリック
削除の方法は初見だと少々わかりづらいかもしれません。"Delete module"のメニューが”Manage Module for Organization”の下に隠れているからです。

図を見ていただければ簡単に辿り着けるのではないでしょうか。

![](https://storage.googleapis.com/zenn-user-upload/f1c04d2bf6d7-20240523.png)


### 参考：8. ポップアップが表示されるため `delete` と入力してDeleteをクリック
この画面は良くある形式であまり迷う方はいないかもしれませんが、注意すべき点があります。

moduleが複数バージョンある場合"Delete all providers and versions for this module"を選択する必要があります。デフォルトのままではカレントのバージョンが削除されるだけになり、裏で持っている認証情報（？）が削除されないためです。（私はこれにもハマりました）

![](https://storage.googleapis.com/zenn-user-upload/1f96a6dcfcf9-20240523.png)

`delete` を入力するタイプの警告は良くある形式で迷わないでしょうが、一段階確認が挟まっているのは好ましいと感じます。
![](https://storage.googleapis.com/zenn-user-upload/4654c389fc66-20240523.png)


## 今後への課題
上記のmodule削除->再Publishによって復旧できましたが、今後への課題が残ります。
人材の流動性の高い昨今、様々な理由でチームメンバが入れ替わることは将来的に起こり得ることです。

今回はWeb画面からのGUIによるハートフルな手動による対応を行いました。これは自社製moduleの数が十数程度と多くはないことが理由の一つですが、別の理由としてTerraformによるIaC管理が行われていない範囲だったことが大きいです。

HCP Terraform RegistryはHashiCorpのサービスだけに当然のようにResource `tfe_registry_module` によってTerraform管理が可能なっています。

https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/registry_module

仮に全ての自社製moduleがTerraformとして記述されていたら、一括で全てをコメントアウトして削除し、再びコメントを外して一括再登録が可能だったはずです。

今回の反省を受けて、粛々と `tfe_registry_module` の `terraform import` を行うチケットを作成し、次のタイミングに向けて備えていかねばなりません。（それか、HashiCorpさん側でいい感じに一括対応できる機能を追加してくれるか...）

## 終わりに
以上「HCP TerraformのRegistryのmoduleが更新されなかったので再Publishで解決した」事象の紹介でした。

本記事によって同じハマり方をしている皆様が早く対応できることを願っています。

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味もった方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recuruiting.aeon.info/)