#!/bin/bash

SCRIPTPATH=`dirname $(readlink -f $0)`
cd $SCRIPTPATH/../deScripts_version/deScripts

grep -rn "TODO"
[[ ! $(grep -rn "TODO" | wc -l) == 0 ]] && echo "WARNING: TODO found" && exit 0

echo "SUCCESS"
exit 0
