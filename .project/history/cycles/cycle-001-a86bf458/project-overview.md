---
type: analysis
kind: artifact
title: "Project overview — ModernSyntax"
description: "Consolidated architect-ready dossier: purpose, stack, structure, architecture, domain, conventions, constraints, assumptions, and measured drift findings."
cycle: cycle-001-a86bf458
agent: analyst
workflow: analyst-existing-project
node: synthesis
resource: aefos://run/a86bf45888f6ba01995864dedfeb1f9c
generated:
  by: "analyst-existing-project@node:synthesis"
  at: "2026-08-27T00:00:00Z"
tags:
  - cycle-001
  - analyst
  - overview
sources:
  - id: intake
    resource: /analysis/00-intake.md
    title: "00-intake: ModernSyntax shallow-pass"
  - id: structure
    resource: /analysis/01-structure.md
    title: "01-structure: folder tree, entry points, build/run/test/lint"
  - id: stack
    resource: /analysis/02-stack.md
    title: "02-stack: dependency manifest and runtime stack"
  - id: architecture
    resource: /analysis/03-architecture.md
    title: "03-architecture: module map, flows, abstractions"
  - id: domain
    resource: /analysis/04-domain.md
    title: "04-domain: entities, relationships, business rules, use cases"
  - id: conventions
    resource: /analysis/05-conventions.md
    title: "05-conventions: naming, layout, error handling, testing, patterns"
  - id: gaps
    resource: /analysis/06-gaps-and-risks.md
    title: "06-gaps-and-risks: open questions, assumptions, tech-debt"
---

# Project Overview — ModernSyntax

## 1. Purpose

ModernSyntax is a **Delphi functional-programming extension library** with zero external
dependencies. Its stated purpose (confirmed: `boss.json:2` name field; `pubdelphi.json:5`
`"kind": "runtime"`) is to bring functional-language idioms — pattern matching, Railway
error handling, option types, currying, async/await, and cooperative coroutines — to
Object Pascal / Delphi applications.

**Version:** 1.0.0 (confirmed: `boss.json:3`, `pubdelphi.json:3` — both agree).  
**License:** MIT (confirmed: `LICENSE:1`; `ModernSyntax.pas:9`).  
**Author:** Isaque Pinheiro (confirmed: `ModernSyntax.inc:23`).  
**Package registries:** Boss (`boss.json`) and PubDelphi (`pubdelphi.json`).  
**Published platforms:** Win32, Win64 (confirmed: `pubdelphi.json:7`).

There is no server runtime, no end-user interface, and no runtime external integration.
The sole actor is the **Delphi application developer** who includes `Source/` in their
IDE search path.

---

## 2. Stack

| Dimension | Detail | Measured from |
|---|---|---|
| Language | Object Pascal (Delphi) | `ls Source/*.pas \| wc -l` → 16 units |
| IDE / compiler | Embarcadero RAD Studio | `grep "Delphi.Personality" Examples/CurryingDemo.dproj` → `Delphi.Personality.12` |
| Declared compiler range | Delphi 2010 (VER210) – Delphi 12 (VER360) | `Source/ModernSyntax.inc:228–87` — VER210 lowest, VER360 highest |
| **Effective minimum** | Delphi XE7 (for `System.Threading` / `ITask`) | `Source/ModernSyntax.Async.pas:25`; `Source/ModernSyntax.Coroutine.pas:24` — `Threading` used unconditionally; Delphi-only unit (`System.Threading`). No FPC/Lazarus build exists (see R-04). |
| UI framework | VCL default; FMX opt-in via `{.$DEFINE FMX}` at `ModernSyntax.inc:46` | Commented out by default → `HAS_VCL` active; `HAS_FMX` / `HAS_VCL` consumed by zero `.pas` units (confirmed: `grep -rn "HAS_VCL\|HAS_FMX" Source/*.pas` → no output) |
| External dependencies | **Zero** | `boss.json`: `"dependencies": {}`; `boss-lock.json`: `"installedModules": {}`; `pubdelphi.json`: `"dependencies": {}` |
| RTL units consumed | 14 standard RTL units | `awk '/^uses/,/;/' Source/*.pas` — includes `Rtti`, `SysUtils`, `Classes`, `SyncObjs`, `Threading`, `Generics.Collections`, `RegularExpressions`, `Windows` (2 units unconditionally) |
| Test framework | DUnitX | `uses DUnitX.TestFramework` in every test unit; `[Test]` count: `grep -r "^\s*\[Test\]" "Test Delphi/" --include="*.pas" \| wc -l` → 468 |
| Coverage tool | CodeCoverage.exe (`-emma -xml -html`) | `Test Delphi/EclbrSystem/DCC.bat` |
| CI | None | `find . -name "*.yml" -not -path "./.git/*"` → no project-owned results |

---

## 3. Structure

```
Source/                        16 .pas + 1 .inc  (ls Source/*.pas | wc -l → 16)
Examples/                      2 demo projects   (ls Examples/*.dpr | wc -l → 2)
Test Delphi/
  EclbrSystem/                 10 .dpr + 18 .pas (ls "Test Delphi/EclbrSystem/"*.dpr | wc -l → 10)
  EclbrResultPair/             1 .dpr + 2 .pas   (ls "Test Delphi/EclbrResultPair/"*.dpr | wc -l → 1)
boss.json / boss-lock.json     Boss package manager
pubdelphi.json                 PubDelphi registry descriptor
LICENSE / README.md / SECURITY.md
```

**Total source lines:** `wc -l Source/*.pas Source/*.inc` → **10,766**.

### 3.1 Source modules (16 units — size order)

| Unit | Lines | Primary types |
|---|---|---|
| `ModernSyntax.Currying` | 2,146 | `TCurrying`, `TPipeline<T>`, `TMemoizedCache<T,U>`, `INumeric<T>` |
| `ModernSyntax.Match` | 1,783 | `TMatch<T>`, `TMatch`, `TCaseType` (17 variants) |
| `ModernSyntax.ResultPair` | 1,083 | `TResultPair<S,F>`, `TResultPairValue<T>`, `TResultType` |
| `ModernSyntax.Stream` | 756 | `TModernStreamReader` |
| `ModernSyntax.Objects` | 604 | `TModernObject`, `TSmartPtr<T>`, `TMutableRef<T>` |
| `ModernSyntax.Coroutine` | 585 | `IScheduler`, `TScheduler`, `TCoroutine`, `TCoroutineState` |
| `ModernSyntax.Option` | 486 | `TOption<T>`, `TSome`, `TNone` |
| `ModernSyntax.DotEnv` | 432 | `TDotEnv` |
| `ModernSyntax.Async` | 425 | `TAsync`, `IAutoLock`, `TAutoLock` |
| `ModernSyntax.Tuple` | 365 | `TTuple<K>`, `TTuple`, `TTupleDict<K>` |
| `ModernSyntax.Crypt` | 335 | `TCrypt`, `TPacket` |
| `ModernSyntax.Std` | 330 | `TStd`, `TPointerStream` |
| `ModernSyntax.RegExpression` | 328 | `TModernRegEx` |
| `ModernSyntax.ArrowFun` | 309 | `TArrow` |
| `ModernSyntax.pas` | 288 | `TFuture`, `TSet<T>`, `IMSObserver` |
| `ModernSyntax.Safetry` | 241 | `TSafeTry`, `TSafeResult` |
| `ModernSyntax.inc` | 270 | Compiler-version macros (include, not a unit) |

### 3.2 Build and test

There is no CLI build script for the library. Compilation is IDE-driven (MSBuild `.dproj`
files). Tests run per-project via DUnitX console runners. No CI; all gates are manual.

---

## 4. Architecture

### 4.1 Intra-library dependency graph

Measured by scanning `uses` clauses of all 16 units
(`for f in Source/*.pas; do awk '/^uses/,/;/' "$f"; done`).

```
No internal deps (pure RTL):
  ModernSyntax.Currying
  ModernSyntax.DotEnv
  ModernSyntax.Tuple
  ModernSyntax.SafeTry
  ModernSyntax.RegExpression
  ModernSyntax.Std
  ModernSyntax.ResultPair
  ModernSyntax.Objects

One internal edge:
  ModernSyntax.Option    → ModernSyntax.ResultPair   (Option.pas:22)
  ModernSyntax.Async     → ModernSyntax              (Async.pas:~18)
  ModernSyntax.Coroutine → ModernSyntax              (Coroutine.pas:~21)
  ModernSyntax.Crypt     → ModernSyntax.Std          (Crypt.pas:21)
  ModernSyntax.ArrowFun  → ModernSyntax.Std          (ArrowFun.pas:23)
                         → ModernSyntax              (ArrowFun.pas:24)

Two internal edges:
  ModernSyntax.Stream    → ModernSyntax.Objects      (Stream.pas:22)
                         → ModernSyntax              (Stream.pas:24)

Four internal edges (highest fan-in consumer):
  ModernSyntax.Match     → ModernSyntax.Std          (Match.pas:26)
                         → ModernSyntax.RegExpression(Match.pas:27)
                         → ModernSyntax.ResultPair   (Match.pas:28)
                         → ModernSyntax              (Match.pas:31)
```

**No cycles** found. Foundation units by inbound-reference count:
`ModernSyntax.pas` (5 importers), `ModernSyntax.Std` (3), `ModernSyntax.ResultPair` (2).

### 4.2 Primary data / control flows

**Async dispatch** (`ModernSyntax.Async`):
`Async(proc)` → `TAsync.Create` → `.Await(timeout)` → `_AwaitProc` → `TTask.Run(proc)`;
on success: `FResult.SetOk`; on error: `FResult.SetErr`; continuation marshalled via
`TThread.Queue(TThread.CurrentThread, …)` (Async.pas:227) or `TThread.Queue(nil, …)`
(Async.pas:271 — main thread). Returns `TFuture`.

**Coroutine scheduling** (`ModernSyntax.Coroutine`):
`TScheduler.New(sleepMs).Add(name, func, value).Run(errorProc)` → `TTask.Run(loop)`;
loop dequeues `TCoroutine`, calls `Func(sendValue, value)` → `TFuture`, checks
`TCoroutineState`, sleeps `FSleepTime`. One `ITask` drives all coroutines cooperatively.
Observer pattern within `TCoroutine` (Coroutine.pas:82–87): `Attach/Detach/Notify`.

**Pattern-matching dispatch** (`ModernSyntax.Match`):
`TMatch<T>.Value(x).CaseEq(v,proc)…Default(proc).Exec` accumulates arms into
`FCases: array[TCaseType] of TCaseGroup` (`Match.pas:74`); execution is lazy, triggered
on first arm match. Session state tracked in `TMatchSession` (Match.pas:55–57).
Regex arms delegate to `TModernRegEx`; `TryExcept` arm captures exceptions into
`TResultPair`.

**Option → ResultPair bridge** (`Option.pas:389–394`):
`TOption<T>.OkOr<F>(failure)` converts to `TResultPair<T,F>`:
`IsSome` → `TResultPair.Success(FValue)`; `IsNone` → `TResultPair.Failure(failure)`.

### 4.3 Cross-cutting concerns

| Concern | Detail | Evidence |
|---|---|---|
| `TValue` as universal carrier | 12 of 16 units import `Rtti` and use `TValue` | `grep -c "Rtti" Source/*.pas \| grep -v ":0"` → 12 |
| `System.Threading` / `TTask` | Both `Async` and `Coroutine` use `TTask.Run`; `TCriticalSection` guards `TMemoizedCache`, `TScheduler`, `TAsync` | Async.pas:213,260; Coroutine.pas:439 |
| Windows API coupling | `DotEnv` and `Std` import `Windows` unconditionally | DotEnv.pas:21; Std.pas:67 |
| Class-level mutable state | `TArrow.FValue`, `TStd.FSequenceCounter` — no synchronization; `TModernObject.FContext` — guarded | ArrowFun.pas:39; Std.pas:41; Objects.pas:41 |
| Records for API, classes for state | Public entry points are records (stack-allocated); mutable internals are classes or `TInterfacedObject` descendants | Consistent across all 16 units |
| Interface-ARC lifetime | 22 `TInterfacedObject` descendants; callers hold interface references | `grep -rn "TInterfacedObject" Source/*.pas \| wc -l` → 22 |

---

## 5. Domain

ModernSyntax has no persisted entities, no users, and no network boundary at runtime.
All domain concepts are language-level abstractions.

### 5.1 Core entities (summary — full detail in [/analysis/04-domain.md](/analysis/04-domain.md))

| Entity | Kind | Key contract |
|---|---|---|
| `TFuture` | record | Carries `TValue` payload OR `String` error; states mutually exclusive (RN-001) |
| `TResultPair<S,F>` | record | Railway monad — 42 public methods; `New` starts in `rtNone`; transitions are one-way (RN-003) |
| `TOption<T>` | record | `Some(v)` / `None`; bridges to `TResultPair` via `OkOr<F>` (RN-002; Option.pas:389–394) |
| `TMatch<T>` | record | 17-variant dispatch table (TCaseType); arms accumulated lazily; dispatched on `Exec` (RN-004) |
| `TCurrying` | record | 28 class functions; `TPipeline<T>` for fluent value threading; `TMemoizedCache<T,U>` for thread-safe memoization (RN-007) |
| `TAsync` | record | Wraps `ITask`; `Run`/`NoAwait` = fire-and-forget; `Await(timeout)` = blocking; returns `TFuture` |
| `TCoroutine` / `IScheduler` | class sealed / interface | Cooperative scheduler; one `ITask` drives all coroutines; lifecycle linear (RN-005) |
| `TSmartPtr<T>` | record | RAII wrapper; inner `TInterfacedObject` carries ref count (RN-008) |
| `TSafeTry` | record | Fluent `try/except` wrapper; `End` always executes `Finally` (RN-009) |
| `TDotEnv` | class | Parses `.env` files; falls back to OS environment by default (RN-006) |
| `TModernObject` | class sealed | RTTI factory via `TRttiContext`; class-level context cached (Objects.pas:41) |
| `TArrow` | record | Function factory; `class var FValue: TValue` — deliberate singleton (ArrowFun.pas:39 comment); **no thread guard** |
| `TStd` | class | Lazy singleton; `FSequenceCounter: Int64` incremented by non-atomic `Inc` |

### 5.2 Confirmed business rules

Nine rules confirmed by code; full citations in [/analysis/04-domain.md](/analysis/04-domain.md) §4.

| ID | Rule |
|---|---|
| RN-001 | `TFuture` success and error states are mutually exclusive (`ModernSyntax.pas:205–213`) |
| RN-002 | `TOption.None` carries no value; `Some` requires a value (confirmed at `Option.pas:391–394`) |
| RN-003 | `TResultPair.New` starts `rtNone`; transitions are one-way (`ResultPair.pas:821–823`, `573–578`) |
| RN-004 | `TMatch` dispatches through a fixed 17-variant table (`Match.pas:74`) |
| RN-005 | Coroutine lifecycle is linear; finished coroutines do not resume (`Coroutine.pas:34–36`) |
| RN-006 | `TDotEnv` falls through to OS env by default; opt-out via `AUseSystemFallback:=False` (`DotEnv.pas:323,373`) |
| RN-007 | `TMemoizedCache` caches by input; thread-safe via `TCriticalSection` (`Currying.pas:157`) |
| RN-008 | `TSmartPtr<T>` lifetime is interface-reference-counted (`Objects.pas:78`) |
| RN-009 | `TSafeTry.End` always executes `Finally`, regardless of exception (`Safetry.pas:_EndExecute`) |

---

## 6. Conventions

### 6.1 Naming (measured)

| Prefix | Applies to | Count |
|---|---|---|
| `T` | Classes + records | `grep -rn "= record\b" Source/*.pas \| wc -l` → 23 records; `grep -rn "= class\b\|= class(" Source/*.pas \| wc -l` → 35 classes |
| `I` | Interfaces | `grep -rn "^  I[A-Z]" Source/*.pas` → 10 |
| `E` | Exception classes | `grep -rn "class(Exception)" Source/*.pas \| wc -l` → 3 |
| `F` | Private fields | Pervasive — every class/record sampled |
| `A` | Method parameters | `A` prefix confirmed throughout all sampled units |
| `L` | Local variables | Confirmed (`Match.pas:153` — `LTuple1`, `LTuple2`) |
| `_` | Private helper methods | `grep -rn "procedure _\|function _" Source/*.pas \| wc -l` → 156 |

**Inconsistencies found:** `isSuccess`/`isFailure` (lowercase `is` at `ResultPair.pas:447,455`)
vs `IsSome`/`IsNone` (PascalCase `Is`). Two constant styles: `C_SCREAMING_SNAKE`
(`Coroutine.pas:132`) vs bare `SCREAMING_SNAKE` (`Match.pas:221–230`).

### 6.2 Patterns (measured)

- **Fluent/method-chaining:** every primary type returns `Self`-typed result for chaining.
- **Anonymous methods as first-class values:** 329 occurrences
  (`grep -rn "reference to function\|reference to procedure\|TFunc<\|TProc<" Source/*.pas | wc -l` → 329).
- **133 overloaded declarations** distinguish proc vs func arities
  (`grep -rn "overload;" Source/*.pas | wc -l` → 133).
- **`class sealed`** on 4 types: `TCoroutine`, `TGather<T>`, `TModernObject`, `TSet<T>`.
- **Static `New`/`Value` factory methods** as named constructor alternatives.
- **`inline;` on 225 declarations** (`grep -rn "inline;" Source/*.pas | wc -l` → 225).

### 6.3 Testing (measured)

- 14 `[TestFixture]` classes; 468 `[Test]` methods; 951 `Assert.` calls.
- Zero legacy `CheckEquals`/`CheckTrue` (DUnit style).
- No mocking framework; test doubles are hand-rolled.
- 4 modules without any test project: `ModernSyntax.Coroutine`, `ModernSyntax.Crypt`,
  `ModernSyntax.RegExpression`, `ModernSyntax.ArrowFun`.

### 6.4 Error handling

35 bare `raise Exception.Create(…)` calls across 11 units
(`grep -rn "raise Exception\b" Source/*.pas | wc -l` → 35).
Only `ModernSyntax.ResultPair` defines typed exceptions (3: `EFailureException<F>`,
`ESuccessException<S>`, `ETypeIncompatibility` — lines 27, 31, 35).
Callers cannot catch ModernSyntax-specific errors by type without catching all Delphi exceptions.

---

## 7. Constraints and assumptions

### Confirmed constraints (code-backed)

1. **Zero external runtime dependencies.** All three manifests confirm empty dependency sets.
   The library compiles against Delphi RTL exclusively.
2. **Source-distribution model.** `pubdelphi.json:5` — `"kind": "runtime"` with `"sources": ["./Source/"]`.
   Consumers add `Source/` to their IDE search path; there is no compiled output.
3. **No circular imports.** The intra-library dependency graph is a DAG confirmed by the
   uses-clause scan.
4. **Record-for-API, class-for-state pattern.** All 16 units follow this consistently;
   any new public API type should be a record for ergonomic stack allocation.

### Assumptions made during analysis

- `Threading` (bare name, `Async.pas:25`, `Coroutine.pas:24`) resolves to `System.Threading`
  under Delphi's default namespace search. Confirmed indirectly: no local `Threading.pas`
  (`find . -name "Threading.pas"` → no result).
- Active development IDE is Delphi 12 (`Delphi.Personality.12` in all sampled `.dproj` files).
- `TResultPair.FSuccessFuncs`/`FFailureFuncs` are populated by chaining methods at
  `ResultPair.pas:763–764, 927–928`; the exact public method names calling those lines
  were not confirmed (lines lie inside larger method bodies).
- `libFastMM_FullDebugMode.dylib` in `Test Delphi/EclbrSystem/` is a historical artefact;
  no active macOS CI exists.

---

## 8. Findings — declared intent the code does not honour

Each finding names the intent source (with line), a code line that violates it, and its cost.

### F-01 — `.inc` header cites LGPL; governing license is MIT
**Intent:** `Source/ModernSyntax.inc:6–8` — LGPL v3 text.
**Code:** `LICENSE:1` — MIT License. `ModernSyntax.pas:9` — MIT. `README.md` badge — MIT.
**Cost:** Legal ambiguity for consumers who read the header rather than `LICENSE`.

### F-02 — README claims cross-platform (Win/Linux/macOS/iOS/Android); published and code say Win32/Win64
**Intent:** `README.md:28` — "VCL, FMX, Console (Win/Linux/macOS/iOS/Android)".
**Code:** `pubdelphi.json:7` — `["Win32","Win64"]`. `DotEnv.pas:21` and `Std.pas:67` — `uses Windows` unconditionally. No platform-conditional guards in either unit.
**Cost:** Any non-Windows build breaks at compile time, not runtime. The README claim is unverifiable.

### F-03 — FMX switch is inert; README treats FMX as equal to VCL
**Intent:** `ModernSyntax.inc:46` — `{.$DEFINE FMX}` (commented-out mechanism implies FMX is available).
**Code:** `grep -rn "HAS_VCL\|HAS_FMX" Source/*.pas` → no output. No `.pas` unit reads either define.
**Cost:** Activating FMX mode produces zero compile-time difference. FMX support is promised but not implemented.

### F-04 — `TArrow.FValue` class var is an unguarded process-global slot
**Intent:** `ArrowFun.pas:39` comment: "Internal storage for the last processed value" — deliberate design.
**Code:** `grep -n "Critical\|Lock\|Interlocked" Source/ModernSyntax.ArrowFun.pas` → 0 results. Two concurrent `TTask` closures calling `TArrow.Fn` produce a data race.
**Cost:** Correctness failure under concurrent use. The library's own `TAsync`/`TCoroutine` create concurrent task contexts.

### F-05 — `TStd.GenerateSequentialNumber` uses non-atomic `Inc`
**Intent:** Method name implies monotonically unique values.
**Code:** `Std.pas:58` — `Inc(FSequenceCounter)`. No `TInterlocked.Increment`. 64-bit `Inc` is not atomic on 32-bit targets.
**Cost:** Duplicate sequence numbers under concurrent use; undefined behaviour on Win32 targets.

### F-06 — `IMSObserver` is declared but never implemented or consumed
**Intent:** `ModernSyntax.pas:27` — a public observer interface with GUID.
**Code:** `grep -rn "IMSObserver" Source/*.pas` → one hit (declaration only). Two observable types (`TCoroutine`, `TModernStreamReader`) use ad-hoc incompatible callback types.
**Cost:** Dead public interface surface in the foundation unit; the intended extension point cannot be used as designed.

### F-07 — `System.Threading` imported but unused in `ModernSyntax.Stream`
**Intent:** Import at `Stream.pas:23` implies concurrent stream processing.
**Code:** `grep -n "TTask\|ITask\|TThread" Source/ModernSyntax.Stream.pas` → no output. The unit runs fully synchronously.
**Cost:** Misleading import; dead code; unnecessary dependency on a platform-specific unit.

### F-08 — `.inc` header claims Delphi 2010 (VER210) minimum; code requires XE7
**Intent:** `ModernSyntax.inc:228` — VER210 (Delphi 2010) block is the lowest defined.
**Code:** `ModernSyntax.Async.pas:25`, `ModernSyntax.Coroutine.pas:24` — `Threading` (`System.Threading`, `ITask`/`TTask`) used unconditionally. `System.Threading` requires Delphi XE7. Anonymous methods used in 329 places require Delphi 2009+.
**Cost:** Any attempt to compile against Delphi 2010 fails; the version support claim is false.

### F-09 — `DCC.bat` coverage script references 7 non-existent test projects
**Intent:** `Test Delphi/EclbrSystem/DCC.bat` — lists 14 named projects for coverage runs.
**Code:** `ls "Test Delphi/EclbrSystem/"*.dpr | wc -l` → 10. Missing: `PTestDictionary`, `PTestVector`, `PTestMap`, `PTestList`, `PTestStr`, `PTestDirectory`, `PTestThreading`.
**Cost:** Coverage script fails at first missing project; coverage reports cannot be generated via the provided tooling.

### F-10 — 8 test units import absent external libraries
**Intent:** 8 units in `Test Delphi/EclbrSystem/` (e.g. `UTestEcl.Dictionary.pas:9–10`) import `Fluent.Core`, `Fluent.Collections`, `ecl.ifthen`.
**Code:** `ls Source/` → only `ModernSyntax.*`. `boss.json` `"dependencies": {}` — these libraries are not declared.
**Cost:** 8 test units cannot compile; they inflate the apparent test-unit count without contributing tests.

### F-11 — `FSuccessFuncs`/`FFailureFuncs` in `TResultPair` appeared vestigial but are active
**Prior finding (04-domain §F-04):** appeared to have no population site.
**Resolved (06-gaps §A-01):** write sites at `ResultPair.pas:763–764, 927–928`; read sites at lines 638–640, 659–661. These arrays implement a multi-callback chain for `ThenOf`/`ExceptOf`. **Not a finding — resolved.** Noted here to close the prior open report.

---

## 9. Tech-debt register (full — prioritised)

Source: [/analysis/06-gaps-and-risks.md](/analysis/06-gaps-and-risks.md).

| # | Area | Severity | File : line |
|---|---|---|---|
| TD-01 | TArrow class-var data race | **High** | `ArrowFun.pas:39,98` |
| TD-02 | Non-atomic TStd sequence counter | **High** | `Std.pas:41,58` |
| TD-03 | Windows API unconditional in DotEnv | **High** | `DotEnv.pas:21,373,415,420,427` |
| TD-04 | Windows API unconditional in Std | **High** | `Std.pas:67,80` |
| TD-05 | FPC/Lazarus: sem build; bloco `{$IFDEF FCP}` morto (typo); `Threading` exigiria condicional num porte futuro | Low | `ModernSyntax.inc:255–258`; `Async.pas:25`; `Coroutine.pas:24` |
| TD-06 | 4 modules with no test project | Medium | `Test Delphi/EclbrSystem/` |
| TD-07 | No CI pipeline | Medium | repo root |
| TD-08 | DCC.bat references 7 absent projects | Medium | `Test Delphi/EclbrSystem/DCC.bat` |
| TD-09 | 8 orphaned test units | Medium | `Test Delphi/EclbrSystem/UTestEcl.*.pas` |
| TD-10 | HAS_VCL/HAS_FMX switch inert | Medium | `ModernSyntax.inc:50,52` |
| TD-11 | IMSObserver unused | Low | `ModernSyntax.pas:27` |
| TD-12 | System.Threading unused import | Low | `Stream.pas:23` |
| TD-13 | 35 bare Exception.Create raises | Low | 11 source units |
| TD-14 | isSuccess/isFailure naming | Low | `ResultPair.pas:447,455` |
| TD-15 | Dual constant style | Low | `Coroutine.pas:132`, `Match.pas:221` |
| TD-16 | 135 commented-out code lines | Low | `ArrowFun.pas:66–279`, `Objects.pas:532,565` |
| TD-17 | XML doc coverage uneven | Low | `ArrowFun.pas`, `Crypt.pas`, `Stream.pas` |
| TD-18 | .inc header cites LGPL; LICENSE is MIT | Low | `ModernSyntax.inc:6–8`, `LICENSE:1` |
