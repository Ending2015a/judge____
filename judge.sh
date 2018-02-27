#!/bin/bash
DIRS=`ls -d -- list/*/`

for DIR in $DIRS; do
    echo "hello $DIR"
done
