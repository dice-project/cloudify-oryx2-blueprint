# coding=UTF-8

from cloudify import ctx
from cloudify.exceptions import NonRecoverableError
from subprocess import check_output, CalledProcessError


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


ctx.logger.info("[fix_fqdn] FQDN")
ctx.download_resource_and_render('templates/hosts', '/tmp/hosts')

sudo('mv', '/tmp/hosts', '/etc/hosts')
