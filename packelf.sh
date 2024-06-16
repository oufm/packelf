#!/usr/bin/env sh
#set -o pipefail # bash extension
set -e

# These vars will be modified automatically with sed
run_mode=packer
compress_flag=-z
program=
ld_so=

load() {
    script_path="$0"

    while link_path=$(readlink "$script_path"); do
        script_path="$link_path"
    done

    unpack_dir=$(dirname "$script_path")

    exec "$unpack_dir/$program.res/$ld_so" \
        --library-path "$unpack_dir/$program.res" \
        "$unpack_dir/$program.res/$program" "$@"
    # unreachable
}

if [ "$run_mode" = loader ]; then
    load "$@"
fi

pack_help() {
    echo "Usage: $0 [-zjJn] <ELF_SRC_PATH> <DST_PATH> [ADDITIONAL_LIBS ...]"
    echo "      -zjJ    compress flag passed to tar, '-z' by default"
    echo "      -n      pack without compress"
}

pack() {
    [ $# -ge 2 ] || {
        pack_help
        exit 1
    }

    case $1 in
        -z|-j|-J)
            compress_flag=$1
            shift
        ;;
        -n)
            compress_flag=''
            shift
        ;;
        -h|--help)
            pack_help
            exit 0
        ;;
        *)
        ;;
    esac

    src="$1"
    shift
    dst="$1"
    shift

    libs="$(ldd "$src" | grep -F '/' | sed -E 's|[^/]*/([^ ]+).*?|/\1|')"
    ld_so="$(echo "$libs" | grep -F '/ld-linux-' || echo "$libs" | grep -F '/ld-musl-')"
    ld_so="$(basename "$ld_so")"
    program="$(basename "$src")"

    cat "$0" | sed -E \
        -e 's/^run_mode=[^ ]*$/run_mode=unpacker/' \
        -e 's/^compress_flag=[^ ]*$/compress_flag='"$compress_flag"'/' \
        -e 's/^program=[^ ]*$/program='"$program"'/' \
        -e 's/^ld_so=[^ ]*$/ld_so='"$ld_so"'/' \
        >"$dst"

    tar $compress_flag -ch \
        --transform 's@.*/@'"$program"'.res/@' \
        "$src" $libs "$@" \
        >>"$dst" #\
        #2> >(grep -v 'Removing leading' >&2) # bash extension

    chmod +x "$dst"
    echo "'$src' was packed to '$dst'"
    echo "$dst" | grep -q / || dst="./$dst"
    echo "Just run '$dst ARGS...' to execute the command."
    echo "Or run 'PACKELF_UNPACK_DIR=xxx $dst' to unpack it only."
}

unpack() {
    if [ -n "$PACKELF_UNPACK_DIR" ]; then
        [ -d "$PACKELF_UNPACK_DIR" ] || {
            echo "'$PACKELF_UNPACK_DIR' is not a dir."
            exit 1
        }
        [ -e "$PACKELF_UNPACK_DIR/$program" ] && {
            echo "'$PACKELF_UNPACK_DIR/$program' already exists, please remove it first."
            exit 1
        }
        unpack_dir="$PACKELF_UNPACK_DIR"

    else
        if [ -n "$PACKELF_TMP_DIR" ]; then
            unpack_dir="$PACKELF_TMP_DIR"
        else
            tmp_parent=/tmp/packelf_tmp
            mkdir -p "$tmp_parent"
            unpack_dir=$(mktemp -d -p "$tmp_parent" || echo "$tmp_parent")
        fi

        trap 'rm -rf "$unpack_dir"' 0 1 2 3 6 10 12 13 14 15
    fi

    check_path="$unpack_dir/__check_permission__"
    if ! (echo > "$check_path" && chmod +x "$check_path" && [ -x "$check_path" ]); then
        rm -rf "$unpack_dir"
        tmp_parent="$(pwd)/packelf_tmp"
        mkdir -p "$tmp_parent"
        unpack_dir="$(mktemp -d -p "$tmp_parent"  || echo "$tmp_parent")"
    fi

    sed '1,/^#__END__$/d' "$0" | tar $compress_flag -x -C "$unpack_dir"
    sed -i 's@/etc/ld.so.preload@/etc/___so.preload@g' "$unpack_dir/$program.res/$ld_so"

    if [ -n "$PACKELF_UNPACK_DIR" ]; then
        sed '/^#__END__$/,$d' "$0" > "$unpack_dir/$program"
        sed -i -E 's/^run_mode=\w*$/run_mode=loader/' "$unpack_dir/$program"
        chmod +x "$unpack_dir/$program"
        rm -f "$check_path"
        echo "'$program' was unpacked to '$unpack_dir'."
        echo "$unpack_dir" | grep -q / || unpack_dir="./$unpack_dir"
        echo "You can run '$unpack_dir/$program ARGS...' to execute the command."

    else
        "$unpack_dir/$program.res/$ld_so" \
            --library-path "$unpack_dir/$program.res" \
            "$unpack_dir/$program.res/$program" "$@"
        exit $?
    fi
}


if [ "$run_mode" = unpacker ]; then
    unpack "$@"
else
    pack "$@"
fi

exit 0
#__END__
