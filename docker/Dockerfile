FROM debian:jessie
MAINTAINER chris500
USER root
RUN useradd -d "/app" -u 1000 -m -s /bin/bash elixir
RUN chown -R  elixir:elixir /app
USER elixir
ENV OTP_VERSION="21.0"

USER root
RUN apt-get update && apt-get install -y git curl autoconf gcc make libncurses-dev apt-utils openssl libssl-dev sed perl m4
RUN set -xe \
	&& OTP_DOWNLOAD_URL="https://github.com/erlang/otp/archive/OTP-${OTP_VERSION}.tar.gz" \
	&& runtimeDeps='libodbc1 \
	libsctp1' \
	&& buildDeps='unixodbc-dev \
	libsctp-dev' \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends $runtimeDeps \
	&& apt-get install -y --no-install-recommends $buildDeps \
	&& curl -fSL -o otp-src.tar.gz "$OTP_DOWNLOAD_URL" \
	&& mkdir -p /usr/src/otp-src \
	&& tar -xzf otp-src.tar.gz -C /usr/src/otp-src --strip-components=1 \
	&& rm otp-src.tar.gz \
	&& cd /usr/src/otp-src \
	&& ./otp_build autoconf \
	&& ./configure --enable-sctp \
	&& make -j$(nproc) \
	&& make install \
	&& find /usr/local -name examples | xargs rm -rf \
	&& apt-get purge -y --auto-remove $buildDeps \
	&& rm -rf /usr/src/otp-src /var/lib/apt/lists/*

ENV REBAR3_VERSION="3.6.1"

RUN set -xe \
	&& REBAR3_DOWNLOAD_URL="https://github.com/erlang/rebar3/archive/${REBAR3_VERSION}.tar.gz" \
	&& mkdir -p /usr/src/rebar3-src \
	&& curl -fSL -o rebar3-${REBAR3_VERSION}.tar.gz "$REBAR3_DOWNLOAD_URL" \
	&& tar -xzf rebar3-${REBAR3_VERSION}.tar.gz -C /usr/src/rebar3-src --strip-components=1 \
	&& rm rebar3-${REBAR3_VERSION}.tar.gz \
	&& cd /usr/src/rebar3-src \
	&& HOME=$PWD ./bootstrap \
	&& install -v ./rebar3 /usr/local/bin/ \
	&& rm -rf /usr/src/rebar3-src
user elixir
ENV ELIXIR_VERSION="v1.7.2" \
	LANG=C.UTF-8
user root
RUN set -xe \
	&& ELIXIR_DOWNLOAD_URL="https://github.com/elixir-lang/elixir/releases/download/${ELIXIR_VERSION}/Precompiled.zip" \
	&& buildDeps=' \
	unzip \
	' \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends $buildDeps \
	&& curl -fSL -o elixir-precompiled.zip $ELIXIR_DOWNLOAD_URL \
	&& unzip -d /usr/local elixir-precompiled.zip \
	&& rm elixir-precompiled.zip \
	&& apt-get purge -y --auto-remove $buildDeps \
	&& rm -rf /var/lib/apt/lists/*
user elixir
RUN  mix local.hex --force
RUN  mix local.rebar --force
CMD cd /app && mix local.hex --force && mix local.rebar --force && mix deps.get && mix ecto.create && mix ecto.migrate && iex -S mix
