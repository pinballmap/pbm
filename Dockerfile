FROM ruby:2.5.1-alpine3.7
RUN apk update && apk add build-base postgresql-dev nodejs
RUN mkdir /pbm
WORKDIR /pbm
COPY Gemfile /pbm/Gemfile
COPY Gemfile.lock /pbm/Gemfile.lock
RUN bundle install
COPY . /pbm
ENTRYPOINT ["bundle", "exec", "rails", "s", "-p", "3000", "-b", "0.0.0.0"]
