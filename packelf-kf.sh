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

libs="$(ldd "$src" | grep -F '/' | sed -E 's|[^/]*/([^ ]+).*?|/\1|')"
ld_so="$(echo "$libs" | grep -F '/ld-linux-')"
ld_so="$(basename "$ld_so")"
program="$(basename "$src")"

cat >"$dst" <<EOF
#!/usr/bin/env sh
tmp_dir="/tmp/static-$program"
if [ ! -d "\$tmp_dir" ]; then
    mkdir "\$tmp_dir"
    sed '1,/^#__END__$/d' "\$0" | tar -xz -C "\$tmp_dir"
    sed -i 's@/etc/ld.so.preload@/etc/___so.preload@g' "\$tmp_dir/$ld_so"
fi
"\$tmp_dir/$ld_so" --library-path "\$tmp_dir" "\$tmp_dir/$program" "\$@"
exit \$?
#__END__
EOF

tar -czh --transform 's/.*\///g' "$src" $libs "$@" >>"$dst" 2> >(grep -v 'Removing leading' >&2)
chmod +x "$dst"
