#!/bin/sh
# https://github.com/gopro/gpmf-parser
# docker build -t runsascoded/gpmf-parser .
docker run --rm -it -v "$PWD:/media" runsascoded/gpmf-parser "/media/$1" -a -f

