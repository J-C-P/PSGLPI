# Internal Functions have names WITHOUT dash "-" caracter.

Function GetGLPISessionToken {
    param($Creds)
    #Get-Date -f T | write-host -NoNewLine
    #Write-Host " Enter Function"
    $Creds.AuthorizationType
    if (("Basic","user_token") -ccontains $Creds.AuthorizationType) {Invoke-RestMethod "$($Creds.AppURL)/initSession" -Headers @{"Content-Type" = "application/json";"Authorization" = "$($Creds.AuthorizationType) $($Creds.UserToken)";"App-Token"=$Creds.AppToken}}
    else {Write-Host 'AuthorizationType MUST be "user_token" or "Basic". This is Case Sensitive.' -ForegroundColor Red}
}

function Get-GlpiBase64Login {
    <#
.SYNOPSIS
    The Base64 encoded login & password.
.DESCRIPTION
    Generate the Base64 login & password string used to authenticate with GLPI.
.PARAMETER login
    User name 
.PARAMETER password
    Password
.EXAMPLE
     Get-GLPILoginBase64 -login "MyGlpiUser" -password "MyGlpiPassword"
.INPUTS
    Strings
.OUTPUTS
    String
.NOTES
    Author:  Jean-Christophe Pirmolin #>
    param([parameter(Mandatory=$true)][String]$login,[parameter(Mandatory=$true)][String]$password)
    $sStringToEncode="$($login):$($password)"
    $sEncodedString=[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($sStringToEncode))
    return $sEncodedString
}


Function Get-GlpiItems {
    <#
.SYNOPSIS
    Get all items of a specific item type.
.DESCRIPTION
    Retrieve all items of a specific item type by range.
    Useful for instance, to load a list in memory and avoid multiple call to an existing collection.
.PARAMETER ItemType
    Type of item wanted. 
    Exemples : Computer, Monitor, User, etc.
.PARAMETER Range
    Range of the results.
    Exemple : 0-199
.PARAMETER Creds
    Credetials for the GLPI API. This is an object.
    Exemple : $GlpiCreds = @{
                    AppURL =     "https://[MyGlpiServer]/apirest.php"
                    UserToken =  "c8BRf8uJHPDr1AyDTgt2zm95S6EdMAHPXK6qTxlA"
                    AppToken =   "EaNdrm33jKDFVdK8gvFQtOf1XHki2Y4BVtPKssgl"
                    AuthorizationType = "Basic" or "user_token"
                    }
.PARAMETER QueryOptions
    Options to pass to the query. See API documentation. 
    Separator is "&"
    expand_dropdowns (default: false): show dropdown name instead of id. Optional.
    get_hateoas (default: true): Show relation of item in a links attribute. Optional.
    only_id (default: false): keep only id keys in returned data. Optional.
    sort (default 1): name of the field to sort by. Optional.
    order (default ASC): ASC - Ascending sort / DESC Descending sort. Optional.
    searchText (default NULL): array of filters to pass on the query (with key = field and value the text to search)
    is_deleted (default: false): Return deleted element. Optional.
    add_keys_names: Retrieve friendly names. Array containing fkey(s) and/or "id". Optional.
    Exemple : expand_dropdowns=true&get_hateoas=false
.EXAMPLE
     Get-GlpiItems -ItemType "Location" -Range "0-99" -Creds $GlpiCreds
.INPUTS
    None
.OUTPUTS
    Array
.NOTES
    Author:  Jean-Christophe Pirmolin #>
    param([parameter(Mandatory=$true)][String]$ItemType,[parameter(Mandatory=$false)][String]$Range="0-999",[parameter(Mandatory=$true)][Object]$Creds, $QueryOptions="")

    $UserToken = $Creds.UserToken
    $SessionToken = GetGLPISessionToken -Creds $Creds
    $SearchResult = Invoke-RestMethod "$($Creds.AppUrl)/$($ItemType)/?range=$($Range)&$($QueryOptions)" -Headers @{"session-token"=$SessionToken.session_token; "App-Token" = "$($Creds.AppToken)"}
    if ($SearchResult.Count -ge 1) {$SearchResult}
    else {$false}
    Invoke-RestMethod "$($Creds.AppUrl)/killSession" -Headers @{"session-token"=$SessionToken.session_token; "App-Token" = "$($Creds.AppToken)"}
}

Function Get-GlpiItem {
    <#
.SYNOPSIS
    Get a specific item by item type.
.DESCRIPTION
    Retrieve a specific item.
    Return the instance fields of item identified by id
.PARAMETER ItemType
    Type of item wanted. 
    Exemples : Computer, Monitor, User, etc.
.PARAMETER ID
    ID of item wanted. 
    Exemples : 114
.PARAMETER Creds
    Credetials for the GLPI API. This is an object.
    Exemple : $GlpiCreds = @{
                    AppURL =     "https://[MyGlpiServer]/apirest.php"
                    UserToken =  "c8BRf8uJHPDr1AyDTgt2zm95S6EdMAHPXK6qTxlA"
                    AppToken =   "EaNdrm33jKDFVdK8gvFQtOf1XHki2Y4BVtPKssgl"
                    AuthorizationType = "Basic" or "user_token"
                    }
.PARAMETER QueryOptions
    Options to pass to the query. See API documentation. 
    Separator is "&"
    expand_dropdowns (default: false): show dropdown name instead of id. Optional.
    get_hateoas (default: true): Show relation of item in a links attribute. Optional.
    only_id (default: false): keep only id keys in returned data. Optional.
    sort (default 1): name of the field to sort by. Optional.
    order (default ASC): ASC - Ascending sort / DESC Descending sort. Optional.
    searchText (default NULL): array of filters to pass on the query (with key = field and value the text to search)
    is_deleted (default: false): Return deleted element. Optional.
    add_keys_names: Retrieve friendly names. Array containing fkey(s) and/or "id". Optional.
    Exemple : expand_dropdowns=true&get_hateoas=false
.EXAMPLE
     Get-GlpiItem -ItemType "Monitor" -ID 114 -Creds $GlpiCreds
.INPUTS
    None
.OUTPUTS
    Array
.NOTES
    Author:  Jean-Christophe Pirmolin #>
    param([parameter(Mandatory=$true)][String]$ItemType, [parameter(Mandatory=$true)][Int]$ID, $QueryOptions="", [parameter(Mandatory=$true)][object]$Creds)
    $SessionToken = GetGLPISessionToken -Creds $Creds
    $SearchResult = Invoke-RestMethod "$($Creds.AppUrl)/$($ItemType)/$($ID)?$QueryOptions" -Headers @{"session-token"=$SessionToken.session_token; "App-Token" = "$($Creds.AppToken)"} -ErrorAction Ignore
    if ($SearchResult) {$SearchResult}
    else {$false}
    Invoke-RestMethod "$($Creds.AppUrl)/killSession" -Headers @{"session-token"=$SessionToken.session_token; "App-Token" = "$($Creds.AppToken)"}
}

Function Get-GlpiSubItems {
    <#
.SYNOPSIS
    Get a specific item by item type.
.DESCRIPTION
    Retrieve a specific item.
    Return the instance fields of item identified by id
.PARAMETER ItemType
    Type of item wanted. 
    Exemples : Computer, Monitor, User, etc.
.PARAMETER ID
    ID of item wanted. 
    Exemples : 114
.PARAMETER Creds
    Credetials for the GLPI API. This is an object.
    Exemple : $GlpiCreds = @{
                    AppURL =     "https://[MyGlpiServer]/apirest.php"
                    UserToken =  "c8BRf8uJHPDr1AyDTgt2zm95S6EdMAHPXK6qTxlA"
                    AppToken =   "EaNdrm33jKDFVdK8gvFQtOf1XHki2Y4BVtPKssgl"
                    AuthorizationType = "Basic" or "user_token"
                    }
.EXAMPLE
     Get-GlpiItem -ItemType "Monitor" -ID 114 -Creds $GlpiCreds
.INPUTS
    None
.OUTPUTS
    Array
.NOTES
    Author:  Jean-Christophe Pirmolin #>
    param([parameter(Mandatory=$true)][String]$ItemType, [parameter(Mandatory=$true)][Int]$ID, [String]$QueryOptions="", [parameter(Mandatory=$true)][Object]$Creds, [parameter(Mandatory=$true)][String]$Relation)
    $SessionToken = GetGLPISessionToken -Creds $Creds
    $SearchResult = Invoke-RestMethod "$($Creds.AppUrl)/$($ItemType)/$($ID)/$($Relation)?$QueryOptions" -Headers @{"session-token"=$SessionToken.session_token; "App-Token" = "$($Creds.AppToken)"} -ErrorAction Ignore
    if ($SearchResult) {$SearchResult}
    else {$false}
    Invoke-RestMethod "$($Creds.AppUrl)/killSession" -Headers @{"session-token"=$SessionToken.session_token; "App-Token" = "$($Creds.AppToken)"}
}

Function Search-GlpiItem {
    <#
.SYNOPSIS
    Use the GLPI Search Engine.
.DESCRIPTION
    Expose the GLPI searchEngine and combine criteria to retrieve a list of elements of specified itemtype.
.PARAMETER ItemType
    Type of item wanted.
    Note : you can use 'AllAssets' itemtype to retrieve a combination of all asset's types.
    Exemples : Computer, Monitor, User, etc.
.PARAMETER SearchOptions
    SearchOptions should be given in a form of array of arrays. 
    ("AND",1,"contains","AMC0132"),("OR",1,"contains","AMC0176)
    If only ONE criteria is present, start with a COMA!
     ,("OR",1,"contains","AMC0176")
    BE CAREFULL the first coma in the SearchOption definition!!
    You can use Get-GlpiSearchOptions to display the list of search options (fields) available for a specific item type.
    If you want to retreive a specific field that is missing the default result view, you can add it to the SearchOptions under the form of ,("OR",[FieldID],"contains","")
    Exemples : ("AND",1,"contains","AMC"),("AND",105,"is","Luxembourg") to find items that contains "AMC" in the name AND are located in "Luxembourg".
    ,("OR",1,"contains","AMC0176") to find items that contains "AMC0176" in the name.
.PARAMETER Range
    Range of the results. (Optional, default is 0-999)
    Exemple : 0-199
.PARAMETER Creds
    Credetials for the GLPI API. This is an object.
    Exemple : $GlpiCreds = @{
                    AppURL =     "https://[MyGlpiServer]/apirest.php"
                    UserToken =  "c8BRf8uJHPDr1AyDTgt2zm95S6EdMAHPXK6qTxlA"
                    AppToken =   "EaNdrm33jKDFVdK8gvFQtOf1XHki2Y4BVtPKssgl"
                    AuthorizationType = "Basic" or "user_token"
                    }
.EXAMPLE
     Search-GlpiItem -ItemType "Monitor" -SearchOptions ("AND",21,"is","737386"),("OR",13,"contains","") -Creds $GlpiCreds
.INPUTS
    None
.OUTPUTS
    Array
.NOTES
    Author:  Jean-Christophe Pirmolin #>
    param([Parameter(Mandatory=$true)][String] $ItemType,[Parameter(Mandatory=$true)][array] $SearchOptions,[String]$Range="0-999",[Parameter(Mandatory=$true)][Object] $Creds)
    
    # Building the SearchOptions String
    $i=0
    foreach ($Criteria in $SearchOptions) {
        if ($i -eq 0) {$StrSearchOptions = "criteria[$($i)][link]=$($Criteria[0])&criteria[$($i)][field]=$($Criteria[1])&criteria[$($i)][searchtype]=$($Criteria[2])&criteria[$($i)][value]=$($Criteria[3].replace("'","''"))"
        }
        else {$StrSearchOptions = "$($StrSearchOptions)&criteria[$($i)][link]=$($Criteria[0])&criteria[$($i)][field]=$($Criteria[1])&criteria[$($i)][searchtype]=$($Criteria[2])&criteria[$($i)][value]=$($Criteria[3].replace("'","''"))"
        }
        $i++
    }
    
    $SessionToken = GetGLPISessionToken -Creds $Creds
    $SearchResult = Invoke-RestMethod "$($Creds.AppUrl)/search/$($ItemType)?$StrSearchOptions&range=$($Range)&forcedisplay[2]=1" -Headers @{"session-token"=$SessionToken.session_token; "App-Token" = "$($Creds.AppToken)"} -ErrorAction Ignore
    if ($SearchResult) {$SearchResult.data}
    else {return $false}
    Invoke-RestMethod "$($Creds.AppUrl)/killSession" -Headers @{"session-token"=$SessionToken.session_token; "App-Token" = "$($Creds.AppToken)"}
}

Function Get-GlpiSearchOptions {
<#.SYNOPSIS
    List search option for GLPI Search Engine.
.DESCRIPTION
    Expose the GLPI searchEngine options / fields for a specified item type.
.PARAMETER ItemType
    Type of item wanted.
    Note : you can use 'AllAssets' itemtype to retrieve a combination of all asset's types.
    Exemples : Computer, Monitor, User, etc.
.PARAMETER Creds
    Credetials for the GLPI API. This is an object.
    Exemple : $GlpiCreds = @{
                    AppURL =     "https://[MyGlpiServer]/apirest.php"
                    UserToken =  "c8BRf8uJHPDr1AyDTgt2zm95S6EdMAHPXK6qTxlA"
                    AppToken =   "EaNdrm33jKDFVdK8gvFQtOf1XHki2Y4BVtPKssgl"
                    AuthorizationType = "Basic" or "user_token"
                    }
.EXAMPLE
     Get-GlpiSearchOptions -ItemType "Monitor" -Creds $GlpiCreds
.INPUTS
    None
.OUTPUTS
    Array
.NOTES
    Author:  Jean-Christophe Pirmolin #>
    param([parameter(Mandatory=$true)][String]$ItemType,[parameter(Mandatory=$true)][Object]$Creds)
    $SessionToken = GetGLPISessionToken -Creds $Creds
    $SearchResult = Invoke-RestMethod "$($Creds.AppURL)/listSearchOptions/$($ItemType)" -Headers @{"session-token"=$SessionToken.session_token; "App-Token" = "$($Creds.AppToken)"} -ErrorAction Ignore
    if ($SearchResult) {
        $SearchOptions = $SearchResult.PSObject.Properties #| Select-Object -property Value | Select-Object -Property *
        $Result = @()
        foreach ($Option in $SearchOptions) {
            $item = New-Object psobject
            $Item | Add-Member -Type NoteProperty -Name ID -Value $Option.name
            $Item | Add-Member -Type NoteProperty -Name "Field Name" -Value $Option.value.field
            $Item | Add-Member -Type NoteProperty -Name Name -Value $Option.value.name
            $Result += $item
            }
        $Result
        }
    else {return $false}
    Invoke-RestMethod "$($Creds.AppURL)/killSession" -Headers @{"session-token"=$SessionToken.session_token; "App-Token" = "$($Creds.AppToken)"}
}


Function Add-GlpiItem {
        <#
.SYNOPSIS
    Add an object into GLPI.
.DESCRIPTION
    Add an object (or multiple objects) into GLPI.
.PARAMETER ItemType
    Type of item wanted.
    Note : you can use 'AllAssets' itemtype to retrieve a combination of all asset's types.
    Exemples : Computer, Monitor, User, etc.
.PARAMETER Details
    Describe the details of the object you wan to add into GLPI.
    It is expected to be an object that you can create using :
    $Details = @{
        name="PC99999"
        serial="01.02.03.04.05"}
.PARAMETER Creds
    Credetials for the GLPI API. This is an object.
    Exemple : $GlpiCreds = @{
                    AppURL =     "https://[MyGlpiServer]/apirest.php"
                    UserToken =  "c8BRf8uJHPDr1AyDTgt2zm95S6EdMAHPXK6qTxlA"
                    AppToken =   "EaNdrm33jKDFVdK8gvFQtOf1XHki2Y4BVtPKssgl"
                    AuthorizationType = "Basic" or "user_token"
                    }
.EXAMPLE
    $Details = @{
        name="PC99999"
        serial="01.02.03.04.05"}
    Add-GlpiItem -ItemType "computer" -Details $Details -Creds $GlpiCreds
.INPUTS
    None
.OUTPUTS
    Array
.NOTES
    Author:  Jean-Christophe Pirmolin #> 
    param([parameter(Mandatory=$true)][String]$ItemType,[parameter(Mandatory=$true)][Object]$Details,[parameter(Mandatory=$true)][Object]$Creds)
    $Details = @{input=$Details} 
    $SessionToken = GetGLPISessionToken -Creds $Creds
    $json = ConvertTo-Json $Details
    $AddResult = Invoke-RestMethod "$($Creds.AppUrl)/$($ItemType)" -Method Post -Headers @{"session-token"=$SessionToken.session_token; "App-Token" = "$($Creds.AppToken)"} -Body ([System.Text.Encoding]::UTF8.GetBytes($json)) -ContentType 'application/json'
    Invoke-RestMethod "$($Creds.AppUrl)/killSession" -Headers @{"session-token"=$SessionToken.session_token; "App-Token" = "$($Creds.AppToken)"}
    return $AddResult
}

Function Add-GlpiSubItem {
        <#
.SYNOPSIS
    Add a sub object into GLPI.
.DESCRIPTION
    Add a sub object (or multiple objects) into GLPI.
.PARAMETER ItemType
    Type of PARENT item.
    Exemples : Computer, Monitor, User, Ticket, etc.
.PARAMETER ID
    ID of the PARENT item. 
    Exemples : 114
.PARAMETER Details
    Describe the details of the sub object you wan to add into GLPI.
    It is expected to be a sub object that you can create using :
    $Details = @{
        name="internal"
        IP="127.0.0.1"}
.PARAMETER SubItemType
    Type of SUB item you want to add.
    Exemple : ITILFolowup for a ticket, Networkname for a network device, etc.
    Note : If the SubItemType is a "Document_Item", "name" and "_filename" are requested details.
.PARAMETER Creds
    Credetials for the GLPI API. This is an object.
    Exemple : $GlpiCreds = @{
                    AppURL =     "https://[MyGlpiServer]/apirest.php"
                    UserToken =  "c8BRf8uJHPDr1AyDTgt2zm95S6EdMAHPXK6qTxlA"
                    AppToken =   "EaNdrm33jKDFVdK8gvFQtOf1XHki2Y4BVtPKssgl"
                    AuthorizationType = "Basic" or "user_token"
                    }
.EXAMPLE
    $Details = @{
        name="PC99999"
        serial="01.02.03.04.05"}
    Add-GlpiItem -ItemType "computer" -Details $Details -Creds $GlpiCreds
.INPUTS
    None
.OUTPUTS
    Array
.NOTES
    Author:  Jean-Christophe Pirmolin #> 
    param([parameter(Mandatory=$true)][String]$ItemType,[parameter(Mandatory=$true)][Int]$ID,[parameter(Mandatory=$true)][String]$SubItemType,[parameter(Mandatory=$true)][Object]$Details,[parameter(Mandatory=$true)][Object]$Creds)
    $SessionToken = GetGLPISessionToken -Creds $Creds
    if ($SubItemType -eq "Document") {
        $FileContent = [System.IO.File]::ReadAllBytes($Details._filename)
        $uploadManifest = @{
            uploadManifest= @{input = $Details}
            filename= @($FileContent)
        }
        $json = ConvertTo-Json $uploadManifest
        Invoke-RestMethod "$($Creds.AppUrl)/$($ItemType)/$($ID)/$($SubItemType)" -Method Post -Headers @{"session-token"=$SessionToken.session_token; "App-Token" = "$($Creds.AppToken)"} -Body ([System.Text.Encoding]::UTF8.GetBytes($json)) -ContentType 'multipart/data'
    }
    else {
        $Details = @{input=$Details} 
        $json = ConvertTo-Json $Details
        $AddResult = Invoke-RestMethod "$($Creds.AppUrl)/$($ItemType)/$($ID)/$($SubItemType)" -Method Post -Headers @{"session-token"=$SessionToken.session_token; "App-Token" = "$($Creds.AppToken)"} -Body ([System.Text.Encoding]::UTF8.GetBytes($json)) -ContentType 'application/json'
    }
    Invoke-RestMethod "$($Creds.AppUrl)/killSession" -Headers @{"session-token"=$SessionToken.session_token; "App-Token" = "$($Creds.AppToken)"}
    return $AddResult
}


Function Update-GlpiItem {
    <#
.SYNOPSIS
    Update an object into GLPI.
.DESCRIPTION
    Update an object into GLPI.
.PARAMETER ItemType
    Type of item want to update.
    Exemples : Computer, Monitor, User, etc.
.PARAMETER ID
    ID of item you want to update.
    Exemples : 117
.PARAMETER Details
    Describe the details of the object you wan to update into GLPI.
    It is expected to be an object that you can create using :
    $Details = @{
        name="PC99999"
        serial="01.02.03.04.05"}
.PARAMETER Creds
    Credetials for the GLPI API. This is an object.
    Exemple : $GlpiCreds = @{
                    AppURL =     "https://[MyGlpiServer]/apirest.php"
                    UserToken =  "c8BRf8uJHPDr1AyDTgt2zm95S6EdMAHPXK6qTxlA"
                    AppToken =   "EaNdrm33jKDFVdK8gvFQtOf1XHki2Y4BVtPKssgl"
                    AuthorizationType = "Basic" or "user_token"
                    }
.EXAMPLE
    $Details = @{
        name="PC99999"
        serial="01.02.03.04.05"}
    Update-GlpiItem -ItemType "computer" -Details $Details -Creds $GlpiCreds -ID 117
.INPUTS
    None
.OUTPUTS
    Array
.NOTES
    Author:  Jean-Christophe Pirmolin #> 
    param($ItemType, $Details, $Creds)
    $Details = @{input=$Details}
    $SessionToken = GetGLPISessionToken -Creds $Creds
    $json = $Details | ConvertTo-Json
    $AddResult = Invoke-RestMethod "$($Creds.AppUrl)/$($ItemType)/$($ID)" -Method Put -Headers @{"session-token"=$SessionToken.session_token; "App-Token" = "$($Creds.AppToken)"} -Body ([System.Text.Encoding]::UTF8.GetBytes($json)) -ContentType 'application/json'
    Invoke-RestMethod "$($Creds.AppUrl)/killSession" -Headers @{"session-token"=$SessionToken.session_token; "App-Token" = "$($Creds.AppToken)"}
    return $AddResult
}


Function Remove-GlpiItems {
    <#
.SYNOPSIS
    Remove a specific item by item type.
.DESCRIPTION
    Remove a specific item.
.PARAMETER ItemType
    Type of item wanted.
    Exemples : Computer, Monitor, User, etc.
.PARAMETER IDs
    Array of IDs of item to remove. If only ONE criteria is present, start with a COMA!
    Exemples : ,(114) or (110,114)
.PARAMETER Creds
    Credetials for the GLPI API. This is an object.
    Exemple : $GlpiCreds = @{
                    AppURL =     "https://[MyGlpiServer]/apirest.php"
                    UserToken =  "c8BRf8uJHPDr1AyDTgt2zm95S6EdMAHPXK6qTxlA"
                    AppToken =   "EaNdrm33jKDFVdK8gvFQtOf1XHki2Y4BVtPKssgl"
                    AuthorizationType = "Basic" or "user_token"
                    }
.PARAMETRE Purge
    If the itemtype have a trashbin, you can force purge (delete finally).Default: False
    Exemple : false, true
.PARAMETRE History
    Set to false to disable saving of deletion in global history. Default: True.
    Exemple : false, true
.EXAMPLE
     Remove-GlpiItems -ItemType "Monitor" -IDs 114 -Purge $true -History $false -Creds $GlpiCreds
.INPUTS
    None
.OUTPUTS
    Array
.NOTES
    Author:  Jean-Christophe Pirmolin #>
    param(
        [parameter(Mandatory=$true)][String]$ItemType, 
        [parameter(Mandatory=$true)][Array]$IDs, 
        [parameter(Mandatory=$true)][object]$Creds,
        [parameter(Mandatory=$false)][string]$Purge="false", 
        [parameter(Mandatory=$false)][string]$History="true")
    
    # Build array of IDs.
    if ($IDs -notcontains "ID"){
        $ids2 = @()
        foreach ($ID in $IDs){
            $hash = [ordered]@{}
            $hash.add("id" , $ID)
            $ids2 += [pscustomobject]$hash
        }
        $IDs = $ids2
    }
    $Details = @{
        input=$IDs
        force_purge = $Purge
        history = $History}
    $json = $Details | ConvertTo-Json
    #if (($Details["input"] | Get-Member -MemberType Properties).Count -eq 1){
    #    $json = $json.Remove(($lastIndex = $json.LastIndexOf("]")),1).Insert($lastIndex,"").Remove(($firstIndex = $json.IndexOf("[")),1).Insert($firstIndex,"")
   # }
   $SessionToken = GetGLPISessionToken -Creds $Creds
    Invoke-RestMethod "$($Creds.AppUrl)/$($ItemType)" -Method Delete -Headers @{"session-token"=$SessionToken.session_token; "App-Token" = "$($Creds.AppToken)"} -Body $json -ContentType 'application/json'
    Invoke-RestMethod "$($Creds.AppUrl)/killSession" -Headers @{"session-token"=$SessionToken.session_token; "App-Token" = "$($Creds.AppToken)"} -ErrorAction SilentlyContinue| Out-Null
}

Function Get-GlpiFieldLock {
<#
.SYNOPSIS
    List a field lock(s) of an item.
.DESCRIPTION
    Get the list of field locks of an item. This requires that FusionInventory plugin is installed.
.PARAMETER ItemType
    Type of item to retrieve the list of field locks on.
    Exemples : Computer, Monitor, Printer, etc.
.PARAMETER Id
    ID of item to retrieve the list of field locks on.
    Exemple : 1600
.PARAMETER Creds
    Credetials for the GLPI API. This is an object.
    Exemple : $GlpiCreds = @{
                    AppURL =     "https://[MyGlpiServer]/apirest.php"
                    UserToken =  "c8BRf8uJHPDr1AyDTgt2zm95S6EdMAHPXK6qTxlA"
                    AppToken =   "EaNdrm33jKDFVdK8gvFQtOf1XHki2Y4BVtPKssgl"
                    AuthorizationType = "Basic" or "user_token"
                    }
.EXAMPLE
    Get-GlpiFieldLock -ItemType "printer" -ID 1600 -Creds $GlpiCreds
.INPUTS
    None
.OUTPUTS
    Array of strings
.NOTES
    Author:  Jean-Christophe Pirmolin #> 
    param([parameter(Mandatory=$true)][String]$ItemType,[parameter(Mandatory=$true)][Int]$ID,[parameter(Mandatory=$true)][Object]$Creds)
    $tablename = "glpi_$($ItemType)s"
    $ExistingLocks = Get-GlpiItems -Creds $GlpiCreds -ItemType PluginFusioninventoryLock -Range 0-999999999 | ? {$_.tablename -eq $tablename -and $_.items_id -eq $id}
    if ($ExistingLocks) {
        $LocksArray=$ExistingLocks.tablefields.trim(@("[","]")).split(",")#.trim('"')
        $LocksArray = $LocksArray.ForEach({$_ -replace '"'})
        return $LocksArray
        }
}

Function Add-GlpiFieldLock {
<#
.SYNOPSIS
    Add a lock on a field of an item.
.DESCRIPTION
    Add a lock on a field of an item. This requires that FusionInventory plugin is installed.
.PARAMETER ItemType
    Type of item to manipulate.
    Exemples : Computer, Monitor, Printer, etc.
.PARAMETER Id
    ID of item to manipulate.
    Exemple : 1600
.PARAMETER Field
    The field you want to lock.
    Exemples : serial, comment, otherserial, etc.
.PARAMETER Creds
    Credetials for the GLPI API. This is an object.
    Exemple : $GlpiCreds = @{
                    AppURL =     "https://[MyGlpiServer]/apirest.php"
                    UserToken =  "c8BRf8uJHPDr1AyDTgt2zm95S6EdMAHPXK6qTxlA"
                    AppToken =   "EaNdrm33jKDFVdK8gvFQtOf1XHki2Y4BVtPKssgl"
                    AuthorizationType = "Basic" or "user_token"
                    }
.EXAMPLE
    Add-GlpiFieldLock -ItemType "printer" -ID 1600 -Field otherserial -Creds $GlpiCreds
.INPUTS
    None
.OUTPUTS
    None
.NOTES
    Author:  Jean-Christophe Pirmolin #> 
    param([parameter(Mandatory=$true)][String]$ItemType,[parameter(Mandatory=$true)][Int]$ID,[parameter(Mandatory=$true)][String]$Field,[parameter(Mandatory=$true)][Object]$Creds)
    $tablename = "glpi_$($ItemType)s"
    $ExistingLocks = Get-GlpiItems -Creds $GlpiCreds -ItemType PluginFusioninventoryLock -Range 0-999999999 | ? {$_.tablename -eq $tablename -and $_.items_id -eq $id}
    if ($ExistingLocks) {
        $LocksArray=$ExistingLocks.tablefields.trim(@("[","]")).split(",")#.trim('"')
        $LocksArray = $LocksArray.ForEach({$_ -replace '"'})
        if ($LocksArray -icontains $Field) {
            return "already locked"
            }
        else {
            $LocksArray.Add($Field)
            $LocksString = "[" + (($LocksArray.ForEach({ '"' + $_ + '"' })) -join ",") + "]"
            $Details = @{
                id=$ExistingLocks.id
                tablefields=$LocksString}
            $return = Update-GlpiItem -ItemType "PluginFusioninventoryLock" -Details $Details -Creds $GlpiCreds
            return $return
            }
        }
    else {
        $LocksArray = @($Field)
        $LocksString = "[" + (($LocksArray.ForEach({ '"' + $_ + '"' })) -join ",") + "]"
        $Details = @{
            tablename=$tablename
            items_id=$ID
            tablefields=$LocksString}
        $return = Add-GlpiItem -ItemType "PluginFusioninventoryLock" -Details $Details -Creds $GlpiCreds
        return $return
        }
}

Function Remove-GlpiFieldLock {
<#
.SYNOPSIS
    Remove a lock on a field of an item.
.DESCRIPTION
    Remove a lock on a field of an item. This requires that FusionInventory plugin is installed.
.PARAMETER ItemType
    Type of item to manipulate.
    Exemples : Computer, Monitor, Printer, etc.
.PARAMETER Id
    ID of item to manipulate.
    Exemple : 1600
.PARAMETER Field
    The field you want to unlock.
    Exemples : serial, comment, otherserial, etc.
.PARAMETER Creds
    Credetials for the GLPI API. This is an object.
    Exemple : $GlpiCreds = @{
                    AppURL =     "https://[MyGlpiServer]/apirest.php"
                    UserToken =  "c8BRf8uJHPDr1AyDTgt2zm95S6EdMAHPXK6qTxlA"
                    AppToken =   "EaNdrm33jKDFVdK8gvFQtOf1XHki2Y4BVtPKssgl"
                    AuthorizationType = "Basic" or "user_token"
                    }
.EXAMPLE
    Remove-GlpiFieldLock -ItemType "printer" -ID 1600 -Field otherserial -Creds $GlpiCreds
.INPUTS
    None
.OUTPUTS
    None
.NOTES
    Author:  Jean-Christophe Pirmolin #> 
    param([parameter(Mandatory=$true)][String]$ItemType,[parameter(Mandatory=$true)][Int]$ID,[parameter(Mandatory=$true)][String]$Field,[parameter(Mandatory=$true)][Object]$Creds)
    $tablename = "glpi_$($ItemType)s"
    $ExistingLocks = Get-GlpiItems -Creds $GlpiCreds -ItemType PluginFusioninventoryLock -Range 0-999999999 | ? {$_.tablename -eq $tablename -and $_.items_id -eq $id}
    if ($ExistingLocks) {
        $LocksArray=$ExistingLocks.tablefields.trim(@("[","]")).split(",")#.trim('"')
        $LocksArray = $LocksArray.ForEach({$_ -replace '"'})
        if ($LocksArray -icontains $Field) {
            # Need to unlock
            $LocksArray.remove($field)
            if ($LocksArray.Count -gt 0) {
                $LocksString = "[" + (($LocksArray.ForEach({ '"' + $_ + '"' })) -join ",") + "]"
                $Details = @{
                    id=$ExistingLocks.id
                    tablefields=$LocksString}
                $return = Update-GlpiItem -ItemType "PluginFusioninventoryLock" -Details $Details -Creds $GlpiCreds
                }
            else {
                $return = Remove-GlpiItems -ItemType "PluginFusioninventoryLock" -Creds $GlpiCreds -IDs $ExistingLocks.id
                }
            return $return
            }
        else {
            return "No lock on this field"
            }
        }
    else { return "No field lock on the item"}
}

Function Set-GlpiFieldLock {
<#
.SYNOPSIS
    Apply a set of locks on one or more field of an item, removing all the others.
.DESCRIPTION
    Apply a set of locks on one or more field of an item, removing all the others. This requires that FusionInventory plugin is installed.
.PARAMETER ItemType
    Type of item to manipulate.
    Exemples : Computer, Monitor, Printer, etc.
.PARAMETER Id
    ID of item to manipulate.
    Exemple : 1600
.PARAMETER Locks
    The lock(s) you want to apply.
    This is an array.
    Exemples : @(serial,comment), @(otherserial), etc.
.PARAMETER Creds
    Credetials for the GLPI API. This is an object.
    Exemple : $GlpiCreds = @{
                    AppURL =     "https://[MyGlpiServer]/apirest.php"
                    UserToken =  "c8BRf8uJHPDr1AyDTgt2zm95S6EdMAHPXK6qTxlA"
                    AppToken =   "EaNdrm33jKDFVdK8gvFQtOf1XHki2Y4BVtPKssgl"
                    AuthorizationType = "Basic" or "user_token"
                    }
.EXAMPLE
    Set-GlpiFieldLock -ItemType "printer" -ID 1600 -Locks $(otherserial -Creds $GlpiCreds
.INPUTS
    None
.OUTPUTS
    None
.NOTES
    Author:  Jean-Christophe Pirmolin #> 
    param([parameter(Mandatory=$true)][String]$ItemType,[parameter(Mandatory=$true)][Int]$ID,[parameter(Mandatory=$true)][Array]$Locks,[parameter(Mandatory=$true)][Object]$Creds)
    $tablename = "glpi_$($ItemType)s"
    $ExistingLocks = Get-GlpiItems -Creds $GlpiCreds -ItemType PluginFusioninventoryLock -Range 0-999999999 | ? {$_.tablename -eq $tablename -and $_.items_id -eq $id}
    if ($ExistingLocks) {
        $LocksString = "[" + (($Locks.ForEach({ '"' + $_ + '"' })) -join ",") + "]"
        $Details = @{
            id=$ExistingLocks.id
            tablefields=$LocksString}
        $return = Update-GlpiItem -ItemType "PluginFusioninventoryLock" -Details $Details -Creds $GlpiCreds
        return $return
        }
    else {
        $LocksString = "[" + (($Locks.ForEach({ '"' + $_ + '"' })) -join ",") + "]"
        $Details = @{
            tablename=$tablename
            items_id=$ID
            tablefields=$LocksString}
        $return = Add-GlpiItem -ItemType "PluginFusioninventoryLock" -Details $Details -Creds $GlpiCreds
        return $return
        }
}

Function Clear-GlpiFieldLocks {
<#
.SYNOPSIS
    Clear all locks on all field of an item.
.DESCRIPTION
    Clear all locks on all field of an item. This requires that FusionInventory plugin is installed.
.PARAMETER ItemType
    Type of item to manipulate.
    Exemples : Computer, Monitor, Printer, etc.
.PARAMETER Id
    ID of item to manipulate.
    Exemple : 1600
.PARAMETER Creds
    Credetials for the GLPI API. This is an object.
    Exemple : $GlpiCreds = @{
                    AppURL =     "https://[MyGlpiServer]/apirest.php"
                    UserToken =  "c8BRf8uJHPDr1AyDTgt2zm95S6EdMAHPXK6qTxlA"
                    AppToken =   "EaNdrm33jKDFVdK8gvFQtOf1XHki2Y4BVtPKssgl"
                    AuthorizationType = "Basic" or "user_token"
                    }
.EXAMPLE
    Clear-GlpiFieldLocks -creds $GlpiCreds -ItemType "printer" -ID 1600
.INPUTS
    None
.OUTPUTS
    None
.NOTES
    Author:  Jean-Christophe Pirmolin #> 
    param([parameter(Mandatory=$true)][String]$ItemType,[parameter(Mandatory=$true)][Int]$ID,[parameter(Mandatory=$true)][Object]$Creds)
    $tablename = "glpi_$($ItemType)s"
    $ExistingLocks = Get-GlpiItems -Creds $GlpiCreds -ItemType PluginFusioninventoryLock -Range 0-999999999 | ? {$_.tablename -eq $tablename -and $_.items_id -eq $id}
    if ($ExistingLocks) {
        $return = Remove-GlpiItems -ItemType "PluginFusioninventoryLock" -IDs $ExistingLocks.id -Creds $GlpiCreds
        return $return
        }
    else {return "no lock on this item's fields"
        }
}
