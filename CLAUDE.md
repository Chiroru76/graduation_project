# Claude Code ガイド

## プロジェクト概要
**MochiPet（モチペット）** - ゲーミフィケーション型習慣管理・タスク管理アプリ

日々の習慣やタスクの達成が、育てるの成長に直結します。
睡眠・勉強・運動などを記録するとステータスが変化し、タスクをこなすと経験値が貯まりレベルアップや進化が可能に。
一方で、習慣を続けなかったりログインを怠るとキャラは弱り、やがて「死」を迎えてしまいます。
ゲーム感覚で習慣形成や継続、タスクの管理をすることができるサービスです。

### 主な機能
- タスク管理（TODO/習慣の2種類）
- ペット育成（経験値・レベル・しあわせ度(bond_hp)管理）
- OpenAI APIによるペットコメント動的生成
- LINE通知（期限リマインダー、ペット死亡通知など）
- 称号付与
- 統計グラフ表示

## 技術スタック
### バックエンド
- Ruby 3.4.5
- Rails 8.0.2.1
- PostgreSQL 16
- Redis 7（キャッシュ・セッション・ジョブキュー）
- Sidekiq + Sidekiq-cron（バックグラウンドジョブ・定期実行）

### フロントエンド
- Hotwire（Turbo Rails + Stimulus）
- JavaScript（esbuildバンドリング）
- TailwindCSS 4.3.0
- Chart.js / Chartkick

### 認証・API連携
- Devise（メール認証）
- OmniAuth（Google OAuth 2.0、LINE OAuth）
- OpenAI API（GPT-4によるコメント生成）
- LINE Messaging API（プッシュ通知）

### テスト・品質管理
- RSpec + Capybara + Selenium WebDriver
- Factory Bot + Faker
- RuboCop（コード解析）
- Brakeman（セキュリティスキャン）

### インフラ
- Docker / Docker Compose（開発環境）
- Render（本番環境）
- GitHub Actions（CI/CD）

## 共通コマンド

### 開発環境の起動
```bash
# Docker環境の起動（DB、Redis、Chromeを含む）
docker compose up -d

# Rails サーバー + Sidekiq + アセットビルドを一括起動
docker compose exec web bin/dev

# または個別起動（それぞれ別のターミナルで実行）
docker compose exec web rails server
docker compose exec web bundle exec sidekiq
```

### テスト実行
```bash
# すべてのテストを実行（テスト環境のDBを使用）
docker compose exec -e RAILS_ENV=test web bundle exec rspec

# システムテスト（ブラウザテスト）のみ実行
docker compose exec -e RAILS_ENV=test web bundle exec rspec spec/system
```

### データベース操作
```bash
# マイグレーション実行
docker compose exec web rails db:migrate

# コンソールでデータ確認・操作
docker compose exec web rails console
```

### コード品質チェック
```bash
# RuboCop実行（自動修正あり）
docker compose exec web bundle exec rubocop -a

# RuboCop実行（自動修正なし）
docker compose exec web bundle exec rubocop

```

### アセット・依存関係
```bash

# Ruby gem のインストール
docker compose exec web bundle install

```

### Sidekiq管理
```bash
# Sidekiq起動（workerコンテナで起動済み）
docker compose exec worker bundle exec sidekiq
```

### Docker操作
```bash
# コンテナ起動
docker compose up -d

# コンテナ再起動
docker compose restart

# 特定のコンテナを再起動
docker compose restart web
docker compose restart worker

# ログ確認
docker compose logs -f web
docker compose logs -f worker

```

## 重要な制約事項

### ペット育成システムのビジネスロジック
**絶対に壊してはいけない仕様**:
- 新規登録時に「たまご」キャラを自動生成
- Lv.2で誕生（childキャラにランダム進化）
- Lv.10でadultキャラに進化
- きずなHP（0-100）が0になるとペット死亡（state: dead）
- しあわせ度(bond_hp)は毎日00:00に減衰


### 定期実行ジョブ（schedule.yml）
**変更時は必ず影響範囲を確認**:
- 00:00 - ペットのきずなHP減衰
- 00:00 - 習慣タスクのリセット
- 00:00 - ペット死亡通知
- 09:00 - タスク期限リマインダー
- 09:00 - きずなHP低下警告

すべて`Asia/Tokyo`（JST）で実行されます。


### コード品質
- RuboCop違反は原則修正（CI/CDでチェック）
- テスト追加なしでの機能追加は禁止

### やってはいけないこと
- タイムゾーン変更（すべてAsia/Tokyoを前提に設計）
- しあわせ度(bond_hp)計算ロジックの変更（既存ユーザーに影響）
- マイグレーションの直接編集（過去のものは変更不可）

## ディレクトリ構成
```
app/
├── controllers/     # 16個のコントローラ（characters, tasks, charts等）
├── models/          # 10個のモデル（User, Character, Task等）
├── services/        # ビジネスロジック（LINE通知、ペットコメント生成等）
├── jobs/            # 8個のSidekiqジョブ
├── views/           # ERBテンプレート
└── javascript/      # Stimulusコントローラ

config/
├── schedule.yml     # cronジョブ定義
├── sidekiq.yml      # Sidekiq設定
└── locales/         # 日本語・英語対応

spec/                # テストスイート
├── models/
├── requests/
├── system/
└── services/
```

---

> このファイルは Claude Code がプロジェクトを理解し、適切に作業するためのガイドラインです。
> 変更時は必ずこのファイルを更新してください。
