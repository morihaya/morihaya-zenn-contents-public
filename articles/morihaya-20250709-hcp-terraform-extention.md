---
title: "HCP Terraform Plan結果を見やすくするGitHub PR向けブラウザ拡張のご紹介"
emoji: "🍊"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: # タグを指定する
  - "hashicorp"
  - "terraform"
  - "github"
  - "chrome拡張"
  - "aeon"
published: true
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。

本記事では、当社で利用しているHCP Terraform（以降はHCPt）において、GitHubでPR(Pull Request)を作成した際に実行されるplanの結果をわかりやすく表示するブラウザ拡張を作成したので紹介します。

![before_after](/images/morihaya-20250709-hcp-terraform-extention/2025-07-09-09-52-14.png)

## TL;DR

本記事を箇条書きでまとめると以下です。

- ADOからGitHubへTerraform関連リポジトリを移行しているが、PR時のPlan結果が見づらくなった
- AIパワーでVibe Codingしてブラウザ拡張を作った
  - [Chrome Web Store](https://chromewebstore.google.com/detail/github-hcp-terraform-plan/jkgkbodmannfjfidngjejojmhhacolop)
  - [Edge Add-on](https://microsoftedge.microsoft.com/addons/detail/github-hcp-terraform-plan/ddclhlggkolkmeofiocfecepdekaipjj)
- PRのHCP TerraformのPlan結果が大変見やすくなった

## 背景

当社では[ADO](https://azure.microsoft.com/ja-jp/products/devops/)の[Repos](https://azure.microsoft.com/ja-jp/products/devops/repos/)と[HCP Terraform](https://developer.hashicorp.com/terraform)を利用し、Azureの主要リソースやNew Relicなど、さまざまなプロダクトの管理をTerraformで管理し、VCSとしてADOを利用し、HCPtでCI/CDを行なってきましたが、昨今のAI機能の充実さを鑑みVCSはGitHubへの移行を進めています。

GitHubへの移行は目的であったAI支援（とくにGitHub Copilot Coding agent）を受けられる点で素晴らしいメリットがありますが、一方で体験が悪くなることもありました。

それが「PR作成時に実行されるHCPtのplan結果が、ADOに比べて見づらい」といったものです。

## ADOではPlanの結果の数値がわかる

ADOでは以下の図の通り、HCPtの結果が`Terraform plan: 3 to add, 0 to change, O to destroy.`のようにそれぞれの数値も明確に表示されます。実際のHCPtのRunページもこの数値が表示されているエリアをクリックすれば開けます。

![ado_pr](/images/morihaya-20250709-hcp-terraform-extention/2025-07-09-09-11-35.png)


## GitHubではPlanの結果の成否しかわからない

一方でGitHubでは、以下のようにPlanの結果が正常かどうかはわかりますが、具体的な`add, change, destroy`の数値を確認することはできませんでした。

![github_pr](/images/morihaya-20250709-hcp-terraform-extention/2025-07-09-09-17-51.png)

実際にはPlanの各数値は後半に表示されているのですが、表示の仕様上省略されている状況でした。
以下はブラウザのウィンドウサイズを広げた結果ですが、途中から省略されていることがわかります。

![github_pr_wide](/images/morihaya-20250709-hcp-terraform-extention/2025-07-09-09-20-47.png)

## 同僚氏のブラウザ拡張機能にインスパイアされ、Vibe Codingの練習がてら自作へ

不満を感じている中、同僚の[@raki](https://x.com/raki)さんが開発している[GitHub向けブラウザ拡張機能](https://github.com/officel/github-web-cosmetic)がGitHubのPR上でのHCPt Plan結果をADOっぽく表示する機能を実装してくれて、当初はこちらを利用していました。

上述したrakiさんのgithub-web-cosmeticの表示に満足していたものの、昨今のAI隆盛の流れの中で「これはVibe Codingの練習にちょうど良さそう」と思い立ち自分でも自作することとしました。

利用したのは主にClaude Codeと、途中からGitHub Copilotです。どちらもSonnet 4のモデルを利用して気分で使い分ける形でした。
コード自体は土日の片手間で全体通して2,3時間程度で完了しています。個人的に一番大変なのはストアへの登録でした。


## Chrome Web StoreとEdge Add-onsへ申請して無事に公開へ至る

ストアへの申請のために、Geminiでアイコン画像を生成し、説明のためのスクリーンショットを指定されたサイズで準備しました。
申請の各種記入欄についても基本的にはSonnet 4に支援してもらいながら、得意ではない英語で入力していきました。

申請後、Chrome Web Storeは2日ほどで、Edge Add-onsは5日ほどで無事に審査が通り、以下のように公開することができました。
ニッチなツールではありますが世界に自作のブラウザ拡張機能が公開されるというのは楽しい気分です。

- ブラウザ拡張「GitHub HCP Terraform Plan Formatter」
  - [Chrome Web Store](https://chromewebstore.google.com/detail/github-hcp-terraform-plan/jkgkbodmannfjfidngjejojmhhacolop)
  - [Edge Add-on](https://microsoftedge.microsoft.com/addons/detail/github-hcp-terraform-plan/ddclhlggkolkmeofiocfecepdekaipjj)

![chrome_webstore](/images/morihaya-20250709-hcp-terraform-extention/2025-07-09-10-35-05.png)
![edge_add-ons](/images/morihaya-20250709-hcp-terraform-extention/2025-07-09-10-38-12.png)

## おわりに

以上が「HCP Terraform Plan結果を見やすくするGitHub PR向けブラウザ拡張のご紹介」でした。

今回の記事で一番の学びは「ブラウザ拡張の開発とAIによるVibe Codingは相性が良い」です。
便利なAI支援ですが、お客様向けの大規模かつ複雑なプロダクションコードでは複雑性が増し、テストとレビューの負担が大きくなる感触があります。

一方で今回のようなブラウザ拡張の場合、基本はスクラッチ開発になりますしコードの規模も大きくはなりません。
テストについても基本的には自分が便利に使うためのものであるため、ブラックボックス的なテストで期待する動作をすれば問題ないと判断できます。

こうして手応えをえましたので、今後もちょっと自分が便利になるかもしれないツール開発にもAI支援を活用していこうと考えています。

それではみなさまEnjoy HCP Terraform & Vibe Coding！

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味もった方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recruiting.aeon.info/)
