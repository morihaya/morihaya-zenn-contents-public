---
title: "GitHub Copilot CLIの/chronicleで課金体系の変更に備えよう"
emoji: "📜"
type: "tech" # tech: 技術記事 / idea: アイデア
topics:
  - "github"
  - "githubcopilot"
  - "githubcopilotcli"
  - "aeon"
published: true
published_at: "2026-05-27 08:00"
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。

先日5/25にFindyさん主催のイベント「GitHub Copilot CLI を装備せよ 〜実践テクニック共有会 LT Night〜」に参加してきました。

https://findy.connpass.com/event/391200/

イベント名の通りGitHub Copilot CLIに関して総勢10本のLTが行われ（私も1本を受け持たせてもらいつつ）面白さとナレッジの溢れた良い場になっていました。
そんな中でも10本のLTのうち4本かそれ以上で取り上げられていたのが `/chronicle` コマンドです。

`/chronicle`は「Copilot CLIのセッション履歴を分析してインサイトを出してくれる」コマンドです。
一見地味かもしれませんが、朝会向けのメモを提示し、過去のプロンプトへ改善提案をし、さらには `.github/copilot-instructions.md` の改善案まで提案してくれる優れもので、2026年6月からのリクエスト数から消費トークン課金へ移行することも鑑みて非常に有用なものだと言えるでしょう。

よって本記事ではLTで思わず取り上げたくなるホットなコマンド `/chronicle` について公式ドキュメントの「Using GitHub Copilot CLI session data（コンセプトやユースケースの紹介）」と「About GitHub Copilot CLI session data（細かな利用方法の紹介）」をベースに、`/chronicle` の概要、サブコマンド、そして活用イメージを整理します。

https://docs.github.com/en/copilot/concepts/agents/copilot-cli/chronicle
https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/chronicle

なお本記事はGitHub Copilot CLI [v1.0.55-1](https://github.com/github/copilot-cli/releases/tag/v1.0.55-1) 2026-05-27リリース時点の情報をベースとしています。

## TL;DR

- `/chronicle` はGitHub Copilot CLIのセッション履歴を分析して、作業レポートや改善提案を生成する
- 主なサブコマンドは `/chronicle standup`, `/chronicle tips`, `/chronicle cost-tips`, `/chronicle improve`
- どれも便利だが2026/6からの課金体系変更に向けて `cost-tips` で指示方法を洗練させよう

## /chronicle とは

`/chronicle` はGitHub Copilot CLIのコマンドのひとつです。
ローカルマシンに保存されているCLIセッション履歴を分析し、作業内容の要約、パーソナライズされたTips、カスタムインストラクションの改善案などを生成します。

なお現時点で実験的な機能なようで、利用のためには`/experimental on` または `--experimental` での起動が必要です。

## セッションデータはどこに保存されるのか

GitHub Copilot CLIは、インタラクティブセッションの履歴をローカルマシンに保存します。公式ドキュメントでは、主に以下の2種類が説明されています。

| データ | 役割 |
|---|---|
| `~/.copilot/session-state/` 配下のセッションファイル | 各セッションの完全な履歴を保持し、`copilot --resume` などでの再開に使われる |
| `~/.copilot/session-store.db` | セッション履歴の一部を構造化したSQLiteベースのセッションストア。`/chronicle` や自然言語での履歴質問に使われる |

注意事項として、ローカルに保存される点は安心材料ですが、セッション履歴について質問したり `/chronicle` を実行したりする際は通常のCopilot CLI利用と同じくAIモデルへ送信されることを認識しておきましょうと記載があります。

セッションデータは手動で削除可能ですが、その場合は後述するサブコマンド `reindex` の実行が”必須”となります。

## サブコマンド一覧

`/chronicle` には現在以下のサブコマンドがあります。`/chronicle` 単体で実行した場合はサブコマンドの一覧が表示されカーソルキーで選択するモードとなります。

| サブコマンド | 概要 |
| --- | --- |
| `/chronicle standup` | 前日のセッションをもとに作業レポートを生成 |
| `/chronicle search`  | すべてのセッションをキーワードかトピックで検索し一覧を表示 |
| `/chronicle tips` | 実際の使用パターンを分析し、3〜5件のパーソナライズされた改善案を提示 |
| `/chronicle cost-tips` | `tips`同様に分析を行い、利用トークンを削減する改善案を提示 |
| `/chronicle improve` | セッション履歴から摩擦パターンを特定し、`.github/copilot-instructions.md` の改善案を提案・適用 |
| `/chronicle reindex` | ローカルのセッションファイルからセッションストアを再構築（セッション手動削除時は実行必須） |

順番に見ていきましょう。

## /chronicle standup

「前日に何をGitHub Copilot CLIで行ったか」をまとめてくれるコマンドです。

24時間のセッションを対象に、どのブランチで何をしたか、何が完了して何が進行中か、関連するPull Requestがあるか、といった情報をまとめます。

```sh
/chronicle standup
```

まさに朝会（スタンドアップ）の前に実行すれば、「昨日何やったっけ...？」を思い出す時間を減らせるかもしれません。
しかしCopilot CLIに閉じた情報にとどまるため、チャットやチケットやドキュメントやメールや会議など多様なタスクをこなしている現状からは部分的な情報との印象もあります。

またドキュメントでは以下のように期間指定も可能とありますが、7days ago などを指定しても効いていないような印象でした...（現時点のN=1の情報）

```sh
/chronicle standup for the last 3 days
```

## /chronicle search

過去のセッション履歴をキーワード検索で抜粋できるコマンドです。

```sh
/chronicle search <任意の文字列>
```

`/resume`などで過去のセッションを再開したい場合に、IDを調べるために活用できるでしょう。

## /chronicle tips

自分の実際の使用パターンをもとに、パーソナライズされた改善提案を数件提示してくれます。

```sh
/chronicle tips
```

以下のようにTipsを特定の範囲に絞って行うことも可能です。

```sh
/chronicle tips for better prompting
```

公式ドキュメントの例では、以下のような観点が挙げられています。

- ファイル内容を貼り付ける代わりに `@` でファイルを指定する
- 毎回新しいセッションを始めず、同じセッション内で反復する
- 調査作業には `/research` を試す
- 繰り返し使うプロンプトをカスタムエージェント化する
- 複数ステップの作業にはplanモードを使う

回答が赤裸々すぎるため実回答の内容を記事には書きませんが、私のケースでは例の「`@`でファイル指定」「`/research`利用」の他に、「似たような作業をやってるが、それ用のスキルがあるから、ちゃんとスキル名を指定して実行しろ」といった指摘を受けました。

適切な指摘に背筋が伸びると共に、すぐに使えるナレッジを獲得できて大変良い機能だと感嘆しました。

## /chronicle cost-tips

上記で紹介した`tips`のコスト特化のものです。興味深いことに記事執筆時点ではドキュメントに記載がないため、6月からの課金体系移行に向けた実験的なサブコマンドだと想像できます。

```sh
/chronicle cost-tips
```

実行したところ以下のような指摘をもらえ、”コスト＝Token使用量”削減のための参考情報を得ることができました。

- 同じセッションで何回も”コード規約”のSkillを読み込むな、以降はすでに読み込んだ規約に従え」と伝えよ
- 大きなテキストは`@`で渡せ
- 大きなテキストを渡した後は`/compact`をやれ
- 長期タスクは`/new` で分割しろ
- 繰り返す指示はプロンプトじゃなく既存スキルを最初から指定しろ

こちらも`tips`の回答同様に読んでいてなるほどとなるものばかりです。学びがありますね。

## /chronicle improve

過去のやり取りを元にインストラクションファイル`.github/copilot-instructions.md`の修正提案を行ってくれます。

```text
/chronicle improve
```

具体的には、以下のようなシグナルを探します。

- 繰り返し発生したビルドエラー
- 何度も失敗したテスト
- ユーザが何度も同じ方向に軌道修正した会話

公式ドキュメントでは「Copilot CLIが`jest` を使おうと毎回するが、実際は `vitest` を使うプロジェクトだと人間が修正指示を出している」というケースが例として挙げられています。
毎回「このプロジェクトは `vitest` です。`jest` ではありません」と指摘しているなら、それは人間が毎回言うべきことではなく、カスタムインストラクションとして常に渡すべき知識です。

実際に使用した感想としては、直近のイレギュラーな障害対応などの情報を強く拾ってしまい、平時の運用に向けてはあまり有効ではない提案が行われました。
そのため`improve`でお伺いを立てるのは、一定以上落ち着いているタイミングが良いのかもしれません。（またはプロンプトで非常時の情報を除外していくなどができるかも？）

## /chronicle reindex

セッションストアのインデックスを再構築するコマンドです。

```text
/chronicle reindex
```

通常は頻繁に使うものではありませんが、公式ドキュメントでは以下のようなケースで有用とされています。

- セッションストアが存在する前の古いセッションファイルをインデックスしたい
- 特定のセッションディレクトリを削除した後、セッションストアも更新したい
- 別マシンからセッションファイルを移行した
- `~/.copilot/session-store.db` が壊れた、または消えてしまった
- クラッシュや電源断などでセッション終了時の書き込みが完了しなかった

`/chronicle` の結果が明らかにおかしい場合や、セッションデータを整理した後に思い出すコマンド、くらいの位置づけで良さそうです。

## 課金体系の変更に備えるために

あらためて、いよいよ2026年6月にGitHub Copilotの課金体系の変更が迫ってきました。本記事から数日後です。

https://github.blog/news-insights/company-news/github-copilot-is-moving-to-usage-based-billing/

GitHub Copilotへのリクエスト回数にしか意識を向けずに済んだ牧歌的な時代は終わり、今後は適切な情報量を適切に渡して行くことがコストに直結します。

GitHub CopilotユーザかつGitHub管理者でもある私たちSREチームは、定期的に組織のCopilot利用状況を俯瞰し`/chronicle cost-tips`等による改善を促して行く必要があるでしょう。

また現時点では実装されていないようですが、GitHub CopilotにはVSCodeやCloud agentなど複数の利用方法が存在するため、それらを横断的にChronicleできる機能も期待したいです。（その場合は横断的なセッション履歴をどう参照させるかが悩ましそうですが）

## おわりに

以上が「GitHub Copilot CLIの/chronicleで課金体系の変更に備えよう」の内容でした。

コマンド`/chronicle` はまだ実験的機能の扱いですが、その方向性は非常に魅力的で現時点でも実用的です。

これまでのGitHub Copilot活用は、「いま目の前のタスクをどう助けてもらうか」が中心でした。一方で `/chronicle` は、「過去の自分の使い方を分析し、次の自分の使い方を良くする」ための機能です。

GitHub Copilotに手伝ってもらった作業履歴そのものが、次のCopilotを賢くする材料になる。これはなかなかワクワクする世界です。

加えて`/chronicle tips`, `/chronicle improve`による提案・指摘の内容は、私たちに直接改善と成長を促す良いインプットとなる手応えもありました。
今後のAI時代に心強い相棒になってくれそうです。

それではみなさま、Enjoy GitHub Copilot CLI & `/chronicle`！

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味を持った方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![イオングループエンジニア採用バナー](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recruiting.aeon.info/)
