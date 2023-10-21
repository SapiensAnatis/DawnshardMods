print_and_exec() {
    echo "> $@"
    eval "$@"
}

print_and_exec rm -rf ./build/*
