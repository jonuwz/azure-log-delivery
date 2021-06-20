<source>
  @type kafka_group
  consumer_group $Default
  brokers ${eventhubNS}.servicebus.windows.net:9093
  ssl_ca_certs_from_system true
  username $ConnectionString
  password "${connectionString}"
  topics /app_.*/
  format json
  add_prefix kafka
</source>
<match kafka.**>
  @type rewrite_tag_filter
  <rule>
    key tag
    pattern /(.*)/
    tag $1
  </rule>
</match>
<filter out.**>
  @type record_transformer
  <record>
    splunk_index $${tag_parts[2]}
    splunk_host $${tag_parts[4]}
    splunk_sourcetype $${tag_parts[3]}
    fluent_worker "#{ENV['WORKER']}"
  </record>
</filter>
<match out.**>
  @type splunk_hec
  hec_host localhost
  hec_port 8088
  insecure_ssl true
  hec_token hec_token
  source_key source
  index_key splunk_index
  sourcetype_key splunk_sourcetype
  host_key splunk_host
  time_key "@timestamp"
  <fields>
    fluent_worker
  </fields>
  <format **>
    @type single_value
    message_key log
  </format>
  <buffer>
    flush_mode interval 
    flush_interval 5s
  </buffer>
</match>
