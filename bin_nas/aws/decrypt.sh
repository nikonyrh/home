#!/bin/bash
#PW=`~/bin/aws/md5sum.sh "$2"`
PW=`~/bin/aws/sha1sum.sh "$2"`
openssl aes-256-cbc -d -salt -in "$1" -k $PW

