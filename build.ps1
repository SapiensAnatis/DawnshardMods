$ModToolsPath = "D:\Documents\Programming\dragalia\DragaliaModTools\ModTools\bin\Release\net6.0\ModTools.exe"

# Merge options
$ManifestToMerge = "D:\DragaliaLost Assets\EU_locale\manifest\h6lObp9eiVabAdyO"
$SrcAssetDir = "D:\DragaliaLost Assets\EU_locale"

$Locales = "ja_jp", "en_us", "en_eu", "zh_cn", "zh_tw"
$Platforms = "iOS", "Android"

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

function Invoke-Modtools {
    param (
        [string] $Command
    )

    Write-Output "> $ModToolsPath $Command"
    Invoke-Expression "& $ModToolsPath $Command"
}

function Merge-Manifest {
    param (
        [string] $Locale,
        [string] $Platform
    )

    $manifestName = Get-ManifestName $Locale
    $outputDir = "./build/${Platform}"

    Write-Output "Merging manifest $ManifestToMerge into ${outputDir}/${manifestName}"

    Invoke-Modtools "manifest merge `"${outputDir}/${manifestName}`" `"${ManifestToMerge}\${manifestName}`" `"${SrcAssetDir}`" `"${outputDir}`""
}

foreach ($locale in $Locales) {
    foreach ($platform in $Platforms) {
        Merge-Manifest $locale $platform
    }
}