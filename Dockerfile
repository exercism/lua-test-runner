FROM ubuntu:24.04

ENV LUA_VER="5.5.0"
ENV LUA_CHECKSUM="57ccc32bbbd005cab75bcc52444052535af691789dba2b9016d5c50640d68b3d"
ENV LUAROCKS_VER="3.13.0"
ENV LUAROCKS_GPG_KEY="3FD8F43C2BB3C478"

RUN apt-get update && \
    apt-get install -y curl gcc jq make unzip gnupg git && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get purge --auto-remove && \
    apt-get clean

RUN curl -R -O -L http://www.lua.org/ftp/lua-${LUA_VER}.tar.gz && \
    [ "$(sha256sum lua-${LUA_VER}.tar.gz | cut -d' ' -f1)" = "${LUA_CHECKSUM}" ] && \
    tar -zxf lua-${LUA_VER}.tar.gz && \
    cd lua-${LUA_VER} && \
    make all install && \
    cd .. && \
    rm lua-${LUA_VER}.tar.gz && \
    rm -rf lua-${LUA_VER}

RUN curl -R -O -L https://luarocks.org/releases/luarocks-${LUAROCKS_VER}.tar.gz && \
    curl -R -O -L https://luarocks.org/releases/luarocks-${LUAROCKS_VER}.tar.gz.asc && \
    gpg --keyserver keyserver.ubuntu.com --recv-keys ${LUAROCKS_GPG_KEY} && \
    gpg --verify luarocks-${LUAROCKS_VER}.tar.gz.asc luarocks-${LUAROCKS_VER}.tar.gz && \
    tar -zxpf luarocks-${LUAROCKS_VER}.tar.gz && \
    cd luarocks-${LUAROCKS_VER} && \
    ./configure && make && make install && \
    cd .. && \
    rm luarocks-${LUAROCKS_VER}.tar.gz.asc && \
    rm luarocks-${LUAROCKS_VER}.tar.gz && \
    rm -rf luarocks-${LUAROCKS_VER}

RUN luarocks install busted

COPY . /opt/test-runner
WORKDIR /opt/test-runner
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
