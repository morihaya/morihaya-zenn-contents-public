---
title: "GitHub CopilotのTargeted model rules(Preview)の有効化で一時的にモデル選択が不可となった"
emoji: "🎯"
type: "tech"
topics:
  - "github"
  - "githubcopilot"
  - "aeon"
published: true
published_at: "2026-06-23 08:00"
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://x.com/morihaya55)です。

当社はGitHub Enterprise Cloud with Enterprise Managed Users（以降はGitHub EMU）を利用しており、私たちSREチームはEnterpriseやOrganization単位でGitHub Copilotの設定を管理する機会があります。

先日、社内から突然「GitHub Copilotのモデル選択が出来なくなった〜（涙）」と悲鳴が上がり、調査したところGitHub ChangelogでPublic Previewとして案内されていた[Targeted model rules](https://github.blog/changelog/2026-05-26-target-copilot-models-to-organizations-with-model-rules/)の機能が有効になったことが原因だった、との事象に遭遇しました。

![cannot_choice_models](/images/morihaya-20260623-targeted-model-rules/2026-06-23-13-07-59.png)

Targeted model rulesは執筆時点でPreviewなため、GAに向けて仕様はもう少し優しい仕様になると想定しますが、同じ事象で驚くかもしれないGitHub EMUユーザ＆管理者向けの注意喚起としてブログします。

## TL;DR

- Targeted model rulesの機能自体は大変有用。Organization単位でモデルを柔軟に絞れて良い
- Preview期間だからか、機能有効化のタイミングでデフォルトでモデル選択が使えなくなったのは驚いた
- GitHub EMU管理者のみなさんはお気をつけどうぞ、Ruleを作れば再び使えるようになります

## Targeted model rulesとは

Targeted model rulesは、Enterprise配下のOrganizationごとにGitHub Copilotで利用可能なモデルを制御できる機能です。

https://docs.github.com/en/copilot/how-tos/administer-copilot/manage-for-enterprise/manage-availability-of-default-models#creating-targeted-model-rules


従来もEnterprise全体でCopilotモデルの有効・無効は管理できましたが、Targeted model rulesにより「このOrganizationではこのモデルを許可する」といった、より細かな制御ができるようになります。

GitHub Changelogでは、主に以下のような内容として案内されています。

- Enterprise OwnerがOrganizationごとに利用可能なCopilotモデルを制御できる
- Enterprise全体のデフォルトモデル設定に加えて、特定Organization向けのルールを作成できる
- デフォルトモデルの管理画面も更新され、各モデルを`Enabled`または`Optional`として扱える
- Copilot BusinessおよびCopilot Enterpriseプランで利用できる
- 現時点ではPublic Preview

https://github.blog/changelog/2026-05-26-target-copilot-models-to-organizations-with-model-rules/

## 機能としてはとても嬉しいTargeted model rules

まず前提として、このTargeted model rules機能自体はとても嬉しいものです。

GitHub Copilotのモデルは日々増えています。Claude、GPT、Gemini、今後は[MAI‑Code‑1‑Flash](https://github.blog/changelog/2026-06-18-mai-code-1-flash-available-on-more-copilot-surfaces/)など複数のモデルが選べることはユーザにとって大きな利点ですが、Enterprise管理者の立場では考えることも増えます。

たとえば以下のようなケースです。

| やりたいこと | Targeted model rulesで期待できること |
| --- | --- |
| 特定Organizationだけ新モデルを先行検証したい | 検証用OrgにだけPreviewモデルを許可できる |
| Lowコストモデルに絞って展開したい | コスト最適化の観点 |
| 本番開発チームには安定モデルだけを見せたい | 主要モデルに絞った運用ができる |
| チームごとの利用方針に合わせたい | Org単位でモデル選択肢を変えられる（チームとOrgをどんな建て付けにするかはあるが） |
| AIガバナンスを段階的に強めたい | Enterprise全体一括ではなくOrg単位で小さく適用できる |

とくにGitHub EMUのようにEnterprise配下に複数Organizationを持つ運用では、「全体に一律で適用する」よりも「Organization単位で段階的に適用する」ほうが現実的な場面があります。（と書きましたが、Org分割はインナーソースなどの観点から極力避けており、当社のOrg数は極めて少ないです）

その意味で、Targeted model rulesはエンタープライズなOrgを複数持つ大規模環境において、AIガバナンスの運用を一段進める機能だと感じます。

## 何が起きたのか

6月中旬のある日、突然組織内のユーザが選べるモデルがAutoまたはHaikuのみになりました。

![cannot_choice_models](/images/morihaya-20260623-targeted-model-rules/2026-06-23-13-07-59.png)
上記のスクリーンショットではAutoのみですが、私個人のCopilot CLIではClaude Haiku 4.5のみが選べる状態となっていました。

これを受けてGitHub管理者としては一瞬で血の気が引きます。

「何か設定を間違えたか？」
「Enterprise全体のモデル設定を壊したか？」

Haiku 4.5は決して悪いモデルではありませんが、大きめな機能追加やレビュー計画においてはOpusやGPTを選択するのが現時点で優れた手法とされています。
この状況はとてもまずいと考え、慌てて調査を開始しました。

## 調査の流れと、原因として見えたこと

### Budgets and alertsは問題なし

最初に疑ったのは予算（Budget）超過による制限です。
[Billing and licensing]->[Budgets and alerts]->[All AI Credit SKUs]を確認しましたが、6月からのToken従量課金を受けて多めにしていたこともあり、問題がない状況でした。

![budgets](/images/morihaya-20260623-targeted-model-rules/2026-06-23-13-24-33.png)

### 従来のモデルの設定は問題なし

次に、GitHub管理者の誰かが、何らかの理由でモデルの許可をオフにした可能性を疑いました。
[AI Controls]->[Copilot]->[Configure allowed models]を開き、”Enterprise-wide enabled models”を確認しましたが、意図したモデルが有効化されていました。

![enterprise_enabled](/images/morihaya-20260623-targeted-model-rules/2026-06-23-13-28-57.png)

念の為Orgレベルでも同様に確認しましたが、当然のようにEnterpriseレベルでEnabledされたものは許可されていました。

### 見慣れない項目「Targeted model rules」に気づく

混乱しながら何度目かの確認をしたところ、上述した「Enterprise-wide enabled models」と同じ画面の下の方に見慣れない「Targeted model rules」の存在に気づきます。

![Targeted model rules](/images/morihaya-20260623-targeted-model-rules/2026-06-23-13-32-36.png)

Previewとある通り最近有効になったようです。
とうぜんながらこの時点ではTargeted model rulesには何もRuleは作成されていない状態でした。

上述した[Changelog](https://github.blog/changelog/2026-05-26-target-copilot-models-to-organizations-with-model-rules/)も参照し、磁気的なものからあやしいぞと思い、状況を改善したい思いから設定することにしました。

## 対応したこと

対応としては、EnterpriseのAI ControlsからCopilotモデルの設定を確認し、Orgに対して利用させたいモデルを改めて有効化しました。

手順は以下の通りです。

1. Enterprise設定のAI Controlsを開く
2. CopilotのModelsページを開く
3. Targeted model rulesの右側にある「Create access rule」をクリック
4. 対象となるOrgと、許可するModelを選択する（画面参照）

![create_target_rule](/images/morihaya-20260623-targeted-model-rules/2026-06-23-13-39-57.png)

＊GitHubの画面は更新が早いため、細かなメニュー名や画面構成は変わる可能性があります

## おわりに

以上が「GitHub CopilotのTargeted model rules(Preview)の有効化で一時的にモデル選択が不可となった」でした。

Targeted model rulesは、Organization単位でGitHub Copilotのモデル選択肢を制御できる大変有用な機能です。AI活用が広がるほど、モデルをどう許可し、どう段階的に展開するかは重要な管理ポイントになるでしょう。

一方で、突然組織内ユーザのモデル選択肢ができなくなったのはなかなか刺激的な体験でした。高機能モデルの恩恵を一時的とはいえ失ってわかるありがたみですね。

GitHub EMU管理者のみなさまは、ぜひ検証範囲を小さくしつつ、モデル設定のBefore/Afterを確認しながらお試しください。

それではみなさま、Enjoy GitHub Copilot and Targeted model rules!

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味を持った方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recruiting.aeon.info/)
