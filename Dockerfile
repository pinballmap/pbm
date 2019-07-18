FROM ruby:2.6.2-alpine3.9

WORKDIR /pbm

RUN apk update && apk add build-base postgresql-dev nodejs

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

CMD bundle exec rails s
