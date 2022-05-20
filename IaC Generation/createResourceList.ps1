param(
    [Parameter(Mandatory=$true)]
    [String]$resourceGroupName
)

$rg=Get-AzResourceGroup -name ZEISS.ESB.DEV
$json = "{ 'resources': []}" | ConvertFrom-Json

function Get-PulumiResourceType () {
    Param ($AzType)

    switch ($AzType) {
        'microsoft.alertsmanagement/smartDetectorAlertRules' { $result = "azure-native:alertsmanagement:SmartDetectorAlertRule" }
        'Microsoft.ApiManagement/service' { $result = "azure-native:apimanagement:ApiManagementService" }
        'Microsoft.AzureActiveDirectory/b2cDirectories' { $result = "azure-native:azureactivedirectory:B2CTenant" }
        'microsoft.cdn/profiles' { $result = "azure-native:cdn:Profile" }
        'microsoft.cdn/profiles/endpoints' { $result = "azure-native:cdn:Endpoint" }
        'Microsoft.CertificateRegistration/certificateOrders' { $result = "azure-native:certificateregistration:AppServiceCertificateOrder" }
        'Microsoft.Compute/virtualMachineScaleSets' {$result = "azure-native:compute:VirtualMachineScaleSet"}
        'Microsoft.ContainerRegistry/registries' { $result = "azure-native:containerregistry:Registry" }
        'Microsoft.DocumentDb/databaseAccounts' { $result = "azure-native:documentdb:DatabaseAccount" }
        'Microsoft.EventGrid/topics' { $result = "azure-native:eventgrid:Topic" }
        'Microsoft.EventHub/namespaces' { $result = "azure-native:eventhub:Namespace" }
        'microsoft.insights/actiongroups' { $result = "azure-native:insights:ActionGroup" }
        'microsoft.insights/activityLogAlerts' { $result = "azure-native:insights:ActivityLogAlert" }
        'microsoft.insights/components' { $result = "azure-native:insights:Component" }
        'microsoft.insights/dataCollectionRules' {$result = "azure-native:insights:DataCollectionRule"}
        'microsoft.insights/metricalerts' { $result = "azure-native:insights:MetricAlert" }
        'microsoft.insights/scheduledqueryrules' { $result = "azure-native:insights:ScheduledQueryRule" }
        'microsoft.insights/webtests' { $result = "azure-native:insights:WebTest" }
        'microsoft.insights/workbooks' { $result = "azure-native:insights:Workbook"}
        'Microsoft.KeyVault/vaults' { $result = "azure-native:keyvault:Vault" }
        'Microsoft.Logic/workflows' { $result = "azure-native:logic:Workflow"}
        'Microsoft.ManagedIdentity/userAssignedIdentities' { $result = "azure-native:managedidentity:UserAssignedIdentity"}
        'Microsoft.Network/applicationGateways' { $result = "azure-native:network:ApplicationGateway"}
        'Microsoft.Network/frontdoors' { $result = "azure-native:network:FrontDoor" }
        'Microsoft.Network/frontdoorWebApplicationFirewallPolicies' { $result = "azure-native:network:WebApplicationFirewallPolicy"}
        'Microsoft.Network/loadBalancers' { $result = "azure-native:network:LoadBalancer"}
        'Microsoft.Network/networkProfiles' { $result = "azure-native:network:NetworkProfile"}
        'Microsoft.Network/networkSecurityGroups' { $result = "azure-native:network:NetworkSecurityGroup"}
        'Microsoft.Network/publicIPAddresses' { $result = "azure-native:network:PublicIPAddress" }
        'Microsoft.Network/virtualNetworks' { $result = "azure-native:network:VirtualNetwork" }
        'Microsoft.Portal/dashboards' { $result = "azure-native:portal:Dashboard" }
        'Microsoft.ServiceBus/namespaces' { $result = "azure-native:servicebus:Namespace" }
        'Microsoft.ServiceFabric/clusters' { $result = "azure-native:servicefabric:Cluster"}
        'Microsoft.Sql/servers' { $result = "azure-native:sql:Server" }
        'Microsoft.Sql/servers/databases' { $result = "azure-native:sql:Database" }
        'Microsoft.Storage/storageAccounts' { $result = "azure-native:storage:StorageAccount" }
        'Microsoft.Web/certificates' { $result = "azure-native:web:Certificate" }
        'Microsoft.Web/connections' { $result = "azure-native:web:Connection"}
        'Microsoft.Web/serverFarms' { $result = "azure-native:web:AppServicePlan" }
        'Microsoft.Web/sites' { $result = "azure-native:web:WebApp" }
        'Microsoft.Web/sites/appserviceplan' { $result = "azure-native:web:AppServicePlan" }
        'Microsoft.Web/sites/slots' { $result = "azure-native:web:WebAppSlot" }
        'Microsoft.Web/sites/webapp' { $result = "azure-native:web:WebApp" }

        Default {
            $result = "unknown: " + $AzType
        }
    }

    Write-Output $result
}

foreach ($res in $(Get-AzResource -ResourceGroupName $rg.ResourceGroupName)) {
	$random = -join (((48..57)+(65..90)+(97..122)) * 80 |Get-Random -Count 12 |%{[char]$_})
	$pulumiResourceName = $res.ResourceName + "-" + $random
    $objToAdd = @"
    {
    "type":"$(Get-PulumiResourceType($res.ResourceType))",
    "name":"$($pulumiResourceName)",
    "id":"$($res.ResourceId)"
    }
"@

    $json.resources += (ConvertFrom-Json -InputObject $objToAdd)
}

write-host (ConvertTo-Json $json)
(ConvertTo-Json $json) | Out-File resources.json
$unknownTypes = "{'t': []}" | ConvertFrom-Json
foreach ($el in $json.resources) {
    if ($el.type.StartsWith("unknown: ")) {
        $cleanedUnknownType = $el.type.Replace("unknown: ", "")
        if (!$unknownTypes.t.Contains($cleanedUnknownType)) {
            $unknownTypes.t += $cleanedUnknownType
        }
    }
}

Write-Host (ConvertTo-Json $unknownTypes.t)