---
title: "GitHub Copilot usage metrics dashboardに感じるAIガバナンス"
emoji: "📈"
type: "tech"
topics:
  - "github"
  - "githubcopilot"
  - "aeon"
published: false
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。

本記事は[AEON Advent Calendar 2025](https://qiita.com/advent-calendar/2025/aeon)の11日目の記事です。

今回は、2025年10月28日にPublic Previewとして公開された“[Copilot usage metrics dashboard](https://github.blog/changelog/2025-10-28-copilot-usage-metrics-dashboard-and-api-in-public-preview/)”を紹介します。

## TL;DR

- Copilot usage metrics dashboardがPublic Previewとして利用可能になった
- 利用言語の割合やActive User数など、組織のCopilot活用状況を可視化できる
- AIツールの利用状況を把握することは、これからのAIガバナンスにおいて重要な一歩となる期待
- 今後の進化に、個人レベルの利用状況までドリルダウンできることを期待したい

## Copilot usage metrics dashboardとは

まずはCopilot usage metrics dashboardについて簡単に説明します。
Copilot usage metrics dashboardは、GitHub Copilotの利用状況を可視化するためのダッシュボードです。Enterprise管理者およびBilling Managerが、組織全体でのCopilot活用状況を把握できるようになりました。現時点ではプレビューフェーズの新しい機能です。

![cumd](/images/morihaya-20251211-github-copilot-usage/2025-12-11-03-41-46.png)

具体的には以下のような情報が確認できます。

- Active Users: 実際にCopilotを利用しているユーザー数
- Code Completions (acceptance rate): コード補完の採用率や生成行数
- Chat model usage: Copilotで利用しているModelの利用状況
- Language usage per day: どのプログラミング言語でよく使われているか

これらのメトリクスを視覚的に確認できるようになったのは大きな進化です。GitHubの継続的な改善に感謝します。

## Copilot usage metrics dashboardの有効化

このダッシュボードを有効化するには、Enterprise管理者による設定が必要です。[How to enable Copilot usage metrics in your enterprise](https://github.blog/changelog/2025-10-28-copilot-usage-metrics-dashboard-and-api-in-public-preview/#how-to-enable-copilot-usage-metrics-in-your-enterprise)より抜粋すると以下になります。

1. github.comでEnterprise設定の「AI Controls」タブに移動する
2. 左サイドバーから「Copilot」を選択する
3. 「Metrics」セクションまでスクロールし、「Copilot usage metrics」を見つける
4. Copilot usage metricsのポリシー設定を「Enabled」に変更する

これにより、EnterpriseのCopilot usage metricsダッシュボードとAPIが有効化され、Enterprise管理者およびBilling managerが利用状況と採用データを確認できるようになります。

![ai-control](/images/morihaya-20251211-github-copilot-usage/2025-12-11-04-45-37.png)

その後スクロールして

![enable-copilot-usage-metrics](/images/morihaya-20251211-github-copilot-usage/2025-12-11-04-47-20.png)

## 現在足りていないと感じること

その有用性は素晴らしいものですが、このダッシュボードには現時点ではいくつかの機能が不足しています。

### 個人レベルの詳細が見えない

組織全体やチーム単位での集計値は見えますが「誰がどれくらい使っているか」という個人レベルの情報までドリルダウンできません。ライセンス管理の観点からすると、「割り当てているけど使っていないユーザー」を特定してライセンスの最適化を図りたいケースがあり、今の機能ではその用途を満たしていません。

### 時系列での傾向分析が限定的

組織の振り返りは1か月、4か月、半年、年の単位で行われることが多くあります。このようなロングスパンで利用状況の推移を追いたい場合、今のUIにある機能では物足りなさを感じます。
スクリーンショットのように7, 14, 28 daysの3択しかなく、「導入から4ヶ月でどれだけ浸透したか」あるいは特定の週の利用状況といった分析はできません。

![time-frame](/images/morihaya-20251211-github-copilot-usage/2025-12-11-02-50-27.png)

### 利用言語の解像度の低さ

言語の粒度についても疑問があります。下記スクリーンショットの通り、「Other Languages」の割合がかなり大きくなっています。実際にGitHub Copilotを率先して利用しているチームのひとつに私たちSREチームがありますが、私たちが多く書くTerraformやYAML、Markdownなどはすべて「Other Languages」としてまとめられてしまっているようです。

私たちの観点からはTerraformやKubernetesのマニフェスト（YAML）でどれだけCopilotが活用されているかを把握したいところですが、その詳細が見えません。TypeScriptやPythonといったメジャーな言語は個別に表示されるのに対し、IaC系の言語が重視されていない印象を受けます。

![many-language-in-others](/images/morihaya-20251211-github-copilot-usage/2025-12-11-02-55-19.png)

## ダッシュボードの活用方法

上記のように多少の不足点をあげつつも、このダッシュボードはAI利用のガバナンスの第一歩として活用の価値があります。私たちのチームでは以下のような使い方を検討しています。

### 定期的な利用状況のモニタリング

定点観測を続けることは新たな気づきが生まれます。月次でダッシュボードを確認し、Active User数の推移をウォッチします。当社のGitHub Copilotライセンスの付与は希望者のみに付与しています。しかしながら導入したものの使われていない、そんな状況を早期に検知できるのが嬉しいポイントです。

### 言語別の活用状況から施策を検討

たとえばTypeScriptでの利用率が高くPythonでの利用率が低い場合、「Python向けのCopilot活用Tips共有会」を開催するといった施策につなげられますし、社内の多くのプロダクト・チームに対して横断的に組織の状態を伝えられます。

### 投資対効果の説明材料として

GitHub Copilotはユーザライセンスでの課金です。当社は定期的なコスト最適化の取り組みを継続的に行っています。AIの活用推進を掲げる一方で不必要なライセンスは正すべきです。また経営層への報告時に、「これだけのユーザーが日常的に活用しています」との定量的なデータを示せる点も魅力的です。

## おわりに

以上が「GitHub Copilot usage metrics dashboardに感じるAIガバナンス」でした。

AIツールの導入は「入れて終わり」ではなく、継続的に利用状況を把握し改善していくことが大切です。今回紹介した「GitHub Copilot usage metrics dashboard」は、まさにそのための土台となる機能だと感じています。

まだPublic Previewの段階で機能が不足している点もありますが、今後さらに機能が拡充されることを期待しています。とくに個人レベルの詳細や、より柔軟な時系列分析ができるようになると嬉しいです。

それではみなさま、Enjoy GitHub Copilot!

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味を持った方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recruiting.aeon.info/)
