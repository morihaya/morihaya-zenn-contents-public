---
title: "Power AutomateでExcel管理の1000人をTeamsに30分で自動追加しました"
emoji: "🤖"
type: "tech"
topics:
  - "powerautomate"
  - "teams"
  - "excel"
  - "zennfes2025infra"
  - "microsoft365"
published: true
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。
本記事では「Power Automate」で現場を支援した話を書きます。何番煎じかわかりませんが、実際に喜んでくれた現場があるので紹介したいです。

要件は以下のとおりでした。

> 半年に一度実施される情報セキュリティ訓練のメール配信で、「Teamsチャネルにメンバーを漏れなく追加したい」。しかしメンバーリストはExcelで管理されているものの、手作業での追加では漏れや抜けが発生しがちです。何とかならないでしょうか？

この依頼を受けて、Power Automate初心者の自分が約1000人のメンバーをExcelから自動でTeamsに追加した実装と、その過程で直面した課題の解決方法について共有します。

## TL;DR

- Power AutomateでExcelからTeamsメンバーを自動追加する仕組みを構築
- Excelの256件制限をPaginationオプションで回避（Max 2000設定）
- 約1000人のメンバーを30分でTeamsチャネルに追加完了
- Try-Catch-Finallyブロックでエラー処理を実装
- エラーとなったメールアドレスをリスト化して確認可能に

## 背景と課題

### 現状の課題

当社にはサイバーセキュリティやリスクマネジメントの専門チームがあります。
各チームは組織のセキュリティリテラシーに責任を持っており、たとえば半年に一度の情報セキュリティ訓練を通して組織にリスクを思い出させます。

具体的にはコミュニケーションツールのTeamsを活用し、当グループの多くをカバーした連絡体制を取っています。
その訓練対象者はExcelファイルでリストとして管理されていましたが、以下のような課題がありました：

- 手作業による追加漏れ: 1000人近いメンバーを手動で追加すると、どうしても漏れが発生
- 時間的コスト: 手作業では数時間かかる作業
- 人的ミス: メールアドレスのコピペミスなど
- 棚卸し不足: すでに異動・退職したメンバーがリストに残っている

### 対策としてPower Automateを選んだ理由

そこで改善策として選ばれたのがPower Automateです。Power Automateには以下の利点がありました。

- Microsoft 365のライセンスで利用可能
- ExcelとTeamsの連携が標準コネクタで実現可能
- ローコードで実装できるため、メンテナンスが容易
- エラーハンドリングの仕組みが充実
- コミュニティも含めたナレッジの豊富さ（そしてそれをAI Agentが活用できる）

並べてみるととても優れた要素がPower Automateにはありますね。

## 実装の詳細

### フロー全体の構成

実装したPower Automateフローの全体構成は以下の通りです：

```
1. 手動トリガー
2. Excelファイルから行データを取得（Pagination設定）
3. Apply to eachでメールアドレスをループ処理
4. Conditionでメールアドレスの妥当性チェック
5. Try-Catch-Finallyでエラー処理
6. Teamsメンバー追加
7. エラーリストの集約と通知
```

![pa-flow](/images/morihaya-20251022-powerautome-genba/2025-10-22-01-46-31.png)

---

### 1. Excelデータの読み取り（256件制限の突破）

ここからは各項目について解説します。

Power AutomateのExcelコネクタには、デフォルトで256件の取得制限があります。これを回避するため、Paginationオプションを有効化しました。

```
アクション: List rows present in a table
設定:
- Pagination: ON
- Threshold: 2000
```

UIとしては以下になります。

![Pagenation](/images/morihaya-20251022-powerautome-genba/2025-10-22-01-51-33.png)

:::message
Paginationの設定は「Settings」タブから行います。この設定により、最大2000件まで一度に取得可能になります。
:::

### 2. Apply to eachによるループ処理

取得したExcelデータを1行ずつ処理します：

```
Apply to each
├─ Select: value (Excelから取得した行データ)
└─ 処理内容:
    ├─ Condition (メールアドレスチェック)
    ├─ Try-Catch-Finally
    └─ Compose (エラー記録)
```

ブロックとしてはシンプルで、直前のExcelから読み取る`List rows present in a table`を受け取る形になります。

![apply-to-each](/images/morihaya-20251022-powerautome-genba/2025-10-22-01-53-31.png)

### 3. メールアドレスの妥当性チェック

実は後続のTry-Catch-Finallyで対応できていますが、そもそもメールアドレスとして体をなしていないものは手前で排除しています。最後のCompose処理でエラーとなったメールアドレス一覧を表示しており、そこに明らかにおかしいアドレスを混ぜ込みたくないためです。

Conditionを使って、メールアドレスが有効かどうかをチェック：

```
Condition:
- contains(items('Apply_to_each')?['Email'], '@')
- not(empty(items('Apply_to_each')?['Email']))
```

![condition](/images/morihaya-20251022-powerautome-genba/2025-10-22-01-55-45.png)

これにより、不正なメールアドレスや空のセルをスキップできます。

### 4. エラーハンドリングの実装

Try-Catch-Finallyブロックを活用して、個別のエラーがフロー全体を止めないように実装、加えてエラーとなったメールアドレスの一覧をCatchにより最後に表示させます：

```
Scope (Try)
├─ Add member to team
│   ├─ Team ID: [対象のTeams ID]
│   └─ User: items('Apply_to_each')?['Email']
│
Scope (Catch) - Configure run after: Failed, Skipped, Timed out
├─ Append to array variable
│   └─ Value: items('Apply_to_each')?['Email']
│
Scope (Finally) - Configure run after: Succeeded, Failed, Skipped, Timed out
└─ (次の処理へ)
```

:::message alert
Try-Catch-Finallyは「Scope」アクションを3つ組み合わせて実装します。CatchとFinallyのスコープでは「Configure run after」の設定が重要です。
:::

このノウハウに関しては[ユニフェイスの上村さんの記事](https://hub.uni-face.co.jp/power-automate-error-handling/)が役立ちました。3年近く経っても通用する素晴らしいアウトプットに感謝しています。

![try-catch-finally](/images/morihaya-20251022-powerautome-genba/2025-10-22-01-59-33.png)

なお最後のFinallyにはActionがひとつもありませんが、Apply to eachのループ処理を進めるためのおまじないと考えています。

### 5. エラーメールアドレスのリスト化

最後に、処理できなかったメールアドレスをComposeアクションで一覧化：

```
Compose:
- Inputs: variables('ErrorEmailList')
```

このリストは、後続の手動確認やデバッグに活用できます。
マスターとなるExcelの正常性を誰が担保できるのかは答えに困る問題ですが、少なくともEntra IDに存在しないメールアドレスを異常と判定できます。

![compose](/images/morihaya-20251022-powerautome-genba/2025-10-22-02-01-57.png)

## パフォーマンスと結果

実際の運用結果：

- 処理時間: 約1000人を30分で処理完了
- 成功率: 95%以上（エラーは主に無効なメールアドレス）
- エラー処理: 全エラーをリスト化し、後続対応が可能に。なおおよそ二桁を超える異常メールアドレスの洗い出しに成功しています

## 実装できなかった機能と今後の改善点

### メンバーの「洗い替え」機能

当初の要望には「既存メンバーをすべて削除してから新規追加」（洗い替え）がありましたが、Power Automateの標準アクションではTeamsメンバーの削除が見つかりませんでした。

![why-delete-menber-from-teams-nothing](/images/morihaya-20251022-powerautome-genba/2025-10-22-02-03-56.png)

上記は`Teams`関連のアクションですが`Add a member to team`も`Delete a member from a tag`もあるのに`Delete a member from team`が存在しないことに違和感しかありません。代替手段をお持ちの方はぜひご連絡ください。

### 今後の改善案

1. **Graph APIの活用**
   - Microsoft Graph APIを使用すれば、メンバー削除も可能に、なるのか？（情報を求めています）

2. **差分チェック機能**
   - 現在のTeamsメンバーリストとExcelの差分を取得
   - 追加・削除対象を自動判定

3. **処理速度の改善**
   - 並列処理の導入（Concurrency Control）
   - バッチ処理での一括追加

4. **セキュリティの観点：マスターExcelとPower Automateの管理者**
   - 期待する動作は行いました。ではこのメールアドレスが大量に描かれたExcelと、Power Automateの管理者を適切にアサインできるのか
   - 組織に寄り添ったアサインが必要となります

## 実装時のTips

以降は今回の学びです。Power Automateビギナーのあるあるが伝わると嬉しいです。

### 1. テスト環境での事前検証

本番のTeamsのTeamで実行する前に、必ず”テスト用Team”の利用と”テストで追加するメンバーの事前了承”を得てから動作確認を行いましょう。
なぜならTeamに追加や削除をされる際に、本人に通知メールが飛ぶからです。（信頼関係があるなら問題ないですが）

### 2. 実行履歴の確認

Power Automateの実行履歴から、各ステップの詳細を確認できます。エラー発生時のデバッグに非常に有用です。
当初`Apply to each`が256で止まった時は、なんてわかりやすいLimitなのだろうと考えましたが、実際には`List rows present in a table`のPaginationのチューニングが必要でした。

### 3. エラーが起きてもループを継続させる

Paginationにより1000件以上に対応しても、異常エラーで止まってしまうのは問題です。ScopeブロックによるTry-Catch-Finallyのエラーハンドリングと、Composeによるエラー要因の一覧が役立つはずです。

## おわりに

以上が「Power AutomateでExcel管理の1000人をTeamsに30分で自動追加しました」の記事でした。
Power Automateを使うことで、手作業では数時間かかっていたTeamsメンバー追加作業を30分で自動化できました。
課題は残っており、完全な「洗い替え」機能は実装できませんでしたが、追加作業の自動化だけでも大幅な業務効率化を実現できました。

そしてPower Automateの便利さに助けられる一方で、ミクロな現場の改善に疑問を覚えているのも事実です。かつてのVBAやExcelマクロが辿った個別最適化の道を歩いている感触がひしひしとあります。
このリスクを常に頭に持ちながらも、今助けられる現場を支援していきたいとも考えています。

この課題感を抱きながらも、みなさまEnjoy Power Automate!!!

## 参考リンク

- [Power Automate - Excel Online (Business) コネクタ](https://docs.microsoft.com/ja-jp/connectors/excelonlinebusiness/)
- [Power Automate - Microsoft Teams コネクタ](https://docs.microsoft.com/ja-jp/connectors/teams/)

---

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味をもった方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recuruiting.aeon.info/)
