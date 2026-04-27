---
title: "AkamaiのDevice CharacterizationでPC/スマホ/タブレットごとにCDNキャッシュを分ける"
emoji: "📱"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: # タグを指定する
  - "akamai"
  - "cdn"
  - "キャッシュ"
  - "aeon"
published: true
published_at: 2026-04-28 08:00  # 公開したい日時（JST換算でOK）
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://twitter.com/morihaya55)です。

本記事ではAkamaiのProperty Managerにおける[Device Characterization](https://techdocs.akamai.com/property-mgr/docs/device-characterization-dc) Behaviorを利用し、PC/スマートフォン/タブレットごとに異なるCDNキャッシュを返す方法を紹介します。

当社ではCDN/WAFの機能に[Akamai社](https://www.akamai.com/ja)のサービスを採用しています。サービスを運用していると「同じURLでもデバイスによって出し分けたいのに、Akamaiのキャッシュは1種類しか持っていない」というケースに遭遇することがあります。

たとえばOriginがUser-Agentを見てPC向け/スマホ向けのHTMLを出し分けている場合、CDN側でその違いを区別せずキャッシュしてしまうと、スマホユーザーにPC向けHTMLが返ってしまう、といった事故が起きます。

このときに役立つのが「Device Characterization」(DC) です。Akamai Edge側でデバイス種別を判定し、その結果をキャッシュキーに含めることで、同一URLでもデバイス別にキャッシュを分けられます。

## TL;DR

本記事を箇条書きでまとめると以下です。

- Originがデバイス別（PC/スマホ/タブレットなど）にレスポンスを変える場合、CDNでもデバイス別にキャッシュを分ける必要がある
- AkamaiのBehaviorには`Device Characterization - Define Cached Content`があり、選択した特性ごとにキャッシュキーが分かれる
- `elements`に`is_mobile`/`is_tablet`を指定することで、PC/スマホ/タブレットの3パターンに分割できる
- 同じく`Device Characterization - Forward in Header` Behaviorを併用すると、Origin側にもデバイス特性を伝えられる
- `is_mobile`/`is_tablet`はUser-Agent由来のため、URL Purgeでは一意に特定できない警告が出る点に注意
- 過剰に分割するとヒット率が落ちるため、本当にデバイス別の出し分けが必要なパスにだけ適用する

## 背景

### 同じURLでもデバイス別にレスポンスを変えたい

Webサービスの中には、同じURLに対してOriginがUser-Agentを見て出し分けるタイプがあります。

たとえば`/hogeservice`というURLに対して、PCからのアクセスにはPC向けHTML、スマートフォンからのアクセスにはスマホ向けHTMLを返す、といった構成です。（全記事同様、HOGEサービスはサンプル用の仮名であり当社の実サービスではございません）

この構成自体は珍しくないのですが、間にCDNを挟む場合にひと工夫必要になります。

### CDNがデバイスを区別しないと事故る

AkamaiのようなCDNは、基本的にURLとホスト名などをキーにしてキャッシュを持ちます。

つまり、何も工夫しないと「`https://example.com/hogeservice`のレスポンスは1種類」とみなされ、最初にアクセスしたデバイスのHTMLが、以降すべてのユーザーに返ってしまいます。

- スマホユーザーが先にアクセス → スマホ向けHTMLがキャッシュされる
- 続いてPCユーザーがアクセス → スマホ向けHTMLが返ってしまう

このような事故を避けるためには、CDN側でも「これはPC向け」「これはスマホ向け」「これはタブレット向け」とキャッシュを分ける必要があります。

そこで使うのがAkamaiの`Device Characterization`です。

https://techdocs.akamai.com/property-mgr/docs/device-characterization-dc

![akamai-console](/images/morihaya-20260428-akamai-device-characteristic/2026-04-28-02-28-59.png)

## AkamaiのDevice Characterizationでデバイス別キャッシュを実現する

### Device Characterizationとは

Device Characterization（DC）はAkamaiのBehaviorのひとつで、リクエスト元デバイスの特徴をRule内で扱えるようにする機能です。Behaviorとして以下の2つがセットで提供されています。

| Behavior | JSON名 | 役割 |
| --- | --- | --- |
| Device Characterization - Define Cached Content | `deviceCharacteristicCacheId` | 選択した特性ごとにキャッシュキーを分ける |
| Device Characterization - Forward in Header | `deviceCharacteristicHeader` | 選択した特性をHTTPヘッダでOriginへ転送する |

判定はAkamai Edgeが内部で保持するデバイス情報DB（WURFLや独自シグナル）によって行われるため、Originや自前のUser-Agent解析を持たなくても、Edge側でデバイス種別を判別できます。

代表的な特性（characteristic）には以下のようなものがあります。

| Characteristic | 役割 |
| --- | --- |
| `is_mobile` | スマートフォン判定 |
| `is_tablet` | タブレット判定 |
| `device_os` | OS（iOS、Android、Windowsなど） |
| `brand_name` | 端末ブランド名（Samsung、Appleなど） |
| `resolution_width` | 画面の横解像度（ピクセル） |

今回のHOGEサービスではシンプルに「PC / スマートフォン / タブレット」の3区分にしたいため、`is_mobile`と`is_tablet`の組み合わせで分割します。Akamai Edgeは選択した特性の値の組み合わせごとにキャッシュエントリを自動生成してくれて、こちらで「PCのときは…」のようなRule分岐を書く必要はありません。

| 想定デバイス | `is_mobile` | `is_tablet` |
| --- | --- | --- |
| PC | false | false |
| スマートフォン | true | false |
| タブレット | false | true |

### JSONでみる具体的な設定内容

Akamai CDNのProperty Managerには、設定状態をXMLまたはJSONで表示する機能があります。今日のAI Agentの隆興を鑑み本記事では具体的な設定をJSON形式で提示します。

`/hogeservice`配下というPath Criteriaに対して、DCの2つのBehaviorをまとめて1つのRuleに入れた構成です。Criteria側で「どのリクエストに適用するか」を絞り込み、Behavior側で「キャッシュキーをどう分けるか」「Originに何を伝えるか」を指定する形になります。

```json
{
  "name": "Hoge Device Characterization",
  "criteria": [
    {
      "name": "path",
      "options": {
        "matchOperator": "MATCHES_ONE_OF",
        "values": [
          "/hogeservice",
          "/hogeservice/*"
        ]
      }
    }
  ],
  "criteriaMustSatisfy": "all",
  "behaviors": [
    {
      "name": "deviceCharacteristicCacheId",
      "options": {
        "elements": [
          "is_mobile",
          "is_tablet"
        ]
      }
    },
    {
      "name": "deviceCharacteristicHeader",
      "options": {
        "elements": [
          "is_mobile",
          "is_tablet"
        ]
      }
    }
  ]
}
```

:::message
上記は記事用に重要部分だけを抜粋した例です。実際のRuleにはOriginや通常のキャッシュTTL設定なども含まれています。
:::

## 実装内容

### `/hogeservice`配下だけを対象にする

まず、デバイス別キャッシュ分割の対象を`/hogeservice`配下に限定します。Path Criteriaを使う点はDCに限らずよくあるパターンですね。

```json
{
  "name": "path",
  "options": {
    "matchOperator": "MATCHES_ONE_OF",
    "matchCaseSensitive": false,
    "normalize": false,
    "values": [
      "/hogeservice",
      "/hogeservice/*"
    ]
  }
}
```

サイト全体でデバイス別キャッシュにしてしまうと、本来1種類で十分な静的アセットまでキャッシュが3倍に分裂し、キャッシュヒット率が下がります。

DCを使うときは、まず「本当にデバイス別にレスポンスが違うパスはどこか」を切り分けることが大切です。

### `deviceCharacteristicCacheId` Behaviorでキャッシュキーを分ける

今回の主役がこの`deviceCharacteristicCacheId` Behaviorです。
Web画面には`Device Characterization - Define Cached Content`と表示され、JSONコンフィグ上ではシンプルに`deviceCharacteristicCacheId`として扱われています。

```json
{
  "name": "deviceCharacteristicCacheId",
  "options": {
    "elements": [
      "is_mobile",
      "is_tablet"
    ]
  }
}
```

`elements`に列挙した特性の**値の組み合わせごとに、別々のキャッシュエントリ**が作られます。`is_mobile`と`is_tablet`を選ぶだけで、Akamai Edge上では同じ`/hogeservice`に対して以下のようなキャッシュが保持されます。

- `is_mobile=false, is_tablet=false` → PC向け
- `is_mobile=true, is_tablet=false` → スマートフォン向け
- `is_mobile=false, is_tablet=true` → タブレット向け

PC判定のために自前で「`is_mobile`がfalse かつ `is_tablet`がfalse」のようなCriteriaを書く必要はなく、Akamai側が組み合わせを自動で展開してくれるのが楽なポイントです。

### `deviceCharacteristicHeader` BehaviorでOriginにも伝える

キャッシュキーを分けるだけでなく、Originにもデバイス情報を渡したい場合は`deviceCharacteristicHeader`を併用します。
Web画面では`Device Characterization - Forward in Header`と表示されているBehaviorです。

```json
{
  "name": "deviceCharacteristicHeader",
  "options": {
    "elements": [
      "is_mobile",
      "is_tablet"
    ]
  }
}
```

これを入れておくと、Originへのリクエスト時に`X-Akamai-Device-Characteristics`ヘッダが付与され、`is_mobile=true,is_tablet=false`のような形でデバイス情報が伝わります。

Origin側がこのヘッダを見て出し分ける構成にしておけば、自前のUser-Agent解析を持たずに済みます。Akamai公式の[Tips](https://techdocs.akamai.com/property-mgr/docs/device-characterization-dc)でも「キャッシュキーに加えた特性は、合わせてForwardしておくのを推奨」とされているため、基本は2つセットで設定するのが無難です。

### Vary対応の代替としても使える

似たような目的では`Vary: User-Agent`をOriginから返す方法もありますが、User-Agentは無数のバリエーションがあるため、CDN側でほぼキャッシュが効かなくなりがちです。

DCであれば「PC / スマホ / タブレット」のような粒度に丸めてからキャッシュキーに含められ、現実的なヒット率を保ちつつデバイス別キャッシュを実現できます。

## この方式の良いところ

### Originや自前ロジックに依存しなくて済む

一番大きな利点は、デバイス判定をAkamai Edgeに任せられることです。

| 方式 | デバイス判定の場所 | キャッシュ効率 | 実装コスト |
| --- | --- | --- | --- |
| 自前のUser-Agent解析 | アプリ側 | 工夫が必要 | 高い |
| `Vary: User-Agent` | Origin | 低い（ほぼキャッシュされない） | 低い |
| Device Characterization | Akamai Edge | デバイス粒度で安定 | 中程度 |

OriginやアプリのUser-Agent解析をメンテし続ける必要がなく、デバイスDB自体はAkamai側で更新されていきます。新機種への追従コストが下がるのは、運用上かなりありがたいポイントです。

### 適用範囲を絞れる

今回のように`path` Criteriaと組み合わせれば、デバイス別キャッシュを必要なパスにだけ適用できます。

サイト全体ではなくデバイス出し分けが本当に必要なエンドポイントだけに限定することで、キャッシュヒット率の低下を最小限に抑えられます。

「画像や静的JSは1種類で十分、HTMLだけはデバイス別に持ちたい」のような切り分けがしやすいのもAkamaiの良いところです。

### 既存のRule構成に追加しやすい

`deviceCharacteristicCacheId`は単なるBehaviorであり、既存のRule構成にあとから追加しやすいです。

たとえば「すでに`/hogeservice`向けのキャッシュRuleがある」場合、そのRuleにDCのBehaviorを2つ足すだけで対応できます。

メンテナンスRuleや認可Ruleなど、他のBehaviorと組み合わせて使えるため運用上の柔軟性も高いと感じます。

## 注意点

### Stagingで必ず確認する

デバイス判定の挙動は、見た目はシンプルでも実機確認が大切です。

とくに以下はAkamai Stagingで確認しておくべきでしょう。本番でPCユーザーにスマホ向けHTMLが返ったりすると目も当てられません。

- PCからアクセスしたときにPC向けキャッシュ（`is_mobile=false, is_tablet=false`）にヒットするか
- スマートフォンからアクセスしたときにスマホ向けキャッシュ（`is_mobile=true, is_tablet=false`）にヒットするか
- タブレットからアクセスしたときにタブレット向けキャッシュ（`is_mobile=false, is_tablet=true`）にヒットするか
- それぞれのレスポンスヘッダで`X-Cache`やキャッシュキーが想定通り分かれているか
- Originに渡る`X-Akamai-Device-Characteristics`ヘッダの値がデバイスごとに変わっているか
- 対象外パス（`/hogeservice`配下以外）には影響していないか

User-Agentを切り替えて手動で確認するのも良いですし、Akamai Pragma Headerを使って`X-Cache-Key`系の情報を出力させて確認するのも有効です。


#### Akamai Pragma Header

詳細は割愛しますが、AkamaiのデバッグヘッダーことPragmaヘッダーはCDNのキャッシュ状況を確認するために大変有用です。

簡単にPragmaヘッダーを追加できる拙作の拡張機能「Akamai Pragma Injector」を参考までにご紹介しますので、よければご利用ください。
＊Chrome, Edgeそれぞれ公開しております

https://chromewebstore.google.com/detail/akamai-pragma-injector/jbnmnhdcefmgbdmcongkjkdfdajboagf
https://microsoftedge.microsoft.com/addons/detail/akamai-pragma-injector/ofnimccincbphihoaacnkmjfclnpijce


### 過剰なキャッシュ分割はヒット率を下げる

DCは便利ですが、なんでもかんでもデバイス別に分けるとキャッシュ効率が落ちます。

| 対象 | デバイス別キャッシュ |
| --- | --- |
| HTML（デバイス別レスポンス） | 必要 |
| JSON API（デバイス別レスポンス） | 必要 |
| 画像・CSS・JS | 基本不要 |

「Originがデバイス別にレスポンスを変えるかどうか」を基準に、適用範囲を決めましょう。

ちなみに、すでに`/sp/`や`/m/`のようにURL自体がデバイス別に分かれている場合は、そもそもDCが不要なケースもあります。URLが違えば自然にキャッシュも分かれるためです。

### URLによるPurgeが効かなくなる点に注意する

`Device Characterization - Define Cached Content` Behaviorを設定すると、Akamai Control Center上で次のような警告が表示されます。

> With Device Characterization - Define Cached Content within a match on Request Header, the content can't be purged by URL. Contact your Akamai representative to explore alternative methods for making your content purgeable.

これはちょっと重要な警告で、要点は「URLによるPurgeが効かなくなる」ということです。

公式ドキュメントの[Device Characterization (DC)](https://techdocs.akamai.com/property-mgr/docs/device-characterization-dc)にも以下のような記載があります。

> DC creates cache keys based on the values of the characteristics you select.

`is_mobile`や`is_tablet`はAkamai Edgeが内部的にUser-Agentヘッダから算出している値です。そのため、これらをキャッシュキーの`elements`に入れた瞬間に、キャッシュエントリは「URLだけでは一意に特定できない」状態になります。警告文の `within a match on Request Header` は、まさにこのリクエストヘッダ由来の値がキャッシュキーに混ざる状況を指しています。

| Purge方式 | DC環境での挙動 |
| --- | --- |
| URL Purge | デフォルトのキャッシュエントリしか消えない可能性がある |
| CP Code Purge | 配下すべてが消える（粒度が粗い） |
| Cache Tag Purge | タグを設計しておけば狙ったコンテンツを消せる |

つまり、デバイス別にキャッシュを分けた`/hogeservice`に対して「Fast Purge by URLで`/hogeservice`を消す」を実行しても、PC向け・スマホ向け・タブレット向けの3キャッシュ全てが想定通りに消えるとは限らない、ということです。

警告に書かれている「Contact your Akamai representative to explore alternative methods」は、典型的には以下の代替手段の検討を意味します。

- **Cache Tag**: レスポンスに`Edge-Cache-Tag`ヘッダを付与し、Fast Purge by Cache Tagで一括Purgeする
- **CP Code単位のPurge**: デバイス別キャッシュ専用のCP Codeを切り、CP Code Purgeで全消しする
- **TTLを短めに設定**: そもそもPurgeに依存せず短時間でキャッシュを入れ替える運用にする

運用設計の観点では、DCを使う前に「このコンテンツは緊急Purgeが必要になり得るか？」を整理しておくのがおすすめです。緊急Purgeの可能性があるパスでは、Cache Tagの導入をセットで検討しておくと安心です。

なお、私のイチオシするCDN関連の名著『Web配信の技術』に従うならば、「手動パージが必要にならない程度のTTLを常時設定しておくべし」とありますため、当社の場合はTTLでコントロールしています。

https://gihyo.jp/book/2021/978-4-297-11925-6

### Forwardする特性とキャッシュキーの特性は揃える

AkamaiのDCに関する同ドキュメントの[Tips and best practices](https://techdocs.akamai.com/property-mgr/docs/device-characterization-dc#tips-and-best-practices)では、`deviceCharacteristicCacheId`に入れた特性は`deviceCharacteristicHeader`にも入れて、Originに何が伝わっているかを`X-Akamai-Device-Characteristics`ヘッダで確認できる状態にしておくことが推奨されています。

```text
X-Akamai-Device-Characteristics: is_mobile=true,is_tablet=false
```

![akamai-console](/images/morihaya-20260428-akamai-device-characteristic/2026-04-28-02-28-59.png)


ここを揃えておかないと、「キャッシュキーは分かれているのに、Originから見ると何で分かれているのかわからない」状態になりがちです。Origin側のログ解析やデバッグでも、このヘッダが大いに役立つため両方に同じ`elements`を指定しておくのがおすすめです。

## おわりに

以上が「AkamaiのDevice CharacterizationでPC/スマホ/タブレットごとにCDNキャッシュを分ける方法」の紹介でした。

今回のポイントは、デバイス判定をAkamai Edgeに任せ、`Device Characterization - Define Cached Content` Behaviorで`is_mobile`/`is_tablet`をキャッシュキーに含めることです。

Originがデバイスを見て出し分けるタイプのサービスでは、CDNでも同じ粒度でキャッシュを分けてあげないと、簡単に「PCユーザーにスマホHTMLが返る」事故が起きます。DCを使えば、Originや自前のUser-Agent解析に頼らず、Akamai側でこの問題を素直に解決できます。

ただし、便利さの裏で「URL Purgeが効かなくなる」という運用上の制約も付いてきます。適切なキャッシュのTTLを設定すべきでしょう。

CDNはキャッシュ高速化のイメージが強いですが、こういった「キャッシュをどう分けるか」「どう消すか」の設計もサービスの改善に効果的です。

本記事が同じように、デバイス別キャッシュで悩んでいる方の参考になれば幸いです。

それではみなさまEnjoy Akamai！

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味をもった方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recuruiting.aeon.info/)
