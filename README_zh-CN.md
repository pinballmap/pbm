<!-- hy-mt2-i18n:start -->
[English](./README.md) | **中文** | [日本語](./README_ja.md) | [Español](./README_es.md)
<!-- hy-mt2-i18n:end -->

[![codecov](https://codecov.io/gh/pinballmap/pbm/branch/master/graph/badge.svg?token=Kgt4ffi0RK)](https://codecov.io/gh/pinballmap/pbm)

代码许可证：[![许可证：GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

本仓库中的代码受 [GPL v3](LICENSE) 许可证的约束。

数据许可协议：[![许可协议：CC BY-SA 4.0](https://img.shields.io/badge/License-CC_BY--SA_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by-sa/4.0/)

该仓库中不包含数据，而是通过公共 API 来访问这些数据。这些数据受 [CC BY-SA](LICENSE-CC-BY-SA) 许可协议约束（而非 GPL v3 许可协议）。根据该许可协议的要求，在使用这些数据时必须注明出处。

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/P5P411XZAM)


玩弹珠游戏超爽的兄弟

该仓库是[pinballmap.com](https://pinballmap.com)的代码库。[Pinball Map移动应用]的代码位于此处：[https://github.com/pinballmap/pbm-react](https://github.com/pinballmap/pbm-react)。如果您遇到应用相关问题，请使用那个仓库。

## API 文档

文档地址：[http://pinballmap.com/api/v1/docs](http://pinballmap.com/api/v1/docs)

## 开发环境搭建

**注意：** 如果遇到问题，您可以通过 [Discord](https://discord.gg/zK6xjyYHJf) 快速联系我们。

### 1. 在 Github 上 fork 该仓库。然后：
* `git clone https://github.com/{you}/pbm.git`
* `git remote add upstream git://github.com/pinballmap/pbm.git`

### 2. 安装 Ruby

* 正确的 Ruby 版本可在此处查看：[https://github.com/pinballmap/pbm/blob/master/.ruby-version](https://github.com/pinballmap/pbm/blob/master/.ruby-version)

### 3. 安装依赖项
* `gem install bundler`
* `bundle install`

#### Mac

* `brew update`

### 4. 安装 postgresql

#### Linux系统

* 安装 postgresql 包

#### Mac

* 下载 [Postgres App](http://postgresapp.com/)
* `brew install postgresql`

### 5. 配置 PostgreSQL

* `initdb /usr/local/var/postgres -E utf8`
* `createuser --interactive`
* `CREATEDB pbm_dev`
* 将 `cp config/database.yml.example config/database.yml` 执行，以便为开发环境创建自己的 database.yml 文件
* `bin/rake db:create ; RAILS_ENV=test bin/rake db:create`
* `bin/rake db:migrate ; RAILS_ENV=test bin/rake db:migrate`

### 6. 下载 MaxMind 数据库
* 访问 https://www.maxmind.com 并创建账户 
* 在导航菜单的“GeoIP / GeoLite”下方点击“Download files”
* 找到“GeoLite City”并选择“Download GZIP”
* 解压后会出现一个名为 GeoLite2-City.mmdb 的文件
* 将该文件放入项目文件夹中的 ‘tmp/GeoLite2-City.mmdb’ 目录下

### 7. 启动开发服务器
* `bin/rails s`

### 8. 运行测试
* `bundle exec rspec`

### 9. 运行调试服务器
* 启动服务器：`bin/debug`
* 通过命令面板安装 VSCode 命令行工具。在 VSCode 顶部菜单中选择：`View | Command Palette`，然后搜索：`Shell Command: Install 'code' command in path`
* 使用 VSCode 调试器附加到进程并设置断点

### 10. 获取数据库导出文件

如果网站能够正常加载，那将是一个空的 pinballmap.com 页面。数据库备份文件可从[此仓库](https://github.com/pinballmap/pbm-db-dump)获取。

* `psql -U username -d pbm_dev < pbm_db_scrubbed.sql`
* `bin/rails create_developer_account` # 会创建用户名为 `example@example.com`、密码为 `example` 的用户


## Docker 设置

_警告_：自最初搭建以来就没人再使用过 Docker，因此我们无法保证以下步骤的正确性。如果您希望更新相关说明，请随时进行。

### 先决条件
* Docker >= v1.12.0+
* Docker-Compose（随 Docker for Mac 一同提供，在 Linux 上需单独安装）
* _可选_：[direnv](http://direnv.net/) 或其他可用于加载环境变量的工具，以便在端口冲突时覆盖默认端口设置

### 使用方法
#### 完全容器化方案
* 运行 `docker-compose up -d` 启动容器
* 访问 `localhost:$PORT`（可自行指定端口，默认为 `3000`）
* 使用 `docker-compose down` 停止容器
  * 默认情况下，数据库的状态会以[docker卷](https://docs.docker.com/storage/volumes/)的形式保存。如果想要重新开始，可运行 `docker-compose down -v` 来删除该卷。下次再次启动此 docker-compose 文件时，`db:create` 和 `db:migrate` 命令会重新填充数据库数据。

#### 仅 PostgreSQL
如果您只想在容器中运行 PostgreSQL，同时使用本地文件系统来运行 Rails，可以使用专门的 PostgreSQL Compose 配置文件。
* 运行 `docker-compose -f docker-compose.postgres.yml up -d` 启动容器
* 如果是首次运行，请执行 `bin/rake db:create db:migrate` 以填充 PostgreSQL 容器中的数据
* 使用 `docker-compose -f docker-compose.postgres.yml down` 停止容器
  * 默认情况下，数据库的状态会以 [docker volume](https://docs.docker.com/storage/volumes/) 的形式保存。如果想要重新开始，可运行 `docker-compose -f docker-compose.postgres.yml down -v` 来删除该卷。
