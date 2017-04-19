[![Build Status](https://travis-ci.org/scottwainstock/pbm.svg?branch=master)](https://travis-ci.org/scottwainstock/pbm)
[![Coverage Status](https://coveralls.io/repos/scottwainstock/pbm/badge.png)](https://coveralls.io/r/scottwainstock/pbm)

*sweet pinballin' brah*

## API Documentation

Available here: [http://pinballmap.com/api/v1/docs](http://pinballmap.com/api/v1/docs)

## Mac Enviroment Setup
Below is a summary of the steps that [Brian Hanifin](https://github.com/brianhanifin) undertook to get the site up and running on OS X 10.9. If you would like to contribute, and have any trouble, please ask.

* Follow the Ruby install instructions at [railsapps.github.io/installrubyonrails-mac.html](http://railsapps.github.io/installrubyonrails-mac.html). Make sure you also download ruby-2.3.4.
* `cd /Projects-Path/`
* `git clone https://github.com/scottwainstock/pbm.git` (*I used the SourceTree app instead.*)
* `cd /Projects-Path/pbm`
* `rvm --default use ruby-2.3.4`
* `bundle install`
* `selenium install`
* `brew update && brew install phantomjs`
* `cp config/database.yml.example config/database.yml` to create your database.yml for development

* `brew install postgresql`
* `initdb /usr/local/var/postgres -E utf8`
* Download [Postgres App](http://postgresapp.com/). (*I have mine run at startup on my "Dev" profile.*)
* `bundle exec rake db:create ; RAILS_ENV=test bundle exec rake db:create`
* `bundle exec rake db:migrate ; RAILS_ENV=test bundle exec rake db:migrate`
* `rake doc:app`  (*I think this generates documentation for the app, which sounds helpful for later.*)
* `curl get.pow.cx | sh`
* `cd ~/.pow`
* `ln -s /Projects-Path/pbm`
* `open http://pbm.dev`

Start server: `bundle exec rails s`

Run tests: `bundle exec rspec`

If the site loads properly it will be an empty version of pinballmap.com, then ask Scott for a data dump so you can have a full set of data to work with.

## Linux Setup

1. Fork it. Then:

* `clone https://github.com/{you}/pbm.git`
* `git remote add upstream git://github.com/scottwainstock/pbm.git`

2. Install postgresql and pgadmin3 via package manager.

3. Setup postgres (good luck):

* ubuntu/debian/linux mint: [maybe this](https://www.codeproject.com/Articles/898303/Installing-and-Configuring-PostgreSQL-on-Linux-Min)
* arch/manjaro: [this](http://rmaicle.github.io/blog/2015/11/03/postgresql.html) and [then this](https://wiki.archlinux.org/index.php/PostgreSQL)

4. Install and setup ruby and rvm:

* `curl -L https://get.rvm.io | bash -s stable --ruby`
* `rvm install ruby-2.3.4`
* `rvm --default use ruby-2.3.4`
* `gem install bundler`
* `bundle install`
* `cp config/database.yml.example config/database.yml` to create your database.yml for development
* `bundle exec rake db:create ; RAILS_ENV=test bundle exec rake db:create`
* `bundle exec rake db:migrate ; RAILS_ENV=test bundle exec rake db:migrate`

5. Install phantomjs via package manager.

6. Get a database dump from Scott. Then:
* `pg_restore --verbose --clean --no-acl --no-owner -h localhost -d pbm_dev dump.file`

Start server: `bundle exec rails s`

Run tests: `bundle exec rspec`
