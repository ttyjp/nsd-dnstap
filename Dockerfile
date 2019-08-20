FROM alpine:3.9

LABEL maintainer "dorayaki (@ttyjp)"

ARG PROTOBUF_VERSION="3.6.1"
ARG PROTOBUF_C_VERSION="1.3.1"
ARG FSTRM_VERSION="0.4.0"

ARG NSD_VERSION="4.1.26"
ARG NSD_GPG_ID="0x9F6F1C2D7E045F8D"
ARG NSD_SHA256_HASH="9f8a41431d21034d64b9a910567b201636521b64b6a9947390bf898388dc15f4"

RUN set -ex \
  && apk add libgcc libevent openssl \
  && apk add --virtual build-dependencies \
      build-base \
      linux-headers \
      curl \
      automake \
      autoconf \
      libtool \
      libevent-dev \
      openssl-dev \
      gnupg \
  && mkdir /tmp/protobuf \
  && curl -L https://github.com/google/protobuf/archive/v${PROTOBUF_VERSION}.tar.gz \
  | tar zxv --strip-components=1 -C /tmp/protobuf \
  && mkdir /tmp/protobuf-c \
  && curl -L https://github.com/protobuf-c/protobuf-c/releases/download/v${PROTOBUF_C_VERSION}/protobuf-c-${PROTOBUF_C_VERSION}.tar.gz \
  | tar zxv --strip-components=1 -C /tmp/protobuf-c \
  && mkdir /tmp/fstrm \
  && curl -L https://github.com/farsightsec/fstrm/archive/v${FSTRM_VERSION}.tar.gz \
  | tar zxv --strip-components=1 -C /tmp/fstrm \
  && cd /tmp/protobuf \
  && ./autogen.sh \
  && ./configure \
  && make && make install \
  && cd /tmp/protobuf-c \
  && ./configure \
  && make \
  && cd /tmp/protobuf \
  && make install \
  && cd /tmp/protobuf-c \
  && make install \
  && cd /tmp/fstrm \
  && ./autogen.sh \
  && ./configure \
  && make && make install \
  && cd /tmp \
  && wget https://www.nlnetlabs.nl/downloads/nsd/nsd-${NSD_VERSION}.tar.gz \
  && wget https://www.nlnetlabs.nl/downloads/nsd/nsd-${NSD_VERSION}.tar.gz.asc \
  && NSD_CHECKSUM=$(sha256sum nsd-${NSD_VERSION}.tar.gz | head -c 64) \
  && if [ "${NSD_CHECKSUM}" != "${NSD_SHA256_HASH}" ]; then exit 1; fi \
  && gpg --keyserver keys.gnupg.net --recv-keys ${NSD_GPG_ID} \
  && gpg --verify nsd-${NSD_VERSION}.tar.gz.asc nsd-${NSD_VERSION}.tar.gz \
  && tar zxvf nsd-${NSD_VERSION}.tar.gz \
  && cd nsd-${NSD_VERSION} \
  && ./configure --enable-zone-stats --enable-dnstap \
  && make && make install \
  && apk del build-dependencies \
  && cd /usr/local/lib \
  && rm -rf $(ls | grep -v "libfstrm.so\|libprotobuf-c.so") \
      /tmp/* \
      /root/.gnupg \
      /usr/local/include/* \
      /usr/local/share/* \
      /var/cache/apk/* \
      /usr/local/bin/protoc*

CMD ["sh"]