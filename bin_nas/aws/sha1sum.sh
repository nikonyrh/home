#!/bin/bash
echo $1 | sha1sum - | cut -c -40
