---
title: "Dependabotがstack level too deepでエラーになった意外な理由"
emoji: "🔁"
type: "tech"
topics:
  - "github"
  - "terraform"
  - "dependabot"
  - "aeon"
published: false
publication_name: "aeonpeople"
---

## はじめに

こんにちは、あけおめことよろです。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。

本記事ではTerraform用の巨大リポジトリにDependabotを導入しようとしたところRubyのSystemStackErrorメッセージ `stack level too deep` エラーが発生し動作しなかった問題の調査の流れと原因特定から解決までを紹介する記事です。

## TL;DR

- 当社はGHAS導入をはじめリポジトリへのセキュリティ強化を推進しており、Dependabotの導入もそのひとつ
- 主にSREチームが管理する巨大なTerraformリポジトリにTerraform向け定義でdependabot.ymlを配置したが `stack level too deep` エラーが発生
- 原因は `main.tf` ファイル内のコメント部に記載された使用例（Usage）の`source =`の記述だった

## 背景

当社はセキュリティの向上のためGitHub Advanced Security(GHAS)を導入・展開しています。その一環でDependabot自体もちゃんと利用するよう見直す動きをしていました。

私たちSREチームが管理するリポジトリに対してdependabot.ymlの配置を進めており、もっとも巨大でよく使うTerraformのリポジトリでその問題が発生しました。

## ハマり1: directory: "/" 指定ではtfファイルを見つけてくれない

最初に遭遇したのは `Dependabot couldn't find any dependency files in the directory` のエラーです。

当初私はこのタスクがすぐに終わるものと予想していました。
いつものようにGitHub Copilotに対して「このリポジトリ向けのdependabot.ymlを作成してください。」とお願いすれば終わるものと考えていたのです。

そうして当初Copilotが生成したのは以下のdependabot.ymlでした。

```yml
# /.github/dependabot.yml
version: 2

updates:
  - package-ecosystem: "terraform" # Terraform provider updates
    directory: "/" # Location of Terraform configuration files
    schedule:
      interval: "weekly"
    registries:
      - terraform-cloud

  - package-ecosystem: "github-actions" # GitHub Actions workflow updates
    directory: "/" # Location of GitHub Actions workflows
    schedule:
      interval: "weekly"
```

この内容でマージするとさっそくGitHub Actionsに対してはcheckoutなどのバージョンアップの修正PRを作成してくれました。

一方Terraformはというと `Dependabot couldn't find any dependency files in the directory` エラーが発生しています。

![coldnt-find](/images/morihaya-20260109-dependabot-too-level-deep/2026-01-09-00-23-15.png)

Actionsの詳細なログを確認したところ以下のように記録されており、シンプルな `directory: "/"` ではDependabotがTerraformコードを見つけられないことがわかりました。

> ...省略...
> updater | 2026/01/08 15:12:12 ERROR <job_1203614876> Error during file fetching; aborting: No files found in /
>   proxy | 2026/01/08 15:12:12 [008] POST /update_jobs/1203614876/record_update_job_error
>   proxy | 2026/01/08 15:12:12 [008] 204 /update_jobs/1203614876/record_update_job_error
>   proxy | 2026/01/08 15:12:12 [010] PATCH /update_jobs/1203614876/mark_as_processed
>   proxy | 2026/01/08 15:12:13 [010] 204 /update_jobs/1203614876/mark_as_processed
> updater | 2026/01/08 15:12:13 INFO <job_1203614876> Finished job processing
> updater | 2026/01/08 15:12:13 INFO Results:
> Dependabot encountered '1' error(s) during execution, please check the logs for more details.
> +-----------------------------------------------------------------+
> |                             Errors                              |
> +---------------------------+-------------------------------------+
> | Type                      | Details                             |
> +---------------------------+-------------------------------------+
> | dependency_file_not_found | {                                   |
> |                           |   "message": "No files found in /", |
> |                           |   "file-path": null                 |
> |                           | }                                   |
> +---------------------------+-------------------------------------+
> Failure running container 0f57a792844e73e77d9cd2742d2504a9d08162e4687867db6f8afd604657fadc: Error: Command failed with exit code 1: /bin/sh -c $DEPENDABOT_HOME/dependabot-updater/bin/run update_files
> ...省略...


## ハマり2: directories: "/path/**/*" で stack level too deep 発生

次に試したのが `/path/**/*/` を利用した以下のような指定です。実はこれが正解のコードなのですがこの時はエラーとなりました。

```yml
# /.github/dependabot.yml
version: 2

updates:
  - package-ecosystem: "terraform" # Terraform provider updates
    directories:
      - "/modules/**/*"
      - "/systems/**/*"
    schedule:
      interval: "weekly"
    registries:
      - terraform-cloud

  - package-ecosystem: "github-actions" # GitHub Actions workflow updates
    directory: "/" # Location of GitHub Actions workflows
    schedule:
      interval: "weekly"
```

対象のTerraformリポジトリの構成を簡単に説明すると、以下のように深く広くなっておりディレクトリ数は3桁あります。それらのディレクトリを`directory`で個別指定するのは現実的ではありません。そのため `directories` と `**/*` の記載を利用したいと考えました。


```sh
# ディレクトリ構成の概要（かなりザックリ要約したもの）
.
├── modules
│   ├── common
│   │   └── <Azure Services>
│   ├── data
│   │   └── <Azure Subscriptions>
│   └── system
│       └── <Systems>
│           └── <Systems Azure Services>
└── systems
    └── <Products>
        └── <Environments>
            └── <etc>
```

`directories` は Dependabot の公式オプションとして複数ディレクトリ指定がサポートされています。

https://docs.github.com/en/code-security/dependabot/working-with-dependabot/dependabot-options-reference?learn=dependency_version_updates&learnProduct=code-security#directories-or-directory--


興味深いことに、このdependabot.ymlの記述 `directories: "/modules/**/*"` はGitHub Copilot Reviewから否定されていたものです。調査を難航させた一端でもあるため、そのやりとりを以下に紹介します。

![copilot-review-comment](/images/morihaya-20260109-dependabot-too-level-deep/2026-01-09-00-38-37.png)

- Copilot Review: 「Dependabotの設定で directories (複数形) は無効なフィールドです。GitHub Dependabotは directory (単数形) のみをサポートしています。」
- 私: 「 directoriesが使えることはドキュメントにちゃんと記載があるぞ
https://docs.github.com/en/code-security/dependabot/working-with-dependabot/dependabot-options-reference#directories-or-directory-- 」

結果としてCopilotは以下のように謝罪とともに`Change files 0`のPRとしクローズしてくださいと言ってきました。

![copilot-apologised](/images/morihaya-20260109-dependabot-too-level-deep/2026-01-09-00-42-30.png)

この時の私は率直に言って「Copilotくんもまだまだだねぇ」と調子に乗っていたと思います。
しかし意気揚々とこのdependabot.ymlを反映したところブログタイトルでもある `stack level too deep` が発生しました。

調べていくとDependency graphの概要画面では `Dependabot encountered an unknown error`とOracle DBで出る `ORA-600` のような具体性のない恐ろしいメッセージを表示しています。

> Dependabot encountered an unknown error
>  Dependabot failed to update your dependencies because an unexpected error occurred. See the logs for more details.

![unknown-error](/images/morihaya-20260109-dependabot-too-level-deep/2026-01-09-00-58-14.png)

詳細を調べるために"View logs"からActionsの実行ログを見たところ `stack level too deep (SystemStackError)` を確認しました。エラーを読んでいくと `... 9784 levels...` といった表示もあり、どうやらループした挙句にエラーになっているようだとわかりました。

![too-deep](/images/morihaya-20260109-dependabot-too-level-deep/2026-01-09-01-02-20.png)

> updater | /usr/local/lib/ruby/3.4.0/pathname.rb:128:in 'Kernel#initialize_dup': stack level too deep (SystemStackError)
> 	from /usr/local/lib/ruby/3.4.0/pathname.rb:128:in 'Pathname#initialize'
> 	from /usr/local/lib/ruby/3.4.0/pathname.rb:128:in 'Class#new'
> 	from /usr/local/lib/ruby/3.4.0/pathname.rb:128:in 'Pathname#cleanpath_aggressive'
> 	from /usr/local/lib/ruby/3.4.0/pathname.rb:98:in 'Pathname#cleanpath'
> 	from /home/dependabot/common/lib/dependabot/file_fetchers/base.rb:135:in 'Dependabot::FileFetchers::Base#directory'
> 	from /home/dependabot/dependabot-updater/vendor/ruby/3.4.0/gems/sorbet-runtime-0.6.12544/lib/types/private/methods/call_validation_2_7.rb:59:in 'UnboundMethod#bind_call'
> 	from /home/dependabot/dependabot-updater/vendor/ruby/3.4.0/gems/sorbet-runtime-0.6.12544/lib/types/private/methods/call_validation_2_7.rb:59:in 'block in Dependabot::FileFetchers::Base#create_validator_method_fast0'
> 	from /home/dependabot/common/lib/dependabot/file_fetchers/base.rb:232:in 'Dependabot::FileFetchers::Base#load_cloned_file_if_present'
> 	 ... 9784 levels...
> 	from /home/dependabot/dependabot-updater/vendor/ruby/3.4.0/gems/sorbet-runtime-0.6.12544/lib/types/private/methods/call_validation.rb:282:in 'UnboundMethod#bind_call'
> 	from /home/dependabot/dependabot-updater/vendor/ruby/3.4.0/gems/sorbet-runtime-0.6.12544/lib/types/private/methods/call_validation.rb:282:in 'T::Private::Methods::CallValidation.validate_call'
> 	from /home/dependabot/dependabot-updater/vendor/ruby/3.4.0/gems/sorbet-runtime-0.6.12544/lib/types/private/methods/_methods.rb:277:in 'block in Dependabot::BaseCommand#_on_method_added'
> 	from bin/update_files.rb:41:in '<main>'
> Failure running container 808965bf11c6e8f30833e550cb481f898bc08ee1a5f09f102594cabe45c16891: Error: Command failed with exit code 1: /bin/sh -c $DEPENDABOT_HOME/dependabot-updater/bin/run update_files

## ハマり3: directory: "/path" で個別指定しても `stack level too deep` が発生

この結果を受けて私は `directories` 指定が何らかのバグを持っていると誤解しました。

切り分けのためこのタイミングでリポジトリ自体をForkし、レビューなしで直接dependabot.ymlを更新できるようにしました。長期戦を覚悟した形です。

直前のCopilot Coding Reviewによる `directories` についての否定的なレビューコメントもあり、一定個数以上のディレクトリ数やネスト数などを条件に `**/*` だと問題が起きるのだろうと仮説を立てたのです。

そのためdependabot.ymlを以下のような指定にしました。

```yml
# /.github/dependabot.yml
version: 2

updates:
  - package-ecosystem: "terraform" # Terraform provider updates
    directory: "/some-terraform-path"
    schedule:
      interval: "weekly"
    registries:
      - terraform-cloud

  - package-ecosystem: "github-actions" # GitHub Actions workflow updates
    directory: "/" # Location of GitHub Actions workflows
    schedule:
      interval: "weekly"
```

サンプルの `directory: "/some-terraform-path"`は絶対パス指定でtfファイルが配置されたディレクトリを指定しています。
そのディレクトリに置かれていたのはたった3つのシンプルなtfファイルです。

```sh
total 56
-rw-r--r--@ 1 morihaya  staff   6.6K Jan  7 18:07 main.tf
-rw-r--r--@ 1 morihaya  staff   7.1K Jan  9 00:11 README.md
-rw-r--r--@ 1 morihaya  staff   4.9K Jan  7 17:20 variables.tf
-rw-r--r--@ 1 morihaya  staff   155B Jan  7 17:20 versions.tf
```

さすがにこれは通るだろうと考えましたが、同じように `stack level too deep` エラーが発生しました。
私は久しぶりに「うそだろ...」と思わず顔を覆いました。

## ハマり4: directoryの指定パスをいくつか変更しても改善せず

ここからは泥臭いため簡単に書きますが、3桁のディレクトリのうちからサンプリングした複数のディレクトリを `directory:` で指定しましたが同じエラーが続きました。

今考えると同じコード規約で同じように書かれたコード群に対して、サンプリングでの切り分けだけでは分が悪かったのでしょう。

## ハマり5: Copilotの提案で.terraform.lock.hcl ファイルを配置しても改善せず

自分の仮説と切り分けでは埒が明かなかったため、GitHub Copilot(Claude Opus 4.5)と壁打ちを始めました。

CopilotはまずAgentモードでシンボリックリンクによるループなどを検査してくれましたが問題はありませんでした。

次にCopilotが提案してきたのが `.terraform.lock.hcl` の配置です。

以下にCopilotの回答全文を載せますが、これは明確に間違っていますので注意してください。
現時点のDependabotの仕様では、`.terraform.lock.hcl` の有無と `stack level too deep` は無関係です。

> 問題が見つかりました。
>
> ## 原因
> .terraform.lock.hclファイルが存在しません。
>
> Dependabotは Terraform の依存関係を更新するために、.terraform.lock.hclファイルが必須です。このファイルがないと、Dependabotはディレクトリを再帰的に探索しようとして無限ループに陥り、stack level too deep (SystemStackError) エラーが発生します。
>
> ### なぜこのエラーが起きるのか
>
> Dependabotは指定されたディレクトリ（some-terraform-path）で依存関係ファイルを探します
> .terraform.lock.hclが見つからないため、親ディレクトリなどを再帰的に探索
> 探索が無限ループになり、スタックオーバーフローが発生
>
> ## 解決方法
> .terraform.lock.hclファイルを生成してコミットしてください

繰り返しますがこれは明確に間違っている、いわゆるハルシネーションな回答です。

しかし、これを読んだ私は「.terraform.lock.hclの発想はなかった！！」と小躍りしながら `.gitignore` から `.terraform.lock.hcl` を削除し、`terraform init` し、コミットしてプッシュしました。

結果変わらず `stack level too deep` エラーが発生しました。

## 原因判明: main.tfのコメント部分の source の記述が原因だった

`.terraform.lock.hcl` の配置でもだめだったとCopilotに返したところ、ついに正解を見つけてくれました。（といっても私が切り分けた directory指定を勧めてくるなど何度かやり取りを往復した上です）


その回答が以下になります。

> ## 問題の根本原因
>
> エラーログの filter_excluded: entries=4, exclude_paths=[] からわかることがあります。Dependabotは以下の流れで動作します：
>
> 1. リポジトリをクローン
> 2. 指定されたdirectoryでTerraformファイルを検索
> 3. moduleブロック内のsource参照を再帰的にたどる
>
> 問題は、main.tfのコメント内に書かれたサンプルコード：
>
> これがコメント内にあるにもかかわらず、Dependabotのパーサーがこれを実際のモジュール参照として解釈し、自分自身を参照するパスを無限に辿っている可能性があります。
>
> ## 解決策
>
> 方法1: コメント内のsource参照を削除/変更
> main.tf:11 のコメント部分で source = "../../../../modules/common/some-terraform-dir" を変更：
>
> *   source = "./path/to/some-terraform-dir"  # example path

私たちの `main.tf` には、Usageセクションとしてコメントで以下のような記載することが標準となっています。

```hcl
/*
 * # AzureRM Front Door Terraform module
 *
 * ---
 *
 * # Usage
 *
 * ```hcl
 * module "cdn_frontdoor_morihaya_test" {
 *   source = "../../../../modules/common/cdn_frontdoor"
 *
 *   resource_group_name        = module.common_platform.resource_group.name
 *   cdn_frontdoor_profile_info = {}
 *   cdn_frontdoor_map_info     = var.cdn_frontdoor_morihaya_test_map_info
 *
 *   ## environments
 *   env_id    = "t"
 *   system_id = "morihaya"
 *   context   = "morihaya001"
 * }
 * ```
 *
 */

resource "azurerm_cdn_frontdoor_profile" "main" {
  name                     = "${var.env_id}${var.system_id}fd${var.region_code}${var.context}"
...以下略...
```

今回問題となった `stack level too deep` を発生させていたのは、以下のsourceの行だったのです。

>  *   source = "../../../../modules/common/cdn_frontdoor"

見ていただくとわかる通り `source = `の行は `/*` と `*/` で囲んだセクション内にあり、hclではコメント扱いとなる部分ですが、それをDependabotが参照した結果無限ループが発生していたのです。

人によるとは思いますが、「HCLとしてはコメント部分」が悪さをしていたこの問題は、Terraformコードに慣れている人間ほど原因に気づきにくいと感じました。

## 解決: コメント部分の記述を修正

原因さえ分かれば、修正自体は簡単です。

エディタの全体置換機能を使い、以下のように置換しました。

元: `*   source = "../../../../modules`
先: `*   source = "../path/to/`

そしてdependabot.ymlは当初やりたかった `directories` で `**/*` を使用しています。

追加としてHCP Terraform のプライベートレジストリにあるモジュールを扱うために、`registries` でHCP Terraformのレジストリと`TF_API_TOKEN`を設定しています。

```yml
# /.github/dependabot.yml
version: 2

registries:
  terraform-cloud:
    type: terraform-registry
    url: https://app.terraform.io
    token: ${{secrets.TF_API_TOKEN}}

updates:
  - package-ecosystem: "terraform" # Terraform provider updates
    directories:
      - "/modules/**/*"
      - "/systems/**/*"
    schedule:
      interval: "weekly"
    registries:
      - terraform-cloud

  - package-ecosystem: "github-actions" # GitHub Actions workflow updates
    directory: "/" # Location of GitHub Actions workflows
    schedule:
      interval: "weekly"
```

このdependabot.ymlをPushし、Forkした切り分け用のリポジトリで、一気に大量のDependabotからのPRが作成された時は喝采をあげました。これによって大規模なTerraformリポジトリでも問題なくDependabotを運用できる準備が整ったと言えるでしょう。

## おわりに

以上が「Dependabotがstack level too deepでエラーになった意外な理由」です。

今回の切り分けにおいては、改めて生成AIによる支援の凄さを体験できました。

AIは確かに本文中で紹介したようなハルシネーションを起こします。（directoriesが使えないとか、.terraform.lock.hclファイルをおけば治るとか）

それでも原因の特定に、1時間弱ほどの時間で自分だけでたどり着けたのはCopilotによるサポートがあったからだと確信しています。AI未使用だった場合はチームメンバーの何名かを招集して数時間分を注ぎ込む必要があったでしょう。

あらためてCopilotをはじめとしたAI活用を、さらに進めていこうと強く思えた良いタスクでした。

それではみなさま、Enjoy Dependabot & GitHub Copilot!

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味を持った方は、キャリア登録やカジュアル面談の登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recruiting.aeon.info/)
