# Repo hygiene

Guards that stop a class of problem this repository has already paid for.

## After cloning

```bash
bash tool/install_hooks.sh
```

One command, once. It points `core.hooksPath` at `tool/hooks/`, so the hooks
are version-controlled and reviewed like any other file instead of living
untracked in `.git/hooks` where every fresh clone starts without them.

## What is guarded, and why

### Oversized files and vendored directories

`tool/check_repo_hygiene.sh` refuses anything over **25 MB**, anything under a
build/dependency/virtualenv directory, and any file that carries credentials.

It exists because of a specific incident. A commit added
`ml_training/.venv-ml` — a Python virtualenv — carrying `dnnl.lib` at 606 MB,
`cudnn_cnn_infer64_8.dll` at 578 MB and `cublasLt64_12.dll` at 514 MB: about
49,000 files and 7.9 million lines. GitHub hard-rejects any blob over 100 MB,
so that commit **could never be pushed**. `main` was stuck, and every later
piece of work had to be parked on a side branch instead — which is how the
repository ended up with eleven branches and two unrelated orphan roots.

That was never a branching problem. It was one oversized commit, and the check
that would have stopped it takes under a second.

Runs in two places, from the same script so they cannot drift:

| Where | Scope |
|---|---|
| `tool/hooks/pre-commit` | staged files, before the commit exists |
| CI `hygiene` job | the whole tracked tree, gating every other job |

Bypass locally with `git commit --no-verify`. CI still enforces it.

### Line endings — `.gitattributes`

Everything is normalised to LF, with two deliberate exceptions: `*.bat` keeps
CRLF (Windows batch breaks subtly without it) and `gradlew` / `*.sh` are pinned
to LF (CRLF there produces `bad interpreter`).

Binaries — fonts, PNGs, pickled models, the Gradle wrapper jar — are marked
`binary` **explicitly** rather than left to `text=auto` detection. A font that
Git guesses wrong gets corrupted on checkout, silently, and only shows up at
runtime.

### Generated files

`GeneratedPluginRegistrant.java` is **not tracked**. It is produced by
`flutter pub get` from the plugin list in `pubspec.yaml`, so tracking it meant
a second source of truth that drifted: it sat in the tree missing
`firebase_auth`, `firebase_core` and `google_sign_in` long after those were
added, and turned up as a spurious "modified" file after almost every build.
Every CI job runs `flutter pub get` before analyze/test/build, so it is always
regenerated.

Files that *are* still tracked but generated — `lib/l10n/generated/**`,
`*.g.dart`, `pubspec.lock` — are marked `linguist-generated` so GitHub
collapses them in diffs and leaves them out of language stats.

## Two settings to turn on in GitHub

Not code, so they are not in this repo. Both are worth a minute:

1. **Settings → General → Automatically delete head branches.**
   The four `copilot/*` branches would have cleaned themselves up.

2. **Settings → Branches → protect `main`, require a pull request.**
   Nothing lands directly, so `main` never becomes the branch nobody can push
   to — the state that started all of this.

## The pattern underneath

Almost every collision in this repo has been the same shape: **two sources of
truth that drift apart.** Duplicate branches, two `redirect:` parameters on one
router, an SMS receiver registered both statically and dynamically, a verdict
string the writers produced that `isThreat` had never heard of, a font family
declared in `pubspec.yaml` whose files were secretly WOFF2.

The durable fix is to delete one of the two. Where that is impossible, pin them
against each other with a test — `scan_verdict_test.dart`,
`font_assets_test.dart` and `route_guard_test.dart` all exist for exactly that
reason.
