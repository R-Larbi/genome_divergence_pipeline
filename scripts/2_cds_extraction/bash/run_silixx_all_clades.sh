#!/bin/bash

DIST=$0
PAIR=$1
OUT=$2

silixx $(($(wc -l < "$DIST")-1)) "$PAIR" > "$OUT"
echo "silixx execution completed for file $PAIR"
