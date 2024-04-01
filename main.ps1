param (
    [Parameter(Mandatory = $true)]
    [string]$RootReportPath
)

$logFile = "$((Get-Date).toString("yyyy-MM-dd.HH-mm-ss")).log"
$startTime = Get-Date
function WriteLog([string]$message) {
    $currentDateTime = Get-Date
    $elapsedTime = $currentDateTime - $startTime
    $formattedTime = '{0:HH:mm:ss} [{1:hh\:mm\:ss}]' -f $currentDateTime, $elapsedTime
    $logMessage = "$formattedTime $message"
    Add-content $logFile -value $logMessage
    Write-Host $logMessage
}

if (!(Test-Path $RootReportPath)) {
    WriteLog "Err $RootReportPath directory does not exist."
    exit
}
$rootPath = Resolve-Path -Path $RootReportPath
WriteLog "Statement Root Path: $($rootPath)"

$organizations = Get-ChildItem -Path $rootPath -Directory | Where-Object { $_.Name -match '^\d{5}$' }

foreach ($organization in $organizations) {
    WriteLog "$($organization.Name) ($($organizations.IndexOf($organization) + 1)/$($organizations.Length))"
    $partiesFilePath = Join-Path -Path $organization -ChildPath "$($organization.Name)_partije.json"

    if (!(Test-Path $partiesFilePath)) {
        WriteLog "  Err $($organization.Name)_partije.json file does not exist."
        continue
    }
    try {
        $parties = Get-Content -Path $partiesFilePath -Raw | ConvertFrom-Json -Depth 100
    }
    catch {
        WriteLog "  Err $($organization.Name)_partije.json does not appear to be a valid json file."
        continue
    }
    
    $organizationIds = $parties.psobject.Properties | Select-Object -ExpandProperty Name
    $partesRegex = ($parties.psobject.Properties | Select-Object -ExpandProperty Value) -join "|"
 
    $dates = Get-ChildItem -Path $rootPath -File -Recurse | `
        Where-Object { $organizationIds -Contains $_.Directory.Parent.Name } | `
        Where-Object { $_.Directory.Name -match '^\d{4}-\d{2}-\d{2}$' } | `
        Where-Object { $_.Name -match "($partesRegex)\.(json|txt|pdf)\.zip$" } | `
        Select-Object -ExpandProperty Directory -Unique

    foreach ($date in $dates) {
        $workingDirectory = Join-Path $rootPath ".$([System.Guid]::NewGuid()))"

        [array]$allZipFilesForDate = @()
        foreach ($org in $parties.psobject.Properties) {
            $orgId = $org.Name
            $orgParties = $org.Value

            foreach ($orgParty in $orgParties) {
                $searchDateDir = Join-Path $rootPath $orgId $date.Name
                if (!(Test-Path $searchDateDir)) {
                    continue
                }
                $allZipFilesForDate += Get-ChildItem -Path $searchDateDir -File | Where-Object { $_.Name -match "$($orgParty)\.(json|txt|pdf)\.zip$" }
            }
        }

        WriteLog "  $($date.Name) ($($allZipFilesForDate.Length))"
        if ($allZipFilesForDate.Length -eq 0) {
            continue
        }
        try {
            foreach ($zipFile in $allZipFilesForDate) {
                Expand-Archive -Path $zipFile -DestinationPath $workingDirectory | Out-Null
            }
            $filesToCompress = Get-ChildItem -Path $workingDirectory -File
            $zipDir = Join-Path $organization $date.Name
            New-Item -Path $zipDir -ItemType Directory -Force | Out-Null
            $reportZip = Join-Path  $zipDir "$($organization.Name)_sve-partije.zip"
            Compress-Archive -Path $filesToCompress -DestinationPath $reportZip -Force | Out-Null
            
            $logMessage = "    "
            $filesToCompress | Group-Object { $_.BaseName } | ForEach-Object {
                $extensions = $_.Group.Extension.TrimStart('.') -join ' '
                $logMessage += "$($_.Name) ($extensions) "
            }
            WriteLog $logMessage
        }
        catch {
            WriteLog "    Err was encountered during the creation of the zip archive. Message: $($_.Exception)"
        }
        finally {
            if (Test-Path $workingDirectory) {
                Remove-Item -Path $workingDirectory -Recurse -Force
            }        
        }
    }
}

WriteLog "Done"