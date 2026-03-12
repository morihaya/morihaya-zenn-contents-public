---
title: "Azure Backupが使えないPremium BlobをAzure Storage Moverでバックアップする"
emoji: "🚚"
type: "tech"
topics:
  - "azure"
  - "azurestorage"
  - "azurestoragemover"
  - "githubactions"
  - "aeon"
published: false # false or true , スケジュール公開の場合はfalseで予約して後からtrueにFix必要
publication_name: "aeonpeople"
---

## はじめに

こんにちは。イオンスマートテクノロジー株式会社（AST）でSREチームの林aka[もりはや](https://twitter.com/morihaya55)です。

本記事はAzureのマネージドストレージであるStorage account（以後SA）のうち、Azure Backupを適用できなかったAzure Blob Storage（パフォーマンス: Premium）のデータに対して、Azure Storage MoverとGitHub Actionsを組み合わせた定期バックアップ運用の紹介です。

先に明記しておくと、Azure BackupはAzure Blob Storageのバックアップに対して基本の選択肢です。Microsoft LearnでもAzure Blob向けにAzure Backupを利用した方法が案内されています。

ただし、私たちが扱っていた一部のPremium BlobはAzure Backupの前提条件から外れていました。そのためStorage Moverをバックアップ代替の定期コピー手段として活用する方針を取りました。

## TL;DR

- 当社ではAzure Storage Account BlobのバックアップはAzure Backupを利用している
- ただしBlobに対してAzure BackupのOperational backupはStandard Blobが前提で、Premiumは対象外
- そこでAzure Storage MoverのJob definitionをGitHub Actionsから定期起動し、別Blobへの定期コピーでバックアップを実現している

## Azure Storage Account Blobのバックアップ手段を先に整理する

Azure上でSAのBlobをバックアップするなら、まず候補に挙がるのはAzure Backupです。

https://learn.microsoft.com/ja-jp/azure/backup/blob-backup-overview

Azure BackupはVMやDBだけでなくBlobにも対応しており、現在は大きく次の2つの保護方式があります。

- Operational backup: ソースのストレージアカウント内で変更履歴を保持し、ポイントインタイムで戻す方式
- Vaulted backup: Backup vault側へ保護データを保持する方式

とくにOperational backupは「スケジュールを定義しない継続的な保護」であり、Blobのバージョン管理、Soft delete、Change feed、Point-in-time restoreなどの機能で実現しています。
余談ですがこの"Soft delete"を有効にすると、Azure Data Factoryのジョブが以下のようなエラーとなる事象もありましたので有効化の際は十分に検証してください。

> Job failed due to reason: at Sink 'sink1': Operation failed: "This endpoint does not support BlobStorageEvents or SoftDelete. Please disable these account features if you would like to use this endpoint.", 409, HEAD,

## ただし"パフォーマンス: Premium"のBlobはAzure Backupの対象外である

ここで1つ制約があります。

Azure BackupのBlob向けSupport matrixでは、Vaulted backupはStandardのgeneral-purpose v2ストレージアカウント上のBlock Blobsのみをサポートすると明記されています。

> You can back up only block blobs in a standard general-purpose v2 storage account using the vaulted backup solution for blobs.

https://learn.microsoft.com/en-us/azure/backup/blob-backup-support-matrix?tabs=vaulted-backup#supported-and-unsupported-scenarios-for-azure-blob-backup

つまり「Azure BackupがあるからBlobは全部安心！」とはならず、対象のストレージ種別やBlobの性質を見て設計を分ける必要があります。

私たちもほぼすべてのBlobのバックアップをAzure Backupで実装しましたが、一部だけPremium Blobが存在し、実際にこの制約へぶつかりました。そこで別案を考えることになりました。

## 初手はAzCopyでの実装を考えた

最初に浮かんだのはAzCopyです。

AzCopyはAzure Storageまわりでデータをコピーする際の定番ツールです。Microsoft Learnにも、ストレージアカウント間でBlobをコピーする方法がまとまっています。

https://learn.microsoft.com/ja-jp/azure/storage/common/storage-use-azcopy-blobs-copy

Learnにもある通り、AzCopyはサーバー間APIを利用してコピーできるため「Blobを別のBlobへ複製したい」要件だけを見るとかなり素直です。

しかし、実装には考慮するべきポイントがいくつかあります。

まず実行環境です。AzCopyそのものはシンプルでも、「どこでそのコマンドを動かすか」は別問題です。
GitHub ActionsのSelf-hosted runnerで動かすのか、適切なネットワーク上のAzure VMでcron実行するのか、あるいは既存の運用基盤に載せるのかで、設計も責任分界も変わります。

次に認証です。AzCopyはMicrosoft Entra IDでもSASでも実行できますが、自動化を前提にすると「誰の権限でコピーするか」「その資格情報をどう安全に持つか」を決める必要があります。

https://learn.microsoft.com/ja-jp/azure/storage/common/storage-use-azcopy-authorize-azure-active-directory

さらに、運用で必要なのは一度きりの成功ではなく、定期実行、失敗時の再実行、ログの確認、監視といった周辺設計です。シェルスクリプトとAzCopyで作り込むことはできますが、私には「一般的で強力な方法ではあるが、実行環境など考えることが多くてやや面倒」でした。

そのため「コピー処理もう少しAzureのマネージドなサービス側へ寄せられないか」と検討している状態でした。

## Azure Storage Moverをバックアップ代替として使えないかと考えた

そんな中で耳にしたのがAzure Storage Moverです。

https://learn.microsoft.com/en-us/azure/storage-mover/service-overview

Storage Moverは名前のとおり本来は移行サービスです。Microsoft Learnでも、オンプレミスやAWS S3などからAzure Storageへデータを移すためのフルマネージドの移行サービスと説明されています。

よって「バックアップのためのサービス」ではありません。（念のため明記！！）

一方で当時（2025年12月ごろ）Storage MoverのPreviewな機能として「Azure to Azure」の機能が実装されたと紹介を受けました。

https://learn.microsoft.com/en-us/azure/storage-mover/azure-to-azure-migration

![azure-to-azure](/images/morihaya-20260313-azure-storage_mover_is_backupper/2026-03-13-03-25-19.png)

この構造を見た時に、私は「このサービスは移行専用ではなく、定期的に差分コピーを走らせたいケースにも使えるのでは……？」と考えました。

サービス名の”Mover”に引っ張られますが、マネージドな環境でBlobからBlobへコピーを行えるのであれば、Storage Moverは十分にバックアップを実装するサービスとして検討対象になりました。

検証用の環境で試したところ、以下の図のように問題なくBlob内のファイルをコピーでき、本格的に定期バックアップに活用することを決定しました。実行環境を準備しなくて済むのは素晴らしいです。
![Storage MoverによるBlobコピーの検証結果](/images/morihaya-20260313-azure-storage_mover_is_backupper/2026-03-13-02-44-40.png)

また、Storage MoverのJobではコピーモードが選択可能です。今回はバックアップ用途であるため"Merge content into target"を選択しました。

- Merge content into target: ターゲットコンテナーに、ソースコンテナーの内容をマージ（ターゲット側で削除はない）
- Mirror source to target: ソースコンテナーの内容を同期（ソースにないファイルはターゲット側からも削除される）

## 定期実行のStorage Mover本体ではなくGitHub Actionsで行う

Blob内のファイルをコピーする機能は確認が取れましたが、Storage Moverには「スケジュール実行」の機能はありません。
名前からして「データ移行用」のサービスですから、繰り返し実行を想定していないためでしょう。

よって定期実行のために、Storage MoverのJob definitionをGitHub Actionsから定期実行する構成にしました。「定期的な起動のトリガーをGitHub Actionsに持たせる」設計です。

課題として、GitHub Actionsは取り回しは良くてもスケジュール実行時間の正確さに難がありますが、Dailyのバックアップでは多少の実行時間のずれは問題ないと判断しています。

CLIリファレンスにもある通り、Storage MoverのJob実行は`az storage-mover job-definition start-job`で起動できます。

https://learn.microsoft.com/en-us/cli/azure/storage-mover/job-definition?view=azure-cli-latest

実際のGitHub Actionsのイメージは次のような形です。

```yaml
name: Azure Storage Mover Job Execution

on:
  schedule:
    - cron: '5 18 * * *'
  workflow_dispatch:

permissions:
  id-token: write # azure/login を OIDC で使うために必要
  contents: read  # actions/checkout を使うために必要

jobs:
  start-storage-mover-job:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Azure Login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.STORAGE_MOVER_AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}

      - name: Start Storage Mover job definition
        env:
          AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          RESOURCE_GROUP: ${{ vars.RESOURCE_GROUP }}
          STORAGE_MOVER_NAME: ${{ vars.STORAGE_MOVER_NAME }}
          PROJECT_NAME: ${{ vars.PROJECT_NAME }}
          JOB_DEFINITION_NAME: ${{ vars.JOB_DEFINITION_NAME }}
        run: |
          az storage-mover job-definition start-job \
            --subscription "${AZURE_SUBSCRIPTION_ID}" \
            --resource-group "${RESOURCE_GROUP}" \
            --storage-mover-name "${STORAGE_MOVER_NAME}" \
            --project-name "${PROJECT_NAME}" \
            --job-definition-name "${JOB_DEFINITION_NAME}"
```

このような設定でGitHub Actionsでスケジュール実行を実現できます。ポイントは以下です。

- わかりやすさ（cron形式による日次実行）
- 任意で手動実行できる（`workflow_dispatch`）
- OIDCによるAzureログイン
- 実行履歴をGitHub Actions側でも追える

## RBAC権限まわりは最初に整理しておこう

Storage MoverはRBACの前提を理解しておくと後が楽です。

Learnの前提条件にありますがStorage Mover登録時、ジョブ初期化、ジョブの実行（リラン）で必要な権限が異なります。
https://learn.microsoft.com/en-us/azure/storage-mover/service-prerequisites#permissions

初回実行まではセットアップとして行っておき、GitHub Actionsで実行する権限はジョブのリランに必要なものだけに絞るのが良いでしょう。

ただドキュメントはリランに必要なロールは以下とあります。

- Subscription: Reader
- Resource group: Contributor
- Storage mover: Contributor
- Target storage account: Owner

しかし実際には以下だけで動いており、このあたりはPreviewであるため今後変更されるかもしれません。導入にあたっては十分な検証を行なってください。

- Storage mover: Contributor

結果として以下のようにDailyの定期バックアップが行われる状態を実現できました。（Start Timeのばらつきはご愛嬌ですね）

![run_history](/images/morihaya-20260313-azure-storage_mover_is_backupper/2026-03-13-03-22-26.png)

## おわりに

以上が「Azure Backupが使えないPremium BlobをAzure Storage Moverでバックアップする」でした。
振り返ってみるとバックアップ手段の考え方としては以下の順で検討し、

1. 基本的にはAzure Backupが使えるところはAzure Backupを使う
2. Azure Backupが使えないところは別のAzureサービスで代替する
3. 適切なAzureサービスがないならSelf-hostedな環境でスクリプトでがんばる

今回はうまいこと2のケースとしてAzure Storage Mover x GitHub Actionsがハマった、という話でした。

それではみなさま、Enjoy Azure!

## イオングループで、一緒に働きませんか？

イオングループでは、エンジニアを積極採用中です。少しでもご興味をもった方は、キャリア登録やカジュアル面談登録などもしていただけると嬉しいです。
皆さまとお話できるのを楽しみにしています！

[![AEON engineer recruitment banner](https://storage.googleapis.com/techhire-prd-assets/AEON/ATH_engineer_Zenn%E3%83%8F%E3%82%99%E3%83%8A%E3%83%BC.png)](https://engineer-recuruiting.aeon.info/)
