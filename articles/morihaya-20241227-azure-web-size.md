---
title: "目grepしやすいAzure Web Portalはフォントサイズとウィンドウサイズから"
emoji: "😳"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: # タグを指定する
  - "azure"
  - "azureportal"
  - "aeon"
published: false
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。
いよいよ年の瀬ということでAzure Web Portalの小ネタ記事です。

なおこちらは以下のアベンドカレンダーの空きを埋める形で参加しています、わいわい。

- [Microsoft Azure Advent Calendar 2024](https://qiita.com/advent-calendar/2024/azure)シリーズ2の17日目
- [AEON Advent Calendar 2024](https://qiita.com/advent-calendar/2024/aeon)のシリーズ2の20日目

## TL;DR

本記事を箇条書きでまとめると以下です。

- AzureのWeb Portalで特定の設定をリソース別に交互に比較したい時がある（目grep）
- リソース一覧の左ペインが表示されているとやりやすい
- フォントとウィンドウサイズのバランスで左ペインのリソース一覧が表示されたり隠れたりする

## 背景

Azureユーザの多くの皆さまは、日々Azure Web Portalを利用してさまざまな確認を行なっているでしょう。
私たちASTのSREチームも、Terraformでリソースを管理し、New RelicでObservabilityを実装していますが、細かな設定やコストなどの確認のために日々Azure Web Portalを利用しています。

## 複数リソースの設定の違いを目で簡単にチェックしたい場合

よく発生するケースとして「特定のリソースの特定のパラメータについて違いを確認したい」があります。
例としてはVMやMySQLのインスタンスのサイズや、以下の動画のようなストレージアカウントのコンテナ作成状況などです。

![](/images/morihaya-20241227-azure-web-size/2024-12-26-21.14.26.gif)

この動画では3つのストレージアカウントのContainersの作成状況を確認しており、それぞれ"$logs"の他に"hoge","fuga","piyo"コンテナがあることを、左ペインのリソース名を次々とクリックするだけで確認しています。まさに"目grep"です。


:::message
"目grep"について

"目grep"はテキストファイルから特定の文字列を抽出する `grep` コマンドのような動作を、人間が肉眼で行う様を指すユニークな表現です。
今回のケースだと「肉眼で違いを調べる」ため正しくは"目diff"とでもいうべきでしょうが、目を使って必要な情報を抽出する広い意味でも"目grep"が使われているようなので採用してみました。
:::

## 左ペインにリソースが並ぶのが便利

Azure Web Portalでの目grepのポイントは以下の要素からなります。
- gif動画でも示したように、左ペインにフィルタ可能なリソースの一覧が表示される
- 左ペインのリソースを変更しても、右ペインの詳細情報のカテゴリは維持される

![](/images/morihaya-20241227-azure-web-size/2024-12-26-21-27-55.png)


## 便利なリソース一覧の左ペインが表示されない場合がある

このような大変便利な左ペインのリソース一覧ですが、以下のように表示されない場合があります。

![](/images/morihaya-20241227-azure-web-size/2024-12-26-21-35-54.png)

この状況は時折発生し、楽観的な私は「進化の早いAzureだしこういうこともあるよな」とか、「このサービスだと左ペインは表示されないんだっけ」などと不満をもらしつつも流してきました。
しかし、本記事のタイトルにもある通り、その法則性をついに発見したのです！！！

## 便利なリソース一覧はウィンドウサイズとフォントサイズのバランス

裏どりを行うため、急激に安定性と正確性が向上していると噂の"Microsoft Copilot in Azure"に質問をしてみました。

https://learn.microsoft.com/ja-jp/azure/copilot/overview

半年ほど前（2024/05）は待たされた上に良くエラーになっていた印象でしたが、現在は数秒でしっかりと回答をしてくれました！
その回答の全文が以下になります。

![](/images/morihaya-20241227-azure-web-size/2024-12-26-21-45-09.png)

テキストに起こすと以下の通りです。

> Q: The left pane of the Azure Web Portal sometimes appears and sometimes doesn't. What are the conditions for it to appear?
> 
> A: The left pane in the Azure Web Portal typically appears based on the following conditions:
> 1. Screen Size: On smaller screens or when the browser window is resized to a smaller width, the left pane may automatically collapse to provide more space for the main content area.
> 2. User Interaction: Users can manually toggle the visibility of the left pane using the menu icon (hamburger icon) located at the top left corner of the portal.
> 3. Portal Settings: The Azure Portal may remember your last setting for the left pane visibility and restore it the next time you log in.
> If you are experiencing inconsistent behavior, it might be due to a combination of these factors.

---
> Q: Azure Web ポータルの左ペインが時々表示され、また時々表示されないことがあります。表示される条件は何ですか？
> 
> A: Azure Web ポータルの左ペインは通常、以下の条件に基づいて表示されます。
> 1. 画面サイズ：画面が小さい場合、またはブラウザウィンドウの幅が小さくリサイズされた場合、左ペインは自動的に折りたたまれ、メインコンテンツ領域により多くのスペースが提供されます。
> 2. ユーザー操作：ユーザーは、ポータル左上隅にあるメニューアイコン（ハンバーガーアイコン）を使用して、左ペインの表示を手動で切り替えることができます。
> 3. ポータル設定：Azureポータルは、左ペインの表示に関する最後の設定を記憶し、次回ログイン時にそれを復元することがあります。
> 動作の一貫性がない場合は、これらの要因が組み合わさっていることが原因である可能性があります。

Microsoft Copilot in Azureが真っ先に回答してくれたように「画面サイズ」によって左ペインが消える（折りたたまれる）ことがわかりました。

## せっかくなので簡単に検証してみる

左ペイン消失の原因がわかったので簡単に検証してみました。

### 画面サイズの変更

検証の結果、見事に画面サイズによって左ペインが消えたり表示されることを確認できました。

![](/images/morihaya-20241227-azure-web-size/2024-12-26-22.03.28.gif)

### 文字サイズの変更

Microsoft Copilot in Azureは「画面サイズの変更」とだけ教えてくれましたが、フォントサイズでも同様に左ペインの表示に影響することがわかりました。
正確な計算式はわかりませんが、画面サイズとフォントサイズが一定以上の割合になった際に、左ペインが消える設定になっているようです。

![](/images/morihaya-20241227-azure-web-size/2024-12-26-21.55.46.gif)

## おわりに

以上が「目grepしやすいAzure Web Portalはフォントサイズとウィンドウサイズから」の紹介でした。
最近買った[CleanShot X for Mac](https://cleanshot.com/)の"Record Screen"機能が便利＆楽しいためgif動画を多めに利用してみました。

### 2024年の年の瀬ですね

さて、2024年は私にとってASTにジョインと同時にAzureに入門した年です。それまで触っていたAWSとの違いに驚き・発見・面白さ・楽しさを感じた年となりました。
JAZUGなどAzureを通して出会えた方も多く、学びと刺激を多くいただけました。全方位に大感謝です。

2025年はよりAzure知識を深めてiAEONをはじめとしたAzure上で動く当社サービス群により貢献していければと決意を新たにしています。

それではみなさまEnjoy Azure！良いお年を！！

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味をもった方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recuruiting.aeon.info/)
