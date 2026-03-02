---
title: "ブラウザ開発ツールの'Copy as cURL'が調査にとても便利"
emoji: "🛠️"
type: "tech"
topics:
  - "curl"
  - "edge"
  - "chrome"
  - "aeon"
published: true # false or true , スケジュール公開の場合はfalseで予約して後からtrueにFix必要
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。

本記事ではChromeやEdgeブラウザで利用できる「Copy as cURL」機能が各種調査にとても便利だったので紹介します。意外と同僚氏の何人かも知らなかったので、きっと誰かの役に立つはずです。

## TL;DR

- ブラウザで開いたページを、開発ツールを使って「Copy as cURL」できる
- User-Agentなど各種ヘッダーを取り揃えた `curl` コマンドがクリップボードに取り出せる
- 便利なユースケースをいくつか紹介

## 「Copy as cURL」とは

「Copy as cURL」は、簡単に言えば「現在開いているページに対してブラウザが送ったHTTPリクエストを、`curl`コマンドとしてコピーする」機能です。

### `curl` コマンド

`curl` コマンドについても簡単に紹介すると「URLを指定してサーバーとの間でデータを送受信するツール」と`man`の冒頭で紹介されています。以下は`man`コマンドからの引用です。

> curl is a tool for transferring data from or to a server using URLs. It supports these protocols: DICT, FILE, FTP, FTPS, GOPHER, GOPHERS, HTTP, HTTPS, IMAP, IMAPS, LDAP, LDAPS, MQTT, POP3, POP3S, RTMP, RTMPS, RTSP, SCP, SFTP, SMB, SMBS, SMTP, SMTPS, TELNET, TFTP, WS and WSS.

シンプルな使い方の例が以下で、とりあえず応答が来ればサーバが生きてそうだ、などと判断ができます。

```bash
$ curl https://example.com
```

### 「Copy as cURL」でヘッダー組み立てを自動化

では主題の「Copy as cURL」は何が嬉しいのか。それはリクエストヘッダーの組み立てをブラウザ側が行った通りにコマンドにしてくれるからです。

具体例として上記と同様に https://example.com をEdgeブラウザで開いたとしましょう。一見すると `curl https://example.com` と同じように見えるかもしれません。

しかし実際には「リクエストヘッダー」と呼ばれる多くの情報をブラウザが付与した状態でリクエストを行っています。
有名なところでは「User-Agent」ヘッダーがあり、利用しているブラウザやモバイルアプリの情報を格納するヘッダーとして広く使われています。

実際に私のMacBookでEdgeブラウザをプライベートモードで起動し、https://example.com を開いたときのリクエストを開発ツールのNetworkで確認した画面が以下です。赤枠部分が「Request Headers」として表示されており、片手では足りない数のヘッダーがリクエスト時に付与されていることがわかります。

![request-headers](/images/morihaya-20260220-koneta-copy-as-curl/2026-02-20-02-07-29.png)

リクエストヘッダーの付与は `curl` コマンドでも`-H`オプションとして対応しており`curl -H '<HEADER_NAME>: <VALUE>' <URL>` のように記述できます。これを実際のブラウザ同様のリクエストヘッダーで行う場合、何個も`-H`オプションを書く必要があり、人間がやるにはなかなか大変な作業です。

それを簡単にしてくれるのが今回紹介する「Copy as cURL」です。
実際に利用して取得したコマンドを以下に紹介します。とてもではないですが手動で組み立てる気にはなりませんね...。

```bash
curl 'https://example.com/' \
  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
  -H 'accept-language: ja' \
  -H 'cache-control: no-cache' \
  -H 'pragma: no-cache' \
  -H 'priority: u=0, i' \
  -H 'sec-ch-ua: "Not:A-Brand";v="99", "Microsoft Edge";v="145", "Chromium";v="145"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  -H 'sec-fetch-dest: document' \
  -H 'sec-fetch-mode: navigate' \
  -H 'sec-fetch-site: none' \
  -H 'sec-fetch-user: ?1' \
  -H 'upgrade-insecure-requests: 1' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0'
```

### 「Copy as cURL」の利用の仕方

使い方は簡単です。

1. ChromeやEdgeブラウザで開発ツールを開く
2. ブラウザでWebページを開く
3. 開発ツールの[Network]->Nameで[対象のパスorドメイン]->右クリック->「Copy」->「Copy as cURL」をクリック

![copy_as_curl](/images/morihaya-20260220-koneta-copy-as-curl/2026-02-20-02-22-42.png)

たったこれだけで複雑で数の多いリクエストヘッダーを備えた `curl` コマンドが手に入ります。

## 想定ユースケース

### スクリプトなどで自動化する

コマンド化することで、運用スクリプトやCI/CDパイプラインでの利用が可能になります。
たとえば、定期的なヘルスチェックやステージング環境での動作確認など、手動で行っていた作業をスクリプト化できます。

また、cronなどの定期ジョブでの定期監視や、デプロイ後の自動テストにも活用できます。ブラウザと同等のリクエストを送れるためより実環境に近いテストが実現できますが、不要なヘッダーが増えてメンテナンスコストが上がることも考慮して、必要最低限でやると良いでしょう。

### トラブル時の調査

WAFやCDNまたはアプリケーションでは、正しいヘッダーが設定されていない場合にリクエストをブロックする処理を自動or意図的に行うことがあります。
これらの場合に、ブラウザが生成した正しいヘッダーをコマンドとして取得できると調査がしやすいです。

とくにアプリケーション側がAKSのPod上にある場合などは、GUIのブラウザを立ち上げるのは簡単ではありませんし、`curl`コマンドが頼りになります。

具体的なシナリオとしては以下のようなケースがあります。

- 「ブラウザでは見れるのにcurlだと403が返る」ケース
  - WAFがUser-Agentやその他のヘッダーをチェックしている場合、シンプルな `curl` コマンドではブロックされることがあります。「Copy as cURL」で取得したコマンドなら、ブラウザと同じヘッダーでリクエストできるため、問題の切り分けが容易になります
- Pod内からの疎通確認
  - Kubernetes環境でPod間通信の問題を調査する際、`kubectl exec` でPodに入り、コピーした `curl` コマンドを実行することで、実際のブラウザリクエストを再現した調査が可能です

### 認証が必要なAPIコールの再現

「Copy as cURL」はCookieや認証トークンも含めてコピーしてくれます。これにより、ログインが必要なページやAPIエンドポイントへのリクエストも再現できます。

OAuth認証後のAPIコールや、セッション管理されたページのデバッグに非常に便利です。ただし、認証情報が含まれる場合があるためコマンドの取り扱いには注意が必要です。チャットツールなどに貼り付ける際は、トークンやCookie部分をマスクすることをオススメします。

### チームメンバーへの問題共有

「この操作をするとエラーになる」という報告を受けた際、「Copy as cURL」でコマンドを共有してもらえば、同じリクエストを手元で再現できます。

そうすることで環境差異による問題の切り分けや、特定のヘッダーが原因かどうかの調査がスムーズになります。

当社の環境特有かもしれませんが、ブラウザを用いた社内からの外部へのリクエストはPACファイルの内容によって利用するプロキシが変わることがあります。一方で、何も指定しない`curl`は通常PACを参照しないためブラウザと経路が変わり切り分けとして有効な場合があるのです。

## おわりに

以上が「ブラウザ開発ツールの'Copy as cURL'が調査にとても便利」の記事でした。

本記事で紹介した「Copy as cURL」は、地味ながらも知っていると知らないとではいざという時に大きな差が出る機能です。私自身、同僚氏に教えてもらう最近までその存在を認識していませんでした。

トラブルシューティングや自動化の場面で「あ、これ使えそう」と思い出していただければ幸いです。

それではみなさまEnjoy cURL！

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味をもった方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recuruiting.aeon.info/)
