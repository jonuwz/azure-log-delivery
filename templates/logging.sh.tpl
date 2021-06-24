#!/bin/bash
HERE=$(cd $(dirname $0);pwd)
vmname=$${1?Need vmname}

get_sas_token() {
    local EVENTHUB_URI="${eventHubURI}"
    local SHARED_ACCESS_KEY_NAME="${accessKeyName}"
    local SHARED_ACCESS_KEY="${accessKey}"
    local EXPIRY=$${EXPIRY:=$((60 * 60 * 24 * 365 * 10))} # Default token expiry is 10 years

    local ENCODED_URI=$(echo -n $EVENTHUB_URI | jq -s -R -r @uri)
    local TTL=$(($(date +%s) + $EXPIRY))
    local UTF8_SIGNATURE=$(printf "%s\n%s" $ENCODED_URI $TTL | iconv -t utf8)

    local HASH=$(echo -n "$UTF8_SIGNATURE" | openssl sha256 -hmac $SHARED_ACCESS_KEY -binary | base64)
    local ENCODED_HASH=$(echo -n $HASH | jq -s -R -r @uri)

    echo -n "$EVENTHUB_URI?sr=$ENCODED_URI\&sig=$ENCODED_HASH\&se=$TTL\&skn=$SHARED_ACCESS_KEY_NAME"
}

sltok="$(get_sas_token)"
vmid="$(az vm show -g ${rgName} -n $vmname --query "id" -o tsv)"

az vm extension set \
  --publisher Microsoft.Azure.Diagnostics \
  --name LinuxDiagnostic \
  --version 4.0 \
  --resource-group tf-rg \
  --vm-name tf-vm-0 \
  --protected-settings <( cat $HERE/lad_private_settings.json | sed "s#__SAS_URL_SYSLOG__#$sltok#" ) \
  --settings <( cat $HERE/lad_public_settings.json | sed "s#__VM_RESOURCE_ID__#$vmid#")