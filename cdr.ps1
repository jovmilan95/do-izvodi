param (
  [Parameter(Mandatory=$true)]
  [string]$JsonFilePath,
  [Parameter(Mandatory=$true)]
  [string]$ReportPath

)

$ErrorActionPreference = "Stop"


function ConvertToJson {
    param (
        [string]$FilePath
    )

    $jsonPath = Resolve-Path -Path $FilePath
    $jsonObject = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
    return  $jsonObject
}


function GenerateReports {
    param (
        [string]$organizationId,
        [string]$partyId,
        [string]$reportRootPath,
        [string]$date
    )
    if (-not (Test-Path -Path $reportRootPath)) {
        New-Item -Path $reportRootPath -ItemType Directory -Force
    }
    GenerateJsonReport -organizationId $organizationId -partyId $partyId -reportRootPath $reportRootPath -date $date
    GenerateTxtReport -organizationId $organizationId -partyId $partyId -reportRootPath $reportRootPath -date $date
    GeneratePdfReport -organizationId $organizationId -partyId $partyId -reportRootPath $reportRootPath -date $date

}



function GenerateJsonReport {
    param (
        [string]$organizationId,
        [string]$partyId,
        [string]$reportRootPath,
        [string]$date
    )
    
    $reportContent = "{ 'reportName': 'Json report for $partyId party' }"
    $workingDir = GetWorkingDir
    $reportJson = Join-Path -Path $workingDir -ChildPath $organizationId
    $reportJson = Join-Path -Path $reportJson -ChildPath $date
    $reportJson = Join-Path -Path $reportJson -ChildPath "$partyId.json"

    $reportDir = Resolve-Path -Path $reportRootPath
    $reportDir = Join-Path -Path $reportDir -ChildPath $organizationId
    $reportDir = Join-Path -Path $reportDir -ChildPath $date
    $reportZip = Join-Path -Path $reportDir -ChildPath "$partyId.json.zip"

    Write-Output "Json report generation process started for organization:$organizationId party:$partyId"
    New-Item -Path $reportJson -ItemType File -Force
    Set-Content -Path $reportJson -Value $reportContent

    New-Item -Path $reportDir -ItemType Directory -Force
    Compress-Archive -Path $reportJson -DestinationPath $reportZip -Force

    Write-Output "Json report generation process finished $reportZip"

}


function GenerateTxtReport {
    param (
        [string]$organizationId,
        [string]$partyId,
        [string]$reportRootPath,
        [string]$date
    )
    
    $reportContent = "Text report for $partyId party"
    $workingDir = GetWorkingDir
    $reportTxt = Join-Path -Path $workingDir -ChildPath $organizationId
    $reportTxt = Join-Path -Path $reportTxt -ChildPath $date
    $reportTxt = Join-Path -Path $reportTxt -ChildPath "$partyId.txt"
    
    $reportDir = Resolve-Path -Path $reportRootPath
    $reportDir = Join-Path -Path $reportDir -ChildPath $organizationId
    $reportDir = Join-Path -Path $reportDir -ChildPath $date
    $reportZip = Join-Path -Path $reportDir -ChildPath "$partyId.txt.zip"
    
    Write-Output "Text report generation process started for organization:$organizationId party:$partyId"

    New-Item -Path $reportTxt -ItemType File -Force
    Set-Content -Path $reportTxt -Value $reportContent

    New-Item -Path $reportDir -ItemType Directory -Force
    Compress-Archive -Path $reportTxt -DestinationPath $reportZip  -Force

    Write-Output "Text report generation process finished $reportZip"
}

function GeneratePdfReport {
    param (
        [string]$organizationId,
        [string]$partyId,
        [string]$reportRootPath,
        [string]$date
    )
    Write-Output "Pdf report generation process started for organization:$organizationId party:$partyId"
    $reportContent = "Pdf report for $partyId party"
    $workingDir = GetWorkingDir
    $reportPdf = Join-Path -Path $workingDir -ChildPath $organizationId
    $reportPdf = Join-Path -Path $reportPdf -ChildPath $date
    $reportPdf = Join-Path -Path $reportPdf -ChildPath "$partyId.pdf"

    $reportDir = Resolve-Path -Path $reportRootPath
    $reportDir = Join-Path -Path $reportDir -ChildPath $organizationId
    $reportDir = Join-Path -Path $reportDir -ChildPath $date
    $reportZip = Join-Path -Path $reportDir -ChildPath "$partyId.pdf.zip"

    New-Item -Path $reportPdf -ItemType File -Force
    Set-Content -Path $reportPdf -Value $reportContent

    New-Item -Path $reportDir -ItemType Directory -Force
    Compress-Archive -Path $reportPdf -DestinationPath $reportZip -Force

    Write-Output "Text report generation process finished $reportZip"
}


function GenerateZipReport {
    param (
        [Object]$organization,
        [string]$reportRootPath,
        [string]$date
    )

    $dir = Resolve-Path -Path $reportRootPath
    $dir = Join-Path -Path $dir -ChildPath $organization.id
    $dir = Join-Path -Path $dir -ChildPath $date
    $zipFile = Join-Path -Path $dir -ChildPath "$($organization.id)_sve-partije.zip"

    Write-Output "All parties archive process started for organization:$($organization.id) date:$date"
    
    $workingDir = GetWorkingDir
    $reportDir = Join-Path -Path $workingDir -ChildPath $organization.id
    $reportDir = Join-Path -Path $reportDir -ChildPath $date


    $files = $(Get-ChildItem -Path $reportDir  -File | ForEach-Object { $_.FullName })
    Compress-Archive -Path $files -DestinationPath $zipFile -Force
    Write-Output "All parties archive process finished $zipFile"

}

function GenerateAllPartiesJson {
    param (
        [Object]$organization,
        [string]$reportRootPath,
        [string]$date
    )
    if (-not (Test-Path -Path $reportRootPath)) {
        New-Item -Path $reportRootPath -ItemType Directory -Force
    }
    $filePath = Resolve-Path -Path $reportRootPath
    $filePath = Join-Path -Path $filePath -ChildPath $organization.id
    $filePath = Join-Path -Path $filePath -ChildPath "$($organization.id)_partije.json"

    Write-Output "All parties file generation process started for organization:$($organization.id)"

    $jsonData = New-Object PSObject

    $internalPartyIds = @($organization.parties | Where-Object { $_.type -eq "internal" } | ForEach-Object { $_.id })
    $jsonData | Add-Member -MemberType NoteProperty -Name $organization.id -Value $internalPartyIds 
    
    $externalPartyGroups = $organization.parties | Where-Object { $_.type -eq "external" } | Group-Object -Property organizationId
    $externalPartyGroups | ForEach-Object {
        $externalPartyIds = @($_.Group | ForEach-Object { $_.id })
        $jsonData | Add-Member -MemberType NoteProperty -Name $_.Name -Value $externalPartyIds
    }

    $fileContent = $jsonData | ConvertTo-Json
    New-Item -Path $filePath -ItemType File -Force
    Set-Content -Path $filePath -Value $fileContent

    Write-Output "All parties file generation process finished $filePath"
}


function CleanupOldArchives {
    param (
        [Object]$organization,
        [string]$reportRootPath,
        [string]$retentionPeriodDays
    )
    if (-not (Test-Path -Path $reportRootPath)) {
        return 
    }

    $organizationDir = Resolve-Path -Path $reportRootPath
    $organizationDir = Join-Path -Path $organizationDir -ChildPath $organization.id
    if (-not (Test-Path -Path $organizationDir)) {
        return 
    }

    Write-Output "Starting archive cleanup for organization $($organization.id)"
    $thresholdDate = (Get-Date).AddDays(-$retentionPeriodDays)
    $directories = Get-ChildItem -Path $organizationDir -Directory | Where-Object { $_.Name -match '^\d{4}-\d{2}-\d{2}$' }
    $directories = $directories | ForEach-Object { Get-Date -Date $_.Name } | Where-Object { $_ -lt $thresholdDate }
    $directoriesToCleanUp = $directories | ForEach-Object { Join-Path -Path $organizationDir -ChildPath $($_.ToString("yyyy-MM-dd")) }


    foreach ($dir in $directoriesToCleanUp) {
        $filesToDelete = Get-ChildItem -Path $dir -File | Where-Object { $_.Name -match '^\d{13}\.(json|txt|pdf)\.zip$' }
        $filesToDelete | Remove-Item -Force
        $filesToDelete | ForEach-Object {
            Write-Output "Removing the report that exceeds the $retentionPeriodDays-day threshold.: $($_.FullName)"
        }

        $allPartiesZipFile = Get-ChildItem -Path $dir -File | Where-Object { $_.Name -match "$($organization.id)_sve-partije.zip" }
        $allPartiesZipFile | Remove-Item -Force
        $allPartiesZipFile | ForEach-Object {
            Write-Output "Removing the report that exceeds the $retentionPeriodDays-day threshold.: $($_.FullName)"
        }

        $remainingFilesCount = $(Get-ChildItem -Path $dir).length
        if ($remainingFilesCount -eq 0) {
            Remove-Item -Path $dir -Recurse -Force
            Write-Output "Empty folder $dir is being deleted."
        }
    }

    Write-Output "The cleanup is complete for organization $($organization.id)"
}

function GetAllActiveParties {
    param (
        [Object]$organization,
        [string]$date
    )
    return @($organization.parties | Where-Object { $_.lastActivity -eq $date })
}



function IsPartyActive {
    param (
        [Object]$party,
        [string]$date
    )
    return $party.lastActivity -eq $date
}


function SetupWorkingDir {
    $env:RUN_UID = [System.Guid]::NewGuid()
    $env:WORKING_DIR = Join-Path -Path $env:TEMP -ChildPath $env:RUN_UID
    New-Item -Path $env:WORKING_DIR -ItemType Directory
    Write-Output "Working dir is set to $($env:WORKING_DIR)"
}

function GetWorkingDir {
    return $env:WORKING_DIR
}

function CleanupWorkingDir {
    Remove-Item -Path $env:WORKING_DIR -Recurse -Force
    Write-Output "Clean working directory $($env:WORKING_DIR)"
}

SetupWorkingDir
$currentDirectory = Get-Location
$logPath = Join-Path -Path $currentDirectory -ChildPath "cdr_$((Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")).log"

Start-Transcript -Path $logPath -Append 

$defaultRetentionPeriodDays = 60
$data = ConvertToJson -FilePath $JsonFilePath

foreach ($organization in $data.organizations) {
    CleanupOldArchives -organization $organization -reportRootPath $ReportPath -retentionPeriodDays $defaultRetentionPeriodDays
    $activeParties = GetAllActiveParties -organization $organization -date $data.date
 
    foreach ($party in $activeParties) {
        GenerateReports -organizationId $organization.id -partyId $party.id -reportRootPath $ReportPath -date $data.date
    }
    GenerateAllPartiesJson -organization $organization -reportRootPath $ReportPath -date $data.date
    if ($activeParties.length -gt 0) {
        GenerateZipReport -organization $organization -reportRootPath $ReportPath -date $data.date
    }
}

CleanupWorkingDir
Stop-Transcript
