. ./options.ps1
. ./options.local.ps1

$BuildDir = Join-Path $pwd "build"

foreach ($platform in $Platforms) {
    $manifestName = Read-Host "What should the new manifest for '$platform' be called?"
    $platform = $platform.ToLower()
    
    $assetDir = Join-Path $BuildDir $platform "assets"
    $manifestDir = Join-Path $BuildDir $platform "manifests"

    $r2AssetDir = "r2:dragalia/dl/assetbundles/universe/"
    $r2ManifestDir = "r2:dragalia/dl/manifests/universe/$manifestName/"

    Write-Host "Copying asset bundles to $r2AssetDir" -ForegroundColor Blue
    & $RclonePath "copy" $assetDir $r2AssetDir "--progress"

    Write-Host "Copying manifests to $r2ManifestDir" -ForegroundColor Blue
    & $RclonePath "copy" $manifestDir $r2ManifestDir "--progress"
}
