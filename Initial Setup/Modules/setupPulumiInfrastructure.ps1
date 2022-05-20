# public or china
$armEnvironment
$keyVaultName
$location
$resourceGroupName
$servicePrincipalName
$storageAccountName
$subscriptionId


# Setting up the Service Principal for DevOps Service Connection
# Contains appId, displayName, password and tenant
$servicePrincipal = az ad sp create-for-rbac \
 --name $servicePrincipalName \
 --role Owner --scopes "/subscriptions/$(subscriptionId)" | ConvertFrom-Json

# Create the Resource Group for Keyvault and Storage Account
az group create \
 --location $location \
 --resource-group $resourceGroupName \
 --subscription $subscriptionId

# Creating the Keyvault for Variable Group, Storage Account Key (BYOK) and Service Principal Secret
$keyVault = az keyvault create \
 --name $keyVaultName \
 --location $location \
 --resource-group $resourceGroupName \
 --enable-purge-protection | ConvertFrom-Json
# Allow Service Connection Principal to get, list and set the Secrets of the KeyVault
az keyvault set-policy \
 --name $keyVaultName \
 --resource-group $resourceGroupName \
 --object-id $servicePrincipal.appId \
 --secret-permissions get list set 

# Create the Storage Account with System Assigned Identity and allow Access to Keyvault Key
az storage account create \
 --name $storageAccountName \
 --location $location \
 --resource-group $resourceGroupName \
 --allow-blob-public-access \
 --sku Standard_LRS \
 --kind StorageV2 \
 --assign-identity

$storageAccountPrincipalId=az storage account show \
 --name $storageAccountName \
 --resource-group $resourceGroupName \
 --query identity.principalId \
 --output tsv

az keyvault set-policy \
 --name $keyVaultName \
 --resource-group $resourceGroupName \
 --object-id $storage_account_principal \
 --key-permissions get unwrapKey wrapKey

# Create Key for BYOK for Storage acccount
$keyName = "$(storageAccountName)-byok"
$key = az keyvault key create \
 --name $keyName \
 --protection software \
 --size 3072 \
 --vault-name $keyVaultName | ConvertFrom-Json

# Update Storage Account to use Key for Encryption
az storage account update \
 --name $storageAccountName \
 --resource-group $resourceGroupName \
 --encryption-key-name $keyName \
 --encryption-key-version $key.key.kid \
 --encryption-key-source Microsoft.Keyvault \
 --encryption-key-vault $keyVault.properties.vaultUri
 

 # Create Secret with Service Pincipal Password in Keyvault
 az keyvault secret set \
 --name "servicePrincipalSecret" \
 --vault-name $keyVaultName \
 --value $servicePrincipal.password \
 --description "Contains the Service Principal Secret for Deployments" -o none

$storageAccountKey=az storage account keys list --account-name $storageAccountName --query [0].value --output tsv

 #Setup Object for Creation of Secrets used for the Versioning
 $secrets = @(
     [pscustomobject]@{SecretName='major';Value='0';Description='Contains Information for the Versioning of the Deployment'}
     [pscustomobject]@{SecretName='minor';Value='0';Description='Contains Information for the Versioning of the Deployment'}
     [pscustomobject]@{SecretName='patch';Value='0';Description='Contains Information for the Versioning of the Deployment'}
     [pscustomobject]@{SecretName='keyVaultName';Value=$keyVaultName;Description='Contains Information for the Versioning of the Deployment'}
     [pscustomobject]@{SecretName='servicePrincipalId';Value=$servicePrincipal.appId;Description='Contains the App Id for the stored Service Principal Secret'}
     [pscustomobject]@{SecretName='tenantId';Value=$tenantId;Description='Contains the Tenant Id for Deployments'}
     [pscustomobject]@{SecretName='subscriptionId';Value=$subscriptionId;Description='Contains the Subscription Id for Deployments'}
     [pscustomobject]@{SecretName='armEnvironment';Value=$armEnvironment;Description='Contains the ARM Environment for Deployments'}
     [pscustomobject]@{SecretName='storageAccountKey';Value=$storageAccountKey;Description='Contains the Storage Account Key for Deployments'}
 )
 # Creating all Secrets in the Keyvault for the Variable Group
 foreach($secret in $secrets){
     az keyvault secret set \
      --name $secret.SecretName \
      --vault-name $keyVaultName \
      --value $secret.Value \
      --description $secret.Description
 }
