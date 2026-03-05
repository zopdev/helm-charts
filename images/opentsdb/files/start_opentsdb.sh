#!/bin/bash
export TSDB_VERSION="::TSDB_VERSION::"

echo "listing /data/hbase"
ls -lhat /data/hbase

if [ ! -e /data/hbase/opentsdb_tables_created.txt ]; then
    echo "creating tsdb tables"
    bash /opt/bin/create_tsdb_tables.sh
    echo "created tsdb tables"
fi

echo "starting opentsdb"
exec /usr/local/bin/tsdb tsd --port=4242 --staticroot=/usr/local/share/opentsdb/static --cachedir=/tmp/opentsdb --auto-metric
