---
type: analysis
kind: artifact
title: "04-domain: ModernSyntax — entities, relationships, business rules, use cases"
description: "Domain model extracted from source code: 16 library entities, their relationships, 9 confirmed business rules, and 10 primary use cases."
status: stable
generated:
  by: "analyst-discovery@node:domain"
  at: "2026-08-27T00:00:00Z"
tags:
  - domain
  - analyst
  - discovery
  - modelsyntax
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
---

# Domain — ModernSyntax

## 0. System character

ModernSyntax is a **Delphi functional-programming extension library**.
It has no end-user interface and no server runtime.
The sole actor is the **Delphi application developer** who adds the library to their project.
Domain concepts are language-level abstractions (types, combinators, containers);
there are no persisted entities, no users, no external integrations at runtime.

Unit count: `ls Source/*.pas | wc -l` → **16** deliverable units.

---

## 1. Entities and public types

Each subsection names the primary type, its source location (confirmed), and its key fields.

### 1.1 TFuture — async result container

**Source:** `Source/ModernSyntax.pas` lines 34–86.  
**Kind:** `record`.  
**Fields** (confirmed `Source/ModernSyntax.pas:35-38`):

```
FValue  : TValue   — the successful payload
FErr    : String   — the error message
FIsOK   : Boolean  — set True by SetOk, forced False by SetErr
FIsErr  : Boolean  — set True by SetErr, forced False by SetOk
```

**Public surface:** `IsOk`, `IsErr`, `Ok<T>`, `Err`, `SetOk(TValue)`, `SetErr(String)`.

`TAsync` (`Source/ModernSyntax.Async.pas:22`) and `TCoroutine`/`IScheduler` (`Source/ModernSyntax.Coroutine.pas:30`) both re-alias this type:
```pascal
TFuture = ModernSyntax.TFuture;   -- Async.pas:22; Coroutine.pas:30
```
confirming `TFuture` is the shared async-result carrier across the concurrency layer.

### 1.2 TSet\<T\> — generic hash set

**Source:** `Source/ModernSyntax.pas` lines 88–173.  
**Kind:** `class sealed`.  
**Backing store:** `TDictionary<T, Boolean>` (confirmed `ModernSyntax.pas:91`).  
**Comparer:** optional `IEqualityComparer<T>` injected at construction.  
No dependency on other ModernSyntax units.

### 1.3 IMSObserver — observer callback

**Source:** `Source/ModernSyntax.pas` lines 24–28.  
**Kind:** `interface` with GUID `{5887CDFF-DA23-4466-A5CB-FBA1DFEAF907}`.  
Single method: `Update(const Progress: Integer)`.  
Used nowhere in `Source/` other than its declaration — confirmed:
`grep -r "IMSObserver" Source/*.pas` → only `ModernSyntax.pas` declares it; no unit implements or references it elsewhere.
Status: declared, unused in library code. **FINDING — see §6 F-01.**

### 1.4 TOption\<T\> — maybe / nullable value

**Source:** `Source/ModernSyntax.Option.pas` lines 46–250.  
**Kind:** `record`.  
**Fields:** `FHasValue: Boolean`, `FValue: T`.  
**Variants:** `Some(T)` (has value) and `None` (no value).  
**Dependency:** imports `ModernSyntax.ResultPair` (`Option.pas:18`) to support `OkOr<F>`.

Public API: 26 methods (counted: `grep -c "^    function\|^    class function\|^    procedure" Source/ModernSyntax.Option.pas` → 26), including:
`Some`, `None`, `Zip`, `IsSome`, `IsNone`, `IsSomeAnd`, `Contains`, `Unwrap`, `UnwrapOr`, `UnwrapOrElse`, `UnwrapOrDefault`, `Expect`, `Map<U>`, `Filter`, `AndThen<U>`, `Otherwise`, `OrElse`, `OkOr<F>`, `Match`, `IfSome`, `Take`, `Flatten<U>`.

**Bridge to ResultPair** (confirmed `Option.pas:389-394`):
```pascal
function TOption<T>.OkOr<F>(const AFailure: F): TResultPair<T, F>;
begin
  if FHasValue then
    Result := TResultPair<T, F>.Success(FValue)
  else
    Result := TResultPair<T, F>.Failure(AFailure);
end;
```

Helper records in same unit: `TSome` (wraps `TValue`), `TNone` (wraps a message `TValue`).

### 1.5 TResultPair\<S,F\> — Railway Pattern result

**Source:** `Source/ModernSyntax.ResultPair.pas` lines 57–540.  
**Kind:** `record`.  
**State enum:** `TResultType = (rtNone, rtSuccess, rtFailure)` (`ResultPair.pas:25`).  
**Fields (strict private):** `FSuccess: TResultPairValue<S>`, `FFailure: TResultPairValue<F>`, `FSuccessFuncs: TArray<TFuncOk>`, `FFailureFuncs: TArray<TFuncFail>`, `FResultType: TResultType`.

Public API: 42 methods (counted: `grep -n "^    function\|^    procedure\|^    class function" Source/ModernSyntax.ResultPair.pas | grep -v "strict\|private" | wc -l` → 42), including chaining: `Success`, `Failure`, `ThenOf`, `Map`, `FlatMap`, `Reduce`, `When`, `Recover`, `Swap`, `Exec`, `Ok`, `Fail`, `Pure`, `SuccessOrDefault`, `SuccessOrException`, `FailureOrDefault`, `FailureOrException`, `isSuccess`, `isFailure`.

**Initial state:** `TResultPair<S,F>.New` → calls `Create(TResultType.rtNone)` (confirmed `ResultPair.pas:821-823`). A `New` instance carries no value until `.Success(v)` or `.Failure(v)` is called.

Helper types in same unit: `TResultPairValue<T>` (nullable value holder), `TResultValue` (raw pair record), `EFailureException<F>`, `ESuccessException<S>`, `ETypeIncompatibility`.

The _Railway Pattern_ term appears explicitly in doc comments at `ResultPair.pas:79`, `91`, `138`.

### 1.6 TMatch\<T\> — pattern-matching engine

**Source:** `Source/ModernSyntax.Match.pas` lines 63–1783.  
**Kind:** `record`.  
**Dependencies:** `ModernSyntax.Std`, `ModernSyntax.RegExpression`, `ModernSyntax.ResultPair`, `ModernSyntax` (confirmed `Match.pas:19-27`).

**Case dispatch enum** (`TCaseType`, `Match.pas:33-49`) — 17 variants (counted: enum declaration lines 33–49, 17 distinct names):

| Variant | Index | Meaning |
|---|---|---|
| ctCaseIfProc | 0 | guard predicate → procedure |
| ctCaseIfFunc | 1 | guard predicate → function |
| ctCaseEqProc | 2 | equality match → procedure |
| ctCaseEqFunc | 3 | equality match → function |
| ctCaseGtProc | 4 | greater-than → procedure |
| ctCaseGtFunc | 5 | greater-than → function |
| ctCaseLtProc | 6 | less-than → procedure |
| ctCaseLtFunc | 7 | less-than → function |
| ctCaseInProc | 8 | membership match → procedure |
| ctCaseInFunc | 9 | membership match → function |
| ctCaseIsProc | 10 | type-is match → procedure |
| ctCaseIsFunc | 11 | type-is match → function |
| ctCaseRangeProc | 12 | range match → procedure |
| ctCaseRangeFunc | 13 | range match → function |
| ctDefaultProc | 14 | default fallback → procedure |
| ctDefaultFunc | 15 | default fallback → function |
| ctTryExcept | 16 | exception-wrapping case |

**Session state machine** (`TMatchSession`, `Match.pas:55-57`):
`sMatch`, `sGuard`, `sCase`, `sDefault`, `sTryExcept`.

**Internal storage:** `FCases: array[TCaseType] of TCaseGroup` where `TCaseGroup = TDictionary<TValue, TValue>` (`Match.pas:74`).

A non-generic sibling `TMatch` (without type parameter) is also declared in the same unit (`Match.pas:201` onward) — it receives a raw `TValue` and uses the same `TCaseType` dispatch.

### 1.7 TCurrying — partial application and functional combinators

**Source:** `Source/ModernSyntax.Currying.pas` lines 167–2146.  
**Kind:** `record`.  
**No ModernSyntax inter-dependency** (pure RTL — confirmed: dependency scan shows no `ModernSyntax.*` in Currying's uses).

Public class functions: 28 (counted: `grep -c "^    class function" Source/ModernSyntax.Currying.pas` → 28), including:
`Op<T>`, `Concat`, `Value<T>`, `TValueValue`, `Compose<T,U,V>`, `Partial<T,V>`, `Memoize<T,U>`, `Pipe<T>`, `Curry<T,U,V>`, `UnCurry<T,U,V>`, `Map<T,U>`, `Filter<T>`, `Fold<T,U>`, `ArrayToString<T>`, `Take<T>`, `Drop<T>`, `Zip<T1,T2>`, `Any<T>`, `All<T>`, `GroupBy<T,TKey>`, `TakeWhile<T>`, `DropWhile<T>`, `Distinct<T>`, `Reverse<T>`, `Sort<T>`.

**Companion types in same unit:**

- `TPipeline<T>` (`record`) — fluent value pipeline: `Apply<U>`, `Map<U>`, `Thn<U>`, `Value` (`Currying.pas:106-133`)
- `TMemoizedCache<T,U>` (`class`) — thread-safe `TDictionary`-backed cache with `ICleanup`; used by `Memoize` (`Currying.pas:141-163`)
- `INumeric<T>` — arithmetic interface: `Add`, `Subtract`, `Multiply`, `Divide`, `Power`, `Modulus`, `AsString`, `GetValue` (`Currying.pas:42-95`)
- `ICleanup` — single-method `Cleanup` interface (`Currying.pas:27-39`)

### 1.8 TArrow — arrow function wrapper

**Source:** `Source/ModernSyntax.ArrowFun.pas` lines 35–309.  
**Kind:** `record`.  
**Dependencies:** `ModernSyntax.Std`, `ModernSyntax` (`ArrowFun.pas:15-16`).  
**Sole class field:** `FValue: TValue` (class var, `ArrowFun.pas:47`).

Provides: `Fn(...)` returning `TProc` or `TProc<TValue>`, and `Result(...)` returning `TFunc<TValue>`.
Works as an adapter to create anonymous-method references from concrete values, supporting variable side-effects without direct closures.

### 1.9 TTuple — positional and named tuple types

**Source:** `Source/ModernSyntax.Tuple.pas`.  
**No ModernSyntax inter-dependency** (pure RTL generics).

Three distinct types:
- `TTuple` (`record`) — positional, backed by `TValueArray` (`array of TValue`), with index access (`Tuple.pas:94-120`)
- `TTuple<K>` (`record`) — keyed, delegates to `ITupleDict<K>` / `TTupleDict<K>` (`Tuple.pas:46-89`)
- `TTupleDict<K>` (`class`, implements `ITupleDict<K>`) — `TDictionary<K, TValue>` wrapper

Implicit conversion operators between `TTuple` / `TValueArray` and `array of Variant` confirmed at `Tuple.pas:98-101`.

### 1.10 TAsync — async/await executor

**Source:** `Source/ModernSyntax.Async.pas` lines 30–90.  
**Kind:** `record`.  
**Dependencies:** `ModernSyntax` for `TFuture` (`Async.pas:22`); `System.Threading` for `ITask` (`Async.pas:25`).

Fields: `FTask: ITask`, `FProc: TProc`, `FFunc: TFunc<TValue>`, `FError: TFunc<Exception, TFuture>`, `FLock: IAutoLock`.

Public API: `Await(AContinue, ATimeout)`, `Await(ATimeout)`, `Run`, `Run(AError)`, `NoAwait`, `NoAwait(AError)`, `Status`, `GetId`, `Cancel`, `CheckCanceled`.

Module-level factory functions (confirmed `Async.pas:95-103`):
```pascal
function Async(const AProc: TProc): TAsync;
function Async(const AFunc: TFunc<TValue>): TAsync;
```

Thread safety via `IAutoLock` / `TAutoLock` wrapping `TCriticalSection` (`Async.pas:33-50`).

### 1.11 TCoroutine and IScheduler — cooperative coroutine host

**Source:** `Source/ModernSyntax.Coroutine.pas`.  
**Kind:** `TCoroutine` is a `class sealed`; `IScheduler` is an interface implemented by `TScheduler : TInterfacedObject`.

**Coroutine lifecycle states** (`TCoroutineState`, `Coroutine.pas:34-36`):
`csActive`, `csPaused`, `csFinished`.

**TCoroutine fields** (confirmed `Coroutine.pas:62-76`):
`FName`, `FState`, `FFunc: TFuncCoroutine`, `FProc: TProc`, `FValue: TValue`, `FSendValue: TValue`, `FSendCount: UInt32`, `FObserverList: TList<TCoroutine>`, `FLock: TCriticalSection`, `FInterval: UInt32`, `FLastExecutionTime: TDateTime`.

The coroutine implements the **observer pattern** internally: `Attach`, `Detach`, `ObserverNotify`, `Notify(TParamNotify)` (`Coroutine.pas:82-87`).

**IScheduler public API** (confirmed `Coroutine.pas:101-120`):
`Add(name, func, value, proc, interval)`, `Run`, `Run(AError)`, `Started(handler)`, `Finished(handler)`.  
`TScheduler.New(ASleepTime)` is the constructor entry point (`Coroutine.pas:151`).

Ancillary records: `TException`, `TSend`, `TPause`, `TParamNotify` — all carry typed value payloads for coroutine communication.

### 1.12 TModernObject and TSmartPtr\<T\> — RTTI factory and smart pointer

**Source:** `Source/ModernSyntax.Objects.pas`.  
**No ModernSyntax inter-dependency** (confirmed: dependency scan shows none).

- `TModernObject` (`class sealed`, implements `IModernObject`) — uses `TRttiContext` (class var) to instantiate objects by `TClass` with optional constructor arguments; thread-safe via `TCriticalSection` class var (`Objects.pas:46-48`)
- `TSmartPtr<T: class, constructor>` (`record`) — RAII wrapper; lifetime tied to interface reference count (`Objects.pas:78+`)
- `IAutoRefLock` / `TAutoRefLock` — `TCriticalSection` wrapper (`Objects.pas:63-76`)

### 1.13 TSafeTry and TSafeResult — structured exception builder

**Source:** `Source/ModernSyntax.Safetry.pas`.  
**No ModernSyntax inter-dependency.**

**TSafeTry** (`record`) — fluent builder: `Try(func)`, `Except(proc)`, `Finally(proc)`, `End` → `TSafeResult`.  
**TSafeResult** (`record`) — outcome carrier: `IsOk`, `IsErr`, `GetValue`, `TryGetValue`, `ExceptionMessage`, `AsType<T>`, `IsType<T>`.

Module-level aliases confirmed (`Safetry.pas:55-59`):
```pascal
function &Try(const AFunc: TFunc<TValue>): TSafeTry;
function &Try(const AProc: TProc): TSafeTry;
function &Try: TSafeTry;
```

### 1.14 TModernStreamReader — functional stream processor

**Source:** `Source/ModernSyntax.Stream.pas`.  
**Dependencies:** `ModernSyntax.Objects` (for `TSmartPtr`), `ModernSyntax` base (`Stream.pas:25-26`).

**Fields** (confirmed `Stream.pas:46-49`): `FDataInternal: TSmartPtr<TStreamReader>`, `FDataString: TSmartPtr<TStringStream>`, `FDataReader: TSmartPtr<TStreamReader>`, `FListeners: TList<TStreamReaderListenerEvent>`.

Supports listener registration (`TStreamReaderListenerEvent`) for line-level operation notifications.  
Functional operations: `Map`, `Filter`, `Distinct`, and stream-level `Reduce` — all return `TModernStreamReader` for chaining via `_ProcessStream` (`Stream.pas:54-58`).

### 1.15 TDotEnv — environment variable loader

**Source:** `Source/ModernSyntax.DotEnv.pas`.  
**Dependencies:** RTL only (`Windows`, `Generics.Collections`).

Fields: `FFileName: String`, `FVariables: TDictionary<String, TValue>`, `FUseSystemFallback: Boolean` (confirmed `DotEnv.pas:30`).

Operations: `Open` (reload file), `LoadFiles(array of String)` (multi-file merge), `Save`, `Add`, `Push` (fluent add), `Delete`, `Value<T>(name)` (typed read with exception on missing).  
System fallback confirmed active in `_GetValue` at `DotEnv.pas:323` and `373`:
```pascal
else if FUseSystemFallback then
  ...GetEnvironmentVariable(AName)
```

Imports `Windows` unconditionally (`DotEnv.pas:21`) — platform-guard absent. **Cross-referenced with F-02 in [stack](/analysis/02-stack.md).**

### 1.16 TCrypt — Base64 / MD5 utilities

**Source:** `Source/ModernSyntax.Crypt.pas`.  
**Dependencies:** `ModernSyntax.Std` (confirmed by dependency scan).

Public methods (confirmed `Crypt.pas:38-48`): `DecodeBase64`, `EncodeBase64`, `EncodeString`, `DecodeString`, `EncodeStream`, `DecodeStream`, `Hash(MarshaledAString): Cardinal`, `MD5Simple(TDate, Integer, Integer, String): String`.

`TPacket` variant record (confirmed `Crypt.pas:26-31`) — a 4-byte union used for bit-manipulation in the Base64 codec.

Internal constants `C_ENCODETABLE` (64-char) and `C_DECODETABLE` (128-entry) confirmed in `Crypt.pas` implementation section.

### 1.17 TStd — standard utility singleton

**Source:** `Source/ModernSyntax.Std.pas`.  
**Dependencies:** RTL only + `Windows` (for `OutputDebugString` in `DebugPrint`, guarded `{$IFDEF DEBUG}`).

Pattern: singleton class accessed via `TStd.Get` (class var `FInstance`).  
Public static methods: `IfThen<T>`, `JoinStrings`, `RemoveTrailingChars`, `Iso8601ToDateTime`, `DateTimeToIso8601`, `Min`, `Max`, `Split`, `Clone<T>`, `ToCharArray`, `Fill<T>`, `GenerateSequentialNumber` (confirmed `Std.pas:36-58`).

`TPointerStream` (`class(TCustomMemoryStream)`) in same unit — provides a `TStream` view over an existing memory pointer without copying (`Std.pas:30-34`).

### 1.18 TModernRegEx — regex wrapper

**Source:** `Source/ModernSyntax.RegExpression.pas`.  
**Wraps:** `System.RegularExpressions.TRegEx` (confirmed `RegExpression.pas:28`).  
**No ModernSyntax inter-dependency.**

Provides a thin typed facade over the RTL regex engine; imported by `TMatch` to enable regex-based case branches.

---

## 2. Entity relationship map

```
ModernSyntax.pas (base)
  TFuture <-------------- aliased by TAsync, TCoroutine/IScheduler
  TSet<T>
  IMSObserver             (declared; unused in library — see §6 F-01)

ModernSyntax.ResultPair
  TResultPair<S,F> <----- referenced by TOption<T>.OkOr<F>
                    <----- referenced by TMatch<T> (for result passing)

ModernSyntax.Option
  TOption<T> -----------> TResultPair<S,F>  (via OkOr<F>)

ModernSyntax.Match
  TMatch<T> -----------> TResultPair<S,F>
              ----------> TModernRegEx  (for regex-case branches)
              ----------> TStd

ModernSyntax.Currying
  TCurrying              (standalone; no ModernSyntax dep)
  TPipeline<T>
  TMemoizedCache<T,U>

ModernSyntax.ArrowFun
  TArrow ---------------> TStd, ModernSyntax base

ModernSyntax.Stream
  TModernStreamReader --> TSmartPtr<T> (from Objects)
                     --> ModernSyntax base

ModernSyntax.Objects
  TModernObject          (standalone; no ModernSyntax dep)
  TSmartPtr<T>

ModernSyntax.Async
  TAsync ---------------> TFuture (from base)

ModernSyntax.Coroutine
  TCoroutine
  IScheduler/TScheduler -> TFuture (from base)

ModernSyntax.Crypt ------> TStd (TPointerStream)
ModernSyntax.Std           (RTL only — no ModernSyntax dep)
ModernSyntax.Tuple         (RTL only — no ModernSyntax dep)
ModernSyntax.RegExpression (RTL only — no ModernSyntax dep)
ModernSyntax.SafeTry       (RTL only — no ModernSyntax dep)
ModernSyntax.DotEnv        (RTL only — no ModernSyntax dep)
```

**Dependency count** (by intra-library imports, as measured by the `for f in Source/*.pas` scan):

| Unit | Inbound refs from other Source/ units |
|---|---|
| `ModernSyntax.pas` | 5 (`Async`, `Coroutine`, `Match`, `ArrowFun`, `Stream`) |
| `ModernSyntax.ResultPair` | 2 (`Match`, `Option`) |
| `ModernSyntax.Std` | 3 (`Match`, `ArrowFun`, `Crypt`) |
| `ModernSyntax.RegExpression` | 1 (`Match`) |
| `ModernSyntax.Objects` | 1 (`Stream`) |
| All others | 0 |

`ModernSyntax.pas` is the hub; `ResultPair` and `Std` are secondary hubs.

---

## 3. Actors and roles

This is a library — there are no runtime actors (no users, no services).  
The single actor class is:

| Actor | Role | How they interact with the library |
|---|---|---|
| **Delphi developer** | Consumer | Adds `Source/` to project search path; adds units to `uses`; calls static constructors (`TResultPair<S,F>.New`, `TMatch<T>.Value(x)`, `Async(proc)`, etc.); receives results as value types or interfaces |

There is no authenticated user, no session, and no network boundary in the library itself.

---

## 4. Business rules (confirmed in code)

Each rule was verified in the cited line; the `Source/` path is absolute from repository root.

**RN-001 — TFuture states are mutually exclusive.**  
`SetOk` writes `FIsOK:=True; FIsErr:=False` (`ModernSyntax.pas:212-213`); `SetErr` writes `FIsErr:=True; FIsOK:=False` (`ModernSyntax.pas:205-206`). A `TFuture` cannot simultaneously report success and error.

**RN-002 — TOption\<T\>.None carries no value; Some requires a value.**  
`None` returns a zero-initialised record with `FHasValue=False` (implicit Delphi record zero-init); `Some(AValue)` sets `FHasValue:=True` and `FValue:=AValue`. Confirmed by `TOption<T>.OkOr<F>` branch at `ModernSyntax.Option.pas:391-394` which tests `FHasValue` directly.

**RN-003 — TResultPair\<S,F\>.New starts in rtNone; transitions are one-way.**  
`New` calls `Create(TResultType.rtNone)` (`ResultPair.pas:821-823`). `_SetSuccessValue` forces `FResultType:=rtSuccess`; `_SetFailureValue` forces `FResultType:=rtFailure` (`ResultPair.pas:573-578`). No code path resets from rtSuccess or rtFailure back to rtNone.

**RN-004 — TMatch dispatches through a fixed 17-variant case-type table.**  
`FCases: array[TCaseType] of TCaseGroup` (`Match.pas:74`) maps each of the 17 `TCaseType` variants to a `TDictionary<TValue, TValue>`. Dispatch iterates each type's dictionary in method order. The session state (`TMatchSession`) gates which types are active at a given point in fluent construction.

**RN-005 — TCoroutine lifecycle is linear; finished coroutines do not resume.**  
States `csActive`, `csPaused`, `csFinished` (`Coroutine.pas:34-36`). No code path transitions from `csFinished` back to `csActive` (confirmed: `grep -n "csFinished" Source/ModernSyntax.Coroutine.pas` — only write assignments, no guards that re-activate finished coroutines).

**RN-006 — TDotEnv falls through to OS environment variables when a key is absent (default on).**  
`FUseSystemFallback` defaults to `True` at construction (`DotEnv.pas:40,153`). `_GetValue` at `DotEnv.pas:323` and `373` calls `GetEnvironmentVariable(AName)` when the key is absent from `FVariables`. Developer can opt out by passing `AUseSystemFallback:=False`.

**RN-007 — TMemoizedCache caches by function input; subsequent calls with the same input skip re-execution.**  
`TMemoizedCache<T,U>.GetOrAdd(Key, Func)` delegates to `TDictionary.TryGetValue`; adds on miss (`Currying.pas:157`). Thread safety declared via `SyncObjs.TCriticalSection` in `TCurrying` (`Currying.pas:24`).

**RN-008 — TSmartPtr\<T\> lifetime is interface-reference-counted.**  
`TSmartPtr<T: class, constructor>` is a `record` that holds an `ISmartPtr<T>` interface (`Objects.pas:78`). When the record goes out of scope, the interface reference drops to zero, triggering `_Release` which frees the wrapped object.

**RN-009 — TSafeTry.End always executes the Finally block, regardless of exception.**  
`_EndExecute` (`Safetry.pas`) runs the try body, catches exceptions into `TSafeResult._Err`, and always calls `FFinally` in the `finally` section. `&End` delegates exclusively to `_EndExecute`.

---

## 5. Primary use cases

All scenarios are from the developer's perspective; library has no other actor.

**UC-001 — Pattern-match a value with multiple case kinds**  
Developer calls `TMatch<T>.Value(x).CaseEq(v, action).CaseGt(n, action).Default(fallback).Exec`.  
Supported case kinds: equality, greater-than, less-than, membership, type-is, range, guard predicate, regex, try/except (17 total — RN-004).  
Units: `ModernSyntax.Match`.

**UC-002 — Railway-style error propagation**  
Developer writes `TResultPair<String, Exception>.New.Success(value).ThenOf(fn1).Map(fn2).SuccessOrDefault('')`.  
On first `Failure(...)`, subsequent chained calls short-circuit on the failure track.  
Units: `ModernSyntax.ResultPair`.

**UC-003 — Null-safe optional value handling**  
Developer uses `TOption<Integer>.Some(42).Map(double).Filter(positive).UnwrapOr(0)`.  
`OkOr<F>` converts to `TResultPair` when integration with the error track is needed (RN-002).  
Units: `ModernSyntax.Option`, `ModernSyntax.ResultPair`.

**UC-004 — Partial application and function composition**  
`TCurrying.Partial(add, 10)` returns a unary function.  
`TCurrying.Pipe(x).Apply(fn1).Map(fn2).Value` pipelines transformations.  
`TCurrying.Memoize(expensiveFunc)` wraps with `TMemoizedCache` (RN-007).  
Units: `ModernSyntax.Currying`.

**UC-005 — Async task with optional await**  
`Async(proc).Await(continueProc, timeoutMs)` runs `proc` on `System.Threading.TTask`, blocks up to timeout, returns `TFuture`.  
`NoAwait` fires-and-forgets.  
Units: `ModernSyntax.Async`, `ModernSyntax`.

**UC-006 — Coroutine-based interval scheduling**  
`TScheduler.New(500{ms}).Add('task', coroutineFunc, initValue).Started(onStart).Run.Finished(onDone)`.  
Each registered `TCoroutine` runs on its own interval; observer chain notifies dependents on value change.  
Units: `ModernSyntax.Coroutine`, `ModernSyntax`.

**UC-007 — Fluent exception handling without bare try/except**  
`TSafeTry.Try(riskFunc).Except(logError).Finally(cleanup).End` returns `TSafeResult`; caller queries `IsOk` / `GetValue`.  
Units: `ModernSyntax.SafeTry`.

**UC-008 — Environment variable loading with system fallback**  
`TDotEnv.Create('.env').Value<String>('DB_HOST')` reads from file, falls through to OS environment when absent (RN-006).  
Multi-file merge via `LoadFiles(['base.env', 'local.env'])`.  
Units: `ModernSyntax.DotEnv`.

**UC-009 — Functional stream processing**  
`TModernStreamReader.Create(stream).Map(transformLine).Filter(predicate).Reduce(accumulate)` chains transformations lazily, notifies registered listeners per line.  
Units: `ModernSyntax.Stream`, `ModernSyntax.Objects`.

**UC-010 — RTTI-based object instantiation**  
`TModernObject.New.Factory(TConcreteClass)` creates an instance without knowing the concrete type at compile time; optional `Factory(cls, args, methodName)` calls a named constructor.  
Units: `ModernSyntax.Objects`.

---

## 6. Findings (domain-level drift)

**F-01 — IMSObserver is declared but never implemented or consumed in Source/.**  
Command: `grep -r "IMSObserver" Source/*.pas` → only `ModernSyntax.pas` line 24. No unit in `Source/` implements the interface or references it. The observer protocol is re-implemented ad-hoc in `TCoroutine` via `FObserverList: TList<TCoroutine>` (`Coroutine.pas:71`) — a different, incompatible mechanism. `IMSObserver` is dead interface surface.

**F-02 — TDotEnv calls Windows-only API without platform guard.**  
`GetEnvironmentVariable` and `SetEnvironmentVariable` are called at `DotEnv.pas:415,420,427` (and two more sites at lines 373, 400). The `Windows` unit is in the `uses` clause unconditionally (`DotEnv.pas:21`). On non-Windows targets this unit will fail to compile. The README's cross-platform claim for this module is unsupported. **Cross-references [stack](/analysis/02-stack.md) finding F-01.**

**F-03 — TStd imports Windows unconditionally despite its only Windows call being debug-guarded.**  
`Std.pas:80` calls `OutputDebugString` inside `{$IFDEF DEBUG}`. The `Windows` unit in `uses` (`Std.pas:67`) is not guarded; non-Windows compilation will fail before the `{$IFDEF}` fires. Same root cause as F-02.

**F-04 — TResultPair carries two function-array fields (FSuccessFuncs, FFailureFuncs) with no visible population site.**  
`FSuccessFuncs: TArray<TFuncOk>` and `FFailureFuncs: TArray<TFuncFail>` declared at `ResultPair.pas:65-66`. No public method appends to these arrays (confirmed: `grep -n "FSuccessFuncs\|FFailureFuncs" Source/ModernSyntax.ResultPair.pas` → only declaration lines). These may be vestigial from an earlier design or populated inside an implementation method not examined in this pass.

---

## 7. Open questions

**Q1 — What populates FSuccessFuncs / FFailureFuncs in TResultPair?**  
Tried: `grep -n "FSuccessFuncs\|FFailureFuncs" Source/ModernSyntax.ResultPair.pas` — found only the declaration at lines 65-66. No write site in any public method. Possible interpretations: (a) vestigial — allocated but unused, (b) populated inside an internal method whose body was not examined. Requires reading the full implementation section of `ResultPair.pas` (lines 550–1083).

**Q2 — Is IMSObserver intended as an extension point for consumers, or is it dead code scheduled for removal?**  
Tried: `grep -r "IMSObserver" .` excluding `.project/` → zero hits outside `ModernSyntax.pas`. No test references it. No example uses it. No ADR or TODO comment found near its declaration at `ModernSyntax.pas:24`. Could not answer from code alone; requires author intent.
