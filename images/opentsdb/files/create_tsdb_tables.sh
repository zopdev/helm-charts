#!/bin/bash

export COMPRESSION="NONE"
export HBASE_HOME=/opt/hbase
export TSDB_VERSION="::TSDB_VERSION::"
export JAVA_HOME="::JAVA_HOME::"

# https://github.com/OpenTSDB/opentsdb/issues/1481
sed -i "s/, TTL => '\$TSDB_TTL'//g" /usr/local/share/opentsdb/tools/create_table.sh

/usr/local/share/opentsdb/tools/create_table.sh
touch /data/hbase/opentsdb_tables_created.txt
