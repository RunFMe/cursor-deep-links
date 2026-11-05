#!/bin/sh
# Print a Cursor deep link for a file or folder on this machine.
# Usage: cursor_link.sh <path> [line [column]]
#        cursor_link.sh --remember <alias> [pattern]
#        cursor_link.sh --whoami
# The SSH alias for this machine comes from CURSOR_SSH_HOST or from the hosts
# table: one "<glob pattern> <alias>" per line, matched against this machine's
# hostname, full hostname and DNS search domains. The alias "local" means
# Cursor runs on this machine.
set -eu

table=${CURSOR_LINK_HOSTS:-${XDG_CONFIG_HOME:-$HOME/.config}/cursor-deep-links/hosts}

# Names this machine goes by, one per line.
names() {
	{
		hostname 2>/dev/null || true
		hostname -f 2>/dev/null || true
		awk '$1 == "search" || $1 == "domain" { for (i = 2; i <= NF; i++) print $i }' /etc/resolv.conf 2>/dev/null || true
	} | awk 'NF && !seen[$0]++'
}

# Print the alias of the first table line whose pattern matches one of our names.
lookup() {
	[ -r "$table" ] || return 0
	my_names=$(names)
	while read -r pattern alias _; do
		case $pattern in '' | '#'*) continue ;; esac
		for name in $my_names; do
			case $name in $pattern)
				printf '%s\n' "$alias"
				return 0
				;;
			esac
		done
	done <"$table"
}

remember() {
	alias=$1
	pattern=${2:-$(hostname -f 2>/dev/null || hostname)}
	case $alias in '' | *[[:space:]/]*)
		echo "bad alias: '$alias'" >&2
		exit 64
		;;
	esac
	mkdir -p "$(dirname "$table")"
	if [ -f "$table" ]; then
		awk -v p="$pattern" '$1 != p' "$table" >"$table.tmp"
		mv "$table.tmp" "$table"
	fi
	printf '%s %s\n' "$pattern" "$alias" >>"$table"
	echo "saved: $pattern -> $alias (in $table)" >&2
}

case ${1:-} in
--remember)
	if [ $# -lt 2 ] || [ $# -gt 3 ]; then
		echo "usage: $0 --remember <alias> [pattern]" >&2
		exit 64
	fi
	shift
	remember "$@"
	exit 0
	;;
--whoami)
	echo "names: $(names | tr '\n' ' ')"
	echo "alias: ${CURSOR_SSH_HOST:-$(lookup)}"
	echo "table: $table"
	exit 0
	;;
esac

if [ $# -lt 1 ] || [ $# -gt 3 ]; then
	echo "usage: $0 <path> [line [column]]" >&2
	exit 64
fi

target=$1
if [ ! -e "$target" ]; then
	echo "no such file or directory: $target" >&2
	exit 1
fi
if [ -d "$target" ]; then
	abs=$(cd "$target" && pwd -P)
else
	abs=$(cd "$(dirname "$target")" && pwd -P)/$(basename "$target")
fi

suffix=
if [ $# -ge 2 ]; then
	suffix=":$2"
	if [ $# -ge 3 ]; then
		suffix="$suffix:$3"
	fi
elif [ ! -d "$target" ]; then
	# Cursor opens a remote link without :line as a folder, giving an empty window.
	suffix=":1"
fi

# Percent-encode characters that break URLs; leave / and common path characters alone.
encoded=$(printf '%s' "$abs" | LC_ALL=C awk '
	BEGIN { for (i = 0; i < 256; i++) ord[sprintf("%c", i)] = i }
	{
		out = ""
		for (i = 1; i <= length($0); i++) {
			c = substr($0, i, 1)
			if (c ~ /[A-Za-z0-9\/._~+=,@-]/) out = out c
			else out = out sprintf("%%%02X", ord[c])
		}
		printf "%s", out
	}')

host=${CURSOR_SSH_HOST:-$(lookup)}
if [ -z "$host" ]; then
	echo "unknown host: no SSH alias saved for this machine (names: $(names | tr '\n' ' ')) in $table" >&2
	echo "ask the user for the alias, or 'local' if Cursor runs here, then run: $0 --remember <alias> [pattern]" >&2
	exit 2
fi

if [ "$host" = local ]; then
	printf 'cursor://file%s%s\n' "$encoded" "$suffix"
else
	printf 'cursor://vscode-remote/ssh-remote+%s%s%s\n' "$host" "$encoded" "$suffix"
fi
