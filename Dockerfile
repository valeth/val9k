FROM ruby:2.4.1-slim 

MAINTAINER Patrick Auernig <patrick.auernig@gmail.com>

RUN apt-get update -qq \
 && apt-get install -qqy --no-install-recommends \
   build-essential \
   libpq-dev \
   git
 
ENV APP_ROOT /app
RUN mkdir -p $APP_ROOT
WORKDIR $APP_ROOT

COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .

ENTRYPOINT ["bundle", "exec", "rake", "run"]
