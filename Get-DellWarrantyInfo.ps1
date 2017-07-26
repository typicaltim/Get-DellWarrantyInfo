<#  ====================================================================================================================================================

    |                                                          DELL WARRANTY MANAGEMENT SCRIPT                                                         |
        
    Name:            Get-DellWarrantyInfo

    Description:     Uses the Dell Warranty API to gather information about specified computers.

    Author:          typicaltim

    !WARNING!:       !~ DO NOT PUBLISH THIS WITH THE API KEY VISIBLE ~!

    ===================================================================================================================================================#>

<# INITIAL VARIABLE DECLARATIONS AND URL SEGMENT PREP-WORK
    This section is just setting up tiny URL chunks and other variables so they can be easily changed and called on later to make
    reading this script easier.
#>

    $computerList = Import-CSV "\\servername\folder\list_computerlist.csv"           # Set Target PC List
    $endpointType = @("https://sandbox.api.dell.com","https://api.dell.com")         # Set Sandbox/Production URL list
    $endpointTypeSelection = $endpointType[0]                                        # Select which endpoint will be accessed (1/0)
    $requestType = @("getassetheader/","getassetwarranty/","getassetsummary/")       # Set Request Type list
    $apiURLsegment = "/support/assetinfo/v4/"                                        # Set API URL Segment
    $apiKey = "YOUR-API-KEY-HERE"                                                    # Set API Key
    $apiKeyToken = "?apikey=$apiKey"                                                 # Set API Key URL Token
    $exportLocation = "\\servername\folder\exported-warranty-info-results.csv"       # Set the save file location

<# LOOPER 
This section will iterate through the computerList array and grab the info for each computer.
#>
ForEach ($computerName in $computerList.computerName) {
    
    Write-Host "INFO: Gathering information for Service Tag " -ForegroundColor Green -nonewline; Write-Host " $computerName " -BackgroundColor White -ForegroundColor Black;

    <# URL SEGMENT JOINS
    Combining all the tiny stuff together to make shortcuts to each endpoint. The final products will look like:
        "https://sandbox.api.dell.com/support/assetinfo/v4/getassetwarranty/computer123?apikey=myapikey123"
    #>
            $endpointAssetHeader = $endpointTypeSelection + $apiURLsegment + $requestType[0] + $computerName + $apiKeyToken
            $endpointAssetWarranty = $endpointTypeSelection + $apiURLsegment + $requestType[1] + $computerName + $apiKeyToken
            $endpointAssetSummary = $endpointTypeSelection + $apiURLsegment + $requestType[2] + $computerName + $apiKeyToken

    <# CREATING REQUEST SHORTCUTS 
    Now we are taking the endpoint shortcuts and using that to make simplified request shortcuts.
    #>
            $requestAssetHeader = Invoke-RestMethod -URI $endpointAssetHeader -Method GET -contenttype 'Application/xml'
            $requestWarrantyHeader = Invoke-RestMethod -URI $endpointAssetWarranty -Method GET -contenttype 'Application/xml'
            $requestSummaryHeader = Invoke-RestMethod -URI $endpointAssetSummary -Method GET -contenttype 'Application/xml'

    <# REQUESTING XML INFORMATION
    The following will actually retrieve the information we want.
    #>
            $getAssetHeader = $requestAssetHeader.AssetHeaderDTO.AssetHeaderResponse.AssetHeaderResponse.AssetHeaderData
            $getAssetWarranty = $requestWarrantyHeader.AssetWarrantyDTO.AssetWarrantyResponse.AssetWarrantyResponse.AssetEntitlementData.AssetEntitlement
            $getAssetSummary = $requestSummaryHeader.AssetSummaryDTO.AssetSummaryResponse.AssetHeaderData
            
            <# NOTES 
                    Sample for data filtering.
                        $request = $request.AssetWarrantyDTO.AssetWarrantyResponse.AssetWarrantyResponse.AssetEntitlementData.AssetEntitlement | Where-Object ServiceLevelDescription -NE 'Dell Digitial Delivery'
            #>

    <# HOUSE KEEPING
    Clear out the values about to be written to the results variable so that if a proceeding attempt fails - there are no duplicate entries.
    #>
            $results.computerName = ""
            $results.computerModel = ""
            $results.shipDate = ""
            $results.orderNumber = ""
            $results.serviceLevelDescription = ""
            $results.warrantyStart = ""
            $results.warrantyEnd = ""
            $results.productImageLink = ""

    <# CREATING CUSTOM OBJECT
    Create an Object that will contain the information
    #>
            $currentTime = Get-Date -Format r

            $results = New-Object PSObject
                $results | add-member -membertype NoteProperty -name attemptTime -Value $currentTime
                $results | add-member -membertype NoteProperty -name attemptedServiceTag -Value $computerName
                $results | add-member -membertype NoteProperty -name computerName -Value $getAssetHeader.ServiceTag
                $results | add-member -membertype NoteProperty -name computerModel -Value $getAssetHeader.MachineDescription
                $results | add-member -membertype NoteProperty -name shipDate -Value $getAssetHeader.ShipDate
                $results | add-member -membertype NoteProperty -name orderNumber -Value $getAssetHeader.OrderNumber
                $results | add-member -membertype NoteProperty -name serviceLevelDescription -Value $getAssetWarranty[0].ServiceLevelDescription
                $results | add-member -membertype NoteProperty -name warrantyStart -Value $getAssetWarranty[0].StartDate
                $results | add-member -membertype NoteProperty -name warrantyEnd -Value $getAssetWarranty[0].EndDate
                $results | add-member -membertype NoteProperty -name productImageLink -Value $getAssetSummary.ImageUrl

    <# EXPORTING DATA
    Now we'll take the information we got and export it to a csv file.
    #>
            if (-not (Test-Path $exportLocation)) {
            Write-Host "INFO: No existing export file found. A new export file will be created at" $exportLocation -ForegroundColor Yellow
            # Create the Catalog file and spit the output to null so it doesn't bother the user, it looks ugly
            New-Item $exportLocation | Out-Null
            }
            $results | Export-CSV $exportLocation -NoType -Append -Force

    <# REQUEST LIMITER
    It appears that too many requests too quickly will cause subsequent requests to be ignored. This section will slow down the requests
    by adding a wait period of 5 seconds between requests. This could just be a limitation of the Sandbox key status.
    #>
            Start-Sleep -s 5
    }
