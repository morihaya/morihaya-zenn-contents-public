---
title: "Azure DevOpsのGroupをTerraform管理するときに権限まわりでハマった話"
emoji: "📠"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: # タグを指定する
  - "Azure"
  - "AzureDevOps"
  - "Terraform"
  - "aeon"
published: true
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。

本記事では、TerraformでAzure DevOpsのGroupを管理しようとして認証にハマって解決した件を紹介します。
同様の事象に悩む方は極めて少数かもしれませんが、同じハマりどころに遭遇した方の助けになれば幸いです。

なお、本件の中心となって進めてくれたのは別の同僚氏で、私はモブワークで一部をヘルプした関係で執筆をしています。

## TL;DR

本記事を箇条書きでまとめると以下です。

- Terraformで[Azure DevOps provider](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs)を利用してAzure DevOpsのGroupを管理しようとした
- planは通ったがapply時に`Additional details: security token: 12345678-1234-1234-1234-123456789012, permission bits required: 2.` エラーが発生
- Terraformで利用するService principalを`Project Collection Administrators`のメンバーにすることで解決

以下はエラーの詳細です。

> Error: Access Denied: 12345678-1234-1234-1234-123456789012 needs the following permission(s) in the Identity security namespace to perform this action: Edit identity information. Additional details: security token: 12345678-1234-1234-1234-123456789012, permission bits required: 2.

この以降は背景となりますので、詳細を知りたい方のみ読み進めてください。

## 背景

当社ではHCP Terraformを利用し、Azureの主要リソースやNew Relicなど、さまざまなプロダクトの管理をTerraformで管理しています。
その中で数少ない手動での設定が残っていたAzure DevOpsのグループ管理をTerraformで管理しようということになりました。

Azure DevOpsのグループ管理には[Azure DevOps provider](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs)を利用します。

Terraformのコードの一部は以下の通りです。

```hcl
## resoruce
resource "azuredevops_group" "this" {
  for_each     = local.groups_info
  display_name = each.key
}

## import
import {
  to = azuredevops_group.this["AST-morihaya-group-01"]
  id = "hogehoge"
}

import {
  to = azuredevops_group.this["AST-morihaya-group-02"]
  id = "fugafuga"
}
```

前提として `local.groups_info` にはTerraformで管理するEntra IDのグループ一覧が格納されており、その変数をAzure DevOpsでも利用するコードとなっています。

認証の方式はService Principalを利用し、HCP TerraformのWorkspaceのVariablesに以下を設定しました。

- ARM_CLIENT_ID
- ARM_CLIENT_SECRET
- ARM_TENANT_ID

利用するService PrincipalはEntra IDで作成後、Azure DevOps側でもユーザとして追加しています。

### planは通るがapplyはエラーに

同僚氏の頑張りにより既存グループのimport blockの記述によってplanは通る状態となりました。
planの状態をチームでレビューし、マージによって実行されたHCP Terraformのapplyの結果、import処理は成功しましたが、今回の処理でAzure DevOpsに作成されるグループすべてについて以下のエラーが発生しました。

> Error: Access Denied: 12345678-1234-1234-1234-123456789012 needs the following permission(s) in the Identity security namespace to perform this action: Edit identity information. Additional details: security token: 12345678-1234-1234-1234-123456789012, permission bits required: 2.

## 数々の対応策、ただし改善しなかった

ここからは試したが効果のなかった対応策の紹介です。
Azure DevOpsの権限を考えた時、こんな切り口もあるのだなと気づきになれば幸いです。

### Access Levelの切り分け

Azure DevOps上でEntra IDのService Principalはユーザとして扱われます。
そのため該当ユーザのAccess Levelについて以下を試しました。

- Basic
- Stakeholder

![](/images/draft-morihaya-20241029-azure-devops-t/2024-11-01-02-24-19.png)

結果どちらも改善しませんでしたが、結果として動作している現在はBasicを選択しています。
ドキュメントから抜粋すると全体を管理するTerraformの権限としてはBasicがふさわしいと考えます。

https://learn.microsoft.com/ja-jp/azure/devops/organizations/security/access-levels?view=azure-devops

> Basic: ほとんどの機能にアクセスできます。

### Entra IDでAzureのAdministrator権限を持っているグループに追加する

次に行ったのが、Terraformで利用するService PrincipalをEntra IDで連携されたAdministrator権限を持つグループに追加しました。こちらもグループ作成時のエラーは解決しませんでした。

後から考えればこれはとても惜しいのですが、DevOps内はあくまでDevOpsの権限で制御されているため、Azure側のAdministratorグループに入っていたとしてもグループ作成の権限は得られていなかったのです。

### `az devops security permission update` を実行する

次に行ったのがCLIによる権限付与です。
エラーには「Additional details: security token: 12345678-1234-1234-1234-123456789012, permission bits required: 2.」と記載があります。

ドキュメント[Learn/Azure/Azure DevOps - コマンドラインツールを使用して権限を管理する](https://learn.microsoft.com/ja-jp/azure/devops/organizations/security/manage-tokens-namespaces)を参考にCLIにて権限許可を行うことを試みました。

Service PrincipalのIDに対し `az devops security permission show --id hoge-fuga-piyo-moge --subject <Service Principal Name> --token muga-fuge-piro-ropi-hoho` を実行すると、以下の結果を得られました。

要注意ポイントとして `--subject` には権限を確認する先のDiscriptorの指定が必要になりますが、Discriptorの調べ方はAzure DeVops画面のPermissionsで、ブラウザの開発ツールを使って発見するとのことでした。赤枠部分に `subjectDescriptor=...` とあるのがわかるでしょうか。
（もっと楽な方法あればどなたか教えてください）

![](/images/draft-morihaya-20241029-azure-devops-t/2024-11-01-03-05-42.png)

改めて以下がコマンド結果です。

```sh
$ az devops security permission show --id hoge-fuga-piyo-moge --subject <Service Principalのdescriptor> --token muga-fuge-piro-ropi-hoho
[
  {
    "acesDictionary": {
      "Microsoft.IdentityModel.Claims.ClaimsIdentity;<Service Principalのdescriptor>": {
        "allow": 0,
        "deny": 0,
        "descriptor": "Microsoft.IdentityModel.Claims.ClaimsIdentity;<Service Principalのdescriptor>",
        "extendedInfo": {},
        "resolvedPermissions": [
          {
            "bit": 1,
            "displayName": "View identity information",
            "effectivePermission": "Not set",
            "name": "Read"
          },
          {
            "bit": 2,
            "displayName": "Edit identity information",
            "effectivePermission": "Not set",
            "name": "Write"
          },
          {
            "bit": 4,
            "displayName": "Delete identity information",
            "effectivePermission": "Not set",
            "name": "Delete"
          },
          {
            "bit": 8,
            "displayName": "Manage group membership",
            "effectivePermission": "Not set",
            "name": "ManageMembership"
          },
          {
            "bit": 16,
            "displayName": "Create identity scopes",
            "effectivePermission": "Not set",
            "name": "CreateScope"
          },
          {
            "bit": 32,
            "displayName": "Restore identity scopes",
            "effectivePermission": "Not set",
            "name": "RestoreScope"
          }
        ]
      }
    },
    "includeExtendedInfo": true,
    "inheritPermissions": true,
    "token": "muga-fuge-piro-ropi-hoho"
  }
]
```

ポイントは以下の"bit: 2"部分です。ここをNot setからAllowにできれば良いのではと考えました。

```json
          {
            "bit": 2,
            "displayName": "Edit identity information",
            "effectivePermission": "Not set",
            "name": "Write"
          },

```

そのため `az devops security permission update --allow-bit 3` によるBitを許可したいと考え、以下を実行しました。

```sh
$ az devops security permission update --allow-bit 3 --deny-bit 32 --id hoge-fuga-piyo-moge --subject <Service Principalのdescriptor> --token muga-fuge-piro-ropi-hoho
[
  {
    "acesDictionary": {
      "Microsoft.VisualStudio.Services.Claims.AadServicePrincipal;<Service Principalのdescriptor>": {
        "allow": 3,
        "deny": 32,
        "descriptor": "Microsoft.VisualStudio.Services.Claims.AadServicePrincipal;<Service Principalのdescriptor>",
        "extendedInfo": {
          "effectiveAllow": 3,
          "effectiveDeny": 32
        },
        "resolvedPermissions": [
          {
            "bit": 1,
            "displayName": "View identity information",
            "effectivePermission": "Allow",
            "name": "Read"
          },
          {
            "bit": 2,
            "displayName": "Edit identity information",
            "effectivePermission": "Allow",
            "name": "Write"
          },
          {
            "bit": 32,
            "displayName": "Restore identity scopes",
            "effectivePermission": "Deny",
            "name": "RestoreScope"
          }
        ]
      }
    },
    "includeExtendedInfo": true,
    "inheritPermissions": true,
    "token": "muga-fuge-piro-ropi-hoho"
  }
]
```

コマンドは成功し、以下の通りbit: 2へAllowが付与されたように見えています。

```json
          {
            "bit": 2,
            "displayName": "Edit identity information",
            "effectivePermission": "Allow",
            "name": "Write"
          },
```

しかしこの状態であっても `terraform apply` 時には同じエラーが発生しました。

### Permissions全部Allowに

次に行ったのがGUIでのPermissions画面にて、すべてのPermissionをAllowにしました。

![](/images/draft-morihaya-20241029-azure-devops-t/2024-11-01-02-58-44.png)

こちらもエラーに変化はありませんでした。

### ついに解決へ、グループを作成できるユーザとの権限比較

その後、モブワークで別の同僚氏メンバー（私含む）で課題解決のリトライをした際に、グループを作成できるDevOpsユーザとの比較を行いました。

具体的にはPermissions画面にて管理権限を持つ自分のアカウントを眺めたところ、権限の右端に情報マーク"ℹ️"があり、それにマウスオーバーをするとどこから権限を継承されているかがわかりました。

![](/images/draft-morihaya-20241029-azure-devops-t/2024-11-01-03-11-08.png)

具体的には情報ボタンをマウスオーバーすることで、以下のメッセージを確認できました。

> The permission value is being inherited through your direct or indirect membership in these groups: [ORG NAME]\Project Collection Administrators

そう、ここでやっとGroup作成ができるユーザが"Project Collection Administrators"に所属していることに気づけたのです。


## Project Collection AdministratorsへTerraform用のService Principalユーザを追加して解決

ここまでくればあとは試すのみで、Project Collection AdministratorsにTerraformで利用するService Principalユーザを追加したところ、無事に `terraform apply` が実行されました。
この瞬間は、数多の `terraform apply` のエラーに苦しんでいたモブワークの一同で快哉をあげました。

## おわりに

以上、TerraformでAzure DevOpsのGroupを管理しようとして認証にハマって解決した流れをご紹介しました。

AzureのRBACもそうですが、成熟したプロダクトの権限制御は柔軟性がある一方で、扱う私たちにとっては複雑に感じるケースがあります。
日々学びながら検証を重ねて理解を進めていきたいですね。

そして本件は、個人では解決が困難な状況に陥った時、目線が違った同僚氏たちと壁打ちしながらトライ＆エラーを繰り返すことで新しい道がひらけた良い体験の例です。
今後もチームで課題解決していきたいと心をあらたに思いました。

それではみなさまEnjoy Azure DevOps！

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味もった方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recuruiting.aeon.info/)
