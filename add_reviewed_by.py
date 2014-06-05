#!/usr/bin/env python

import sys
import subprocess


def git_get(key):
    proc = subprocess.Popen(
        'git config --get'.split() + [key], stdout=subprocess.PIPE)
    out, _err = proc.communicate()
    assert proc.returncode == 0
    return out.strip()


def get_name():
    return git_get('user.name')


def get_email():
    return git_get('user.email')


def get_reviewed_by():
    return "Reviewed-by: {name} <{email}>".format(
        name=get_name(), email=get_email())


def add_reviewed_by(fname, stream):
    first_pick_done = False

    lines = []
    with open(fname, 'rb') as todofile:
        lines = todofile.readlines()

    lines.append(get_reviewed_by())

    with open(fname, 'wb') as todofile:
        for l in lines:
            todofile.write(l)


if __name__=="__main__":
    import sys
    fname, = sys.argv[1:]
    stream = sys.stdout
    add_reviewed_by(fname, stream)

