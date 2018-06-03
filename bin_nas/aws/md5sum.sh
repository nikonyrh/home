#!/bin/bash
echo $1 | md5sum - | cut -c -32
