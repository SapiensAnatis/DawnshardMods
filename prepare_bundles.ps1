. ./options.ps1
. ./options.local.ps1

function Invoke-ModTools {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]] $MyArgs
    )

    Write-Host "> ModTools $MyArgs" -ForegroundColor Blue

    & $ModToolsPath @MyArgs
   
    if ($LASTEXITCODE) {
        Write-Error "ModTools invocation failed with exit code $LASTEXITCODE"
        exit 1
    }
}

$androidDir = Join-Path "additionalBundles" "android"
$iosDir = Join-Path "additionalBundles" "ios"


foreach ($bundle in Get-ChildItem $androidDir) {
    Invoke-ModTools update-names $bundle "-o" $bundle

    $iosPath = Join-Path $iosDir $bundle.Name
    Invoke-Modtools convert $bundle "-o" $iosPath
}