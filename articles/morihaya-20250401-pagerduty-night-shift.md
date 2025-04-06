---
title: "PagerDutyでService Orchestrationsを用いて夜間インシデントを通知遅延させる技"
emoji: "🌙"
type: "tech"
topics:
  - "pagerduty"
  - "障害対応"
  - "インシデント"
  - "オンコール運用"
  - "aeon"
published: true # false or true , スケジュール公開の場合はfalseで予約して後からtrueにFix必要
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。

本記事はPagerDutyを各チームへ展開する中で「夜間帯のインシデント通知を遅らせたい」との要望をいただき、[Service Orchestrations](https://support.pagerduty.com/main/lang-ja/docs/event-orchestration#service-orchestrations)を利用することで実現した方法の紹介です。（なおこれは同僚のrakiさんにアシストをもらって私が実装してブログにしています）

注意点として、本記事で利用する機能はPagerDutyの[AiOps](https://www.pagerduty.co.jp/pricing/aiops/)のAddonが必要となります。

## TL;DR

- 社内の各チームへPagerDutyを展開している
- アラートのチューニングに不安のある中で「即回復系のアラートで起こされたくないため、夜間帯だけ通知を遅らせてほしい」との要望が出た
- Service OrchestrationsのEvent Ruleの`On a recurring weekly schedule`と`Pause notifications`で実装した
  - ＊注意：`On a recurring weekly schedule`はAIOps Add-Onが必要

## 背景

簡単に背景を説明します。

当社ではより優れたインシデント対応のためにPagerDutyを導入し活用範囲を社内へ広げています。
各チームのPagerDutyの受け入れに際し、基本的なサービスの概念や操作方法を座学やハンズオンといった形でSREチームから行います。

多くの場合に課題となるのはPagerDutyそれ自体の操作ではなく、通知すべきアラートのチューニングです。
PagerDutyの導入には前向きだとしても、夜間帯に不必要に起こされたくはないのは誰もが思うことです。

数分で自動回復するアラートをチューニングしきれたと確信できない状況では、多少のMTTAを犠牲にしても夜間のアラートにはバッファ時間を設けたいとの要望が出ました。

## Service Orchestrationsを活用

[Service Orchestrations](https://support.pagerduty.com/main/lang-ja/docs/event-orchestration#service-orchestrations)はサービスの単位で利用できるEvent Orchestrationです。

Event Orchestrationでは以下の[5つの条件](https://support.pagerduty.com/main/lang-ja/docs/event-orchestration#create-a-routing-rule)を利用してインシデントの事前処理を行えます。

1. `Always (for all events)`: つねにルールを実行する
2. `If Events Match Certain Conditions`: イベントが特定の条件と一致する場合
3. `On a recurring weekly schedule`: 週次の定期スケジュール(AdvancedEvent Orchestration で利用可能)
4. `During a scheduled date range`: 日時指定(AdvancedEvent Orchestration で利用可能)
5. `Depends on event frequency`: イベントの頻度(AdvancedEvent Orchestration で利用可能)

＊上述の通り3,4,5の項目はAIOps Addonが必要になります。

今回利用するのは3の`On a recurring weekly schedule`です。

### Condition: On a recurring weekly schedule

`On a recurring weekly schedule`は日本語に訳せば「毎週の定期的なスケジュール」です。

利用方法は設定画面を見た方が直感的です。（この辺りのUIのわかりやすさはさすがPagerDutyさんといったところです）

![On a recurring weekly schedule](/images/morihaya-20250401-pagerduty-night-shift/2025-04-01-23-47-21.png)


設定できる項目は以下の通りです。

- `Start`: Ruleの適用を開始する時間
- `End`: Ruleの適用を終了する時間
- `Days of the week`: Ruleを適用する曜日
- `Timezone`: 指定時間のタイムゾーン

今回の要件は「夜間帯のインシデント通知を遅らせたい」であるため定時外の18:00-09:00ですべての曜日を対象としています。

### Rule: Pause notifications

条件を指定した後は、Step 2にて通知を遅らせるための設定を行います。
そのために`Suspend alert for N seconds before triggering an incident`を指定します。

![Pause notifications. Suspend alert for 300 seconds before triggering an incident](/images/morihaya-20250401-pagerduty-night-shift/2025-04-02-00-05-10.png)

"Seconds"とあるように秒数で指定します。
指定可能な範囲は10秒から14,400秒（24時間）です。

場合によりますが、実際に指定するのは5分(300秒)から30分(1,800秒)くらいが妥当でしょう。

## 余談: 時間帯の指定がなければAuto-Pauseが簡単

今回は”夜間帯のみ”の指定があったためService Orchestrationsを利用しましたが、単純に通知までのバッファを設けるならAuto-Pauseがシンプルで便利です。
Auto-Pauseは特定の時間帯指定なしで一定秒数通知を遅らせる機能です。

![auto-pause](/images/morihaya-20250401-pagerduty-night-shift/2025-04-02-00-33-34.png)

## おわりに

以上が「PagerDutyでService Orchestrationsを用いて夜間インシデントを通知遅延させる技」の記事でした。Event Orchestrationは多機能ですべての機能を使いこなせてはいませんが、要件に応じて深掘りしてみると大体のことはできる優れものです。シンプルさを継続しつつも各チームの要件にも応えられるバランスを考え続けていきたいですね。

それではみなさまEnjoy PagerDuty!

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味をもった方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recuruiting.aeon.info/)
