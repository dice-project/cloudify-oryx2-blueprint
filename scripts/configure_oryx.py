# coding=UTF-8

from cloudify import ctx
from cloudify.exceptions import NonRecoverableError
from subprocess import check_output, CalledProcessError
import os


def do(*args, **kwargs):
    try:
        return check_output(args), 0
    except CalledProcessError as e:
        if kwargs.get('fail_on_nonzero'):
            raise kwargs.get('exception', NonRecoverableError)(
                '[{}] {}'.format(e.cmd, e.message))
        else:
            return e.output, e.returncode


def sudo(*args, **kwargs):
    do('sudo', *args, **kwargs)


ORYX_BIN = os.path.expanduser('~/oryx')
cc = ORYX_BIN + '/compute-classpath.sh'
conf = ORYX_BIN + '/oryx.conf'
template_vars = ctx.instance.runtime_properties.copy()

do('rm', '-f', cc)
do('rm', '-f', conf)

ctx.download_resource('resources/compute-classpath.sh', cc)
ctx.download_resource_and_render('templates/oryx.conf', conf, template_vars)

do('chmod', '+x', cc)
