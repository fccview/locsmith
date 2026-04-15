scan() {
  local scan_dir="$1"; shift
  local -a find_cmd=(find "$scan_dir" -type f -print0)
  (( $# > 0 )) && find_cmd=(find "$scan_dir" \( "$@" \) -prune -o -type f -print0)

  local total_loc=0 file_count=0

  while IFS= read -r -d '' file; do
    printf "\r\033[K%s[*]%s Scanning: %.80s" "$color_warn" "$color_reset" "$file"

    [[ "$(file -b --mime-encoding "$file" 2>/dev/null || true)" == "binary" ]] && continue

    local loc
    loc="$(wc -l < "$file" 2>/dev/null || printf "0")"
    loc="${loc// /}"

    if [[ "$loc" =~ ^[0-9]+$ ]] && (( loc > 0 )); then
      (( total_loc += loc ))
      (( file_count += 1 ))
      printf "%s %s\n" "$loc" "$file" >> "$tmp_file"
    fi
  done < <("${find_cmd[@]}")

  printf "\r\033[K"
  log_info "Inspection complete!"
  printf "\n"

  if (( file_count > 0 )); then
    printf "Total lines of code: %s\n" "$total_loc"
    printf "Total files: %s\n" "$file_count"
    printf "Average lines per file: %s\n" "$(((total_loc + (file_count / 2)) / file_count))"
    print_extension_breakdown
    printf "\n"
    print_top_files
  else
    printf "No text files found.\n"
  fi
}
