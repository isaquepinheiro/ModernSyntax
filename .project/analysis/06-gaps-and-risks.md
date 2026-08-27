---
type: analysis
title: "06 Gaps and Risks: ModernSyntax"
description: "Architect-ready dossier of open questions, assumptions, tech-debt hotspots, and verified findings from the discovery pass."
status: stable
tags: [gaps, risks, discovery, delphi, functional-programming, architect]
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
---

# ModernSyntax — Gaps and Risks

Each item carries: **severity**, the **command or file:line** that grounded the
finding, and (for open questions) what was tried before raising it. Nothing in
this document is taken from README, code comments, or prior documentation
without an independent code confirmation.

---

## Answered while looking

Items the analyst resolved during this pass. Recorded here so the architect
knows they were checked.

| # | Question | Resolution | Evidence |
|---|----------|------------|----------|
| AW-1 | Is `TMemoizedCache` thread-safe? | **Yes.** `FLock: TCriticalSection` guards both `GetOrAdd` and `Cleanup`. | `Source/ModernSyntax.Currying.pas:137` (field), `1355` (Lock.Enter in GetOrAdd), `1345` (Lock.Enter in Cleanup) |
| AW-2 | Does `TCoroutine` protect its state under concurrent access? | **Yes.** Both `TCoroutine` and `TScheduler` hold a `FLock: TCriticalSection` acquired on every state-mutating method. | `Source/ModernSyntax.Coroutine.pas:75, 143` (fields); `257, 274, 294, 318, 342, 362, 475` (acquire sites) |
| AW-3 | Does `TModernStreamReader` leak its internal streams? | **No.** `FListeners: TList` freed in `Destroy` (line 357); `FDataInternal`, `FDataString`, `FDataReader` are `TSmartPtr<T>` fields — freed by interface reference-count on scope exit. | `Source/ModernSyntax.Stream.pas:42–45, 355–357` |
| AW-4 | Is there any `isNone` / `IsUninitialized` method on `TResultPair`? | **No.** Only `isSuccess` and `isFailure` are public. Both return `False` for `rtNone`. No detection path exists. | `grep -n "IsNone\|rtNone" Source/ModernSyntax.ResultPair.pas` — `rtNone` appears only at line 25 (enum definition) and line 823 (constructor) |
| AW-5 | Does `Match.pas` import any threading primitive? | **No.** `uses` block (lines 18–29) contains no `SyncObjs`, `TMonitor`, or `TThread` reference; confirmed by `grep -n "SyncObjs\|TCriticalSection\|TMonitor" Source/ModernSyntax.Match.pas` → zero results. |  `Source/ModernSyntax.Match.pas:18–29` |
| AW-6 | Does `TMemoizedCache` have a size cap or eviction policy? | **No.** `FCache: TDictionary<T,U>` (line 136) grows without bound. `Cleanup` (line 1343) clears the cache only when called by the consumer via `ICleanup`; the library never calls it internally. | `Source/ModernSyntax.Currying.pas:136, 1343–1349` |
| AW-7 | Is the 56-class-function count in `TCurrying` correct? | **Yes.** `grep -c "class function\|class procedure" Source/ModernSyntax.Currying.pas` → **56** | confirmed |
| AW-8 | Does `TAsync` have any conversion to `TResultPair` or `TSafeResult`? | **No.** All `TAsync` public methods return `TFuture` (lines 67–72); no adapter to the other two carriers exists in the file or in any other source unit. | `Source/ModernSyntax.Async.pas:67–72`; `grep -rn "TResultPair\|TSafeResult" Source/ModernSyntax.Async.pas` → 0 results |

---

## Risk hotspots (tech-debt areas)

These are file-level areas where multiple risks concentrate, ranked by
combined severity.

| File:area | Concern count | Highest severity | Summary |
|-----------|--------------|-----------------|---------|
| `ModernSyntax.Match.pas` — `TMatch` class | G-01, G-07 | CRITICAL | Global class variable race + result-carrier impedance mismatch |
| `ModernSyntax.Std.pas` + `ModernSyntax.DotEnv.pas` — interface `uses` | G-02 | HIGH | Unconditional `Windows` import in interface block; five downstream units inherit the dependency transitively |
| `ModernSyntax.Currying.pas` — `TMemoizedCache` | G-03 | MEDIUM-HIGH | Unbounded cache growth; no max-size or eviction policy |
| `Test Delphi/` — Coroutine, Crypt, ArrowFun, RegExpression | G-04 | MEDIUM-HIGH | Zero executable tests for 1 557 lines of production code |
| `ModernSyntax.ResultPair.pas` — `rtNone` state | G-06 | MEDIUM | Silent uninitialized container with no detection method |
| `ModernSyntax.SafeTry.pas` — `_EndExecute` | G-09 | MEDIUM | Exceptions from `&Finally` handlers silently discarded |
| `ModernSyntax.pas` — `IMSObserver` | G-10 | LOW | Dead interface in public API namespace |
| `Source/ModernSyntax.inc` — license header | G-11 | LOW-LEGAL | LGPL v3 header contradicts MIT in all other files |

---

## Findings — Critical

### G-01 — `TMatch.FMatch` class variable is a thread-race hazard

**Severity: CRITICAL**

`TMatch` (companion class, not the generic record) declares:

```pascal
class var FMatch: TValue;   // ModernSyntax.Match.pas:213
```

This is a single slot shared by every `TMatch<T>` instance at process-wide
scope. When `TMatch<T>.Value(x)` is called it writes:

```pascal
TMatch.FMatch := TValue.From<TMatch<T>>(Result);   // Match.pas:242
```

and the terminal `TMatch.Value<T>` reads it back:

```pascal
Result := FMatch.AsType<TMatch<T>>.FValue.AsType<T>;   // Match.pas:1652
```

`Match.pas` imports no threading primitive
(`grep -n "SyncObjs\|TCriticalSection\|TMonitor" Source/ModernSyntax.Match.pas` → 0 results).
Two threads calling pattern-matching simultaneously write to and read from the
same `TValue` without serialisation: the result read by thread A may be the
result written by thread B. This is a data race in the strict sense.

**Architect decision needed:** (a) add a `TCriticalSection` around writes and
reads of `FMatch`; (b) replace the class variable with a local variable
threading the result through method parameters; or (c) document as
single-threaded only and add a `{$IFNDEF DELPHI_THREADING}` assertion.
Option (b) removes the class entirely and eliminates the root cause.

---

## Findings — High

### G-02 — `Windows` unit unconditionally imported in interface section of two units; six units blocked from non-Windows compilation

**Severity: HIGH**

Measured: `grep -n "Windows" Source/ModernSyntax.Std.pas Source/ModernSyntax.DotEnv.pas Source/ModernSyntax.Objects.pas`

| Unit | Section | Line | Symbol used |
|------|---------|------|-------------|
| `ModernSyntax.Std` | interface `uses` | 21 | `OutputDebugString` (in `DebugPrint`, `Std.pas:80`) |
| `ModernSyntax.DotEnv` | interface `uses` | 22 | `GetEnvironmentVariable` (OS env fallback, `DotEnv.pas:323`) |
| `ModernSyntax.Objects` | implementation `uses` | 161 | imported but unused — all `VirtualProtect` call sites are commented out (`Objects.pas:558,562,588,592`) |

`Std` and `DotEnv` place `Windows` in the **interface** uses block. Any unit
that `uses` either of them also drags in the Windows dependency — regardless
of whether the consumer runs on Windows. This blocks the following downstream
units from compiling on non-Windows targets:

- `ModernSyntax.Crypt` → via `ModernSyntax.Std` (`Crypt.pas:21`)
- `ModernSyntax.ArrowFun` → via `ModernSyntax.Std` (`ArrowFun.pas:23`)
- `ModernSyntax.Match` → via `ModernSyntax.Std` (`Match.pas:26`)

Total blocked: **6 of 16 units** (37.5 %). `pubdelphi.json` declares only
`Win32`/`Win64` (line 6), but the README claims Linux, macOS, iOS, and Android
support — a claim that is false for these units in their current form.

`ModernSyntax.Objects` confines `Windows` to the implementation block (line 161)
and is not transitively problematic.

**Architect decision needed:** wrap Windows-specific calls in
`{$IFDEF MSWINDOWS}` and provide RTL or POSIX alternatives
(`TTimeZone`, `GetEnvironmentVariable` from `System.SysUtils` for non-Windows),
or formally retract the cross-platform claim in README and `pubdelphi.json`.

---

## Findings — Medium-High

### G-03 — `TMemoizedCache` grows without bound; no eviction or size cap

**Severity: MEDIUM-HIGH**

`TMemoizedCache<T,U>` (confirmed `Source/ModernSyntax.Currying.pas:134`) stores
results in `FCache: TDictionary<T,U>` (line 136). `GetOrAdd` (line 1353) adds
each new key permanently. There is no max-size parameter, no LRU or TTL policy,
and no automatic eviction.

`Cleanup` (line 1343) calls `FCache.Clear` (line 1347) but is exposed only
through the `ICleanup` interface (`Source/ModernSyntax.Currying.pas:33–38`).
The library never calls `Cleanup` internally
(`grep -n "Cleanup\|ICleanup" Source/ModernSyntax.Currying.pas` → definition
and one call site at line 906 which merely casts `LCache` to `ICleanup` to hold
a reference — the cast does not trigger cleanup).

Long-running applications calling `TCurrying.Memoize` (line 214) with a large
or unbounded input domain will exhaust heap silently.

**Architect decision needed:** add an optional `MaxEntries` constructor
parameter and an LRU eviction path, or document that `TMemoizedCache` is
suitable only for inputs with bounded cardinality and expose `ICleanup.Cleanup`
in the public-facing API.

### G-04 — Four modules have zero test coverage

**Severity: MEDIUM-HIGH**

Confirmed: `find "Test Delphi" -name "*Coroutine*" -o -name "*Crypt*" -o -name "*Arrow*" -o -name "*RegExp*"` → no output.

| Unit | Lines | Risk |
|------|-------|------|
| `ModernSyntax.Coroutine` | 585 | Cooperative scheduler, observer notification, state machine — concurrency code with no test |
| `ModernSyntax.Crypt` | 335 | Base64 + MD5 — correctness-critical; no test |
| `ModernSyntax.ArrowFun` | 309 | Lambda factory over `TValue` — RTTI-heavy; no test |
| `ModernSyntax.RegExpression` | 328 | 12 domain validators including CPF/CNPJ — no test |

**Combined: 1 557 lines of production code with zero executable tests**
(not counted from docs — line counts from
`wc -l Source/ModernSyntax.Coroutine.pas Source/ModernSyntax.Crypt.pas Source/ModernSyntax.ArrowFun.pas Source/ModernSyntax.RegExpression.pas`
→ 585 + 335 + 309 + 328 = 1 557).

`DCC.bat` also omits these four units from code-coverage collection
(`Test Delphi/EclbrSystem/DCC.bat` — confirmed by reading the full file: only
13 named projects are present, none of the four above).

**Architect decision needed:** write `PTestCoroutine`, `PTestCrypt`,
`PTestArrow`, `PTestRegExpression` test projects; add them to the DCC.bat
coverage script; add them to `TestMSGroup.groupproj`.

### G-05 — No CI pipeline and no automated test runner

**Severity: MEDIUM-HIGH**

Confirmed: `find . -name ".github" | wc -l` → 0. No `.yml`, `.yaml`, CI
configuration, `Makefile`, or shell runner exists at repository root
(confirmed: `find . -maxdepth 2 -name 'Makefile' -o -name '*.yml' -o -name '*.yaml'` → no output).

DCC.bat (`Test Delphi/EclbrSystem/DCC.bat`) is Windows-only and covers only
13 of 21 testable targets. The NUnit XML output path is configured per runner
(`TDUnitX.Options.XMLOutputFile`) but no pipeline consumes it. Tests require
manual execution in the Delphi IDE or via `dcc32`/`dcc64` on a Windows machine.

A `{$DEFINE CI}` directive exists (commented out) at
`Test Delphi/EclbrSystem/PTestMatch.dpr:3` — it suppresses the end-of-run
key-press pause — but no pipeline activates it.

**Architect decision needed:** establish a CI workflow (GitHub Actions with
Delphi image, or a DANT/dcc32 script) that builds and runs all 11 test
projects and uploads NUnit XML as artefacts. Choose whether to run the
full 14-platform matrix or gate on Win64 only.

---

## Findings — Medium

### G-06 — `TResultPair.New` produces `rtNone` — no public detection method

**Severity: MEDIUM**

`TResultPair<S,F>.New` calls `Create(TResultType.rtNone)` (line 823). The
`rtNone` state means: neither success nor failure has been set. Both
`isSuccess` and `isFailure` return `False` for `rtNone` (lines 680–685 —
neither branch matches `rtNone`). There is no `isNew`, `IsNone`, or
`IsUninitialized` public method (confirmed: `grep -n "IsNone\|isNone\|isNew"
Source/ModernSyntax.ResultPair.pas` → 0 results).

A consumer who calls `TResultPair.New` and then forgets to call `.Success` or
`.Failure` will chain callbacks silently onto a container that executes nothing,
with no error or exception.

**Architect decision needed:** add a public `IsNone: Boolean` predicate and/or
a `{$WARN}` assertion in `ThenOf`/`ExceptOf` that raises when called on `rtNone`.

### G-07 — Three incompatible result carriers; no conversion path

**Severity: MEDIUM**

The library ships three independent result-carrier types:

| Type | Defined at | Used by |
|------|-----------|---------|
| `TFuture` | `ModernSyntax.pas:32` | `TAsync`, `TCoroutine` |
| `TResultPair<S,F>` | `ModernSyntax.ResultPair.pas:57` | `TMatch`, `TOption` |
| `TSafeResult` | `ModernSyntax.Safetry.pas:23` | `TSafeTry` only |

No conversion function exists between any two of them (confirmed:
`grep -rn "TFuture\|TResultPair" Source/ModernSyntax.Safetry.pas` → 0 results;
`grep -rn "TResultPair\|TSafeResult" Source/ModernSyntax.Async.pas` → 0 results — neither
file references the other carriers). A consumer building UC-04 (Async) + UC-03 (Match) +
UC-09 (SafeTry) must hand-write all three conversions.

**Architect decision needed:** define a common `IResult<T>` interface or adapter
record, or formally document which carrier is authoritative for each domain and
how to convert. `TFuture` and `TSafeResult` expose the same `.IsOk`/`.IsErr`
shape and are candidates for unification.

### G-08 — `TAsync` continuation delivery depends on main-thread message pump

**Severity: MEDIUM**

`TThread.Queue` (confirmed at `Source/ModernSyntax.Async.pas:227, 271, 313` — all three
pass `TThread.CurrentThread`, not `nil`) posts continuations to the main-thread message
loop. In a VCL/FMX application whose main thread is blocked (modal dialog, `Sleep`, or a
tight wait loop), the continuation is queued but never dispatched — a silent hang with no
timeout signal.

The source carries no warning comment and no documentation of this constraint.
The risk is highest in console applications and service processes that never
call `Application.ProcessMessages`.

**Note on mitigation:** `TThread.Synchronize` is **not** a safe replacement here —
`Synchronize` is blocking, and calling it from inside an `Await` continuation would
deadlock (the continuation blocks waiting for the main thread, while the main thread is
already blocked waiting for the continuation). This deadlock risk has not been measured;
the current `Queue` behaviour is the safer choice. The undocumented constraint is the
actual problem.

**Architect decision needed:** add a `<remarks>` XML-doc warning on every `Await` overload
documenting the main-thread queue dependency; evaluate a `TAsync.RunBackground: TFuture`
variant that avoids the main-thread queue entirely for use in console/service contexts.

### G-09 — `TSafeTry._EndExecute` silently discards `&Finally`-handler exceptions

**Severity: MEDIUM**

Confirmed at `Source/ModernSyntax.Safetry.pas:128–141`. The implementation
block catches any exception raised inside the user-supplied `&Finally` handler
and swallows it without surfacing it to the caller. Source comment at line 141
reads `// Ignora exceções em Finally silenciosamente` (translates: "Silently
ignores exceptions in Finally"). A secondary failure (e.g., a database
connection close that throws) is invisible to the caller, who receives only the
primary result.

**Architect decision needed:** expose secondary failures — either chain them
onto the returned `TSafeResult`, raise them after the primary result is captured,
or at minimum document the suppression explicitly in the public XML-doc
`<remarks>` block so consumers know they must handle their own Finally errors.

---

## Findings — Low

### G-10 — `IMSObserver` is dead code in the umbrella unit's public API

**Severity: LOW**

`IMSObserver` is declared at `Source/ModernSyntax.pas:27` with a single
`Update(Progress: Integer): Integer` method. Zero other source units reference
it (`grep -rn "IMSObserver" Source/*.pas` → 1 result, the definition itself).
`TCoroutine`'s observer mechanism uses `TList<TCoroutine>` (line 73) with
`Attach`/`Detach`/`ObserverNotify` (lines 87–89) — entirely unrelated.

This interface occupies the umbrella unit's public namespace and may mislead
consumers into implementing it expecting coroutine integration.

**Architect decision needed:** remove `IMSObserver`, connect it to `TCoroutine`
as the observer contract (replacing the `TList<TCoroutine>` pattern), or move
it to `ModernSyntax.Coroutine.pas` where it belongs semantically.

### G-11 — `ModernSyntax.inc` carries an LGPL v3 license header (legal drift)

**Severity: LOW / LEGAL**

All 16 `.pas` files carry `SPDX-License-Identifier: MIT` (confirmed:
`grep -rn "SPDX-License-Identifier" Source/ | wc -l` → 16). `SOURCE/ModernSyntax.inc`
lines 1–16 declare the GNU Lesser General Public License version 3. Git log
entry `"docs: standardize and update headers in all .pas files to MIT"` names
`.pas` files explicitly; the `.inc` file was not included in that commit.

Any consumer who reads `.inc` headers faces ambiguous licensing.

**Architect decision needed:** update `Source/ModernSyntax.inc` lines 1–16 to
the MIT SPDX header to match all other source files.

### G-12 — `{$I ModernSyntax.inc}` consumed by one unit; version symbols unavailable elsewhere

**Severity: LOW**

`Source/ModernSyntax.Objects.pas:16` is the only file that includes the
version-detection file (confirmed: `grep -rn '{\$I' Source/*.pas` → 1 result).
The symbols `DELPHI14_UP`, `DELPHI_XE_UP`, `DELPHI27_UP`, etc. are only
active inside `Objects`. Any other unit that adds a Delphi-version conditional
must also add the `{$I ModernSyntax.inc}` include — a step easily overlooked.

**Architect decision needed:** add `{$I ModernSyntax.inc}` to every source unit
as a convention, or move version-ladder detection into individual units that
need it and retire the include file.

### G-13 — Umbrella unit (`ModernSyntax.pas`) does not re-export sub-units

**Severity: LOW**

`ModernSyntax.pas` `uses` clause (lines 14–20) lists only RTL units
(`Rtti`, `SysUtils`, `Generics.Collections`, `Generics.Defaults`). It defines
`TFuture`, `TSet<T>`, and `IMSObserver` inline. No sub-unit is re-exported.
Consumers must explicitly list every sub-unit they need in their own `uses`
clause (confirmed: no `uses ModernSyntax.ResultPair` or similar in
`ModernSyntax.pas`).

For a library with 16 units and 19+ entity types, the absence of a convenience
aggregator adds friction.

**Architect decision needed:** evaluate whether to create a façade unit
`ModernSyntax.All.pas` that re-exports all sub-units, or document the
intended selective-import pattern explicitly.

### G-14 — Brazilian document validators are structural regex only (no checksum)

**Severity: LOW / CORRECTNESS**

`TModernRegEx.IsMatchCPF` (line 138) and `IsMatchCNPJ` (line 149) are pure
regular-expression checks. CPF (11 digits) and CNPJ (14 digits) have mandatory
modulo-11 check-digit algorithms under Brazilian Federal Revenue rules. A
structurally valid number that fails the checksum will pass `IsMatchCPF` /
`IsMatchCNPJ`.

Confirmed: `grep -n "mod\|Mod\|checksum\|digito\|verif" Source/ModernSyntax.RegExpression.pas` → 0 results.

**Architect decision needed:** add checksum-digit validation for CPF and CNPJ
(well-known public-domain algorithms), or rename the methods to
`IsMatchCPFFormat` / `IsMatchCNPJFormat` to signal structural-only intent.

### G-15 — DUnitX version is uncontrolled

**Severity: LOW**

`boss.json` and `boss-lock.json` declare `"dependencies": {}` and
`"installedModules": {}` respectively (confirmed at lines 8 and 4). DUnitX is
imported by every test project (`DUnitX.TestFramework` — confirmed
`PTestMatch.dpr:17–19`) but is not pinned to any version. Test suite
compilation depends on whichever DUnitX version ships with the developer's
Delphi installation. A breaking change in DUnitX's API would surface only at
compile time, with no lock-file indication.

**Architect decision needed:** either declare DUnitX as a Boss `dev-dependency`
with a specific version constraint, or document the minimum DUnitX version
required and add a `{$IF DUNITX_VERSION < N}` compile-time check.

---

## Open questions

These questions survived a code-search attempt. Each entry states what was
tried and why it remains open.

| # | Question | Tried | Why still open |
|---|----------|-------|----------------|
| OQ-1 | Is `ModernSyntax.inc` LGPL omission intentional or an oversight? | Read git log entry for the MIT migration commit; `.inc` not named. Checked for any follow-up commit mentioning `.inc`. | Requires author intent — no ADR or issue link found in the repository. |
| OQ-2 | Should `TFuture` and `TSafeResult` be unified into one type? | Read both definitions; confirmed same `.IsOk`/`.IsErr` shape. Searched for any comment or ADR explaining the split — none found. | Requires product decision; both types are used by distinct subsystems (`TAsync` vs `TSafeTry`). Unification is a breaking API change. |
| OQ-3 | What is the intended maximum concurrency for `TScheduler`? | Read `TScheduler` implementation (`ModernSyntax.Coroutine.pas:122–160`); the scheduler runs all coroutines on a single background thread. No max-coroutine limit or queue depth documented. | Architectural intent for high-load scenarios is unrecorded; requires product decision. |
| OQ-4 | Are the four untested units (`Coroutine`, `Crypt`, `ArrowFun`, `RegExpression`) considered stable or experimental? | No `status`, `@experimental`, or `deprecated` annotation found in any of the four units' file headers (confirmed: `grep -n "experimental\|deprecated\|unstable\|beta" Source/ModernSyntax.Coroutine.pas Source/ModernSyntax.Crypt.pas Source/ModernSyntax.ArrowFun.pas Source/ModernSyntax.RegExpression.pas` → 0 results). | Stability contract is undeclared; requires author clarification before tests are written. |
| OQ-5 | Does the FMX/VCL compile-time toggle (`{.$DEFINE FMX}` in `ModernSyntax.inc`) affect any unit other than `ModernSyntax.Objects`? | `{$I ModernSyntax.inc}` appears only in `Objects.pas` (confirmed). `HAS_FMX` and `HAS_VCL` are defined only in `ModernSyntax.inc` (`grep -rn "HAS_FMX\|HAS_VCL" Source/*.pas` → **0** results; `grep -rn "HAS_FMX\|HAS_VCL" Source/*.inc` → 2 results, the definitions themselves in `ModernSyntax.inc:50,52`). Since only Objects includes the `.inc`, the toggle currently affects only Objects. | Whether the toggle was designed for future extension is undocumented; requires architect clarification. |
