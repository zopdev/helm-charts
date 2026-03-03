#!/bin/bash
export JAVA_HOME="::JAVA_HOME::"
export PATH="::PATH::"
export HBASE_MANAGES_ZK=false
export HBASE_NO_REDIRECT_LOG=1
export HBASE_ROOT_LOGGER="INFO,console"
export HADOOP_ROOT_LOGGER="INFO,console"

echo "starting hbase master"
/opt/hbase/bin/hbase-daemon.sh foreground_start master &

sleep 20

echo "starting hbase regionserver"
/opt/hbase/bin/hbase-daemon.sh foreground_start regionserver &