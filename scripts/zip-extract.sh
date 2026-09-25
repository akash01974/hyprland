#!/usr/bin/env bash
#
# Zip extractor for quickshell pill launcher.
# Handles .zip extraction, icon/Desktop entry generation, and registry.
#
# Usage:
#   zip-extract.sh install <path-to.zip>
#   zip-extract.sh remove  <slug>
#   zip-extract.sh rename  <slug> <new name>
#
set -euo pipefail

data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
apps_dir="${HOME}/.local/bin/Zips"
desktop_dir="$data_home/applications"
icon_dir="$data_home/quickshell/zips"
registry="$data_home/quickshell/zips.json"

mkdir -p "$apps_dir" "$desktop_dir" "$icon_dir"
[ -f "$registry" ] || echo '{}' >"$registry"

_tmpdir=""
cleanup() { [ -n "$_tmpdir" ] && rm -rf "$_tmpdir"; }
trap cleanup EXIT

die() { echo "$1" >&2; exit 1; }

is_zip() {
	local f="$1"
	[ -f "$f" ] || return 1
	case "$f" in
		*.zip | *.ZIP) ;;
		*) return 1 ;;
	esac
	local magic
	magic="$(head -c 4 "$f" | od -An -tx1 | tr -d ' \n')"
	[ "$magic" = "504b0304" ]
}

slugify() {
	local s
	s="$(strip_tokens "$1")"
	s="$(printf '%s' "$s" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
	[ -n "$s" ] || s="app"
	printf '%s' "$s"
}

strip_tokens() {
	local base="$1" out="" tok low
	base="${base%.zip}"
	base="${base%.ZIP}"
	local IFS='._-'
	for tok in $base; do
		[ -n "$tok" ] || continue
		low="$(printf '%s' "$tok" | tr '[:upper:]' '[:lower:]')"
		case "$low" in
			x86_64 | amd64 | x86 | i386 | i686 | aarch64 | arm64 | armhf | arm | linux | gnu | glibc | musl | static | portable) continue ;;
		esac
		printf '%s' "$tok" | grep -qE '^[vV]?[0-9]+([.][0-9]+)*$' && continue
		out="$out $tok"
	done
	printf '%s' "${out# }"
}

prettify() {
	local s
	s="$(strip_tokens "$1")"
	[ -n "$s" ] || s="${1%.zip}"
	s="${s%.ZIP}"
	printf '%s' "$s"
}

reg_set() {
	local slug="$1" name="$2" zip="$3" icon="$4" desktop="$5" appid="$6" tmp
	tmp="$(mktemp)"
	jq --arg s "$slug" --arg n "$name" --arg a "$zip" --arg i "$icon" --arg d "$desktop" --arg p "$appid" \
		'.[$s] = {name:$n, zipPath:$a, iconPath:$i, desktopPath:$d, appId:$p}' "$registry" >"$tmp"
	mv "$tmp" "$registry"
}

install_zip() {
	local src="$1"
	is_zip "$src" || die "not a zip: $src"

	local fname dest slug
	fname="$(basename "$src")"
	dest="$apps_dir/$fname"
	slug="$(slugify "$fname")"

	_tmpdir="$(mktemp -d)"
	local tmp="$_tmpdir"

	local tmpcopy="$tmp/$(basename "$src")"
	cp -f "$src" "$tmpcopy"

	if (cd "$tmp" && unzip -o "$tmpcopy" >/dev/null 2>&1); then
		local root="$tmp"
		local name="" iconname="" wmclass=""

		if [ -d "$tmp/squashfs-root" ]; then
			root="$tmp/squashfs-root"
		fi

		local df
		df="$(find "$root" -maxdepth 2 -name '*.desktop' | head -1)"
		if [ -n "$df" ]; then
			name="$(grep -m1 '^Name=' "$df" | cut -d= -f2- || true)"
			iconname="$(grep -m1 '^Icon=' "$df" | cut -d= -f2- || true)"
			wmclass="$(grep -m1 '^StartupWMClass=' "$df" | cut -d= -f2- || true)"
		fi
		[ -n "$name" ] || name="$(prettify "$fname")"
	else
		name="$(prettify "$fname")"
	fi

	[ "$src" -ef "$dest" ] || cp -f "$tmpcopy" "$dest"
	chmod +x "$dest" 2>/dev/null || true

	local appid="${wmclass:-${name:-$slug}}"
	local action prevPath prevId
	prevPath="$(jq -r --arg s "$slug" '.[$s].zipPath // empty' "$registry")"
	if [ -z "$prevPath" ]; then
		action="new"
	elif [ "$prevPath" -ef "$dest" ] 2>/dev/null || [ "$prevPath" = "$dest" ]; then
		action="reinstalled"
	else
		prevId="$(jq -r --arg s "$slug" '.[$s].appId // empty' "$registry")"
		if [ -z "$prevId" ] || [ "$prevId" = "$appid" ]; then
			action="updated"
			rm -f "$prevPath"
		else
			local n=2
			while [ -n "$(jq -r --arg s "$slug-$n" '.[$s].zipPath // empty' "$registry")" ]; do
				n=$((n + 1))
			done
			slug="$slug-$n"
			action="new"
		fi
	fi

	[ -n "$iconname" ] && install_icon "$tmpcopy" "$iconname" "$slug"

	local icon_path="$icon_dir/$slug.png"
	[ -f "$icon_path" ] || { icon_path="$icon_dir/$slug.svg"; [ -f "$icon_path" ] || icon_path=""; }

	local df_out="$desktop_dir/quickshell-$slug.desktop"
	{
		echo "[Desktop Entry]"
		echo "Type=Application"
		echo "Name=$name"
		echo "Exec=$dest %U"
		[ -n "$icon_path" ] && echo "Icon=$icon_path"
		echo "Terminal=false"
		echo "X-Quickshell-Zip=true"
	} >"$df_out"

	reg_set "$slug" "$name" "$dest" "$icon_path" "$df_out" "$appid"
	update-desktop-database "$desktop_dir" 2>/dev/null || true

	printf '%s\t%s\t%s\n' "$slug" "$name" "$action"
}

install_icon() {
	local zipfile="$1" iconname="$2" slug="$3" found="" sz

	rm -f "$icon_dir/$slug.png" "$icon_dir/$slug.svg"

	case "$iconname" in */*) iconname="${iconname##*/}" ;; esac
	case "$iconname" in *.png | *.svg | *.xpm) iconname="${iconname%.*}" ;; esac

	if [ -n "$iconname" ]; then
		found="$(find "$zipfile" -path '*/scalable/*' -name "$iconname.svg" 2>/dev/null | head -1)"
		if [ -z "$found" ]; then
			for sz in 1024x1024 512x512 256x256 128x128 96x96 64x64 48x48; do
				found="$(find "$zipfile" -path "*/$sz/*" -name "$iconname.png" 2>/dev/null | head -1)"
				[ -n "$found" ] && break
			done
		fi
		[ -z "$found" ] && found="$(find "$zipfile" -name "$iconname.svg" -o -name "$iconname.png" 2>/dev/null | head -1)"
	fi

	if [ -z "$found" ] && [ -e "$zipfile/.DirIcon" ]; then
		found="$(readlink -f "$zipfile/.DirIcon" 2>/dev/null || true)"
		[ -n "$found" ] && [ -f "$found" ] || found="$zipfile/.DirIcon"
	fi
	[ -z "$found" ] && found="$(find "$zipfile" -maxdepth 1 \( -name '*.png' -o -name '*.svg' \) 2>/dev/null | head -1)"

	[ -n "$found" ] && [ -f "$found" ] || return 0
	local ext="png"
	case "$found" in *.svg) ext="svg" ;; esac
	cp -f "$found" "$icon_dir/$slug.$ext"
}

remove_zip() {
	local slug="$1"
	[ -n "$slug" ] || die "no slug"
	local zip icon desktop
	zip="$(jq -r --arg s "$slug" '.[$s].zipPath // empty' "$registry")"
	icon="$(jq -r --arg s "$slug" '.[$s].iconPath // empty' "$registry")"
	desktop="$(jq -r --arg s "$slug" '.[$s].desktopPath // empty' "$registry")"
	[ -n "$zip" ] && rm -f "$zip"
	[ -n "$icon" ] && rm -f "$icon"
	[ -n "$desktop" ] && rm -f "$desktop"
	local tmp
	tmp="$(mktemp)"
	jq --arg s "$slug" 'del(.[$s])' "$registry" >"$tmp" && mv "$tmp" "$registry"
	update-desktop-database "$desktop_dir" 2>/dev/null || true
}

rename_zip() {
	local slug="$1" newname="$2" desktop tmp
	[ -n "$slug" ] && [ -n "$newname" ] || die "usage: rename <slug> <name>"
	desktop="$(jq -r --arg s "$slug" '.[$s].desktopPath // empty' "$registry")"
	[ -n "$desktop" ] && [ -f "$desktop" ] || die "unknown slug: $slug"
	tmp="$(mktemp)"
	newname="$newname" awk 'BEGIN { n = ENVIRON["newname"] } !done && /^Name=/ { print "Name=" n; done = 1; next } { print }' "$desktop" >"$tmp" && mv "$tmp" "$desktop"
	tmp="$(mktemp)"
	jq --arg s "$slug" --arg n "$newname" '.[$s].name = $n' "$registry" >"$tmp" && mv "$tmp" "$registry"
	update-desktop-database "$desktop_dir" 2>/dev/null || true
}

[ "${BASH_SOURCE[0]}" = "${0}" ] || return 0

cmd="${1:-}"
case "$cmd" in
	install) install_zip "${2:-}" ;;
	remove) remove_zip "${2:-}" ;;
	rename) rename_zip "${2:-}" "${3:-}" ;;
	*) die "usage: zip-extract.sh install|remove|rename ..." ;;
esac