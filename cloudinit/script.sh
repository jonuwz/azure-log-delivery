#!/bin/bash
if [[ "$(cloud-init query --format '{{ v1.platform }}')" == "nocloud" ]];then
echo -e "\n192.168.122.1 kafkaext" >> /etc/hosts

cat <<'EOF' >> /etc/td-agent-bit/parsers.conf

[PARSER]
    Name isotimestamp-singleline
    Format regex
    Regex ^(?<time>\S+) (?<log>.*)
    Time_Key    time
    Time_Format %Y-%m-%dT%H:%M:%S.%L%z
    Time_Keep   On
EOF

cat <<'EOF' > /etc/td-agent-bit/td-agent-bit.conf
@SET OU=makerun
[SERVICE]
    flush        5
    daemon       Off
    log_level    info
    parsers_file parsers.conf
    plugins_file plugins.conf
    http_server  Off
    http_listen  0.0.0.0
    http_port    2020
    storage.metrics on
[INPUT]
    name tail
    parser isotimestamp-singleline
    tag  app.local.${HOSTNAME}.${OU}.sourcetype
    path /tmp/test.log
    db /tmp/fluentbit.db
    path_key source
[FILTER]
    name lua
    match *
    script /opt/td-agent-bit/scripts/append_tag.lua
    call append_tag
[OUTPUT]
    name  kafka
    match *
    brokers kafkaext:9093
    topics test
EOF

nohup bash -c 'while :;do echo $(date +%FT%T.%3N%z) this is a test;sleep 0.1;done > /tmp/test.log' &

fi

service td-agent-bit restart 
