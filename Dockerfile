FROM ruby:3.0.5-alpine3.16

WORKDIR /pbm

RUN apk update && apk add build-base postgresql-dev nodejs

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

CMD bundle exec rails s
