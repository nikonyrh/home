#!/bin/bash
grep "$1" | grep -v grep | grep -v psGrep.sh
