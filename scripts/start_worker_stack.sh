#!/usr/bin/env bash

set -e

touch /tmp/alen

ctx logger info "Get key"
## Get HDFS key
ctx download_resource resources/hdfs.pem /tmp/hdfs.pem
ctx download_resource resources/hdfs.pem.pub /tmp/hdfs.pem.pub

ctx logger info "Set key"
## Todo: proper access through .ssh/config
## Create HDFS SSH settings
sudo -u hdfs mkdir -p ~hdfs/.ssh/
sudo -u hdfs cp /tmp/hdfs.pem ~hdfs/.ssh/id_rsa
sudo -u hdfs cp /tmp/hdfs.pem.pub ~hdfs/.ssh/id_rsa.pub
sudo -u hdfs touch ~hdfs/.ssh/authorized_keys
cat /tmp/hdfs.pem.pub | sudo -u hdfs tee -a ~hdfs/.ssh/authorized_keys
sudo -u hdfs chmod 600 ~hdfs/.ssh/id_rsa
sudo -u hdfs chmod 620 ~hdfs/.ssh/id_rsa.pub
sudo -u hdfs chmod 700 ~hdfs/.ssh/
sudo -u hdfs chown -R hdfs:hadoop ~hdfs/.ssh/
## Create Spark SSH settings - running as root for now - not necessary if start
#  script run on worker instance
sudo mkdir -p ~root/.ssh/
sudo cp /tmp/hdfs.pem ~root/.ssh/id_rsa
sudo cp /tmp/hdfs.pem.pub ~root/.ssh/id_rsa.pub
sudo touch ~root/.ssh/authorized_keys
cat /tmp/hdfs.pem.pub | sudo tee -a ~root/.ssh/authorized_keys
sudo chmod 600 ~root/.ssh/id_rsa
sudo chmod 620 ~root/.ssh/id_rsa.pub
sudo chmod 700 ~root/.ssh/
sudo chown -R root:root ~root/.ssh/

ctx logger info "Start Hadoop services"
## Start remaining Hadoop services
set +e
for service in $(cd /etc/init.d; ls hadoop-*); do
    sudo service ${service} start
done
set -e

ctx logger info "Start Zookeeper"
## Zookeeper
sudo service zookeeper-server start

ctx logger info "Spark slaves"
## Spark Slaves
slaves=$(ctx instance runtime-properties spark_worker_fqdns_sh)
source /etc/default/spark
sudo touch ${SPARK_CONF_DIR}/slaves
for slave in $(echo ${slaves}); do
    echo ${slave} | sudo tee -a ${SPARK_CONF_DIR}/slaves
done

ctx logger info "Spark config"
## Spark Config
sudo rm -f ${SPARK_CONF_DIR}/spark-worker-env.sh
sudo ln -s spark-env.sh ${SPARK_CONF_DIR}/spark-worker-env.sh
sudo rm -f ${SPARK_CONF_DIR}/spark-master-env.sh
sudo ln -s spark-env.sh ${SPARK_CONF_DIR}/spark-master-env.sh

ctx logger info "Spark service"
## Start Spark
# for service in $(cd /etc/init.d; ls spark-*); do
#     sudo service ${service} start
# done
# TODO: fix permissions etc.
sudo /usr/lib/spark/sbin/start-slave.sh 1 spark://$(ctx instance runtime-properties master_fqdn):7077

ctx logger info "Kafka bin"
## Kafka bin
source /etc/default/kafka
mkdir -p /tmp/kafka_bin
cd /tmp/kafka_bin
wget -qO- https://github.com/apache/kafka/archive/trunk.tar.gz | tar xzf - kafka-trunk/bin --exclude=kafka-trunk/bin/windows --strip-components=2 # --skip-old-files
for script in ./*.sh; do
    sed -i '0,/^$/s//\nsource \/etc\/default\/kafka\nif \[\[ \$(whoami) != kafka \]\]; then\n  exec sudo -u kafka -- "\$0" "\$@"\nfi\n/' ${script}
    sed -i 's/$0/${KAFKA_BIN}\/$(basename $0 .sh)\.sh/' ${script}
    chmod +x ${script}
    sudo cp ${script} ${KAFKA_BIN}/${script}
    sudo chown kafka:root ${script}
    sudo rm -f /usr/bin/$(basename ${script} .sh)
    sudo ln -s ${KAFKA_BIN}/$(basename ${script}) /usr/bin/$(basename ${script} .sh)
    sudo rm -f /usr/bin/$(basename ${script})
    sudo ln -s ${KAFKA_BIN}/$(basename ${script}) /usr/bin/$(basename ${script})
done

ctx logger info "Kafka service"
## Kafka service
set +e
sudo restart kafka
sudo start kafka
set -e
