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


#menuen
function show-menu {
    param (
        [string]$Title
    )
    Clear-Host
    Write-Host "$Title"

    Write-Host "press '1' for update SQL Servers"
    Write-Host "press '2' for update All other Servers" "`n"

    Write-Host "press '4' for status"
    Write-Host "press '5' for status of the remaning servers" "`n"
    
    Write-Host "press '9' to restart SQL servers"
    Write-Host "press '0' to restart All other servers" "`n"

    Write-Host "press 'p' to Print Custom Patch to file"
    Write-Host "press 'Q' to quit"
}

do {
    show-menu -Title "Windows Update Automation"
    $selection = Read-Host "Choose how to update Windows"
    $status = "Vil du kï¿½re opdateringerne igen"
    switch ($selection) {
        '1' {
            #opdatere alle SQL servere
            $msgbox = [System.Windows.MessageBox]::Show("Do you want to update SQL servers?", "Server Update", "YesNo", "Error")
            switch ($msgbox) {
                "Yes" {
                    Start-Transcript -Path "C:\windows\logs\logfile.txt" -Append

                    foreach ($object in $SQL_Servers) {
                        "`n"
                        $TestConSql = Test-Connection -ComputerName $fejl -Count 1 -Quiet
                        if ($TestConSql -eq $true) {

                        $Cred = Get-CurerntPassword $object

                        if ($Cred -ne $null) {
                        
                        "Connecting $object"
                        try {
                            $Session = New-PSSession -ComputerName $object -Credential $Cred  -ErrorAction Stop

                            Invoke-Command -Session $Session -ScriptBlock {
                                Enable-WURemoting
                                #Laver en firewall regl så man kan lave et WUjob til serveren
    
                                $Get = Get-WindowsUpdate

                                $Status = $Get.Status

                                $CheckForDwnl = $Status -match "D"

                                $CheckForDwnlDone = $Status -notmatch "D"
                                
                                if ($Status -le ($CheckForDwnl) -and ($CheckForDwnlDone)) { 
                                #Checker om der mangler en download, eller om der er klar til at blive installeret. De skal være downloadet, ellers kan de ikke blive installeret.
                                    "-Status"
                                    $Status 
                                    "`n"
                                    Write-Host "Der mangler en download"
                                    try {
                                        " Making schedulejob - download"
                                        Invoke-Command -ComputerName $object -ScriptBlock { Get-WindowsUpdate -Download -AcceptAll -ScheduleJob (Get-Date -Hour ((Get-Date).Hour) -Minute ((Get-Date).Minute)).AddSeconds(+10) }
                                        #Laver et schedulejob som downloader opdateringerne
                                        Write-Output "  Reset Done"
                                    }
                                    finally {
                                        "Starting WUJob"
                                        Invoke-WUJob -ComputerName $object -Script { Import-Module PSWindowsUpdate; Install-WindowsUpdate -AcceptAll } -Confirm:$false -verbose -RunNow
                                        #Installere opdateringerne.
                                        " Task Scheduled"
                                    }
                                }
                                else {
                                    "-Status"
                                    $Status
                                    "`n"
                                    Write-Host "Der er klar til installation"
                                    " Starter WUJob"
                                    Invoke-WUJob -ComputerName $object -Script { Import-Module PSWindowsUpdate; Install-WindowsUpdate -AcceptAll } -Confirm:$false -verbose -RunNow
                                    #installere opdateringerne hvis de er downloadet.
                                    "  Task Scheduled"
                                }
                            
                            }
                        
                            Invoke-Command -Session $Session -ScriptBlock { Remove-NetFirewallRule -DisplayName "PSWindowsUpdate (RPC Dynamics Ports)" }
                            #Fjerner firewall reglen som WURemote laver.

                            Stop-Transcript
                        }
                        catch {
                            Write-Host "$object Error...Maybe access is Denied or wrong Password" -ForegroundColor Red
                            Write-Output $Error[0]"`n"  | Out-File -FilePath C:\Windows\Logs\ServersWithError.txt -Append #ændre filepath hvis filen skal ligge et andet sted 
                        }
                        } else {
                            #Tjekker om den kan finde et password i 1password
                            Write-Host "$object eksistere ikke i 1PASSWORD!" -ForegroundColor RED
                        }
                        } else {
                            Write-Host "Server $fejl eksisterer IKKE!" -ForegroundColor Red 
                        }
                        Remove-PSSession -ComputerName * -ErrorAction Ignore 
                        #Fjerner alle sessions man har lavet. Der er et loft på hvor mange man kan have åbne
                    }
                    
                }
                
                
                "No" {
                    
                }
            }
        }
        '2' {
            #opdatere alle andre end SQL servere
            $msgbox_2 = [System.Windows.MessageBox]::Show("Do you want to update ALL other servers? (Not SQL servers)", "Server Update", "YesNo", "Error")
            switch ($msgbox_2) {
                "Yes" {
                    Start-Transcript -Path "C:\windows\logs\logfile.txt" -Append

                    foreach ($object in $NoSQLServer) {
                        "`n"
                        $TestConNotSql = Test-Connection -ComputerName $object -Count 1 -Quiet
                        #Tester connecntiion til serverene.
                        if ($TestConNotSql -eq $true) {
                        $Cred = Get-CurrentPassword $object
                        
                        if ($Cred -ne $null) {
                        
                        "Connecting $object"
                        try {
                            $Session = New-PSSession -ComputerName $object -Credential $Cred -ErrorAction Stop

                            Invoke-Command -Session $Session -ScriptBlock {
                                Enable-WURemoting
                                #Laver en firewall regl så man kan lave et WUJob til serveren
    
                                $Get = Get-WindowsUpdate

                                $Status = $Get.Status

                                $CheckForDwnl = $Status -match "D"

                                $CheckForDwnlDone = $Status -notmatch "D"

                                if ($Status -le ($CheckForDwnl) -and ($CheckForDwnlDone)) {
                                #Checker om der mangler en download, eller om der er klar til at blive installeret. De skal være downloadet, ellers kan de ikke blive installeret.
                                    "-Status"
                                    $Status 
                                    "`n"
                                    Write-Host "Der mangler en download"
                                    try {
                                        " Making schedulejob - download"
                                        Invoke-Command -ComputerName $object -ScriptBlock { Get-WindowsUpdate -Download -AcceptAll -ScheduleJob (Get-Date -Hour ((Get-Date).Hour) -Minute ((Get-Date).Minute)).AddSeconds(+10) }
                                        #Laver et schedulejob som downloader opdateringerne
                                        Write-Output "  Reset Done"
                                    }
                                    finally {
                                        "Starting WUJob"
                                        Invoke-WUJob -ComputerName $object -Script { Install-WindowsUpdate -AcceptAll } -Confirm:$false -verbose -RunNow
                                        #Installere opdateringerne.
                                        " Task Scheduled"
                                    }
                                }
                                else {
                                    "-Status"
                                    $Status
                                    "`n"
                                    Write-Host "Der er klar til installation"
                                    " Starter WUJob"
                                    Invoke-WUJob -ComputerName $object -Script { Install-WindowsUpdate -AcceptAll } -Confirm:$false -verbose -RunNow
                                    #installere opdateringerne hvis de er downloadet.
                                    "  Task Scheduled"
                                }
                            
                            }
                   
                            Invoke-Command -Session $Session -ScriptBlock { Remove-NetFirewallRule -DisplayName "PSWindowsUpdate (RPC Dynamics Ports)" }
                            #Fjerner firewall reglen som WURemote laver.

                            Stop-Transcript

                        }
                        catch {
                            Write-Host "$object Error...Maybe access is Denied or wrong Password" -ForegroundColor Red
                            Write-Output $Error[0]"`n"  | Out-File -FilePath C:\Windows\Logs\ServersWithError.txt -Append #ændre filepath hvis filen skal ligge et andet sted 
                        }
                        } 
                        else {
                            #Tjekker om den kan finde et password i 1password
                            Write-Host "$object eksistere ikke i 1PASSWORD!" -ForegroundColor RED
                        }
                        } 
                        else {
                            Write-Host "Server $fejl eksisterer IKKE!" -ForegroundColor Red 
                        }
                        Remove-PSSession -ComputerName * -ErrorAction Ignore
                        #Fjerner alle sessions man har lavet. Der er et loft på hvor mange man kan have åbne
                    }
                }
                "No" {

                } 
            }
        }
        '4' {
            Start-Transcript -Path "C:\windows\logs\Status.txt"
            
            $ResultReturn = @() #Laver en empty array som vi bruger længere nede for at kunne få data ud i en txt fil
            foreach ($object in $Allservers) {
                "`n"
                $TestCon = Test-Connection -ComputerName $object -Count 1 -Quiet
                if ($TestCon -eq $true) {
                    #tester om der er en connection til servere, om den eksistere
                    $Cred = Get-CurrentPassword $object -ErrorAction SilentlyContinue

                    if ($Cred -ne $null) {
                        
                        try {
                            $Session = New-PSSession -ComputerName $object -Credential $Cred -ErrorAction Stop
                                
                            $Result = Invoke-Command -Session $Session -ScriptBlock {
                                Enable-WURemoting
                                #Laver en firewall regl så man kan forbinde til serveren
                                $Get = Get-WindowsUpdate

                                if ([string]::IsNullorEmpty($Get) -eq $false) {
                                    foreach ($line in $get) {
                                        $line.ComputerName + " " + $line.status + " " + $line.KB + "`n"
                                    }
                                         
                                }
                                else {
                                    "{0} Er installeret""`n" -f $env:COMPUTERNAME
                                 
                                }
                                #Laver en status på om opdateringerne er downloadet eller installeret
                            }
                            Invoke-Command -Session $Session -ScriptBlock { Remove-NetFirewallRule -DisplayName "PSWindowsUpdate (RPC Dynamics Ports)" } #Der skal laves en invoke-command, ellers kan den ikke finde Displayname
                            #Fjerner firewall reglen som WURemote laver
                        } 
                        catch {
                            Write-Host "$object Error...Maybe access is Denied or wrong Password" -ForegroundColor Red
                            Write-Output $Error[0]"`n" | Out-File -FilePath C:\Windows\Logs\Error.txt -Append 
                        }
                        Write-Host $Result

                        if ($Result -match "-D") {
                            $ResultReturn += $Result.Split(" ")[0]
                        } #Putter $result ind i $resultReturn array. Der laves en split på det først ord indtil der kommer et mellemrum. I det her tilfælde er det server navnet

                    } else {
                        #Tjekker om den kan finde et password i 1password
                        Write-Host "$object eksistere ikke i 1PASSWORD!" -ForegroundColor RED
                    }
                }
                else {
                    Write-Host "Server $object eksisterer IKKE!" -ForegroundColor Red
                }
                Clear-Variable Result
                Remove-PSSession -ComputerName * -ErrorAction Ignore
                #Fjerner alle sessions man har lavet. Der er et loft på hvor mange man kan have åbne

            }
            
            $ResultReturn | Sort-Object | Get-Unique | Out-File -FilePath C:\Windows\Logs\ServersInProgress.txt 
            #Laver en out-file med alle servere som stadig mangler at få installeret opdateringerne
            Stop-Transcript
        }
        '5' {
            $GetCon = Get-Content -Path "C:\windows\logs\ServersInProgress.txt" -ErrorAction Ignore #Får fat i txt filen med serverne som mangler at få installeret opdateringerne
            $ResultReturn2 = @() #Laver en empty array som vi bruger længere nede for at kunne få data ud i en txt fil

            foreach ($Servers in $GetCon) {
                "`n"
                $TestCon2 = Test-Connection -ComputerName $Servers -Count 1 -Quiet
                #tester om der er en connection til servere, om den eksistere
                if ($TestCon2 -eq $true){
                    $Cred = Get-CurrentPassword $Servers

                    if ($Cred -ne $null){
                        
                        try {
                        $Session = New-PSSession -ComputerName $Servers -Credential $Cred -ErrorAction stop

                        $Result2 = Invoke-Command -Session $Session -ScriptBlock {
                            Enable-WURemoting
                            #Laver en firewall regl så man kan forbinde til serveren
                            $Get = Get-WindowsUpdate
                            if ([string]::IsNullorEmpty($Get) -eq $false) {
                                foreach ($line in $get) {
                                    $line.ComputerName + " " + $line.status + " " + $line.KB + "`n"
                                }
                            }
                            else {
                            "{0} Er installeret""`n" -f $env:COMPUTERNAME            
                            }#Laver en status på om opdateringerne er downloadet eller installeret
                        }
                        Invoke-Command -Session $Session -ScriptBlock { Remove-NetFirewallRule -DisplayName "PSWindowsUpdate (RPC Dynamics Ports)" } #Der skal laves en invoke-command, ellers kan den ikke finde Displayname
                        #Fjerner firewall reglen som WURemote laver
                        } 
                        catch {
                            Write-Host "$object Error...Maybe access is Denied or wrong Password" -ForegroundColor Red
                            Write-Output $Error[0]"`n"  | Out-File -FilePath C:\Windows\Logs\ServersWithError.txt -Append 
                        }
                        Write-Host $Result2

                        if ($Result2 -match "-D") {
                        $ResultReturn2 += $Result2.split(" ")[0]
                        } #Putter $result2 ind i $resultReturn2 array. Der laves en split på det først ord indtil der kommer et mellemrum. I det her tilfælde er det server navnet
                    } 
                    else {
                        #Tjekker om den kan finde et password i 1password
                        Write-Host "$object eksistere ikke i 1PASSWORD!" -ForegroundColor RED
                    }
                } 
                else {
                   Write-Host "Server $Servers eksisterer IKKE!" -ForegroundColor Red 
                }
                Clear-Variable Result2
                Remove-PSSession -ComputerName * -ErrorAction Ignore
                #Fjerner alle sessions man har lavet. Der er et loft på hvor mange man kan have åbne
            }
            
            $ResultReturn2 | Sort-Object | Get-Unique | Out-File -FilePath C:\Windows\Logs\ServersInProgress.txt
            #Laver en out-file med alle servere som stadig mangler at få installeret opdateringerne
        }
        'P' {
            Write-host "Printer Custom Patch fil til C:\Windows\Logs\CustomPatchServers.txt" -ForegroundColor Green
            $CustomServers | Out-File -FilePath C:\Windows\Logs\CustomPatchServers.txt
            #Laver en txt fil med alle custom serveres som ikke opdateres automatisk
        }
        '9' {
            #Genstarter alle SQL servere
            $msgbox_9 = [System.Windows.MessageBox]::Show("Reboot SQL servers?", "Server Update", "YesNo", "Error")
            switch ($msgbox_9) {
                "Yes" {


                    foreach ($object in $SQL_Servers) {
                        $Cred = Get-CurrentPassword $object
                        try {
                            Restart-Computer -ComputerName $object -Credential $Cred -Force -ErrorAction Stop
                            Start-Sleep -Seconds 10
                    
                        }
                        catch {
                            Write-Output $Error[0]"`n"  | Out-File -FilePath C:\Windows\Logs\ServersWithError.txt -Append #ændre filepath hvis filen skal ligge et andet sted 
                        } 
                        Remove-PSSession -ComputerName * -ErrorAction Ignore
                        #Fjerner alle sessions man har lavet. Der er et loft på hvor mange man kan have åbne
                    }
                    
                }
                    
                "No" {
                
                }
            }
        } 
        '0' {
            #Genstarter alle andre servere end SQL
            $msgbox_0 = [System.Windows.MessageBox]::Show("Reboot All other servers?", "Server Update", "YesNo", "Error")
            switch ($msgbox_0) {
                "Yes" {


                    foreach ($object in $NoSQLServer) {
                        $Cred = Get-CurrentPassword $object
                        try {
                            Restart-Computer -ComputerName $object -Credential $Cred -Force -ErrorAction Stop
                            Start-Sleep -Seconds 10
                    
                        }
                        catch {
                            Write-Output $Error[0]"`n"  | Out-File -FilePath C:\Windows\Logs\ServersWithError.txt -Append #ændre filepath hvis filen skal ligge et andet sted 
                        }
                        Remove-PSSession -ComputerName * -ErrorAction Ignore
                        #Fjerner alle sessions man har lavet. Der er et loft på hvor mange man kan have åbne
                    } 
                    
                }
                "No" {
                }
            }
        }
        'q' {
            return
        }
    }
    pause
}
until ($selection -eq 'q')