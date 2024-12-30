#!/bin/bash
recordmydesktop --windowid $(xwininfo | grep 'id: 0x' | grep -Eo '0x[a-z0-9]+')
