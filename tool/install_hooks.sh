#!/usr/bin/env bash
#
# Installs the repo's Git hooks. Run once after cloning:
#   bash tool/install_hooks.sh
#
# Points core.hooksPath at tool/hooks/ so the hooks are version-controlled and
# reviewed like any other file, rather than living untracked in .git/hooks
# where every clone starts without them.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
git config core.hooksPath tool/hooks
chmod +x tool/hooks/* 2>/dev/null || true

echo "Hooks installed (core.hooksPath = tool/hooks):"
ls -1 tool/hooks
echo
echo "Bypass a single commit with --no-verify. CI enforces the same checks."
