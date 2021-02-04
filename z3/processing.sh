#!/bin/bash

if [ $# -ne 1 ]; then
	echo $0 inputfile
	exit
fi

INPUTFILE=$1

for i in $(cat $INPUTFILE | cut -d\: -f1-3); do
	echo "$(date);DONE;$i"
done
