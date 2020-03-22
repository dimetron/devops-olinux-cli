#!/bin/bash

# generate host keys if not present
ssh-keygen -A

# do not detach (-D), log to stderr (-e), passthrough other arguments
if [ $# -eq 0 ]
  then
    echo "Running SSH server"
    exec /usr/sbin/sshd -D -e "$@"
  else
    exec "$@"
fi