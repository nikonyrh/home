#!/bin/bash
dd if=/dev/zero bs=$[1024*1000] count=$[1000 * $1] | \
	openssl aes-256-cbc -salt -k abc > "out_$2.dat"

