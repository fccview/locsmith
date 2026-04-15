print_top_files() {
  printf "Top 10 largest files:\n"
  sort -nr "$tmp_file" | head -n 10 | while read -r loc path; do
    printf "  %6s lines  %s\n" "$loc" "$path"
  done
}

print_extension_breakdown() {
  printf "\nLines by extension:\n"
  declare -A ext_lines ext_files
  while read -r loc path; do
    local ext="${path##*.}"
    [[ "$path" == "$ext" || "$path" == *"/" ]] && ext="(none)"
    [[ "$path" != *.* ]] && ext="(none)"
    ext_lines["$ext"]=$(( ${ext_lines["$ext"]:-0} + loc ))
    ext_files["$ext"]=$(( ${ext_files["$ext"]:-0} + 1 ))
  done < "$tmp_file"

  for ext in "${!ext_lines[@]}"; do
    printf "%s %s %s\n" "${ext_lines[$ext]}" "${ext_files[$ext]}" "$ext"
  done | sort -nr | head -n 15 | while read -r lines files ext; do
    printf "  .%-12s %6s lines across %s files\n" "$ext" "$lines" "$files"
  done
}
