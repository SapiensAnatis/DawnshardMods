. ./options.ps1
. ./options.local.ps1

$buildPath = Join-Path $pwd "build"
Remove-Item $buildPath -Force -Recurse

$OutputHashes = [ordered]@{}

function Write-Title {
    param (
        [string] $Message,
        [System.ConsoleColor] $Color = 'Green'
    )

    $desiredLength = 80
    $sideLength = ($desiredLength - $Message.Length - 2) / 2

    $firstHalf = "$('=' * $sideLength) $Message "
    $secondHalf = "$('=' * ($desiredLength - $firstHalf.Length))"

    Write-Host "${firstHalf}${secondHalf}" -ForegroundColor $Color
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

    $outputDir = Join-Path $pwd "build" $Platform
    $dir = New-Item -Path $outputDir -ItemType Directory -Force
    
    $dir.FullName
}

function Get-BundleOutputPath {
    param (
        [string] $BundlePath
    )

    $hash = Invoke-ModTools "hash" $BundlePath
    $outputDir = Join-Path $outputDir "assets" "$hash".Substring(0, 2)
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    $outputPath = Join-Path $outputDir $hash

    $outputPath
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
        Write-Error "ModTools invocation failed with exit code $LASTEXITCODE"
        exit 1
    }
}

function Merge-Manifest {
    param (
        [string] $Locale,
        [string] $Platform
    )

    $manifestName = Get-ManifestName $Locale
    $outputDir = Get-OutputDir $Platform.ToLower()

    $targetManifest = Join-Path $outputDir "manifests" $manifestName
    $sourceManifest = Join-Path $ManifestToMerge $manifestName

    $outputManifestDir = Join-Path $outputDir "manifests"
    $outputAssetDir = Join-Path $outputDir "assets"

    $mergeArgs = @("manifest", "merge", "--target", $targetManifest, "--source", $sourceManifest, "--output-manifests", $outputManifestDir, "--output-bundles", $outputAssetDir,  "--assets-path", "$SrcAssetDir,$SrcAssetDir2")
    
    if ($Platform -eq "iOS") {
        $mergeArgs += "--convert"
    }
    
    Invoke-ModTools $mergeArgs
}

function Add-Bundles {
    param (
        [string] $Platform
    )

    $manifestName = Get-ManifestName "ja_jp" # We don't need to add localized bundles... yet
    $outputDir = Get-OutputDir $Platform.ToLower()
    $manifestPath = Join-Path $outputDir "manifests" $manifestName

    $bundlesDir = Join-Path "additionalBundles" $Platform.ToLower()

    Invoke-ModTools manifest add-bundles $manifestPath --bundles $bundlesDir --output $manifestPath

    foreach ($bundle in Get-ChildItem $bundlesDir) {
        $outputPath = Get-BundleOutputPath $bundle
        Copy-Item $bundle $outputPath -Force
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

    Invoke-ModTools import-multiple $masterSourcePath --directory $dictionaryDir --output $masterTmpPath

    if ($BannerConfig) {
        Invoke-ModTools banner $BannerConfig --master $masterTmpPath --output $masterTmpPath
    }

    $textLabelPath = Join-Path $pwd "textlabel" "${Locale}.json"

    Invoke-ModTools "import" $masterTmpPath --asset "TextLabel" --dictionary $textLabelPath "--inplace"

    $masterOutputPath = Get-BundleOutputPath $masterTmpPath
    Move-Item $masterTmpPath $masterOutputPath -Force

    $manifestSourcePath = Join-Path $pwd "source" $platformLower $manifestName
    $manifestOutputDir = Join-Path $outputDir "manifests"
    $manifestOutputPath = Join-Path $manifestOutputDir $manifestName

    New-Item -Path $manifestOutputDir -ItemType Directory -Force | Out-Null
    Invoke-ModTools "manifest" "edit-master" $manifestSourcePath --master $masterOutputPath --output $manifestOutputPath

    if ($Locale -eq "ja_jp") {
        Add-Bundles $Platform
    }

    $OutputHashes["${Platform}_${Locale}"] = [System.IO.Path]::GetFileName($masterOutputPath)
}

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

foreach ($locale in $Locales) {
    foreach ($platform in $Platforms) {
        Write-Title "Starting build for $locale / $platform"

        Build-Locale $locale $platform

        if ($ManifestToMerge) {
            Merge-Manifest $locale $platform
        }

        Write-Title "Build complete"
    }
}

$elapsed = $stopwatch.Elapsed.TotalSeconds

Write-Title "All builds complete" -Color Magenta
Write-Host "Total build time: $elapsed seconds."
Write-Host "New master hashes:"
$OutputHashes
