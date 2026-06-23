---
title: "GitHub CodespacesはEnterprise環境でのレビューや短期支援時に刺さるのでは"
emoji: "🚀"
type: "tech"
topics:
  - "github"
  - "codespaces"
  - "devcontainer"
  - "aeon"
published: true
published_at: "2026-06-24 08:00"
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://x.com/morihaya55)です。

当社はGitHub Enterprise Cloud with Enterprise Managed Users（以降はGitHub EMU）を利用しており、SREチームとしてGitHubのEnterprise/Organization/Team/Repository、GitHub Copilot、GitHub Advanced Securityなど、GitHubまわりの幅広い領域を管理しています。

本記事ではGitHubのWeb上で開発環境が立ち上げられる[GitHub Codespaces](https://docs.github.com/ja/codespaces/about-codespaces/what-are-codespaces)が、当社のようなEnterprise環境においてもかなり魅力的なサービスだと感じているためブログします。

ポイントは「毎日のメイン開発環境をすべてGitHub Codespacesに置き換える」ではなく、「レビューや短期的な支援の場面でピンポイントに使う」と強い道具である点です。

そしてこの場合のレビューは単にコードレビューだけでなく、起動したCodespacesの環境内で実行しWeb画面を確認するといったことも可能です。

## TL;DR

- 関わる領域が広いEnterpriseでは、GitHub Codespacesの「すぐ同じ環境に入れる」魅力が大きい
- 常用の開発環境というより、レビューや短期的な支援の場面に刺さる
- Dev Container（開発コンテナ）文化の展開に寄与する
- GitHub CopilotやGHASのような継続的なライセンスコストと比べると、短時間利用のCodespacesは安価（当社比）

## GitHub Codespacesとは

以下の公式ドキュメントからざっくり概要を引用します。

https://docs.github.com/ja/codespaces/about-codespaces/what-are-codespaces

> GitHub Codespaces は、クラウドでホストされている開発環境です。

また、作成される環境については以下のように説明されています。

> 作成する各 codespace は、仮想マシン上で実行されている Docker コンテナー内の GitHub によってホストされます。

つまり、GitHub上のリポジトリから、そのままクラウド上の開発環境を起動できる機能です。
ローカルPCにランタイムやSDK、CLI、拡張機能を一式そろえなくても、リポジトリに定義された開発環境へ入れます。

つまり「開発環境セットアップ手順書」にしたがって`brew`とか`uv`とか`npx`とかを実行することなく、開発環境が使えるようになります。

接続方法も柔軟です。
公式ドキュメントでは、codespaceへの接続に以下を使えると紹介されています。

> codespace への接続には、ブラウザー、Visual Studio Code、または GitHub CLI を使うことができます。

ブラウザだけでも動き、普段のVS Codeからも接続でき、GitHub CLIからも扱える。
この「GitHubの中に開発環境がある」感覚がCodespacesのわかりやすい魅力です。以下に公式ドキュメントから図を引用します。

![codespaces-diagram](https://docs.github.com/assets/cb-68851/mw-1440/images/help/codespaces/codespaces-diagram.webp)

## EnterpriseでCodespacesが刺さる場面

個人開発やOSSでは「ローカル環境を汚さずにすぐ試せる」がCodespacesの代表的な価値だと思います。
一方で、当社のように扱うサービスが多く、部門も多いEnterprise環境では少し違う魅力があります。

Enterprise環境では、関わるリポジトリや技術領域が広くなりがちです。
私たちSREチームでも、アプリケーション開発、IaC（クラウドインフラ）、CI/CD、セキュリティ、オブザーバビリティ＆監視、GitHub設定など、横断的に関わる場面があります。

このとき、毎回すべてのリポジトリをローカルにcloneし、依存関係を入れ、言語バージョンを合わせ、READMEを読んだ上で動かすところまで持っていくのはなかなか大変です。

そのような状況でDev ContainerおよびCodespacesがあると、初動が大幅に軽くなります。

| 場面 | Codespacesで嬉しいこと |
| --- | --- |
| Pull Requestレビュー | 対象ブランチをそのまま動かして確認できる |
| 短期的なトラブル支援 | 手元に環境を作り込まず、必要な期間だけ入れる |
| 他チームのリポジトリ確認 | 言語やツールチェーンの差分を吸収しやすい |
| 新メンバーのオンボーディング | まず動く環境に到達しやすい |
| セキュリティ・CI/CD調査 | ローカル環境に依存しない再現環境を作りやすい |

## 常用環境というより、レビューや短期支援の道具として考える

そんな便利なCodespacesですが、常用の開発環境として使うかは要検討です。

### 使い勝手はやっぱりローカルPCでしょ

Codespacesにはブラウザだけで開発できる、端末を選ばない、スペックの弱い端末でもクラウド側の計算資源を使える、ローカルPCからも使えるなどのメリットは大きいです。
では常用しない理由はというと、シンプルに使い勝手とコストでしょう。

日常的に深く触るリポジトリは、ローカル環境を整えて個人最適化することも、技術者の遊び心を感じる醍醐味です。
お気に入りのターミナル、IDE、スクリプト、AIツールはローカルPCでこそ使い込めるというものです。

### 常用するとなればコストがかかるし、手元のハイスペックPCの意義は？

コストについても、昨今のToken従量課金化されたGitHub CopilotやGHASと比べれば当社比で安価に見える状況ですが、常時利用すると当然跳ね上がっていきます。当社はありがたいことに開発PCには一定以上のスペックを備えたものを提供してくれるため、その手元の性能を使わずにCodespacesにコストをかけるのは健全ではありません。

### しかし短期利用なら効果は抜群だ

一方で、レビューや短期支援は話が違います。

- そのリポジトリを触るのは今日だけかもしれない（低頻度である）
- ローカルに依存関係を入れたくない
- 動作確認だけできれば十分
- PRの文脈でブランチをすぐ開きたい
- 支援が終わったら環境ごと消えてくれてよい

このような場面では、Codespacesの「必要なときだけ起動し、終わったら止める・消す」性質が刺さります。

## コスト面でも短時間利用ならかなり現実的

あらためてコストについて言及すると、Codespacesは従量課金です。
[GitHub Codespacesの課金](https://docs.github.com/ja/billing/concepts/product-billing/github-codespaces)では、料金が発生する要素として以下の2種類が説明されています。

> コンピューティング時間: codespace がアクティブな間の処理時間と電力消費。
>
> ストレージ: codespace またはプレビルドが存在している間に占有するディスク領域。

執筆時点では、たとえば2コアのCodespacesコンピューティングは1時間あたり$0.18、4コアは1時間あたり$0.36です。
ストレージは1GB/月あたり$0.07です。

レビュー、短期支援、オンボーディング期間などに当てはめると、かなり使いやすいコスト感になります。

たとえば4コアのCodespacesを1時間使ってPRレビューや調査をするなら、コンピューティング費用は$0.36です。
もちろんストレージやプレビルド、利用人数が増えた場合の管理は必要ですが、少なくとも「短時間だけ開発環境を借りる」用途では非常に小さく始められます。

加えてCodespacesは、一定時間未使用の場合に自動でマシンを停止する機能があり、「放置していた結果、不必要な数十時間のコンピューティング費用を払う」といった状況も起きません。（ストレージ料金は削除まで継続しますが、大変安価です）

## 安全策としてコストキャップはかけておく

便利ではありますが、大規模環境で「便利だから全開放」で終わり、とするのはやめましょう。
他のGitHubサービス同様に、Codespacesの使用コストに対するバジェットとアラートを設定できます。

当社の場合は大きめのバッファを取った上で、予算超過時は利用を停止する設定としています。

![budgetsandalerts](/images/morihaya-20260624-github-codespaces/2026-06-24-03-26-14.png)

## Dev Containerを整えると効果がさらに出る

簡単にWeb側に開発環境を構築できるCodespacesの価値は、リポジトリ側に開発環境の定義があればより高まります。

公式ドキュメントでも、構成ファイルをリポジトリにコミットすることで、プロジェクトの全ユーザーに対して繰り返し可能なCodespaces構成を作れると説明されています。

つまり、`.devcontainer/devcontainer.json` を整えておくと、「このリポジトリはCodespacesで開けばだいたい動く」状態に近づきます。

これはCodespacesだけのためではありません。
開発環境の前提がコード化されることで、オンボーディング、CI/CD、ローカル開発、レビュー支援にも効いてきます。

全リポジトリにDev Containerを用意する必要はないと考えていますが、以下のような、レビューや調査で多くの人が触る機会が多いリポジトリには今後も導入していきたいです。

- 依存関係のインストールが重い
- セットアップ手順が長い
- 複数言語や複数ツールを使う
- 新メンバーや他チームが触ることが多い
- PRレビューで動作確認したい場面が多い

Codespacesをきっかけに「このリポジトリの開発環境は再現可能か？」を考えるのは、かなり良い改善テーマではないでしょうか。

### 重いCodespacesの起動を高速化できるPrebuilds

詳細はドキュメントに任せますが、大規模で複雑なリポジトリのCodespaces起動を早くする方法として「Prebuilds」という方法があります。

https://docs.github.com/ja/codespaces/prebuilding-your-codespaces/about-github-codespaces-prebuilds

当社のとあるリポジトリでも通常は15minほどの起動時間がかかるところを、このPrebuildsによって1min程度に大幅短縮した実績があるため、起動時間に課題を感じた場合はオススメしたいです。

## まずはレビュー用途から始めるのが良さそう

これは社内に向けてもですが、Codespacesをこれから試すなら、まずレビュー用途がおすすめです。

日常のメイン開発環境を移行しようとすると、IDE、各種認証、ローカルツール、パフォーマンス、コストなど、考えることが一気に増えますが、レビュー用途なら期待値を絞れます。

- PRのブランチを開ける
- テストやビルドを軽く実行できる
- 画面やAPIの動作を確認できる
- レビューが終わったら停止・削除できる

これくらいの用途であれば、Codespacesの価値を体感しやすく、導入時の議論もしやすいです。

「全員の開発環境を変える」ではなく、「レビューと短期支援の初動を速くする」と捉える。
この見方が、Enterprise環境でCodespacesを活用する第一歩だと考えています。

## データレジデンシー（データ所在地）の日本リージョン対応

また比較的最近の2026-01-29に発表されたCodespacesのデータレジデンシーは、3月時点で日本リージョンに対応し、４月にGAしています。
これも日本のEnterprise環境での利用を見据えた改善と見ることもできるかもしれません。

https://github.blog/changelog/2026-01-29-codespaces-is-now-in-public-preview-for-github-enterprise-with-data-residency/

https://github.blog/changelog/2026-03-19-codespaces-with-data-residency-now-available-in-japan/

https://github.blog/changelog/2026-04-01-codespaces-is-now-generally-available-for-github-enterprise-with-data-residency/

## おわりに

以上が「GitHub CodespacesはEnterprise環境でのレビューや短期支援時に刺さるのでは」でした。

GitHub Codespacesは、単なるクラウド開発環境ではなく、Enterprise環境における横断支援、レビュー、オンボーディング、環境再現性の課題に効く道具だと感じています。

常用の開発環境として使うかはチームや個人の方針や好みがあるでしょうが、レビューや短期的な支援のためにピンポイントで使うなら、コスト面でも運用面でもかなり現実的かつ効果的です。

加えてGitHub CopilotやGHASのような大きな投資と比べると、Codespacesは小さく始めて効果を確認しやすい領域です。
Enterprise環境でGitHubを広く使っているみなさまは、まずはPRレビュー用の一時環境として試してみると良いのではないでしょうか。

それではみなさま、Enjoy GitHub Codespaces！

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味を持った方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recruiting.aeon.info/)
