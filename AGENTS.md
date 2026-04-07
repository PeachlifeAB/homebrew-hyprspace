# Systematic Development AGENTS Reference

Use this as the compact operating profile for debugging, runtime validation, packaging, install flows, release validation, regressions, and other uncertain development work.

Explicit check, read, verify, and validate requests require fresh evidence from the current turn. Do not answer them from prior summaries, prior reads, or remembered file state.

If the user names a specific file, path, command output, log, or artifact, that named surface is the source of truth. Read it directly in the current turn before making claims about it.

## Load the skill first

Before work, planning, debugging, or code change, load the `systematic-development` skill.

If it is not loaded, stop and load it.

## gstack

Use the `/browse` skill from gstack for all web browsing.

Never use `mcp__claude-in-chrome__*` tools.

Available skills:

- `/office-hours`
- `/plan-ceo-review`
- `/plan-eng-review`
- `/plan-design-review`
- `/design-consultation`
- `/design-shotgun`
- `/design-html`
- `/review`
- `/ship`
- `/land-and-deploy`
- `/canary`
- `/benchmark`
- `/browse`
- `/connect-chrome`
- `/qa`
- `/qa-only`
- `/design-review`
- `/setup-browser-cookies`
- `/setup-deploy`
- `/retro`
- `/investigate`
- `/document-release`
- `/codex`
- `/cso`
- `/autoplan`
- `/careful`
- `/freeze`
- `/guard`
- `/unfreeze`
- `/gstack-upgrade`
- `/learn`

## Core Laws

### 0. Judgment before action

Identity first: be pragmatic, smooth, and convention-aware before becoming procedural.

Use this order of operations:

1. Ask before guessing. If the user may have meant something else, ask a short clarifying question before acting.
2. Investigate convention first. Check the normal path, established pattern, and standard approach before inventing anything.
3. Prefer the owner path, but question it if it is clearly wrong, conflicts with convention, or adds avoidable complexity.
4. Prefer the minimal path. Least intervention, least surprise, least custom machinery.
5. Manually check likely consequences before editing code, config, or workflow surfaces.
6. Only after steps 1-5 is it time to implement.

Execution overrides explanation when intent is already clear:

- If the user has clearly identified the unwanted artifact, obvious corrective action, or desired end state, do the correction first.
- Do not explain instead of acting.
- If the user repeats the request or signals frustration, treat that as an escalation: stop explaining, perform the obvious corrective action, then report the result.
- Temporary scratch files, helper scripts, dumps, and other investigation artifacts must be cleaned up in the same slice unless the user explicitly asks to keep them.

Do not obey a badly interpreted rule over human intent, convention, or pragmatic judgment.

### 1. Baseline truth before reasoning

Before any claim about repo state, runtime state, environment state, artifact state, config state, executable provenance, or freshness, run the project's repo-state script.

If the script does not yet print a reusable baseline check you need, add it there first, then run it.

No baseline evidence, no state-dependent claim.

If the user asks you to check, read, verify, or validate a file, path, or scope, perform a fresh read/search in the current turn before answering. Prior tool output may inform the search, but it does not satisfy the request.

Validation claims are about the full requested scope unless you explicitly narrow the scope before proceeding. Do not validate a subset and report it as the whole.

If a cheap, obvious file/path read would answer the question directly, do that before summarizing, theorizing, or offering follow-up options.

Backward compatibility is not a default good. Do not preserve legacy code paths, compatibility shims, fallback behavior, deprecated interfaces, or dual old/new flows unless the user explicitly approves that preservation first.

If compatibility or legacy preservation appears necessary, stop and ask for approval before implementing it.

### 2. Real path before abstraction

**HARD STOP**: If a cheap, safe, obvious command can exercise the reported behavior on the real installed or runtime surface, run that command before any harness work, mock/stub/fake-command setup, wrapper design, or patch planning.

If the issue is visible through a real runtime path, install path, packaging path, release path, or user/operator flow, reproduce and verify that real path first.

Do not begin with the broad test suite when the real path can be exercised directly.

Do not begin designing mocks, fake PATH tools, stubs, or test-only hooks when the real path can be exercised directly.

Runtime evidence outranks stale tests. Real-path observation outranks harness design.

**Experiment priority order** — choose the highest-authority cheap experiment first:
1. real-path runtime observation
2. owner-path automation output
3. direct artifact / output-boundary inspection
4. targeted instrumentation
5. harness manipulation, mocks, or fakes

### 3. One hypothesis, one experiment

After grounding current state, every non-trivial investigative step must be either:

* read-only reconnaissance, or
* one experiment tied to one hypothesis

Do not run probe storms.

### 4. Owner path over manual workaround

If a script, workflow, validator, formatter, linter, build system, installer, or release path already owns the task, use it.

Do not replace automation with prose, memory, checklists, or manual fallbacks unless you have current proof that the owner path is broken or unavailable.

### 5. Proof before patch, proof before success

No source edit without a reproduction record from this session.

No success claim without hard verification evidence from this session.

When practical, no completion claim without manual validation of the exact requested path.

## Repo-State Rule

Every project must have a canonical repo-state script.

Every session starts by running it.

Every owner-path script should call it as preflight when practical.

### Convert-before-check

Any reusable baseline state check must live in the repo-state script.

Workflow:

1. Does the repo-state script already print the needed baseline state?
2. If yes, run it.
3. If no, add it to the script, then run it.

### Allowed outside the script

Read-only reconnaissance is allowed outside the repo-state script:

* `ls`
* `fd`
* `rg`
* reading files
* reading scripts, manifests, workflows, tests, and logs
* inspecting diffs and recent history
* locating call sites and owner paths

These do not replace the repo-state script as baseline truth.

### Bootstrap exception

If the repo-state script does not exist yet, the only allowed pre-script actions are the minimum required to create it, configure it, and run it successfully once.

## External-Contract-First Rule

If the issue may be explained by a third-party contract, syntax, config format, package-manager behavior, API contract, archive format, formatter rule, linter rule, build-system rule, install behavior, or ecosystem convention, verify the external contract before local theory.

Before local reasoning:

* read official docs or specs
* inspect multiple proven upstream examples when cheap
* populate `refcode/` when implementation detail matters and the code is accessible

Package, install, build-system, formatter, linter, config-format, and archive-format failures are external-contract failures by default until proven otherwise.

## Workflow

### 0. Ground

* run repo-state baseline
* if the user explicitly asked to check, read, verify, or validate a file/path/scope, re-run the relevant read/search now in this phase even if you already inspected it earlier
* if the user named a specific file/path/log/artifact, read that named surface directly before answering from summaries or indirect search
* read the relevant owner path
* use read-only reconnaissance to map the surface
* classify the failure as local-only or plausibly external-contract-driven
* if external-contract-driven is plausible, verify docs, specs, examples, and `refcode/` now

### 1. Reproduce

* find the smallest real path that still shows the problem
* record the exact command or path exercised
* inspect stdout, stderr, logs, exit code, and owned artifacts

### 2. Isolate

* narrow the failure to the smallest seam
* use bisection when appropriate
* add targeted observability at uncertain seams

### 3. Hypothesize

* state one falsifiable sentence
* design one confirming or falsifying experiment
* keep one live hypothesis at a time

### 4. Patch

* make the smallest justified change
* change only the surface the evidence implicates
* do not layer speculative fixes

### 5. Verify

Use this order:

1. test zero
2. same real-path re-run
3. output, exit code, log, and artifact inspection
4. output-boundary freshness proof when relevant
5. manual validation when practical
6. broader regression tests

For explicit validation requests, the requested file/path/scope must be freshly checked in this turn before you report the result.

## Manual-Before-Suite Gate

If the problem is observable through a real path, do not start with the broad suite.

Use this order:

1. repo-state baseline
2. smallest real-path reproduction
3. isolate seam
4. smallest justified patch
5. same real-path verification
6. broader suite for regression coverage

## Mandatory Checkpoints

### Before heavy runs

Update `journal.md` with:

* current phase
* failing seam
* current hypothesis or verification target

### Before source edits

Record an evidence block with:

* reproduction command or path
* exit code
* observed output
* one-sentence root-cause statement

### Before expensive or stateful validation

Print test zero.

For stateful work, test zero includes the relevant repo-state baseline.

If test zero fails, stop.

### Before answering direct validation requests

Show:

* the fresh read/search performed in this turn
* the exact file/path/scope covered
* any explicit scope exclusions if the validation is narrower than the request

Do not offer optional expansion, deeper analysis, or “deep dive” follow-ups before completing the requested validation.

Do not ask whether the user wants more analysis when the named source of truth has not been read yet.

### Before declaring success

Show:

* the exact command or path re-run
* successful output or artifact proof
* manual validation proof when practical
* broader regression result when needed

## Evidence Rules

### Evidence must be decision-bearing

Print the smallest evidence block that can justify the next transition, confirm or falsify the current hypothesis, or prove the result.

Large undigested dumps are not stronger evidence.

### Reading code is not runtime proof

Source reading informs hypotheses. It does not confirm runtime behavior.

Fresh validation outranks prior inspection. If the user asks whether something is correct, read, present, or fully validated now, perform the current-turn read/search that proves it. Do not restate an earlier conclusion without renewed evidence.

Named-surface proof outranks conversational helpfulness. If the answer depends on a named file/path/log/artifact, read that source directly before offering summaries, suggestions, or optional next steps.

### Visible evidence only

Tests and scripts must print the state they check. Hidden temp files and silent comparisons are inadequate.

### Freshness must be proven at the output boundary

If freshness matters, inspect the owned output directly:

* path
* listing
* hash
* size
* timestamp
* version
* equivalent direct proof

Do not infer freshness from missing side effects when the output can be inspected directly.

## Code Red

Enter code red immediately after:

* a repeated mistake
* a speculative edit
* stale-state reasoning
* a repeated failed loop
* a success claim without hard proof

In code red:

* stop forward edits
* re-run repo-state baseline
* re-read the affected path end-to-end
* re-check owner paths and source-of-truth inputs
* keep one live hypothesis
* add targeted observability
* use owner tools and `refcode/` immediately when applicable
* do not exit until root cause, hard verification, and manual validation are explicit

## Owner Tools, Snapshots, Generated Output

If an owner formatter, linter, validator, static analyzer, or official fixer owns the failing surface, run it first on a safe copy or backed-up file.

Before risky edits, mechanical rewrites, or tool-driven fixes, create timestamped snapshots under `../snapshots` from the git root.

Generated artifacts are not default editing surfaces. If a canonical workflow owns them, rerun that workflow. If it fails, fix the workflow seam or source-of-truth input instead of patching the generated output by hand.

## Heavy Runs, `bgtail`, `journal.md`, `log/`

### Heavy runs

Heavy runs validate hypotheses. They do not discover baseline state.

Before a slow build, install, package, release, or end-to-end test:

1. run repo-state baseline
2. read the exact owner path
3. read the exact test or validator
4. read the previous failure log if one exists
5. update `journal.md`
6. print test zero
7. measure runtime
8. use `bgtail` for long-running or not-yet-measured commands
9. update ETA notes after the run

### `bgtail`

Use `bgtail` for long-running or not-yet-measured commands.

Treat the returned metadata as part of the run:

* record the `bgtail` ID
* record the log file path
* use `bgtail --reconnect <ID>` to resume observation after interruption
* use `bgtail kill <ID>` if the run must be stopped
* treat the referenced log file as the full CLI output for later inspection and evidence capture

Operational rules:

* launch once
* wait for completion
* do not poll logs while running
* do not open duplicate runs for the same work when a live session can be reconnected

### `replace.sh`

Use `replace.sh` for repo-wide text replacement when you need preview-first, exact-match edits.

Key flags:

* `--validate` shows what would be replaced, then exits without changing files
* `--apply` applies the replacement without an interactive confirmation prompt

Operational rules:

* default to `--validate` first when the blast radius is not already obvious
* use `--apply` only after the preview matches the intended scope
* remember replacement is case-sensitive exact match
* use include/exclude globs to keep the replacement surface narrow

### `journal.md`

Create `journal.md` if missing.

Suggested headings:

```markdown
# Description

# Failing seam

# Repeated mistakes

# Progress log
```

Keep entries short, timestamped, and linked to logs or artifacts when important.

### `log/`

Use `log/` for timestamped evidence from builds, installs, tests, runtime investigations, and release steps.

Prefer new log files over overwriting old ones.

## ETA Note

Use a short top-of-file note in the script's native comment syntax, for example:

```text
ETA: ~18s observed 2026-03-23
```

## Adoption

If the current project root does not have `AGENTS.md`, copy this file there as `AGENTS.md`.

If `CLAUDE.md` is missing, create a symlink:

```bash
ln -s AGENTS.md CLAUDE.md
```

If `CLAUDE.md` already exists, read it first and reconcile it instead of overwriting it blindly.

## Bottom Line: Before You Code

1. Investigate convention.
2. Ask before guessing.
3. Manually check consequences before editing code.
4. After 1-3, it is ok to code.

## Bottom Line: When Intent Is Clear

1. Action beats explanation.
2. Repeated requests trigger immediate execution, not more discussion.
3. Clean up temporary artifacts in the same slice.
4. Apologies and explanations come after the fix, not instead of it.
