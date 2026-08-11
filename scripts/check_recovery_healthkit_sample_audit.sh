#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

source scripts/lib/evidence_paths.sh
audit_dir="$(mori_evidence_path "output/healthkit-audit/recovery-healthkit-samples-2026-06-26" "${1:-}")"
export MORI_AUDIT_DIR="$audit_dir"

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/mori-recovery-healthkit-probe.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

probe_binary="$tmp_dir/recovery-healthkit-probe"
probe_output="$tmp_dir/probe-output.txt"

xcrun swiftc \
  -parse-as-library \
  -o "$probe_binary" \
  scripts/probe_recovery_healthkit_samples.swift \
  Services/MoriRecoveryHealthSampleStore.swift \
  Services/MoriRecoveryHealthService.swift \
  Services/MoriRecoveryHealthAnalyzers.swift \
  Services/MoriRecoveryScoring.swift \
  Services/MoriRecoverySignalBuilder.swift \
  Services/MoriRecoveryModels.swift

"$probe_binary" > "$probe_output"

ruby - "$probe_output" <<'RUBY'
probe_output_path = ARGV.fetch(0)
audit_path = File.join(ENV.fetch("MORI_AUDIT_DIR"), "AUDIT.md")
problems = []

def require_file(path, problems)
  problems << "Missing required file: #{path}" unless File.file?(path)
end

def require_include(path, phrases, problems)
  require_file(path, problems)
  return unless File.file?(path)

  body = File.read(path, encoding: "UTF-8", invalid: :replace, undef: :replace)
  phrases.each do |phrase|
    problems << "#{path} missing phrase #{phrase.inspect}" unless body.include?(phrase)
  end
end

require_include(probe_output_path, [
  "OK: Recovery HealthKit sample probe produced ready snapshot",
  "score=",
  "state=openReady",
  "signals=hrv,resting-heart-rate,sleep,respiratory-rate,temperature",
  "sleep=",
  "trainingMinutes="
], problems)

require_include("Services/MoriRecoveryHealthSampleStore.swift", [
  "protocol MoriRecoveryHealthSampleServing",
  "func requestAuthorization(readTypes: Set<HKObjectType>) async throws",
  "func quantitySamples(",
  "func categorySamples(",
  "func workouts(start: Date, end: Date) async throws -> [MoriRecoveryWorkoutSample]",
  "let samples: [HKWorkout]",
  "workout.statistics(for: quantityType)?.sumQuantity()",
  "final class MoriRecoveryHealthSampleStore: MoriRecoveryHealthSampleServing"
], problems)

require_include("Services/MoriRecoveryHealthService.swift", [
  "private let sampleStore: MoriRecoveryHealthSampleServing",
  "private let healthDataAvailable: () -> Bool",
  "private let nowProvider: () -> Date",
  "sampleStore: MoriRecoveryHealthSampleServing = MoriRecoveryHealthSampleStore()",
  "healthDataAvailable: @escaping () -> Bool = { HKHealthStore.isHealthDataAvailable() }",
  "nowProvider: @escaping () -> Date = Date.init",
  "guard healthDataAvailable() else",
  "let now = nowProvider()"
], problems)

require_include("scripts/probe_recovery_healthkit_samples.swift", [
  "HKQuantitySample",
  "HKCategorySample",
  "HKObjectType.workoutType()",
  "MoriRecoveryWorkoutSample",
  "ProbeRecoveryHealthSampleStore: MoriRecoveryHealthSampleServing",
  "MoriRecoveryHealthService(",
  "healthDataAvailable: { true }",
  "nowProvider: { now }",
  "service.snapshot(requestAuthorization: true)",
  "snapshot.status == .ready",
  "snapshot.state == .openReady",
  "hrv",
  "resting-heart-rate",
  "sleep",
  "respiratory-rate",
  "temperature"
], problems)

require_include(audit_path, [
  "Recovery HealthKit Sample Service Audit - 2026-06-26",
  "scripts/check_recovery_healthkit_sample_audit.sh",
  "scripts/probe_recovery_healthkit_samples.swift",
  "HKQuantitySample",
  "HKCategorySample",
  "`HKWorkout` query boundary",
  "MoriRecoveryWorkoutSample",
  "statistics(for:)",
  "MoriRecoveryHealthService.snapshot(requestAuthorization:)",
  "ready snapshot",
  "HRV",
  "resting-heart-rate",
  "sleep",
  "respiratory-rate",
  "temperature",
  "does not prove live Apple Health database samples",
  "does not prove Apple Health authorization sheets"
], problems)

if problems.empty?
  puts "Recovery HealthKit sample audit compiles and runs HealthKit-shaped sample coverage through MoriRecoveryHealthService."
else
  abort problems.join("\n")
end
RUBY
