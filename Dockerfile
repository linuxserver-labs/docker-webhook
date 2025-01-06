# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-alpine:3.21 AS buildstage

# build variables
ARG APP_VERSION

# hadolint ignore=DL3018
RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache \
    curl \
    g++ \
    gcc \
    git \
    go \
    tar && \
  echo "**** fetch source code ****" && \
  if [ -z ${APP_VERSION+x} ]; then \
    APP_VERSION=$(curl -sX GET "https://api.github.com/repos/adnanh/webhook/releases/latest" | \
    awk '/tag_name/{print $4;exit}' FS='[""]') \
  ;fi && \
  mkdir -p /tmp/webhook && \
  curl -o /tmp/webhook-src.tar.gz -L \
    "https://github.com/adnanh/webhook/archive/${APP_VERSION}.tar.gz" && \
  tar xf /tmp/webhook-src.tar.gz -C /tmp/webhook --strip-components=1 && \
  echo "**** compile webhook  ****" && \
  cd /tmp/webhook && \
  rm -f go.sum && \
  go get -d && \
  go build -o /app/webhook

FROM ghcr.io/linuxserver/baseimage-alpine:3.21

ARG BUILD_DATE
ARG VERSION
ARG APP_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"

LABEL maintainer="Roxedus"

# copy files from build stage and local files
COPY --from=buildstage /app/webhook /app/webhook
COPY root/ /
