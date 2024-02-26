#!/usr/bin/env pwsh

[CmdletBinding()]
param(
  [parameter()]
  [int32]
  $NumberOfIterations = 100,

  [parameter(Mandatory)]
  [string]
  $Url,

  [parameter(Mandatory)]
  [System.Management.Automation.PSCredential]
  $Creds
)

function Test-NtlmUrl {
  [CmdletBinding()]

  param(
    [parameter()]
    [int32]
    $NumberOfIterations = 100,

    [parameter()]
    [string]
    $Url,

    [parameter()]
    [System.Management.Automation.PSCredential]
    $Creds
  )

  for ($i = 0; $i -lt $NumberOfIterations; $i++) {
    try {
      Invoke-RestMethod $Url -Credential $Creds
    }
    catch {
      Write-Host "Error on iteration number $($i + 1)"
      $_
      break
    }
  }
}

Test-NtlmUrl -Url $Url -Creds $Creds -NumberOfIterations $NumberOfIterations
