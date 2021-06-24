{
    "storageAccountName": "${storageAccount}",
    "storageAccountSasToken": "${storageAccountToken}",
    "sinksConfig": {
      "sink": [
        {
            "name": "EHforSyslog",
            "type": "EventHub",
            "sasURL": "__SAS_URL_SYSLOG__"
        }
      ]
    }
}