#Login til CMDB
$apiKey = 
$userName = 
$password =
$baseUri = 
$tokenUri =
$authMode = 
$tokenRequestBody =

@{
    "Accept"     = "application/json";
    "grant_type" = "password";
    "client_id"  = $apiKey;
    "username"   = $userName;
    "password"   = $password;
}
#Get access token
$tokenResponse = Invoke-RestMethod -Method POST -Uri "${tokenUri}?auth_mode=${authMode}" -Body $tokenRequestBody
$requestHeader = @{ Authorization = "Bearer $($tokenResponse.access_token)" }

$searchUri = $baseUri  #Manuelle servere

$searchCustom = $baseUri  #Custom servere

$searchResultsCustom = Invoke-RestMethod -Method Get -Uri $searchCustom -ContentType application/json -Header $requestHeader # -Body $searchResultsRequest

$CustomServers = $searchResultsCustom."friendly name"

$searchResultsResponse = Invoke-RestMethod -Method Get -Uri $searchUri -ContentType application/json -Header $requestHeader # -Body $searchResultsRequest
   
$servers = $searchResultsResponse

$Allservers = $servers."friendly name"

$sql = $servers | Where-Object { $_.Description -Match "sql" }

$SQL_Servers = $sql."friendly name"

$NoSQL = $servers | ? { $_ -notin $SQL_Servers }

$NoSQLServer = $NoSQL."friendly name"

function Get-CurrentPassword {
    #Får fat i passwords fra 1password
    param(
        [parameter(Mandatory = $true)]
        [string] $object
    )

    #1Password Connect Server API information
    $baseUri1Password = 
    $tokenResponse1Password = 
    $requestHeader1Password = @{ Authorization = "Bearer $($tokenResponse1Password)" }
    
    
    #Search for all items in the vault, return them as powershellobjects
    $searchUriAllItems1Password = 
    $searchResultsResponseAllItems = 
      
    #Find the PS object where the title is equal to the name of the current server in the "For each" loop of Active windows Servers from Cherwell.
    $ServerObject = 
    #Create new search that get the specific item with all attributes including current password. 
    $searchUriSpecificItems1Password = 
    
    $searchResultsResponseSpecificItem = 
    #Find the array entry where password is ID
    $PasswordObject = $searchResultsResponseSpecificItem.fields | Where-Object { $_.id -eq 'password' }
    #Save the vaulue of Password into variable $CurrentPassword
    $CurrentPassword = $PasswordObject.value
    $CurrentPasswordSecure = ConvertTo-SecureString $CurrentPassword -AsPlainText -Force
    $Cred = New-Object System.Management.Automation.PSCredential ("$object\administrator", $CurrentPasswordSecure)

    return $Cred
}

 $jobs = 0

$MaxThreads = 2 #Max limit på 5
$SleepTimer = 500

$getserviceinfo = {
    $(Get-WindowsUpdate)|Select KB,Status
}

$Computers = "Computername","Computername", "Computername"

foreach ($computer in $Computers) {
    while ($(get-job -State Running).count -ge $MaxThreads) {
        Write-Progress -Activity "Creating Jobs" -Status "Waiting for jobs to close" -CurrentOperation "$jobs Jobs Created - $($(Get-Job -State Running).count) Jobs Active" -PercentComplete ($jobs/$Computers.Count * 100)

        Start-Sleep -Milliseconds $SleepTimer
    }

    
    $jobs++
    $Cred = Get-CurrentPassword $Computer 
    $Session = New-PSSession -ComputerName $Computers -Credential $cred -ErrorAction SilentlyContinue
    Invoke-Command -Session $Session -ScriptBlock $getserviceinfo -AsJob
    Write-Progress  -Activity "Creating Jobs" -Status "Waiting for jobs to close" -CurrentOperation "$jobs Jobs Created - $($(Get-Job -state running).count) Jobs Active" -PercentComplete ($jobs/$Computers.count * 100)

}

$runningcount = (get-job | where State -eq running).count

#while ($runningcount -ne 0){ #hvis running jobs ikke er 0 køre whileloopet
#    $runningcount = (get-job | where State -eq running).count
#    Write-Output "$runningcount Jobs remaining"
#    Start-Sleep -Seconds 1
#    
#}

$endResult = get-job | Receive-Job -Force -Wait | Out-File -FilePath C:\Temp\Optimering\testStatus.txt 
#sometimes 1 job hang forever,force is needed otherwise you will wait forever to get output

#$endResult | Out-GridView -Title "Windows update"

Remove-PSSession -Name *
get-job | remove-job -Force