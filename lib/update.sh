REPO="fccview/locsmith"
INSTALL_DIR="$HOME/.locsmith"

run_update() {
  log_info "Checking for updates..."

  local latest_tag
  latest_tag="$(curl -fsSL -o /dev/null -w '%{url_effective}' "https://github.com/$REPO/releases/latest" | sed 's|.*/||')"
  if [[ -z "$latest_tag" ]]; then
    printf "Failed to resolve latest version.\n" >&2
    return 1
  fi

  log_info "Latest version: $latest_tag"

  local tarball_url="https://github.com/$REPO/releases/download/${latest_tag}/locsmith_${latest_tag}.tar.gz"
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN

  if ! curl -fsSL "$tarball_url" -o "$tmp_dir/release.tar.gz"; then
    printf "Failed to download update.\n" >&2
    return 1
  fi

  tar -xzf "$tmp_dir/release.tar.gz" -C "$tmp_dir"

  local extracted
  extracted="$(find "$tmp_dir" -maxdepth 1 -mindepth 1 -type d | head -n 1)"
  [[ -z "$extracted" ]] && extracted="$tmp_dir"

  cp "$extracted/index.sh" "$INSTALL_DIR/index.sh"
  rm -rf "$INSTALL_DIR/lib"
  cp -r "$extracted/lib" "$INSTALL_DIR/lib"

  chmod +x "$INSTALL_DIR/index.sh"
  log_info "Updated successfully."
}
