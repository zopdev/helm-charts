# -------------------------------
# Base OS
# -------------------------------
# Alpine is used for a small image footprint.
# This does NOT affect data safety or versions.
FROM alpine:3.23


# -------------------------------
# Version pinning (CRITICAL)
# -------------------------------
# These versions MUST match the currently running custom image
# to ensure binary compatibility with existing HBase data.
ENV TINI_VERSION v0.18.0
ENV TSDB_VERSION 2.3.1
ENV HBASE_VERSION 1.4.4
ENV GNUPLOT_VERSION 5.2.4


# -------------------------------
# Java configuration (CRITICAL)
# -------------------------------
# OpenTSDB + HBase 1.4.x REQUIRE Java 8.
# Changing Java version can cause WAL or serialization issues.
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/bin/


# -------------------------------
# Runtime & build dependencies
# -------------------------------
# ALPINE_PACKAGES:
#   Runtime dependencies required for OpenTSDB, HBase and gnuplot.
#
# BUILD_PACKAGES:
#   Only required at build time (OpenTSDB & gnuplot compilation).
#   These are removed later to keep image size small.
ENV ALPINE_PACKAGES "rsyslog bash openjdk8 make wget libgd libpng libjpeg libwebp libjpeg-turbo cairo pango lua"
ENV BUILD_PACKAGES "build-base autoconf automake git python3-dev cairo-dev pango-dev gd-dev lua-dev readline-dev libpng-dev libjpeg-turbo-dev libwebp-dev sed"


# -------------------------------
# JVM tuning for containers
# -------------------------------
# CMS GC + cgroup memory flags.
# These flags DO NOT affect stored data.
ENV HBASE_OPTS "-XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -XX:InitiatingHeapOccupancyPercent=70"
ENV JVMARGS "-XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -enableassertions -enablesystemassertions"


# -------------------------------
# Tini init system
# -------------------------------
# WHY THIS LINK:
# https://github.com/krallin/tini
#
# Tini ensures:
# - Proper signal handling
# - Clean shutdown of HBase & OpenTSDB
# - WALs are flushed correctly on SIGTERM
#
# This is IMPORTANT for avoiding WAL corruption.
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-amd64 /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]


# -------------------------------
# Install runtime packages
# -------------------------------
RUN apk --update add apk-tools \
    && apk add ${ALPINE_PACKAGES} \
    # Repository required for gnuplot dependencies
    --repository http://dl-cdn.alpinelinux.org/alpine/v3.0/testing/ \
    && mkdir -p /opt/opentsdb


# -------------------------------
# OpenTSDB build preparation
# -------------------------------
WORKDIR /opt/opentsdb/
RUN set -ex && apk add --virtual builddeps ${BUILD_PACKAGES}

# OpenTSDB build scripts expect `python` binary
RUN ln -sf /usr/bin/python3 /usr/bin/python


# -------------------------------
# Download OpenTSDB source
# -------------------------------
# WHY THIS LINK:
# https://github.com/OpenTSDB/opentsdb
#
# We build from source to:
# - Control version precisely
# - Match existing deployment
RUN wget --no-check-certificate \
    -O v${TSDB_VERSION}.zip \
    https://github.com/OpenTSDB/opentsdb/archive/v${TSDB_VERSION}.zip \
  && unzip v${TSDB_VERSION}.zip \
  && rm v${TSDB_VERSION}.zip \
  && cd /opt/opentsdb/opentsdb-${TSDB_VERSION} \
  # HTTP tuning (runtime behavior, not data-related)
  && echo "tsd.http.request.enable_chunked = true" >> src/opentsdb.conf \
  && echo "tsd.http.request.max_chunk = 1000000" >> src/opentsdb.conf


# -------------------------------
# Maven repository fixes
# -------------------------------
# WHY THIS EXISTS:
# Older OpenTSDB builds referenced HTTP Maven endpoints.
# This rewrites them to HTTPS to avoid build failures.
RUN cd /opt/opentsdb/opentsdb-${TSDB_VERSION} \
  && find . | xargs grep -s central.maven.org | cut -f1 -d : | xargs sed -i "s/http:\/\/central/https:\/\/repo1/g" \
  && find . | xargs grep -s repo1.maven.org | cut -f1 -d : | xargs sed -i "s/http:\/\/repo1/https:\/\/repo1/g"


# -------------------------------
# Build & install OpenTSDB
# -------------------------------
RUN cd /opt/opentsdb/opentsdb-${TSDB_VERSION} \
  && ./build.sh \
  && cp build-aux/install-sh build/build-aux \
  && cd build \
  && make install \
  && cd / \
  && rm -rf /opt/opentsdb/opentsdb-${TSDB_VERSION}


# -------------------------------
# Install gnuplot
# -------------------------------
# WHY THIS LINK:
# https://sourceforge.net/projects/gnuplot/
#
# gnuplot is used by OpenTSDB for graph rendering.
RUN apk add --no-cache gnuplot

# -------------------------------
# Cleanup build dependencies
# -------------------------------
RUN apk del builddeps && rm -rf /var/cache/apk/*


# -------------------------------
# Install HBase
# -------------------------------
# WHY THIS LINK:
# http://archive.apache.org/dist/hbase/
#
# Apache archive ensures we always get the exact version
# required for compatibility with existing HBase data.
RUN mkdir -p /data/hbase /root/.profile.d /opt/downloads
WORKDIR /opt/downloads
RUN wget -O hbase-${HBASE_VERSION}.bin.tar.gz http://archive.apache.org/dist/hbase/${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz \
    && tar xzvf hbase-${HBASE_VERSION}.bin.tar.gz \
    && mv hbase-${HBASE_VERSION} /opt/hbase \
    && rm -r /opt/hbase/docs \
    && rm hbase-${HBASE_VERSION}.bin.tar.gz


# -------------------------------
# Config & startup scripts
# -------------------------------
RUN ln -s /usr/local/share/opentsdb/etc/opentsdb /etc/opentsdb \
    && rm /etc/opentsdb/opentsdb.conf \
    && mkdir /opentsdb-plugins

ADD opentsdb/files/opentsdb.conf /etc/opentsdb/opentsdb.conf
ADD opentsdb/files/hbase-site.xml /opt/hbase/conf/hbase-site.xml.sample
ADD opentsdb/files/start_opentsdb.sh /opt/bin/
ADD opentsdb/files/create_tsdb_tables.sh /opt/bin/
ADD opentsdb/files/start_hbase.sh /opt/bin/
ADD opentsdb/files/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh /opt/bin/start_opentsdb.sh /opt/bin/start_hbase.sh /opt/bin/create_tsdb_tables.sh


# -------------------------------
# Script variable substitution
# -------------------------------
RUN for i in /opt/bin/start_hbase.sh /opt/bin/start_opentsdb.sh /opt/bin/create_tsdb_tables.sh; \
    do \
        sed -i "s#::JAVA_HOME::#$JAVA_HOME#g; s#::PATH::#$PATH#g; s#::TSDB_VERSION::#$TSDB_VERSION#g;" $i; \
    done


# -------------------------------
# HBase environment config
# -------------------------------
RUN echo "export HBASE_OPTS=\"${HBASE_OPTS}\"" >> /opt/hbase/conf/hbase-env.sh


# -------------------------------
# Exposed ports
# -------------------------------
# 4242  -> OpenTSDB API
# 16010 -> HBase Master UI
# 16070 -> HBase RegionServer UI
EXPOSE 60000 60010 60030 4242 16010 16070


# -------------------------------
# Persistent volumes (CRITICAL)
# -------------------------------
# /data/hbase:
#   ALL OpenTSDB data lives here.
#   PVC MUST be reused to avoid data loss.
VOLUME ["/data/hbase", "/tmp", "/opentsdb-plugins"]


# -------------------------------
# Startup
# -------------------------------
CMD ["/entrypoint.sh"]