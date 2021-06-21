# azure-log-delivery
  
This is an example of how to get logs out of azure virtual machines, via fluent-bit and eventhubs, collected by fluentd, and into splunk.  

## How ?

Using terraform, we create an eventhub, and connection credentials.  
This information is embedded into fluent-bit config files on the virtual machines.  
  
Messages are delivered to an eventhub topic  
  
On the other end, terraform spits out a local file that can be used by fluentd to fetch the data from the eventhub topics.  
  
Fluent inserts data into splunk using HEC.  
  
## Usage 

You'll need az locally with credentials to control your subscription. These are pre-reqs for terraform.
  
Go into the terraform directory, and run :
```bash
terraform apply -var="node_count=1" -auto-approve
```

where `node_count` is the number of VMs you need want to spin up.

A file called fluent.conf will be created in the local directory that can be used to load the data into splunk.  
You will probably need to modify `local/fluent.conf.tpl` to alter the splunk location + token variables.

## Dependencies

The official `td-agent-bit` (fluent-bit) repositories lack the ability to do `SASL_SSL` communications to azure eventhubs.  
As a convenience, there's a recompiled binary hosted in a deb repository at make.run/repo 
