---
title: "PagerDutyのService Event OrchestrationでIncident名を日本語でわかりやすくする方法"
emoji: "📝"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: # タグを指定する
  - "pagerduty"
  - "newrelic"
  - "aeon"
published: false
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。

こちらは[PagerDuty Advent Calendar 2024](https://qiita.com/advent-calendar/2024/pagerduty)の4日目の記事です。

本記事では[Service Event Orchestration](https://support.pagerduty.com/main/lang-ja/docs/event-orchestration#service-orchestrations)を利用してNew Relicアラートとして受け取った英語のIncidentのタイトルをわかりやすい日本語に変換する方法を紹介します。
なお実装したのは同僚の黒木 雄敏（Yuto Kuroki）さんで、私はPagerDutyの相談などで関わりがある中で黒木さんの良い工夫を知り本人承諾の上で紹介記事を書いています。

## TL;DR

本記事を箇条書きでまとめると以下です。

- New RelicのアラートをPagerDutyへ連携している
- PagerDuty上でIncidentを確認する際に、わかりやすい日本語名にしたかった
- Service Event Orchestrationを利用して `Summary` を書き換えることで実現した

## 背景

当社ではNew Relicを用いてシステムをモニタリングし、そのアラートをPagerDutyに連携して各担当者に通知する仕組みを展開中です。

New RelicとPagerDutyの連携は極めて簡単で、2種類あるIntegration方式のどちらを選ぶか決定さえすれば数クリックで実装することが可能です。
連携方式は`Account level integration using REST API Keys (recommended)`と`Service integration using Events API keys`があり、当社では運用をサービス単位で行える管理のやりやすさから後者の`Service integration using Events API keys`を選択しています。

### PagerDuty上のIncidentのタイトルを日本語にしたい要望が出た

両SaaSの連携自体は簡単にできましたが、実際にPagerDutyを用いた運用に向けて検証をする中で開発チームとして要望が出ました。
それが「PagerDuty上のIncidentのタイトルを日本語にしつつ、エラー内容をより具体的にしたい」です。

### New Relic側の"Title template"で日本語化できていたが不足があった

実のところ、Incidentのタイトルを日本語化するだけであればNew Relic側で完結できます。
PagerDutyに対してアラートを通知するNew Relic側では[Title template](https://docs.newrelic.com/docs/alerts/create-alert/condition-details/title-template/)の機能を利用してIncidentのタイトルを日本語化できていました。

具体的には以下の図のように`PRD環境/{{priority}}/HTTPステータスエラー率アラート/{{entity.name}}`と入力しておくことで日本語化が可能となります。

![](/images/morihaya-20241204-pagerduty-event-orchestration/2024-12-04-01-00-00.png)

しかしながら開発チームとしての要望は「Warningならエラー率10%、Criticalならエラー率20%」のように具体的な割合も数字としてIncidentタイトルに含めたいといったものでした。

担当していた黒木さんはNew RelicのTitle templateで実現できないか検討しましたが、後述する方法を使えばPagerDuty側で簡単にコントロールできると判断しました。

## 実装：PagerDutyのEvent OrchestrationでIncident Titleを書き換える

PagerDutyの[Event Orchestration](https://support.pagerduty.com/main/lang-ja/docs/event-orchestration)はIncidentをTriggerした際に処理を実行できる非常に強力な機能です。公式ドキュメントより概要を以下に引用します。

> Event Orchestrationを使用すると、ユーザーはイベントをPagerDutyに送り、イベントの内容に基づいて実行するアクションを定義する柔軟なルールを作成できます。Event OrchestrationはPagerDutyの最新ソリューションで、インシデント対応の自動化を実現します。

今回はこのEvent Orchestrationの機能を利用してIncidentのタイトルを「Warningならエラー率10%、Criticalならエラー率20%」といったものに変更します。

なおEvent Orchestrationには以下の3種類がありますが、今回のケースは単体のServiceでの要望であるため一番シンプルで範囲も狭い`Service Orchestrations`を使用しています。

- Global Orchestrations(PagerDuty AIOpsアドオンが必要)
- Global Integrations(全パッケージで利用可能)
- Service Orchestrations(全パッケージで利用可能、本記事のケースではこちらを利用)

### Service Event Orchestrationの設定画面の開き方

[ドキュメント](https://support.pagerduty.com/main/lang-ja/docs/event-orchestration#manage-a-service-orchestration-rule-in-event-orchestration)によればService Event Orchestrationの設定は`AIOps`と`Service`の2つのセクションから作成が可能とありますが、今回のケースは「あくまでService専用のEvent Orchestrationである」との観点から後者の`Service`セクションで設定をしています。

具体的には以下の手順で`Service Event Orchestration`の設定画面を開きます。

1. 画面上部のメニューから"Services"->"Service Directory"で対象のServiceの画面を表示する
2. Service画面のタブから"Settings"を選択
3. "Event Management"セクションの"Service Event Orchestration"の"View Event Orchestration Rules"ボタンを選択

![](/images/morihaya-20241204-pagerduty-event-orchestration/2024-12-04-01-32-36.png)

### Service Event Orchestrationの設定

`Service Event Orchestration`の設定は、過去にフローチャートを学んだことがあれば直感的に操作ができる優れたUIとなっています。

参考として全体の図を載せますが、今回紹介するのは赤枠の部分です。

![](/images/morihaya-20241204-pagerduty-event-orchestration/2024-12-04-01-39-03.png)

赤枠部分の`BFF側にてHTTPステータスエラー率が10%を超えました。`のルールを開くと以下のような設定になっています。

![](/images/morihaya-20241204-pagerduty-event-orchestration/2024-12-04-01-41-21.png)

図で表示されている条件の簡単な解説は以下の通りです。

- 2つのIFがAndで記述されており、2つとも条件にマッチされた場合のみに実行されるRuleとなっている
- 1つめのIFではNew Relicから渡される`event.custom_details['Alert Condition Names']`に対し`matches part (contains)`で文字列`hoge-prd-error-rates`に一致するかを判定する
- 2つめのIFでも同様に`event.custom_details['Impacted Entities']`に対し`matches part (contains)`で文字列`bff-prod`に一致するかを判定する

つまり、特定のアラートから生成された特定のIncidentに対して有効になるRuleが表現されています。
次に右下の`Next`ボタンを押すと実際の処理（Action）を設定する画面となります。

![](/images/morihaya-20241204-pagerduty-event-orchestration/2024-12-04-01-52-01.png)

この画面のUIも優れている感じる点として、変更を行なった`Event Field`のみがチェックマークが付与されているところがわかりやすくてGoodです。

図で表示されているActionの簡単な解説は以下の通りです。

- `Event Fields`の変更処理を行っている
- `summary`フィールドに対してtemplateを使って内容をリプレース（置き換え）する
- 置き換える内容は`PRD環境/warning/BFF側にてHTTPステータスエラー率が10%を超えました。`である

つまり、New Relicからは`PRD環境/{{priority}}/HTTPステータスエラー率アラート/{{entity.name}}`のtemplateにより`PRD環境/warning/HTTPステータスエラー率アラート/bff-prod`として通知されてくるIncidentに対して、Service Event Orchestrationが`PRD環境/warning/BFF側にてHTTPステータスエラー率が10%を超えました。`に書き換えを行うのです。

そして仮に`{{priority}}`が`warning`ではなく`critical`だった場合は、別のRuleによって`PRD環境/critical/BFF側にてHTTPステータスエラー率が10%を超えました。`に書き換えられます。

これらのService Event Orchestrationによって、Incidentを受ける開発チームの要望であるIncidentのタイトルを「Warningならエラー率10%、Criticalならエラー率20%」にすることを実現しました。

## 運用の課題は多少残るがわかりやすさをとる

ここまで紹介してきた実装は開発チームの要望を叶えた点で素晴らしいものです。

しかし、運用の観点からすると多少の煩雑さがあります。
具体的にはエラー率の10%や20%といった閾値はNew Relic側で設定するものであるため、仮に閾値を30%や40%へ変更した場合はPagerDuty側のメッセージの変更も別途必要になります。
今回設定を行なった黒木さんや私のように実装を理解できていれば問題ありませんが、New Relic側の閾値だけ変更する可能性が将来に残ります。
対策としてTerraformなどでIaC管理し、コメントやコード上での連携などを行えると良いのですが現在はできていない状況です。

それでも異常事態を知らせるIncidentのタイトルがわかりやすいことは優先すべきことですし、Event Orchestratrionの良い事例としても良い取り組みだと考えています。

## おわりに

以上が「PagerDutyのService Event OrchestrationでIncident名を日本語でわかりやすくする方法」の紹介でした。
New RelicもPagerDutyも成熟した素晴らしいSaaSです。当社ではそれらを活用し学びながら良いサービス提供につなげるべく改善の取り組みを行っています。
本記事で取り上げた`Event Orchestration`も、Incidentタイトルを書き換える以外にも大変多くの機能を有しており、また別の機会に紹介できればと考えています。

最後に、見事に実装をやり遂げた黒木さんに改めて感謝をお伝えいたします！

それではみなさまNew Relic & PagerDuty！

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味をもった方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recuruiting.aeon.info/)
