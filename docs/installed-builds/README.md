# Installed Mori 0.1.0 (5) source record

This branch captures the exact source used for the installed development-signed app. Version metadata was supplied by build overrides; the default project version was not bumped by this commit.

Verify without building:

```sh
python3 scripts/build_installed.py docs/installed-builds/mori-0.1.0-5.json --verify-only
```

Reproduce the recorded source/configuration when a new build is actually needed:

```sh
python3 scripts/build_installed.py docs/installed-builds/mori-0.1.0-5.json --derived-data /tmp/mori-installed-5-build
```

Xcode resolves the pinned PostHog dependency from the checked-in project/package resolution. No signing credentials are committed. The source manifest also records exact dependency inputs and signed artifact/entitlement hashes. Binary reproducibility is not promised across SDKs, paths, timestamps or signing operations.

Approved Before Feed copy validation retained; exact approved patch reverse-check passed and original breathing-state/clock prefix retained. Signed entitlements and endpoint match prior installed build 4.

Previously verified signed artifacts and full device receipts are retained in the local task cache. Future requests with unchanged source/configuration should verify and reuse those artifacts while provisioning remains valid, without rerunning all builds/tests. No signed app/archive or provisioning data is uploaded by this commit. In-place install/normal launch does not prove physical notification, Health, Screen Time or Watch behavior.
