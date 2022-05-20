


$env:AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY=

az devops service-endpoint azurerm create \
    --name $serviceConnectionName \
    --azure-rm-tenant-id $tenantId \
    --azure-rm-subscription-id $subscriptionId \
    --azure-rm-subscription-name $subscriptionName \
    --azure-rm-service-principal-id $servicePrincipalId

