---
type: analysis
title: "03 Architecture: ModernSyntax"
description: "Module map, dependency graph, key abstractions, primary data/control flows, and cross-cutting concerns for the ModernSyntax library."
status: stable
tags: [architecture, discovery, delphi, functional-programming, dependency-graph]
sources:
  - id: structure
    resource: /analysis/01-structure.md
    title: "01 Structure — ModernSyntax"
  - id: stack
    resource: /analysis/02-stack.md
    title: "02 Stack — ModernSyntax"
---

# ModernSyntax — Architecture

## 1. Module Map

16 source units (measured: `ls Source/*.pas | wc -l` → 16). Each row below states the unit's responsibility and its **internal** dependencies — imports of other `ModernSyntax.*` units only, derived from the `uses` clause of each file (confirmed line numbers given for every edge).

| Unit | Responsibility | Internal deps (file:line) |
|---|---|---|
| `ModernSyntax` (umbrella) | Defines `TFuture` (result carrier), `TSet<T>` (dictionary-backed set), `Tuple` type alias, `IMSObserver` interface | none |
| `ModernSyntax.ResultPair` | `TResultPair<S,F>` — typed success/failure sum type; Railway Pattern foundation | none |
| `ModernSyntax.Safetry` | `TSafeTry` — exception-to-result bridge; wraps a block in a `TFuture`-like `TSafeResult` | none |
| `ModernSyntax.Tuple` | `TTuple<K>` generic + 13 concrete aliases (`TTupluString`, `TTupluInteger`, …) | none |
| `ModernSyntax.Currying` | `TCurrying` partial-application record; `TPipeline<T>` combinator; `TMemoizedCache<T,U>`; 14 `INumeric<T>` implementors for numeric types | none |
| `ModernSyntax.RegExpression` | Thin class wrapper over RTL `RegularExpressions`; exposes `TModernRegEx` | none |
| `ModernSyntax.Objects` | `TModernObject` (RTTI factory); `TSmartPtr<T>` (RAII smart-pointer record); `IAutoRefLock`/`TAutoRefLock` (ref-counted lock) | none (Windows imported in **implementation** section only — `ModernSyntax.Objects.pas:161`) |
| `ModernSyntax.DotEnv` | `TDotEnv` — `.env` file parser; loads key/value pairs into a `TDictionary`; supports system-env fallback via `Windows.GetEnvironmentVariable` | none (Windows in **interface** uses — `ModernSyntax.DotEnv.pas:22`) |
| `ModernSyntax.Std` | `TStd` singleton — string/date/number utilities; `TPointerStream`; global `DebugPrint`; imports `Windows` unconditionally | none (Windows in **interface** uses — `ModernSyntax.Std.pas:21`) |
| `ModernSyntax.Option` | `TSome`/`TNone` optional type; bridges absent values to `TResultPair` | `ModernSyntax.ResultPair` (`ModernSyntax.Option.pas:22`) |
| `ModernSyntax.Crypt` | `TCrypt` record — Base64 encode/decode, MD5 hash; `TPacket` union variant record | `ModernSyntax.Std` (`ModernSyntax.Crypt.pas:21`) |
| `ModernSyntax.ArrowFun` | `TArrow` record — lambda helpers operating on `TValue`; side-effect combinators | `ModernSyntax.Std` (`ModernSyntax.ArrowFun.pas:23`), `ModernSyntax` (`ModernSyntax.ArrowFun.pas:24`) |
| `ModernSyntax.Async` | `TAsync` record — wraps `ITask` from `System.Threading`; factory function `Async(TProc)`/`Async(TFunc<TValue>)` (lines 79–80); returns `TFuture` from `.Await`/`.Run` | `ModernSyntax` (`ModernSyntax.Async.pas:26`) |
| `ModernSyntax.Coroutine` | `TCoroutine` (stateful coroutine node with observer list); `IScheduler`/`TScheduler` (cooperative round-robin driver) | `ModernSyntax` (`ModernSyntax.Coroutine.pas:26`) |
| `ModernSyntax.Stream` | `TModernStreamReader` — file/string stream with fluent Map/Filter/Reduce; uses `TSmartPtr<T>` for internal reader lifetime | `ModernSyntax.Objects` (`ModernSyntax.Stream.pas:22`), `ModernSyntax` (`ModernSyntax.Stream.pas:24`) |
| `ModernSyntax.Match` | `TMatch<T>` record — fluent pattern matcher (equality, guard, range, regex, type-check, try/except); `TMatch` class stores inter-step result via class variable | `ModernSyntax.Std` (`ModernSyntax.Match.pas:26`), `ModernSyntax.RegExpression` (`ModernSyntax.Match.pas:27`), `ModernSyntax.ResultPair` (`ModernSyntax.Match.pas:28`), `ModernSyntax` (`ModernSyntax.Match.pas:29`) |

---

## 2. Dependency Graph

Arrows mean "imports" — each edge was confirmed in the `uses` clause of the source file.

```
RTL only (leaf nodes)
  ModernSyntax (umbrella)
  ModernSyntax.ResultPair
  ModernSyntax.Safetry
  ModernSyntax.Tuple
  ModernSyntax.Currying
  ModernSyntax.RegExpression
  ModernSyntax.Objects    ← Windows (impl-section only)
  ModernSyntax.DotEnv     ← Windows (interface)
  ModernSyntax.Std        ← Windows (interface)

Level 1 (one internal dependency)
  ModernSyntax.Option     → ModernSyntax.ResultPair
  ModernSyntax.Crypt      → ModernSyntax.Std
  ModernSyntax.ArrowFun   → ModernSyntax.Std, ModernSyntax
  ModernSyntax.Async      → ModernSyntax
  ModernSyntax.Coroutine  → ModernSyntax
  ModernSyntax.Stream     → ModernSyntax.Objects, ModernSyntax

Level 2 (multiple internal dependencies)
  ModernSyntax.Match      → ModernSyntax.Std, ModernSyntax.RegExpression,
                            ModernSyntax.ResultPair, ModernSyntax
```

No circular imports exist: the graph is a DAG with `ModernSyntax` (umbrella) and `ModernSyntax.ResultPair` as shared roots, and `ModernSyntax.Match` as the unit with the most fan-in (4 internal imports, confirmed above).

`ModernSyntax.Currying` and `ModernSyntax.Tuple` are fully isolated from all other library units (no `ModernSyntax.*` line in their `uses` clauses, confirmed: `ModernSyntax.Currying.pas:18-27`, `ModernSyntax.Tuple.pas:18-24`).

---

## 3. Key Abstractions

### 3.1 `TFuture` — universal async/error carrier
`Source/ModernSyntax.pas:32`. A value-type record holding a `TValue` (`FValue`), an error string (`FErr`), and two boolean flags (`FIsOK`, `FIsErr`). `SetOk`/`SetErr` are mutually exclusive setters (lines 209–214); `Ok<T>` casts via `TValue.AsType<T>` and raises if not OK (lines 195–200). Used as the return type of `TAsync.Await` (confirmed: `ModernSyntax.Async.pas:67-68`) and `TCoroutine` function bodies (confirmed: `ModernSyntax.Coroutine.pas:32` — `TFuncCoroutine = reference to function(...): TFuture`).

### 3.2 `TResultPair<S,F>` — typed Railway Pattern
`Source/ModernSyntax.ResultPair.pas:57`. A `strict private` record (Delphi value type) carrying `TResultPairValue<S>` and `TResultPairValue<F>` pair fields plus two callback arrays (`FSuccessFuncs`, `FFailureFuncs`). Three exceptions handle misuse: `EFailureException<F>`, `ESuccessException<S>`, `ETypeIncompatibility` (lines 27–37). `TResultType` enum (`rtNone, rtSuccess, rtFailure`, line 25) tracks state. Unlike `TFuture`, this type is parameterised on both success and failure, making it the typed variant.

### 3.3 `TMatch<T>` + `TMatch` — fluent pattern matcher
`Source/ModernSyntax.Match.pas:63` (generic record) and line 211 (companion class). The record holds a state machine via `TMatchSession` enum (`sMatch, sGuard, sCase, sDefault, sTryExcept`, line 57) and a `TCaseGroup` dictionary (alias `TDictionary<TValue,TValue>`, line 60) keyed by `TCaseType` (17-variant enum, lines 32-50). The companion `TMatch` class (line 211) exposes a `class var FMatch: TValue` (line 213) that is written at the **beginning** of the session in `TMatch<T>.Value` (`Match.pas:242`, `TMatch.FMatch := TValue.From<TMatch<T>>(Result)`), carrying the `TMatch<T>` record itself across the value-copy boundaries that chaining introduces. This two-type design (record for chaining, class for shared state) is the core structural decision in the matching subsystem.

### 3.4 `TAsync` — task wrapper
`Source/ModernSyntax.Async.pas:50`. Record wrapping an `ITask` (`System.Threading`). Factory global functions `Async(TProc)` / `Async(TFunc<TValue>)` (lines 79–80) construct the record. `.Await` dispatches to `_AwaitProc` or `_AwaitFunc` depending on which constructor was used (lines 97–104). Returns `TFuture`. `IAutoLock`/`TAutoLock` (lines 33–48) provide a ref-counted critical section for internal thread safety.

### 3.5 `IScheduler` / `TScheduler` / `TCoroutine` — cooperative concurrency
`Source/ModernSyntax.Coroutine.pas:64, 101, 122`. `TCoroutine` is a sealed class carrying a `TFuncCoroutine`, state (`TCoroutineState`: `csActive, csPaused, csFinished`, line 35), a `TCriticalSection`, an interval and last-execution timestamp, and an observer list (`TList<TCoroutine>`, line 73). The observer interface (Attach/Detach/ObserverNotify, lines 87–89) links coroutines so one can notify dependants on completion. `IScheduler` (line 101) drives the round-robin: `Add` enqueues, `Run` starts the scheduler thread, `Send`/`Yield` exchange values between caller and coroutine, `Next` ticks a single step.

### 3.6 `TModernStreamReader` — functional stream pipeline
`Source/ModernSyntax.Stream.pas:40`. Class holding three `TSmartPtr<T>` fields (lines 42–44) — two `TStreamReader` wrappers and one `TStringStream` — managed via the RAII smart pointer from `ModernSyntax.Objects`. Pipeline operations (Map, Filter, Distinct, …) call `_ProcessStream` (line 63) which rebuilds `FDataString`/`FDataReader` from each step's output, enabling method chaining. A listener list (line 45) dispatches `TStreamReaderListenerEvent` callbacks per operation.

### 3.7 `TCurrying` / `TPipeline<T>` / `TMemoizedCache<T,U>`
`Source/ModernSyntax.Currying.pas:163, 97, 134`. `TCurrying` is a record providing partial application over anonymous method references. `TPipeline<T>` (line 97) is a generic record enabling `.Pipe(f).Pipe(g)…` composition chains. `TMemoizedCache<T,U>` (line 134) is a ref-counted class implementing `ICleanup` (line 33) that stores computed results in a `TDictionary`. 14 concrete `INumeric<T>` implementors (lines 390–766) cover all numeric types from `Byte` to `Currency`.

### 3.8 `TSmartPtr<T>` — RAII resource management
`Source/ModernSyntax.Objects.pas:80`. A record wrapping a managed class instance with `interface` lifetime (Delphi's ARC on interfaces). Consumed by `TModernStreamReader` (three fields, confirmed `ModernSyntax.Stream.pas:42-44`). Provides the library's primary RAII pattern; all other memory management is manual `Free`/`try-finally`.

---

## 4. Primary Data and Control Flows

### 4.1 Synchronous functional pipeline
Consumer code calls `TMatch<T>.Value(x)` → chains `.CaseEq(v, proc)` / `.CaseIf(cond: Boolean, proc)` / `.Default(proc)` → calls `.Execute`. Each chaining method updates `FCases` in the record and advances `FSession`; `.Execute` dispatches to one of the 17 `_Matching*` private methods (lines 78–95), which walk `FCases` and invoke the stored anonymous method. The `TMatch<T>` record itself is written into `TMatch.FMatch` (class var, line 213) at the **start** of the session (`Match.pas:242`), letting subsequent chaining methods retrieve the shared record across value-copy boundaries; the terminal value is read via `TMatch.Value<T>` (`Match.pas:1652`).

### 4.2 Async/await flow
`Async(proc)` → constructs `TAsync` with `FProc := proc` → `.Await` → `_AwaitProc(timeout)` → posts `FProc` to `TTask.Run` (via `System.Threading.ITask`) → blocks the calling thread until done or timeout → wraps the outcome in `TFuture` returned to caller. The `IAutoLock` field serialises shared state between the calling thread and the task thread.

### 4.3 Coroutine scheduler tick
Consumer calls `TScheduler.Add(name, func, value)` → `TScheduler.Run(errorHandler)` → scheduler spawns a background thread → each tick calls `Next` → dequeues next `TCoroutine` from `TGather` (internal sealed `TList<T>` with queue semantics, `ModernSyntax.Coroutine.pas:125`) → checks `_IsReadyToExecute` (interval-based gate) → invokes `FFunc(SendValue, Value)` → stores returned `TFuture` result → calls `ObserverNotify` to trigger chained coroutines.

### 4.4 Railway chaining
`TResultPair<S,F>.New` (the sole `class function` factory, `ResultPair.pas:143`) creates an `rtNone` container → caller chains `.Success(x)` or `.Failure(e)` (instance methods that mutate Self and return `Self`, `ResultPair.pas:674, 617`) → consumer chains `.ThenOf(func)` → if state is `rtSuccess`, appends `func` to `FSuccessFuncs`; at terminal `.Return`, stored callbacks are invoked in order. Failure short-circuits to `FFailureFuncs` chain. The correct idiom is `.New.Success(x)` (confirmed: `Test Delphi/EclbrResultPair/UTestMS.ResultPair.pas:105`). Note: `.Ok` (`ResultPair.pas:502`) is a side-effect executor (`TProc<S>`), not a constructor; `.Execute` belongs to `TMatch`, not `TResultPair`. `ModernSyntax.Option` wraps absent values into a `TResultPair<T,String>` (confirmed: `ModernSyntax.Option.pas:22` imports `ModernSyntax.ResultPair`), bridging null-safety into the railway.

---

## 5. Cross-Cutting Concerns

### 5.1 `TValue` as universal carrier
`Rtti.TValue` is imported by 9 of 16 units (measured: counted from `uses` blocks in `02-stack.md`) and used as the internal currency for `TFuture.FValue`, `TMatch` case dictionaries, `TCoroutine` `FValue`/`FSendValue`, `TArrow` method parameters, and `TDotEnv.FVariables`. This coupling to RTTI is pervasive: any value crossing a library boundary is boxed in `TValue`.

### 5.2 Windows unconditional import (F-ARCH-01)
Three units break cross-platform compilation:

| Unit | Section | Line | Symbol used |
|---|---|---|---|
| `ModernSyntax.Std` | interface `uses` | 21 | `Windows` (used for `OutputDebugString` in `DebugPrint` — `Std.pas:80`) |
| `ModernSyntax.DotEnv` | interface `uses` | 22 | `Windows` (used for `GetEnvironmentVariable` OS-env fallback) |
| `ModernSyntax.Objects` | implementation `uses` | 161 | `Windows` (imported; all `VirtualProtect` call sites are commented out — effectively unused) |

`ModernSyntax.Std` and `ModernSyntax.DotEnv` place `Windows` in the **interface** uses block, meaning any unit that `uses` them also drags in the Windows dependency. `ModernSyntax.Objects` confines it to the implementation block, limiting blast radius. None of the three uses `{$IFDEF MSWINDOWS}`. Five downstream units are transitively affected via `ModernSyntax.Std`: `ModernSyntax.Crypt`, `ModernSyntax.ArrowFun`, and `ModernSyntax.Match`.

### 5.3 `{$I ModernSyntax.inc}` — include used by one unit only
`ModernSyntax.Objects.pas:16` is the only source unit that includes the version-detection file (confirmed: `grep -rn '{\$I' Source/*.pas` — one result). All other units compile without the compiler-version symbols (`DELPHI14_UP`, `DELPHI_XE_UP`, etc.). Whether those units need version guards is not asserted anywhere in source comments — not verified.

### 5.4 `IMSObserver` — defined, never consumed
`ModernSyntax.pas:27` declares `IMSObserver` with a single `Update(Progress: Integer)` method. No other source file references this interface (confirmed: `grep -rn "IMSObserver" Source/*.pas` → one result, the definition itself). `TCoroutine` implements its own observer list (Attach/Detach/ObserverNotify, lines 87–89) using `TList<TCoroutine>` with no connection to `IMSObserver`. The interface is dead code in the current codebase.

### 5.5 Value-type record pattern
`TFuture`, `TResultPair<S,F>`, `TAsync`, `TMatch<T>`, `TCurrying`, `TTuple<K>`, `TArrow`, `TSafeResult` are all Delphi records (value types). This enables copy-on-pass semantics and avoids heap allocation for short-lived pipeline steps. It also means mutable state must be carefully managed — `TMatch<T>` works around Delphi's record copy semantics by externalising result storage into the `TMatch` companion class variable (`ModernSyntax.Match.pas:213`), a pattern that trades allocation for a global-variable risk.

### 5.6 No shared error-handling abstraction
`TFuture` (umbrella), `TResultPair<S,F>` (ResultPair), `TSafeResult` (Safetry) are three distinct result-carrier types. They do not share a base type or interface. `TAsync` returns `TFuture`; `TMatch` integrates with `TResultPair` (import confirmed line 28); `TSafeTry` returns `TSafeResult` without converting to either. A consumer combining Async + Match + SafeTry must manually convert between carriers.

---

## 6. Architecture Findings

**F-ARCH-01 — Windows imports block five units from cross-platform compilation (extends F-STACK-01)**
`ModernSyntax.Std` (interface `uses`, line 21) and `ModernSyntax.DotEnv` (interface `uses`, line 22) pull in `Windows` unconditionally. Downstream units that import `Std` — `ModernSyntax.Crypt` (line 21), `ModernSyntax.ArrowFun` (line 23), `ModernSyntax.Match` (line 26) — inherit this dependency transitively. `ModernSyntax.Objects` (implementation, line 161) is self-contained. Total units blocked from non-Windows compilation: `Std`, `DotEnv`, `Objects`, `Crypt`, `ArrowFun`, `Match` — 6 of 16.

**F-ARCH-02 — `IMSObserver` is dead code**
Defined at `ModernSyntax.pas:27`; zero references elsewhere (measured: `grep -rn "IMSObserver" Source/*.pas` → 1 result). `TCoroutine` provides its own observer mechanism. The interface occupies namespace in the umbrella unit without function.

**F-ARCH-03 — Three incompatible result carriers**
`TFuture`, `TResultPair<S,F>`, and `TSafeResult` serve overlapping roles with no conversion path between them. `TAsync` returns `TFuture`; `TMatch` integrates with `TResultPair`; `TSafeTry` returns `TSafeResult`. No cross-type adapter exists (confirmed: `grep -rn "TFuture\|TResultPair" Source/ModernSyntax.Safetry.pas` → 0 results; `grep -rn "TResultPair\|TSafeResult" Source/ModernSyntax.Async.pas` → 0 results — neither file references the other types).

**F-ARCH-04 — `TMatch` class variable is global shared state**
`TMatch.FMatch` at `ModernSyntax.Match.pas:213` is a `class var` — one slot shared across all `TMatch<T>` instances at runtime. Concurrent use of the pattern-matching DSL from multiple threads will race on this field. No locking exists in `TMatch` (confirmed: no `TCriticalSection` or `SyncObjs` import in `ModernSyntax.Match.pas:18-29`).

**F-ARCH-05 — `{$I ModernSyntax.inc}` consumed by one unit only**
Version-detection symbols (`DELPHI14_UP`, etc.) are only active in `ModernSyntax.Objects`. Whether other units need version-conditional code paths is not indicated. This is low risk today but means adding a version guard to any other unit requires adding the `{$I}` line, which may be forgotten.
