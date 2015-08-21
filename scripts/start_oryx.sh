#!/usr/bin/env bash

export ORYX_BIN=~/oryx
cd ${ORYX_BIN}

# Blatantly stolen from oryx-run.sh

ANY_JAR=$(ls -1 oryx-batch-*.jar oryx-speed-*.jar oryx-serving-*.jar | head -1)
CONFIG_FILE="oryx.conf"
CONFIG_PROPS=$(java -cp ${ANY_JAR} -Dconfig.file=${CONFIG_FILE} com.cloudera.oryx.common.settings.ConfigToProperties)

INPUT_ZK=$(echo "${CONFIG_PROPS}" | grep -E "^oryx\.input-topic\.lock\.master=.+$" | grep -oE "[^=]+$")
INPUT_KAFKA=$(echo "${CONFIG_PROPS}" | grep -E "^oryx\.input-topic\.broker=.+$" | grep -oE "[^=]+$")
INPUT_TOPIC=$(echo "${CONFIG_PROPS}" | grep -E "^oryx\.input-topic\.message\.topic=.+$" | grep -oE "[^=]+$")
UPDATE_ZK=$(echo "${CONFIG_PROPS}" | grep -E "^oryx\.update-topic\.lock\.master=.+$" | grep -oE "[^=]+$")
UPDATE_KAFKA=$(echo "${CONFIG_PROPS}" | grep -E "^oryx\.update-topic\.broker=.+$" | grep -oE "[^=]+$")
UPDATE_TOPIC=$(echo "${CONFIG_PROPS}" | grep -E "^oryx\.update-topic\.message\.topic=.+$" | grep -oE "[^=]+$")

ALL_TOPICS=$(kafka-topics --list --zookeeper ${INPUT_ZK} 2>&1 | grep -vE "^mkdir: cannot create directory")

if [ -z $(echo "${ALL_TOPICS}" | grep ${INPUT_TOPIC}) ]; then
    ctx logger info "[start_oryx] Creating input topc"
    kafka-topics --zookeeper ${INPUT_ZK} --create --replication-factor 2 --partitions 4 --topic ${INPUT_TOPIC} 2>&1 | grep -vE "^mkdir: cannot create directory"
fi
if [ -z `echo "${ALL_TOPICS}" | grep ${UPDATE_TOPIC}` ]; then
    ctx logger info "[start_oryx] Creating update topc"
    kafka-topics --zookeeper ${UPDATE_ZK} --create --replication-factor 2 --partitions 1 --topic ${UPDATE_TOPIC} 2>&1 | grep -vE "^mkdir: cannot create directory"
    kafka-topics --zookeeper ${UPDATE_ZK} --alter --topic ${UPDATE_TOPIC} --config retention.ms=86400000 --config max.message.bytes=16777216 2>&1 | grep -vE "^mkdir: cannot create directory"
fi

tmux new -d -s batch_layer './oryx-run.sh batch; read'
tmux new -d -s speed_layer './oryx-run.sh speed; read'
tmux new -d -s serving_layer './oryx-run.sh serving; read'
