#!/usr/bin/env python3
"""Verify the installed source/configuration manifest; build only on request."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("manifest", type=Path)
parser.add_argument("--verify-only", action="store_true")
parser.add_argument("--derived-data", type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
manifest = json.loads(args.manifest.read_text())
changed = []
for relative, expected in manifest["source_files_sha256"].items():
    path = root / relative
    if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != expected:
        changed.append(relative)
if changed:
    raise SystemExit("Installed source differs: " + ", ".join(changed))
print(f"Verified {len(manifest['source_files_sha256'])} exact installed-source files.")
if args.verify_only:
    raise SystemExit(0)
if args.derived_data is None or not str(args.derived_data).startswith("/tmp/"):
    raise SystemExit("Pass an isolated --derived-data path below /tmp/.")
command = ["xcodebuild", *manifest["build_arguments"], "-derivedDataPath", str(args.derived_data), "build"]
print("Building the recorded configuration; no archive/export/upload action.")
raise SystemExit(subprocess.run(command, cwd=root).returncode)
