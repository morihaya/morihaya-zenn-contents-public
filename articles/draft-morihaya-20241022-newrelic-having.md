---
title: "SQLならGROUP BYしてHAVINGだけど、New RelicのNRQLならFACETしてgetField()するって話"
emoji: "✋"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: # タグを指定する
  - "NewRelic"
  - "aeon"
  - "NRQL"
published: false
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。

本記事では、日々AzureとNew Relicを駆使してシステムの改善に努めている中で、NRQLを使ったちょっとしたデータ集計の時に役立つTipsを紹介します。

## TL;DR

本記事を箇条書きでまとめると以下です。

- NRQLを使うとAzureのメトリクスをNew Relicで簡単に可視化できます
- NRQLでは[`FACET`](https://docs.newrelic.com/jp/docs/nrql/nrql-syntax-clauses-functions/#sel-facet)を使うことでSQLにおける`GROUP BY`のように集約できます
- `FACET`による集約結果に”n以上"などの条件を加えて結果をフィルタリングする場合、NRQLでは [`getField()`](https://docs.newrelic.com/jp/docs/nrql/nrql-syntax-clauses-functions/#func-getfield)を使用します


完成したNRQLが以下の通りです。

```SQL
-- NRQL完成版
SELECT max(`azure.dbformysql.flexibleservers.io_consumption_percent`)
FROM Metric 
WHERE entity.name LIKE 'pmh%'
AND getField(`azure.dbformysql.flexibleservers.io_consumption_percent`, max) < 50
SINCE 30 Days ago
FACET entity.name
LIMIT MAX
```


:::message alert
SQLとNRQLは近い構文ですが、SQLのGROUP BY、HAVINGが完全に同じと考えるのは危険です。期待した結果を得られているかは全件結果を別の手段で抽出するなどの確認を推奨します。
:::


## NRQLをなぜ使うのか

Tipsの紹介するにあたり、どうして私たちがNRQLを活用するかを個人の目線から紹介します。
システムの状態が健全であるかを確認するために、私たちにはいくつかの手段があります。

### 稼働するプラットフォームの機能を利用する

ひとつにはシステムが稼働するプラットフォームの機能を活用することです。ASTではシステムのほぼすべてをパブリッククラウドのAzureを用いて提供しています。

Azureには[Azure Monitor](https://learn.microsoft.com/ja-jp/azure/azure-monitor/overview)と呼ばれる優れたモニタリングのためのサービスがあります。Azure Monitorのもっとも優れた点のひとつに、Azure上で各種PaaSやサービスを利用した場合にその習熟度に関係なく必要なメトリクスが取得されていることが挙げられます。

Azure上でどんなサービスを利用しても”Native platform metrics”として追加コスト不要で時系列のメトリクスが収集され、個別のメトリクスをグラフとして参照したり、個別のダッシュボードとして作成することが可能です。

### New RelicのNRQLの強み

Azureがモニタリング/可観測性の機能をAzure Monitorとして提供している一方で、ユーザである私たちがNew Relicのようなサービスを活用するモチベーションについては以下の資料が詳しいです。

@[speakerdeck](6c8c5a957593407b97968867fe2d6bd1)

具体的には[P11](https://speakerdeck.com/aeonpeople/ionnotesitarusihutozhan-lue-wozhi-eru-newrelichuratutohuomunodao-ru-toxiao-guo-1bef3f5a-3d81-4b8d-b587-f92c7800f364?slide=11)にある通り、言語もAPMも異なる環境が多く存在する中で可観測性（とくにAPM）に強みのあるNew Relicを用いて統一を行うことで、共通したインターフェイスによる手段の効率化および、それらを経て各チームの文化の変容を促し、最終的にはより良いプロダクトづくりのきっかけのひとつとなっています。

NRQLはNew Relicが提供するクエリ言語で、New Relicが扱うほぼすべてのデータにアクセスが可能です。今回の記事で特筆すべきは従来のSQLに似た構文を採用している点でしょう。

あくまで個人の所感によるものですが、Azureでも同様にデータにアクセスし集計が可能な[Azure Resource Graph](https://learn.microsoft.com/ja-jp/azure/governance/resource-graph/overview)があります。何度か利用しそのパワフルな機能に利便性を感じつつも、[KQL](https://learn.microsoft.com/ja-jp/kusto/query/)に対して一定の戸惑いを感じることがしばしばありました。KQLに比べるとNRQLのSQLで見慣れた構文に親しみを感じることが多いのが現状です。

## NRQLでもGROUP BYしてHAVINGがしたい

本題です。とあるタスクに取り組む中で以下の条件にマッチするMySQLのインスタンス一覧を抽出したいと考えました。

「一定期間（30日）のAzure Database for MySQLのIO使用率（Storage IO percent）の最高が50%未満のpmhで始まるMySQLインスタンス」

### SQLで書くならこんな感じに

従来のSQLで表現するなら以下のようになるでしょう。

```SQL
SELECT instance_name, MAX(io_consumption_percent)
FROM dbmetrics
WHERE instance_name LIKE 'pmh%'
AND timestamp >= DATEADD(day, -30, GETDATE())
GROUP BY instance_name
HAVING MAX(io_consumption_percent) < 50
```

`SELECT`句にDB名とIO消費率を、
`WHERE`句で名前と時間の範囲を指定し、
`GROUP BY`句でDB名で集約し、
`HAVING`句で集計結果に対して条件でフィルタします。

### NRQLで書くなら：STEP1 時系列データ

NRQLではどうでしょうか。

手始めに私は簡単に以下の構文までは組み上げることができました。
これは時系列グラフとして各DBのIO使用率の遷移を表示します。
日頃からシステムの状態を時系列データで確認することはSREの日常業務であることから、簡単に作ることができました。

```SQL
-- 未完成の、時系列にDBごとのIO使用率を表示するNRQL
SELECT max(`azure.dbformysql.flexibleservers.io_consumption_percent`)
FROM Metric 
WHERE entity.name LIKE 'pmh%'
SINCE 30 Days ago
FACET entity.name
LIMIT MAX
TIMESERIES
```

SQLの例と似た構文であることが伝わるでしょうか。`SELECT`, `FROM`, `WHERE`, `LIKE`の使い方はほぼSQLと同じです。

NRQLの特徴である以下についても簡単に解説しておきます。

- `SINCE`: 過去の範囲を指定します。時間指定はSQLよりNRQLの方が直感的です
- `FACET`: GROUP BYとほぼ同様な扱いとなります
- `LIMIT`: デフォルトだと制限された件数しか出ないため、全件を出すためにMAXを指定しています
- `TIMESERIES`: 時系列グラフを表示する際に使用します。データの粒度を指定することも可能です。

クエリの結果はグラフとして以下のようになり、繁忙期などを知るのに有効です。

![](/images/draft-morihaya-20241022-newrelic-having/2024-10-22-04-03-00.png)

### NRQLで書くなら：STEP2 一定期間のMAX全件取得

欲しいのは時系列データではなく一定期間のDBごとの最大値ですので、修正して以下のようになりました。

具体的には `TIMESERIES` 句を削っただけです。

```SQL
-- 未完成の、DBごとのIO使用率の最大値を表示するNRQL
SELECT max(`azure.dbformysql.flexibleservers.io_consumption_percent`)
FROM Metric 
WHERE entity.name LIKE 'pmh%'
SINCE 30 Days ago
FACET entity.name
LIMIT MAX
```

このクエリを実行し、Chart Typeを"Table"へ変更することで以下のような結果を取得できました。

![](/images/draft-morihaya-20241022-newrelic-having/2024-10-22-04-23-58.png)

ここまで来れば"Export as CSV"を実行することでCSVを入手でき `grep` なりExcelなどを使用して50%未満のDBを抽出できます。

![](/images/draft-morihaya-20241022-newrelic-having/2024-10-22-04-25-25.png)

### NRQLで書くなら：FINAL 一定期間のMAX全件取得を条件付きで

ほぼ目的を達成するNRQLを作成することはできましたが、CSVでダウンロードして抽出するのは手間ですし、可能ならNRQLで完結したいと考えました。

SQLであれば集約したデータに条件を加える場合HAVING句を利用すると考え、以下のようなクエリを実行しました。

```SQL
-- HAVINGでエラーになるNRQL
SELECT max(`azure.dbformysql.flexibleservers.io_consumption_percent`)
FROM Metric 
WHERE entity.name LIKE 'pmh%'
SINCE 30 Days ago
FACET entity.name
HAVING azure.dbformysql.flexibleservers.io_consumption_percent < 50
LIMIT MAX
```

しかしながら以下のエラーが発生します。

> There was a problem...
NRQL Syntax Error: Error at line 6 position 1, unexpected 'HAVING'

エラーの通り、NRQLではHAVINGが存在しません。

困った私は頼りになる”New Relicの中の方（いつもナイスサポートに感謝！）”にカジュアルにエラー内容と目的をお伝えしたところ、すぐに回答いただいたのが[getField()](https://docs.newrelic.com/jp/docs/nrql/nrql-syntax-clauses-functions/#func-getfield)関数です。

`getField()` 関数の説明をドキュメントより引用します。

> `getField()`関数を使用して、ディメンションメトリックデータなどの複合データ型からフィールドを抽出します。

つまり`getField()`を利用することで、`FACET entity.name` によってDBごとに、`MAX()`によって最大値が集計された複合データに対し、50未満といった条件で抽出できるのです。

こうして目的を完全に達成したNRQLが以下になります。

```SQL
-- NRQL完成版
SELECT max(`azure.dbformysql.flexibleservers.io_consumption_percent`)
FROM Metric 
WHERE entity.name LIKE 'pmh%'
AND getField(`azure.dbformysql.flexibleservers.io_consumption_percent`, max) < 50
SINCE 30 Days ago
FACET entity.name
LIMIT MAX
```

結果もしっかりと50以下のDBに絞られていることが確認できました。
![](/images/draft-morihaya-20241022-newrelic-having/2024-10-22-05-34-02.png)

## おわりに

以上、NRQLを使用する際に、SQLの`GROUP BY`句や`HAVING`句に相当するクエリを組み立てる方法をご紹介しました。

NRQLの`FACET`句と`getField()`関数を活用することで、みなさんのNRQLライフが少しでも快適になれば幸いです。

それではみなさまEnjoy Azure & New Relic！

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味もった方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recuruiting.aeon.info/)
