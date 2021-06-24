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

** AS WITH ALL CLOUD THINGS, REMEMBER TO SHUT DOWN THINGS YOU SPUN UP **

## Dependencies

The official `td-agent-bit` (fluent-bit) repositories lack the ability to do `SASL_SSL` communications to azure eventhubs.  
As a convenience, there's a recompiled binary hosted in a deb repository at make.run/repo 

# Alternatives

You can use the azure diagnostics extension to forward arbitrary files to an event hub.  
While the [documentation](https://docs.microsoft.com/en-us/azure/azure-monitor/agents/diagnostics-extension-overview) says  
```
The Azure Diagnostic extension for both Windows and Linux always collect data into an Azure Storage account
```

This doesnt seem to be true for not true for [fileLogs](https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/diagnostics-linux?toc=%2Fazure%2Fazure-monitor%2Ftoc.json&tabs=azcli#filelogs). Just specifying an eventhub sink with no table option, just forwards the log contents to the eventhub.

## Implementation

You need to hand craft the configuration settings of the diagnostics extension. There are samples in the [documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/diagnostics-linux?tabs=azcli).  
This repository creates the necessary protected and public json files needed to configure a VM.  
  
The helper script renders/logging.sh <hostname>, will create the eventhub sasURL, and configure the VM.  

We monitor the file called /tmp/john.log, which is written to on VM boot.
  
## Under the hoods

This is all based on fluentd, which runs as the `omsagent` binary on the guest OS.
The syslog and file monitoring directives create fluentd config under the /etc/opt/microsoft directory.  
Fluentd contains an Azure [fluentd output plugin](https://github.com/Azure/fluentd-plugin-mdsd) that sends messages to the local msds agent on the guest OS.  
The msds agent is responsible for actually sending the messages to storage and/or eventhubs.  
  
The msds agent looks at the tags in each message received from the omsagent and routes the messages accordingly.
