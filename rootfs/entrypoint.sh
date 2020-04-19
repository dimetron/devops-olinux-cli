#!/bin/bash

# generate host keys if not present
ssh-keygen -A

exec "$@"
