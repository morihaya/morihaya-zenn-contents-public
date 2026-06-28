---
title: "Kubestronautの一員になりました！"
emoji: "⛵️"
type: "idea"
topics:
  - "kubernetes"
  - "cncf"
  - "kubestronaut"
  - "aeon"
published: true
published_at: "2026-06-29 08:00"
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林 aka [もりはや](https://x.com/morihaya55)です。

このたび、Cloud Native Computing Foundation (CNCF) からKubestronautに認定頂きましたので報告ブログです。
シンプルに報告＆所感を目的とした内容であり、取得のためのナレッジなどはあまり無いためこれから取得を試みる方向けの記事ではありません。

執筆時点(2026-06-29)で世界で約4,000人、日本に限定すると約170人程度が認定されており、以下の公式サイトから概要やメンバーを確認できます。

https://www.cncf.io/training/kubestronaut/

私の認定ページは[こちら](https://www.cncf.io/training/kubestronaut/?_sf_s=yukiya+hayashi+aka+morihaya&p=yukiya-hayashi-aka-morihaya)です。更新が途絶えて消えそうな気もするためスナップショットとしても記録しておきます。

![morihaya-is-kubestronaut](/images/morihaya-20260629-Kubestronaut/2026-06-29-02-14-23.png)

## Kubestronautとは

私の上司の光さんがわかりやすく解説してくれているためそちらを引用します。2年前にこの認定の初期フェーズで取得しているの強いなぁ。

> Kubestronautとは、CNCFのすべてのKubernetes認定資格（CKA、CKAD、CKS、KCNA、KCSA）を同時に保有する個人に与えられる称号です。

https://zenn.dev/aeonpeople/articles/74a5ba758fe909

### さらに上のGolden Kubestronautもあります

Kubestronautにはその上位資格とも言えるGolden Kubestronautがあります。
こちらを先日、上司の光さんが見事に取得しておりますため、興味のある方はご覧ください。

> Golden Kubestronautとは、Kubestronaut（CKA、CKAD、CKS、KCNA、KCSA）に加えて、以下の資格を同時に保持することで認定される称号です。
>
> - Prometheus Certified Associate (PCA)
> - Istio Certified Associate (ICA)
> - Cilium Certified Associate (CCA)
> - Certified Argo Project Associate (CAPA)
> - GitOps Certified Associate (CGOA)
> - Certified Backstage Associate (CBA)
> - OpenTelemetry Certified Associate (OTCA)
> - Kyverno Certified Associate (KCA)
> - Certified Cloud Native Platform Engineering Associate (CNPA)
> - Certified Cloud Native Platform Engineer (CNPE)
> - Linux Foundation Certified System Administrator (LFCS)

https://zenn.dev/aeonpeople/articles/c087889c3e85c8

## 取得したモチベーション

取得にあたっては以下のモチベーションで挑みました。

1. 普段からAKSを通してK8sを触っている
2. 上司の光さんがGolden Kubestronautをとったことで、自分の中の敷居が下がった
3. 前回の2025年のKubeCon Japanで「次はKubestronautとして参加します」と宣言したフラグ回収

ざっとそれぞれのモチベーションについて所感を書いていきます。

### 1. 普段からAKSを通してK8sを触っている

当社では多くのアプリケーションがコンテナ化され、Azure Kubernetes Service（AKS）上で動いています。
AKSはマネージドなK8sであり、基本的には安定していますが、SREとして日頃からK8sに関わることは少なくありません。

そのためK8s知識の継続的なアップデートや、`kubectl`筋の維持といった目的は、業務に直接プラスとなり取得に向けた大きな理由のひとつでした。

一方でCKADくらいまでは余裕だったものの、普段はマネージドなAKSに携わっているためコントロールプレーンやノードの現場感が少なく、CKA & CKSについては知識のなさが露呈しました。とくにCKSはリトライした上で合格点ぴったりでのギリギリ通過となり、良い学びにはなりましたがまだまだ伸びしろが大きいと感じています。

ターミナルオペレーションで行う実践形式のCKAD, CKA, CKSは資格として優れている一方、時間配分が非常に重要でKiller.shでの事前練習は必須でした。K8s知識と試験慣れとCLI能力を求められるなかなかの難易度だと思います。

### 2. 上司の光さんがGolden Kubestronautをとったことで、自分の中の敷居が下がった

上でも記事を紹介しましたが、Kubestronautの上位資格のGolden Kubestronautが身近なロールモデルとしていることで、Kubestronautへの挑戦ハードルが自分のなかでグッと下がりました。

この勢いを借りて自分もGolden Kubestronautへ！と宣言したいところですが、必要資格数の多さとIstioやBackstageなど業務で未使用なプロダクト専用の資格もあることから、現在の自分の可処分時間を考えると優先は難しいかな...

### 3. 前回の2025年のKubeCon Japanで「次はKubestronautとして参加します」と宣言したフラグ回収

昨年のKubeCon Japan 2025（公称はKubeCon + CloudNativeCon Japan 2025）は、国際カンファレンスであるKubeConがはじめて日本で行われたものです。

私も参加し、「国際カンファレンスとしてのフォーマットをそのまま日本で実施」されていたことに衝撃と感動を覚えたものでした。
具体的には全セッションが英語による発表でしたし、参加者には日本国外の方も多くいて、過去に何回か参加した海外のカンファレンスの空気感を日本にいながら体感できる稀有な場となっていました。その点だけでもK8s知らない方にもオススメできるカンファレンスです。

https://events.linuxfoundation.org/kubecon-cloudnativecon-japan/

それでいて国内のアクセスの良さもあり、参加もしやすいことから「次回はKubestronautとして参加しますよ！！」と会場の廊下で誰かと談笑しながら宣言した記憶があります。（会期中は本当に多くの方とお会いしたので、その場にいらした方のお名前を正確に思い出せず恐縮ですが…）

あの時のフラグ、無事に回収できましたのできっかけをありがとうございました！！

そして今年のKubeCon + CloudNativeCon Japan 2026は7/28-30 at YOKOHAMAで開催されます。今から参加が楽しみです。

## おわりに

以上が「Kubestronautの一員になりました！」でした。

資格試験を通して業務では扱わないK8s知識の獲得、`kubectl`筋のトレーニング、AKSのマネージドの恩恵を再認識するなど学びが多くありました。次はAzure関係の資格も検討していきたいですね。

それではみなさま、Enjoy Kubernetes & AKS！

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味を持った方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recruiting.aeon.info/)
