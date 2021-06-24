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
<match **>
  @type stdout
</match>
