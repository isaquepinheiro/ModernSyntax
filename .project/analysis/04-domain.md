---
type: analysis
title: "04 Domain: ModernSyntax"
description: "Entities, relationships, actors, business rules, and use cases extracted from source code measurements."
status: stable
tags: [domain, discovery, delphi, functional-programming, entities]
sources:
  - id: intake
    resource: /analysis/00-intake.md
    title: "00 Intake — ModernSyntax"
  - id: structure
    resource: /analysis/01-structure.md
    title: "01 Structure — ModernSyntax"
---

# ModernSyntax — Domain

## 1. What the system does

ModernSyntax is a source-only Object Pascal library that provides
functional-programming idioms and modern-syntax extensions to the Delphi RTL.
It does not contain an application; the domain is the library API itself —
specifically, the value types, combinators, and concurrency primitives it
exports to downstream Delphi programs.

Confirmed at `Source/ModernSyntax.pas` line 4 (file header comment):
> "Functional programming toolkit and modern syntax extension for Delphi."

The library adds no persistent state (no database, no network). Its entire
runtime footprint is the in-process object graph managed by the library's
types. The library has one actor and nineteen primary exported entities (see §2
and §3).

---

## 2. Actor

There is one actor: the **Delphi Developer** (library consumer). The actor
adds `./Source` to their Delphi library path
(confirmed: `boss.json` line 6 `"mainsrc": "./Source"`;
`pubdelphi.json` line 5 `"sources": ["./Source/"]`)
and `uses` individual sub-units in their own code.

No end-user actor exists; the library ships no executable.
No admin or operator role exists.

---

## 3. Entities

Measurement: `grep -c "^  T[A-Za-z].*= \(record\|class\)" Source/ModernSyntax.*.pas`
yielded per-file counts; the entities below are the 19 **public, named types**
that form the library's API surface — internal helper records are excluded.

### 3.1 Core functional types

| Entity | Kind | Defined at | State / discriminant |
|---|---|---|---|
| `TOption<T>` | `record` | `ModernSyntax.Option.pas:48` | `FHasValue: Boolean` (line 50) |
| `TResultPair<S,F>` | `record` | `ModernSyntax.ResultPair.pas:57` | `TResultType` enum: `rtNone`, `rtSuccess`, `rtFailure` (line 25) |
| `TMatch<T>` | `record` | `ModernSyntax.Match.pas:63` | `TMatchSession` enum: `sMatch`, `sGuard`, `sCase`, `sDefault`, `sTryExcept` (line 57) |
| `TFuture` | `record` | `ModernSyntax.pas:32` | `FValue: TValue` + `FError: String`; `.IsOk`/`.IsErr` accessors (lines 180-210) |
| `TSafeTry` | `record` | `ModernSyntax.Safetry.pas:42` | wraps a try block; `.&End` returns `TSafeResult` (line 54 — `End` is a reserved word; method is declared `function &End`) |
| `TSafeResult` | `record` | `ModernSyntax.Safetry.pas:23` | `.IsOk`, `.IsErr`, `.GetValue`, `.ExceptionMessage` (lines 33-38) |

#### TOption<T> — null-safe optional

Created via:
- `TOption<T>.Some(AValue)` — valued option (`FHasValue := True`, `FValue := AValue` — confirmed lines 247-248)
- `TOption<T>.None` — empty option (`FHasValue := False` — confirmed line 253)

Key operations (confirmed at `ModernSyntax.Option.pas` lines 56-233):
`IsSome`, `IsNone`, `Unwrap`, `UnwrapOr`, `Map<U>`, `Filter`, `AndThen<U>`,
`Otherwise`, `OrElse`, `OkOr<F>`, `Flatten<U>`, `Zip`, `Replace`, `Take`,
`Contains`, `IsSomeAnd`, `Match`, `IfSome`.

#### TResultPair<S,F> — success/failure container

Created via `.New` (state `rtNone` — uninitialized; line 823), then populated
by `.Success(ASuccess)` (state -> `rtSuccess`) or `.Failure(AFailure)` (state
-> `rtFailure`). Both `FSuccess` and `FFailure` are `TResultPairValue<*>`
wrapper records (lines 65-66).

Key operations (confirmed `ModernSyntax.ResultPair.pas` lines 143-554):
`Map`, `FlatMap`, `Reduce`, `When`, `Pure`, `Swap`, `Recover`,
`SuccessOrElse`, `SuccessOrException`, `SuccessOrDefault`,
`FailureOrElse`, `FailureOrException`, `FailureOrDefault`,
`isSuccess`, `isFailure`, `ValueSuccess`, `ValueFailure`,
`Exec`, `Ok`, `Fail`, `ThenOf`, `ExceptOf`, `Return`, `Dispose`.

#### TMatch<T> — multi-strategy pattern matcher

Entry point: `TMatch<T>.Value(AValue)` (line 239) opens a match session.
17 case-kind variants (confirmed `TCaseType` enum, lines 33-49):
`CaseIf`, `CaseEq`, `CaseGt`, `CaseLt`, `CaseIn`, `CaseIs`, `CaseRange`,
`CaseRegex`, `Default`, `TryExcept` — each with proc and func overloads.
Additional: `Combine` (merge sessions). Note: there is no public `Guard` method — the guard concept is implemented internally via `FUseGuard`/`_ExecuteProcGuard` (`Match.pas:70,128`); the public API for conditional branches is the `CaseIf(const ACondition: Boolean)` overload (`Match.pas:157`).
`Execute` terminates the chain and returns
`TResultPair<Boolean, String>` (line 700) or `TResultPair<R, String>` (line 734).

### 3.2 Concurrency types

| Entity | Kind | Defined at | Notes |
|---|---|---|---|
| `TAsync` | `record` | `ModernSyntax.Async.pas:50` | wraps `TTask.Run` (confirmed line 213) |
| `TCoroutine` | `class sealed` | `ModernSyntax.Coroutine.pas:64` | cooperative, state-machine-driven |
| `TCoroutineState` | `enum` | `ModernSyntax.Coroutine.pas:35` | `csActive`, `csPaused`, `csFinished` |
| `IScheduler` / `TScheduler` | `interface` / `class` | `ModernSyntax.Coroutine.pas:101,122` | owns and runs a list of `TCoroutine` instances |

`TAsync` methods (confirmed lines 67-76): `Run`, `NoAwait`, `Await`, `Cancel`,
`CheckCanceled`, `Status`, `GetId`. Backing implementation calls
`System.Threading.TTask.Run` (confirmed line 213) and dispatches continuations
via `TThread.Queue` (confirmed lines 227, 271, 313).

`TCoroutine` state transitions: initial `csActive` (direct field write in constructor, `FState :=` — line 492) → `csPaused` on `Suspend` (via `State` property setter, line 281) → back to `csActive` on `Resume` (line 299) → `csFinished` after body returns (line 398). `csFinished` is terminal (no subsequent write to `csActive` or `csPaused` — verified: `grep "FState :=" Source/ModernSyntax.Coroutine.pas` → one result, line 492; all other state changes go through the public `State` property setter at `Coroutine.pas:96`).

### 3.3 Higher-order function types

| Entity | Kind | Defined at | Primary purpose |
|---|---|---|---|
| `TCurrying` | `record` | `ModernSyntax.Currying.pas:163` | function composition, currying, memoize, list combinators |
| `TPipeline<T>` | `record` | `ModernSyntax.Currying.pas:97` | chainable single-value transform pipeline |
| `TMemoizedCache<T,U>` | `class` | `ModernSyntax.Currying.pas:134` | `TDictionary<T,U>`-backed cache for `TCurrying.Memoize` |
| `TArrow` | `record` | `ModernSyntax.ArrowFun.pas:37` | lambda/closure factory producing `TProc`/`TFunc<TValue>` |

`TCurrying` exposes 56 class functions
(counted: `grep -c "class function" Source/ModernSyntax.Currying.pas -> 56`).
Named operations (confirmed lines 200-329): `Compose`, `Partial`, `Memoize`,
`Pipe`, `Curry`, `UnCurry`, `Map`, `Filter`, `Fold`, `Take`, `Drop`, `Zip`,
`Any`, `All`, `GroupBy`, `TakeWhile`, `DropWhile`, `Distinct`, `Reverse`.

### 3.4 Stream / collection types

| Entity | Kind | Defined at | Notes |
|---|---|---|---|
| `TModernStreamReader` | `class` | `ModernSyntax.Stream.pas:40` | lazy text-line pipeline |
| `TSet<T>` | `class sealed` | `ModernSyntax.pas:88` | `TDictionary<T,Byte>`-backed set |
| `TTuple<K>` | `record` | `ModernSyntax.Tuple.pas:46` | typed key-indexed tuple |
| `TTuple` | `record` | `ModernSyntax.Tuple.pas:68` | untyped `array of TValue` tuple |

`TModernStreamReader` pipeline operations (confirmed lines 164-293):
`Map`, `Filter`, `Reduce`, `ForEach`, `Distinct`, `Skip`, `Sort`, `Take`,
`Concat`, `Partition`, `Join`, `AsLine`, `AsString`, `Any`, `All`, `Comprehend`.
`Partition` returns `TPair<TModernStreamReader, TModernStreamReader>`
(confirmed line 252).

### 3.5 Supporting types

| Entity | Kind | Defined at | Notes |
|---|---|---|---|
| `TModernObject` | `class sealed` | `ModernSyntax.Objects.pas:39` | RTTI-based object factory |
| `TSmartPtr<T>` | `record` | `ModernSyntax.Objects.pas:80` | reference-counted smart pointer |
| `TMutableRef<T>` | `record` | `ModernSyntax.Objects.pas:123` | mutable smart reference |
| `TDotEnv` | `class` | `ModernSyntax.DotEnv.pas:26` | `.env` / system-env loader |
| `TStd` | `class` | `ModernSyntax.Std.pas:36` | generic utilities (IfThen, Min, Max, ISO 8601, etc.) |
| `TCrypt` | `record` | `ModernSyntax.Crypt.pas:33` | Base64, stream encode/decode, hash, MD5 |
| `TModernRegEx` | `class` | `ModernSyntax.RegExpression.pas:28` | regex wrapper + domain validators |
| `IMSObserver` | `interface` | `ModernSyntax.pas:27` | **dead code** — declared but not implemented by any type; `TCoroutine` uses its own `TList<TCoroutine>` observer list (`Coroutine.pas:73`) with no connection to this interface (`grep -rn "IMSObserver" Source/*.pas` → 1 result, the declaration itself) |

`TModernRegEx` exposes 12 domain-specific validators
(counted: `grep -c "class function IsMatch" Source/ModernSyntax.RegExpression.pas -> 14`
minus 2 generic overloads = 12, confirmed at lines 98-215):
`IsMatchValidEmail`, `IsMatchUUID`, `IsMatchIPV4`, `IsMatchCEP`,
`IsMatchCPF`, `IsMatchCNPJ`, `IsMatchDDDPhone`, `IsMatchPlacaMercosul`,
`IsMatchPlaca`, `IsMatchData`, `IsMatchCredCard`, `IsMatchURL`.
Five validators (`CEP`, `CPF`, `CNPJ`, `DDDPhone`, `PlacaMercosul`) target
Brazilian-specific document and contact formats.

`TDotEnv` constructor (confirmed line 40):
`constructor Create(const AFileName: String = '.env'; AUseSystemFallback: Boolean = True)`.
When `AUseSystemFallback = True` the loader falls back to OS environment
variables for any name absent from the file (confirmed by fallback path
before the exception at lines 337-341).

---

## 4. Entity relationships

```
TOption<T>
  --OkOr<F>-->  TResultPair<T,F>                       Option.pas:188

TMatch<T>
  --Execute-->  TResultPair<Boolean,String>             Match.pas:700
  --Execute<R>--> TResultPair<R,String>                Match.pas:734

TAsync
  --Run/Await-->  TFuture                               Async.pas:67-71
                  (TFuture defined at ModernSyntax.pas:32)

TCoroutine
  --Attach/Detach-->  TCoroutine (as observer)          Coroutine.pas:87-88
  --owned by-->  IScheduler / TScheduler                Coroutine.pas:101-160
  [IMSObserver is NOT implemented by TCoroutine — dead code, see §3.5]

TCurrying
  --Pipe<T>-->  TPipeline<T>                            Currying.pas:220
  --Memoize<T,U>-->  TMemoizedCache<T,U>               Currying.pas:904-914

TSafeTry
  --&End-->  TSafeResult                                Safetry.pas:54

TModernStreamReader
  --Partition-->  TPair<TModernStreamReader,
                         TModernStreamReader>           Stream.pas:252

TSmartPtr<T>
  --Match<R>-->  R  (null/valid dispatch)               Objects.pas:105

TMutableRef<T>
  --Match<R>-->  R                                      Objects.pas:151
```

---

## 5. Business rules

**RN-001 — TOption<T> is either Some or None, never both.**
`FHasValue` is set `True` only in `Some` (line 247) and `False` only in
`None` (line 253). No other public method mutates it.

**RN-002 — TResultPair<S,F> carries at most one live branch.**
`FSuccess` is written only by `_SetSuccessValue` (line 575); `FFailure` only
by `_SetFailureValue` (line 569). The discriminant switches between
`rtSuccess` (line 680) and `rtFailure` (line 685); no code path sets both
branches simultaneously (verified by reading `Success` and `Failure` method
bodies — neither invokes the other).

**RN-003 — TMatch<T>.Execute always returns TResultPair.**
Both overloads at lines 207-208 (declarations) and 700, 734 (implementations)
return `TResultPair`. There is no void Execute path.

**RN-004 — TCoroutine csFinished is a terminal state.**
State transitions: `csActive` set in constructor (`FState :=` direct write, line 492),
`csPaused` on Suspend (via `State` property setter, line 281), `csActive` on Resume
(line 299), `csFinished` after body exits (line 398). `csFinished` is terminal — no
subsequent transition writes `csActive` or `csPaused` (verified: `grep "FState :="
Source/ModernSyntax.Coroutine.pas` → one result at line 492; all other state changes go
through the public `State` property at `Coroutine.pas:96`; `grep "csFinished"` shows
only the write at 398 and read-guards at 372 and 403).

**RN-005 — TDotEnv file variables take priority; OS environment is the fallback.**
`Get<T>` (`DotEnv.pas:296`) calls `FVariables.TryGetValue(AName, LResult)` first
(the in-memory dictionary populated from the `.env` file). Only when that lookup
fails AND `FUseSystemFallback = True` does it call `EnvLoad(AName)` (OS env read,
`DotEnv.pas:323-341`). The `.env` file wins; OS is the fallback, not the primary.

**RN-006 — TMemoizedCache stores results on first call; subsequent calls return cache.**
`GetOrAdd` checks `FCache: TDictionary<T,U>` (line 136); if the key is absent
it calls the wrapped function and stores the result; if present it returns the
cached value immediately (line 157).

**RN-007 — TAsync continuations run on the main-thread message queue.**
`TThread.Queue` (confirmed lines 227, 271, 313) posts continuations to the
main-thread message loop — not `TThread.Synchronize`. A blocked main thread
will therefore never receive the continuation.

**RN-008 — TResultPair.New creates an rtNone (uninitialized) container.**
`TResultPair<S,F>.New` calls `Create(TResultType.rtNone)` (line 823).
Neither `isSuccess` nor `isFailure` returns `True` for `rtNone` (lines
680-685), leaving the container silently inert until populated.

**RN-009 — TMatch<T> is single-use; Execute disposes internal state.**
`TMatch<T>.Execute` has a `finally _Dispose` block (`Match.pas:729–731`).
After `Execute` returns, the case dictionaries are cleared and the record is
unusable. Callers must not call `Execute` twice on the same `TMatch<T>` variable.

**RN-010 — Arms added after a wrong session state are silently discarded.**
Every arm method (`CaseEq`, `CaseIf`, `CaseGt`, etc.) opens with:
```pascal
if not (FSession in [TMatchSession.sMatch, TMatchSession.sGuard, TMatchSession.sCase]) then
  Exit;
```
(`Match.pas:276, 289, 302, ...`). If a consumer calls an arm after `Default` or
after `Execute`, the arm is silently dropped with no error. This is the most
surprising behaviour of the type: a misplaced arm call compiles and runs, but
the branch it was supposed to handle is never registered.

---

## 6. Use cases

### UC-01 — Null-safe value handling
Actor: Delphi Developer.
Wrap a nullable computation in `TOption<T>.Some`/`None`; chain `Map`,
`Filter`, `AndThen`; extract via `Unwrap`, `UnwrapOr`, or `Match`.
Entities: `TOption<T>`.
Cross-entity: `OkOr<F>` (line 188) converts to `TResultPair<T,F>`.

### UC-02 — Railway-oriented error propagation
Actor: Delphi Developer.
Initialise `TResultPair<S,F>.New`; set `Success` or `Failure`; chain
`ThenOf`, `ExceptOf`, `Map`, `FlatMap`; inspect with `isSuccess` or extract
with `SuccessOrElse` / `FailureOrElse`.
Entities: `TResultPair<S,F>`.

### UC-03 — Multi-strategy pattern matching
Actor: Delphi Developer.
Open `TMatch<T>.Value(x)`; add arms via `CaseEq`, `CaseGt`, `CaseLt`,
`CaseIn`, `CaseRange`, `CaseIs`, `CaseIf`, `CaseRegex`; close with `Default`;
call `Execute` to obtain a `TResultPair`.
Entities: `TMatch<T>`, `TResultPair`.

### UC-04 — Async task execution
Actor: Delphi Developer.
Declare `TAsync`; call `Run` or `NoAwait`; chain `Await` for continuation;
receive a `TFuture`; check `.IsOk`/`.IsErr`.
Entities: `TAsync`, `TFuture`.

### UC-05 — Cooperative coroutine scheduling
Actor: Delphi Developer.
Create `TScheduler`; call `Add` to register named coroutine functions
(`TFuncCoroutine`); call `Run`; use `Next` to step, `Suspend`/`Resume` to
pause/unpause, `Send` to push values, `Yield` to pull.
Entities: `TCoroutine`, `IScheduler`, `TScheduler`, `TFuture`.

### UC-06 — Functional text-stream processing
Actor: Delphi Developer.
Wrap a `TStream` / `TStreamReader` in `TModernStreamReader`; chain `Map`,
`Filter`, `Distinct`, `Sort`, `Take`, `Skip`, `Concat`; terminate with
`ForEach`, `Reduce`, `Join`, `AsString`, `Any`, `All`.
Entities: `TModernStreamReader`.

### UC-07 — Partial application and function composition
Actor: Delphi Developer.
Use `TCurrying.Curry` to split a two-argument function; `Partial` to fix one
argument; `Compose` to chain two unary functions; `Pipe<T>` to start a
`TPipeline<T>` chain.
Entities: `TCurrying`, `TPipeline<T>`.

### UC-08 — Memoised function calls
Actor: Delphi Developer.
Wrap a pure function with `TCurrying.Memoize<T,U>(F)`; call the returned
function repeatedly; `TMemoizedCache<T,U>` returns the cached result on
repeated equal keys.
Entities: `TCurrying`, `TMemoizedCache<T,U>`.

### UC-09 — Safe exception handling
Actor: Delphi Developer.
Create `TSafeTry`; chain `&Except(proc)` for the error path and `&Finally(proc)`
for cleanup; call `&End` to obtain a `TSafeResult`; inspect with `.IsOk`/`.IsErr`.
(`End`, `Except`, `Finally` are all reserved words; the ampersand prefix is required — confirmed `ModernSyntax.Safetry.pas:54, 209`.)
Entities: `TSafeTry`, `TSafeResult`.

### UC-10 — Environment configuration loading
Actor: Delphi Developer.
Create `TDotEnv('.env')`; call `Open` or `LoadFiles`; retrieve typed values
via `Value<T>(name)`, `GetOr<T>`, or `TryGet<T>`.
Entities: `TDotEnv`.

### UC-11 — RTTI-based object construction and smart-pointer wrapping
Actor: Delphi Developer.
Call `TModernObject.New.Factory(TClass)` to construct an object via RTTI
without knowing the concrete type; wrap in `TSmartPtr<T>` for automatic
lifecycle; use `TSmartPtr<T>.Match` to dispatch on null/valid state.
Entities: `TModernObject`, `TSmartPtr<T>`, `TMutableRef<T>`.

### UC-12 — Brazilian document format validation
Actor: Delphi Developer.
Call `TModernRegEx.IsMatchCPF(s)`, `IsMatchCNPJ(s)`, `IsMatchCEP(s)`,
`IsMatchDDDPhone(s)`, or `IsMatchPlacaMercosul(s)` to validate user input
against Brazilian document patterns.
Entities: `TModernRegEx`.
Limitation: these are structural regex checks only; no checksum digit
verification is implemented (confirmed: `grep -n "mod\|Mod\|checksum\|digito"
Source/ModernSyntax.RegExpression.pas` returns no match).

---

## 7. Domain findings

**D-01 — rtNone has no public test method (silent limbo state).**
`TResultType.rtNone` (line 25) is produced by `TResultPair.New` (line 823).
Neither `isSuccess` nor `isFailure` acknowledges it — both return `False`,
leaving the container inert with no error signal and no public way to detect
the uninitialized state.

**D-02 — Brazilian regex validators perform structural-only checks.**
`IsMatchCPF` and `IsMatchCNPJ` (lines 138-149) are pure regex comparisons.
CPF and CNPJ have mandatory digit-verification algorithms that the library does
not implement. A passing check is not proof of a valid document number.

**D-03 — Umbrella unit does not re-export sub-units.**
`ModernSyntax.pas` `uses` clause (lines 18-20) lists only `Rtti`, `SysUtils`,
`Generics.Collections`, `Generics.Defaults`. Consumers must enumerate every
needed sub-unit individually; there is no single-unit import path for the full
API.

**D-04 — TAsync continuation model risks deadlock in blocking-main-thread scenarios.**
`TThread.Queue` (lines 227, 271, 313) posts continuations to the main-thread
message loop. An application whose main thread blocks (e.g., on a modal wait
loop) will not drain the queue, and the continuation will never execute. This
risk is not documented in the source.

**D-05 — Four units have no test program and no XML-doc specification.**
`ModernSyntax.ArrowFun`, `ModernSyntax.Coroutine`, `ModernSyntax.Crypt`,
`ModernSyntax.RegExpression` have no `PTest*.dpr` file
(confirmed from `find 'Test Delphi' -name '*.dpr'` — no match for these
four names) and carry no XML documentation comments that would substitute as a
specification.
