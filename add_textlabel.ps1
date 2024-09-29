param (
    [Parameter(Mandatory=$true)] [string] $key,
    [Parameter(Mandatory=$true)] [string] $defaultText
)

$TextLabels = Get-ChildItem "./textlabel"


foreach ($TextLabel in $TextLabels) {
    jq  ".${key} += { `"_Id`": `"${key}`", `"_Text`": `"${defaultText}`" }" $TextLabel > tmp.json
    Move-Item tmp.json $TextLabel -Force
}
