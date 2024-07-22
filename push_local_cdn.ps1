$LocalCdnBundlePath = "D:\DragaliaLost Assets\EU_locale"
$LocalCdnManifestPath = "D:\DragaliaLost Assets\EU_locale\manifest"
$Platforms = "Android", "iOS"

$BuildDir = Join-Path $pwd "build"

foreach ($platform in $Platforms) {
    $assetDir = Join-Path $BuildDir $platform "assets"
    $manifestDir = Join-Path $BuildDir $platform "manifests"

    if (-Not(Test-Path -Path $assetDir) || -Not(Test-Path -Path $manifestDir)) {
        Write-Host "Skipping platform ${platform}: build output not found"
        continue
    }

    $manifestName = Read-Host "What should the new manifest for '$platform' be called?"
  

    $destinationManifestDir = Join-Path $LocalCdnManifestPath $manifestName
    New-Item -Path $destinationManifestDir -ItemType Directory -Force

    Write-Host "Copying asset bundles to $LocalCdnBundlePath" -ForegroundColor Blue
    Copy-Item "$assetDir/*" $LocalCdnBundlePath -Recurse -Force

    Write-Host "Copying manifests to $destinationManifestDir" -ForegroundColor Blue
    Copy-Item "$manifestDir/*" $destinationManifestDir -Recurse -Force
}
