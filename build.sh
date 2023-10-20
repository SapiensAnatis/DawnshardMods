MOD_TOOLS=/home/jay/DragaliaModTools/ModTools/bin/Debug/net6.0/ModTools

print_and_exec() {
    echo "> $@"
    eval "$@"
}

build_locale() {
    local locale=$1
    local platform=$2

    if [[ "$locale" = "ja_jp" ]]; then
        local manifest="assetbundle.manifest"
    else
        local manifest="assetbundle.${locale}.manifest"
    fi

    echo "Using platform ${platform}"
    echo "Using locale ${locale}"
    echo "Using manifest name ${manifest}"

    local output_dir=./build/${platform}
    local output_file=${output_dir}/${locale}_master
    mkdir -p ${output_dir}

    # Apply mods
    print_and_exec ${MOD_TOOLS} import-multiple ./source/${platform}/${locale}_master ./dictionaries ${output_file}
    print_and_exec ${MOD_TOOLS} import ${output_file} TextLabel ./textlabel/${locale}.json --inplace

    # Rename with hash and move
    local hash=$($MOD_TOOLS hash $output_file)
    local new_output_dir="${output_dir}/${hash:0:2}"
    mkdir -p ${new_output_dir}
    print_and_exec mv ${output_file} "${new_output_dir}/${hash}"
    output_file="${new_output_dir}/${hash}"

    # Update manifest
    print_and_exec ${MOD_TOOLS} manifest ./source/${platform}/${manifest} ${output_file} ${output_dir}/${manifest}

    echo "Build complete\n\n"
}

build_locale "ja_jp" "android"
build_locale "en_us" "android"
build_locale "en_eu" "android"
