# Roadmap

Incremental, test-first implementation plan. Each substep follows the same rhythm:

1. Write fixtures (captured CLI output or mock data)
2. Write failing tests against the fixture
3. Implement until tests pass
4. Byte-compile clean + lint clean
5. Manual spot-check in `emacs -Q` if the substep has UX surface

No substep depends on a booted simulator/emulator unless marked **(integration)**. Unit tests use fixture data exclusively.

---

## Phase 0: Foundation

The goal is a working vertical slice — one platform (iOS), core verbs, basic transient, compilation-mode output. Android follows the same patterns once iOS proves the architecture.

### 0.0 — Project scaffold

- [x] Eask file with metadata + deps (`transient`, `compat`)
- [x] Makefile (`compile`, `test`, `lint`, `check`, `clean`)
- [x] `lisp/mdc.el` — package header, defgroup, requires
- [x] `test/` directory with a single passing no-op ert test
- [x] Confirm `make check` passes from a clean state
- [x] `make test-apps` target to shallow-clone test apps (not tracked in git):
  - iOS: [Apple Food Truck](https://github.com/apple/sample-food-truck) → `test-apps/ios/`
  - Android: [Now in Android](https://github.com/android/nowinandroid) → `test-apps/android/`
- [x] Add `test-apps/` to `.gitignore` (entire directory — fixtures are committed separately in `test/fixtures/`)
- [x] Verify both test apps build: `xcodebuild` for Food Truck, `./gradlew assembleDebug` for Now in Android

**Gate:** `eask test ert` and `eask compile` both exit 0. Both test apps build successfully.

### 0.1 — Core utilities (`mdc-core.el`)

- [ ] Process invocation helpers — `mdc-core--call` (sync), `mdc-core--start` (async with sentinel/filter)
- [ ] JSON parsing helper — `mdc-core--parse-json` (wraps `json-parse-buffer` with consistent error handling)
- [ ] Project context resolution — `mdc-core--project-value` (reads `.dir-locals.el` values: device-id, bundle-id, scheme, flavor)
- [ ] Device ID validation — refuse to operate on unconfigured targets

**Tests:** Mock process output via fixture strings. Test that project-value resolution returns expected values from a temp `.dir-locals.el`. Test that missing config raises a user-facing error.

**Gate:** All unit tests pass. No integration needed.

### 0.2 — iOS device listing (`mdc-ios.el`, first function)

- [ ] Capture real `xcrun simctl list devices --json` output → `test/fixtures/simctl-list.json`
- [ ] `mdc-ios--parse-devices` — extract booted devices as alist of `(name . udid)`
- [ ] `mdc-ios-devices` — interactive command that calls simctl and displays results

**Tests:** Parser tested against fixture. Multiple cases: no devices booted, one booted, several booted, mix of unavailable/shutdown/booted.

**Gate:** Unit tests pass. Interactive command works in `emacs -Q -L lisp`.

### 0.3 — iOS build (`mdc-ios-build`)

- [ ] Capture real `xcodebuild` output (success + failure) → `test/fixtures/xcodebuild-*.txt`
- [ ] `mdc-ios--build-args` — constructs argument list from project context (scheme, destination)
- [ ] `mdc-ios-build` — async process via `compilation-mode`
- [ ] Compilation error regex for xcodebuild output — `next-error` jumps to source

**Tests:** Argument construction tested with various project configs. Error regex tested against fixture output (known error lines should match, non-error lines should not).

**Gate:** Unit tests pass. **(Integration)** manual build of a test project works with `next-error` navigation.

### 0.4 — iOS install + run (`mdc-ios-install`, `mdc-ios-launch`, `mdc-ios-stop`)

- [ ] `mdc-ios--install-args`, `mdc-ios--launch-args` — argument construction
- [ ] Commands that call `simctl install`, `simctl launch`, `simctl terminate`
- [ ] Launch returns PID / confirms boot state

**Tests:** Argument construction against fixture project configs. Verify correct bundle-id and device-id threading.

**Gate:** Unit tests pass. **(Integration)** install + launch on dedicated test simulator.

### 0.5 — iOS logs (`mdc-ios-logs`)

- [ ] `mdc-ios-logs` — async process streaming `simctl spawn <udid> log stream --predicate ...` into a buffer
- [ ] Process filter that applies bundle-id predicate
- [ ] Buffer naming convention: `*mdc-logs: <device-name>*`

**Tests:** Filter logic tested against sample log lines (fixture). Verify predicate construction from bundle-id.

**Gate:** Unit tests pass. **(Integration)** log stream works against booted test sim.

### 0.6 — iOS utilities (`mdc-ios-deep-link`, `mdc-ios-screenshot`, `mdc-ios-clear-data`)

- [ ] `mdc-ios-deep-link` — `simctl openurl`
- [ ] `mdc-ios-screenshot` — `simctl io screenshot`, saves to configurable path
- [ ] `mdc-ios-clear-data` — uninstall + reinstall (simctl has no direct clear)

**Tests:** Argument construction. Path generation for screenshots (dated, device-named).

**Gate:** Unit tests pass. **(Integration)** each command works on test sim.

### 0.7 — Transient menu (`mdc-transient.el`)

- [ ] Root transient `mdc-dispatch` with iOS submenu
- [ ] iOS submenu wiring: devices, build, install, run, stop, logs, deep-link, screenshot, clear-data
- [ ] Transient infix for device selection (populated from `mdc-ios-devices`)
- [ ] Transient infix for scheme/config override

**Tests:** Transient definitions load without error. Menu structure matches expected layout (programmatic introspection of transient suffixes).

**Gate:** `make check` passes. Menu works in `emacs -Q`.

### 0.8 — Dispatch layer (`mdc-dispatch.el`)

- [ ] Project type detection — heuristic (`.xcodeproj` presence) + `.dir-locals.el` override
- [ ] `mdc-dispatch--platform` — returns `ios`, `android`, or prompts
- [ ] Unified verb commands (`mdc-build`, `mdc-run`, etc.) that delegate to platform-specific functions

**Tests:** Detection heuristic tested with temp directories containing marker files. Dispatch routing tested with `let`-bound platform value.

**Gate:** Unit tests pass. Calling `mdc-build` in an iOS project context routes to `mdc-ios-build`.

---

## Phase 1: Test result integration

### 1.0 — xcresult parsing (`mdc-compile.el`)

- [ ] Capture real `xcresulttool get --format json` output → `test/fixtures/xcresult-*.json`
- [ ] `mdc-compile--parse-xcresult` — extract test failures as `(file line column message)` tuples
- [ ] Emit failures into a compilation buffer with proper format for `next-error`

**Tests:** Parser tested against fixture. Edge cases: all-pass, single failure, multiple failures across files, test crashes.

**Gate:** `next-error` navigates correctly from parsed xcresult fixture data.

### 1.1 — Gradle JUnit XML parsing

- [ ] Capture real Gradle test XML output → `test/fixtures/gradle-test-*.xml`
- [ ] `mdc-compile--parse-junit-xml` — extract failures via `libxml-parse-xml-region`
- [ ] Same compilation buffer integration as xcresult

**Tests:** Parser against fixture. Cases: pass, failure, error, skipped, multiple test suites.

**Gate:** `next-error` works. Parity with xcresult output format.

### 1.2 — Unified test command

- [ ] `mdc-test` dispatches to `xcodebuild test` or `./gradlew test` based on platform
- [ ] Results automatically parsed and presented in compilation buffer
- [ ] Transient entry added

**Gate:** End-to-end flow works: invoke test → build runs → results parsed → `next-error` jumps to source.

---

## Phase 2: Android adapter + cross-platform

### 2.0 — Android device listing (`mdc-android.el`)

- [ ] Fixture from `adb devices -l` output
- [ ] `mdc-android--parse-devices`
- [ ] `mdc-android-devices`

### 2.1 — Android build (`mdc-android-build`)

- [ ] `./gradlew` invocation via compilation-mode
- [ ] Gradle error regex for `next-error`

### 2.2 — Android install + run + stop

- [ ] `adb install`, `adb shell am start`, `adb shell am force-stop`

### 2.3 — Android logs, deep-link, screenshot, clear-data

- [ ] `adb logcat` with package filter
- [ ] `adb shell am start -a android.intent.action.VIEW -d <url>`
- [ ] `adb exec-out screencap -p`
- [ ] `adb shell pm clear`

### 2.4 — Dispatch integration

- [ ] `mdc-dispatch` routes to Android adapter when context is Android project
- [ ] Transient menu gains Android submenu
- [ ] Unified verbs work for both platforms

### 2.5 — Compositions: parity

- [ ] `mdc-parity-run` — install + launch on all booted targets
- [ ] `mdc-parity-screenshot` — screenshot all, display side-by-side
- [ ] Buffer layout for comparison

---

## Phase 3: Higher-level utilities

### 3.0 — Scenario sweeps

- [ ] Scenario file format (Elisp forms for v0)
- [ ] `mdc-scenario-run` — replay steps against a target
- [ ] `mdc-scenario-sweep` — matrix of scenarios × devices, screenshot each

### 3.1 — State bookmarks

- [ ] `mdc-bookmark-save` — snapshot app container + metadata
- [ ] `mdc-bookmark-restore` — restore from snapshot
- [ ] Transient UI for listing/selecting bookmarks

### 3.2 — Flaky test triage

- [ ] `mdc-test-rerun-failures` — rerun failing tests N times
- [ ] Report pass rate per test
- [ ] Classify: consistent failure vs flaky

### 3.3 — Build diff

- [ ] Archive two branches
- [ ] Diff: app size, Info.plist, permissions, frameworks
- [ ] Report buffer

### 3.4 — Decoupled profiling

- [ ] `xctrace record` wrapper with scenario input
- [ ] Save `.trace`, open Instruments as viewer
- [ ] (Future: parse `xctrace export` XML into Emacs buffer)

---

## Regression Testing Strategy

Every substep adds tests. Tests never get deleted. The cumulative test suite is the primary quality guarantee.

**Fixture management:**
- Fixtures are real CLI output, captured once and committed
- When platform CLI output format changes (OS updates, new Xcode), re-capture fixtures and fix parsers — the test catches the regression
- Each fixture file is documented with what platform version produced it

**Test categories:**
- **Unit** (no side effects, fixture-driven) — runs on every `make check`
- **Integration** (needs booted devices) — opt-in via `MDC_INTEGRATION=1`, guarded by `skip-unless`
- **Regression** — any bug fix gets a test case *before* the fix, using the exact input that triggered it

**Coverage expectations:**
- Every public function has at least one test
- Every parser has edge-case coverage (empty input, malformed input, version-specific quirks)
- Argument construction functions are tested for every meaningful combination of project config values
- Error paths are tested: missing config, device not booted, CLI not found, parse failure on unexpected output

**When to re-capture fixtures:**
- Major Xcode or Android SDK version bumps
- When a real-world CLI output doesn't match the fixture (discovered via integration test failure)
- Tag fixture files with the tool version: `simctl-list-xcode15.2.json`
