---
title: "GitHub CopilotのSkillsは手順書だ：3桁行差分の大規模Terraform移行に使い回す"
emoji: "📋"
type: "tech"
topics:
  - "githubcopilot"
  - "terraform"
  - "azure"
  - "azurefrontdoor"
  - "aeon"
published: false
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。

本記事ではGitHub Copilotの「Skills」と呼ばれる機能について、私たちJTCやEnterpriseの文脈で捉え直した結果「要は手順書ですね」と捉えることで複雑なTerraformの移行を再現性のある形で進められるようになった話を紹介します。

ポイントは「Skills」ってカッコ良い表現よりも、「AI用の手順書じゃん」と捉えることで利用の敷居が大幅に下がったという点です。

## TL;DR

- Skills、Custom-instructionなんて言葉に惑わされていたかも
- 「Skills」=「Copilotのための手順書」と捉えると、従来のIT作業の考え方にもフィットする
- 3桁行近く差分がでるAzure CDN ClassicからFront DoorへのTerraformリプレースが再現性ある状態となった

## SkillsやCustom instructionsとは

GitHub Copilotを日常的に利用している方であれば耳にしたことがあるであろう「Skills」について、ここではGitHub Copilotでの位置づけに絞って簡単に説明します。

### Custom instructions

Custom instructionsはGitHub Copilotに対して「自分たちのプロジェクトではこういうルールで動作してね」と伝えるための仕組みです。リポジトリのルートに `.github/copilot-instructions.md` を配置することで、Copilotがコードを生成する際にその内容をコンテキストとして参照してくれます。

https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions

たとえば「Terraformのリソース名はスネークケースで書く」「変数名にはプレフィックスをつける」といったコーディング規約をここに書いておけば、Copilotがそれに沿ったコードを生成してくれます。

### Skills

SkillsはCustom instructionsに対して、より具体的な指示やスクリプトを反復して利用するための指示書です。特定のタスクに対して、より詳細な手順や判断基準をMarkdownファイルやスクリプトとして定義しておく仕組みです

https://docs.github.com/ja/copilot/concepts/agents/about-agent-skills

当チームでもTerraformの利用規約や環境情報をCustom instructionへ、具体的なリソース追加時のお作法などをSkillsに定義し、チームのナレッジを形式知としてCopilotに伝えています。

## 横文字ばっかだな、と思った

さて本題です。
SkillsもCustom instructionsも素晴らしい機能であることは間違いありません。しかし私はこれらの用語を社内で展開しようとした際に、ふと立ち止まりました。

「Skills？Custom instructions？...なんだか横文字ばかりで、伝わりにくいな」

私たちSREチームはAIツールの活用に積極的ですが、組織全体で見ればAIに馴染みのないメンバーも少なくありません。そこに「GitHub Copilotを利用するにはSkillsを定義しましょう」「Custom instructionsを書きましょう」と言ったところで「何それ？どうちがうの？」となる可能性を懸念しました。（事実として私も当初は少なからず混乱しました）

そんなとき、ふと気づいたのです。

Skillsって、いわゆる手順書じゃないか。

## Skills=手順書という発見

考えてみると、Skillsがやっていることは以下の通りです。

- 特定のタスクに対する前提条件を整理する
- 作業の手順をステップバイステップで記述する
- 判断基準や注意事項を明記する
- 期待される成果物のフォーマットを定義する

まさに、SIerやEnterprise環境で長年運用されてきた「手順書」そのものです。

| 手順書の構成要素 | Skillsでの対応 |
|---|---|
| 目的・概要 | descriptionフィールド |
| 前提条件 | 前提条件セクション |
| 作業手順 | ステップバイステップの記述 |
| 注意事項 | 制約条件やガードレールの記述 |
| 期待結果 | 出力フォーマットの定義 |

つまりSkillsとは「人間が読む手順書の代わりに、AIが読めるようにしたもの」と言い換えることができます。

この表現の考え方は地味ですが、経験豊富な方への展開において強力だと考えました。「Skillsを書きましょう」と言うと構えてしまう人も、「繰り返される作業はAI向けの手順書を書きましょう、それがSkillsです」と言えば受け入れやすいのではないでしょうか。

## 事例：Azure CDN ClassicからFront Doorへの大規模移行

この「Skills=手順書」の考え方が直近でもっとも効果を発揮したのが、Azure CDN ClassicからAzure Front DoorへのTerraformリプレースでした。

### 背景：Azure CDN Classicの廃止

Azureを利用されている方にはご存じの方も多いでしょうが、Azure CDN Standard from Microsoft (classic)は廃止が予定されています。

https://learn.microsoft.com/en-us/azure/cdn/classic-cdn-retirement-faq

当社ではAzure CDN Classicを複数プロダクトの複数環境で利用しています。これらすべてをAzure Front Doorへ移行する必要があり、当然ながらTerraformで管理しているためTerraformコード側もリプレースが必要です。

### GUIからは移行が簡単

このAzure CDN ClassicからAzure Front Doorへの移行はAzure Portalで簡単に影響なしで実施が可能です。

以下の図のように、Migrationの画面からボタンぽちぽちで進められます。
![migration](/images/morihaya-20260224-copilot-skills-is-tetsuzukisho/2026-02-25-02-51-12.png)

### Terraformコード移行の難しさ

一方でTerraformコードの移行は大変です。この移行が厄介なのは単純な「リソースの設定変更」ではなく、リソース構造がフラットな構造から分散した構造へ作り変わる点です。

| 移行元（CDN Classic） | 移行先（Front Door） | 役割の違い |
|---|---|---|
| `azurerm_cdn_profile` | `azurerm_cdn_frontdoor_profile` | プロファイル本体 |
| `azurerm_cdn_endpoint` | `azurerm_cdn_frontdoor_endpoint` | エンドポイント（ホスト名）の定義のみ |
| （endpointに内包） | `azurerm_cdn_frontdoor_origin_group` | バックエンドのグルーピング、ヘルスプローブ設定 |
| （endpointに内包） | `azurerm_cdn_frontdoor_origin` | 実際のバックエンドサーバー設定 |
| （endpointに内包） | `azurerm_cdn_frontdoor_route` | エンドポイントとオリジングループの紐付け、パス設定 |
| `azurerm_cdn_endpoint_custom_domain` | `azurerm_cdn_frontdoor_custom_domain` | カスタムドメイン定義（検証方法が異なる） |

とくに `endpoint` ひとつにまとまっていた設定が `origin_group`, `origin`, `route` に分割されるため、import時にそれぞれのリソースIDを特定してブロックを書く必要があります。

見ての通り、CDN Classicでは1つのendpointに内包されていた設定が、Front Doorでは複数の独立したリソースに分離されます。つまり1つのCDN Classicリソースを移行するだけでも、複数のTerraformリソースを新規に定義し直す必要があるのです。

これらをすべて対応するとその差分行数は3桁近くになります。

### 手順書（Skill）を書く

ここで「Skills=手順書」の出番です。

まず、Terraform力の高い同僚氏が最初の1つのCDN ClassicリソースをFront Doorへ移行しました。
同様の作業を私が別環境に行った際、Opus 4.5の支援を受けてもapply可能となるまで5回以上のやりとりが発生しました。

そこでふと閃いたのがSkillsの活用です。

完了済みのCommitからファイル差分を抽出し、GitHub Copilotに渡して作業手順としてSkillファイルを書き出しました。内容としては以下のような構成です。

```markdown
# Azure CDN → Front Door 移行ガイド (Terraform)

Azureポータルの移行ツールでCDN Standard_Microsoft → Front Door Standard_AzureFrontDoor へ
インプレース移行した後、Terraformコードを追従させるための実践ガイド。

## 前提条件
- Azureポータルで CDN → Front Door のインプレース移行が完了済み
- 移行後、同一のAzureリソースIDでCDN ProfileがFront Door Profileに変わっている
- Terraform stateにはまだ旧CDNリソースが登録されている

## 移行の全体像
1. モジュールにFront Doorリソース定義を追加（use_front_door フラグで切替）
2. 旧CDNリソースをstateから安全に除去（moved + removed のチェーン形式）
3. 新Front Doorリソースを import ブロックでstateに取り込み
4. diagnostic_setting から旧 cdn_endpoint エントリを削除

## 変更対象ファイル（モジュール層）
- variables.tf : use_front_door 変数を追加
- cdn.tf : 既存CDNリソースに count = var.use_front_door ? 0 : 1 を追加
- front_door.tf : 新規作成 — profile, endpoint, origin_group, origin,
                  route, rule_set, rule, custom_domain, association を定義
- outputs.tf : CDN/Front Door の条件付き出力に変更

## 変更対象ファイル（システム層）
- variables.tf : use_front_door = true を設定
- main.tf : モジュール呼び出しに use_front_door パラメータを追加
- diagnostic_setting.tf : cdn_endpoint エントリを削除
- import.tf : Front Door importブロック + 旧CDN moved/removedブロックを追加

## ⚠️ 最重要：moved チェーン
state内での変換フロー:
  main (インデックスなし) → main[0] (count追加) → main_cdn (リネーム) → removed
count追加前のstateはインデックスなしで格納されているため、
main → main[0] → main_cdn → removed の3段チェーンが必須。

## よくあるミス
- Endpoint の tags = {} → Azure側のタグが削除される
- Route に cdn_frontdoor_origin_path 未設定 → origin_path が null になる
- Rule Set 名の不一致 → import 失敗（Azureポータルで実名を確認）

## Plan結果の期待値
Plan: N to import, 2 to add, M to change, 0 to destroy.
⚠️ destroy が 1以上ある場合は moved チェーンを確認！
```

上記はブログ掲載用に要約した概要ですが、実際のSkillにはリソースIDのパターンや環境別の適用順序、具体的なHCLコードのテンプレートまで記載しています。

### 手順書をSkillとしてCopilotに渡す

この手順書をSkillとして配置し、Copilotに「このSkillを使用し、移行済みのCDN ClassicリソースをFront Door書き換えて」と指示したところ、1回でapply可能なTerraformコードが生成されるようになりました。

ポイントは以下です。

1. 手順書（Skill）があるため、Copilotが毎回同じルールでコードを生成する
2. 人間が手順書をレビューすることで、AIの出力品質を担保できる
3. 手順書を改善すれば、以降のすべての移行作業に反映される

とくに3番目が重要で、最初の数件で「ここの変換ルールが足りなかった」「この設定値のデフォルトが違った」といったフィードバックを手順書に反映していくことで、回を重ねるごとに精度が上がるでしょう。

### 再現性という価値

3桁行に近いTerraformコードの書き換えにおいて「再現性」は極めて重要です。

手作業であれば担当者のスキルや体調によって品質にばらつきが出ます。Copilotに任せたとしても複数回のやりとりが発生しました。移行用スクリプトを書く方法もありますが、CDN ClassicからFront Doorへの変換は設定の差異などから複数パターンにわたり、すべてのケースを網羅するスクリプトを書くのは結構な労力です。

一方でSkill（手順書）＋Copilotの組み合わせであれば、手順書に記載されたルールに沿って柔軟にコードを生成してくれます。パターンが増えれば手順書に追記するだけです。

現時点で移行作業は完了していませんが、「再現性ある状態」つまり「あとはこの手順書通りにCopilotに依頼すればいい」という状態にたどり着けたことは大きな進歩です。

## 手順書文化をAI時代のアドバンテージに

ここまでの話を振り返ると、JTC・Enterpriseで長年培われてきた「手順書文化」は、AI時代においてむしろアドバンテージになり得るのではないでしょうか。

手順書として形式知化されたナレッジは、そのままAIへのインプットになります。暗黙知として個人の頭の中にしかないナレッジよりも、普通のMarkdownで書かれた手順書のほうがこのAI時代には大きな価値となります。

そして手順書を書く文化がある組織はSkillsを書く土壌がすでにあり、それらを積極的に活用していけると強く感じています。むしろ従来の細かなコマンドレベルの正確さが必要な人間向けの手順書に比べて、生成AIはいい感じに補完する能力があるため、より簡単に作成できるわけですから多くの便利なSkillsを生み出せるでしょう。

## おわりに

以上が「GitHub CopilotのSkillsは手順書だ：3桁行差分の大規模Terraform移行に使い回す」でした。

SkillsもCustom instructionsも、要するに「AIに渡す手順書・指示書」です。横文字に惑わされず、自分たちがこれまでも行ってきた「手順書を書く」という行為の延長線上で捉えれば、Skills活用のハードルはぐっと下がるのではないでしょうか。

Azure CDN ClassicからFront Doorへの移行はまだ完了し切ってはいませんが、「再現性ある手順」が確立できたことで、あとは粛々と進めるフェーズに入っています。手順書文化万歳です。

それではみなさま、Enjoy GitHub Copilot & Skills！

---

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味を持った方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![イオングループエンジニア採用バナー](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recruiting.aeon.info/)
