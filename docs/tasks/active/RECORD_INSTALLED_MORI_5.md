# Record installed Mori 0.1.0 (5)

Status: source capture and verification complete; remote delivery is recorded in the local push receipt.
Owner: task recording the three installed October 6 versions.
Goal: commit the exact approved source already installed, preserving canonical dirty work and independent ongoing work.
Scope: the frozen installed-source file manifest plus this Task Card, installed-build manifest/README and scripts/build_installed.py. For Forma, also exclude generated Pods via the bounded .gitignore addition. Stage only actual changed owned paths.
Safety: no main push/merge, force push, archive upload, TestFlight action, backend deployment, credential/data inspection, or app reset. No new heavy builds/tests; the pace worker owns that slot.
Verification: exact source hashes, diff/secret checks, recorded already-completed validation, current CI trigger audit and remote branch hash.
Definition of done: the named independent branch contains this exact snapshot and reproducible metadata, remote SHA matches the local commit, and reusable signed artifacts remain local.
