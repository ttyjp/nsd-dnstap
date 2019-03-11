FROM alpine:3.9

LABEL maintainer "dorayaki (@ttyjp)"

ARG PROTOBUF_VERSION="3.6.1"
ARG PROTOBUF_C_VERSION="1.3.1"
ARG FSTRM_VERSION="0.4.0"

ARG NSD_VERSION="4.1.26"
ARG NSD_GPG_ID="0x9F6F1C2D7E045F8D"
ARG NSD_SHA256_HASH="9f8a41431d21034d64b9a910567b201636521b64b6a9947390bf898388dc15f4"

ARG BIND_VERSION="9.11.6"
ARG BIND_GPG_ID="0x74BB6B9A4CBB3D38"
ARG BIND_SHA256_HASH="4499007f3a6b8bba84fc757053caeabf36466d6f7d278baccef9fd109beac6d4"

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
  && : \
  && : "memo: NSD install" \
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
  && : \
  && : "memo: Use only dig and dnstap-read" \
  && cd /tmp \
  && wget https://ftp.isc.org/isc/bind9/${BIND_VERSION}/bind-${BIND_VERSION}.tar.gz \
  && wget https://ftp.isc.org/isc/bind9/${BIND_VERSION}/bind-${BIND_VERSION}.tar.gz.sha256.asc \
  && BIND_CHECKSUM=$(sha256sum bind-${BIND_VERSION}.tar.gz | head -c 64) \
  && if [ "${BIND_CHECKSUM}" != "${BIND_SHA256_HASH}" ]; then exit 1; fi \
  && gpg --keyserver keys.gnupg.net --recv-keys ${BIND_GPG_ID} \
  && gpg --verify bind-${BIND_VERSION}.tar.gz.sha256.asc bind-${BIND_VERSION}.tar.gz \
  && tar zxvf bind-${BIND_VERSION}.tar.gz \
  && cd bind-${BIND_VERSION} \
  && ./configure --disable-symtable --without-python --enable-dnstap \
  && make \
  && cp ./bin/dig/dig ./bin/tools/dnstap-read /usr/local/bin/ \
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