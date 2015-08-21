# coding=UTF-8

from cloudify import ctx


rp = ctx.instance.runtime_properties

rp['zoo_fqdns'] = [rp['master_fqdn']] + rp['worker_fqdns']
rp['spark_worker_fqdns'] = list(rp['worker_fqdns'])
rp['spark_worker_fqdns_sh'] = ' '.join(rp['spark_worker_fqdns'])
rp['kafka_brokers_fqdns'] = map(lambda v: v + ':9092', [rp['master_fqdn']] + rp['worker_fqdns'])
rp['zookeeper_fqdns'] = map(lambda v: v + ':2181', [rp['master_fqdn']] + rp['worker_fqdns'])
rp['hdfs_base'] = 'hdfs:///user/ubuntu/Oryx'
