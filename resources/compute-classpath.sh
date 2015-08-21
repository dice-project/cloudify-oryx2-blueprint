#!/usr/bin/env bash

source /etc/default/hadoop
source /etc/default/zookeeper-server
SPARK_HOME=/usr/lib/spark

echo ${HADOOP_CONF_DIR}
ls -1 \
 ${ZOOKEEPER_HOME}/zookeeper-*.jar \
 ${SPARK_HOME}/lib/spark-assembly-*.jar \
 ${SPARK_HOME}/lib/spark-examples-*.jar \
 ${HADOOP_HOME}/hadoop-auth-*.jar \
 ${HADOOP_HOME}/hadoop-common-*.jar \
 ${HADOOP_HDFS_HOME}/hadoop-hdfs-*.jar \
 ${HADOOP_MAPRED_HOME}/hadoop-mapreduce-client-core-*.jar \
 ${HADOOP_YARN_HOME}/hadoop-yarn-api-*.jar \
 ${HADOOP_YARN_HOME}/hadoop-yarn-client-*.jar \
 ${HADOOP_YARN_HOME}/hadoop-yarn-common-*.jar \
 ${HADOOP_YARN_HOME}/hadoop-yarn-server-web-proxy-*.jar \
 ${HADOOP_YARN_HOME}/hadoop-yarn-applications-distributedshell-*.jar \
 ${HADOOP_HOME}/lib/htrace-core-3.0.4.jar \
 ${HADOOP_HOME}/lib/commons-cli-1.2.jar \
 ${HADOOP_HOME}/lib/commons-collections-*.jar \
 ${HADOOP_HOME}/lib/commons-configuration-*.jar \
 ${HADOOP_HOME}/lib/commons-lang-2.6.jar \
 ${HADOOP_HOME}/lib/protobuf-java-*.jar \
 ${HADOOP_HOME}/lib/snappy-java-*.jar \
 | grep -E "[0-9]\\.jar$"
