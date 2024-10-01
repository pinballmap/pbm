[![codecov](https://codecov.io/gh/pinballmap/pbm/branch/master/graph/badge.svg?token=Kgt4ffi0RK)](https://codecov.io/gh/pinballmap/pbm)

Code License: [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

The [GPL v3](LICENSE) license applies to the _code_ in this repository.

Data License: [![License: CC BY-SA 4.0](https://img.shields.io/badge/License-CC_BY--SA_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by-sa/4.0/)

The _data_ is not included in this repository. Rather, it is accessed via the public API. This data is under a [CC BY-SA](LICENSE-CC-BY-SA) license (and not GPL v3). Amongst other things, this license requires attribution when using the data.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/P5P411XZAM)


*sweet pinballin' brah*

This repo is the codebase for [pinballmap.com](https://pinballmap.com). The code for the [Pinball Map mobile app is here](https://github.com/pinballmap/pbm-react). If you have an app issue, please use that repo.

## API Documentation

Available here: [http://pinballmap.com/api/v1/docs](http://pinballmap.com/api/v1/docs)

## Mac Environment Setup

1. Fork it on Github. Then:
* `git clone https://github.com/{you}/pbm.git`
* `git remote add upstream git://github.com/pinballmap/pbm.git`

2. Install the [correct ruby version](https://github.com/pinballmap/pbm/blob/master/.ruby-version)

3. Install dependencies
* `bundle install`
* `selenium install`
* `brew update`

4. Install and configure the database
* Download [Postgres App](http://postgresapp.com/).
* `cp config/database.yml.example config/database.yml` to create your database.yml for development
* `brew install postgresql`
* `initdb /usr/local/var/postgres -E utf8`
* `CREATEDB pbm_dev`
* `bin/rake db:create ; RAILS_ENV=test bin/rake db:create`
* `bin/rake db:migrate ; RAILS_ENV=test bin/rake db:migrate`

5. Run the development server
* `bin/rails s`

6. Run the tests
* `bundle exec rspec`

Run tests: `bundle exec rspec`

8. Run the debug server
* Start server: `bin/debug`
* Install VSCode command line tools via command palette. From the VSCode top Menu: `View | Command Palette` then search for: `Shell Command: Install 'code' command in path`
* Attach via VSCode debugger and set breakpoints

7. Get a database dump from Scott. Then:
* `pg_restore --verbose --clean --no-acl --no-owner -h localhost -d pbm_dev dump.file`

If the site loads properly it will be an empty version of pinballmap.com, then ask Scott for a data dump so you can have a full set of data to work with.

## Linux Setup

1. Fork it. Then:

* `clone https://github.com/{you}/pbm.git`
* `git remote add upstream git://github.com/pinballmap/pbm.git`

2. Install postgresql.

3. Setup postgres:

* createuser --interactive
* createdb pbm_dev

4. Install the [correct ruby version](https://github.com/pinballmap/pbm/blob/master/.ruby-version)

* `gem install bundler`
* `bundle install`
* `cp config/database.yml.example config/database.yml` to create your database.yml for development
* `bin/rake db:create ; RAILS_ENV=test bin/rake db:create`
* `bin/rake db:migrate ; RAILS_ENV=test bin/rake db:migrate`

5. Get a database dump from Scott. Then:
* `pg_restore --verbose --clean --no-acl --no-owner -h localhost -d pbm_dev dump.file`

Start server: `bin/rails s`

Run tests: `bundle exec rspec`


## Docker Setup
### Prerequisites
* Docker >= v1.12.0+
* Docker-Compose (comes with Docker for Mac. Separate install on Linux)
* _Optional_: [direnv](http://direnv.net/) or some other way to source environment variables to override default ports in case of conflict

### Usage
#### Fully Containerized
* Run `docker-compose up -d` to start containers
* Navigate to `localhost:$PORT` (either specified, or defaults to `3000`)
* Bring down containers with `docker-compose down`
  * By default, the database will keep its state as a [docker volume](https://docs.docker.com/storage/volumes/). If you want to start fresh, run `docker-compose down -v` to destroy the volume. The next time you bring up this docker-compose file, `db:create` and `db:migrate` will re-populate the database.

#### Postgres only
If you just want to run postgres in a container and use your local filesystem for running Rails, you can use the postgres only compose file.
* Run `docker-compose -f docker-compose.postgres.yml up -d`
* If first time running, run `bin/rake db:create db:migrate` to populate the postgres container.
* Bring down containers with `docker-compose -f docker-compose.postgres.yml down`
  * By default, the database will keep its state as a [docker volume](https://docs.docker.com/storage/volumes/). If you want to start fresh, run `docker-compose -f docker-compose.postgres.yml down -v` to destroy the volume.
