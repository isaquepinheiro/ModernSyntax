---
type: handoff
kind: artifact
title: "ModernSyntax — Handoff to Architect"
description: "Executive summary, must-know decisions, finding pointers, and open questions from the discovery pass."
cycle: cycle-001-895e1e3e
agent: analyst
workflow: analyst-existing-project
node: synthesis
resource: aefos://run/895e1e3e3cd5c3c50b9218ed2a0b398c
generated:
  by: analyst-existing-project@node:synthesis
  at: "2026-08-27T00:00:00Z"
tags: [cycle-001, handoff, modernsyntax, delphi, functional-programming]
---

# ModernSyntax — Handoff to Architect

## Executive Summary

ModernSyntax is a **source-only Object Pascal / Delphi library** that adds
functional-programming idioms to the Delphi RTL. It has **16 units**,
**10 496 source lines**, **zero external runtime dependencies**, and is
distributed through the Boss and PubDelphi package registries.

The library is architecturally sound at the intra-module level: the internal
dependency graph is a clean DAG, identifier conventions are consistent across
all 16 units, and 11 of 15 testable modules have DUnitX coverage (431 tests,
951 assertions).

**Three issues demand an architect decision before any feature work or
multi-platform roadmap item is started:**

1. **G-01 (CRITICAL)** — `TMatch.FMatch` is a process-wide class variable with
   no locking. Concurrent pattern matching is a data race today.

2. **G-02 (HIGH)** — `Windows` is imported unconditionally in the interface
   section of `ModernSyntax.Std` and `ModernSyntax.DotEnv`, blocking 6 of 16
   units from non-Windows compilation — directly contradicting the README's
   cross-platform claim.

3. **G-07 (MEDIUM)** — The library ships three independent result carriers
   (`TFuture`, `TResultPair<S,F>`, `TSafeResult`) with no conversion path
   between them. Any consumer combining Async + Match + SafeTry writes all three
   conversions by hand. Unification is a breaking API change; the longer it is
   deferred, the more expensive it becomes.

---

## Must-Know Decisions

Every item below is a MEASURED fact with its citation. Nothing is taken from
documentation alone.

### 1. `TMatch.FMatch` class variable — CRITICAL thread-race hazard

`TMatch` (companion class, `Match.pas:211`) declares:

```pascal
class var FMatch: TValue;   // Match.pas:213
```

Written at `Match.pas:242`, read at `Match.pas:1652`. No threading primitive
in the file (`grep -n "SyncObjs\|TCriticalSection\|TMonitor" Source/ModernSyntax.Match.pas` → 0 results).

**Decision options the architect must choose between:**
- (a) Add a `TCriticalSection` around `FMatch` writes and reads.
- (b) Eliminate the class variable entirely; thread the result through local
  variables — this removes the companion class.
- (c) Formally document `TMatch<T>` as single-threaded only and add a runtime
  assertion.

### 2. `Windows` unconditional import — 6 units blocked from non-Windows

`ModernSyntax.Std.pas:21` and `ModernSyntax.DotEnv.pas:22` list `Windows` in
the **interface** `uses` with no `{$IFDEF MSWINDOWS}`. Downstream units `Crypt`
(line 21), `ArrowFun` (line 23), `Match` (line 26) inherit the dependency
transitively. `ModernSyntax.Objects.pas:161` is implementation-only (lower risk).

**Decision options:**
- (a) Wrap Windows-specific calls in `{$IFDEF MSWINDOWS}` and supply RTL/POSIX
  alternatives (`TTimeZone`, `SysUtils.GetEnvironmentVariable`).
- (b) Formally restrict the supported platforms to Win32/Win64 in README and
  `pubdelphi.json` and remove the cross-platform claim.

### 3. Three incompatible result carriers

| Carrier | Defined at | Used by |
|---------|-----------|---------|
| `TFuture` | `ModernSyntax.pas:32` | `TAsync`, `TCoroutine` |
| `TResultPair<S,F>` | `ModernSyntax.ResultPair.pas:57` | `TMatch`, `TOption` |
| `TSafeResult` | `ModernSyntax.Safetry.pas:23` | `TSafeTry` |

No adapter between any two (confirmed by `grep`; see [project-overview.md](project-overview.md) §Architecture).
`TFuture` and `TSafeResult` expose the same `.IsOk`/`.IsErr` shape and are
candidates for unification.

**Decision options:**
- (a) Define a common `IResult<T>` interface or adapter record.
- (b) Formally document which carrier is authoritative for each domain and
  provide a utility function for each conversion pair.
- (c) Unify `TFuture` and `TSafeResult` (breaking change for consumers using
  `TSafeTry` by name).

### 4. `rtNone` undetectable state in `TResultPair` (MEDIUM)

`TResultPair.New` produces `rtNone` (`ResultPair.pas:823`). Neither `isSuccess`
nor `isFailure` detects it (lines 680–685). No `IsNone`/`IsNew` predicate
exists (`grep -n "IsNone\|isNone" Source/ModernSyntax.ResultPair.pas` → 0).
A consumer who forgets to call `.Success`/`.Failure` silently chains callbacks
on a permanently inert container.

**Architect decision:** add `IsNone: Boolean` predicate, or raise in
`ThenOf`/`ExceptOf` when called on `rtNone`.

### 5. Four modules with zero test coverage (MEDIUM-HIGH)

`ModernSyntax.Coroutine` (585 lines), `ModernSyntax.Crypt` (335 lines),
`ModernSyntax.ArrowFun` (309 lines), `ModernSyntax.RegExpression` (328 lines)
have no `PTest*.dpr` (confirmed: `find "Test Delphi"` search → no output for
any of the four names). Combined: **1 557 lines** of production code with no
executable tests.

**Architect decision:** determine stability status of these four units before
writing tests (see OQ-4 below), then commission `PTestCoroutine`, `PTestCrypt`,
`PTestArrow`, `PTestRegExpression` and add them to `DCC.bat` and
`TestMSGroup.groupproj`.

### 6. No CI pipeline (MEDIUM-HIGH)

`find . -name ".github" | wc -l` → 0. DUnitX produces NUnit XML; no pipeline
consumes it. `{$DEFINE CI}` stub in `PTestMatch.dpr:3` is commented-out dead code.

**Architect decision:** establish a CI workflow (GitHub Actions with Delphi
image, or a `dcc32`/`dcc64` script) targeting at least Win64 initially.

### 7. `TAsync` continuations require main-thread message pump (MEDIUM)

`TThread.Queue` at `Async.pas:227, 271, 313` (all pass `TThread.CurrentThread`, not `nil`) — in any
process that never calls `Application.ProcessMessages` (console apps, services),
continuations queue indefinitely with no timeout signal.

**Note:** `TThread.Synchronize` is **not** a safe drop-in replacement — it is blocking
and would deadlock when called from inside an `Await` continuation. The current `Queue`
behaviour is the safer choice; the undocumented constraint is the real problem.

**Architect decision:** document the main-thread queue dependency in every `Await` overload's
`<remarks>` XML-doc; evaluate a `TAsync.RunBackground` variant for console/service contexts.

### 8. `TSafeTry._EndExecute` silently discards `&Finally` exceptions (MEDIUM)

Source comment at `SafeTry.pas:141`: `// Ignora exceções em Finally
silenciosamente`. Secondary failures are invisible.

**Architect decision:** surface secondary failures in `TSafeResult`, re-raise
after primary capture, or add explicit XML-doc warning.

### 9. `ModernSyntax.inc` carries LGPL v3 header (LOW / LEGAL)

`Source/ModernSyntax.inc` lines 1–16 declare GNU LGPL v3. All 16 `.pas` files
carry `SPDX-License-Identifier: MIT`. The `.inc` was not updated in the MIT
standardisation commit.

**Architect decision:** update lines 1–16 of `Source/ModernSyntax.inc` to MIT
SPDX header. One-line change; no code impact.

---

## Detail Files

All section files live under `.project/analysis/`. Links are bundle-absolute.

| File | Contents |
|------|----------|
| [00-intake](/analysis/00-intake.md) | Project identity, primary stack, unit size table, README claims vs. code |
| [01-structure](/analysis/01-structure.md) | Folder tree, entry points, test projects, build/test commands, platform targets |
| [02-stack](/analysis/02-stack.md) | Language/runtime, package managers, build system, RTL unit dependency table, DUnitX |
| [03-architecture](/analysis/03-architecture.md) | Module map, dependency DAG, key abstractions, data/control flows, cross-cutting concerns |
| [04-domain](/analysis/04-domain.md) | 19 entities, relationships, 10 business rules, 12 use cases |
| [05-conventions](/analysis/05-conventions.md) | Naming, error idioms, test style, recurring patterns, ADR candidates |
| [06-gaps-and-risks](/analysis/06-gaps-and-risks.md) | 15 findings with severity + evidence, 8 answered questions, 6 open questions |

Full consolidated dossier: [project-overview.md](project-overview.md).

---

## Open Questions

These survived a code-search attempt. Each entry records what was tried.

| # | Question | What was tried | Why still open |
|---|----------|----------------|----------------|
| OQ-1 | Is the LGPL header in `ModernSyntax.inc` an oversight or intentional? | Read git log for the MIT migration commit; `.inc` not mentioned; no follow-up commit found. | Requires author intent; no ADR or issue link in repo. |
| OQ-2 | Should `TFuture` and `TSafeResult` be unified? | Both definitions read; confirmed same `.IsOk`/`.IsErr` shape; no ADR or comment explaining the split found. | Product decision; breaking API change; both types serve distinct subsystems. |
| OQ-3 | What is the intended maximum concurrency for `TScheduler`? | Read `TScheduler` at `Coroutine.pas:122–160`; single background thread; no max-coroutine limit or queue-depth constant found. | Architectural intent for high-load use is unrecorded; requires product decision. |
| OQ-4 | Are the four untested units stable, experimental, or deprecated? | `grep -n "experimental\|deprecated\|unstable\|beta"` across all four units → 0 results. | Stability contract is undeclared; test scope cannot be set without this. |
| OQ-5 | Does the FMX/VCL compile-time toggle affect anything beyond `ModernSyntax.Objects`? | `grep -rn "HAS_FMX\|HAS_VCL" Source/*.pas` → **0** results (`HAS_FMX`/`HAS_VCL` are defined only in `ModernSyntax.inc:50,52`, not in any `.pas` file); only `Objects.pas` includes the `.inc`. | Whether the toggle was designed for future extension is undocumented. |
