#!/bin/bash
cd "$(dirname "$(realpath "$0")")";

if [ "$1" == "" ]; then
	>&2 echo "Usage: $0 ip" && exit 1
fi

NAME="$2"
if [ "$NAME" == "" ]; then
	NAME=unknown
fi

ping -c 1 $1 > /dev/null || sleep 10 && \
    ping -c 1 $1 > /dev/null || ./slackNotify.sh "Failed to ping $1! ($NAME)"

