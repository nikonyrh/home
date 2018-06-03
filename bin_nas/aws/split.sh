#!/bin/bash
for u in $1/*.aes; do
	if [ -f "${u}_p00" ]; then
		echo "skip $u, splits exist"
		continue
	fi
	
	echo "process $u from $1"
	split -d --bytes=500M "$u" "${u}_p"
done
