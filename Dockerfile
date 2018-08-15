FROM ruby:2.5.1
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
RUN mkdir /pbm
WORKDIR /pbm
COPY Gemfile /pbm/Gemfile
COPY Gemfile.lock /pbm/Gemfile.lock
RUN bundle install
COPY . /pbm
