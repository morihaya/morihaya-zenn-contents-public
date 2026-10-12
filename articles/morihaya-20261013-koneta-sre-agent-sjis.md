---
title: "小ネタ: Azure SRE AgentのナレッジソースにShift_JISのWebページを追加するとエラー"
emoji: "🔍"
type: "tech"
topics:
  - "azure"
  - "sre"
  - "azuresreagent"
  - "aeon"
published: true
published_at: "2026-10-13 08:00"
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。

当チームではAzure SRE Agentの検証を進めており、特にAzure実データを利用した共通のドメイン知識を持った上での調査・検討処理で手応えを感じています。
本記事はAzure SRE Agentを検証する中で発見した小ネタです。ナレッジソースへ追加できないURLが1つあり、理由が意外で面白かったので書いておきます。（きっと遠くない日にFixされるでしょう！）

## TL;DR

- Azure SRE Agentの検証を始めていて、手応えを感じつつある
- 「ナレッジソース」は、ファイルやWebページをSRE Agentの参照資料として追加する機能
- あるURLだけが必ず追加に失敗した、その原因はページの文字コードがShift_JISだった（そのうちFixされるはず）

## ナレッジソースは、調査の材料をAgentへ渡す場所

Azure SRE Agentには「コンテキスト」としてAgentに知識を与えることができます。
コンテキストは以下の3つから構成されています。

- コードアクセス: GitHubやADOなどコードリポジトリを追加する
- ナレッジソース: ファイルやURLを追加する
- 管理対象リソース: Azureリソースへのアクセスを追加する

この中でもナレッジソースは、調査で参照してほしい資料をAgentへ渡しておく機能です。
ポータルからは、ファイルのアップロードと、公開WebページのURL追加ができます。

Webページは、URLと名前と説明（任意）を入れて追加します。

Agentはログイン処理などはできず、匿名として該当の1ページを取得し、取得できた時点の内容をインデックスします。
認証ができない他は30秒タイムアウト制限などの制限がありますが、詳細はドキュメントで確認することを推奨します。（進化も早いため最新情報を推奨！）

https://learn.microsoft.com/ja-jp/azure/sre-agent/add-web-page-knowledge

## あるURLだけ、追加が必ず失敗する

ブラウザでは普通に開ける公開ページを、ナレッジソースへ追加しようとしました。同じURLでは、何度やっても失敗します。

![ナレッジソースへWebページを追加する画面](/images/morihaya-20261013-koneta-sre-agent-sjis/add-web-page.png)

表示されたメッセージは次のとおりです。

> Web ページを追加できませんでした: An unexpected error occurred while fetching the web page.

![Webページ追加時のエラー画面](/images/morihaya-20261013-koneta-sre-agent-sjis/add-web-page-error.png)

ドキュメントには、URL形式の不正、403、404、タイムアウト、中身が空、といった失敗が挙がっています。今回のメッセージは、その表には見当たりませんでした。

https://learn.microsoft.com/ja-jp/azure/sre-agent/add-web-page#step-4-add-the-web-page

検証であるため急ぎでもなく、Webページの追加作業自体も大した手間ではないため「なんか調子悪かったのかも」とタイミングをずらして数回やってみたが同じ事象が続きました。

仕方ないのでAzure SRE Agent自身も利用しながら調査しました。

## 匿名のGETは403ではなかった

ドキュメントには、自動リクエストを弾くページは403になるとあります。今回のメッセージはそれとは別でしたが、念のため匿名のGETも確認しました。

User-Agentを外した場合も、curl、python-requests、Goのクライアントを名乗った場合も、応答はHTTP 200でした。（このあたりの調査はAI Agentさんがシュッとやってくれます）

## 原因は、ページの文字コードがShift_JISだった

応答ヘッダのContent-Typeは `text/html; charset=S-JIS` でした。HTMLのmetaは `shift-jis` です。本文はShift_JISとして読めます。

Shift_JISは、かつて日本語のWebで使われてきた文字コードです。

今のページの多くはUTF-8ですが、Shift_JISのまま配信されているページも残っており、今回追加したかったページがそうでした。
見分けが難しいのは、ChromeやEdgeのようなブラウザは問題なく表示できる一方、Azure SRE Agentのナレッジソースの追加だけが、取得中の予期しないエラーで止まります。

さらに上述したように、メッセージに文字コードの話は出てきません。
このあたりのエラーメッセージの不足感は他にも感じることがあり、今後のAzure SRE Agentの成熟に期待するポイントです。

## 参考：簡易的な検証を行った

元のページ以外でも再現するか確認したくて、自分個人の公開S3バケットにテスト用HTMLを置きナレッジソースへ追加してみました。表示上の日本語は同じです。

| オブジェクト（Link） | Content-Type | 本文 | 追加 |
| --- | --- | --- | --- |
| [index-utf8.html](https://s3.ap-northeast-1.amazonaws.com/public.morihaya.tech/index-utf8.html) | `text/html` | UTF-8 | できた |
| [index-shift-jis.html](https://s3.ap-northeast-1.amazonaws.com/public.morihaya.tech/index-shift-jis.html) | `text/html; charset=Shift_JIS` | Shift_JIS | 失敗 |
| [index-sjis.html](https://s3.ap-northeast-1.amazonaws.com/public.morihaya.tech/index-sjis.html) | `text/html; charset=S-JIS` | 上と同一のShift_JIS | 失敗 |

失敗した2つの本文は同じバイト列です。違うのは応答ヘッダのcharsetだけで、正式な `Shift_JIS` と、元ページと同じ `S-JIS` です。どちらも最初と同じメッセージで失敗しました。UTF-8のページは、同じバケットなのに登録できました。

このエラーは、ホストの拒否や403では説明できません。charsetを正式な `Shift_JIS` にしても落ちたので、`S-JIS` の表記だけが原因でもありません。

Shift_JIS側は元ページに寄せてHTML 4.01にし、metaは `charset=shift-jis` だけにしています。UTF-8側はHTML5のままなので、doctypeまで揃えた比較ではありません。それでも、本文が同じ2つが同じく落ちたので、原因は本文がShift_JISであることだと考えています。

## おわりに

以上が「小ネタ: Azure SRE AgentのナレッジソースにShift_JISのWebページを追加するとエラー」の記事でした。

進化の速いAzure SRE Agentだと、今回のようにドキュメントに挙がっていないエラーに出会うことがあります。
それが予想外だったSJISだったとの点で今回のエラーは面白く感じました。
面白がるだけでなく、関係者にフィードバックもしており近いうちに解決するだろうと楽観しています。

もし同じメッセージで止まった方がいたら、対象ページの文字コードも確認してみてください。

それではみなさまEnjoy Azure SRE Agent！

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味をもった方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recruiting.aeon.info/)
