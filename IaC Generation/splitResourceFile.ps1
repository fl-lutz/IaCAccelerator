$bulkJson = Get-Content resources.json | ConvertFrom-Json


Write-Host $bulkJson.resources[0]
$resourceTypes = @()
foreach ($resource in $bulkJson.resources){
    if(!($resourceTypes.Contains($resource.type))){
        $resourceTypes += $resource.type
    }
}

foreach ($resourceType in $resourceTypes){
    $json = "{ 'resources': []}" | ConvertFrom-Json
    foreach($resource in $bulkJson.resources){
        if($resourceType -eq $resource.type){
            $json.resources += $resource
        }
    }
    $type = ($resourceType -split ":")[$_.Count-1]
    (ConvertTo-Json $json) | Out-File "./Resource-Files/$type.json" -encoding ASCII
}