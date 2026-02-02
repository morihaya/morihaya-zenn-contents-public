---
title: "影響なし：Azure DevOps Pipelinesが突然Encountered error(s)を出し始めた"
emoji: "🚧"
type: "tech"
topics:
  - "Azure"
  - "AzureDevOps"
  - "azurepipelines"
  - "aeon"
published: true
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）SREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。

本記事ではAzure DevOps（以降はADO）Pipelineの実行時に、突然怖いエラーが出て慌てたが結局問題はなかった事象を紹介します。
デフォルトの権限で発生し得る事象であるため、私たちと同じように慌てる人がでないことを願って記事を書いています。

具体的には以下のエラーが突然表示されるようになりました。このエラーがPipeline実行においては警告でしかなかったというものです。

> Encountered error(s) while parsing pipeline YAML:Job Run_Execute: Environment <Env Name> could not be found. The environment does not exist or has not been authorized for use.Job Run_Execute: Environment <Env Name> could not be found. The environment does not exist or has not been authorized for use.Job Apply: Environment <Env Name> could not be found. The environment does not exist or has not been authorized for use.

## TL;DR

- ADO Pipelineを用いてCI/CDを行っているが、ある日突然エラーメッセージが表示されるようになった
- 基本的にリリース作業はADO Pipelineを用いてプロダクトチームにセルフで行ってもらっているが、エラーでびっくりした
- Microsoftサポートの協力もあり、あくまでメッセージが出るようになっただけで、権限の仕様に変更は無く、実行には問題なかった

## 背景

当社ではAzure DevOps（ADO）Pipelineを利用してCI/CDを実現しています。（もちろんGitHubおよびActionsもあります）

たとえばAzureネイティブで連携が容易なAKSへのManifest反映などをADO Pipeline経由で行っており、プロダクトチームが自律的にリリース作業を行えるよう仕組みを整えています。

いくつかのADO Pipelineでは[Environment](https://learn.microsoft.com/ja-jp/azure/devops/pipelines/process/environments)機能を活用しており、デプロイ対象の環境ごとに承認フローやリソースの管理を行っています。

## プロダクトチームのリリース時に突然出てきた大量のエラーメッセージ

ある日、プロダクトチームからリリース作業時にエラーが発生しているとの救援要請を受けました。

時をおかず当チームから有志が反応し、リリースのためのオンライン会議室に参加し状況を確認してみると、ADO Pipelineの実行画面に以下のようなエラーメッセージが大量に表示されていました。

> Encountered error(s) while parsing pipeline YAML:Job Run_Execute: Environment <Env Name> could not be found. The environment does not exist or has not been authorized for use.

具体的には以下の画面です。ものものしいエラーに驚く気持ちがわかるでしょうか。

![ado-pipeline-env-erros](/images/morihaya-20260130-ado-env-error/2026-01-30-22-39-22.png)

少し遅れて支援に入った私はこのメッセージを見た時点ではEnvironmentが見つからない、あるいは認可されていないとのことで「権限の問題で実行ができなくなったのでは？」と焦りました。

当チームではPlatform Engineering（以降はPFE）の観点からEntra IDの権限変更の見直しを行なっており、その影響でこのエラーが発生した可能性を想定したためです。つまり当チームの作業影響かもしれないと考えました。

## その場は強権限を持つSREチームが入ることでフォローした

"You build it, You run it."（自分で開発して自分で運用しよう）が提唱されて久しいですが、ASTでも可能な限りプロダクトのリリースはそのプロダクトを開発チームに任せる方針をとっています。

しかし今回のケースではエラーの発生から通常のリリースは難しいと判断し、強権限をもつ当チームがADO Pipelineを実行することでその場はリリース作業を行い、エラーへの対応は後回しとしました。

これは暫定対応で、個人としてはついその場で原因特定のために切り分けや試行錯誤をしたくなりますが、プロダクトチームがリリースを予定通りに進めることが優先されると判断しました。

## Environment Securityの見直しで警告を抑止できた

リリース作業を無事に終えたあとは、チーム内で対策を検討しました。
初手としてMicrosoft Azureには心強いサポート部隊がいるため、状況と解決策をService Request（以降はSR）として起票しました。

並行して、自分たちでも調査を進めます。原因が不明な状況で他のプロダクトチームがリリース作業を行う際にエラーメッセージが表示されると混乱を招くため、早急に解決したいと考えました。

幸いなことにSandBox用のPipelineも同じ状況であることを確認しました。
当社では日頃からSIT（開発用のテスト）環境の他に、破壊しても問題ないSandBox用の環境を用意していますが、今回の調査もそれが大いに役立ちました。

実際のEnvironmentのSecurity設定画面は以下のようになっています。赤枠部分のロール設定が今回のポイントです。
![env-security](/images/morihaya-20260130-ado-env-error/2026-01-31-01-05-15.png)

この画面を見ながらチームメンバー4名ほどでディスカッションしながら検証し、暫定対処として、以下のようにEnvironmentのセキュリティ設定を変更することで警告メッセージの表示を回避することがわかり、全体へ周知の上で設定を展開しました。


```
# 現状
## プロジェクト全体のEnvironment Level
- <Project>/Contributors: Creator
- <Project>/Project Administrators: Creator
## 個別Environment Level（プロジェクト全体のEnvironmentから継承される）
- <Project>/Contributors: Reader
- <Project>/Project Administrators: Reader

↓

# 暫定対処後
## プロジェクト全体のEnvironment Level
- <Project>/Contributors: User
- <Project>/Project Administrators: Administrator
## 個別Environment Level（プロジェクト全体のEnvironmentから継承される）
- <Project>/Contributors: User
- <Project>/Project Administrators: Administrator
```

つまり、プロジェクト（上位）で`Creator`の権限を付与すると、個別（下位）のEnvironmentでは`Reader`の権限が付与されますが、該当のエラーを抑止するためには`User`以上の権限が必要でした。

この変更により警告メッセージは消えましたが、「そもそもなぜ急に警告が出るようになったのか」との疑問は残りました。

### 参考：ADO Pipeline EnvironmentsのSecurity種別

先に暫定対策としてSecurityの変更について記載しましたが、参考として以下に[ドキュメント](https://learn.microsoft.com/en-us/azure/devops/pipelines/policies/permissions?view=azure-devops#set-security-for-environments-in-azure-pipelines)から各ロールについての説明を引用します。

| 種別 | 名前 / グループ | 説明 |
| --- | --- | --- |
| ロール | Creator | プロジェクト内で Environment を作成できる。プロジェクト レベルのセキュリティにのみ適用される。Contributors は自動的にこのロールが割り当てられる。 |
| ロール | Reader | Environment を閲覧できる。 |
| ロール | User | YAML Pipeline を作成または編集する際に、その Environment を利用できる。 |
| ロール | Administrator | 権限の管理、Environment の作成・管理・閲覧・利用ができる。Environment の作成者には、その Environment の Administrator ロールが付与される。Administrator は、プロジェクト内のすべての Pipeline に対して Environment へのアクセスを開放することもできる。また、Environment を作成した個人には、その Environment に対する Administrator ロールが自動的に与えられ、このロール割り当ては変更できない。 |


また以下はデフォルトのユーザーおよびグループの役割の割り当ての仕様です。

| 種別 | グループ名 | 説明 |
| --- | --- | --- |
| デフォルト割り当て | [project name]\Contributors | Creator（プロジェクト レベル）、Reader（オブジェクト レベル） |
| デフォルト割り当て | [project name]\Project Administrators | Creator |
| デフォルト割り当て | [project name]\Project Valid Users | Reader |


## 解決に向けてサポートケースを作成

根本的な原因を把握するため、Microsoftサポートにケースを作成して問い合わせを行いました。

問い合わせ内容として以下のポイントを伝えました。

- ある日突然、ADO PipelineでEnvironmentに関するエラーメッセージが表示されるようになった
- Pipeline自体は正常に動作しており、実行結果には影響がない
- 権限設定を変更することで警告は消えたが、根本原因を把握したい
- 今後の対応方針として、どの権限設定がベストプラクティスか知りたい

## サポート回答によって事象が整理され、問題がないことがわかった

SR起票の翌日に来たMicrosoftサポートからの回答により、事象の全容が明らかになりました。（多くのMSサポートのみなさんの仕事の速さにいつも感謝しています！）

結論として、**これはAzure DevOpsの仕様変更によるものでした**。YAML解析時にEnvironmentへのアクセス権限チェックが厳密になり、その結果として`Reader`権限のみのユーザーに警告が出るようになった、との位置づけです。

以下に回答の一部を引用します。

> ...(略)...お問い合わせのエラー メッセージは、下記 Azure DevOps Services の [Sprint 266 (2025/12/19) リリース](https://learn.microsoft.com/ja-jp/azure/devops/release-notes/2025/pipelines/sprint-266-update)にて行われた修正の影響により、表示されるようになりました。Environments の Security 設定の継承や、アクセス権限の仕様自体には変更は行われておりません...(略)...

以前はEnvironmentへのアクセス権限がない場合でもエラーメッセージが表示されませんでしたが、セキュリティの透明性向上のためにメッセージが表示されるようになったとのことです。

重要なポイントは以下です。

- Environment周辺の権限の仕様自体は変更されていない
- メッセージが表示されるようになっただけで、従来と同じくPipeline実行には支障がない
- Readerレベルの権限では警告が出るが、User以上であれば警告が出ない

つまり、私たちが暫定対処として行った「ContributorsをReaderからUserに変更する」対応はエラーを抑止する点では適切でしたが、Pipline実行については影響がなかったそうです。
一方で全体Envに対して`Creator`->`User`としたことで、ContributorsからEnvironmentの作成権限を奪ってしまうことになります。

## 参考：警告を回避しつつ権限も維持するベストなケース

サポートからのアドバイスを踏まえ、当社での推奨設定をまとめます。

| レベル | グループ | 推奨権限 |
|--------|----------|----------|
| 全体Env Level | Contributors | Creator |
| 全体Env Level | Project Administrators | Administrator |
| 個別Env Level | Contributors | User(個別設定) |
| 個別Env Level | Project Administrators | Administrator（継承） |

この設定により、以下のメリットがあります。

- プロダクトチーム（Contributors）がPipelineを実行する際に警告メッセージが表示されない
- 必要以上の権限を付与せず、最小権限の原則を維持できる
- 管理者（Project Administrators）はEnvironmentの設定変更が可能

そして以下のデメリットがあります。

- 個別EnvのContributorsに対して、Environmentを作成するために継承を外して個別のSecurity設定を行う必要がある

運用面を考えれば継承を前提として全体でUserを与えるべきですが、Environmentの作成権限が失われます。全体でCreatorを与えると最小権限の原則を守れますが、個別EnvでのToilが発生します。
どちらを選択するかは対象のEnvironmentやPipelineの用途を考慮すると良いでしょう。

まとめると以下になります。

- 暫定対処：全体EnvでContributorsに`User`を付与（Environment 作成権限が失われる）
- 推奨設定：全体Envは`Creator`のまま、個別Envで`Contributors`を`User`にする（Toilは増えるが最小権限を維持）

## おわりに

以上が「影響なし：Azure DevOps Pipelinesが突然Encountered error(s)を出し始めた」事象の紹介でした。

今回の事象は、結果として影響なしであったものの、プロダクトチームにとっては「いつも通りの作業で急にエラーが出た」不安な体験でした。

日々のクラウドサービスの進化に感謝しつつも、利用する上でこのような仕様変更は避けられません。
今回の件を通して重要なのは焦らずに情報を整理し、必要に応じてサポートに確認することだと改めて体感しました。

本記事が似たようなエラーで慌てたどなたかに届くと幸いです。

それではみなさま、Enjoy Azure DevOps Pipeline!

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味を持った方は、キャリア登録やカジュアル面談の登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recruiting.aeon.info/)
