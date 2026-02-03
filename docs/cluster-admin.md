# クラスタ管理者向けドキュメント

このドキュメントは、Teleport / Kubernetes クラスタの運用に関わるクラスタ管理者向けの手順をまとめたものです。

## GCP 認証と GKE クラスタ情報の取得

Terraform などで GKE クラスタを操作する前提として、GCP への認証とクラスタ情報の取得を行います。

```bash
gcloud auth application-default login

gcloud container clusters get-credentials \
  default \
  --region asia-northeast1 \
  --project teleport-central
```

## 鍵のコピー（Terraform Provider 用ユーザーの作成）

Auth Service 上で Terraform Provider 用のユーザーを作成し、その鍵をローカルにコピーします。

> 注意: この操作は Teleport Auth Service への管理アクセス権限を持つ管理者のみが実行してください。

```bash
kubectl \
    --namespace teleport \
    exec deploy/teleport-auth -- \
    tctl users add terraform --roles=terraform-provider

kubectl --namespace teleport exec deploy/teleport-auth -- tctl auth sign \
  --user=terraform \
  --out=terraform-identity \
  --format=file \
  --ttl=8760h \
  --overwrite

kubectl -n teleport exec deploy/teleport-auth -- \
  cat terraform-identity > terraform-identity
```

作成された `terraform-identity` は、このリポジトリの Terraform 実行時に利用する前提です。運用ポリシーに従って安全に保管してください。
