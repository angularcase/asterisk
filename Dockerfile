FROM debian:bullseye-slim

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    git \
    libedit-dev \
    uuid-dev \
    libjansson-dev \
    libxml2-dev \
    libsqlite3-dev \
    libssl-dev \
    libsrtp2-dev \
    libspandsp-dev \
    libspeex-dev \
    libspeexdsp-dev \
    libcurl4-openssl-dev \
    libogg-dev \
    libvorbis-dev \
    libpq-dev \
    unixodbc-dev \
    libresample1-dev \
    libpopt-dev \
    libgsm1-dev \
    libopus-dev \
    libopusfile-dev \
    liblua5.2-dev \
    libiksemel-dev \
    libsnmp-dev \
    libunbound-dev \
    libldap2-dev \
    libmariadb-dev \
    libmariadb-dev-compat \
    libhiredis-dev \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Clone Asterisk repository
RUN git clone https://github.com/asterisk/asterisk.git /usr/src/asterisk

# Copy our modified res_audiosocket.c
COPY res/res_audiosocket.c /usr/src/asterisk/res/

# Build Asterisk
WORKDIR /usr/src/asterisk
RUN ./configure --with-jansson-bundled \
    && make menuselect.makeopts \
    && menuselect/menuselect --enable res_audiosocket menuselect.makeopts \
    && make -j$(nproc) \
    && make install \
    && make samples \
    && make config

# Create necessary directories
RUN mkdir -p /var/lib/asterisk \
    && mkdir -p /var/spool/asterisk \
    && mkdir -p /var/log/asterisk \
    && mkdir -p /var/run/asterisk \
    && mkdir -p /etc/asterisk

# Set up entrypoint
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

# Set environment variables
ENV ASTERISK_USER=asterisk \
    CONTAINER_TIMEZONE=UTC \
    SET_CONTAINER_TIMEZONE=false

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["asterisk", "-f"] 