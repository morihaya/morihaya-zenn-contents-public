---
title: "GitHub Copilot CLIへAbout GitHub Copilot CLIを読みながら入門する"
emoji: "⌨️"
type: "tech"
topics:
  - "githubcopilot"
  - "cli"
  - "aeon"
published: false
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。

ついにGitHub Copilot CLIが2026/02/25に[GA](https://github.blog/changelog/2026-02-25-github-copilot-cli-is-now-generally-available/)しました。
私はプレビューの段階で少し触りましたが、なんやかんやVSCodeでGitHub Copilotを使うことが大半でした。

本記事ではGAを機に本格的にGitHub Copilot CLIを触っていこうと考え、この記事を書きながら入門してみます。
＊そのため、しっかりと検証したものではなく、想定と感想を多分に含んだ内容です。

参照するのは公式の「About GitHub Copilot CLI」です。
https://docs.github.com/en/copilot/concepts/agents/copilot-cli/about-copilot-cli

他にも「[Using GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli)」や「[Best practices for GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/cli-best-practices)」も読むと良さそうですが、今回は「About GitHub Copilot CLI」のみを参照します。

## TL;DR

- GitHub Copilot CLIにはプログラマティック（`copilot -p`）とインタラクティブ（`copilot`）の2つのインタフェースがあり、用途に応じて使い分けられる
- Custom instructions、MCP、カスタムエージェントなどVSCodeでおなじみのカスタマイズ機能がCLIでも利用でき、シェル芸との掛け算でAgenticなワークフローの可能性が広がる
- モデル選択やEffort Levelの設定が可能で、ACP（Agent Client Protocol）によるサードパーティ連携など今後の発展にも期待できる
- やはり「About GitHub Copilot CLI」だけでは足りないため、他のドキュメントも読むべきだが、概要の理解としては役立った


## 初期セットアップはさらっと終わる

私の環境は以下です。

- Apple M3 Pro
- macOS 15.7.1 (24G231)
- GitHub Copilot CLI 0.0.420.
- GitHub Copilot Enterprise （サンキューAST!）

そのため以下の`brew`コマンドでインストールはシュッと終わりました。

```sh
brew install copilot-cli
```

認証方法はいくつかありますがTokenなどは極力払い出したくないためOAuth認証を以下で実施しました。

```sh
copilot login
```

## 2つのインタフェースを理解する

GitHub Copilot CLIには2つのインタフェースが用意されています。

### プログラマティック インタフェース

ドキュメントの順番と前後しますが、わかりやすかったので先にプログラマティックの方を触りました。
CLIでアドホックにCopilotへリクエストできる機能です。
`-p` or `--prompt` を使用し問い合わせを実行できます。

```sh
$ copilot -p "お前は何ができる？"
● fetch_copilot_cli_documentation
  └ # GitHub Copilot CLI Documentation

私（GitHub Copilot CLI）にできることを日本語でまとめます：
...（以下略）...
```

オプションとして `--allow-all-tools`, `--allow-all`, `--yolo` を追加して実行時の承認を自動化できます。便利そうですが怖くもありますね。

ちょっとしたシェル芸の途中で `copilot` コマンドを使ったAgenticなワークフローが思い浮かびました。

### インタラクティブ インタフェース

単に `copilot` と実行して起動したTUIの中で操作するのがインタラクティブ インタフェースです。
以下の3つのモードが用意されており、適宜使い分けることが推奨されています。

1. ask/execute モード（デフォルト）
2. plan モード
3. autopilot モード

名前から機能が大体わかるためとくに補足はしませんが、autopilotモードは今（2026/03/02時点)でAbout...のドキュメントには記載されていませんでした。チラ見したUsing...の方に記載があります。

モードの切り替えは `shift` + `tab` で行え、autopilotモードになると権限承認の警告が出ます。

## ユースケース

ドキュメントにはCopilot CLIのユースケースが豊富に紹介されています。
VSCode + GitHub Copilotでやっていることも多くありましたが、[Tasks involving GitHub.com](https://docs.github.com/en/copilot/concepts/agents/copilot-cli/about-copilot-cli#tasks-involving-githubcom)でGitHubまわりの例が手厚く紹介されているのは学びになりました。

`Merge all of the open PRs that I've created in octo-org/octo-repo` はちょっとパンチが効きすぎている感もあります。

## 会話操作

- 処理の実行中でも追加で指示を送ることができて、より自然な会話になります
- toolの認証許可を拒否した際に、インラインでCopilotへフィードバックでき行動を限定できます

## 自動のコンテキストマネジメント

- トークンが95%以上になった際に、自動でコンテキストを圧縮してくれます
- `/compact` で手動でコンテキストを圧縮できます
- `/context` でコンテキストの使用状況を分解して可視化します

## GitHub Copilot CLIのカスタマイズ

VSCodeでの利用でも見慣れた手法が紹介されています。GitHub Copilot CLI”でも”できるって感じですが、細かな動作に違いがあるかは今後触りながら試すことになります。

- Custom instructions
- MCP
- Custom agents
- Hooks
- Skills
- Copilot memory

## セキュリティ

GitHub Copilot CLI利用におけるセキュリティの注意事項が紹介されています。

- 提案されたコマンドはちゃんとレビューしろ
- copilot cliを起動するディレクトリは厳選しろ
- copilot cliが実行できる tool は限定しろ、いろいろオプションがあるぞ

## モデルの選択

`/model` でモデル選択が可能です。デフォルトは現状(2026/03/02)Claude Sonnet 4.6です。
ドキュメントは4.5を指してますが実態に追いついてないですね...

私は基本的にはClaude Opus 4.6を利用します。

なおEffort Levelといって、スピードか信頼性かのバランスを選ぶ3択が用意されていました。（これもドキュメントにはなさそう...)

```sh
Select Effort Level for Claude Opus 4.6

  1. Low               Minimal thinking, prioritizes speed
  2. Medium            Balanced, thinks on harder problems
❯ 3. High (default)    Optimal performance, thorough thinking
```

私は大体のケースで正しいほうが多少遅いよりは嬉しいためHighを選びますが、どの程度の違いが発生するかは触りながら試すしかありませんね。

## ACP (the Agent Client Protocol) でCopilot CLIを使う

最後にちょろっと[紹介](https://docs.github.com/en/copilot/reference/acp-server)されていたのが「ACPでCopilot CLIを利用できる」ことです。
サードパーティツールやIDEなどからCopilot CLIをエージェントとして利用できるプロトコルだそうで、自分は知りませんでしたが今後に期待ですね。

## 付録：気になったプログラマティック実行時のオプション

案外サクッと「About GitHub Copilot CLI」を読めてしまったため、参考として

```sh
copilot --help
```

で表示された、上記のドキュメントで紹介されていなかったが使いそうor印象的なコマンドオプションをピックアップしました。

- `--add-dir <directory>`: Add a directory to the allowed list for file access (can be
 used multiple times)
  - カレントディレクトリ以外も参照させられて、リポジトリが分かれている時に便利に見えます
- `--agent <agent>`: Specify a custom agent to use
  - agentを指定して起動する需要は必ずあるでしょう
- `--bash-env [value]`: Enable BASH_ENV support for bash shells (on|off)
  - プログラマティックに環境変数を使うシェル芸と相性が良さそうです
- `-s, --silent`: Output only the agent response (no stats), useful for scripting with `-p`
  - 出た！サイレントモード！シェルにはこの手のオプションがやっぱ必要ですよね〜と嬉しいやつです

他のコマンドオプションも眺めながら、従来のシェル芸とCopilot CLIの掛け算で広がるAgenticなジョブやワークフローの可能性をひしひしと感じて楽しくなってきました。

## おわりに

以上がドキュメント[About GitHub Copilot CLI](https://docs.github.com/en/copilot/concepts/agents/copilot-cli/about-copilot-cli)を読みながらメモした内容です。

ブログとして書きながら読むことで、よりしっかりと頭に入ってきたと手応えを感じる一方で、インタラクティブインタフェースでの細かい操作やMCPのセットアップ方法などが紹介されておらず物足りないと感じました...

引き続き「[Using GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli)」や「[Best practices for GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/cli-best-practices)」も参照しながら使いこなしていく必要性を感じています。

なお記事を大体書き終わった後で発見した以下は、日本マイクロソフトの真壁さんの資料「GitHub Copilot CLI 現状確認会議」です。
1ヶ月ほど前の情報ですが主要機能をそつなくまとめてあり素晴らしい資料でした。現時点ではAbout...を読むよりこちらの方が個人的にはオススメです。

@[speakerdeck](46ac98b8c569402ea641e1ba1034835a)

それではみなさま、Enjoy GitHub Copilot CLI！

---

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味を持った方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![イオングループエンジニア採用バナー](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recruiting.aeon.info/)
