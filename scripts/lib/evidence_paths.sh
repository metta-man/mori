#!/usr/bin/env bash

# Resolve an evidence path without changing the historical on-disk archive layout.
# An explicit path always wins. Otherwise MORI_EVIDENCE_ROOT is treated as a
# prefix for the legacy output/, outputs/, or .codex-build/ relative path.
mori_evidence_path() {
  local relative_path="$1"
  local explicit_path="${2:-}"
  local evidence_root="${MORI_EVIDENCE_ROOT:-}"

  if [ -n "$explicit_path" ]; then
    printf '%s\n' "$explicit_path"
    return 0
  fi

  if [ -n "$evidence_root" ]; then
    printf '%s/%s\n' "${evidence_root%/}" "${relative_path#/}"
    return 0
  fi

  printf '%s\n' "$relative_path"
}
