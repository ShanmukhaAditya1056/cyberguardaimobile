#!/usr/bin/env bash
#
# Rejects files that must never enter Git history.
#
# This exists because of a specific, expensive incident. A commit added
# ml_training/.venv-ml — a Python virtualenv — carrying dnnl.lib at 606 MB,
# cudnn_cnn_infer64_8.dll at 578 MB and cublasLt64_12.dll at 514 MB, roughly
# 49,000 files and 7.9 million lines in one go. GitHub hard-rejects any blob
# over 100 MB, so that commit could never be pushed. `main` was stuck, and
# every subsequent piece of work had to be parked on a side branch instead —
# which is how the repository ended up with eleven of them and two unrelated
# orphan root commits.
#
# None of that was a branching problem. It was one oversized commit. Catching
# it at the point of `git add` costs nothing; removing it afterwards means
# rewriting history.
#
# Used by the pre-commit hook (staged files) and by CI (whole tree).
#   ./tool/check_repo_hygiene.sh --staged   # what is about to be committed
#   ./tool/check_repo_hygiene.sh            # everything currently tracked

set -uo pipefail

# GitHub hard-fails at 100 MB and warns from 50 MB. Refuse well below the
# hard limit so there is room to notice before history has to be rewritten.
MAX_KB=$((25 * 1024))

# Directories that are build output, dependencies or virtualenvs. All of them
# are reproducible from a manifest, so none belongs in version control.
FORBIDDEN_PATHS='(^|/)(\.venv[^/]*|venv|node_modules|\.dart_tool|\.gradle|build|Pods|\.cxx)(/|$)'

# Config that carries real credentials.
FORBIDDEN_FILES='(google-services\.json|GoogleService-Info\.plist|api_keys\.dart|\.keystore|\.jks|\.env)$'

if [ "${1:-}" = "--staged" ]; then
  mapfile -t FILES < <(git diff --cached --name-only --diff-filter=ACM)
  SCOPE="staged"
else
  mapfile -t FILES < <(git ls-files)
  SCOPE="tracked"
fi

fail=0

for f in "${FILES[@]}"; do
  [ -z "$f" ] && continue

  if [[ "$f" =~ $FORBIDDEN_PATHS ]]; then
    echo "BLOCKED  $f"
    echo "         build output / dependencies / virtualenv — add it to .gitignore"
    fail=1
    continue
  fi

  if [[ "$f" =~ $FORBIDDEN_FILES ]]; then
    echo "BLOCKED  $f"
    echo "         carries credentials — keep it gitignored and out of history"
    fail=1
    continue
  fi

  # Size check runs against the working tree; a staged-only path may be gone.
  [ -f "$f" ] || continue
  kb=$(du -k "$f" 2>/dev/null | cut -f1)
  [ -z "$kb" ] && continue
  if [ "$kb" -gt "$MAX_KB" ]; then
    echo "BLOCKED  $f"
    echo "         $((kb / 1024)) MB exceeds the ${MAX_KB}KB limit — GitHub rejects blobs over 100 MB."
    echo "         Ship it as a release asset or regenerate it from source instead."
    fail=1
  fi
done

if [ "$fail" -ne 0 ]; then
  echo
  echo "Repo hygiene check failed on $SCOPE files (see above)."
  echo "Override once with: git commit --no-verify   (CI still enforces this)"
  exit 1
fi

echo "Repo hygiene OK — ${#FILES[@]} $SCOPE files, none oversized or vendored."
