FROM fluent/fluentd
RUN apk add ruby-dev
RUN gem install fluent-plugin-kafka --no-document
RUN gem install fluent-plugin-split-array --no-document

CMD /usr/bin/fluentd -c /fluent.conf

