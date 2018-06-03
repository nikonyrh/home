#!/bin/bash
cat "$1" | openssl dgst -binary -sha256 | openssl base64
