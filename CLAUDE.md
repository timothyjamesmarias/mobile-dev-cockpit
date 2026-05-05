# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mobile Dev Cockpit (`mdc`) is an Emacs package providing a transient-menu interface over iOS and Android platform CLIs (`xcodebuild`, `simctl`, `devicectl`, `adb`, `gradle`, `emulator`). It unifies mobile development workflows into a single discoverable menu with a shared verb vocabulary across platforms.

**Status:** Design phase. Architecture is documented in `mobile-dev-cockpit.md`. No implementation code exists yet.

## Architecture

Three-layer pure Elisp design (no external binaries):

1. **Platform adapters** (`mdc-ios.el`, `mdc-android.el`) — thin wrappers calling platform CLIs via `call-process` (sync) or `make-process` (async), parsing output with `json-parse-buffer` and `libxml-parse-xml-region`
2. **Transient menu** (`mdc-transient.el`) — magit-style menu tree dispatching to adapter functions
3. **Compositions** (`mdc-compose.el`) — higher-level utilities (parity fan-out, scenario sweeps, bookmarks, flaky test triage) built from adapter primitives

A dispatcher (`mdc-dispatch`) selects the correct platform adapter based on project context. Per-project config (bundle ID, scheme, flavor, device) lives in `.dir-locals.el`.

## Key Design Constraints

- Pure Elisp, single package — no IPC, no external adapter binaries, no new config languages
- Output routes through `compilation-mode` with platform-specific error regexes
- macOS-first (iOS tooling requires it)
- `transient.el` is the only UI framework (menu-as-API pattern)
- Package management via Cask or Eask (not yet scaffolded)

## Build & Test (when scaffolded)

Not yet established. Plan is:
- Package deps managed by Cask or Eask
- Tests via `ert` (Emacs built-in test framework)
- CI via Makefile with shell one-liners wrapping `emacs --batch`

## Phased Rollout

- **Phase 0:** Core adapter functions + basic transient menu + compilation-mode integration
- **Phase 1:** xcresult/Gradle test result parsing into compilation buffer
- **Phase 2:** Cross-platform compositions (parity, scenario, bookmark)
- **Phase 3:** Flaky test triage, build diff, log bookmarks, decoupled profiling
