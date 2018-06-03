#!/bin/bash
cat /dev/urandom | head -c 2048 | hexdump | sha1sum | sed -r 's/ .+//'
