#!/usr/bin/env bash
#
# Installs the APK, starts Appium and runs the E2E suite on a booted emulator.
#
# WHY THIS IS A FILE AND NOT AN INLINE `script:` BLOCK
# ---------------------------------------------------
# reactivecircus/android-emulator-runner runs its `script:` input **one line
# per shell** — the job log shows a separate `/usr/bin/sh -c <line>` for every
# line. Nothing carries across: `cd` does not persist, `&` backgrounding dies
# with the line that started it, `$!` is empty on the next line, and `for` /
# `if` blocks and backslash continuations are torn apart.
#
# That silently broke this suite for a long time in two different ways:
#
#   * `npx appium … --log-timestamp \` ran as its own command, so the trailing
#     backslash was passed to Appium as an argument — `Unrecognized arguments:
#     \` — and the server never started.
#   * `cd automation` had no effect on the following line, so npx could not see
#     the locally installed Appium and downloaded a different version from the
#     registry instead.
#
# Making the action's `script:` a single `bash tool/e2e_on_emulator.sh` gives
# this file one shell, where ordinary shell semantics apply.
#
# Deliberately not `set -e`: every stage below is expected to be able to fail
# and still reach the artifact upload. The suite's real exit code is handed
# back through SUITE_EXIT in $GITHUB_ENV, and the pass-rate gate at the end of
# the job is what fails the build.

set -uo pipefail

ROOT="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$ROOT" || exit 1

# Defaulted rather than assumed. Under `set -u` a missing one of these would
# abort the script with "unbound variable" before the first log line, which is
# the least diagnosable failure available.
: "${CG_APP_PATH:=$ROOT/build/app/outputs/flutter-apk/app-debug.apk}"
: "${GITHUB_ENV:=/dev/null}"

CONSOLE="$ROOT/e2e-console.log"
APPIUM_LOG="$ROOT/appium-server.log"

# Written before anything else. If this file is missing from the e2e-logs
# artifact, the script never ran at all — a different failure from any test
# result, and one worth being able to tell apart at a glance.
echo "e2e_on_emulator.sh started $(date -u +%FT%TZ)" > "$CONSOLE"

log() {
  echo "$@" | tee -a "$CONSOLE"
}

# Re-emits a failure as a check-run annotation. Job logs need an authenticated
# token to read; annotations do not, so this is what makes a failure
# diagnosable from the run page itself.
annotate() {
  local title="$1" body="$2"
  body="$(printf '%s' "$body" | sed 's/%/%25/g' | awk '{printf "%s%%0A", $0}')"
  echo "::error title=${title}::${body}"
}

echo "::group::Device information"
adb wait-for-device
adb shell input keyevent 82 || true
log "release: $(adb shell getprop ro.build.version.release | tr -d '\r')"
log "sdk:     $(adb shell getprop ro.build.version.sdk | tr -d '\r')"
adb devices -l | tee -a "$CONSOLE"
echo "::endgroup::"

echo "::group::Install APK"
if [ ! -f "$CG_APP_PATH" ]; then
  annotate "E2E setup" "APK not found at $CG_APP_PATH — the Download APK step did not produce it."
  exit 1
fi
adb install -r -g "$CG_APP_PATH" 2>&1 | tee -a "$CONSOLE"
install_rc=${PIPESTATUS[0]}
if [ "$install_rc" -ne 0 ]; then
  annotate "E2E setup" "adb install failed (exit $install_rc). Every test would fail on a missing app, so the suite is not run."
  exit 1
fi
adb shell pm list packages | grep cyberguard | tee -a "$CONSOLE"
echo "::endgroup::"

echo "::group::Start Appium"
cd "$ROOT/automation" || exit 1
# Local Appium, not a registry download: `npm ci` in the previous step
# installed the pinned version together with the uiautomator2 driver, and a
# different major from the registry would drive the app differently.
npx appium --allow-cors --relaxed-security --log-timestamp --log "$APPIUM_LOG" &
APPIUM_PID=$!
log "appium pid $APPIUM_PID"

healthy=0
for _ in $(seq 1 60); do
  if curl -sf http://127.0.0.1:4723/status > /dev/null 2>&1; then
    healthy=1
    break
  fi
  sleep 1
done

if [ "$healthy" -ne 1 ]; then
  log "Appium never became healthy on 127.0.0.1:4723"
  tail=""
  [ -f "$APPIUM_LOG" ] && tail="$(tail -c 1200 "$APPIUM_LOG" | tr -d '\r')"
  annotate "E2E setup" "Appium never became healthy on 127.0.0.1:4723.

appium-server.log tail:
${tail:-<log absent — Appium produced no output at all>}"
  exit 1
fi
log "Appium is up"
echo "::endgroup::"

echo "::group::Run suite"
# Redirected rather than piped, so $? below is the suite's own exit code.
# PIPESTATUS would work here too, but only because this script is bash — the
# inline version this replaced ran under sh, where it is unavailable.
npm test >> "$CONSOLE" 2>&1
SUITE_EXIT=$?
tail -n 200 "$CONSOLE"
echo "::endgroup::"

if [ "$SUITE_EXIT" -ne 0 ]; then
  focus="$(grep -E 'Error|error:|failing|AssertionError|Fatal|No tests|not executed|pass rate|Cannot find|ECONNREFUSED' \
            "$CONSOLE" 2>/dev/null | tail -25 | tr -d '\r')"
  annotate "E2E suite failed (exit $SUITE_EXIT)" "${focus:-<no error-shaped lines; see the e2e-console artifact>}"
fi

kill "$APPIUM_PID" 2>/dev/null || true
echo "SUITE_EXIT=$SUITE_EXIT" >> "$GITHUB_ENV"

# Always zero: artifacts are uploaded by later steps, and the pass-rate gate at
# the end of the job is what decides the build.
exit 0
