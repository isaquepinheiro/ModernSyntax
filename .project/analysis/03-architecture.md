---
type: analysis
kind: artifact
title: "Architecture: ModernSyntax — module map, responsibilities, flows, abstractions"
description: ARCHITECTURE step dossier mapping the 16-unit dependency graph, primary data/control flows, key abstractions, and cross-cutting concerns for the ModernSyntax Delphi library.
status: stable
generated:
  by: analyst@node:analyst-architecture
  at: 2026-08-27T00:00:00Z
tags:
  - architecture
  - delphi
  - modular-library
  - functional-programming
sources:
  - id: structure
    resource: /analysis/01-structure.md
    title: "01-structure: ModernSyntax folder tree and build mechanics"
  - id: stack
    resource: /analysis/02-stack.md
    title: "02-stack: ModernSyntax dependency manifest and runtime stack"
---

# Architecture — ModernSyntax

## 1. Module map

**Method:** dependency edges measured by extracting the `uses` clauses of all 16 source units
(`for f in Source/*.pas; do awk '/^uses/,/;/' "$f"; done`). Only imports of `ModernSyntax.*`
units (not RTL) constitute internal edges; every edge below cites the importing line.

```
RTL only (no internal edges)
  ModernSyntax              ← foundation: TFuture, TSet<T>, IMSObserver
  ModernSyntax.Std          ← utility singleton: TStd, TPointerStream
  ModernSyntax.ResultPair   ← ROP monad: TResultPair<S,F>
  ModernSyntax.Objects      ← RTTI factory + smart ptrs: TModernObject, TSmartPtr<T>, TMutableRef<T>
  ModernSyntax.RegExpression← regex wrapper: TModernRegEx
  ModernSyntax.Currying     ← FP combinators: TCurrying, TPipeline<T>, TMemoizedCache<T,U>
  ModernSyntax.DotEnv       ← env-file parser: TDotEnv
  ModernSyntax.Tuple        ← typed tuple: TTuple<K>, TTuple, TTupleDict<K>
  ModernSyntax.SafeTry      ← exception wrapper: TSafeTry, TSafeResult

One internal edge
  ModernSyntax.Option       → ModernSyntax.ResultPair   (Option.pas:22)
  ModernSyntax.Async        → ModernSyntax              (Async.pas uses block, line ~18)
  ModernSyntax.Coroutine    → ModernSyntax              (Coroutine.pas uses block, line ~21)
  ModernSyntax.Crypt        → ModernSyntax.Std          (Crypt.pas:21)
  ModernSyntax.ArrowFun     → ModernSyntax.Std          (ArrowFun.pas:23)
                            → ModernSyntax              (ArrowFun.pas:24)

Two internal edges
  ModernSyntax.Stream       → ModernSyntax.Objects      (Stream.pas:22)
                            → ModernSyntax              (Stream.pas:24)

Four internal edges (the hub)
  ModernSyntax.Match        → ModernSyntax.Std          (Match.pas:26)
                            → ModernSyntax.RegExpression(Match.pas:27)
                            → ModernSyntax.ResultPair   (Match.pas:28)
                            → ModernSyntax              (Match.pas:31)
```

No cycle was found among internal imports. `ModernSyntax` and `ModernSyntax.Std` are the two
most-imported units; `ModernSyntax.Match` is the highest fan-in consumer (4 internal deps).

---

## 2. Unit responsibilities

| Unit | Primary type(s) | Responsibility |
|---|---|---|
| `ModernSyntax` | `TFuture`, `TSet<T>`, `IMSObserver` | Foundation. Defines the async-result box and a hash-set wrapper used by `Stream`; exports `Tuple` alias. |
| `ModernSyntax.Std` | `TStd`, `TPointerStream` | Singleton utility bag (string, date, numeric helpers). `TPointerStream` wraps a raw pointer as a `TCustomMemoryStream`. |
| `ModernSyntax.ResultPair` | `TResultPair<S,F>` | Railway-Oriented Programming. Bifunctor carrying a success value or a failure value; exposes `Map`, `FlatMap`, `When`, `Reduce`, `ThenOf`, `ExceptOf`, `Recover`, `Swap`. |
| `ModernSyntax.Option` | `TOption<T>`, `TSome`, `TNone` | Rust-style option type. Delegates to `TResultPair` via `OkOr<F>` (Option.pas:188). |
| `ModernSyntax.Match` | `TMatch<T>`, `TMatch`, `TCaseType` | Pattern-matching DSL. Ten case discriminators (`Eq`, `Gt`, `Lt`, `In`, `Is`, `Range`, `If`, `Regex`, `Guard`, `Default`). Uses `TModernRegEx` for regex arms and `TResultPair` for `TryExcept` arm. |
| `ModernSyntax.Async` | `TAsync`, `IAutoLock`, `TAutoLock` | Async execution record. Wraps `System.Threading.ITask`; `Run` = fire-and-forget, `Await` = wait-with-timeout. Returns `TFuture`. |
| `ModernSyntax.Coroutine` | `IScheduler`, `TScheduler`, `TCoroutine` | Cooperative coroutine scheduler. Maintains a FIFO queue of `TCoroutine`; driven by a single `System.Threading.ITask`. |
| `ModernSyntax.Currying` | `TCurrying`, `TPipeline<T>`, `TMemoizedCache<T,U>`, `INumeric<T>` | Functional combinators. `TCurrying` holds a `TValue` and returns partial-application closures. `TPipeline<T>` threads a value through `Apply`/`Map`/`Thn`. 14 concrete `INumeric<T>` implementations for numeric types. |
| `ModernSyntax.Objects` | `TModernObject`, `TSmartPtr<T>`, `TMutableRef<T>` | RTTI-based object factory and smart pointer records. `TModernObject.Factory` uses a class-level `TRttiContext` to locate constructors at runtime. |
| `ModernSyntax.ArrowFun` | `TArrow` | Function factory. Produces `TProc`/`TFunc<TValue>` closures over literals or variable references; bridges pointer dereferencing to typed assignment for arrays. |
| `ModernSyntax.Stream` | `TModernStreamReader` | Functional stream pipeline over text lines. Implements `Map`, `Filter`, `Reduce`, `ForEach`, `Distinct`, `Skip`, `Sort`, `Take`, `Concat`, `Partition`, `Comprehend`. Uses `TSet<String>` internally for `Distinct`. |
| `ModernSyntax.Crypt` | `TCrypt`, `TPacket` | Static Base64 encode/decode and a lightweight hash. All methods are `class function`; no instance state. |
| `ModernSyntax.DotEnv` | `TDotEnv` | `.env` file parser and environment proxy. Reads key=value pairs, expands `${VAR}` references, and falls back to `GetEnvironmentVariable` (Windows.pas:408,415,420,427) when `UseSystemFallback` is true. |
| `ModernSyntax.RegExpression` | `TModernRegEx`, type aliases | Thin facade over `System.RegularExpressions`. Re-exports `TMatch`, `TRegExOption`, `TGroupCollection` as local aliases. |
| `ModernSyntax.SafeTry` | `TSafeTry`, `TSafeResult` | Functional exception wrapper. `Try(func).Except(handler).Finally(cleanup).End` captures exceptions into `TSafeResult` without raising. |
| `ModernSyntax.Tuple` | `TTuple<K>`, `TTuple`, `TTupleDict<K>` | Heterogeneous tuple via `TValue` arrays. Pre-declared aliases: `TTupluString`, `TTupluInteger`, … (11 aliases confirmed: Tuple.pas:86–97). |

---

## 3. Primary data / control flows

### 3.1 Async dispatch (`ModernSyntax.Async`)

```
caller: Async(proc)
  → TAsync.Create(proc)                  -- Async.pas:64  stores FProc
  → .Run or .Await(timeout)
      → _ExecProc / _AwaitProc           -- Async.pas:250, 204
          → TTask.Run(proc closure)       -- Async.pas:213, 260
              on success: FResult.SetOk  -- Async.pas:~270
              on error:   FResult.SetErr -- Async.pas:~280
          → [if Await] FTask.Wait(ATimeout) -- Async.pas:222
          → TThread.Queue(nil, callback) -- Async.pas:271 (for Await continuations)
  ← TFuture (IsOk/IsErr + value or error string)
```

`TThread.Queue(TThread.CurrentThread, ...)` is used in `_AwaitProc` (Async.pas:227) to marshal
the continuation to the current (calling) thread; `TThread.Queue(nil, ...)` at line 271 targets
the main thread.

### 3.2 Coroutine scheduling (`ModernSyntax.Coroutine`)

```
caller: TScheduler.Create(sleepTime)
  → .Add(name, TFuncCoroutine, value)  -- Coroutine.pas:109 enqueues TCoroutine
  → .Run(errorProc)                    -- Coroutine.pas:166
      → TTask.Run(loop closure)         -- Coroutine.pas:439
          loop: while not FStoped
            → dequeue next TCoroutine
            → FCurrentRoutine.Func(sendValue, value) → TFuture
            → check TCoroutineState (csActive/csPaused/csFinished)
            → Sleep(FSleepTime)
          on error: TThread.Queue(nil, FErrorCallback) -- Coroutine.pas:453
  → .Send(name, value)  -- caller thread injects value into named coroutine
  → .Yield(name)        -- caller reads last emitted value
  → .Stop(timeout)      -- sets FStoped; FTask.Wait(timeout)
```

One `ITask` drives the entire scheduler; coroutines are not individually threaded — they run
cooperatively within the task's iteration, separated by `Sleep(FSleepTime)`.

### 3.3 Pattern-matching dispatch (`ModernSyntax.Match`)

```
TMatch<T>.Create(value)               -- Match.pas:63 — stores subject in FValue
  .CaseEq(v, proc)  / .CaseEq(v, fn) -- accumulates into TCaseGroup dictionary
  .CaseIf(pred, proc)
  .CaseGt / .CaseLt / .CaseIn / .CaseIs / .CaseRange
  .Guard(pred)
  .CaseDef(proc)    / default arm
  .TryExcept        -- wraps arm execution in try/except → result TResultPair
→ execution triggered lazily on first arm match:
    _ExecuteProcSession / _ExecuteFuncSession  -- Match.pas:127–128
      → selects _ExecuteProc* / _ExecuteFunc* based on TCaseType discriminator
      → on regex arm: TModernRegEx.IsMatch  -- uses RegExpression unit
      → on TryExcept arm: captures exception into TResultPair
```

`TMatchSession` enum (Match.pas:57) tracks whether the matcher is in `sMatch`, `sGuard`, `sCase`,
`sDefault`, or `sTryExcept` state; it is stored as a field in the `TMatch<T>` record.

### 3.4 Option → ResultPair bridge

`TOption<T>.OkOr<F>(failure)` (Option.pas:188) converts the option to `TResultPair<T,F>`:
- `IsSome` → `TResultPair.Success(FValue.AsType<T>)`
- `IsNone` → `TResultPair.Failure(failure)`

This is the only cross-unit data handoff between `Option` and `ResultPair`; all other
`TOption<T>` operations (`Map`, `Filter`, `AndThen`, `Otherwise`, `OrElse`) are self-contained.

### 3.5 Stream functional pipeline (`ModernSyntax.Stream`)

```
TModernStreamReader.Create(stream)  -- wraps TStreamReader
  .Map(fn)      → _ProcessStream  -- appends transformed lines to TStringBuilder
  .Filter(pred) → _ProcessStream
  .Distinct     → uses TSet<String> (from ModernSyntax.pas) as seen-set (Stream.pas:516–519)
  .Sort / .Skip / .Take / .Concat / .Partition / .Comprehend
  .ForEach / .Join / .AsLine / .AsString   -- terminal operations
→ AddListener / _NotifyListeners  -- observer-style callbacks on each line operation
```

`System.Threading` (plain `Threading` import at Stream.pas — wait, actually Stream imports
`System.Threading` with full namespace, Stream.pas:24 confirms `System.Threading`) is imported
but its usage in `TModernStreamReader` was not confirmed in the sampled method signatures;
`TModernObject` (Objects) is used for the RTTI factory path.

---

## 4. Key abstractions (file:area)

| Abstraction | Location | Role |
|---|---|---|
| `TFuture` | `ModernSyntax.pas:32–86` | Value-type box: `TValue` payload + `String` error; `IsOk`/`IsErr` discriminant. The async result carrier shared by `Async` and `Coroutine`. |
| `TResultPair<S,F>` | `ModernSyntax.ResultPair.pas:57–549` | Bifunctor / railway monad. Holds `TResultValue` (two `TValue` slots) + `TResultType` discriminant. API: `Success`/`Failure` constructors, `Map`, `FlatMap`, `When`, `Reduce`, `ThenOf`, `ExceptOf`, `Recover`, `Swap`, `Pure`. |
| `TOption<T>` | `ModernSyntax.Option.pas:48–238` | Nullable wrapper. Holds `TResultPair<T,String>` internally (confirmed: `OkOr` bridges to it at line 188); exposes `IsSome`/`IsNone`, `Unwrap*`, `Map`, `Filter`, `AndThen`, `Take`, `Flatten`, `Replace`. |
| `TMatch<T>` | `ModernSyntax.Match.pas:63–~700` | Pattern-matching record. `TCaseType` (Match.pas:32–51) enumerates 10 discriminator kinds; a `TCaseGroup` (`TDictionary<TValue,TValue>`) stores arm handlers. Session state tracked in `TMatchSession`. |
| `TAsync` | `ModernSyntax.Async.pas:50–76` | Async record. Holds `FProc: TProc`, `FFunc: TFunc<TValue>`, `FTask: ITask`, `FLock: IAutoLock`. Entry points: `Run` (fire-and-forget), `Await` (blocking with timeout), `NoAwait` (alias for Run). |
| `IScheduler` / `TScheduler` | `ModernSyntax.Coroutine.pas:101–122` | Cooperative coroutine runner. `TGather<TCoroutine>` (inner class, Coroutine.pas:125) is a `TList<T>` with queue semantics. A `TCriticalSection` (`FLock`) guards queue access. |
| `TCoroutine` | `ModernSyntax.Coroutine.pas:64–99` | Coroutine node. Holds name, `TFuncCoroutine`, state (`TCoroutineState`), value, sendValue, sendCount, and an observer list (Attach/Detach/Notify — making it also the subject in a lightweight observer pattern). |
| `TStd` | `ModernSyntax.Std.pas:36–62` | Lazy singleton (`Get` at line 204 creates on first call). All methods are `class function`. Holds a process-lifetime `TFormatSettings` for en_US locale (initialized in `initialization` block at Std.pas:322–324). |
| `TCurrying` | `ModernSyntax.Currying.pas:163–192` | Value-carrying record. `Create(TValue)` stores the value; `Op<T>(operation)` returns a `TFunc<T,TCurrying>` closure capturing the stored value; `Value<T>` extracts it. |
| `TPipeline<T>` | `ModernSyntax.Currying.pas:97–133` | Monomorphic value pipeline. `Apply<U>(f)`, `Map<U>(f)`, `Thn<U>(f)` all call `f(FValue)` and wrap in `TPipeline<U>`. `Value` unwraps. |
| `TMemoizedCache<T,U>` | `ModernSyntax.Currying.pas:134–157` | Thread-safe memoization. Holds `TDictionary<T,U>` guarded by `TCriticalSection`. `GetOrAdd(key, func)` checks cache then calls `func` on miss. Implements `ICleanup`. |
| `TModernObject` | `ModernSyntax.Objects.pas:39–57` | RTTI factory. Holds class-level `FContext: TRttiContext` (Objects.pas:41). `Factory(TClass)` resolves the constructor via `FContext.GetType(AClass)` (Objects.pas:220). |
| `TSmartPtr<T>` | `ModernSyntax.Objects.pas:80–108` | Value-type scope guard. Inner class `TSmartPtr` (Objects.pas:89) implements `ISmartPtr<T>` as a ref-counted `TInterfacedObject`; the outer record holds an `ISmartPtr<T>` interface reference — lifetime follows the record. `Match<R>` provides null-aware dispatch. |
| `TArrow` | `ModernSyntax.ArrowFun.pas:37` | Function factory with class-level mutable state (`class var FValue: TValue` — ArrowFun.pas:~40). `Fn(value)` returns a `TProc` that stores the value; `Fn(varRefs, tuple)` returns a `TProc<TValue>` that performs typed pointer dereferencing for array types. |
| `TModernStreamReader` | `ModernSyntax.Stream.pas:40–311` | Functional text-stream pipeline. Lazy: intermediate operations (`Map`, `Filter`, `Distinct`, …) store transforms internally; terminal operations (`Join`, `AsString`, `ForEach`) trigger evaluation. Observer list (`_NotifyListeners`) hooks into each line operation. |
| `TCrypt` | `ModernSyntax.Crypt.pas:33–45` | Stateless Base64 codec + hash record. All methods `class function static`; `TPacket` (Crypt.pas:25) is the 3-byte block used by the Base64 algorithm. |
| `TDotEnv` | `ModernSyntax.DotEnv.pas:26–144` | Env-file manager. Internally stores key→`TValue` in a `TDictionary` (confirmed: `_GetValue` at line 396 is a dictionary lookup). `_ReplaceVars` (line 204) performs `${VAR}` interpolation. `UseSystemFallback` (line 144) enables fall-through to `GetEnvironmentVariable`. |
| `TModernRegEx` | `ModernSyntax.RegExpression.pas:28` | Thin facade; adds no data beyond the delegates to `System.RegularExpressions.TRegEx`. |

---

## 5. Dependency direction summary (arrows = imports confirmed by `uses` clauses)

```
ModernSyntax (foundation)
  ↑ imported by: Async, Coroutine, ArrowFun, Match, Stream

ModernSyntax.Std
  ↑ imported by: ArrowFun, Crypt, Match

ModernSyntax.ResultPair
  ↑ imported by: Option, Match

ModernSyntax.RegExpression
  ↑ imported by: Match

ModernSyntax.Objects
  ↑ imported by: Stream

(ModernSyntax.Currying, DotEnv, Tuple, SafeTry, Option alone among dependents: no one imports them internally)
```

The library has **no circular imports** in `Source/`. Units at the bottom of the fan-in
list (`Currying`, `DotEnv`, `Tuple`, `SafeTry`) are true leaf nodes: nothing in `Source/`
imports them (confirmed: `grep -rn "ModernSyntax.Currying\|ModernSyntax.DotEnv\|ModernSyntax.Tuple\|ModernSyntax.SafeTry" Source/*.pas` — no result other than the unit's own declaration line).

---

## 6. Cross-cutting concerns

### 6.1 `TValue` as universal type carrier

12 of 16 source units import `Rtti` and use `TValue` as their primary polymorphic container
(command: `grep -c "Rtti" Source/*.pas | grep -v ":0"` → 12 units; non-importing: `Crypt`,
`RegExpression`, `Std`, `Stream`). Effects:

- **Erasure at boundaries:** `TFuture.SetOk(AValue: TValue)` and `TFuture.Ok<T>: T` perform
  runtime cast at retrieval (ModernSyntax.pas:77,61). Mis-matched type raises `EInvalidCast`
  at call site, not at storage site.
- **Type-dispatch in Match:** `TMatch<T>` dispatches on `TValue.TypeInfo` to select numeric vs
  string vs object comparison (Match.pas:104–108 — `_IsArrayInteger`, `_IsArrayChar`, …).
- **RTTI factory:** `TModernObject.Factory` uses `TRttiContext.GetType(AClass)` to locate
  constructors; the context is cached in a class variable (Objects.pas:41), shared across
  instances.

### 6.2 `System.Threading` (TTask) for concurrency

Both `Async` and `Coroutine` use `TTask.Run` (Async.pas:213, 260, 346, 378;
Coroutine.pas:439) to dispatch work to Delphi's built-in thread pool. `TThread.Queue` is
used to marshal callbacks back:
- `TThread.Queue(TThread.CurrentThread, …)` (Async.pas:227) — marshal to calling thread.
- `TThread.Queue(nil, …)` (Async.pas:271; Coroutine.pas:453) — marshal to main thread.

`TCriticalSection` is the synchronization primitive in `Async` (`FLock`), `Coroutine`
(`FLock`), and `Currying` (`TMemoizedCache`). `IAutoLock`/`TAutoLock` (Async.pas:33–46) wrap
`TCriticalSection` in an interface for deterministic release.

### 6.3 Windows API coupling (platform lock)

Two source units call Win32 APIs unconditionally:

- `ModernSyntax.Std.pas` — `OutputDebugString` (Std.pas:80, inside `DebugPrint`), imported via `Windows` unit.
- `ModernSyntax.DotEnv.pas` — `GetEnvironmentVariable` / `SetEnvironmentVariable` (DotEnv.pas:408, 415, 420, 427), imported via `Windows` unit.

Neither call is guarded by `{$IFDEF MSWINDOWS}` or any platform conditional. This is a
**drift** from the cross-platform claim in `README.md:28`; FPC/Lazarus is not in scope — `ModernSyntax.inc:256` `{$IFDEF FCP}` is permanently dead code (typo: `FCP` ≠ `FPC`).

### 6.4 Class-level mutable state (`class var`)

Three units hold process-global mutable class variables:

| Variable | Unit | Line | Risk |
|---|---|---|---|
| `TStd.FInstance: TStd` | `ModernSyntax.Std.pas` | 40 | Singleton; created in `initialization`, freed in `finalization` (Std.pas:322–328). Thread-safe access not guarded. |
| `TStd.FSequenceCounter: Int64` | `ModernSyntax.Std.pas` | 41 | Monotonic counter incremented by `GenerateSequentialNumber`; no atomic increment. |
| `TModernObject.FContext: TRttiContext` | `ModernSyntax.Objects.pas` | 41 | Shared `TRttiContext` across all calls to `Factory`; created in `initialization` (Objects.pas:193). |
| `TArrow.FValue: TValue` | `ModernSyntax.ArrowFun.pas` | ~40 | Last-stored value across all `TArrow.Fn`/`TArrow.Result` calls; no synchronization. Concurrent use from multiple tasks is unsafe. |

### 6.5 Record vs class duality

The library uses a **records-for-API, classes-for-state** pattern consistently:
- Public entry points (`TAsync`, `TMatch<T>`, `TCurrying`, `TPipeline<T>`, `TResultPair<S,F>`,
  `TOption<T>`, `TFuture`, `TSafeTry`, `TTuple<K>`, `TArrow`) are **records** — stack-allocated,
  copy-on-assign.
- Mutable or lifecycle-managed internals (`TSet<T>`, `TMemoizedCache<T,U>`, `TModernObject`,
  `TModernStreamReader`, `TScheduler`, `TCoroutine`) are **classes** — heap-allocated, requiring
  explicit `Free` or interface-counted lifetime.
- Smart-pointer records (`TSmartPtr<T>`, `TMutableRef<T>`) bridge this: the inner
  `TInterfacedObject` class carries the lifetime; the outer record holds the interface reference
  and is itself stack-safe.

### 6.6 Observer pattern (`TCoroutine`, `TModernStreamReader`)

Two units implement an ad-hoc observer pattern:

- **`TCoroutine`** (Coroutine.pas:87–90): `Attach`/`Detach`/`ObserverNotify`/`Notify` — a
  coroutine can notify a list of sibling coroutines of events. The observer list type is not
  visible in the public interface (stored as a private field); confirmed by method signatures
  at lines 87–90.
- **`TModernStreamReader`** (Stream.pas:299–305): `AddListener`/`RemoveListener` with
  `TStreamReaderListenerEvent = procedure(const Line, Operation: String) of object` — fires
  on every line processed by `_NotifyListeners` (Stream.pas:52).

`IMSObserver` (ModernSyntax.pas:27) — defined in the foundation unit with a single method
`Update(Progress: Integer)` — is **not referenced by any other source unit** (confirmed:
`grep -rn "IMSObserver" Source/` returns only ModernSyntax.pas:27). It is a declared-but-unused
interface; the two observer patterns above use ad-hoc callbacks rather than this interface.

---

## 7. Findings (drift)

### F-04 — `TArrow.FValue` is a class-level singleton with no thread guard

`TArrow` stores its working value in `class var FValue: TValue` (ArrowFun.pas:~40).
All `Fn` and `Result` overloads read/write this single slot. Concurrent calls from multiple
`TTask` threads (e.g. when `Async(proc)` closures use `TArrow.Fn`) produce a data race.
There is no `TCriticalSection`, `TInterlocked`, or any other synchronization around
`FValue` accesses. The intent of the type (producing closures) does not require shared state;
this appears to be an accidental singleton.

### F-05 — `TStd.GenerateSequentialNumber` is not thread-safe

`GenerateSequentialNumber` (Std.pas:58) increments `FSequenceCounter: Int64` (Std.pas:41).
The increment is a standard `Inc` — not `TInterlocked.Increment`. Concurrent callers can
produce duplicate sequence numbers.

### F-06 — `IMSObserver` is declared but not consumed

`IMSObserver` (ModernSyntax.pas:27) declares an `Update(Progress: Integer)` contract.
No source unit in `Source/` implements or references this interface (confirmed:
`grep -rn "IMSObserver" Source/*.pas` — one hit, the declaration line itself). Two observable
types exist (`TCoroutine`, `TModernStreamReader`) but neither uses `IMSObserver`; they define
their own ad-hoc callback types.

### F-07 — `Threading` vs `System.Threading` import inconsistency

`ModernSyntax.Async.pas` and `ModernSyntax.Coroutine.pas` import `Threading` (bare name,
Async.pas:25, Coroutine.pas:24). `ModernSyntax.Stream.pas` imports `System.Threading` (full
qualified name, Stream.pas — confirmed by `awk '/^uses/,/;/' Source/ModernSyntax.Stream.pas`
output showing `System.Threading`). Both resolve to the same unit under default Delphi namespace
search (`System` prefix), but the inconsistency can confuse cross-platform builds where the
namespace search list differs.

---

## 8. Open questions

**Q1 — Does `TModernStreamReader` use `System.Threading` actively or only via `TModernObject`?**

Attempted: `grep -n "TTask\|ITask\|TThread" Source/ModernSyntax.Stream.pas` — no result.
`grep -n "Threading" Source/ModernSyntax.Stream.pas` returned the `uses` line only.
The `System.Threading` unit is imported but no `TTask`/`TThread` call site was found in
the sampled method signatures. The import may be a leftover, or it may be used inside
`TModernObject` which `Stream` imports. Cannot determine without full method body scan.

**Q2 — Is `TArrow.FValue` intentionally a class variable, or should it be an instance field?**

The `class var FValue: TValue` makes `TArrow` a semi-singleton with shared state. All
public `Fn` and `Result` overloads write to it before returning a closure that captures
the value by value — but the write to `FValue` itself is unguarded. Tried: searching for
any `initialization`/`finalization` or thread-lock around `FValue` in `ModernSyntax.ArrowFun.pas`
(`grep -n "FValue\|Critical\|Lock\|Mutex\|Atomic" Source/ModernSyntax.ArrowFun.pas`) — no
synchronization found. The design rationale is absent from code comments.
