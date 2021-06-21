# azure-log-delivery
  
This is an example of how to get logs out of azure virtual machines, via fluent-bit and eventhubs, collected by fluentd, and into splunk.  

## How ?

Using terraform, we create an eventhub, and connection credentials.  
This information is embedded into fluent-bit config files on the virtual machines.  
  
Messages are delivered to an eventhub topic  
  
On the other end, terraform spits out a local file that can be used by fluentd to fetch the data from the eventhub topics.  
  
Fluent inserts data into splunk using HEC.  
  
 
