# Build stage
FROM debian:bullseye-slim AS builder

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

# Find all Asterisk libraries
RUN find /usr/lib -name "libasterisk*.so*" -ls

# Final stage
FROM debian:bullseye-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libedit2 libjansson4 libxml2 libsqlite3-0 libssl1.1 \
    libsrtp2-1 libspandsp2 libspeex1 libspeexdsp1 libcurl4 \
    libogg0 libvorbis0a libpq5 unixodbc libresample1 libpopt0 \
    libgsm1 libopus0 libopusfile0 liblua5.2-0 libiksemel3 \
    libsnmp40 libunbound8 libldap-2.4-2 libmariadb3 libhiredis0.14 \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Create asterisk user
RUN useradd -m -d /var/lib/asterisk -s /bin/bash asterisk

# Copy built Asterisk from builder stage
COPY --from=builder /usr/lib/asterisk /usr/lib/asterisk
COPY --from=builder /usr/sbin/asterisk /usr/sbin/asterisk
COPY --from=builder /var/lib/asterisk /var/lib/asterisk
COPY --from=builder /var/spool/asterisk /var/spool/asterisk
COPY --from=builder /var/log/asterisk /var/log/asterisk
COPY --from=builder /var/run/asterisk /var/run/asterisk
COPY --from=builder /etc/asterisk /etc/asterisk

# Copy all Asterisk libraries
COPY --from=builder /usr/lib/libasterisk*.so* /usr/lib/

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

# Modify Asterisk to run in foreground by default
#RUN sed -i 's/^\[directories\]/\[directories\]\nrunuser = asterisk\nrungroup = asterisk/' /etc/asterisk/asterisk.conf

ENTRYPOINT ["/docker-entrypoint.sh"]
# CMD ["asterisk", "-f"]
CMD ["tail", "-f", "/dev/null"]