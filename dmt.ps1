param (
  [Parameter(Mandatory=$true)]
  [string]$date,
  [Parameter(Mandatory=$true)]
  [int]$numberOfOrganizations,
  [Parameter(Mandatory=$true)]
  [int]$numberOfParties,
  [Parameter(Mandatory=$true)]
  [int]$numberOfActiveParties,
  [Parameter(Mandatory=$true)]
  [int]$numberOfExternalParties
)

$ErrorActionPreference = "Stop"

function GenerateRandomId {
  param (
      [int]$numberOfDigits
  )
  return -join (1..$numberOfDigits | ForEach-Object { Get-Random -Minimum 0 -Maximum 10 })
}


function GenerateRandomNumberInRange {
  param (
      [int]$min,
      [int]$max
  )
  return Get-Random -Minimum $min -Maximum $max
}

function GenerateOrganizations {
  param (
      [int]$count = 1
  )
  $organizations = @()
  foreach ($_ in 1..$count) {
      $org = New-Object PSObject
      $uid = GenerateRandomId -numberOfDigits 6
      $org | Add-Member -MemberType NoteProperty -Name "id" -Value $uid
      $org | Add-Member -MemberType NoteProperty -Name "parties" -Value @()
      $organizations += $org
  }

  return $organizations

}

function GenerateDataObject {
  param (
      [string]$date
  )
  return [PSCustomObject]@{
      organizations = @()
      date          = $date
  }
}


function GenerateParties {
  param (
      [int]$count = 1
  )
  $parties = @()
  foreach ($_ in 1..$count) {
      $uid = GenerateRandomId -numberOfDigits 13
      $party = [PSCustomObject]@{
          id             = $uid
          lastActivity   = ""
          type           = ""
          organizationId = ""
      }
      $parties += $party
  }

  return $parties
}


function RecordActivity {
  param (
      [int]$numberOfActiveParties,
      [Object[]]$parties,
      [string]$date
  )
  if ($numberOfActiveParties -gt $parties.length) {
      Write-Output "Invalid range for active parties."
      exit
  }

  $cloneParties = @() + $parties
  foreach ($i in 0..($cloneParties.length - 1)) {
      if ($i -lt $numberOfActiveParties) {
          $cloneParties[$i].lastActivity = $date
      }
      else {
          $randomDay = GenerateRandomNumberInRange -min 10 -max 100
          $cloneParties[$i].lastActivity = $(Get-Date $date).AddDays(-$randomDay).ToString("yyyy-MM-dd")
      }
  }
  return $cloneParties

}

function DistributeInternalParties {
  param (
      [Object[]]$organizations,
      [Object[]]$parties
  )

  foreach ($party in $parties) {
      $randomIndex = GenerateRandomNumberInRange -min 0 -max $organizations.length
      $org = $organizations[$randomIndex]
      $p = [PSCustomObject]@{
          id             = $party.id
          lastActivity   = $party.lastActivity
          type           = "internal"
          organizationId = $org.id
      }
      $org.parties += $p    
  }
  
  return $organizations

}

function DistributeExternalParties {
  param (
      [Object[]]$organizations,
      [Object[]]$parties,
      [int]$numberOfExternalParties
  )
  $count = 0

  foreach ($party in $parties) {
      if ($count -eq $numberOfExternalParties) {
          break
      }
      $orgsToWorkWith = @(ExcludeOriginOrganization -organizations $organizations -partyId $party.id)
      $randomIndex = GenerateRandomNumberInRange -min 0 -max $orgsToWorkWith.length
      $org = $orgsToWorkWith[$randomIndex]
      $originOrganization = GetOriginOrganization -organizations $organizations -partyId $party.id
      $p = [PSCustomObject]@{
          id             = $party.id
          lastActivity   = $party.lastActivity
          type           = "external"
          organizationId = $originOrganization.id
      }
      $org.parties += $p    
      $count = $count + 1
  }
  
  return $organizations

}

function ExcludeOriginOrganization {
  param (
      [Object[]]$organizations,
      [string]$partyId
  )
  $result = @()
  foreach ($org in $organizations) {
      $partyList = $org.parties | Where-Object { $_.id -eq $partyId }
      if ($partyList.length -eq 0) {
          $result += $org
      }
  }
  return $result
}

function GetOriginOrganization {
  param (
      [Object[]]$organizations,
      [string]$partyId
  )
  foreach ($org in $organizations) {
      $partyList = $org.parties | Where-Object { $_.id -eq $partyId -and $_.type -eq "internal" }
      if ($partyList.length -gt 0) {
          return $org
      }
  }
  return {};
}



$object = GenerateDataObject -date $date
$orgs = GenerateOrganizations -count $numberOfOrganizations
$parties = GenerateParties -count $numberOfParties
$parties = RecordActivity -numberOfActiveParties $numberOfActiveParties -parties $parties -date $date
$orgs = DistributeInternalParties -organizations $orgs -parties $parties
$orgs = DistributeExternalParties -organizations $orgs -parties $parties -numberOfExternalParties $numberOfExternalParties

$object.organizations = $orgs

$fileContent = $object | ConvertTo-Json -Depth 100
Write-Output $fileContent
