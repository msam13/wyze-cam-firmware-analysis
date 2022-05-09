#!/bin/sh

while [ 1 ]
do
	sleep 0.1;
	if [ -f /tmp/factory ]; then
		/tmp/Test/test.sh &
		break
	fi
	if [ -f /tmp/usrflag ]; then
		break
	fi
done