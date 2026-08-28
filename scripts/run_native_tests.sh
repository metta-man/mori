#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
repo_root="$(git -C "$script_dir/.." rev-parse --show-toplevel 2>/dev/null || true)"

if [ -z "$repo_root" ] || [ "$repo_root" != "$(CDPATH= cd -- "$script_dir/.." && pwd -P)" ]; then
  printf '::error::run_native_tests.sh must run from the Mori repository.\n'
  exit 2
fi

cd "$repo_root"

for command_name in python3 tee xcodebuild xcrun; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf '::error::Required command not found: %s\n' "$command_name"
    exit 1
  fi
done

temporary_paths=("")
created_simulator=""

cleanup() {
  local path

  if [ -n "$created_simulator" ]; then
    xcrun simctl shutdown "$created_simulator" >/dev/null 2>&1 || true
    xcrun simctl delete "$created_simulator" >/dev/null 2>&1 || true
  fi

  for path in "${temporary_paths[@]}"; do
    if [ -n "$path" ] && [ -d "$path" ]; then
      rm -rf -- "$path"
    fi
  done
}
trap cleanup EXIT

if [ -n "${MORI_SIM_DESTINATION:-}" ]; then
  sim_destination="$MORI_SIM_DESTINATION"
  printf 'Using requested simulator destination: %s\n' "$sim_destination"
else
  simulator_selection="$(python3 <<'PY'
import json
import re
import subprocess


def version_tuple(value: str) -> tuple[int, ...]:
    return tuple(int(part) for part in re.findall(r"\d+", value))


payload = json.loads(
    subprocess.check_output(["xcrun", "simctl", "list", "runtimes", "-j"], text=True)
)
sdk_version = subprocess.check_output(
    ["xcrun", "--sdk", "iphonesimulator", "--show-sdk-version"], text=True
).strip()
runtimes = [
    runtime
    for runtime in payload.get("runtimes", [])
    if runtime.get("isAvailable")
    and runtime.get("identifier", "").startswith("com.apple.CoreSimulator.SimRuntime.iOS-")
]
if not runtimes:
    raise SystemExit("No available iOS Simulator runtime is installed.")

matching_runtimes = [runtime for runtime in runtimes if runtime.get("version") == sdk_version]
if matching_runtimes:
    runtime = matching_runtimes[0]
else:
    compatible_runtimes = [
        runtime
        for runtime in runtimes
        if version_tuple(runtime.get("version", "0")) <= version_tuple(sdk_version)
    ]
    if not compatible_runtimes:
        raise SystemExit(
            f"No installed iOS Simulator runtime is compatible with SDK {sdk_version}."
        )
    runtime = max(compatible_runtimes, key=lambda item: version_tuple(item.get("version", "0")))
supported_devices = [
    device
    for device in runtime.get("supportedDeviceTypes", [])
    if device.get("productFamily") == "iPhone"
]
if not supported_devices:
    raise SystemExit(f"No supported iPhone device type found for {runtime['identifier']}.")

pro_devices = []
for device in supported_devices:
    match = re.fullmatch(r"iPhone (\d+) Pro", device.get("name", ""))
    if match:
        pro_devices.append((int(match.group(1)), device))

if pro_devices:
    device = max(pro_devices, key=lambda item: item[0])[1]
else:
    device = sorted(supported_devices, key=lambda item: item.get("name", ""))[0]

print(runtime["identifier"], device["identifier"], device["name"], sep="\t")
PY
)"

  IFS=$'\t' read -r runtime_identifier device_type_identifier device_name <<< "$simulator_selection"
  if [ -z "$runtime_identifier" ] || [ -z "$device_type_identifier" ]; then
    printf '::error::Unable to select a deterministic iOS Simulator destination.\n'
    exit 1
  fi

  simulator_name="Mori-Native-Tests-${GITHUB_RUN_ID:-local}-${GITHUB_RUN_ATTEMPT:-1}-$$"
  created_simulator="$(
    xcrun simctl create "$simulator_name" "$device_type_identifier" "$runtime_identifier"
  )"
  sim_destination="platform=iOS Simulator,id=$created_simulator"

  printf 'Created %s (%s) using %s.\n' "$device_name" "$created_simulator" "$runtime_identifier"
  xcrun simctl boot "$created_simulator"
  xcrun simctl bootstatus "$created_simulator" -b
fi

if [ -n "${MORI_DERIVED_DATA_PATH:-}" ]; then
  derived_data_path="$MORI_DERIVED_DATA_PATH"
  mkdir -p "$derived_data_path"
else
  derived_data_temp="$(mktemp -d "${TMPDIR:-/tmp}/mori-native-tests-derived-data.XXXXXX")"
  temporary_paths+=("$derived_data_temp")
  derived_data_path="$derived_data_temp/DerivedData"
fi

if [ -n "${MORI_TEST_RESULTS_PATH:-}" ]; then
  result_bundle_path="$MORI_TEST_RESULTS_PATH"
else
  results_temp="$(mktemp -d "${TMPDIR:-/tmp}/mori-native-test-results.XXXXXX")"
  temporary_paths+=("$results_temp")
  result_bundle_path="$results_temp/MoriTests.xcresult"
fi

if [ -e "$result_bundle_path" ]; then
  printf '::error::Native test result bundle already exists: %s\n' "$result_bundle_path"
  exit 2
fi
mkdir -p "$(dirname -- "$result_bundle_path")"

if [ -n "${MORI_NATIVE_TEST_LOG:-}" ]; then
  native_test_log="$MORI_NATIVE_TEST_LOG"
else
  native_test_log="$(dirname -- "$result_bundle_path")/MoriTests.log"
fi
mkdir -p "$(dirname -- "$native_test_log")"

printf 'Running the full Mori scheme on %s.\n' "$sim_destination"
set +e
NSUnbufferedIO=YES xcodebuild \
  -project Mori.xcodeproj \
  -scheme Mori \
  -configuration Debug \
  -destination "$sim_destination" \
  -derivedDataPath "$derived_data_path" \
  -parallel-testing-enabled NO \
  -maximum-concurrent-test-simulator-destinations 1 \
  -resultBundlePath "$result_bundle_path" \
  -quiet \
  test 2>&1 | tee "$native_test_log"
native_test_status=${PIPESTATUS[0]}
set -e

if [ -d "$result_bundle_path" ]; then
  printf '\nNative test result summary:\n'
  xcrun xcresulttool get test-results summary \
    --path "$result_bundle_path" 2>/dev/null || true
fi

if [ "$native_test_status" -ne 0 ]; then
  printf '\n::error::The full Mori native test scheme failed. See %s and %s.\n' \
    "$native_test_log" "$result_bundle_path"
  exit "$native_test_status"
fi

printf '\nFull Mori native test scheme passed.\n'
