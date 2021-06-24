#!/bin/bash
nohup bash -c 'while :;do echo $(date +%FT%T.%3N%z) this is a test;sleep 1;done > /tmp/test.log' &
touch /tmp/john.log
chmod 666 /tmp/john.log
nohup bash -c 'while :;do echo $(date +%FT%T.%3N%z) this is a test from omsagent;sleep 1;done > /tmp/john.log' &
/usr/bin/update-alternatives --install /usr/bin/python python /usr/bin/python2 1
