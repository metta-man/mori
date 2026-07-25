#!/usr/bin/env bash

mori_is_missing_simulator_runtime_failure() {
  local log_path="$1"

  if [ ! -f "$log_path" ]; then
    return 1
  fi

  if rg -qi -- \
    '(iOS|watchOS)[[:space:]]+[0-9]+([.][0-9]+)*([[:space:]]+Simulator)?[[:space:]]+(runtime[[:space:]]+)?(is[[:space:]]+not|must[[:space:]]+be)[[:space:]]+installed|missing[[:space:]]+(iOS|watchOS)[[:space:]]+simulator[[:space:]]+runtime|failed[[:space:]]+to[[:space:]]+locate[^[:cntrl:]]*(iOS|watchOS)[^[:cntrl:]]*runtime|no[[:space:]]+matching[^[:cntrl:]]*(iOS|watchOS)[^[:cntrl:]]*runtime' \
    "$log_path"; then
    return 0
  fi

  if rg -qi -- \
    '(Unable to find a destination matching|Ineligible destinations for the .* scheme|Found no destinations)' \
    "$log_path" &&
     rg -qi -- '(iOS Simulator|watchOS|simulator runtime)' "$log_path"; then
    return 0
  fi

  return 1
}
