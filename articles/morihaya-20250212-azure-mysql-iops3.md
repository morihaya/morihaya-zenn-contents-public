---
title: "Azure Database for MySQLのIOPS設定の変更で月額約100万円のコストダウンが実現しました"
emoji: "💰"
type: "tech"
topics:
  - "azure"
  - "mysql"
  - "database"
  - "コスト最適化"
  - "aeon"
published: true # false or true , スケジュール公開の場合はfalseで予約して後からtrueにFix必要
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。

本記事はAzureのマネージドなMySQLである”Azure Database for MySQL Flexible Server”（以後はDB）のIOPS設定機能やコストについてまとめたシリーズの第3弾となり、コストダウンを達成した成果報告の記事となります。

## TL;DR

- DBの"Storage"の"IOPS"の設定を、"Pre-provisioned IOPS"から"Auto scale IOPS"へ変更した
- 結果としてDailyで約4万円弱のコストダウンとなり、月額およそ100万円、年額で1200万円の削減が見込めた
- リスクとして心配していた、急激なIOPS需要へのスケール遅延も（現状は）発生していない

## 本シリーズの過去記事振り返り

結果の詳細について述べる前に、過去2記事を紹介します。

1. [Azure Database for MySQL Flexible ServerのAuto scale IOPSが固定IOPSよりお得か？](https://zenn.dev/aeonpeople/articles/2c2f706c0ae173)
1. [Azure Database for MySQLのIOPS設定の変更で月額n百万円のコストダウンが見込めました](https://zenn.dev/aeonpeople/articles/a1cee204ce9529)

簡単な要約をすると、1の記事では「SingleDBからFlexibleDBに移行するにあたり、新しく選択可能となった"Auto scale IOPS"の有用性」を調べ、2の記事では「実際にDBのIOPSモードを"Pre-provisioned IOPS"から"Auto scale IOPS"へ変更した場合の見積もり方法」について紹介しています。

あれから4か月ほどが過ぎ、プロダクトチームの理解や検証の結果を経て、良い結果を得られました。

## 成果報告

### 変更点

変更したのはAzure Database for MySQL Flexible ServerのStorageのIOPSの設定です。

過去記事でも紹介しましたが、Single ServerのEOLに伴いFlexible Serverへ移行を進めた際に、当初は従来の固定IOPS（Pre-provisioned IOPS）を利用していました。

これを動的IOPS（Auto scale IOPS）に変更しています。

![](/images/morihaya-20250212-azure-mysql-iops3/2025-02-12-01-34-09.png)


#### Terraformでの変更点

当社はTerraformを用いてIaCを行っていますので、実際にはコードによる設定変更を行いました。
参考として`git log -p --full-diff`の差分は以下のとおりです。

```hcl
--- a/systems/hoge/production/piyo/variables.tf
+++ b/systems/hoge/production/piyo/variables.tf
@@ -1880,44 +1880,44 @@ variable "mysql_flexible_server_master_map_info" {
     hoge045 = {
       sku_name           = "GP_Standard_D32ds_v4"
       storage_size_gb    = 1500
-      iops               = 20000
-      io_scaling_enabled = false # コスト削減のため将来的にはtrueに変更する
+      #iops               = 20000
+      io_scaling_enabled = true
     }
```

当社のTerraformコードは基本的にmodule化を行っているためvariableで渡す形になっていますが以下のようなmoduleに値が渡っています。

```hcl
resource "azurerm_mysql_flexible_server" "writer" {
（略）
  sku_name = each.value.sku_name
  storage {
    auto_grow_enabled  = each.value.storage_auto_grow_enabled
    size_gb            = each.value.storage_size_gb
    iops               = each.value.iops
    io_scaling_enabled = each.value.io_scaling_enabled
  }
（略）
```

このコード変更によって`iops`の指定（Pre-provisioned IOPS）が無効となり、`io_scaling_enabled`が有効（Auto scale IOPS）となります。

#### 変更時のセッションダウンなどの影響はなし

この設定変更は、検証や本番環境にかかわらず日中の時間帯にオンラインで変更を実施しました。
事前のドキュメントの仕様確認や検証において、サービス影響は出ない自信はありましたが実際に本番環境へ行う際は緊張感がありました。

結果としてセッションが切れる、急激にパフォーマンスが落ちる、といったことは発生せずにオンラインで問題なく変更を行えました。

変更にかかる時間は1〜3分程度でした。（HCP Terraformによる複数台へのapplyを行った場合）

### Azure Cost Analysisでの測定

コストの変動はAzureの”Cost Analysis”で確認しました。
"Cost Analysis"については私たちSREチームで愛用しており他記事でも紹介しています。

- [Azure異常コストアラート：犯人はResource groupの中にいる！](https://zenn.dev/aeonpeople/articles/fafb830ab8b341)
- [よく使うAzureのCost analysisはDaily costsとフィルタとグループ化の組み合わせ](https://zenn.dev/aeonpeople/articles/morihaya-20241209-azure-costanalysis)

結果として以下のようなグラフを確認できました。
水色がPre-provisioned IOPSの金額、青色がAuto scale IOPSの金額です。

IOPSの変更は影響範囲の少ないものから2回に分けて行ってるため、変更点をわかりやすくマークしています。

![IOPSモード変更によるコスト変動](/images/morihaya-20250212-azure-mysql-iops3/2025-02-12-01-28-55.png)

結果として`約9万円/日`から`約5.5万円/日`程度にコストダウンできていることがわかるでしょうか。

これは別の言い方をすれば以下のコストダウンを意味し、少なくない成果と言えます。

- 日額`約3.5万円`の削減
- 月額`約105万円`の削減
- 年額`約1,270万円`の削減

＊上記はCost AnalysisのFilter機能で特定範囲のDBのみを表示しており、当社の全体の金額を示すものではありません。

### 急激なIOスパイクへの懸念は？

[過去記事](https://zenn.dev/aeonpeople/articles/a1cee204ce9529#%E6%B3%A8%E6%84%8F%EF%BC%9A-auto-scale-iops%E3%81%AF%E6%80%A5%E6%BF%80%E3%81%AA%E3%82%B9%E3%83%91%E3%82%A4%E3%82%AF%E3%81%AB%E9%96%93%E3%81%AB%E5%90%88%E3%82%8F%E3%81%AA%E3%81%84%E3%83%AA%E3%82%B9%E3%82%AF)にて「Auto scale IOPSは急激なスパイクに間に合わないリスク」があることを記載していましたが、現状は安定しています。

具体的には以下はDailyの夜間ジョブで高負荷のIOが発生するDBの"Storage IO Persent"の"MAX"のグラフです。

変更前のPre-provisioned IOPSでは100%まで上がっていましたが、Auto scale IOPSへ変更後は60〜70%に抑えられています。

![](/images/morihaya-20250212-azure-mysql-iops3/2025-02-12-02-19-36.png)

注意点として、これは見方を変えれば”Pre-provisioned IOPSでの指定した値が低かった”と見ることも可能です。Auto scale IOPSを万能とするのではなく、メトリクス・コスト・ジョブの実行時間・IOPS指定値など多角的な観点でチューニングを行っていく必要があります。

### 固定IOPSに戻したケースも

一度Auto scale IOPSにしたが、Pre-provisioned IOPSに戻したケースもご紹介します。
理由は”むしろコストが上がってしまった”ためです。

[過去記事]((https://zenn.dev/aeonpeople/articles/a1cee204ce9529))の通り、設定変更後のコスト効果予測ついては直近30日間のIO Countを用いて試算しています。
以下は、プロダクト側でDBの稼働状況が変化したことで、予想よりも大量のIOが発生した結果むしろコストが高くなってしまい、Pre-provisioned IOPSへ戻す判断をしたDBのコストグラフです。

![高くなったので戻した](/images/morihaya-20250212-azure-mysql-iops3/2025-02-12-09-57-36.png)

このような結果もあり、繰り返しになりますが「Auto scale IOPSを万能とするのではなく、メトリクス・コスト・ジョブの実行時間・IOPS指定値など多角的な観点でチューニングを行っていく必要」があります。

「推測するな、計測せよ」の意識が重要と言えるでしょう。

## おわりに

以上が「Azure Database for MySQLのIOPS設定の変更で月額約100万円のコストダウンが実現しました」の記事でした。総じて”うまくいって良かった”の一言です。

クラウド費用のコストダウンはわかりやすい効果・成果となる一方、予約（Reservation）の購入など「購入レートの最適化」で留まるケースが多いと聞きます。（これをQuick Winと呼ぶ）

私たちASTのSREチームは、週次で開催する”コストモニタリング会”などを通してコスト意識を高める取り組みがありQuick Winの先の「リソースの最適化」の可能性を日常的に探し続けています。そんな考え方のキッカケとなった素晴らしい資料を紹介して本記事の結びとします。

それではみなさまEnjoy Azure！

@[speakerdeck](1ae7ed5e951b40dcaa2428b6070024f8)


## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味をもった方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recuruiting.aeon.info/)
