MOD_TOOLS=/home/jay/DragaliaModTools/ModTools/bin/Debug/net6.0/ModTools

print_and_exec() {
    echo "> $@"
    eval "$@"
}

invoke_modtools() {
    echo "> $MOD_TOOLS $@"
    echo -en "\e[34m"
    if ! eval ${MOD_TOOLS} "$@" | sed -e 's/^/ModTools: /;'; then
        echo -en "\e[31m"
        echo ModTools invocation failed.
        exit 1
    fi

    echo -en "\e[0m"
}

build_locale() {
    local locale=$1
    local platform=$2

    if [[ "$locale" = "ja_jp" ]]; then
        local manifest="assetbundle.manifest"
    else
        local manifest="assetbundle.${locale}.manifest"
    fi

    echo "Starting build for ${platform} / ${locale} / ${manifest}"

    local output_dir=./build/${platform}
    local output_file=${output_dir}/${locale}_master
    mkdir -p ${output_dir}

    # Apply mods
    invoke_modtools import-multiple ./source/${platform}/${locale}_master ./dictionaries ${output_file}
    invoke_modtools import ${output_file} TextLabel ./textlabel/${locale}.json --inplace

    # Rename with hash and move
    local hash=$($MOD_TOOLS hash $output_file)
    local new_output_dir="${output_dir}/${hash:0:2}"
    mkdir -p ${new_output_dir}
    print_and_exec mv ${output_file} "${new_output_dir}/${hash}"
    output_file="${new_output_dir}/${hash}"

    # Update manifest
    invoke_modtools manifest ./source/${platform}/${manifest} ${output_file} ${output_dir}/${manifest}

    echo -e "Build complete\n"
}

locales=(
    "ja_jp"
    "en_us"
    "en_eu"
    "zh_cn"
    "zh_tw"
)

for locale in ${locales[@]}; do
    build_locale ${locale} "android"
    build_locale ${locale} "ios"
done
