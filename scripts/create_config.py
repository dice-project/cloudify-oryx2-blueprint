# coding=UTF-8

from cloudify import ctx


rp = ctx.instance.runtime_properties

none = ['master_ip', 'master_fqdn']
empty = ['worker_ips', 'worker_fqdns', 'zoo_fqdns', 'spark_worker_fqdns',
         'kafka_brokers_fqdns']
counters = ['broker_id']

for n in none:
    rp[n] = None

for e in empty:
    rp[e] = []

for c in counters:
    rp[c] = 0
