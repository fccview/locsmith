list_ignores() {
  local -a names=()
  if [[ -d "$ignore_dir" ]]; then
    for f in "$ignore_dir"/*.ignore; do
      [[ -e "$f" ]] && names+=("$(basename "${f%.ignore}")")
    done
  fi
  if (( ${#names[@]} == 0 )); then
    printf "No ignore profiles available.\nCreate .ignore files in %s to add them.\n" "$ignore_dir"
  else
    printf "Available ignore profiles:\n"
    for name in "${names[@]}"; do
      printf "  - %s\n" "$name"
    done
  fi
}

normalize_ignore() {
  local raw="${1,,}"
  raw="${raw//[ -]/_}"
  case "$raw" in
    js|javascript|ts|typescript) printf "node" ;;
    py) printf "python" ;;
    golang) printf "go" ;;
    default|"") printf "generic" ;;
    *) printf "%s" "$raw" ;;
  esac
}

read_ignore_file_lines() {
  [[ ! -f "$1" ]] && return 0
  sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$1" | grep -vE '^(#|$)' || true
}

build_find_prune_args() {
  local -a args=()
  for p in "$@"; do
    [[ -z "$p" ]] && continue
    (( ${#args[@]} > 0 )) && args+=("-o")
    if [[ "$p" == */* ]]; then
      args+=("-path" "*/$p")
    else
      args+=("-name" "$p")
    fi
  done
  (( ${#args[@]} > 0 )) && printf "%s\n" "${args[@]}" || true
}

choose_ignore_interactive() {
  local -a names=()
  if [[ -d "$ignore_dir" ]]; then
    for f in "$ignore_dir"/*.ignore; do
      [[ -e "$f" ]] && names+=("$(basename "${f%.ignore}")")
    done
  fi

  if (( ${#names[@]} == 0 )); then
    return 1
  fi

  log_info "What type of project is this?" >&2
  for i in "${!names[@]}"; do
    printf "  %s) %s\n" "$((i+1))" "${names[$i]}" >&2
  done

  local ans
  read -r -p "Choose [1]: " ans
  ans="${ans:-1}"

  if [[ "$ans" =~ ^[0-9]+$ ]] && (( ans >= 1 && ans <= ${#names[@]} )); then
    printf "%s" "${names[$((ans-1))]}"
    return 0
  fi

  printf "%s" "$ans"
}
