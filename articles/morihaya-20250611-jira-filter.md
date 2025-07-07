---
title: "先月なにやったっけ？JiraのJQLを用いて複数プロジェクトを跨いだ振り返りを実施しています"
emoji: "😤"
type: "idea" # tech or idea
topics:
  - jira
  - jql
  - aeon
published: true # false OR true , スケジュール公開の場合はfalseで予約して後からtrueにFix必要
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。
当社は[Atlassian社](https://www.atlassian.com/ja)のConfluenceとJiraを導入しており、ドキュメントと課題管理を行っています。

本記事ではSREのような横断的なチームが、タスクフォーマットがそれぞれ異なる複数プロジェクトを跨ぎながら先月の振り返りを行う上で、[Jira Filter](https://support.atlassian.com/ja/jira-work-management/docs/save-your-search-as-a-filter/)によるカスタムで振り返りを促進する方法を解説します。


(2025-07-07)
過去に自分がアサインされたチケットも表示するために`assignee was currentUser()`をクエリに追加しました。

## TL;DR

本記事を3行に要約すると以下です。

- Jira Projectの運用にはチームの個性が出せるが、それは横断的なチームにとって振り返りが大変になることも
- Jiraには高度な検索を可能とするJQLが存在しており、Projectを横断したクエリ検索が可能
- Jira FilterをConfluenceに貼り付けて埋め込みとしても活用できる


なお利用しているのは以下のJQLです。

```sql
(project = "Project_A" OR project = "Project_B" OR project = "Project_C") AND (status = Done OR resolution = Done) AND ((updated >= startOfMonth(-1) AND updated <= endOfMonth(-1)) OR (resolutiondate >= startOfMonth(-1) AND resolutiondate <= endOfMonth(-1))) AND (assignee = currentUser() OR assignee was currentUser())
```

## SREの振り返りあるあるとJiraの活用

SREチームのあるあるとして、複数のプロジェクト/チームを横断して活動することが多いのではないでしょうか。私たちASTのSREチームの場合、マイクロサービスのインフラ環境をチームの一人として構築することもあれば（Embedded）、Azure環境で困っているチームの相談に乗ることもあれば（Enabling）、日常的にAzureのコスト最適化のために厳しくリソースとコストモニタリングを行うなど、多岐に渡ります。

チームでは論理的な”SREチーム”と”PFE（Platform Engineering）チーム”に分かれ、Dailyの朝会で同期をしつつも、チームごとに月次のSprint Reviewをしています。

チームメンバーは振り返りの意義を感じながらも、コンテキストスイッチの多さから「先月ってなにやってたっけ？」となりがちでした。

![what-did-i-do-last-month](/images/morihaya-20250611-jira-filter/2025-06-11-01-48-28.png)

さらに、各チームによってJiraプロジェクトが存在しており、カスタムフィールドを駆使しながらタスク管理の形式もさまざまとなっています。

本来振り返りは"厳しい上長🐈"に対してメンバーが最大限アピールする時間です。
横断かつそれぞれ異なるタスク管理方法から、結果として適切な振り返りができずに終わってしまう...といった状況が散見されていました。

そこで本記事で紹介するJiraの検索機能とフィルターを組み合わせて、先月自分が関わって完了したすべてのタスクを一覧できるようにしました。

## JQL (Jira Query Language) とは

Jiraには[「JQL」](https://support.atlassian.com/ja/jira-work-management/docs/use-advanced-search-with-jira-query-language-jql/)というSQL風のクエリ言語があります。これを使うことで複数プロジェクトを横断した検索などの柔軟なフィルタが可能になります。

JQLの基本的な構造は以下の通りです：

```
[フィールド] [演算子] [値]
```

たとえば、「Project_A」というプロジェクトの「Done」状態のチケットを取得するには：

```sql
project = "Project_A" AND status = Done
```

複数のプロジェクトを横断するには `OR` を使います：

```sql
project = "Project_A" OR project = "Project_B"
```

## 先月クローズしたチケットを集める横断的なJQL

実際に私がチームにシェアし、月次の振り返り用に使っているJQLは冒頭のTL;DRで紹介したものです。


```sql
(project = "Project_A" OR project = "Project_B" OR project = "Project_C") AND (status = Done OR resolution = Done) AND ((updated >= startOfMonth(-1) AND updated <= endOfMonth(-1)) OR (resolutiondate >= startOfMonth(-1) AND resolutiondate <= endOfMonth(-1))) And assignee = currentUser()
```

改めて説明すると：

1. 特定のプロジェクトを対象とする

```sql
(project = "Project_A" OR project = "Project_B" OR project = "Project_C")
```

2. 完了したチケットに限定する

```sql
AND (status = Done OR resolution = Done)
```

3. 先月中に更新または解決されたものに限定する

```sql
AND ((updated >= startOfMonth(-1) AND updated <= endOfMonth(-1)) OR (resolutiondate >= startOfMonth(-1) AND resolutiondate <= endOfMonth(-1)))
```

4. 自分がアサインされているタスクに限定する

(2025-07-07更新)作業対応後、チケットを`完了確認`といった状態で依頼元に返却するために担当を変えてしまうケースに対応するため`assignee was currentUser()`も指定しています。

```sql
AND (assignee = currentUser() OR assignee was currentUser())
```

このJQLのポイントは、`startOfMonth(-1)` と `endOfMonth(-1)` という関数を使って、常に「先月」を指定できる点です。実行日付に合わせて自動的に対象期間が変わるので、毎月クエリを書き換える必要がありません。

単純に解決したタスクを抽出するだけなら`resolutiondate`だけで済むところを、追加で`updated`の最終更新も加えることで、先月クローズとしつつも更新が入ったタスクを行うことで、自分たちの成果を最大限洗い出せるようにしています。

## フィルターとして保存して活用

組み立てたJQLを毎回実行するのは体験としてよくありませんが、Atlassianは[JQLをフィルタとして保存](https://support.atlassian.com/ja/jira-work-management/docs/save-your-search-as-a-filter/)する機能があります。利用方法は以下の通り極めて簡単です。

1. Jiraの検索画面でJQLを入力して検索
2. 右上の「保存」ボタンをクリック
3. フィルター名（例:「先月完了したマイタスク」）を入力して保存

これで、「フィルター」メニューから簡単にアクセスできるようになります。

## Confluenceに埋め込んで見える化

さらに便利な使い方として、このフィルターをConfluenceページに埋め込むことができます：

1. Confluenceでページを編集
2. 保存したフィルタのURLを貼り付ける
3. 埋め込まれたタスク一覧が表示されます

この結果、毎月のスプリントレビューや振り返る際に、Confluenceページに自動更新される先月の自身が関わって完了したタスク一覧を表示できるようになります。

![embedded-filter](/images/morihaya-20250611-jira-filter/2025-06-11-01-54-01.png)

## 参考:カスタマイズして使おう

このJQLはさまざまにカスタマイズして使えます：

- `currentUser()` を特定のユーザー名に変更すれば、他メンバーのタスクも確認可能
- 期間を `startOfMonth(0)` に変更すれば今月のタスクを表示
- `project in (Project_A, Project_B)` のように複数プロジェクトをまとめて指定も可能

自在にJQLを操りながら、あなたのチームの振り返り方法にあわせてカスタマイズしてみてください。

## おわりに

以上が「先月なにやったっけ？JiraのJQLを用いて複数プロジェクトを跨いだ振り返りを実施しています」の記事でした。

私の1年を超えたASTでの経験から、Atlassian製品は成熟し、優れたサービスを提供しているのでしょう。

その価値を最大化し、お客様のためのサービス向上に活かせるかは、私たち利用者に任されていると改めて認識しています。

これからもさまざまなサービスやソフトウェアの力に支えてもらいながら、トータルアプリのiAEON、ひいてはAEONグループをご利用いただくお客様のために、日々改善し続けていく所存です。

それではみなさまEnjoy Atlassian Jira!!

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味をもった方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![イオングループエンジニア採用バナー](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recruiting.aeon.info/)
