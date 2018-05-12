FROM ruby:2.4.1-slim

MAINTAINER Alfredo Ramírez <alfredormz@gmail.com>

ENV PAGER="more"

RUN \
  apt-get update && \
  apt-get -y install build-essential libpq-dev

ENV HOME /root

WORKDIR /app

COPY .gems /tmp/

RUN \
  gem install dep:1.1.0 && \
  cd /tmp/ && \
  dep -f .gems install && dep -f .gems && rm .gems

COPY . /app/
