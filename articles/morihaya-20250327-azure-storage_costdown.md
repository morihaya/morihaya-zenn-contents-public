---
title: "Azure Storage accountsのオプション変更で年間2,000万円以上のコスト削減を達成しました"
emoji: "💰"
type: "tech"
topics:
  - "azure"
  - "azureblobstorage"
  - "azurestorage"
  - "コスト最適化"
  - "aeon"
published: false # false or true , スケジュール公開の場合はfalseで予約して後からtrueにFix必要
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。

本記事はAzureのマネージドなStorageである”Storage accounts”（以後はSA）のオプションを1つチューニングしたことで、年間2,000万円以上のコストダウンを達成した成果報告の記事となります。

なお私たちSREチームは日常的にリソースと信頼性とコスト最適化を模索しており、コストに関連する記事は以下のとおりです。

- [Azure異常コストアラート：犯人はResource groupの中にいる！](https://zenn.dev/aeonpeople/articles/fafb830ab8b341)
- [よく使うAzureのCost analysisはDaily costsとフィルタとグループ化の組み合わせ](https://zenn.dev/aeonpeople/articles/morihaya-20241209-azure-costanalysis)
- [Azure Database for MySQLのIOPS設定の変更で月額約100万円のコストダウンが実現しました](https://zenn.dev/aeonpeople/articles/morihaya-20250327-azure-mysql-iops3)

## TL;DR

- AzureのマネージドStorageサービスの"Storage accounts"の"access tier"の設定を"Hot"層から"Cool"層へ変更した
- 結果としてDailyで約6万円弱のコストダウンとなり、月額およそ180万円、年額で2160万円の削減が見込めた
- 日頃のコスト最適化のアンテナが気づきに繋がった、合言葉は「No Quick Win!」


## 成果報告

まずは端的に何を行いどんな成果につながったかを述べます。
本記事で伝えたいのは後半の”さまざまな気づきに至るチームの在り方”ですが、Howを先にお伝えします。

### Azure Storage accountsについて

前段としてAzure Storage accountsについて簡単に説明します。

https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blobs-overview

SAは、語弊がある言い方かもしれませんが「AWSのS3、Google CloudのCloud Storage」にあたるAzureのマネージドストレージのサービスです。
SAが両者と異なるのはオブジェクトストレージ（Blob）以外にもFile Shares, Queue, Tableの機能を有しており幅広いストレージの機能を有しています。

### コスト削減に効いたStorage accountsの仕組み

SAのBlobには"アクセス層 (Access tiers)"と呼ばれる課金体系が異なる階層が用意されています。
具体的には以下の4種が存在しています。（このあたりはS3もCloud Storageにもある馴染みある仕組みですね）

- ホット アクセス層 - 頻繁にアクセスまたは変更するデータの保存に最適なオンライン層。 ホット アクセス層はストレージ コストが最も高く、アクセス コストは最も安いです。
- クール アクセス層 - アクセスおよび変更の頻度が低いデータの保存に最適なオンライン層。 クール アクセス層のデータは、最低 30 日間は保存する必要があります。 クール アクセス層は、ホット アクセス層と比べてストレージ コストが安く、アクセス コストが高いです。
- コールド アクセス層 - めったにアクセスされたり、変更されたりしないが、それでも高速で取得できなければならないデータを格納するために最適化されたオンライン層。 コールド アクセス層のデータは、最低 90 日間は保存する必要があります。 コールド アクセス層は、クール アクセス層と比べてストレージ コストが安く、アクセス コストが高くなります。
- アーカイブ アクセス層 - めったにアクセスせず、数時間規模の待機時間の変動を許容できるデータ保存に最適なオフライン層。 アーカイブ アクセス層のデータは、最低 180 日間は保存する必要があります。

＊上記は[ドキュメントより引用](https://learn.microsoft.com/ja-jp/azure/storage/blobs/access-tiers-overview)

これらのアクセス層を見直すことでコスト最適化を行えました。

### 変更点

従来の当社SAのアクセス層はアクセスコストを重視したHotを採用してきました。Hot層は頻繁なアクセスに最適化されており、大規模環境を有する当社においては優れた選択と言えます。

しかしながら[AzureDiagnostics（診断ログ）](https://learn.microsoft.com/ja-jp/azure/azure-monitor/reference/tables/azurediagnostics)などの格納が多く、参照が少ないケースではCool層がコスト観点で優れています。

最適な層の選択は[ドキュメント](https://learn.microsoft.com/ja-jp/azure/storage/blobs/access-tiers-best-practices)にもまとめられており、複数の要素を持って層の選択を行うべきだと示されています。

SAの層の変更は極めてシンプルです。
下記の図の通り"Blob access tier(default)（既定のアクセスレベル）"を選択することで、反映後の新規オブジェクトファイルだけでなく、既存のファイル群にもオンラインで層の変更が適用されます。

![default-access-tiers](/images/morihaya-20250327-azure-storage_costdown/2025-03-27-01-09-54.png)

以下は、設定変更後のアクセス層の変化のグラフをMetricsから取得したものです。
およそ900TBのファイル群がすべてHot層からCool層へ切り替わったことをご確認いただけると思います。

![metrics-tiers](/images/morihaya-20250327-azure-storage_costdown/2025-03-27-01-18-39.png)

### 成果

SAの既定のアクセスレベルをHot層からCool層へ変更したことで、下記の通りDailyのコストが6万円相当を削減することができました。

![costanalysis](/images/morihaya-20250327-azure-storage_costdown/2025-03-27-01-25-08.png)
＊注意、このグラフはコスト最適化されたSAのみを表示しており、当社のSA全体を表すものではありません

#### Terraformでの変更点

当社はTerraformを用いてIaCを行っていますので、実際にはコードによる設定変更を行いました。
参考として`git log -p --full-diff`の差分は以下のとおりです。

```hcl
--- a/systems/morihaya/general/common/variables.tf
+++ b/systems/morihaya/general/common/variables.tf
@@ -376,6 +376,7 @@ variable "api_management_sit_info" {
 variable "storage_account_info" {
   description = "Storage Account Information"
   default = {
+    access_tier                       = "Cool"
     account_tier                      = "Standard"
     account_replication_type          = "GZRS"
     allow_nested_items_to_be_public   = false

＊ systems/morihaya は架空のディレクトリです
```

この1行のコード変更によってSAの”既定のアクセスレベルをHot層からCool層へ”の指定が有効となり、コスト最適化につながりました。

ここまでがHowの話です。

## 本題、さまざまな気づきに至るチームの在り方

ここからが本題です。

私たちSREチームには日々改善が生まれる土壌があります。本記事の成果もその流れで生まれたものでした。

### きっかけは何気ないストレージ作成の単純作業

私がSAに向き合うきっかけは、本当にシンプルな開発チームからのSA作成の依頼でした。
S3ほどにはSAに親しみがない私はせっかくのチャンスだから「SA知らないので自分やります！」と表明して担当者にしてもらいました。（ポイント1: やりたいと言えばやれる環境）

Azureで新規のサービスに向き合う時、MS Learnは非常に優れたドキュメントです。
読み進めるうちに[Azure Blob Storage のコストを計画および管理する](https://learn.microsoft.com/ja-jp/azure/storage/common/storage-plan-manage-costs)にたどり着きます。私たちSREチームでは週次で「コスト確認会」を開催し、信頼できる同僚氏のコスト奉行のもとでコスト意識を常にアップデートしているため、コストの文字には敏感になっています。（ポイント2: チームで磨き続ける）

![plan-storage-cost](/images/morihaya-20250327-azure-storage_costdown/2025-03-27-01-42-36.png)

### 気づきを得たらとりあえずチームに投げ込める

ひらめきを放置すれば存在しないと同じです。私はドキュメントを流し読みして手応えを感じ、すぐに頼れる同僚たちに対してアイデアを問いました。

それに対するチームの反応が以下の通りです。ポジティブで背中を押してくれています...!!（ポイント3: 受け止めてくれる信頼）

![slak-response](/images/morihaya-20250327-azure-storage_costdown/2025-03-27-01-52-46.png)

このやりとりによって、私はすでに向き合ってるタスクに加える形でSAのコスト最適化に着手することができました。

## 分析と外部確認による裏取り

以後は具体的な分析と裏取りの話になります。細かいのでAzureのコスト最適化を担っていない方は読む必要はありません。

### 分析

コスト最適化効果を進める上で、SREの原理原則に従い可視化された数値に向き合います。

まずはコスト観点です。効果が少なければ他に優先すべきタスクはいくらでもありますが、Cost analysisによって少なくない金額がStorage accountsにかかっていることがわかりました。

＊再掲　規定の変更前の金額を参照
![costanalysis](/images/morihaya-20250327-azure-storage_costdown/2025-03-27-01-25-08.png)

次に調べるのはアクセス層の利用割合の現状です。SAにある4つの層の割合をMetricsから確認したところ、下記のようにほぼすべてがHot層であることが確認できました。(前述の4種の層以外のPremium, Standardは[page blobs](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blob-pageblob-overview)が該当しますが詳細は割愛)

![hotonly](/images/morihaya-20250327-azure-storage_costdown/2025-03-27-02-04-39.png)

これを受けて「よしCool層だ！」とするには根拠が弱く、Cool層の特性である「アクセスおよび変更の頻度が低いデータの保存に最適なオンライン層」に沿っているかを確認したのが以下です。大量のAppendBlockなどがMega単位であるに対し、アクセスであるGet系がKilo単位であることがわかり、Cool層に適していると判断できました。

![transactions](/images/morihaya-20250327-azure-storage_costdown/2025-03-27-02-07-39.png)

### 外部確認による裏取り

これらの自己分析はドキュメントや経験に基づいていますが個人の判断によるものです。
チームの助言もありMicrosoftのAzureサポートへ自身の仮説の確認を依頼しました。

SR起票後、2営業日も経たない内に回答をいただけて、仮説の正しい点の裏付けと不足している観点を補うことができました。
改めて担当いただいた菅澤さんに感謝と敬意を送ります。素晴らしいサポートサービスを提供いただけました...!!

とくに”既定のアクセスレベル”を変更することで新規追加のファイルだけでなく既存のファイル群も一気にアクセス層を変更できる点は自分にとって直感的でなかったため、既存分はCLIやライフサイクルポリシーでの移行が必要と考えていましたが、誤解を解いていただけて工数を大きく減らすことができました。大変助かりました。

## おわりに

以上が「Azure Storage accountsのオプション変更で年間2,000万円以上のコスト削減を達成しました」の記事でした。気づきから実行に至るまでの流れに、自身のチームのありがたみを感じた一件でした。

以下、前回のコスト削減記事と同じ文言で結びます。

> クラウド費用のコストダウンはわかりやすい効果・成果となる一方、予約（Reservation）の購入など「購入レートの最適化」で留まるケースが多いと聞きます。（これをQuick Winと呼ぶ）

> 私たちASTのSREチームは、週次で開催する”コストモニタリング会”などを通してコスト意識を高める取り組みがありQuick Winの先の「リソースの最適化」の可能性を日常的に探し続けています。そんな考え方のキッカケとなった素晴らしい資料を紹介して本記事の結びとします。

@[speakerdeck](1ae7ed5e951b40dcaa2428b6070024f8)

それではみなさまEnjoy Azure! No Quick Win!!
＊No Quick Winは「短期的な成果だけでなく、長期的なリソース最適化を目指す姿勢」を指しています

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味をもった方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recuruiting.aeon.info/)
