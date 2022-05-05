[![Coverage Status](https://coveralls.io/repos/scottwainstock/pbm/badge.png)](https://coveralls.io/r/scottwainstock/pbm)

*sweet pinballin' brah*

This repo is the codebase for [pinballmap.com](https://pinballmap.com). The code for the [Pinball Map mobile app is here](https://github.com/bpoore/pbm-react). If you have an app issue, please use that repo.


## API Documentation

Available here: [http://pinballmap.com/api/v1/docs](http://pinballmap.com/api/v1/docs)

## Mac Environment Setup
Below is a summary of the steps that [Brian Hanifin](https://github.com/brianhanifin) undertook to get the site up and running on OS X 10.9. If you would like to contribute, and have any trouble, please ask.

* Follow the Ruby install instructions at [railsapps.github.io/installrubyonrails-mac.html](http://railsapps.github.io/installrubyonrails-mac.html). Make sure you also download ruby-2.6.9.
* `cd /Projects-Path/`
* `git clone https://github.com/pinballmap/pbm.git` (*I used the SourceTree app instead.*)
* `cd /Projects-Path/pbm`
* `rvm --default use ruby-2.6.9`
* `bundle install`
* `selenium install`
* `brew update`
* `cp config/database.yml.example config/database.yml` to create your database.yml for development

* `brew install postgresql`
* `initdb /usr/local/var/postgres -E utf8`
* Download [Postgres App](http://postgresapp.com/). (*I have mine run at startup on my "Dev" profile.*)
* `CREATEDB pbm_dev`
* `bundle exec rake db:create ; RAILS_ENV=test bundle exec rake db:create`
* `bundle exec rake db:migrate ; RAILS_ENV=test bundle exec rake db:migrate`
* `rake doc:app`  (*I think this generates documentation for the app, which sounds helpful for later.*)
* `curl get.pow.cx | sh`
* `cd ~/.pow`
* `ln -s /Projects-Path/pbm`
* `open http://pbm.dev`

Start server: `bundle exec rails s`

Run tests: `bundle exec rake`

If the site loads properly it will be an empty version of pinballmap.com, then ask Scott for a data dump so you can have a full set of data to work with.

## Linux Setup

1. Fork it. Then:

* `clone https://github.com/{you}/pbm.git`
* `git remote add upstream git://github.com/pinballmap/pbm.git`

2. Install postgresql.

3. Setup postgres:

* createuser --interactive
* createdb pbm_dev

or read:

* ubuntu/debian/linux mint: [maybe this](https://www.codeproject.com/Articles/898303/Installing-and-Configuring-PostgreSQL-on-Linux-Min)
* arch/manjaro: [this](http://rmaicle.github.io/posts/b1n4mAMm9P34wNR) and [then this](https://wiki.archlinux.org/index.php/PostgreSQL)

4. Install and setup ruby and rvm:

* `curl -L https://get.rvm.io | bash -s stable --ruby`
* `rvm install ruby-2.6.9`
* `rvm --default use ruby-2.6.9`
* `gem install bundler`
* `bundle install`
* `cp config/database.yml.example config/database.yml` to create your database.yml for development
* `bundle exec rake db:create ; RAILS_ENV=test bundle exec rake db:create`
* `bundle exec rake db:migrate ; RAILS_ENV=test bundle exec rake db:migrate`

5. Get a database dump from Scott. Then:
* `pg_restore --verbose --clean --no-acl --no-owner -h localhost -d pbm_dev dump.file`

Start server: `bundle exec rails s`

Run tests: `bundle exec rake`


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
* If first time running, run `bundle exec rake db:create db:migrate` to populate the postgres container.
* Bring down containers with `docker-compose -f docker-compose.postgres.yml down`
  * By default, the database will keep its state as a [docker volume](https://docs.docker.com/storage/volumes/). If you want to start fresh, run `docker-compose -f docker-compose.postgres.yml down -v` to destroy the volume.
