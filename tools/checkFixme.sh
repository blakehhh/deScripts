#!/bin/bash

SCRIPTPATH=`dirname $(readlink -f $0)`
cd $SCRIPTPATH/../deScripts_version/deScripts

grep -rn "FIXME"
[[ ! $(grep -rn "FIXME" | wc -l) == 0 ]] && echo "ERROR: FIXME found" && exit 1

echo "SUCCESS"
exit 0