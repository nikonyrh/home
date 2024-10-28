#!/bin/bash
#find "$1" -type f -print0 | grep -z Upload_ | sort -z | xargs -0 -n1 echo
find "$1" -type f -print0 | sort -z | xargs -0 sha1sum
