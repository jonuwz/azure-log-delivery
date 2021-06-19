#!/bin/bash
cat <<'EOF' >> /etc/td-agent-bit/parsers.conf

[PARSER]
    Name isotimestamp-singleline
    Format regex
    Regex ^(?<time>\S+) (?<log>.*)
    Time_Key    time
    Time_Format %Y-%m-%dT%H:%M:%S.%L%z
    Time_Keep   On
EOF

nohup bash -c 'while :;do echo $(date +%FT%T.%3N%z) this is a test;sleep 0.1;done > /tmp/test.log' &

mv /etc/td-agent-bit/my.conf /etc/td-agent-bit/td-agent-bit.conf

curl -o /opt/td-agent-bit/bin/td-agent-bit https://make.run/fluent-bit

systemctl daemon-reload
service td-agent-bit restart 
