#!/usr/bin/env bash
#
# EXE runner for quickshell - runs Windows .exe files with Wine.
#
# Usage:
#   exe-runner.sh run <path-to.exe> [arguments...]
#
# Examples:
#   exe-runner.sh run myapp.exe
#   exe-runner.sh run "/path/to/My App.exe"
#   exe-runner.sh run myapp.exe --some-argument
#
# Custom Wine prefix:
#   WINEPREFIX="$HOME/.wine-other" exe-runner.sh run myapp.exe
#
set -euo pipefail

SCRIPT_NAME="${0##*/}"

# Log file for diagnostics (kept quiet on success, verbose on failure)
LOG_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/exe-runner.log"

die() {
    printf 'Error: %s\n' "$*" >&2
    printf '[exe-runner] %s\n' "$*" >>"$LOG_FILE" 2>/dev/null || true
    exit 1
}

usage() {
    cat <<EOF
Usage:
  $SCRIPT_NAME run <path-to.exe> [arguments...]

Examples:
  $SCRIPT_NAME run myapp.exe
  $SCRIPT_NAME run "/path/to/My App.exe"
  $SCRIPT_NAME run myapp.exe --some-argument

Custom Wine prefix:
  WINEPREFIX="\$HOME/.wine-other" $SCRIPT_NAME run myapp.exe
EOF
}

# Check whether a file is a valid Windows PE executable.
# Uses the MZ DOS signature (first 2 bytes = 4d5a) which is a lightweight
# check that confirms the file has a PE/EXE structure. Wine itself will
# ultimately determine whether it can actually run the binary.
is_exe() {
    local file="$1"

    [[ -f "$file" ]] || return 1
    [[ -r "$file" ]] || return 1

    # Accept .exe regardless of capitalization.
    local ext="${file##*.}"
    [[ "$ext" =~ ^[Ee][Xx][Ee]$ ]] || return 1

    # Read first 2 bytes as hex; PE executables begin with "MZ" (4d5a).
    local magic
    magic="$(od -An -tx1 -N2 "$file" 2>/dev/null | tr -d '[:space:]')"

    [[ "$magic" == "4d5a" ]]
}

# Resolve a path to an absolute path.
# If already absolute, return as-is. Otherwise prepend $PWD.
absolute_path() {
    local path="$1"

    if [[ "$path" = /* ]]; then
        printf '%s\n' "$path"
    else
        printf '%s/%s\n' "$PWD" "$path"
    fi
}

# Validate and set up the Wine prefix.
# Honors an existing WINEPREFIX, defaulting to $HOME/.wine.
# Expands ~-style paths if supplied.
# Prints the resolved prefix to stdout.
wine_prefix() {
    local prefix="${WINEPREFIX:-$HOME/.wine}"

    # Expand leading tilde.
    if [[ "$prefix" == "~" ]]; then
        printf '%s\n' "$HOME"
    elif [[ "$prefix" == "~/"* ]]; then
        printf '%s\n' "$HOME/${prefix#~/}"
    else
        printf '%s\n' "$prefix"
    fi
}

# Launch a Windows .exe file via Wine.
# Handles path resolution, Wine prefix configuration, and environment
# propagation from the calling session. Errors are logged to $LOG_FILE
# so they persist without flooding the terminal on success.
run_exe() {
    local src="${1:-}"

    [[ -n "$src" ]] || die "missing .exe path"

    # Wine must be available before doing anything else.
    if ! command -v wine >/dev/null 2>&1; then
        die "Wine is not installed or not available in PATH"
    fi

    # Resolve to absolute path (handles spaces, .., relative paths).
    src="$(absolute_path "$src")"

    # Validate the executable format.
    is_exe "$src" \
        || die "not a valid Windows .exe: $src"

    # Use the user's existing WINEPREFIX or Wine's default.
    local wprefix
    wprefix="$(wine_prefix)"

    export WINEPREFIX="$wprefix"

    # Propagate the graphical session environment from the calling process.
    # Do not unconditionally override; preserve what the user already has
    # in their session environment while ensuring Wine has a display target.
    if [[ -z "${WAYLAND_DISPLAY:-}" && -n "${DISPLAY:-}" ]]; then
        export WAYLAND_DISPLAY="${DISPLAY}"
    fi
    # If on pure Wayland, ensure WAYLAND_DISPLAY is set.
    if [[ -z "${WAYLAND_DISPLAY:-}" ]] && [[ -z "${DISPLAY:-}" ]]; then
        # Keep whatever the session already set; Wine will use its defaults.
        :
    fi

    # Controlled Wine debugging:
    # - suppress internal PE/format debug that clutters output
    # - let real errors surface; WINEDEBUG is only set if not already
    if [[ -z "${WINEDEBUG:-}" ]]; then
        export WINEDEBUG="+fixme+err"
    else
        # User supplied WINEDEBUG; keep their choice but trim excessive noise
        export WINEDEBUG="${WINEDEBUG%+fixme*}"
        export WINEDEBUG="${WINEDEBUG%+err*}"
    fi

    # Remove the executable path from the argument list; pass the rest
    # unchanged to Wine.
    shift

    # Log the launch intent (quiet on success, detailed on failure).
    printf '[exe-runner] Launching: %s\\n' "$src" >&2
    printf '[exe-runner] Wine prefix: %s\\n' "$WINEPREFIX" >&2
    printf '[exe-runner] Executable: %s\\n' "$src" >&2

    # Execute Wine with the remaining arguments.
    # The exit code is passed through directly to the caller.
    # stdout/stderr from Wine are forwarded to the caller so errors are visible.
    wine "$src" "$@" >>"$LOG_FILE" 2>&1
    local exit_code=$?

    # On failure, ensure we have some diagnostic output in the log.
    if [[ $exit_code -ne 0 ]]; then
        printf '[exe-runner] Wine exited with code %d\\n' "$exit_code" >>"$LOG_FILE" 2>/dev/null || true
    fi

    return $exit_code
}

main() {
    local cmd="${1:-}"

    case "$cmd" in
        run)
            [[ $# -ge 2 ]] \
                || die "missing .exe path"

            shift
            run_exe "$@"
            ;;

        -h|--help|help)
            usage
            ;;

        "")
            usage >&2
            exit 1
            ;;

        *)
            die "unknown command: $cmd"
            ;;
    esac
}

main "$@"