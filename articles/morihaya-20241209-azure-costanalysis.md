---
title: "よく使うAzureのCost analysisはDaily costsとフィルタとグループ化の組み合わせ"
emoji: "💰"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: # タグを指定する
  - "azure"
  - "コスト最適化"
  - "コスト削減"
  - "aeon"
published: false
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。

こちらは[Microsoft Azure Advent Calendar 2024](https://qiita.com/advent-calendar/2024/azure)の9日目の記事です。

本記事では私がよく使う[Microsoft Cost Management](https://azure.microsoft.com/ja-jp/products/cost-management/)の機能のひとつ[Cost analysis(日本語では”コスト分析”)](https://learn.microsoft.com/ja-jp/azure/cost-management-billing/costs/cost-analysis-common-uses)の利用方法をいくつか紹介します。

## TL;DR

本記事を箇条書きでまとめると以下です。

- AzureのコストモニタリングをCost analysis（コスト分析）で行っている
- よく使うのはDaily costs（１日あたりのコスト）ビュー
- フィルタとグループ化をうまく組み合わせよう

## 背景

私たちASTのSREチームは日々クラウドコストの最適化に向けて奮闘しています。チームとしては週次で「コストモニタリング会」と銘打った時間でプロダクトごとのコストを確認したり、その週に発生したCost alertの棚卸をモブ会形式でドライバーを交代しながら行っています。

個人としては同僚の岩崎さんを筆頭に予約購入などさまざまな取り組みを行っています。
なお岩崎さんは第47回 Tokyo Jazug NightでAzureコストをテーマに「Azureコストは水道代」のタイトルで登壇しているので紹介しておきます。
https://jazug.connpass.com/event/307679/

@[speakerdeck](8988de9d12e74127949f7f3bc2f14514)

### 日々の業務でもちょいちょいCost analysisを使う

私個人としても”負荷試験用の環境構築・運用”や、推進中の”Azure Database for MySQLのIOPSモード変更”などの案件の中でCost analysisを利用する場面があり、自分の中に「Cost analysisを利用する際の'型'」とでも呼ぶ利用方法が身についてきました。

＊このブログを書きながらドキュメントにも目を通したところ、大体のことは以下に記載されていましたので、ぜひ公式にも目を通してください。
https://learn.microsoft.com/ja-jp/azure/cost-management-billing/costs/customize-cost-analysis-views

## 基本はCustomizable viewsのDaily costs

Azureのコストをみていく上で切り口は数多くあります。
デフォルトでは以下の8つのViewが用意されています。（記事執筆時点の2024年12月時点）

- Smart Views
  - Azure OpenAI
  - Reservations（予約）
  - Resource groups
  - Subscriptions
- Customizable Views
  - Accumulated costs（累積コスト）
  - Cost by service（サービスごとのコスト）
  - Daily costs（１日あたりのコスト）
  - Invoice details（請求書の詳細）

![](/images/morihaya-20241209-azure-costanalysis/2024-12-09-22-40-35.png)

この中で私がよく使うのが「Daily costs」です。

### Daily costsで日単位で見ると変化に気づきやすい

Daily costsはその名の通り1日あたりのコストを棒グラフで表示します。
![](/images/morihaya-20241209-azure-costanalysis/2024-12-09-22-49-50.png)

コストの変動要因はさまざまなものがありますが、日単位で眺めることでその変化に気づきやすくなります。上のグラフ例では12/7に紫色の大きな変動が目につきます。

### 凡例をクリックして特定要素を除外するとさらに細かい変化に気づける

初見でわかる大きな変化以外にも目を向けたいケースでは、グラフ下側の凡例部分の除外したい色をクリックするとグラフ上で非表示にできます。

![](/images/morihaya-20241209-azure-costanalysis/2024-12-09-23-06-39.png)
 　　↓↓↓↓↓（Azure Database for MySQLを非表示に）↓↓↓↓↓
![](/images/morihaya-20241209-azure-costanalysis/2024-12-09-23-07-30.png)

この方法で”12/7に紫色の大きな変動”を非表示にすると、12/1の水色の増加や、12/7からエメラルドグリーンの消失などに気づきやすくなります。

![](/images/morihaya-20241209-azure-costanalysis/2024-12-09-23-09-29.png)

### フィルタで必要な情報のみに絞り込む

フィルタを利用することで、グラフに表示させたい情報を絞れます。
似たようなことができるものにスコープがありますが、私はスコープは広い範囲にしておき、フィルタで情報を絞っていくやり方が好みです。

私がよく使うフィルタ条件としては以下の通りです。

- Subscription: 当社ではサブスクリプションはプロダクトと環境ごとに用意されている
  - 利用ケース「先日準備した負荷試験環境のコスト、予算超えてないよね...?」
- Service name: 特定のAzure Serviceの変動に着目する
  - 利用ケース「MySQLのSingle DBからの移行いつ終わったっけ？」
- Resource: 特定の1リソースにフォーカスする
  - 利用ケース「先日スケールダウンしたDB03のコスト変動をみたい」
- Meter: サービス内の細かな課金条件にフォーカスする
  - 利用ケース「MySQLのIOPSにかかる料金だけ確認したい」
- Tag: 作成時に付与しておくことで柔軟に利用可能
  - 利用ケース「1つのサブスクリプションにごちゃ混ぜに作られた特定のリソース群のコストを知りたい」

![](/images/morihaya-20241209-azure-costanalysis/2024-12-09-23-43-38.png)

### グループ化でグラフを細分化する

フィルタで必要な条件を絞った後は、表示されているグラフをGroup byの変更で細分化します。

グループ化が適切でなかった場合グラフは単色で表示されます。これは単純に日毎のコストを見る上でシンプルです。
![](/images/morihaya-20241209-azure-costanalysis/2024-12-09-23-50-43.png)

同じグラフでService nameでグループ化したものが以下です。サービスごとの割合が色で表現されます。各サービスの変動を視覚的に把握するのに役立ちます。
![](/images/morihaya-20241209-azure-costanalysis/2024-12-09-23-53-29.png)

私がよく使うグループ化の条件は上述したフィルタ条件と同じです。
「フィルタで”Subscription”を絞った状態で”Service name”でグループ化」のように組み合わせて利用します。

## フィルタとグループ化を要件に合わせて組み上げる

結局のところ、コストを確認したい観点に合わせる形でフィルタとグループ化の組み合わすことが重要です。


### 実際にMySQLのIOPSコストについてのビュー作成の流れ

参考として、直近で私が進めている「MySQLのIOPSモード変更によるコスト削減」の効果を図るフィルタとグループ化のセットを組み上げたケースでは以下の流れでした。

#### 1. 初手はサービスとサブスクリプション

最初はシンプルに設定変更を行うサブスクリプションと、サービスのみを絞りました。

- フィルタ
  - Service name: Azure Database for MySQL
  - Subscription: 作業対象のサブスクリプション
- グループ化: なし

#### 2. サブスクリプションでは範囲が広いためリソース指定へ

当社は多くのMySQLインスタンスが稼働しています。リスク観点からIOPSのモード変更は段階的に行っており、コストの変動を確認するのはサブスクリプションでは広すぎると判断し、Resource条件で作業をこなった特定のMySQLのみに絞ることとしました。

- フィルタ
  - Service name: Azure Database for MySQL
  - Subscription: 作業対象のサブスクリプション
  - Resource: 作業対象のMySQLのインスタンス
- グループ化: なし

#### 3. MySQLのIOPSのコストだけを表示したいためMeterによるグループ化

フィルタ条件は十分と判断し、グループ化をMeter指定で細分化。

- フィルタ
  - Service name: Azure Database for MySQL
  - Subscription: 作業対象のサブスクリプション
  - Resource: 作業対象のMySQLのインスタンス
- グループ化: Meter

![](/images/morihaya-20241209-azure-costanalysis/2024-12-10-00-34-19.png)

#### 4. フィルタ条件にMeterのIOPSを追加

かなりみやすくなりましたが、Azure Database for MySQLのMeterにはIOPS関連の他にvCoreやStorage Data Storedなどがあるため、フィルタにMeterのIOPS関連の条件を追加します。

- フィルタ
  - Service name: Azure Database for MySQL
  - Subscription: 作業対象のサブスクリプション
  - Resource: 作業対象のMySQLのインスタンス
  - Meter: Additional IOPS, Paid IO LRLS...
- グループ化: Meter

![](/images/morihaya-20241209-azure-costanalysis/2024-12-10-00-37-29.png)


このグラフから、12/4にPre-provisioned IOPSからAuto scale IOPSへ変更した結果、IOPS関連のコストが約50-60%程度に削減できたことが確認できます。

#### 4のフィルタは以下のようにもできるが残しておくと便利かも

4のフィルタ条件は以下のようにSubscriptionやService nameを外し、Resourceのみ指定でも同じ結果となります。

- フィルタ
  - Resource: 作業対象のMySQLのインスタンス
  - Meter: Additional IOPS, Paid IO LRLS...
- グループ化: Meter

しかし、個人的に無理に最小のフィルタ条件を目指す必要はないと考えています。
あえて条件を残してビュー保存しておき、再利用時の条件変更のやりやすさや、思考の過程をわかるようにしておくことの方がメリットがあるためです。

## おわりに

以上が「よく使うAzureのCost analysisはDaily costsとフィルタとグループ化の組み合わせ」の紹介でした。
今回紹介したのは8つのデフォルトビューの1つ"Daily costs（１日あたりのコスト）"でしかありません。他の7つも使いこなしながら、引き続きコスト最適化を通して貢献していきたいと考えています。

それではみなさまEnjoy Azure！

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味をもった方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recuruiting.aeon.info/)
