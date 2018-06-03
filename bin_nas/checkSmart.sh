#!/bin/bash

if [ -z "$1" ]; then
	F="smart.txt"
	rm -f $F
else
	F="$1"
fi

for dev in $(ls /dev/sd?)
do
	sudo smartctl -x $dev >> $F
done
