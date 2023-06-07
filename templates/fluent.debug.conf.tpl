<source>
  @type kafka_group
  consumer_group $Default
  brokers ${eventhubNS}.servicebus.windows.net:9093
  ssl_ca_certs_from_system true
  username $ConnectionString
  password "${connectionString}"
  topics /.*/
  format json
  add_prefix kafka
</source>
<filter kafka.**>
  @type split_array
  split_key records
</filter>
<match **>
  @type stdout
</match>
