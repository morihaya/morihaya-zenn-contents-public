---
title: "HCP TerraformをEntra IDでSSOする勘所（GroupとTeam連携が肝）"
emoji: "🔐"
type: "tech"
topics:
  - "hashicorp"
  - "terraform"
  - "hcpterraform"
  - "entraid"
  - "aeon"
published: true
published_at: "2026-07-17 08:00"
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://x.com/morihaya55)です。

当社ではIaCの実行基盤としてHCP Terraform（以降はHCPt）を利用しています。これまでHCPtへのログインはID/PW+MFAと、HashiCorp Cloud Platform（以降はHCPlatform）からのLinkログインを併用してきましたが、このたびEntra IDによるSSOへ切り替えました。

基本的には[公式ドキュメント](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/single-sign-on/entra-id)に沿って設定すれば良いのですが、Entra IDのGroupとHCPtのTeamを連携させる部分はドキュメント通りでは意図した動きにならず、いくつかの試行錯誤がありました。また、SSO化に伴う運用上の注意点（手動で作ってきたTeamの形骸化や、暗黙的に作られるTeam "sso"の存在）もあわせて共有します。

## TL;DR

- HCPlatformにSSOするとHCPtへのLinkログインができなくなる問題があるため、HCPtとHCPlatformそれぞれに対してEntra IDからSSOする構成にした
- Entra ID GroupとHCPt Teamの連携を”名前一致”で行うために、Entra ID側で「Group Name」を送る設定と、HCPt側で「Team Attribute」の値を変更する必要があった
- Team Management連携が有効なSSOでは、ユーザがSSOログインした瞬間にEntra ID側のGroup所属に基づいてTeamが再アサインされるため、手動で作成してきたTeamとメンバーシップは形骸化する（＝権限が外れる可能性がある）ことに注意
- SSO認証したユーザは暗黙的にTeam "sso"へ所属されるが、権限付与には利用すべきではない

## これまでのHCPtへのログイン方法と課題

HCPtへのログイン方法は大きく以下の3つがあります。

1. ID/PW（+MFA）によるログイン
2. HCPlatformアカウントとのLinkによるログイン
3. SSO（SAML/OIDC）によるログイン

当社ではこれまで1と2を併用してきました。つまり、ユーザによってはHCPtに直接ID/PW+MFAでログインし、別のユーザはHCPlatformからLinkログインする、という状態です。

アカウント管理の観点ではログイン経路は少ないほうが健全ですから、HCPlatformからのログインに集約したいと考えていました。HCPlatform自体はEntra IDとのSSOに対応しているため、「Entra ID → HCPlatform → （Link） → HCPt」という一本道にできれば理想です。

### HCPlatformにSSOするとHCPtにLinkログインできない問題

ところがここに落とし穴がありました。HCPlatform側でSSOを有効化すると、そのアカウントからHCPtへのLinkログインができなくなるのです（執筆時点の2026/07/16時点の挙動です）。

この事象についてはエラーメッセージに"will be supported in the future"とあるため期待していたのですが、半年以上経っても改善されない状況がつづいています。

![sso_login_error](/images/morihaya-20260717-hcpt-entraid-sso/2026-07-17-02-21-32.png)

以下エラーメッセージの全文です。（執筆時点）

> HCP SSO account isn't supported
We noticed that you tried to link your HCP Terraform (HCP Terraform) account to an HashiCorp Cloud Platform (HCP) Single-Sign On (SSO) account. HCP SSO accounts are not currently supported for linking to HCP Terraform user accounts, but will be supported in the future. Please login and link your HCP Terraform account to either your email or HCP GitHub account.

## 方針：HCPtとHCPlatformそれぞれにEntra IDからSSOする

待っていても仕方がないので発想を変え、「HCPlatform経由に集約する」ことは諦めて、シンプルにHCPtとHCPlatformのそれぞれに対してEntra IDからSSOすることにしました。

構成としては以下のイメージです。

- Entra ID → HCPlatform（SSO）
- Entra ID → HCPt（SSO）

ログインの入り口は2つのままですが、どちらも認証はEntra IDに集約されるため、アカウントのライフサイクル管理（入退社・異動時の棚卸しなど）の観点では十分に目的を達成できます。

さらに、HCPlatformからのLinkログインではIdle session timeoutが60minで固定される仕様がありますが、これをより柔軟に変更できるメリットもあります。

![fixed_60min_timeout](/images/morihaya-20260717-hcpt-entraid-sso/2026-07-17-03-04-43.png)

> HCP Terraform accounts linked to HashiCorp Cloud Platform (HCP)  are fixed to 60 minutes. This is enforced by HCP and cannot be modified.

## HCPtのEntra ID SSO設定

基本的な設定手順は公式ドキュメントの通りです。

https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/single-sign-on/entra-id

大まかな流れは以下となります。

1. Entra ID側でエンタープライズアプリケーションを作成し、SAMLベースのSSOを構成する
2. HCPt側のOrganization Settingsから「SSO」を開き、Entra ID（SAML）のメタデータ等を設定する
3. 属性（Attributes & Claims）のマッピングを設定する
4. テストユーザでSSOログインを確認する

ここまでは概ねドキュメント通りに進みますが、問題は次のGroupとTeamの連携です。

### ハマりポイント：Entra ID GroupとHCPt Teamの連携

HCPtのSSOには[Team Management](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/single-sign-on#team-names-and-sso-team-ids)という仕組みがあり、IdP側から送られてくるグループ情報をもとに、ユーザを対応するHCPtのTeamへ自動的にアサインできます。Entra IDのGroupとHCPtの連携できれば、チームメンバーの管理をEntra ID側へ寄せられるため、ぜひ活用したい機能です。

しかしこの部分、ドキュメントではEntra IDのGroup IDを利用する方法が記載されていますが、私たちとしては人間がわかりやすい「Entra IDのグループ名とHCPtのTeam名の一致」によるチームメンバー管理をしたいと考え試行錯誤し、具体的には以下の2点の対応が必要でした。

#### 1. Entra ID側：Group「Name」を送るように設定する

Entra IDのグループ要求（groups claim）はデフォルトではGroupのObject ID（GUID）が送信されます。GUIDのままではHCPt側のTeam名と一致させることができないため、Group Nameを送信するように設定を変更する必要があります。

エンタープライズアプリケーションの [Single sign-on] → [Attributes & Claims] からグループ要求の設定を開き、ソース属性としてGroup Nameを利用するように変更します。

ポイントは以下です。

- デフォルトでgroup claimはないため追加が必要
- HCPtのEnterprise Applicationにアサインしたグループのみを使う（コントロールしやすいため）
- グループ名（Cloud-only group display names）を属性元として利用する

![entraid_group_claim](/images/morihaya-20260717-hcpt-entraid-sso/2026-07-17-02-36-55.png)

#### 2. HCPt側：「Team Attribute」の値を変更する

HCPt側のSSO設定にある「Team Attribute」も、デフォルト値のままではEntra IDが送信するグループ要求のclaim名と一致しません。Entra IDが実際に送信するclaim名に合わせて変更する必要があります。

具体的には以下のように変更しています。

| 変更前後 | 値 |
| -- | --- |
| 変更前 | `MemberOf` |
| 変更後 | `http://schemas.microsoft.com/ws/2008/06/identity/claims/groups`|

![hcpt_team_attribute](/images/morihaya-20260717-hcpt-entraid-sso/2026-07-17-02-48-26.png)

この2点を対応することで、Entra IDのGroup名とHCPtのTeam名が一致するユーザが、SSOログイン時に自動的に対応するTeamへアサインされるようになりました。

なおSAMLレスポンスに実際どのような属性が入っているかは、Entra ID側のテスト機能で確認しながら進めると簡単です。
このEntra IDのテスト機能を私は気に入っており、RequestおよびResponceをXMLとしてダウンロードできるため、それをGitHub Copilotなどで分析することでエラーなどの解決を楽に行うことができましたし、上述したTeam Attributeに指定するグループの値もテスト機能のおかげでわかりました。

![testing_etraid](/images/morihaya-20260717-hcpt-entraid-sso/2026-07-17-02-51-27.png)

## 注意点

さて以降は注意するべき点を紹介します。

### 注意点1：手動で作成してきたTeamとメンバーシップは形骸化する

Team Managementを含めてSSO連携をすると、ユーザがSSOログインするたびにEntra ID側のGroup所属に基づいてTeam所属状態が”洗い替え”されます。

これはつまり、これまで手動で作成・メンテナンスしてきたTeamとそのメンバーシップが形骸化するということです。より具体的に言えば、「ユーザがSSOログインした瞬間に、Entra ID側のGroupに対応しないTeamからは外れ、それまで持っていた権限が失われる可能性がある」ということです。

「SSOを有効化した直後は問題なさそうに見えたのに、各ユーザがログインするたびにポロポロと権限が外れていく」という事態になりかねないため、SSOへの切り替え前に以下を整理しておくことを強くオススメします。

- 現在のHCPtのTeamとメンバーシップの棚卸し
- それに対応するEntra ID側のGroupの作成とメンバー登録
- Team名とGroup名の一致確認

なおこのTeamからユーザが抜ける状況については、HashiCorpヘルプセンターにも[Terraform Cloud Users Are Automatically Removed From Teams](https://support.hashicorp.com/hc/en-us/articles/1500002846242-Terraform-Cloud-Users-Are-Automatically-Removed-From-Teams)として記載があり、対応策としてTeam Managementを無効化してHCPtのUIでチーム管理を続ける選択肢も提示されていますが、当社ではEntra IDで管理するため採用しませんでした。すでに他SaaSのNew RelicやAkamaiでも実績のある運用だからです。

### 注意点2：暗黙的に所属されるTeam "sso"は権限付与に使わない

もうひとつ、SSO認証を行ったユーザは暗黙的にTeam "sso"へ所属されます。

一見「SSOユーザ全員に共通の権限を配るのに便利そう」に思えるかもしれませんが、このTeamはSSOでログインした全ユーザが自動的に含まれるため、権限のコントロールが非常に難しくなります。意図せず広範なユーザへ権限を付与してしまうリスクを考えると、Team "sso"への権限付与は行わず、あくまでEntra IDのGroupと明示的に対応させたTeamで権限を管理すべきです。

この点については、IBM HashiCorp事業部 ソリューションエンジニアの「森元 みらの」さんにスピード感と的確な支援いただき、挙動の理解と運用方針の整理を進めることができました。この場を借りて感謝いたします！みらのさん、いつも助かってます！！

## おわりに

以上が「HCP TerraformをEntra IDでSSOする勘所（GroupとTeam連携が肝）」でした。

HCPlatformへのログイン集約という当初の理想とは形が変わりましたが、HCPtとHCPlatformの両方の認証をEntra IDへ集約でき、アカウント管理の健全性は大きく向上しました。これから設定される方は、GroupとTeamの連携まわりの属性設定と、SSO切り替え時のTeamメンバーシップの扱いにぜひご注意ください。

それではみなさま、Enjoy HCP Terraform with Entra ID SSO!

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味を持った方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recruiting.aeon.info/)
