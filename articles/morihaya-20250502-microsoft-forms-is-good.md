---
title: "Microsoft Forms良いじゃん！となったポイントをGoogle Formsと比較してみる"
emoji: "🍎"
type: "tech"
topics:
  - "microsoft"
  - "microsoft365"
  - "forms"
  - "microsoftforms"
  - "aeon"
published: true # false or true , スケジュール公開の場合はfalseで予約して後からtrueにFix必要
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。
当社はMicrosoft 365(以降はM365)を導入しておりExcelやPowerPointを活用しています。（正直Markdownを書くことの方が多いですが）

本記事ではM365の数多くあるアプリのひとつでアンケートや投票を収集できる[Microsoft Forms](https://www.microsoft.com/ja-jp/microsoft-365/online-surveys-polls-quizzes)を使ってみて、良い感触だったのでそう感じたポイントを紹介します。

なお、個人の感想として”良い”と判断しているため、異なる意見を持たれる方の”良い”もリスペクトします。

## 背景

正直な話、私自身は「フォーム」の製品といえばGoogle Formsが最初に浮かんでいました。

しかしながら当社はM365を採用しており、社内アンケートなどを行う時は必然的にMicrosoft Formを利用しています。
これがなかなか良い体験だったので、Google Formsとの比較をブログにまとめることで言語化してみようと思い立ちました。

## アンケートサンプル

比較するために、同じ内容のアンケートを作成しました。

問いとしては2つです。

1. 好きな果物を3択から選ぶ。”その他”として任意で入力もできる
2. その理由を記入する

回答は以下のパターンで7票です。

```txt
# りんご
青森が好き
かたいから
赤いから

# ばなな
甘いから
ふさだから

# みかん
酸味が良いよね

# スイカ
夏はこれだね
```

## 入力画面は好みの差

シンプルなアンケートの場合、入力画面に機能的な違いはありません。
なお、スクリーンショットは公平を期すために一部を除き個人のフリープランのアカウントで作成したものを利用しています。

### Microsoft Formsの入力画面

Microsoft Formsのデフォルトのカラーは水彩系の青と緑です。

![MSForms-q](/images/morihaya-20250502-microsoft-forms-is-good/2025-05-02-00-41-42.png)

### Google Formsの入力画面

Google Formsのデフォルトのカラーは紫系です。（いまだに私はこちらを見慣れていると感じます...）

![GForms-q](/images/morihaya-20250502-microsoft-forms-is-good/2025-05-02-00-42-48.png)

## 集計画面は違いがでる

### Microsoft Formsの集計画面

Microsoft Formsの集計画面では上段に以下の3つの情報が表示されます。

- 応答数
- 応答にかかった平均時間
- 回答の収集を開始してからの期間

選択式の回答の場合は以下の2つ。

- 各回答ごとの数
- 円グラフの割合

入力式の回答の場合は以下の2つ。

- 回答数
- 最新の回答

![MSForms-a](/images/morihaya-20250502-microsoft-forms-is-good/2025-05-02-00-55-50.png)

### Google Formsの集計画面

Google FormsはMicrosoft Formsに比べてシンプルな印象です。

Google Formsの集計画面では上段に"応答数"の1つの情報が表示されます。

選択式の回答の場合は”円グラフの割合”

入力式の回答の場合は以下の2つ。これはMicrosoft Formsと同じです。

- 回答数
- 最新の回答

![GForms-a](/images/morihaya-20250502-microsoft-forms-is-good/2025-05-02-00-57-53.png)

### 上段部の概要の多機能さはMicrosoft Formsが勝る

以下のように並べれば一目瞭然。
Microsoft Formsにある”平均時間”は回答に要した時間です。
フォーム作成時に想定した時間との差を比較することで、アンケートの適切なボリューム設計に役立ちます

- Microsoft Forms
  - ![MSForms-upper](/images/morihaya-20250502-microsoft-forms-is-good/2025-05-02-01-16-50.png)
- Google Forms
  - ![GForms-upper](/images/morihaya-20250502-microsoft-forms-is-good/2025-05-02-01-17-20.png)

”期間”についてはとくに自分は必要としませんでしたが、「募集期間に対して現在の票数」と想定を比較することで、より回答を集めるためのアナウンスが必要といった判断も可能になるでしょう。

### 選択式回答の表示もMicrosoft Formsの方が嬉しい

選択式の回答の表示についても「各選択項目の個数」が表示される点が嬉しいです。
ただ、円グラフのデザインはGoogle Formsの方が見やすいためそちらの方が好みです。

- Microsoft Forms
  - ![MSForms-choices](/images/morihaya-20250502-microsoft-forms-is-good/2025-05-02-01-30-17.png)
- Google Forms
  - ![GForms-choices](/images/morihaya-20250502-microsoft-forms-is-good/2025-05-02-01-31-17.png)

後述する”その他”の表示の仕方が異なるのも面白いポイントです。

### 記述式回答の表示はGoogle Formsの方が嬉しい

テキスト式の回答の表示は「7つくらいなら全部表示しても良いのでは」と感じたのでGoogle Formsに一票です。
回答数が数十以上となるとまた感想が変わるかもしれません。

- Microsoft Forms
  - ![MSForms-text](/images/morihaya-20250502-microsoft-forms-is-good/2025-05-02-01-35-30.png)
- Google Forms
  - ![GForms-text](/images/morihaya-20250502-microsoft-forms-is-good/2025-05-02-01-36-12.png)

## 他にもMicrosoft Formsの良いところ

以降は思い出しながら個別の機能にフォーカスして紹介します。

### Microsoft Formsはドロップダウンリストでも”その他”が利用できる

選択式の質問において”その他”は便利な機能です。
回答するユーザは選択肢に選びたい項目がない場合、”その他”を選ぶことで自由に回答を行えます。

Google Formsでもこの機能はありますが、ドロップダウンリスト（Google Formでは”プルダウン”と呼ぶ）では”その他”を利用することはできません。（執筆時点の情報）

![sonota](/images/morihaya-20250502-microsoft-forms-is-good/2025-05-02-01-53-05.png)

選択肢が多いケースでは縦幅が短く収まるドロップダウンリストが好みであるため、その他が制限なく利用できるのはありがたいです。

### Microsoft Formsは”その他”に任意回答がばらけても”その他”として集計してくれる

任意回答が可能な”その他”ですが、ユーザがどんなバラバラな回答を行っても1つの”その他”として集計してくれます。
以下はサンプルに”もも”、”ドリアン”、”ぶどう”を追加回答した結果ですが、その他としてまとまっています。

![MSForm-sonota-sum](/images/morihaya-20250502-microsoft-forms-is-good/2025-05-02-02-20-22.png)

一方で同じように”その他”へ追加回答したGoogle Formsでは個別の回答として集計が行われています。
![GForm-sonota-sum](/images/morihaya-20250502-microsoft-forms-is-good/2025-05-02-02-21-55.png)

これも好みの問題と言えますがMicrosoft Formsの方が私としては期待した動作でした。

### 表計算ツールとしてExcel連携が強力

M365のエコシステムとして、Microsoft Formsの結果はExcelへ連携が可能です。
Google FormsでもGoogle Sheetsへ連携が可能ですが、表計算ツールとしてはExcelに一日の長があると言えそうです。

### Power Automateとの連携も容易

Excelと同じくM365のエコシステムに、ローコードやノーコードでワークフローを組めるPower Automateがあります。
別記事で紹介予定ですが「ユーザの入力した値を使った各種自動処理」の”入力画面”をMicrosoft Formsが担ってくれるため、認証も画面も自分たちで用意する必要がありません。

![form-and-powerautomate](/images/morihaya-20250502-microsoft-forms-is-good/2025-05-02-02-03-58.png)

### Copilot連携にも期待が高まる

M365のCopilotのライセンスがあれば、Microsoft FormsにおいてもCopilotの支援を受けることができます。
試しに以下の文章で作成をお願いしたところ、今回のサンプルに近いものを数秒で作成してくれました。

> 好きな果物をのアンケートを取ります。選択肢は”りんご”、”ばなな”、”みかん”の3つで、”その他”で任意の回答もできるようにしてください。
> 加えて短い自由入力で”好きな理由”も集めたいです。
> 項目は全部必須です。

![copilot-01](/images/morihaya-20250502-microsoft-forms-is-good/2025-05-02-02-11-34.png)

Copilotが作成したのが以下です。ほぼ手直し不要と言えます。

![copilot-02](/images/morihaya-20250502-microsoft-forms-is-good/2025-05-02-02-13-08.png)

強いて挙げるなら”その他”の項目がテキストとしての選択肢となっており、サンプルで用意した任意の文字列で入力できる形式ではありませんでした。

## おわりに

以上が「Microsoft Forms良いじゃん！となったポイントをGoogle Formsと比較してみる」の記事でした。
フォームといえばGoogle Formsと長年思ってきただけに、Microsoft Formsの端々で感じる良さが自分の中でも整理できた感触があります。
もちろんGoogle Formsへの高い信頼は今も変わらず、多くの方の役に立つ素晴らしいサービスのひとつだと認識しています。
今後も状況に応じながら両フォームサービスを活用させてもらうつもりです。

それではみなさまEnjoy Microsoft 365!

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味をもった方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recruiting.aeon.info/)
