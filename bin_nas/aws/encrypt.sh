#!/bin/bash
#PW=`~/bin/aws/md5sum.sh "$2"`
PW=`~/bin/aws/sha1sum.sh "$2"`

if [ "$1" == "stdin" ]; then
	openssl aes-256-cbc -salt -k $PW
else
	openssl aes-256-cbc -salt -in "$1" -k $PW
fi
