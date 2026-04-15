#!/usr/bin/env bash

set -euo pipefail

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

color_info=$'\033[1;34m'
color_warn=$'\033[1;33m'
color_reset=$'\033[0m'

log_info() { printf "%s[INFO]%s %s\n" "$color_info" "$color_reset" "$1"; }
log_warn() { printf "%s[*]%s %s\n" "$color_warn" "$color_reset" "$1"; }

base_dir="$HOME/.locsmith"
ignore_dir="$base_dir/ignore"
lib_dir="$base_dir/lib"

if [[ ! -d "$lib_dir" ]]; then
  lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"
fi

source "$lib_dir/ignore.sh"
source "$lib_dir/report.sh"
source "$lib_dir/scan.sh"
source "$lib_dir/update.sh"

usage() {
  cat <<'EOF'
Usage: locsmith [--ignore <name>] [--ignore-file <path>] [--dir <path>]
       locsmith --help [--ignores]
       locsmith --update
EOF
}

ignore_name=""
target_dir="."
show_ignores=0
show_help=0
declare -a ignore_files=() ignore_patterns=() ignore_args=()

while (( $# > 0 )); do
  case "$1" in
    -h|--help) show_help=1; shift ;;
    --ignores) show_ignores=1; shift ;;
    --ignore) ignore_name="${2:-}"; shift 2 ;;
    --dir) target_dir="${2:-}"; shift 2 ;;
    --ignore-file) [[ -n "${2:-}" ]] && ignore_files+=("$2"); shift 2 ;;
    --update) run_update; exit 0 ;;
    *) printf "Unknown arg: %s\n\n" "$1"; usage; exit 2 ;;
  esac
done

if (( show_help == 1 )); then
  if (( show_ignores == 1 )); then
    list_ignores
  else
    usage
  fi
  exit 0
fi

if (( show_ignores == 1 )); then
  list_ignores
  exit 0
fi

if [[ -z "$ignore_name" ]]; then
  if (( ${#ignore_files[@]} > 0 )); then
    ignore_name=""
  elif [[ -t 0 ]] && ignore_name="$(choose_ignore_interactive)"; then
    :
  else
    ignore_name=""
  fi
fi

ignore_name="$(normalize_ignore "$ignore_name")"

[[ -n "$ignore_name" && -f "$ignore_dir/$ignore_name.ignore" ]] && \
  while IFS= read -r line; do ignore_patterns+=("$line"); done < <(read_ignore_file_lines "$ignore_dir/$ignore_name.ignore")

for f in "${ignore_files[@]}"; do
  while IFS= read -r line; do ignore_patterns+=("$line"); done < <(read_ignore_file_lines "$f")
done

while IFS= read -r token; do
  [[ -n "$token" ]] && ignore_args+=("$token")
done < <(build_find_prune_args "${ignore_patterns[@]}")

log_info "Starting inspection${ignore_name:+ (ignore: $ignore_name)}..."
scan "$target_dir" "${ignore_args[@]}"
