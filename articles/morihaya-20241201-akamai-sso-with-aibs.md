---
title: "Akamaiユーザ管理をAIBS＆ASTで協力してSSO化しました（新生AST以前の話）"
emoji: "😆"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: # タグを指定する
  - "sso"
  - "entraid"
  - "Akamai"
  - "aeon"
published: true
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。

本記事は[AEON Advent Calendar 2024](https://qiita.com/advent-calendar/2024/aeon)の1日目の記事です。

そして記事を公開する2024/12/01は、私の所属するASTが[新生イオンスマートテクノロジー株式会社](https://www.aeon.info/news/release_90445/)として始動する記念すべき日でもあります。
ニュースリリースにもある通り、新生ASTは従来のASTと「イオンアイビス株式会社（以下、AIBS）のIT事業を分割・統合」によって誕生します。

本記事では新生ASTとして融合する以前から、ASTとAIBSのIT部門が協力して成果を出してきた事例のひとつを紹介します。

## TL;DR

本記事を箇条書きでまとめると以下です。

- CDN/WAFサービスとしてAkamaiを利用しており、契約・管理はAIBSのIT部門が行っている
- ASTはAIBSから専用のAkamai CDN/WAF設定を切り出してもらっている
- ASTのSREをはじめとしたASTのAkamai利用ユーザは、ASTに関係するAkamai設定のみを参照・操作が可能
- そのASTユーザの追加・更新・削除は、Excel申請書で行ってきた
- Akamaiを利用するプロダクトおよびチームの追加が見込まれ、Excel申請書を廃止しSSOへ切り替えを決断
- AIBSとASTの軽快な連携により短期間でのSSO移行を達成した

## 背景

### これまではAkamaiのユーザ作成にExcel申請書をメールでやりとり

当社ではCDN/WAFの機能に[Akamai社](https://www.akamai.com/ja)のサービスを採用しています。（Azure Front Doorなどその他のCDN/WAFを活用しているシステムもあります）

Microsoft365など、その他の多くのSaaS製品やプロダクトと同様にAkamaiの管理はAIBS社のIT部門にて行われてきました。
ASTが開発・運用する各システムでは、AIBSから払い出されたCDNプロパティおよびWAF設定を利用してサービスを提供しています。

AkamaiにはWebブラウザから各種変更や情報にアクセスできる「Akamai Control Center」があり利用するためにはログインアカウントが必要になります。
私たちASTのSREチームを含む「ASTでAkamai Control Centerを利用したいユーザ」は、Excelの申請書をAIBSのIT部門に提出してアカウント作成を行なってもらう必要がありました。

![](/images/morihaya-20241201-Akamai-sso-with-AIBS/2024-12-01-00-36-23.png)

これまではCDNやWAFのチューニングを行うメンバーは限られており、ユーザ作成・削除の頻度は少なくExcel申請書のやり取りでも問題ない状況でしたが、Akamaiを利用したプロダクトのリリースによる関係者の増加や、トラフィックレポート活用を見据えると従来のやり方ではASTとAIBS双方にとって運用が煩雑になる可能性が高いと考えていました。

### SSO導入の決断

そこで、私たちASTのSREチームとAIBSのIT部門であるDX基盤チームが協力し、Akamaiのユーザ管理をSSO（Single Sign On）に切り替えることを決断しました。

正直に申し上げて、当初私はこの提案をAIBS側へ行うにあたり「従来のやり方を変えることに対して抵抗を受けるのでは...?」と不安な気持ちでいっぱいでしたが、紹介を受けて相談に乗ってくれたDX基盤の新川さんは文字通りノリノリで提案を聞いてくれて、初回のMTGで大まかな設計まで完了する勢いで話が進んでいったことに喜びと驚きを覚えました。
特筆すべきは会議前にざっくりとした方針の叩き台資料が用意されており、会議後の翌日にはその修正版が議論の内容を取り込んだ形で展開されてきたことには脱帽でした。
（なおこのありがたい流れは、同じSREチームでAIBSにも知人の多い岩崎さんの協力も大きかったことを明記します、サンキュー岩崎さん！）

![](/images/morihaya-20241201-Akamai-sso-with-AIBS/2024-12-01-02-58-19.png)

## Akamaiユーザ管理へSSOの導入

### SSOによる単純なユーザ認証までは数日で実装できた

こうして実装を開始した私たちは、テストユーザの作成までは大きな問題なく進めることができました。
手順はAkamai社のtechdocsより[Get started with SSO with SAML](https://techdocs.akamai.com/iam/docs/get-started)を参照しています。（参照のためにはAkamai Control Centerへログインが必要です...一般公開してほしい）

IdPとしてはASTテナントのMicrosoft Entra IDを利用することで、New RelicやPagerDutyでも行っているAzure DevOpsとHCP TerraformのCI/CDのフローでAkamaiのユーザ管理も行えるようになりました。

![](/images/morihaya-20241201-Akamai-sso-with-AIBS/2024-12-01-01-13-26.png)

### 権限のコントロールで課題が発生、複数Enterprise ApplicationだとNG

しかし、実際の運用に向けて実装を進めたところ大きな課題に遭遇しました。
具体的にはグループの制御が当初の設計「Enterprise Applicationを権限別に作成する」方法ではできませんでした。

ASTが希望するAkamaiユーザについては以下のような種類の権限を付与したいと考えていました。

- 参照のみユーザ: 一般開発者向け、トラフィックレポートや設定をみることができる
- 参照＋キャッシュパージユーザ: 運用も行うユーザ向け
- 変更もできるユーザ: SREチームなど設定変更に責任を負うユーザ向け

そのため、ASTのEntra IDに権限に対応したEnterprise Applicationを作成し、必要に応じてグループをそれぞれに紐づけていく設計を考えましたが、AIBSのAkamai側で2つ目を登録する際に以下のエラーが発生しました。

![](/images/morihaya-20241201-Akamai-sso-with-AIBS/2024-12-01-01-34-41.png)

> Entity ID already exists

文字通り同じ"Entity ID"がすでに登録済みであるため登録できない問題が生じたのです。
この方針は過去にAWSの"AWS IAM Identity Center"(旧名AWS SSO)で動作していたものでしたが、Cloudが違えば当然仕様も異なり、設計を見直す必要がありました。

![](/images/morihaya-20241201-Akamai-sso-with-AIBS/2024-12-01-01-58-45.png)

### 一つのEnterprise Applicationでグループ名をマッピング

ドキュメントの再読み込みと切り分けを経て、結果として以下の方式でEntra IDのグループとAkamaiの権限（Role）をマッピングすることが可能となりました。

- Entra IDにAkamai Role別にGroupを作成
- Entra IDにEnterprise Applicationをひとつのみ作成
- そのEnterprise ApplicationにGroupをIAM登録
- Entra IDのユーザの所属するGroupの名前と、AkamaiのRoleをAkamaiのTemplateでマッピングさせておく
- ユーザーがSSOでAkamaiへログインすると、そのユーザが所属するEntra IdのGroupの属性値をみて、AkamaiのRoleが付与される

![](/images/morihaya-20241201-Akamai-sso-with-AIBS/2024-12-01-02-10-41.png)

#### 補足: Entra ID側のGroup属性の設定が重要

細かい話になりますが私がもっともハマったポイントがEntra IDのEnterprise Applicationの設定のAkamaiに渡す属性（Claims）のGroup設定でした。
同様にハマる方がいるかもしれないため参考のために明記しておきます。

SSO全般に言えることとして、どの属性を利用してIdPからSP(Service Providerの略で今回はAkamaiを指す）にユーザ情報を渡すかが大変重要です。
今回のケースではユーザが所属するGroup名をAkamai側のRole名と紐づける必要があり、その設定に苦労しました。

具体的には以下の図のような設定になっています。（灰色部分は無視可能かつ混乱を呼びかねないためマスク）

![](/images/morihaya-20241201-Akamai-sso-with-AIBS/2024-12-01-02-19-46.png)

さらにGroupについては以下の設定も行なっています（大変重要）。

- `Group assigned to the application`: このEnterprise ApplicationにアタッチされたグループのみをAkamaiへ送る
- `Source attributes: Cloud-only group display names`: IDではなくグループ名をAkamaiへ渡す

![](/images/morihaya-20241201-Akamai-sso-with-AIBS/2024-12-01-02-20-41.png)

これらの設定でようやくEntra IDのグループと、AkamaiのRoleを紐づけることができました。

### その他の細かい課題も都度乗り越える

他にも以下のような細かい課題が生じましたが、チャットとMTGを併用しながら軽快に解決することができました。

- 認証はできるが、Just-In-Time provisioningが作成できない
  - -> 作成可能ユーザのメールドメインの制限がかかっていたため、AST側のユーザメールアドレスを一括で見直した
- Entra ID上のExternalユーザで認証できない
  - -> 特殊例として放置しつつ、本当に必要なら通常のEntra IDユーザを作成する

## Akamai SSOを導入してからの成果

こうして無事にAkamaiのユーザ管理をSSOへ変更した結果、関連するプロダクトチームへのAkamaiログイン権限の展開が順調に進みました。
具体的にはExcel管理しか行われていなかった頃と比較し、AkamaiにログインできるASTのユーザは `480%` まで増加しています。

![](/images/morihaya-20241201-Akamai-sso-with-AIBS/2024-12-01-02-35-44.png)

引用元資料: [BizDevOps加速のカギ - レバテック×イオン ~事業会社を支える開発組織のBizDevOps戦略~](https://speakerdeck.com/aeonpeople/the-key-to-accelerating-bizdevops?slide=30)

## おわりに

以上が「Akamaiユーザ管理をAIBS＆ASTで協力してSSO化しました（新生AST以前の話）」の内容です。
SREのプラクティスのひとつに[Eliminating Toil(トイルの撲滅)](https://sre.google/workbook/eliminating-toil/)があります。
今回のAkamaiユーザ管理へのSSO導入によって、Excel申請書によるやり取りがASTとAIBS双方で不要になったことはまさに"Eliminating Toil"な取り組みと言えます。
この取り組みが行われたのはまだ夏を感じられる頃の話ですが、会社をまたいで協力できた素晴らしい案件として強く記憶に残っていました。

そして冒頭でも述べたように、本日2024/12/01より「イオンアイビス株式会社のIT事業を分割・統合」によって新生ASTが始動します。
これまで以上に機動力とパワーを増していく当社に期待が高まりますし、所属するひとりとして今後が楽しみです。

最後に、協力いただいたDX基盤の新川さん、検証に協力してくれたSRE岩崎さんおよび関係各位に改めて感謝をお伝えいたします！

それではみなさまEnjoy Microsoft Entra ID & Akamai！

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味をもった方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recuruiting.aeon.info/)
