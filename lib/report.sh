print_top_files() {
  local found=0
  while read -r loc path; do
    (( loc < 400 )) && break
    if (( found == 0 )); then
      printf "Files above 400 lines of code:\n"
      found=1
    fi
    printf "  %6s lines  %s\n" "$loc" "$path"
  done < <(sort -nr "$tmp_file")
  (( found == 0 )) && printf "Congrats, none of the files within the project exceed 400 lines of code.\n"
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
