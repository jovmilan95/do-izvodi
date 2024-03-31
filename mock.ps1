param (
    [Parameter(Mandatory=$true)]
    [string]$Destination,
    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 99999)]
    [int]$NumberOfOrganizations = $(Get-Random -Minimum 1 -Maximum 20),
    [Parameter(Mandatory=$false)]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$NumberOfPartiesPerOrganization = $(Get-Random -Minimum 1 -Maximum 20),
    [Parameter(Mandatory=$false)]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$NumberOfExternalPartiesPerOrganization = `
            $(Get-Random -Minimum 0 -Maximum $NumberOfPartiesPerOrganization),
    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 60)]
    [int]$NumberOfDatesPerParty = $(Get-Random -Minimum 1 -Maximum 10)
)
function GenerateRandomFileName {
    param ()
    $extensions = @("pdf","json","txt","md","xml","csv")
    $length = 10
    $baseName = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count $length | ForEach-Object {[char]$_})
    $randomExtensionIndex = Get-Random -Minimum 0 -Maximum $extensions.Length
    return "$baseName.$($extensions[$randomExtensionIndex])"
}
function IsItTimeForRandomEvent {
    param ()
    $a = (Get-Random -Minimum 10 -Maximum 2000)
    $b = (Get-Random -Minimum 10 -Maximum 1000)
    return ($a % $b) -eq 0
}
function GenerateOrganizations {
    param (
        [int]$count
        
    )
      if ($count -ge 100000) {
          throw "Err maximum limit of 99999 organizations can be generated."
      }
      $organizations = @()
      # Total organization IDs are segmented into $count sections,
      # with each section randomly selecting a number.
      $step = [Math]::Floor(100000 / $count)
      for ($i = 1; $i -le $count; $i++) {
        $minRange = ($i - 1) * $step 
        $maxRange = $i * $step - 1
        if ($minRange -eq $maxRange) {
            $randomId = $maxRange
        } else {
            $randomId = Get-Random -Minimum $minRange -Maximum $maxRange
        }
        $organizations += [PSCustomObject]@{
            Id      = $randomId.ToString("00000")
            InternalParties = @()
            ExternalParties = @()
        }
    }
    return $organizations
  }
function GenerateParties {
    param (
        [int]$count = 1,
        [int]$numberOfActiveDates = 1
    )
      $parties = @()
      # Total party IDs are segmented into $count sections,
      # with each section randomly selecting a number.
      $step = [int]([int]::MaxValue / $count)
      for ($i = 1; $i -le $count; $i++) {
          $minRange = ($i - 1) * $step 
          $maxRange = $i * $step -1 
          $randomId = Get-Random -Minimum $minRange -Maximum $maxRange
          $parties += [PSCustomObject]@{
              Id                 = $randomId.ToString("0000000000000")
              Dates              = GenerateDates($numberOfActiveDates)
              OriginOrganization = ""
          }
      }
      return $parties
  }
function GenerateDates {
    param (
        [int]$count = 1
    )
      if ($count -ge 60) {
          throw "Err maximum limit of 60 dates can be generated."
      }
      $dates = @()
      $step = [Math]::Floor(60 / $count)
      for ($i = 1; $i -le $count; $i++) {
          $minRange = ($i - 1) * $step 
          $maxRange = $i * $step -1 
          if ($minRange -eq $maxRange) {
            $randomId = $maxRange
          } else {
            $randomNumber = Get-Random -Minimum $minRange -Maximum $maxRange
          }
          $dates += (Get-Date).AddDays(-$randomNumber).ToString("yyyy-MM-dd")
      }
  
    return $dates
  }

function GenerateOrganizationBundle {
 param (
      [int]$numberOfOrganizations = 1,
      [int]$numberOfPartiesPerOrganization = 1,
      [int]$numberOfExternalPartiesPerOrganization = 1,
      [int]$numberOfDatesPerParty = 1
  )
    $organizations = GenerateOrganizations -count $numberOfOrganizations
    $totalNumberOfParties = $numberOfPartiesPerOrganization * $numberOfOrganizations
    $parties = GenerateParties `
                -count $totalNumberOfParties `
                -numberOfDatesPerParty $numberOfDatesPerParty
   
    # Parties are segmented based on organizations, 
    # with each segment assigned to a single organization.
    for ($i = 0; $i -lt $organizations.Length; $i++) {
        for ($j = 0; $j -lt $numberOfPartiesPerOrganization; $j++) {
            $index = $i * $numberOfPartiesPerOrganization + $j
            $parties[$index].OriginOrganization = $organizations[$i].Id
            $organizations[$i].InternalParties += $parties[$index]
        }
    }
    if ($numberOfExternalPartiesPerOrganization -eq 0) {
        return $organizations
    } 
    
    foreach($org in $organizations) {
        $externalPartis = $parties | Where-Object { $_.OriginOrganization -ne $org.Id }
        # External parties array is segmented based on the number of organizations, 
        # and then one random party is selected from each segment.
        $rv = $externalPartis.Length / $numberOfExternalPartiesPerOrganization 
        $step = [Math]::Floor($externalPartis.Length / $numberOfExternalPartiesPerOrganization )
        if ($step -eq 0) {
            continue
        } 
        for ($i = 1; $i -le $numberOfExternalPartiesPerOrganization; $i++) {
            $minRange = ($i - 1) * $step 
            $maxRange = $i * $step - 1
            if ($minRange -eq $maxRange) {
                $randomIndex = $maxRange
            } else {
                $randomIndex = Get-Random -Minimum $minRange -Maximum $maxRange
            }
            $org.ExternalParties += $externalPartis[$randomIndex]
        }
    }
    return $organizations
}
function GenerateOranizationIndex {
    param (
        [Object]$organization
    )
    $orgIndex = @{} 
    $orgIndex[$organization.Id.ToString()] = @()
    $organization.ExternalParties | ForEach-Object { $orgIndex[$_.OriginOrganization] = @() }
  
    $organization.InternalParties | ForEach-Object { $orgIndex[$organization.Id] += $_.Id }
    $organization.ExternalParties | ForEach-Object { $orgIndex[$_.OriginOrganization] += $_.Id }
    return $orgIndex 
}
function ApplyToFileSystem {
  param (
      [string]$rootPath,
      [Object[]]$organizations
  )
    $count = 0
    foreach($org in $organizations) {
        foreach($party in $org.InternalParties) {
            foreach($date in $party.Dates) {
                $extensions = @("pdf", "json", "txt")
                foreach($extension in $extensions) {
                    $dir = Join-Path $rootPath $org.Id $date
                    $filePath = Join-Path $dir "$($party.Id).$extension"
                    
                    New-Item -Path $dir -ItemType Directory -Force | Out-Null
                    New-Item -Path $filePath -ItemType File -Force | Out-Null
                    "Some content!" | Set-Content -Path $filePath -Force

                    $zipFile = Join-Path $dir "$($party.Id).$extension.zip"
                    Compress-Archive -Path $filePath -DestinationPath $zipFile -Force
                    Remove-Item -Path $filePath -Force 

                    $timeForRandomFile = IsItTimeForRandomEvent
                    if ($timeForRandomFile) {
                        $randomFile = Join-Path $dir (GenerateRandomFileName)
                        New-Item -Path $randomFile -ItemType File -Force | Out-Null
                        "Some content!" | Set-Content -Path $randomFile -Force
                    }
                }

            }
        }

        $orgIndex = GenerateOranizationIndex -organization $org
        $orgIndexFilePath = Join-Path $rootPath $org.Id "$($org.Id)_partije.json"
        $orgIndex | ConvertTo-Json | Out-File -FilePath $orgIndexFilePath
    }
}

if ($NumberOfExternalPartiesPerOrganization -gt ($NumberOfOrganizations - 1) * $NumberOfPartiesPerOrganization) {
    Write-Host "NumberOfExternalPartiesPerOrganization is out of valid range."
    exit
}

$organizations = GenerateOrganizationBundle `
    -numberOfOrganizations $NumberOfOrganizations `
    -numberOfPartiesPerOrganization $NumberOfPartiesPerOrganization `
    -numberOfDatesPerParty $NumberOfDatesPerParty `
    -numberOfExternalPartiesPerOrganization $NumberOfExternalPartiesPerOrganization
    
ApplyToFileSystem -organizations $organizations -rootPath $Destination