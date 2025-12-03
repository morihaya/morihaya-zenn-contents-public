---
title: "毎日のSRE朝会でTerraformの割れ窓対応を加速するHCP Terraform Explorer機能"
emoji: "🪟"
type: "tech"
topics:
  - "hashicorp"
  - "terraform"
  - "hcpterraform"
  - "aeon"
published: true
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。

本記事は[AEON Advent Calendar 2025](https://qiita.com/advent-calendar/2025/aeon)の1日目の記事です。

とても便利だが意外と知名度が低そうなHCP Terraform（以降はHCPt）の[Explorer機能](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/explorer)を紹介します。

## TL;DR

- HCPtには多くの便利機能がありExplorerもそのひとつ
- Explorer機能はOrganizationを横断したHCPt関連の情報を確認でき、カスタマイズしたViewを保存できる
- Saved Viewsを活用して、毎朝のSRE朝会で『割れ窓的なDriftとRun異常』を素早く発見・共有している

## HCP TerraformのExplorer機能とは

Explorerは、HCPtのOrganization内にあるすべてのWorkspaceを横断的に検索・フィルタリングできる機能です。HCPtの左メニューから「Explorer」を選択するとアクセスできます。

![explorer_butten](/images/morihaya-20251201-terraform-fix-drifts/2025-12-01-20-18-20.png)

この機能自体は少なくとも自分がHCPtを触り始めた頃から存在していましたが、正直なところ私たちSREチームが本格的に利用し始めたのは比較的最近でした。チームメンバーの [@raki](http://x.com/raki)の提案によって「こんな便利な機能があったのか！」と驚いたのを覚えています。

### Explorerでできること

Explorerでは以下のような情報を一覧で確認できます。

- Workspaceの状態（Run Status）
- Driftの有無（Health Status）
- 管理しているリソース数
- Terraformのバージョン
- 最終Run日時
- タグ情報

大規模なTerraform運用では『全体像が一望できるダッシュボード』が重要になります。
この手のダッシュボード系機能・ツールに私が求めるのは「デフォルトでも便利に使えるようなプリセット」ですが、HCPtのExplorerも「Types & use cases」のタブにしっかりと備えてくれています。

![types_and_usecases](/images/morihaya-20251201-terraform-fix-drifts/2025-12-01-20-28-15.png)

#### Types

Types（赤枠）では以下4つのタイプごとに一覧を表示できます。

1. Modules
1. Workspaces
1. Providers
1. Terraform Versions

表示した一覧に対してさらに細かいフィルタをかけていくことが可能なため、自分が見たいものをまずは一覧化して条件で絞る際に便利です。

個人的によく使うのはやはり「Workspaces」で、管理する数も多いためさまざまな観点で横断的に確認したいケースがあります。とくに「Names」「Tags」に対して「is」「Contains」などの条件は使い勝手が良いです。

![modify_conditions](/images/morihaya-20251201-terraform-fix-drifts/2025-12-01-21-22-59.png)

#### Use cases

Use cases（青枠）では以下の12のユースケースに対応する一覧を表示します。わかりやすくするために簡単な概要を日本語で付与しています。

1. Top module versions（使用頻度の高いモジュールバージョンの一覧）
1. Top provider versions（使用頻度の高いプロバイダーバージョンの一覧）
1. Workspace VCS source（VCSリポジトリ別のワークスペース一覧）
1. Drifted workspaces（差分が発生しているワークスペースの一覧）
1. Workspaces by run status（Run状態別のワークスペース一覧）
1. Latest updated workspaces（最近更新されたワークスペースの一覧）
1. Latest Terraform versions（最新のTerraformバージョンを使用しているワークスペース一覧）
1. Workspaces without VCS（VCS連携していないワークスペースの一覧）
1. Workspaces with failed checks（チェックが失敗しているワークスペースの一覧）
1. All workspace versions（全ワークスペースのTerraformバージョン一覧）
1. Top Terraform versions（使用頻度の高いTerraformバージョンの一覧）
1. Oldest applied workspaces（長期間applyされていないワークスペースの一覧）

日頃からTerraformでIaCを利用している方であれば、どれかひとつくらいは「見たい」と思える一覧があるはずです。
まずは自分のチームで一番困っている観点（例：Drift・失敗Run・VCS未連携など）から触ってみると良いと思います。

### Saved Viewsで条件を保存できる

さて本題でもあるExplorerで一番気に入っているのが「Saved Views」機能です。よく使うフィルタ条件をViewとして保存しておけるため、毎回同じ条件を設定する手間が省けます。

Saved Viewsの作成は簡単で、保存したい表示状態で右上の「Actions」ボタンを押して「Save」をクリックします。
![actions_save](/images/morihaya-20251201-terraform-fix-drifts/2025-12-01-21-27-36.png)

次にポップアップに保存するView名をつけるだけです。日本語もいけるのは日本人としては嬉しいです。

![saveasview](/images/morihaya-20251201-terraform-fix-drifts/2025-12-01-21-29-04.png)

このようにSaved Viewsはチームで共有できるViewを作成することもできるので、「SREチームで監視すべきWorkspace一覧」のような形で運用に組み込めるのがポイントです。

### Explorerを利用できるHCPの権限に注意

(2025-12-03追記)コメントでrakiさんから指摘いただいた通り、Explorerの検索結果は誰もが見えるわけではありません。公式ドキュメントの[Permissions](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/explorer#permissions)には以下の記載があり、オーガニゼーションオーナーまたは、すべてのワークスペースが参照できるかそれ以上の権限を推奨とあります。

> The explorer for workspace visibility requires access to a broad range of an organization's data. To use the explorer, you must have either of the following organization permissions:

> - Organization owner
> - View all workspaces or greater

権限が足りない場合はそのユーザが参照可能なワークスペースしか表示されないといった結果になりますので注意してください。

## 割れ窓理論とは

ブログのタイトルに「割れ窓対応」と書いたので、簡単に「割れ窓理論」についても記載します。

割れ窓理論（Broken Windows Theory）は、1982年にアメリカの犯罪学者ジョージ・ケリング氏とジェームズ・ウィルソン氏によって提唱された理論です。「建物の窓が割れたまま放置されていると、やがて他の窓も割られ、建物全体が荒廃していく」という考え方で、小さな問題を放置すると大きな問題に発展するという教訓を示しています。

これをTerraformの運用に当てはめると、Drift（実際のインフラとTerraformコードの差分）はまさに「割れ窓」の代表例です。1つのDriftを放置すると「まぁいいか」という空気が生まれ、気づけばDriftだらけの管理不能な状態に陥りかねません。

だからこそ、Driftは発生したら早めに対処する。これがIaCを健全に保つコツだと考えています。
SRE目線で言い換えると、『小さな運用負債を放置しない』ためのマインドセットです。

## Saved Viewsをこう使っています

では具体的にTerraformの割れ窓対応をチームでどのようにやっているかを紹介します。
毎朝のSRE朝会では、以下の2つのSaved Viewを開き、前日からの変化を確認して対応方針を決めています。

- Driftが発生しているワークスペースの一覧
- Run Statusが正常ではないワークスペースの一覧

もしかすると「それはUse casesにすでに用意されている一覧では？」と気づかれた方がいるかもしれませんが、その通りです。HCPtには、そのようなプリセットの一覧があらかじめ用意されています。

- Drifted workspaces（差分が発生しているワークスペースの一覧）
- Workspaces by run status（Run状態別のワークスペース一覧）

Saved Viewsではこれらの一覧をより自分たちが見やすい形にカスタマイズしたものを保存しておくことがメリットとなります。

### メリット1：直感的な日本語名を付与できる

日本人が多い組織であれば、日本語名を利用できるのは大きなメリットです。
「Drifted workspaces」と記載するより「Drifted（ドリフトしているワークスペースです）」のように記載したほうが直感的でわかりやすいものになります。

![japanese_name](/images/morihaya-20251201-terraform-fix-drifts/2025-12-01-22-36-35.png)

### メリット2：表示する列の変更

一覧には多くの列が存在しますが、Saved Viewsでは表示する列をカスタマイズした状態で保存できます。
たとえばドリフトが発生しているWorkspaceの一覧の場合、プリセットの「Drifted workspaces」の表示列と比べると以下のように異なります。

- Drifted workspaces（プリセット）
  - Name
  - Project name
  - Drifted
  - Resources drifted
  - Resources undrifted
  - Created
  - Updated
- カスタマイズした私たちのView
  - Name
  - Project name
  - Run status
  - Drifted
  - Resources drifted

![display_columns_presets](/images/morihaya-20251201-terraform-fix-drifts/2025-12-01-22-44-26.png)

![display_columns_saved](/images/morihaya-20251201-terraform-fix-drifts/2025-12-01-22-47-01.png)

何を見たいかはチームや人によって異なるため正解はありませんが「terraform applyに失敗した結果ドリフトが発生している」ようなケースは少なくないため「Run status」を追加するのはオススメです。

また削った以下の列については、あってもさほど情報としての価値がないと判断しています。

- Resources undrifted（母数として参考になるが、結局知りたいのはDriftの数だけ）
- Created（いつ作られたかはさほど重要ではない）
- Updated（同上）


### メリット3：表示条件の変更

Terraformの運用において、Drift以外にも早期で対応しなければいけないのは「terraform apply」が実行できない状況を放置することです。放置してしまえばリソースの追加・更新・削除など次の作業を行えなくなってしまいます。

この状態が発生する契機はさまざまで「Providerの破壊的なバージョンアップ」「data参照しているリソースの停止・削除」「Terraformコードはマージ済みだが、差分が想定外だった」などがあります。

そのためプリセットの「Workspaces by run status」をベースとしつつ、Conditionsへ以下のような条件を追加することで「正常ではない」ワークスペースの一覧を表示しています。

- `Run status does not contain applied`
- `Run status does not contain planned_and_finished`
- `Run status does not contain assessed`

さらに検証用環境のエラーは気にする必要がないとの判断からワークスペース名に”sandbox”を含むものも表示対象から除外しています。

- `Project name does not contain sandbox`

![savedview_run_status](/images/morihaya-20251201-terraform-fix-drifts/2025-12-01-23-05-00.png)

このViewのおかげで「あれ？このワークスペースDiscardのままですけど、明後日のリリース作業で使うのですが大丈夫でしたっけ？」「すいません、一時的なやつなので今日中にFixされます」といった会話がチーム内で交わされることになり情報共有のきっかけとしても有効的に利用しています。

## おわりに

以上が「毎日のSRE朝会でTerraformの割れ窓対応を加速するHCP Terraform Explorer機能」です。
プリセットの一覧をカスタマイズしてSaved Viewsとして保存しておくと、よりHCPtの活用がはかどるのではないでしょうか。

なお今回紹介したHCPtについては、11/26にFindy Toolsさんに紹介記事「[イオンの大規模環境を支えるHCP Terraform](https://findy-tools.io/products/hcp-terraform/335/771)」を寄稿しております。本記事ではExplorerとSaved Viewsに絞りましたが、Findy Toolsさんの記事ではHCP Terraform全体の導入経緯や運用の工夫も紹介しています。

それではみなさま、Enjoy HCP Terraform Explorer ＆ Saved Views!

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味を持った方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recruiting.aeon.info/)
