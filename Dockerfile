# To refresh, copy the Digest from
# `docker buildx imagetools inspect cgr.dev/chainguard/wolfi-base:latest`
ARG WOLFI_BASE=cgr.dev/chainguard/wolfi-base@sha256:7e62cecd3c5712dba6e52c5260afb8f9d7a23b9bbcdd26ad7508a811e74b766d

FROM ${WOLFI_BASE} AS builder

ENV LUA_VER="5.5.0"
ENV LUA_CHECKSUM="57ccc32bbbd005cab75bcc52444052535af691789dba2b9016d5c50640d68b3d"
ENV LUAROCKS_VER="3.13.0"
ENV LUAROCKS_GPG_KEY="3FD8F43C2BB3C478"

# build-base bundles gcc, make, glibc-dev and the standard linker.
# gnupg is the umbrella, gpg supplies the cli binary, gnupg-dirmngr
# the network agent for keyserver lookups.
RUN apk add --no-cache build-base curl gnupg gnupg-dirmngr gpg gpg-agent

RUN curl -R -O -L http://www.lua.org/ftp/lua-${LUA_VER}.tar.gz && \
    [ "$(sha256sum lua-${LUA_VER}.tar.gz | cut -d' ' -f1)" = "${LUA_CHECKSUM}" ] && \
    tar -zxf lua-${LUA_VER}.tar.gz && \
    cd lua-${LUA_VER} && \
    make all install

RUN curl -R -O -L https://luarocks.org/releases/luarocks-${LUAROCKS_VER}.tar.gz && \
    curl -R -O -L https://luarocks.org/releases/luarocks-${LUAROCKS_VER}.tar.gz.asc && \
    gpg --keyserver keyserver.ubuntu.com --recv-keys ${LUAROCKS_GPG_KEY} && \
    gpg --verify luarocks-${LUAROCKS_VER}.tar.gz.asc luarocks-${LUAROCKS_VER}.tar.gz && \
    tar -zxpf luarocks-${LUAROCKS_VER}.tar.gz && \
    cd luarocks-${LUAROCKS_VER} && \
    ./configure && make && make install

RUN luarocks install busted


FROM ${WOLFI_BASE}

# Wolfi is glibc-based, so the Lua interpreter and busted's compiled
# C extensions built above run against Wolfi's glibc unmodified.
# bash + coreutils for the run scripts; lua/busted are otherwise
# pure-Lua and don't pull additional shared libraries.
RUN apk add --no-cache bash coreutils

COPY --from=builder /usr/local /usr/local

COPY . /opt/test-runner
WORKDIR /opt/test-runner
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
