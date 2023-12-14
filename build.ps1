$ModToolsPath = "D:\Documents\Programming\dragalia\DragaliaModTools\ModTools\bin\Release\net6.0\ModTools.exe"

# General build options
$Locales = "ja_jp", "en_us", "en_eu", "zh_cn", "zh_tw"
$Platforms = "iOS", "Android"

# Merge options
$ManifestToMerge = "D:\DragaliaLost Assets\EU_locale\manifest\h6lObp9eiVabAdyO"
$SrcAssetDir = "D:\DragaliaLost Assets\EU_locale"


function Write-Title {
    param (
        [string] $Message
    )

    $desiredLength = 80
    $sideLength = ($desiredLength - $Message.Length - 2) / 2

    $firstHalf = "$('=' * $sideLength) $Message "
    $secondHalf = "$('=' * ($desiredLength - $firstHalf.Length))"

    Write-Host "${firstHalf}${secondHalf}" -ForegroundColor Green
}

function Get-ManifestName {
    param (
        [string] $Locale
    )

    if ($Locale -eq "ja_jp") {
        "assetbundle.manifest"
    }
    else {
        "assetbundle.${Locale}.manifest"
    }
}

function Get-OutputDir {
    param (
        [string] $Platform
    )

    $outputDir = Join-Path "build" $Platform
    $dir = New-Item -Path $outputDir -ItemType Directory -Force
    
    $dir.FullName
}

function Invoke-ModTools {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string[]] $MyArgs
    )

    Write-Host "> ModTools $MyArgs" -ForegroundColor Blue

    & $ModToolsPath @MyArgs
   
    if ($LASTEXITCODE) {
        Write-Error "ModTools invocation failed: $LASTEXITCODE"
        Exit-PSHostProcess 1
    }
}

function Build-Locale {
    param (
        [string] $Locale,
        [string] $Platform
    )

    $platformLower = "$platform".ToLower()
    
    $manifestName = Get-ManifestName $Locale
    $outputDir = Get-OutputDir $platformLower

    $masterFileName = "${Locale}_master"
    $masterSourcePath = Join-Path $pwd "source" $platformLower $masterFileName
    $dictionaryDir = Join-Path $pwd "dictionaries"
    $masterTmpPath = Join-Path $outputDir $masterFileName

    Invoke-ModTools import-multiple $masterSourcePath $dictionaryDir $masterTmpPath

    $textLabelPath = Join-Path $pwd "textlabel" "${Locale}.json"

    Invoke-ModTools "import" $masterTmpPath "TextLabel" $textLabelPath "--inplace"

    $hash = $(Invoke-ModTools "hash" $masterTmpPath)
    $masterOutputDir = Join-Path $outputDir "assets" "$hash".Substring(0, 2)
    $masterOutputPath = Join-Path $masterOutputDir $hash

    New-Item -Path $masterOutputDir -ItemType Directory -Force | Out-Null
    Move-Item $masterTmpPath $masterOutputPath -Force

    $manifestSourcePath = Join-Path $pwd "source" $platformLower $manifestName
    $manifestOutputPath = Join-Path $outputDir $manifestName

    Invoke-ModTools "manifest" "edit-master" $manifestSourcePath $masterOutputPath $manifestOutputPath
}

function Merge-Manifest {
    param (
        [string] $Locale,
        [string] $Platform
    )

    $manifestName = Get-ManifestName $Locale
    $outputDir = Get-OutputDir $Platform

    $inputManifest = Join-Path $outputDir $manifestName
    $outputManifest = Join-Path $ManifestToMerge $manifestName

    Invoke-Modtools "manifest" "merge" $inputManifest $outputManifest $SrcAssetDir $outputDir
}

foreach ($locale in $Locales) {
    foreach ($platform in $Platforms) {
        Write-Title "Starting build for $locale / $platform"

        Build-Locale $locale $platform
        Merge-Manifest $locale $platform

        Write-Title "Build complete"
    }
}