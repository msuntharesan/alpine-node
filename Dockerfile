FROM alpine:edge
MAINTAINER Suntharesan Mohan <mohan.kethees@gmail.com>

ENV NPM_CONFIG_LOGLEVEL=info \
    NODE_VERSION=5.11.1

RUN apk add --no-cache --virtual .build-deps \
        gcc \
        g++ \
        libc-dev \
        make \
        python \
        linux-headers \
        zlib-dev \
        libuv-dev \
        paxctl \
        binutils-gold \
        gnupg \
        curl \
        icu-dev \
        openssl-dev \
        pax-utils
RUN for key in \
        9554F04D7259F04124DE6B476D5A82AC7E37093B \
        94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
        0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
        FD3A5288F042B6850C66B31F09FE44734EB7990E \
        71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
        DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
        B9AE9905FFD7803F25714661B63B535A4C206CA9 \
        C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    ; do gpg --keyserver pool.sks-keyservers.net --recv-keys "$key"; \
    done
RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION.tar.xz" \
    && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xJf node-v$NODE_VERSION.tar.xz \
    && cd node-v$NODE_VERSION \
    && export GYP_DEFINES="linux_use_gold_flags=0" \
    && ./configure --prefix=/usr --with-intl=system-icu --shared-zlib --shared-libuv --shared-openssl --fully-static \
    && NPROC=$(getconf _NPROCESSORS_ONLN) \
    && make -j$(NPROC) -C out mksnapshot BUILDTYPE=Release \
    && paxctl -cm out/Release/mksnapshot \
    && make -j$(NPROC) \
    && make install \
    && paxctl -cm /usr/bin/node \
    && cd / \
    && apk del .build-deps \
    && rm -rf \
      /etc/ssl \
      /node-v$NODE_VERSION.tar.xz \
      /node-v$NODE_VERSION \
      /SHASUMS256.txt.asc \
      /SHASUMS256.txt \
      /usr/share/doc \
      /usr/share/man \
      /usr/share/doc \
      /tmp/* \
      /var/cache/apk/* \
      /root/.npm \
      /root/.node-gyp \
      /root/.gnupg \
      /usr/lib/node_modules/npm/man \
      /usr/lib/node_modules/npm/doc \
      /usr/lib/node_modules/npm/html


# # For base builds
# # ENV CONFIG_FLAGS="--without-npm" RM_DIRS=/usr/include
# ENV CONFIG_FLAGS="--fully-static --without-npm" DEL_PKGS="libgcc libstdc++" RM_DIRS=/usr/include

# RUN apk add --no-cache curl make gcc g++ python linux-headers paxctl libgcc libstdc++ gnupg && \
#   gpg --keyserver pool.sks-keyservers.net --recv-keys 9554F04D7259F04124DE6B476D5A82AC7E37093B && \
#   gpg --keyserver pool.sks-keyservers.net --recv-keys 94AE36675C464D64BAFA68DD7434390BDBE9B9C5 && \
#   gpg --keyserver pool.sks-keyservers.net --recv-keys 0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 && \
#   gpg --keyserver pool.sks-keyservers.net --recv-keys FD3A5288F042B6850C66B31F09FE44734EB7990E && \
#   gpg --keyserver pool.sks-keyservers.net --recv-keys 71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 && \
#   gpg --keyserver pool.sks-keyservers.net --recv-keys DD8F2338BAE7501E3DD5AC78C273792F7D83545D && \
#   gpg --keyserver pool.sks-keyservers.net --recv-keys C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 && \
#   gpg --keyserver pool.sks-keyservers.net --recv-keys B9AE9905FFD7803F25714661B63B535A4C206CA9 && \
#   curl -o node-${VERSION}.tar.gz -sSL https://nodejs.org/dist/${VERSION}/node-${VERSION}.tar.gz && \
#   curl -o SHASUMS256.txt.asc -sSL https://nodejs.org/dist/${VERSION}/SHASUMS256.txt.asc && \
#   gpg --verify SHASUMS256.txt.asc && \
#   grep node-${VERSION}.tar.gz SHASUMS256.txt.asc | sha256sum -c - && \
#   tar -zxf node-${VERSION}.tar.gz && \
#   cd node-${VERSION} && \
#   export GYP_DEFINES="linux_use_gold_flags=0" && \
#   ./configure --prefix=/usr ${CONFIG_FLAGS} && \
#   NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
#   make -j${NPROC} -C out mksnapshot BUILDTYPE=Release && \
#   paxctl -cm out/Release/mksnapshot && \
#   make -j${NPROC} && \
#   make install && \
#   paxctl -cm /usr/bin/node && \
#   cd / && \
#   if [ -x /usr/bin/npm ]; then \
#     npm install -g npm@${NPM_VERSION} && \
#     find /usr/lib/node_modules/npm -name test -o -name .bin -type d | xargs rm -rf; \
#   fi && \
#   apk del curl make gcc g++ python linux-headers paxctl gnupg ${DEL_PKGS} && \
#   rm -rf /etc/ssl /node-${VERSION}.tar.gz /SHASUMS256.txt.asc /node-${VERSION} ${RM_DIRS} \
#     /usr/share/man /tmp/* /var/cache/apk/* /root/.npm /root/.node-gyp /root/.gnupg \
#     /usr/lib/node_modules/npm/man /usr/lib/node_modules/npm/doc /usr/lib/node_modules/npm/html
