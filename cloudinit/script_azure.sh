#!/bin/bash
nohup bash -c 'while :;do echo $(date +%FT%T.%3N%z) this is a test;sleep 0.1;done > /tmp/test.log' &
/usr/bin/update-alternatives --install /usr/bin/python python /usr/bin/python2 1
