#!/bin/bash
P="$1/*.zip.aes_p*"
B=`dirname $0`
S="$2"

if [ -z "$S" ]; then
	S="7"
fi

ls $P | xargs -n1 "$B/s3md5.sh" "$S"
