#!/bin/bash
F="nikonyrh-public/misc/$1.dat"
echo "https://s3-eu-west-1.amazonaws.com/$F"

cat "$1" | gzip | openssl aes-256-cbc -salt -k "$2" | \
    aws s3 cp --storage-class REDUCED_REDUNDANCY - "s3://$F" --acl public-read

