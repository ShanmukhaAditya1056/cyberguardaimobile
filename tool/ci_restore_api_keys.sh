#!/usr/bin/env bash
# Creates lib/core/config/api_keys.dart on a machine that does not have one.
#
# That file is gitignored because it holds a real key locally, but two source
# files import it — link_interceptor_repository.dart and
# safe_browsing_source.dart — so a fresh checkout cannot analyze, test or build
# without it. Every CI job that runs the Flutter toolchain needs this first.
#
# The example template leaves the keys empty, which disables the Safe Browsing
# source. That is the outcome we want on CI: no build should ever call a
# third-party API.
#
# Also useful after `git clone` — see docs/PLATFORMS.md.
set -euo pipefail

target="lib/core/config/api_keys.dart"
template="lib/core/config/api_keys.example.dart"

if [ -f "$target" ]; then
  echo "api_keys.dart already present — leaving it alone."
  exit 0
fi

if [ ! -f "$template" ]; then
  echo "error: $template is missing; cannot create $target" >&2
  exit 1
fi

cp "$template" "$target"
echo "Created $target from the example (empty keys — cloud intel stays disabled)."
