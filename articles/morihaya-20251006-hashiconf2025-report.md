---
title: "HashiConf 2025 at San Francisco参加レポート"
emoji: "🔑"
type: "tech"
topics:
  - "hashicorp"
  - "terraform"
  - "zennfes2025infra"
  - "イベントレポート"
  - "aeon"
published: false
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。
加えて私は[HashiCorp ambassador 2025](https://www.hashicorp.com/en/ambassador/directory?q=Yukiya%20Hayashi)も任命いただいております。

さて、HashiCorpさんの年に1回のビッグイベント「HashiConf 2025」に参加したので会場の熱気や、現地のアメリカはサンフランシスコの雰囲気についてレポートします。

![](/images/morihaya-20251006-hashiconf2025-report/2025-10-05-10-50-12.png)

イベント公式URL:
https://www.hashicorp.com/en/conferences/hashiconf
＊URLに年(2025)が入っていないため、毎年最新のカンファレンスページに更新されるかもしれません

なおHashiCorp社はIBMメンバーとなりましたので、IBM社からも以下のURLでアナウンスがされています。
https://developer.ibm.com/events/hashiconf-2025-global-cloud-conference/

## TL;DR

- HashiCorpさんのビッグイベント「HashiConf 2025 at サンフランシスコ」に参加しました
- カンファレンスではHashiCorpプロダクトの進化を感じる多くの新機能やナレッジが紹介
- サンフランシスコの観光・治安情報もご紹介

## イベント概要

- イベント名: HashiConf 2025
- 会場: Fort Mason Center for Arts & Culture
- 期間: 2025年9月24日・25日・26日（3日間）

「HashiConf 2025」はTerraformやVaultの開発元で知られるHashiCorp社が毎年開催している国際カンファレンスです。
2025年の会場はサンフランシスコの「Fort Mason Center」で行われました。
日本人にとっても観光地として有名なフィッシャーマンズワーフから近い海岸沿いの素敵なロケーションで、建物を一歩出ると海風が心地よい素敵な場所でした。

@[codepen](https://codepen.io/morihaya/pen/QwydNed)

![](/images/morihaya-20251006-hashiconf2025-report/2025-10-05-10-54-36.png)
建物すぐ横には高い丘となっている「Fort Mason Park」があり、急な階段を登って会場を見下ろすと奥にはゴールデンゲートブリッジを眺めることができます。


また、今回は記念すべき10回目のHashiConfでもあり、過去9年分のHashiConfの思い出を振り返るグッズの展示もされていました。（展示の全体像を見たい方は[公式URL](https://www.hashicorp.com/en/conferences/hashiconf)の中段へ）

![](/images/morihaya-20251006-hashiconf2025-report/2025-10-05-10-58-35.png)

すでにYoutubeにライブ配信の動画も上がっていますので、雰囲気を感じたい方はそちらもご覧ください。（全セッションの動画ではありませんでした）

- [Video on Demand: Watch HashiConf 2025 | Day 1](https://www.youtube.com/watch?v=68DdUtHoG-I)
- [Video on Demand: Watch HashiConf 2025 | Day 2](https://www.youtube.com/watch?v=Wkw0X7-C6WU)

## 目玉のアップデート（忙しい方向け）

カンファレンスの日々を振り返る前に、HashiConf 2025で発表のあった新サービスやアップデートについて箇条書きでまとめておきます。さっとアップデートだけ知りたい方はこの節だけ流し読むと良いでしょう。

内容については良くまとまっていたIBM社のIBM Newsroomの以下のリリースをベースにしています。（本家Hashicorpさんのページよりも読みやすいと思った）

https://newsroom.ibm.com/2025-09-25-hashicorp-previews-the-future-of-agentic-infrastructure-automation-with-project-infragraph

### Infrastructure Lifecycle Management (ILM)

まずはインフラ関連です。（ILMとカテゴライズされています）

- Project infragraphの発表
  - IBMファミリーとなったHashiCorpが打ち出した新しいプロジェクトで、ハイブリッドクラウド全体のリソースの関係性等をリアルタイムに可視化する
- HCP Terraform StacksがGA
  - ひとつのTerraformコード群から複数の環境をデプロイ可能なStacksがついにGA
- HCP Terraform search (beta)の発表
  - listリソースや`terraform query`など用いて既存環境のインポートを促進されます。infragraphへの布石にもなってそうですね
- HCP Terraform actions (beta)の発表
  - Terraformコードのリソース内から柔軟に外部環境を呼び出せるactionsが使えるように。Red HatのAnsible連携が紹介されましたが、いろいろ使い所がありそうです
- HCP Terraform hold your own keyのGA
  - ユーザ管理の鍵を利用した暗号化によってガバナンスとセキュリティを強化できる機能のGA
- HCP Terraform MCP server (beta)の発表
  - HCP Terraformに対して利用できるMCP。個人的には一番テンションが上がった発表がこれです
- HCP Packer package visibility (beta)とSBOM StorageのGA
  - SBOMも利用しPackerイメージの追跡性を向上できるそうです
- HCP Terraform Run tasks integration into Cloudabiltyの発表
  - クラウドコストの最適化を支援するFinOpsプラットフォームでありIBMファミリーでもあるCloudabilityへRun tasksが連携可能に。（これはなぜかNewsroom内の記事にはありませんので、直前に対応されたのかもしれません）

### Security Lifecycle Management (SLM)

続いてセキュリティ関連です。（SLMとカテゴライズされています）

- HCP Boundary RDP credential injection (beta)の発表
  - WindwosサーバへRDPする際に、IDとPassをBoundaryが注入してくれる機能です。OSSのGuacamoleとかの雰囲気でしたサーバ管理者には嬉しいやつですね
- HCP Vault Radar Jira SaaS scanning (GA) and IDE plugin enhancement (beta)の発表
  - セキュリティスキャンのVault RadarがAtlassianのJiraにも対応し、加えてVSCodeなどのIDE向けプラグインでコーディング中にリアルタイムで検知してくれるようになります
- HCP Vault Radar MCP server (beta)の発表
  - Vault RadarのMCPが使えるため、自然言語でAIを利用した運用が可能になります
- HCP Vault Dedicated - AWS PrivateLink (GA)の発表
  - HCP VaultがAWS PrivateLinkに正式に対応
- HCP Vault Dedicated - Azure DNS (beta)の発表
  - HCP VaultがAzure DNSに対応。当社としてはこの機能を待望して何ヶ月も前からリクエストしていたため、本当に激アツな機能です。やっとSecret SyncがAzureでも使えるぞ...!
- HCP Vault Dedicated - secrets inventory reporting (beta)の発表
  - Secretの利用状況などのレポートが強化されます。これは嬉しい
- Vault Enterprise 1.21 (expected October 2025)の発表
  - セルフホストなVault Enterpriseの新バージョンでは、新しい暗号化ワークフローやAPIなどの強化が行われるそうです
- Vault MCP server (beta)の発表
  - AIからMCPを利用してVaultのシークレットを自然言語で操作可能になります

### アップデートへの初感

各HCPプロダクトへのMCPの発表によるAI時代への期待感と、当社にとっての「HCP Vault Dedicated - Azure DNS」のように、それぞれの利用者にとっては嬉しい機能のリリースが並んだ充実したアップデートになっていて、10周年を迎えたHashiConfにふさわしい内容だったと言えるでしょう。

目玉として扱われていたProject Infragraphについては、その方向性に正しさを感じつつも全貌がまだ見えていないため、今後の動向に静かな期待を寄せています。HCPlatformにログインすればあらゆるリソースが可視化される世界はきっと素晴らしいものになるはずです。

## HashiConf 2025の振り返り

以降は日付順にHashiConf 2025を振り返っていきます。アップデート情報について前段のまとめで紹介しているため現地ならではの体験について記載します。

### Day 0 (2025-09-24)

2025年9月24日(水)はカンファレンスの前日に当たる日でしたが、多くの国際カンファレンス同様にプレイベントが会場で行われていました。
具体的には以下の催しが実施されています。

- Certification exams
- AWS GameDay challenge
- Welcome reception

#### Ambassador Product Dayでの良い意味で日本人に厳しい環境

私は直接会場へは行かず、HashiCorpの本社で行われたHashiCorp Ambassadorの集い「Ambassador Product Day」に参加してきました。
このイベントはその名の通りHashiCorp Ambassadorに認定された方のみが参加可能なイベントで、毎年HashiConfのタイミングで行われているそうです。
世界各国から集まったHashiCorp強者に会えるまたとない機会ということでわくわくしながらの参加となりました。

会場のHashiCorp本社はカンファレンス会場からは離れており、サンフランシスコの中心部のSalesforce Park近くのビルにあります。
@[codepen](https://codepen.io/morihaya/pen/XJXpjpW)

ロビーのHashiConfロゴをみた時は感動し、受付の方に許可をとって写真を撮るほどでした。

https://x.com/morihaya55/status/1970882969574547692

参加者は40名程度で、実際にイベントが始まるとHashiCorpプロダクトをベースとしつつも今後のIT業界やAIの進化についてフリーのディスカッションが繰り広げられる濃密な空間となりました。
途中からは6名掛けのテーブルでのディスカッションがBoundaryやVaultといったテーマごとに行われ、各テーブルの代表がコメントを発表していくといった形式で進行します。

この時が、私がサンフランシスコ滞在中でもっとも英語力の課題を感じた瞬間でした。
前日までの観光や、1対1での互いに傾聴し合うようなシーンおいて最低限の意思疎通を英語で行える自負はありましたが、ITエンジニア同士の高度なコンテキストでの複数名でのディスカッションにおいては太刀打ちできないことを体験しました。結果としてすべてのプログラムにはとても参加できずに中座しましたが、あの苦しい時間を得られたことは非常に貴重な素晴らしい時間だったと言えます。
少なくとも帰国後のネイティブ言語でのコミュニケーションのハードルが大幅に下がる体感がありましたし、来年こそあのディスカッションに食らいつきたいとの強い気持ちが良いお土産です。

#### 夜は日本人会が開催されました

![](/images/morihaya-20251006-hashiconf2025-report/2025-10-05-15-46-49.png)

またこの日の夜はHashiCorp Japanチームの皆さんの呼びかけによって日本人参加者が会場近くのレストランに集まり、異国の地で親交を暖めることができました。

場所がサンフランシスコといった特別だからか、日中に極めて苦しい言語の壁を感じた後だからか、いつも以上にコミュニケーションが捗ったような記憶があります。
翌日からのHashiConfへの期待や各社のHashiCorpプロダクトの利用状況、CCoEやPFEといった取り組みについて意見交換や今後の展望について語り合うなど、有意義な場となりました。

あらためて企画してくださったHashiCorp Japanチームと参加されたみなさんに感謝です！とても楽しい夜でした！！

### Day 1 (2025-09-25)

Day 1である9月25日（木）からいよいよHashiConf 2025のスタートです。
Keynoteでは[#目玉のアップデート忙しい方向け](#目玉のアップデート忙しい方向け)の多くが紹介され、とくに当社として待望のAzure DNSとの連動が「HCP Vault Dedicated - Bring Your Own DNS」として紹介されてテンションが高まりました。

https://x.com/morihaya55/status/1971258348327797040

他にもTerraform Actionsの発表時にはRed HatからConsulting Technical Marketing Managerの[Hicham Mourad氏が登場](https://youtu.be/68DdUtHoG-I?t=2289)し、IBMファミリーとなったHashiCorpのTerraformとRed HatのAnsibleのより一層の協力関係がアピールされたように感じました。

Keynote後のDeep Diveセッションも面白く

AzureとTerraformをテーマにしたMicrosoftさんの発表からはCopilotの進化が伝えられましたし、
https://x.com/morihaya55/status/1971331679546638535

Air France-KLM Groupの大規模な事例紹介には圧倒されました。
https://x.com/morihaya55/status/1971343381688369152

#### Field CTO Stephen Wilson氏との対面ミーティング

HashiCorp Japanチームの粋な計らいで、Day 1のランチの時間を利用してField CTOのStephen Wilson氏と1時間弱ほどお話しする機会をいただきました。
事前に同僚氏たちからも意見を募集していて、以下のようなことユーザの要望としてお伝えさせていただきました。

- SSO周り
  - HashiCorp Cloud PlatformにSSOログインしても、HCP Terraformにログインできない課題
  - SCIMへの対応（IdP側の削除が反映されて欲しい）
  - JITによる初回ログイン時の自動ユーザ作成（これはHCP Terraformの方）
- HCP TerraformへのMCP実装（Day 2で発表されたので滑稽だったかもしれない）
- HCP TerraformのRun Taskの強化（New RelicとかPagerDutyとか対応していても良いのでは）
- HCP Terraformのパフォーマンス改善への提言
- HCP VaultのBYODNSってAzure対応だよね？（この時点ではAzureと表現されていなかったため）
- ユーザとしてわくわくしたいので、細かな機能追加も積極的にニュースリリースで発信してほしい
- HashiCorpプロダクトとIBMプロダクトの今後の連携について

Wilson氏は私の拙い英語に嫌な顔をひとつせずに真っ直ぐに話を聞いてくれて、とくに「HashiCorpプロダクトとIBMプロダクトの今後の連携について」はIBM VerifyとHashiCorp Boundaryを組み合わせたセキュアな認証認可の展望などを教えていただきました。

振り返ってみると、アイスブレイクと自己紹介のついでにF1が好きかと突然質問してしまうなど謎の行動もありましたし（角田選手と名前が似ているところにつなげたかった）、会社の規模感やシステム構成について説明せずにいきなり質問していくなど反省も多い内容でしたが、少なくとも私にとっては素晴らしい経験と時間になりました。
日本語ですが改めて誠実に対応いただいたWilson氏への感謝と、その場をセッティングしてくれたHashiCorp Japanチームにお礼を申し上げます。

#### Day 1終了後はパーティー

次の予定があったため私は長くは参加しませんでしたが、Day 1終了後には「Evening social in the Fort Mason courtyard (outdoors - don't forget a coat!)」と題したパーティーが会場外で行われ、食事のための屋台や広場にはラダーボールなどちょっと遊べる空間が用意されて楽しい空気となっていました。

![](/images/morihaya-20251006-hashiconf2025-report/2025-10-06-00-59-20.png)

### Day 2 (2025-09-26)

最終日でもあるDay 2のKeynoteは、Day 1に比べれば新機能や新プロダクトの発表は少なくシンプルな印象でした。
AIを中心にしたテーマでゲストが入れ替わりでいい話をされ、HashicorpプロダクトのMCPが紹介されました。

現時点では以下のプロダクト群がMCPに対応しており「Agentic ready」である旨が提示されます。

- Terraform
- Vault
- Vault Radar
- Consul

また、今後の目玉となるであろうProject infragraphが満を持して発表され、あらゆるハイブリッドなインフラリソースがHCPの元で可視化され管理される未来が提示されました。

#### 一番盛り上がったのはMitchell Hashimoto氏の登場

シンプルと表したDay 2のKeynoteですが、全会期中で一番盛り上がる瞬間がありました。
それがMitchell Hashimoto氏の登場です。

https://youtu.be/Wkw0X7-C6WU?t=3812

HashiCorpのFounderでもありTerraformをはじめ多くの素晴らしいプロダクトで世界を変えてきた彼の登場に、HashiConf会場が揺れんばかりの歓声が上がりましたし、自分も拍手と声を出していました。

https://x.com/morihaya55/status/1971625982298816532

Hashimoto氏はHashiCorpに戻るわけではなく、エモい動画で紹介されたビッグプロジェクト（名称はまだない？）へパートタイムで協力していくとの発表がありました。
大半の参加者の気持ちを代弁すると「細かい話は置いてあのMitchell HashimotoがHashiConfの壇上にいてArmon Dadgar氏と握手しているのが感動的」といった感じでした。

今でもHashiCorpの[Aboutページ](https://www.hashicorp.com/en/about)には2012年創業当時の二人の写真や動画が掲載されておりますので比べてみると歴史を感じることができるでしょう。

#### Days 2の各セッションもためになった

Keynote後のセッションも学びとなるものがありました。

Terraform Searchのデモでは`list`リソースと`terraform query`を利用したインポートまでの流れがわかりやすく提示されました。

https://x.com/morihaya55/status/1971643864575525145

とくに興味を引いたのがMCP関連のセッションで、Day 2発表されたばかりのHCP Terraform MCPの紹介です。
以下のスライドでは当該MCPで利用可能なToolの一覧が提示されていて、私も待望のplan結果を取得できそうな気配がひしひしと伝わります。

https://x.com/morihaya55/status/1971707846242029682

こうして、最後のセッションまで充実した楽しいHashiConf 2025となりました。

私は慣れない環境で英語を浴び続けた結果疲れ果ててしまい、最終セッション終了後は近くのSF Brewing CO.に駆け込んでビールで疲労を癒すムーブをかましてしまいます。

https://x.com/morihaya55/status/1971723582716993745

とても惜しいことに、最後まで会場に残っていれば日本人メンバーとHashimoto氏とでの集合写真の記念撮影のタイミングが偶然発生していたそうで、ビールに負けて貴重な機会を逃したことを少し悔やんでいます。（ただビールは最高でした）

## San Franciscoのレポート

せっかくなのでツーリスト目線で見てきたサンフランシスコの観光状況も紹介します。

### 治安について

まずは治安についてです。率直に言ってここ数年のサンフランシスコの治安について自分はあまり良い印象を持っていませんでした。
Covid-19のパンデミック後、リモートワークの増加などの影響で少なくないテック企業がサンフランシスコから撤退した結果、街中の治安が悪化していると聞いていたためです。
そのため盗難対策として、財布とは別の腹巻状のサブバックにパスポートとクレジットカードと少額の現金を入れて備えていました。

![](/images/morihaya-20251006-hashiconf2025-report/2025-10-05-11-52-23.png)

しかしながら私自身の5日間の滞在においては（訪れた場所にもよるでしょうが）夜間に一人で歩いて危険を感じることはほぼありませんでした。
私の移動範囲は「Union Square」近くのホテルを中心としており、その周辺は大型のApple Storeもあり表参道のような小洒落た雰囲気があります。

@[codepen](https://codepen.io/morihaya/pen/qEbRNNv)

一度は夜間に会場である北の「Fort Mason Center」から中華街を抜けて徒歩（ジョグも少し）で帰りましたが、途中にはバーもあり人通りもそれなりにあり、またコンビニっぽいグロッサリーストアも点々としており補給にも困りませんでした。
後述する音楽ライブや芝居鑑賞後の遅い時間であっても街は明るく、警察車両もパトロールなのかよく見かけたため恐怖感を覚えることはありませんでした。

例外としては時折薬物中毒とおぼしき方が交差点で奇声をあげている場面に数回遭遇しましたが、こちらから直接関わらなければ問題はありませんでした。

総じてサンフランシスコ（Union Square周辺）は夜も含めて安心して歩ける街との印象を持ちました。
もちろん「Tenderloin」地区のように治安がよくないとされる場所や、暗い路地は避けた上での感想ですので、行かれる方は警戒を怠らないようにしてください。
Uber, Lift, そしてWaymoなどタクシーサービスは非常に充実していますから積極的に利用するのが安心です。

### オススメなスポット

フリーな日や夜間の空き時間を利用していくつか観光もしてきましたので、そちらの中でもオススメなスポットを紹介します。

#### Waymo - 自動運転のタクシー

スポットではありませんがサンフランシスコ観光として完全無人な自動運転タクシーであるWaymoは外せないでしょう。
利用開始も簡単でGoogleアカウントがあればスマホアプリを入れてアカウントを紐づけるだけです。
他のタクシーサービスと比べて若干割高となっていますが、完全無人の快適空間を占有できるとともに自動でハンドルがぐるぐる回って目的地まで移動できる体験は一度はしておくべきだと断言します。

https://x.com/morihaya55/status/1970214478261395617

利用範囲も日々拡大しているようでサンフランシスコ市内はほぼカバーされているようですし、[サンフランシスコ空港での営業許可も取得した](https://waymo.com/blog/?modal=short-all-systems-go-at-sfo-waymo-has-received-our-pilot-permit)とのことで、近い将来は空港と市内をWaymoで快適に移動することができそうです。（地下鉄を利用した方が圧倒的に安価ですが）

Waymo車内のカーステレオと自身のSpotifyを連動することができ（現在は[Youtube Musicも対応](https://waymo.com/blog/?modal=short-youtube-music)済み）車内でカラオケをした方もいるとか...。以下の写真は私の推しポッドキャスト「COTEN RADIO」を試しに流してみた写真で、アメリカ西海岸で自動運転の車内で聴くのは不思議な体験でした。

![](/images/morihaya-20251006-hashiconf2025-report/2025-10-05-13-19-41.png)

#### フィッシャーマンズワーフ周辺

定番ですが、フィッシャーマンズワーフの周辺は景観もよくお店も多くあり観光にはもってこいです。

近くの船着場からはゴールデンゲートブリッジの下を周遊するクルーズも出ており、天気が良ければ気持ちのよい体験が得られるでしょう。

個人的にはアルカトラズ島を裏側を近くから眺められたことが良い思い出となっていて、いつかの映画を観直したくなりました。

写真の観覧車も相まって、どこか横浜っぽさも感じる素敵なエリアです。

![](/images/morihaya-20251006-hashiconf2025-report/2025-10-06-02-21-38.png)

エリアの奥には潜水艦の展示もあり、少々高額ですが狭い艦内通路を歩けるため興味のある方にはたまらない展示となっていました。

#### ナパバレーでのワインツアー

ワインが好きで丸一日の空きが確保できるようであれば、サンフランシスコ市街を離れてナパバレーのワインセラーを巡るツアーがオススメです。

2日ほど前に行く計画を立てたせいか日本の旅行代理店では予約できませんでしたが、[Viator](https://www.viator.com/tours/San-Francisco/Napa-and-Sonoma-Wine-Country-Tour/d651-2660SFOWIN)というサイトで簡単に予約ができました。

市街とはまた違った風景とワイナリーで解説を聴きながらいただく美味しいワイン、そしてゴールデンゲートを渡るのはツアーならではの経験かもしれません。大型バスで移動するためワイナリーを経るたびに陽気になっていく他のお客さんの様子も楽しいものでした。

![](/images/morihaya-20251006-hashiconf2025-report/2025-10-06-02-15-38.png)

#### 映画館AMC Metreon 16

私は映画を観ることが好きで、とくにイオングループに入ってからはイオンシネマに毎週のように通っています。
サンフランシスコ滞在中にアメリカの映画館を体験してみようと思い訪問したのがAMC Metreon 16です。

いわゆるシネコン型で大型の商業施設の一角を有していて、夜間でも安心して利用できました。
売店もありポップコーンが紙袋に入っているのもアメリカっぽさを感じてよかったです。（日本は紙でできた箱やバケツが多い）
映画館の大型スクリーンで字幕無しの英語の映画を観るのは日本では難しいため、ヒアリングの練習にもなりました。

![](/images/morihaya-20251006-hashiconf2025-report/2025-10-06-02-34-19.png)

#### ベーグルよりもコーヒーに感動 Posh Bagel

サンフランシスコの食事は、期待値を超えて何を食べても美味しいものばかりでした。（金額とカロリーと量はパンチがあります...）
その中でもとくに印象に残ったのがホテル近くにあった「Posh Bagel」というベーグル屋さんです。

平日は朝の7:00から空いており、オススメらしいBLTサンドを"Take away"していただきました。（テイクアウトとは言われなかった）

メインであるベーグルもとても美味しいのですが、一緒に買ったハウスコーヒーが日本に帰った今も飲みたくなるほど印象的でしたので、ベーグルとコーヒーがお好きな方はぜひ訪れてみてください。

![](/images/morihaya-20251006-hashiconf2025-report/2025-10-06-02-41-42.png)

他にも演劇やジャズやライブなど楽しい場所へも訪れましたが、観光ブログになってしまうためこの辺りで終わりにします。

## おわりに

以上が「HashiConf 2025 at San Francisco参加レポート」です。

約6年ぶりに海外のカンファレンスへ参加させていただきましたが、日本では味わうことが難しい種類の刺激を溢れるほど受けることができ、価値観が揺さぶられ目から鱗が落ちる日々を過ごすことができました。
その中でも「国の違いと言語の壁」を体感するのは、日本国内でそれを感じる機会が少なく、自身のアイデンティティがグラつくほどの有意義な体験だったと感じています。

また、IBMファミリーとなりAI時代におけるHashiCorpの今後の展望や、当社を含めたHashiCorpプロダクトユーザ達の熱量を直接感じられたことも素晴らしい経験となりました。

改めて少なくない渡航費用を支援してくださる当社およびイオングループの懐の広さと深さに感謝しつつ、業務において貢献していければと決意しています。


それではみなさま、Enjoy HashiCorp Products!

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味を持った方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recruiting.aeon.info/)
