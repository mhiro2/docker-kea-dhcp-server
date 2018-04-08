FROM alpine:latest as builder

ARG KEA_DHCP_VERSION=1.3.0
ARG LOG4_CPLUS_VERSION=1.2.1

RUN apk add --no-cache --virtual .build-deps \
        alpine-sdk \
        bash \
        boost-dev \
        bzip2-dev \
        file \
        libressl-dev \
        mariadb-dev \
        zlib-dev && \
    curl -sL https://sourceforge.net/projects/log4cplus/files/log4cplus-stable/${LOG4_CPLUS_VERSION}/log4cplus-${LOG4_CPLUS_VERSION}.tar.gz | tar -zx -C /tmp && \
    cd /tmp/log4cplus-${LOG4_CPLUS_VERSION} && \
    ./configure && \
    make -s -j$(nproc) && \
    make install && \
    curl -sL https://ftp.isc.org/isc/kea/${KEA_DHCP_VERSION}/kea-${KEA_DHCP_VERSION}.tar.gz | tar -zx -C /tmp && \
    cd /tmp/kea-${KEA_DHCP_VERSION} && \
    ./configure \
        --enable-shell \
        --with-dhcp-mysql=/usr/bin/mysql_config && \
    make -s -j$(nproc) && \
    make install-strip && \
    apk del --purge .build-deps && \
    rm -rf /tmp/*

FROM alpine:latest
LABEL maintainer "mhiro2 <hirotsu.masaaki@gmail.com>"

RUN apk --no-cache add \
        bash \
        boost \
        bzip2 \
        libressl \
        mariadb-client-libs \
        zlib

COPY --from=builder /usr/local /usr/local/

ENTRYPOINT ["/usr/local/sbin/kea-dhcp4"]
CMD ["-c", "/usr/local/etc/kea/kea-dhcp4.conf"]
