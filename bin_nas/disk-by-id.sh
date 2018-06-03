#!/bin/bash
ls -l /dev/disk/by-id | grep -E 'ata-.+[a-z]$' | sort
