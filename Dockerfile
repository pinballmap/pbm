FROM ruby:3.4.3-alpine3.19

WORKDIR /pbm

RUN apk update && apk add build-base postgresql-dev nodejs

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

CMD bundle exec rails s
