FROM ubuntu:20.04

# Install dependencies
RUN apt-get update && \
    apt-get install -y curl gcc jq make unzip

# Install Lua
RUN curl -R -O http://www.lua.org/ftp/lua-5.4.3.tar.gz && \
    tar zxf lua-5.4.3.tar.gz && \
    cd lua-5.4.3 && \
    make all install

# Install Luarocks
RUN curl -R -O -L https://luarocks.org/releases/luarocks-3.5.0.tar.gz && \
    tar zxpf luarocks-3.5.0.tar.gz && \
    cd luarocks-3.5.0 && \
    ./configure && make && make install

# Install Luarocks packages
RUN luarocks install busted

# Cleanup
RUN rm -rf /var/lib/apt/lists/* && \
    apt-get purge --auto-remove && \
    apt-get clean

COPY . /opt/test-runner
WORKDIR /opt/test-runner
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
