<!-- hy-mt2-i18n:start -->
[English](./README.md) | [中文](./README_zh-CN.md) | **日本語** | [Español](./README_es.md)
<!-- hy-mt2-i18n:end -->

[![codecov](https://codecov.io/gh/pinballmap/pbm/branch/master/graph/badge.svg?token=Kgt4ffi0RK)](https://codecov.io/gh/pinballmap/pbm)

コードライセンス：[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

このリポジトリ内のコードには、[GPL v3](LICENSE) ライセンスが適用されます。

データのライセンス：[![License: CC BY-SA 4.0](https://img.shields.io/badge/License-CC_BY--SA_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by-sa/4.0/)

このリポジトリにはデータは含まれていません。代わりに、公開されているAPIを通じてアクセスします。このデータは[CC BY-SA](LICENSE-CC-BY-SA)ライセンスの下で提供されており（GPL v3ではありません）、特にこのライセンスではデータを利用する際に出所を明記することが求められます。

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/P5P411XZAM)


*素晴らしいピンボール体験だな、兄弟！*

このリポジトリは [pinballmap.com](https://pinballmap.com) のコードベースです。[Pinball Mapモバイルアプリ]のコードはこちらにあります：[https://github.com/pinballmap/pbm-react]。アプリに関する問題がある場合は、そちらのリポジトリをご利用ください。

## APIドキュメント

詳細はこちら：[http://pinballmap.com/api/v1/docs](http://pinballmap.com/api/v1/docs)

## 開発環境の構築

**注:** 何か問題が発生した場合は、[Discordで](https://discord.gg/zK6xjyYHJf)すぐにご連絡いただけます。

### 1. Githubでフォークしてください。その後：
* `git clone https://github.com/{you}/pbm.git`
* `git remote add upstream git://github.com/pinballmap/pbm.git`

### 2. Rubyのインストール

* 正しいRubyバージョンはこちらで確認できます。[https://github.com/pinballmap/pbm/blob/master/.ruby-version](https://github.com/pinballmap/pbm/blob/master/.ruby-version)

### 3. 依存関係のインストール
* `gem install bundler`
* `bundle install`

#### Mac

* `brew update`

### 4. postgresqlのインストール

#### Linux

* postgresqlパッケージをインストールする

#### Mac

* [Postgres App](http://postgresapp.com/) をダウンロードする
* `brew install postgresql`

### 5. PostgreSQLのセットアップ

* `initdb /usr/local/var/postgres -E utf8`
* `createuser --interactive`
* `CREATEDB pbm_dev`
* 開発用のdatabase.ymlを作成するには、`cp config/database.yml.example config/database.yml` を実行してください
* `bin/rake db:create ; RAILS_ENV=test bin/rake db:create`
* `bin/rake db:migrate ; RAILS_ENV=test bin/rake db:migrate`

### 6. maxmindデータベースのダウンロード
* https://www.maxmind.comにアクセスし、アカウントを作成してください  
* ナビゲーションメニューの「GeoIP / GeoLite」の下で「Download files」をクリックします  
* 「GeoLite City」を探し、「Download GZIP」を選択します  
* 解凍すると、GeoLite2-City.mmdbという名前のファイルが出てきます  
* そのファイルをプロジェクトフォルダ内の‘tmp/GeoLite2-City.mmdb’という場所に置いてください

### 7. 開発サーバーを起動する
* `bin/rails s`

### 8. テストの実行
* `bundle exec rspec`

### 9. デバッグサーバーを実行する
* サーバーを起動する：`bin/debug`
* コマンドパレットを通じてVSCodeコマンドラインツールをインストールする。VSCodeのトップメニューから「View | Command Palette」を選択し、次のように検索する：「Shell Command: Install 'code' command in path」
* VSCodeデバッガーを使って接続し、ブレークポイントを設定する

### 10. データベースのダンプを取得する

サイトが正常に表示されれば、それはpinballmap.comの空のバージョンとなります。データベースのダンプは[このリポジトリ](https://github.com/pinballmap/pbm-db-dump)から取得できます。

* `psql -U username -d pbm_dev < pbm_db_scrubbed.sql`
* `bin/rails create_developer_account` # パスワードが `example` のユーザー `example@example.com` を作成します


## Dockerのセットアップ

_警告_: このプロジェクトが最初に構築されて以来、私たちの中でDockerを使用したことがある人はいません。そのため、以下の手順の正確性については保証できません。もし指示内容を更新したい場合は、どうぞご自由に行ってください。

### 前提条件
* Docker >= v1.12.0+
* Docker-Compose（Docker for Macに同梱されています。Linuxでは別途インストールが必要）
* _任意_: 競合が発生した場合にデフォルトのポートを上書きするための環境変数を読み込む手段として、[direnv](http://direnv.net/)やその他のツール

### 使用方法
#### 完全コンテナ化版
* コンテナを起動するには `docker-compose up -d` を実行します
* `localhost:$PORT` にアクセスします（指定がなければデフォルトで `3000` になります）
* コンテナを停止するには `docker-compose down` を使用します
  * デフォルトでは、データベースの状態は[docker volume](https://docs.docker.com/storage/volumes/)として保持されます。一からやり直したい場合は、volumeを破壊するために `docker-compose down -v` を実行してください。このdocker-composeファイルを再度起動すると、`db:create` および `db:migrate` によってデータベースが再構築されます。

#### PostgreSQLのみ
コンテナ内でPostgresのみを実行し、Railsの動作にはローカルファイルシステムを使用したい場合は、PostgreSQLのみ用のcomposeファイルを利用できます。
* `docker-compose -f docker-compose.postgres.yml up -d`を実行します。
* 初回実行の場合は、`bin/rake db:create db:migrate`を実行してPostgresコンテナにデータを入力します。
* `docker-compose -f docker-compose.postgres.yml down`を実行してコンテナを停止します。
  * デフォルトでは、データベースの状態は[docker volume](https://docs.docker.com/storage/volumes/)として保持されます。一からやり直したい場合は、`docker-compose -f docker-compose.postgres.yml down -v`を実行してそのvolumeを削除してください。
