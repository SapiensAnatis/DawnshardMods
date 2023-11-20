if [[ -z ${MOD_TOOLS} ]]; then
    echo No path to ModTools.exe was specified. Set the environment variable MOD_TOOLS to the path to the executable.
    exit 1
else
    echo Using MOD_TOOLS=${MOD_TOOLS}
    mod_tools=${MOD_TOOLS}
fi

print_and_exec() {
    echo "> $@"
    eval "$@"
}

invoke_modtools() {
    echo "> ${mod_tools} $@"
    echo -en "\e[34m"
    if ! eval ${mod_tools} "$@" | sed -e 's/^/ModTools: /;'; then
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
    invoke_modtools import-multiple "./source/${platform}/${locale}_master" "./dictionaries ${output_file}"
    invoke_modtools import "${output_file}" TextLabel "./textlabel/${locale}.json" --inplace

    # Rename with hash and move
    local hash=$($MOD_TOOLS hash $output_file)
    local new_output_dir="${output_dir}/assets/${hash:0:2}"
    mkdir -p "${new_output_dir}"
    print_and_exec mv "${output_file}" "${new_output_dir}/${hash}"
    output_file="${new_output_dir}/${hash}"

    # Update manifest
    invoke_modtools manifest edit-master \"./source/${platform}/${manifest}\" \"${output_file}\" \"${output_dir}/${manifest}\"

    echo -e "Build complete\n"
}

merge_manifest() {
    local locale=$1
    local platform=$2

    local output_dir=./build/${platform}

    if [[ "$locale" = "ja_jp" ]]; then
        local manifest="assetbundle.manifest"
    else
        local manifest="assetbundle.${locale}.manifest"
    fi

    echo Merging manifest ${manifest_merge_name}/${manifest} into ${output_dir}/${manifest}
    local args="\"${output_dir}/${manifest}\" \"${SRC_MANIFEST_DIR}/${MANIFEST_TO_MERGE}/${manifest}\" \"${SRC_ASSET_DIR}\" \"${output_dir}\""

    if [[ "${platform}" = "ios" ]]; then
        args="${args} --convert"
    fi

    invoke_modtools manifest merge ${args}
}

if [[ -z ${EU_ONLY} ]]; then
    locales=(
        "ja_jp"
        "en_us"
        "en_eu"
        "zh_cn"
        "zh_tw"
    )
else
     locales=(
        "ja_jp"
        "en_us"
        "en_eu"
    )
fi

if [[ -z ${PLATFORM} ]]; then
    platforms=(
        "android"
        "ios"
    )
else
    platforms=(
        ${PLATFORM}
    )
fi

for locale in ${locales[@]}; do
    for platform in ${platforms[@]}; do
        build_locale ${locale} ${platform}
        if [[ -v MERGE_MANIFEST ]]; then
            merge_manifest ${locale} ${platform}
        else 
            echo "Skipping merge"
        fi
    done
done
