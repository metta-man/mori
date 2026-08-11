#!/usr/bin/env bash

mori_xcodegen_version() {
  local xcodegen_command="${1:-xcodegen}"
  "$xcodegen_command" --version 2>/dev/null |
    sed -E 's/^[^0-9]*([0-9]+([.][0-9]+){2}).*$/\1/' |
    head -n 1
}

mori_require_xcodegen_version() {
  local required_version="$1"
  local xcodegen_command="${2:-xcodegen}"
  local actual_version

  actual_version="$(mori_xcodegen_version "$xcodegen_command")"
  if [ "$actual_version" != "$required_version" ]; then
    printf '::error::XcodeGen %s is required for deterministic Mori.xcodeproj generation; found %s.\n' \
      "$required_version" "${actual_version:-unknown}"
    printf 'Install/pin the required XcodeGen release before running project generation.\n'
    return 1
  fi

  printf 'OK: XcodeGen %s matches the repository generator pin.\n' "$actual_version"
}
