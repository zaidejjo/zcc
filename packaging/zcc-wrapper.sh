#!/bin/sh
# zcc launcher (AUR prebuilt package): the AOT-compiled binary links the
# Rust standard library dynamically, and target machines have no Rust
# toolchain. The needed libstd-*.so ships in /usr/lib/zcc/ next to the
# binary; this wrapper puts it on the loader path. No behavior change
# beyond library resolution — args pass through untouched.
LIBDIR="/usr/lib/zcc"
if [ -n "$LD_LIBRARY_PATH" ]; then
	LD_LIBRARY_PATH="$LIBDIR:$LD_LIBRARY_PATH"
else
	LD_LIBRARY_PATH="$LIBDIR"
fi
export LD_LIBRARY_PATH
exec "$LIBDIR/zcc" "$@"
