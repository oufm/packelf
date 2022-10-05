#!/bin/bash
set -eo pipefail

[ $# -lt 2 ] && {
    echo "usage: $0 <ELF_SRC_PATH> <DST_PATH> [ADDITIONAL_LIBS ...]"
    exit 1
}

src="$1"
dst="$2"
shift
shift

cat >"$dst" <<EOF
#!/bin/bash
tmp_dir="\$(mktemp -d)"
check_path="\$tmp_dir/__check_permission__"
trap 'rm -rf \$tmp_dir' 0 1 2 3 6
if ! (touch "\$check_path" && chmod +x "\$check_path" && [ -x "\$check_path" ]); then
    rm -rf "\$tmp_dir"
    tmp_dir="\$(TMPDIR="\$(pwd)" mktemp -d)"
fi
sed '1,/^#__END__$/d' "\$0" | tar -xz -C "\$tmp_dir"
"\$tmp_dir/LD_SO" --library-path "\$tmp_dir" "\$tmp_dir/PROGRAM" "\$@"
exit \$?
#__END__
EOF

libs="$(ldd "$src" | grep -F '/' | sed -E 's|[^/]*/([^ ]+).*?|/\1|')"
ld_so="$(echo "$libs" | grep -F '/ld-linux-')"
sed -E -i -e 's|PROGRAM|'"$(basename "$src")"'|' -e 's|LD_SO|'"$(basename "$ld_so")"'|' "$dst"
tar -czh --transform 's/.*\///g' "$src" $libs >>"$dst" "$@" 2> >(grep -v 'Removing leading' >&2)
chmod +x "$dst"
