#!/bin/bash -e

test ! -e /var/run/docker.sock || rm /var/run/docker.sock
if which cgroups-mount; then
    run cgroups-mount
fi;
containerd &
dockerd &
