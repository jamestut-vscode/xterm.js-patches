# AGENTS.md

This file guides an agent tasked with rectifying patch-apply failures in this repository. Read it fully before acting.

## Context: how this repo is built

This repository hosts personal patches on top of upstream [xterm.js](https://github.com/xtermjs/xterm.js). The build has two stages:

1. `./build-repo.sh` — clones upstream xterm.js (if needed), fetches updates, deletes any existing `patched` branch, then applies our patches with `spm/spm.py patches xterm.js`. This is the stage where patch-apply happens.
2. `./build-artifact.sh` — builds the patched xterm.js and produces `xtermjs.tar.gz`. It only runs `npm ci`, `npm run package`, and `npm pack` inside `xterm.js`. It does NOT apply patches.

**Important:** Patch-apply errors surface from `build-repo.sh` (via `spm`), not from `build-artifact.sh`. To reproduce an apply failure, run `spm/spm.py -vp patches xterm.js` (or `./build-repo.sh`) directly — do not waste time inside `build-artifact.sh`.

## How spm applies patches (mechanics the agent must know)

- `patches/patches.list` is the manifest. It contains:
  - `base-commit: <hash>` — the exact upstream commit spm checks out before applying.
  - `final-commit: <hash|ignore>` — expected resulting commit hash (usually `ignore`).
  - an ordered list of `.patch` files (relative paths, must end in `.patch`).
- `spm/spm.py` does: `git checkout -b patched <base-commit>`, then for each patch: `git apply --index` (reading the patch from stdin) followed by a `git commit` whose author/committer name, email, and date are taken from the patch's `From:`/`Date:` headers.
- Failure symptom: spm prints `Error applying patch '<name>' cleanly.` (to stderr) and aborts with a non-zero exit. Because it fails mid-loop, the `patched` branch is typically left partially created (some patches applied and committed, the failing one not).

Because `base-commit` is pinned to an exact hash, a patch generally fails to apply for one of these reasons:
- The patch file itself is stale/broken (e.g., manually edited incorrectly).
- `base-commit` in `patches.list` was bumped to a newer upstream without regenerating the patch (this is the normal reason patches break over time).
- The patch targets a feature that upstream has changed, renamed, removed, or already merged.

## Step 1 — Reproduce and diagnose

1. Run `spm/spm.py -vp patches xterm.js` from the repo root (the `-vp` flag makes `git apply` verbose so you can see exactly which hunk fails).
2. Identify the failing patch file and the feature it targets. Read its `Subject:` line and its diff to understand what behavior it adds/changes.
3. Clean up the half-applied state before retrying: the `patched` branch may already exist. `build-repo.sh` deletes it automatically, but if you run spm directly, first delete it yourself:
   - `cd xterm.js && git checkout master 2>/dev/null; git branch -D patched; cd ..`
4. Note the upstream version context: the `base-commit` is pinned, so the current `xterm.js` working tree is at that commit after a fresh spm run. When investigating "did upstream change this?", compare against the current upstream `master` (already fetched) and/or inspect the working tree at `base-commit`.

## Step 2 — Investigation decision tree (the core of the task)

For the failing patch, determine WHY it fails. Work through these cases in order. Be rigorous: do not jump to conclusions.

**(A) Context drift only.** The feature and all symbols the patch touches still exist, but line numbers / surrounding whitespace / nearby code changed, so the hunk context no longer matches. This is the most common failure when `base-commit` is bumped.
- Fix: regenerate the patch against the new base so it applies cleanly. (See Resolution below.) → **AUTO-FIX.**

**(B) Feature already exists upstream (change merged).** Upstream has adopted the same behavior, so the lines the patch wants to add are already present (or functionally equivalent), causing `git apply` to fail (e.g., "already exists" / context mismatch on an insertion).
- Do NOT try to force the patch in. Report to the user that the change is now obsolete/upstreamed. → **REPORT ONLY.**

**(C) Feature renamed / refactored / moved.** The functionality the patch wants still exists, but under a different symbol name, different file, or different structure.
- **Critical caution:** Before concluding a feature was removed, you MUST scrutinize the code thoroughly. Search the `xterm.js` tree (use grep across `src/`, `typings/`, etc.) for the patched identifiers, option names, function names, and surrounding logic. Upstream frequently renames options, moves code between files, or refactors interfaces. A patch failing does NOT mean the feature is gone.
- If you find the target was renamed/refactored/moved: update the `.patch` so it points at the new symbol/location/structure. → **AUTO-FIX.**
- If after thorough search you genuinely cannot find any trace of the feature or its equivalents, only then treat it as case (D).

**(D) Feature genuinely removed.** The targeted functionality no longer exists anywhere in upstream and there is no renamed/refactored/moved equivalent.
- The patch is no longer applicable. Report to the user that the patch targets a feature that has been removed. → **REPORT ONLY.**

General caution: never declare a feature "removed" (case D) without first exhausting case (C) — i.e. grep for renamed/refactored/moved variants. Prematurely dropping a patch loses functionality.

## Step 3 — Resolution actions

For **(A)** and **(C)** (auto-fix):
- Edit or regenerate the failing `.patch` file under `patches/` so it applies cleanly against the current `base-commit` (or against the newly bumped base-commit if that is the intent). Preferred approach:
  - Apply the patch with `git apply --reject` to get a `.rej` showing what failed, then manually incorporate the intended change at the correct new location, then regenerate the patch via `git diff` (or by committing and using `git format-patch`). Keep the patch in the same `git format-patch`-style format spm expects (proper `From:`/`Date:`/`Subject:` headers and `a/` `b/` paths).
  - **Refresh the date metadata:** when you modify a patch, update its `Date:` header to the current date/time. spm reads that `Date:` line to set `GIT_AUTHOR_DATE`/`GIT_COMMITTER_DATE` on the resulting commit, so refreshing it keeps the patch current. Keep the `From:` author and `Subject:` intact; only the timestamp should change.
- Re-run `spm/spm.py -vp patches xterm.js` (and clean up the `patched` branch first) to confirm all patches now apply cleanly.

For **(B)** and **(D)** (report only):
- Tell the user clearly: (B) the change is already upstreamed/obsolete, or (D) the targeted feature has been removed from upstream.
- Recommend removing the corresponding entry from `patches/patches.list` (and the `.patch` file if appropriate). **Do NOT delete the patch or edit `patches.list` without the user's confirmation** — only report and propose.

After fixing:
- Re-run `./build-repo.sh` to confirm the patched branch builds cleanly, then `./build-artifact.sh` to verify `xtermjs.tar.gz` is produced.

## Guardrails

- Never silently delete patches or remove entries from `patches.list`. Report removal cases (B/D) and obtain user confirmation.
- Do not change `base-commit` casually. If bumping `base-commit` is what triggered the failure, that is a deliberate action — confirm with the user and expect to fix/regenerate patches accordingly.
- Preserve patch metadata integrity: keep `From:` author and `Subject:` when regenerating; refresh `Date:` to current time for modified patches (preferred).
- Verify the end result actually builds (`build-artifact.sh`) before declaring success — a patch that "applies" but breaks the TypeScript build is not a real fix.
- When in doubt about whether a feature was removed vs. moved, search more. Incorrectly dropping a working patch is worse than asking.
