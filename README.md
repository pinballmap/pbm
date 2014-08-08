[![Build Status](https://travis-ci.org/scottwainstock/pbm.svg?branch=master)](https://travis-ci.org/scottwainstock/pbm)

*sweet pinballin' brah*

##API Documentation

Available here: [http://pinballmap.com/api/v1/docs](http://pinballmap.com/api/v1/docs)

##Mac Enviroment Setup
Below is a summary of the steps that [Brian Hanifin](https://github.com/brianhanifin) undertook to get the site up and running on OS X 10.9. If you would like to contribute, and have any trouble, please ask.

* Follow the Ruby install instructions at [railsapps.github.io/installrubyonrails-mac.html](http://railsapps.github.io/installrubyonrails-mac.html). Make sure you also download ruby-1.9.3.
* `cd /Projects-Path/`
* `git clone https://github.com/scottwainstock/pbm.git` (*I used the SourceTree app instead.*)
* `cd /Projects-Path/pbm`
* `rvm --default use ruby-1.9.3`
* `bundle install`
* `selenium install`
* `brew update && brew install phantomjs`
* Create config/database.yml with the following:

```
development:
    adapter: postgresql
    encoding: utf8
    database: pbm_dev
    template: template0
    host: localhost

test: &test
    adapter: postgresql
    encoding: utf8
    database: pbm_test
    template: template0

production:
    adapter: postgresql
    encoding: utf8
    database: pbm
    username: root
    password:
    template: template0

cucumber:
    <<: *test
```

* `brew install postgresql`
* `initdb /usr/local/var/postres -E utf8`
* Download [Postgres App](http://postgresapp.com/). (*I have mine run at startup on my "Dev" profile.*)
* `bundle exec rake db:create ; RAILS_ENV=test bundle exec rake db:create`
* `bundle exec rake db:migrate ; RAILS_ENV=test bundle exec rake db:migrate`
* `bundle exec rspec`
* `rake doc:app`  (*I think this generates documentation for the app, which sounds helpful for later.*)
* `curl get.pow.cx | sh`
* `cd ~/.pow`
* `ln -s /Projects-Path/pbm`
* Edit config.ru: change `run Pbm::Application` to `self.run Pbm::Application` (Workaround: so Pow can run the site.)
* `open http://pbm.dev`

If the site loads properly it will be an empty version of pinballmap.com, then ask Scott for a data dump so you can have a full set of data to work with.
