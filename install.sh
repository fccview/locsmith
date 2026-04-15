#!/usr/bin/env bash

set -euo pipefail

REPO="fccview/locsmith"

color_info=$'\033[1;34m'
color_ok=$'\033[1;32m'
color_reset=$'\033[0m'

log_info() { printf "%s[INFO]%s %s\n" "$color_info" "$color_reset" "$1"; }
log_ok() { printf "%s[OK]%s %s\n" "$color_ok" "$color_reset" "$1"; }

install_dir="$HOME/.locsmith"
bin_dir="$HOME/.local/bin"
remote=0

[[ "${1:-}" == "--remote" ]] && remote=1

_resolve_source() {
  if (( remote == 1 )); then
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "$tmp_dir"' EXIT

    log_info "Resolving latest version..."
    local latest_tag
    latest_tag="$(curl -fsSL -o /dev/null -w '%{url_effective}' "https://github.com/$REPO/releases/latest" | sed 's|.*/||')"
    if [[ -z "$latest_tag" ]]; then
      printf "Failed to resolve latest version.\n" >&2
      exit 1
    fi
    log_ok "Found version: $latest_tag"

    local tarball_url="https://github.com/$REPO/releases/download/${latest_tag}/locsmith_${latest_tag}.tar.gz"
    log_info "Downloading..."
    if ! curl -fsSL "$tarball_url" -o "$tmp_dir/release.tar.gz"; then
      printf "Failed to download release.\n" >&2
      exit 1
    fi

    tar -xzf "$tmp_dir/release.tar.gz" -C "$tmp_dir"
    source_dir="$(find "$tmp_dir" -maxdepth 1 -mindepth 1 -type d | head -n 1)"
  else
    source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  fi
}

_resolve_source

log_info "Installing to $install_dir..."
mkdir -p "$install_dir/ignore"
mkdir -p "$install_dir/lib"

cp "$source_dir/index.sh" "$install_dir/index.sh"
rm -rf "$install_dir/lib"
cp -r "$source_dir/lib" "$install_dir/lib"
chmod +x "$install_dir/index.sh"
log_ok "Copied files to $install_dir"

mkdir -p "$bin_dir"
ln -sf "$install_dir/index.sh" "$bin_dir/locsmith"
log_ok "Linked locsmith to $bin_dir"

if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
  log_info "$bin_dir is not in your PATH."
  printf "  Add this to your shell profile:\n"
  printf "    export PATH=\"%s:\$PATH\"\n" "$bin_dir"
fi

printf "\nDone! Run 'locsmith' to get started.\n"
printf "Add ignore profiles to %s/ignore/ (e.g., node.ignore)\n" "$install_dir"
