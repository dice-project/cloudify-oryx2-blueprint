# coding=UTF-8

from cloudify import ctx


src = ctx.source.instance.runtime_properties
tgt = ctx.target.instance.runtime_properties

for k, v in tgt.items():
    src[k] = v
