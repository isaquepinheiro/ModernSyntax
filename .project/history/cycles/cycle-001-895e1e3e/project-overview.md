---
type: analysis
kind: artifact
title: "ModernSyntax — Project Overview"
description: "Architect-ready consolidated dossier: purpose, stack, structure, architecture, domain, conventions, constraints, and measured findings."
cycle: cycle-001-895e1e3e
agent: analyst
workflow: analyst-existing-project
node: synthesis
resource: aefos://run/895e1e3e3cd5c3c50b9218ed2a0b398c
generated:
  by: analyst-existing-project@node:synthesis
  at: "2026-08-27T00:00:00Z"
tags: [cycle-001, overview, modernsyntax, delphi, functional-programming]
sources:
  - id: intake
    resource: /analysis/00-intake.md
    title: "00 Intake — ModernSyntax"
  - id: structure
    resource: /analysis/01-structure.md
    title: "01 Structure — ModernSyntax"
  - id: stack
    resource: /analysis/02-stack.md
    title: "02 Stack — ModernSyntax"
  - id: architecture
    resource: /analysis/03-architecture.md
    title: "03 Architecture — ModernSyntax"
  - id: domain
    resource: /analysis/04-domain.md
    title: "04 Domain — ModernSyntax"
  - id: conventions
    resource: /analysis/05-conventions.md
    title: "05 Conventions — ModernSyntax"
  - id: gaps
    resource: /analysis/06-gaps-and-risks.md
    title: "06 Gaps and Risks — ModernSyntax"
---

# ModernSyntax — Project Overview

## Purpose

ModernSyntax is a source-only Object Pascal library that brings
functional-programming idioms to the Delphi RTL. It ships no executable;
its entire output is a set of units that downstream Delphi programs add to
their `uses` clause.

Confirmed: `Source/ModernSyntax.pas` line 4 header comment —
*"Functional programming toolkit and modern syntax extension for Delphi."*

---

## Stack

| Dimension | Value | Evidence |
|-----------|-------|----------|
| Language | Object Pascal (Delphi dialect) | all `.pas` files |
| Minimum compiler | Delphi XE (CompilerVersion 22, `VER220`) | `Source/ModernSyntax.inc` line 244 |
| Maximum in version table | Delphi 12 (CompilerVersion 36, `VER360`) | `Source/ModernSyntax.inc` line 56 |
| Lazarus/FPC | Minimal (`{$IFDEF FCP}` → `DELPHI14_UP` only); no FPC test projects | `Source/ModernSyntax.inc:256`; `find "Test Delphi" -name "*.lpr" | wc -l` → 0 |
| Runtime dependencies | **None** | `boss.json:8` `"dependencies": {}`; `pubdelphi.json:7` same |
| Package managers | Boss (`boss.json`) + PubDelphi (`pubdelphi.json`) | root files |
| Build system | Embarcadero MSBuild `.dproj` | `Examples/CurryingDemo.dproj:1` — MSBuild namespace |
| Test framework | DUnitX | `Test Delphi/EclbrSystem/PTestMatch.dpr:17–19` |
| Test output | NUnit XML (`dunitx-results.xml`) | both `EclbrSystem/` and `EclbrResultPair/` |
| VCL/FMX toggle | compile-time; VCL default; FMX off by `{.$DEFINE FMX}` | `Source/ModernSyntax.inc:49–54` |
| CI | **None** | `find . -name ".github" | wc -l` → 0 |

Key RTL units used (measured: `awk '/^uses/{found=1} found{print; if(/;/)exit}' Source/*.pas`):

| RTL unit | Units that import it |
|----------|---------------------|
| `SysUtils` | all 16 |
| `Rtti` | 9 of 16 (ArrowFun, Async, Coroutine, Currying, Match, Objects, Option, ResultPair, Safetry) |
| `Classes` | 10 of 16 |
| `Generics.Collections` | 9 of 16 |
| `SyncObjs` | 4 of 16 (Async, Coroutine, Currying, Objects) |
| `System.Threading` | Async, Coroutine, Stream |
| `Windows` | DotEnv (interface:22), Std (interface:21), Objects (implementation:161) — **unconditional, no `{$IFDEF MSWINDOWS}`** |

---

## Structure

Measured: `find . -maxdepth 3 -not -path './.git/*' | sort`; `ls Source/*.pas | wc -l` → 16; `wc -l Source/*.pas | tail -1` → **10 496** total lines.

```
.
├── Source/          — 16 .pas units + 1 .inc (17 files total)
├── Examples/        — 2 console demo programs (CurryingDemo, PCorrotina)
├── Test Delphi/
│   ├── EclbrSystem/ — 10 test runners; DCC.bat coverage script; TestMSGroup.groupproj
│   └── EclbrResultPair/ — 1 test runner (ResultPair)
├── boss.json        — Boss manifest; "mainsrc": "./Source" (line 6)
├── pubdelphi.json   — PubDelphi manifest; platforms Win32/Win64 (line 6)
├── boss-lock.json   — no installed modules
└── LICENSE          — MIT
```

### Source units — 16 units, sorted by size

(Measured: `wc -l Source/*.pas | sort -rn`)

| Unit | Lines | Primary type(s) |
|------|-------|----------------|
| `ModernSyntax.Currying` | 2 146 | `TCurrying`, `TPipeline<T>`, `TMemoizedCache<T,U>` |
| `ModernSyntax.Match` | 1 783 | `TMatch<T>`, `TMatch` (companion class) |
| `ModernSyntax.ResultPair` | 1 083 | `TResultPair<S,F>` |
| `ModernSyntax.Stream` | 756 | `TModernStreamReader` |
| `ModernSyntax.Objects` | 604 | `TModernObject`, `TSmartPtr<T>`, `TMutableRef<T>` |
| `ModernSyntax.Coroutine` | 585 | `TCoroutine`, `IScheduler`, `TScheduler` |
| `ModernSyntax.Option` | 486 | `TOption<T>` |
| `ModernSyntax.DotEnv` | 432 | `TDotEnv` |
| `ModernSyntax.Async` | 425 | `TAsync`, `TAutoLock` |
| `ModernSyntax.Tuple` | 365 | `TTuple<K>`, untyped `TTuple` |
| `ModernSyntax.Crypt` | 335 | `TCrypt`, `TPacket` |
| `ModernSyntax.Std` | 330 | `TStd`, `TPointerStream` |
| `ModernSyntax.RegExpression` | 328 | `TModernRegEx` (14 validators) |
| `ModernSyntax.ArrowFun` | 309 | `TArrow` |
| `ModernSyntax` (umbrella) | 288 | `TFuture`, `TSet<T>`, `IMSObserver` |
| `ModernSyntax.Safetry` | 241 | `TSafeTry`, `TSafeResult` |

### Test coverage (measured: `find "Test Delphi" -name "*.dpr" | wc -l` → 11 runners)

431 individual `[Test]` cases (measured: `grep -r '\[Test\]' "Test Delphi/" | wc -l` → 431).  
951 `Assert.*` call sites (measured: `grep -rn 'Assert\.' "Test Delphi/" | wc -l` → 951).

**Units with zero test runner:** `ModernSyntax.ArrowFun`, `ModernSyntax.Coroutine`, `ModernSyntax.Crypt`, `ModernSyntax.RegExpression` — combined 1 557 lines.  
(Confirmed: `find "Test Delphi" -name "*Coroutine*" -o -name "*Crypt*" -o -name "*Arrow*" -o -name "*RegExp*"` → no output.)

---

## Architecture

### Dependency graph (all edges confirmed in `uses` clauses)

```
Leaf / RTL-only nodes:
  ModernSyntax (umbrella)          ModernSyntax.ResultPair
  ModernSyntax.Safetry             ModernSyntax.Tuple
  ModernSyntax.Currying            ModernSyntax.RegExpression
  ModernSyntax.Objects  ← Windows (implementation only — Objects.pas:161)
  ModernSyntax.DotEnv   ← Windows (interface — DotEnv.pas:22)
  ModernSyntax.Std      ← Windows (interface — Std.pas:21)

Level 1 (one internal dep):
  ModernSyntax.Option    → ModernSyntax.ResultPair         (Option.pas:22)
  ModernSyntax.Crypt     → ModernSyntax.Std                (Crypt.pas:21)
  ModernSyntax.ArrowFun  → ModernSyntax.Std, ModernSyntax  (ArrowFun.pas:23–24)
  ModernSyntax.Async     → ModernSyntax                    (Async.pas:26)
  ModernSyntax.Coroutine → ModernSyntax                    (Coroutine.pas:26)
  ModernSyntax.Stream    → ModernSyntax.Objects, ModernSyntax (Stream.pas:22,24)

Level 2 (multiple internal deps):
  ModernSyntax.Match → ModernSyntax.Std, ModernSyntax.RegExpression,
                       ModernSyntax.ResultPair, ModernSyntax
                       (Match.pas:26–29)
```

No circular imports. The graph is a DAG. `ModernSyntax` (umbrella) and
`ModernSyntax.ResultPair` are the two shared roots. `ModernSyntax.Match` has
the most fan-in: 4 internal dependencies.  
`ModernSyntax.Currying` and `ModernSyntax.Tuple` are fully isolated from all
other library units (confirmed: `ModernSyntax.Currying.pas:18–27`,
`ModernSyntax.Tuple.pas:18–24`).

### Key abstractions

**`TFuture`** (`ModernSyntax.pas:32`) — value-type record holding `TValue` + error string + `FIsOK`/`FIsErr` flags. The async and coroutine result carrier. Not parameterised on error type.

**`TResultPair<S,F>`** (`ModernSyntax.ResultPair.pas:57`) — record tagged by `TResultType` enum (`rtNone/rtSuccess/rtFailure`, line 25). The typed Railway Pattern carrier. Carries callback arrays (`FSuccessFuncs`, `FFailureFuncs`). Three guard exceptions for misuse (lines 27–37). Used by `TMatch`, `TOption`.

**`TMatch<T>` + `TMatch`** (`Match.pas:63, 211`) — generic record for fluent multi-strategy matching; companion non-generic class holds result in `class var FMatch: TValue` (line 213) to work around Delphi value-copy semantics. **This class variable is unguarded — data race under concurrent use** (see G-01).

**`TAsync`** (`Async.pas:50`) — record wrapping `ITask` from `System.Threading`. Factory global functions `Async(TProc)` / `Async(TFunc<TValue>)` (lines 79–80). `.Await` returns `TFuture`. Continuations posted via `TThread.Queue` (lines 227, 271, 313) — main-thread message pump dependency.

**`IScheduler` / `TScheduler` / `TCoroutine`** (`Coroutine.pas:64, 101, 122`) — cooperative round-robin on a single background thread. `TCoroutine` states: `csActive → csPaused → csActive → csFinished` (terminal). Observer list via `TList<TCoroutine>` (line 73).

**`TSmartPtr<T>`** (`Objects.pas:80`) — RAII record wrapping a class instance via interface reference count. Consumed by `TModernStreamReader` for internal reader lifetime (three fields, `Stream.pas:42–44`).

**`TCurrying`** (`Currying.pas:163`) — 56 class functions (counted: `grep -c "class function" Source/ModernSyntax.Currying.pas` → 56). Includes `Compose`, `Partial`, `Memoize`, `Pipe`, `Curry`, `Map`, `Filter`, `Fold`, `GroupBy`, et al. `TMemoizedCache<T,U>` grows without bound — no eviction (see G-03).

**`TValue` as universal currency** — `Rtti.TValue` imported by 9 of 16 units; used in `TFuture`, `TMatch` case dictionary, `TCoroutine` value slots, `TArrow`, `TDotEnv`. Any value crossing a library boundary is RTTI-boxed.

### Three result carriers — no conversion path

| Type | Defined at | Used by |
|------|-----------|---------|
| `TFuture` | `ModernSyntax.pas:32` | `TAsync`, `TCoroutine` |
| `TResultPair<S,F>` | `ModernSyntax.ResultPair.pas:57` | `TMatch`, `TOption` |
| `TSafeResult` | `ModernSyntax.Safetry.pas:23` | `TSafeTry` only |

No adapter exists between any pair (confirmed: `grep -rn "TFuture\|TResultPair" Source/ModernSyntax.Safetry.pas` → 0; `grep -rn "TResultPair\|TSafeResult" Source/ModernSyntax.Async.pas` → 0). See G-07.

---

## Domain

**One actor:** the Delphi Developer (library consumer). No end-user, no admin role.

**19 public exported types** across 6 groups (measured: `grep -c "^  T[A-Za-z].*= \(record\|class\)" Source/ModernSyntax.*.pas` per file):

- **Functional core:** `TOption<T>`, `TResultPair<S,F>`, `TMatch<T>`, `TFuture`, `TSafeTry`, `TSafeResult`
- **Concurrency:** `TAsync`, `TCoroutine`, `IScheduler`/`TScheduler`
- **Higher-order:** `TCurrying`, `TPipeline<T>`, `TMemoizedCache<T,U>`, `TArrow`
- **Stream/collection:** `TModernStreamReader`, `TSet<T>`, `TTuple<K>`, untyped `TTuple`
- **Support:** `TModernObject`, `TSmartPtr<T>`, `TMutableRef<T>`, `TDotEnv`, `TStd`, `TCrypt`, `TModernRegEx`, `IMSObserver`

**10 business rules** confirmed in code (RN-001–RN-010 in [04-domain](/analysis/04-domain.md)).

**12 use cases** (UC-01–UC-12): null-safe handling, railway error propagation, multi-strategy matching, async task execution, coroutine scheduling, stream pipelines, partial application, memoization, safe exception handling, env-config loading, RTTI object construction, and Brazilian document validation.

---

## Conventions

### Naming (all confirmed by measurement)

| Element | Pattern | Confirmed at |
|---------|---------|-------------|
| Source units | `ModernSyntax.<Feature>.pas` | `ls Source/*.pas | wc -l` → 16, all match |
| Test units | `UTest<Feature>.pas` | `UTestMS.Option.pas:1` |
| Test runners | `PTest<Feature>.dpr` | `PTestOption.dpr` |
| Type prefix `T` | all public types | `TResultPair`, `TOption<T>` — `ResultPair.pas:23` |
| Interface prefix `I` | all interfaces | `IMSObserver` — `ModernSyntax.pas:12` |
| Exception prefix `E` | exception classes | `EFailureException<F>` — `ResultPair.pas:26` |
| Field prefix `F` | record/class fields | `FHasValue` — `SafeTry.pas:22–24` |
| Parameter prefix `A` | method parameters | `AValue`, `ASuccess` — `ResultPair.pas:70+` |
| Private methods `_` | implementation helpers | 101 such methods (`grep -rn 'procedure _\|function _' Source/ | wc -l` → 101) |

### File headers

All 16 `.pas` files carry `SPDX-License-Identifier: MIT` (confirmed: `grep -rn 'SPDX-License-Identifier' Source/ | wc -l` → 16).

### Error handling

Three independent idioms; no single mandate:
1. Railway (`TResultPair`) — primary for domain errors
2. Option (`TOption<T>`) — null-safety; bridges to `TResultPair` via `OkOr<F>`
3. Builder try/catch (`TSafeTry`) — returns `TSafeResult`

### Documentation

1 581 lines of `///` XML-doc triple-slash comments in `Source/` (measured: `grep -rn '///' Source/ | wc -l` → 1 581).

### Quality gates

**None automated.** No CI, no linter, no formatter. DUnitX is the only gate; run manually in IDE. NUnit XML output produced but not consumed by any pipeline.

---

## Constraints and assumptions

These are code-confirmed invariants the architect must preserve or explicitly overturn:

1. **Zero external runtime dependencies.** `boss.json:8` and `pubdelphi.json:7` both declare `"dependencies": {}`. All imports are Delphi RTL. Introducing a third-party dependency requires updating both manifests.

2. **Source-only library.** No compiled binary is distributed. Consumers add `./Source` to their Delphi library path (`boss.json:6` `"mainsrc": "./Source"`, `pubdelphi.json:5` `"sources": ["./Source/"]`).

3. **Delphi XE minimum.** `Source/ModernSyntax.inc:244` opens the `VER220` block. Code using generics, anonymous methods, and `TTask` (Delphi XE7+) must be guarded if the XE floor is to be maintained.

4. **No CI infrastructure.** Tests run manually. Any automation introduced must account for the absence of a Delphi compiler in a standard Linux CI image.

5. **Value-type record design.** Core types (`TFuture`, `TResultPair<S,F>`, `TAsync`, `TMatch<T>`, `TCurrying`, `TTuple<K>`, `TArrow`, `TSafeResult`) are Delphi records. Changes to their memory layout are ABI-breaking for consumers who compiled against the library.

6. **Boss + PubDelphi as sole distribution channels.** No NuGet, no GitHub Packages. `boss install ModernSyntax` is the documented install path.

---

## Findings — declared intent the code does not honour

Each finding states: the intent's location → a violating location → what it costs.

### CRITICAL

**F-01 / G-01 — `TMatch.FMatch` is an unguarded shared class variable (data race)**

Intent: `TMatch<T>` is a fluent API producing a result safely.  
Violation: `TMatch.FMatch: TValue` declared `class var` at `Match.pas:213`; written at `Match.pas:242` and read at `Match.pas:1652` with zero locking (`grep -n "SyncObjs\|TCriticalSection\|TMonitor" Source/ModernSyntax.Match.pas` → 0 results).  
Cost: Two threads calling pattern-matching simultaneously race on a single `TValue` slot; thread A may receive thread B's result. Silent data corruption.

### HIGH

**F-02 / G-02 — `Windows` unit imported unconditionally in interface section; six units blocked from cross-platform compilation**

Intent: README claims support for Win/Linux/macOS/iOS/Android.  
Violation: `ModernSyntax.Std.pas:21` and `ModernSyntax.DotEnv.pas:22` list `Windows` in their **interface** `uses` with no `{$IFDEF MSWINDOWS}` guard. Downstream units `Crypt` (line 21), `ArrowFun` (line 23), `Match` (line 26) inherit the dependency transitively. `ModernSyntax.Objects.pas:161` is in the implementation block only (lower blast radius). Total blocked: 6 of 16 units (37.5 %).  
Cost: Cross-platform compilation fails for those six units on any non-Windows target.

### MEDIUM-HIGH

**F-03 / G-03 — `TMemoizedCache` grows without bound**

Intent: `TCurrying.Memoize<T,U>` should cache pure function results for reuse.  
Violation: `TMemoizedCache<T,U>.FCache: TDictionary<T,U>` (`Currying.pas:136`) has no max-size, no eviction; `Cleanup` (`Currying.pas:1343`) is consumer-driven via `ICleanup`, never called internally (`grep -n "Cleanup\|ICleanup" Source/ModernSyntax.Currying.pas` → definition + one cast at line 906 that does not trigger cleanup).  
Cost: Long-running applications with large/unbounded input domains exhaust heap silently.

**F-04 / G-04 — 1 557 lines of production code with zero executable tests**

Intent: test suite covers all modules.  
Violation: `find "Test Delphi" -name "*Coroutine*" -o -name "*Crypt*" -o -name "*Arrow*" -o -name "*RegExp*"` → no output. `ModernSyntax.Coroutine` (585 lines), `ModernSyntax.Crypt` (335 lines), `ModernSyntax.ArrowFun` (309 lines), `ModernSyntax.RegExpression` (328 lines) have no `PTest*.dpr` and are absent from `DCC.bat`.  
Cost: No automated regression coverage for concurrency, cryptography, lambda, or regex/validation code.

**F-05 / G-05 — No CI pipeline**

Intent: NUnit XML output is configured per runner; `{$DEFINE CI}` stub exists at `PTestMatch.dpr:3`.  
Violation: `find . -name ".github" | wc -l` → 0; no `.yml`/`.yaml` CI config at repository root.  
Cost: Tests are gated on manual developer execution; regressions surface only when a developer runs the IDE.

### MEDIUM

**F-06 / G-06 — `TResultPair.rtNone` is undetectable (silent limbo state)**

Intent: `TResultPair.New` provides an empty starting point for the railway.  
Violation: `TResultPair<S,F>.New` calls `Create(rtNone)` (`ResultPair.pas:823`); `isSuccess` and `isFailure` both return `False` for `rtNone` (lines 680–685); `grep -n "IsNone\|isNone\|isNew" Source/ModernSyntax.ResultPair.pas` → 0 results.  
Cost: A consumer who forgets `.Success`/`.Failure` silently chains callbacks on a permanently inert container with no error signal.

**F-07 / G-07 — Three incompatible result carriers; no conversion path**

Intent: library provides a unified error-handling model.  
Violation: `TFuture` (umbrella), `TResultPair<S,F>` (ResultPair), `TSafeResult` (Safetry) serve overlapping roles; no adapter function exists (`grep -rn "TFuture\|TResultPair" Source/ModernSyntax.Safetry.pas` → 0; `grep -rn "TResultPair\|TSafeResult" Source/ModernSyntax.Async.pas` → 0).  
Cost: Consumer combining Async + Match + SafeTry must hand-write all three conversions.

**F-08 / G-08 — `TAsync` continuations depend on main-thread message pump (not a deadlock — an undocumented constraint)**

Intent: `TAsync.Await` delivers the result to the caller.  
Violation: `TThread.Queue` at `Async.pas:227, 271, 313` (all pass `TThread.CurrentThread`, not `nil`) posts continuations to the main-thread message loop. No XML-doc warning exists. Note: replacing `Queue` with `Synchronize` would itself cause deadlock inside an `Await` continuation — the current `Queue` behaviour is the safer choice.  
Cost: In console applications, services, or any thread that never pumps messages, continuations are silently queued indefinitely with no timeout signal.

**F-09 / G-09 — `TSafeTry._EndExecute` silently discards `&Finally`-handler exceptions**

Intent: `TSafeTry` captures all outcomes.  
Violation: `SafeTry.pas:128–141` catches exceptions inside the user `&Finally` handler and swallows them; source comment at line 141 reads `// Ignora exceções em Finally silenciosamente`.  
Cost: Secondary failures (e.g., resource-close errors) are invisible to the caller.

### LOW

**F-10 / G-10 — `IMSObserver` is dead code in the umbrella unit's public API**

`ModernSyntax.pas:27` declares `IMSObserver`; `grep -rn "IMSObserver" Source/*.pas` → 1 result (the definition). `TCoroutine` uses `TList<TCoroutine>` instead (`Coroutine.pas:73`). Cost: dead symbol in the public namespace; may mislead consumers.

**F-11 / G-11 — `ModernSyntax.inc` carries an LGPL v3 header (legal drift)**

All 16 `.pas` files carry `SPDX-License-Identifier: MIT` (`grep -rn 'SPDX-License-Identifier' Source/ | wc -l` → 16). `Source/ModernSyntax.inc` lines 1–16 declare GNU LGPL v3. Git commit `"docs: standardize and update headers in all .pas files to MIT"` named `.pas` only. Cost: ambiguous licensing for consumers who read the `.inc`.

**F-12 / G-12 — `{$I ModernSyntax.inc}` consumed by one unit; version symbols unavailable elsewhere**

`grep -rn '{\$I' Source/*.pas` → 1 result (`Objects.pas:16`). Any other unit adding a Delphi-version conditional must also add the include — a step easily overlooked. Cost: version-guard discipline degrades as the codebase grows.

**F-13 / G-13 — Umbrella unit does not re-export sub-units**

`ModernSyntax.pas` uses only `Rtti`, `SysUtils`, `Generics.Collections`, `Generics.Defaults` (lines 14–20). Consumers must individually list every sub-unit needed. Cost: friction for consumers trying the library for the first time.

**F-14 / G-14 — CPF/CNPJ validators are structural regex only; no checksum-digit verification**

`grep -n "mod\|Mod\|checksum\|digito\|verif" Source/ModernSyntax.RegExpression.pas` → 0 results. `IsMatchCPF` (line 138) and `IsMatchCNPJ` (line 149) pass structurally valid but checksum-invalid document numbers. Cost: false-positive validation results in document-number inputs.

**F-15 / G-15 — DUnitX version is uncontrolled**

`boss.json:8` and `boss-lock.json:4` declare empty dependencies and installed modules. DUnitX (`DUnitX.TestFramework` — `PTestMatch.dpr:17–19`) is not pinned. Cost: a breaking DUnitX release silently breaks the test suite with no lock-file warning.
