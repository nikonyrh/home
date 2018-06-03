#!/bin/bash

# Auto-starting tip: http://toic.org/blog/2009/reverse-ssh-port-forwarding/
#FG="-f -N"
FG=""

CMD="ssh $FG -i .ssh/aws.wreckedone.org.pem -R 7080:localhost:80 ubuntu@aws.wreckedone.org"
#pgrep -f -x "$CMD" > /dev/null 2>&1 || $CMD
$CMD

#autossh -M 20000 -i .ssh/aws.wreckedone.org.pem -R 7080:localhost:80 ubuntu@aws.wreckedone.org
