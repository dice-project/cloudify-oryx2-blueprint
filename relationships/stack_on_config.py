# coding=UTF-8

from cloudify import ctx
from fcntl import lockf, LOCK_EX, LOCK_UN
from os import getpid
import uuid


class FileLock(object):

    """A file lock to prevent race conditions."""

    def __init__(self, lock_file=None, log_file=None, lock_details=None):
        """
        Register lock and log file.

        :param lock_file: path to the lock file, does not have to exist
        :param log_file: path to the log file, does not have to exist
        :return:
        """
        self.lock_file = lock_file or '/tmp/lock-' + str(uuid.uuid1())
        self.log_file = log_file or self.lock_file + '.log'
        if lock_details is None:
            self.lock_details = ''
        elif isinstance(lock_details, basestring):
            self.lock_details = lock_details
        elif isinstance(lock_details, dict):
            self.lock_details = '\n'.join('{} {}'.format(k, v)
                                           for k, v in lock_details.items())
        elif isinstance(lock_details, list):
            self.lock_details = '\n'.join(map(str, lock_details))
        else:
            self.lock_details = str(lock_details)
        self.acquired = False


    def __enter__(self):
        """
        Open lock and log files, write

        :return: reference to instantiated lock
        """
        self._acquire()
        return self


    def __exit__(self, exc_type, _v, _tb):
        """
        Clean up and release any locks, close open files.

        :param exc_type: part of generic signature
        :param _v:  part of generic signature
        :param _tb: part of generic signature
        :return:
        """
        self._release()


    def _acquire(self):
        """
        Open lock and log files, write identification details into lock.

        :return:
        """
        self.lock_fd = open(self.lock_file, 'w+')
        self.log_fd = open(self.log_file, 'a')

        lockf(self.lock_fd, LOCK_EX)

        self.lock_fd.truncate()
        self.lock_fd.write('lock_pid {}\nlock_status locked\n{}'.format(
            getpid(), self.lock_details))
        self.lock_fd.flush()

        self.acquired = True


    def _release(self):
        """
        Update lock file, release lock and clean up..

        :return:
        """
        if self.acquired:
            self.log_fd.seek(0)
            self.lock_fd.write('lock_pid {}\nlock_status unlocked\n{}'.format(
                getpid(), self.lock_details))
            self.lock_fd.flush()

            lockf(self.lock_fd, LOCK_UN)

            self.lock_fd.close()
            self.log_fd.close()


    def log(self, text):
        """
        Non-fancily log text to log file by writing out a line.

        :param text: message to log
        :return:
        """
        if self.acquired:
            self.log_fd.write(text + '\n')
        else:
            raise Exception('trying to write when unlocked')


lock_file = '{}-{}'.format('/tmp/lock', ctx.deployment.id)
lock_details = {'deployment': ctx.deployment.id,
                'node': ctx.source.instance.id}

with FileLock(lock_file, lock_details=lock_details) as lock:
    src = ctx.source.instance.runtime_properties
    tgt = ctx.target.instance.runtime_properties

    tgt['broker_id'] += 1

    for k, v in tgt.items():
        src[k] = v

    ctx.source.instance.update()
    ctx.target.instance.update()

    lock.log('stack_on_config: {}'.format(tgt['broker_id']))
    lock.log('stack_on_config: {}'.format(tgt))
