#!/bin/bash
if [ "$1" = "" ]; then
	>&2 echo "Usage: $0 key-name" && exit 1
fi

F="/home/$USER/.ssh/$1.pem"
puttygen -t rsa -O private-openssh -o "$F" -P
chmod 600 "$F"

puttygen "$1.pem" -O public-openssh
