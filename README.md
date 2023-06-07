# azure-log-delivery
  
This is an example of how to get logs out of azure virtual machines, via Azure monitor, log analytics export rules, eventhubs, collected by fluentd, and into splunk.  

## How ?

Using terraform, we create a datacollection rule that grabs syslog events and sends them to loganalytics.
The VMs have the Azure monitor Agent installed as an extension
There's a data export rule on the loganalytics workspace that dumps the syslog table to an eventhub.

On the other end, terraform spits out a local file that can be used by fluentd to fetch the data from the eventhub topics.  
Fluent inserts data into splunk using HEC.

Rather than use fluentd, you could use splunks add-ons to pull directly from the eventhub. Fluentd is easier to demo.
  
## Usage 

You'll need az locally with credentials to control your subscription. These are pre-reqs for terraform.
  
Go into the terraform directory, and run :
```bash
terraform apply -var="node_count=1" -auto-approve
```

where `node_count` is the number of VMs you need want to spin up.

A file called renders/fluent.debug.conf will be created that you can use to tail the eventhub

If you have docker installed, run 
```bash
docker build -t local/fluent .   # you only need to do this once
docker run --rm -it -v $(pwd)/renders/fluent.debug.conf:/fluent.conf local/fluent
```

** AS WITH ALL CLOUD THINGS, REMEMBER TO SHUT DOWN THINGS YOU SPUN UP **

## Dependencies

You need an azure account, the azure cli installed, along with terraform.  
You need docker if you want to stream the events
