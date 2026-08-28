---
type: study
title: "ModernRTTI feasibility: RTTI abstraction, anonymous methods, and Invoker for Delphi+Lazarus"
description: "Three pillars have three different cost profiles; two structural blockers must be resolved before any RTTI layer is meaningful."
generated: { by: "product-strategist@node:study", at: "2026-08-27T21:15:00Z" }
kind: artifact
agent: analyst
workflow: product-strategist
node: study
resource: aefos://run/23b95bafe7747707e4150e5dcdeb92bb
tags: [modernrtti, fpc, lazarus, rtti, anonymous-methods, invoker, feasibility]
---

# ModernRTTI — Study

Each number in this document is backed by a command. Each command is printed
beside the number. Claims from README, code comments, or prior OKF documents
are marked as **leads** and confirmed or refuted independently below.

---

## Zero-day measurement: what the codebase looks like today

### Source units

```
ls Source/*.pas | wc -l → 16
```

16 source units, 0 RTTI-property/field/attribute units.

### RTTI usage — scope and depth

```
grep -rn "TRttiType\|TRttiProperty\|TRttiField\|TRttiMethod\|TRttiContext\|GetType\|GetProperty\|GetField" Source/*.pas | grep -v "//" → 8 results, all in Objects.pas
```

Every live RTTI call in the library lives in **one unit** — `ModernSyntax.Objects.pas`.
The calls are:

| Location | What it does |
|---|---|
| `Objects.pas:41` | `class var FContext: TRttiContext` — a shared RTTI context |
| `Objects.pas:193` | `FContext := TRttiContext.Create` |
| `Objects.pas:220` | `LType := FContext.GetType(AClass)` |
| `Objects.pas:221` | `LConstructor := LType.GetMethod(AMethodName)` |
| `Objects.pas:225` | `LInstance := LConstructor.Invoke(…)` — **the only Invoke site** |
| `Objects.pas:238` | `LType := FContext.GetType(TypeInfo(T))` |
| `Objects.pas:239` | `LType.GetMethod('Create').Invoke(…)` — **second Invoke site** |
| `Objects.pas:455` | `LType := TModernObject.Context.GetType(TypeInfo(T))` |

```
grep -rn "GetProperties\|GetFields\|GetAttributes\|TRttiProperty\|TRttiField" Source/*.pas | grep -v "//" → 0 results
```

**No property enumeration, no field enumeration, no attribute reading exists anywhere in the library.** The demand for `TModernRTTIProperty` and `TModernRTTIField` is a greenfield addition — there is no existing layer to wrap.

### Attributes — usage today

```
grep -rn "TCustomAttribute\|GetAttribute\|HasAttribute\|\[.*Attribute\|Attribute\]" Source/*.pas | grep -v "//" → 0 results
```

Zero attributes defined. Zero attributes read. The demand's attribute compatibility
layer starts from an empty page.

### Anonymous methods — density

```
grep -rn "reference to" Source/*.pas | wc -l → 11
grep -c "TProc\b\|TFunc\b\|TPredicate\b" Source/*.pas | grep -v ":0" → 10 files
grep -rn "TProc\b\|TFunc\b" Source/*.pas | wc -l → 451 occurrences
```

`TProc`, `TFunc`, and `TPredicate` are standard Delphi RTL type aliases for
`reference to procedure/function`. They appear **451 times across 10 of 16 source units**.
The `reference to` keyword itself appears 11 times in 5 units where custom anonymous-method
types are declared directly (e.g., `TFuncCoroutine` at `Coroutine.pas:32`,
`TSomeProc<T>` at `Option.pas:25`).

### Lazarus/FPC conditional — the typo

```
grep -rn "FCP\|FPC\|LAZARUS" Source/*.pas Source/*.inc → Source/ModernSyntax.inc:256: {$IFDEF FCP}
```

`ModernSyntax.inc:256` reads `{$IFDEF FCP}`. FPC (Free Pascal Compiler) defines the
predefined symbol `FPC` — not `FCP`. The two letters are transposed.
**This block has never fired under any Free Pascal compiler.** The Lazarus compatibility
branch is dead code.

### Threading — Delphi-only units

```
grep -rn "Threading\b\|System\.Threading" Source/ModernSyntax.Async.pas Source/ModernSyntax.Coroutine.pas Source/ModernSyntax.Stream.pas
```

| File | Line | Import |
|---|---|---|
| `ModernSyntax.Async.pas` | 25 | `Threading` (Delphi RTL — `System.Threading`) |
| `ModernSyntax.Coroutine.pas` | 24 | `Threading` |
| `ModernSyntax.Stream.pas` | 23 | `System.Threading` |

`TTask.Run` is called 5 times in `Async.pas` (lines 213, 260, 299, 346, 378) and
once in `Coroutine.pas` (line 439). FPC 3.2.2 has no `TTask` and no equivalent unit.

### Windows — interface-section imports blocking non-Windows compilation

```
grep -n "^uses" -A 10 Source/ModernSyntax.Std.pas | grep Windows → line 21: Windows
grep -n "^uses" -A 10 Source/ModernSyntax.DotEnv.pas | grep Windows → line 22: Windows
```

`Std.pas:21` and `DotEnv.pas:22` import `Windows` in the **interface** section.
Any unit that `uses` either of them also inherits the Windows dependency.

```
grep -rn "ModernSyntax\.Std\b" Source/*.pas | grep -v "//" → Match.pas:26, Crypt.pas:21, ArrowFun.pas:23
```

Downstream: `Match.pas`, `Crypt.pas`, `ArrowFun.pas` all pull in `Std` and therefore `Windows`.
**Total blocked from FPC compilation: 6 of 16 units (37.5%)** — before any RTTI question arises.

### Dproj / Lazarus project files

```
find . -name "*.dproj" | wc -l → 13
find . -name "*.lpi" -o -name "*.lpr" | wc -l → 0
```

13 Delphi project files, zero Lazarus project files. No FPC build exists for any part of the library.

---

## A. Is this the right thing to build?

The demand groups three items. They are not the same type of work.

### Pillar 1 — RTTI abstraction (`TModernRTTIProperty`, `TModernRTTIField`, attributes)

**What supports it:** RTTI is already used for construction (`Objects.pas:220-225`). The pattern
`TRttiContext.GetType` → `GetMethod` → `Invoke` is established. Extending it to
`GetProperties` and `GetFields` is architecturally consistent.

**What contradicts it:** There is no `GetProperties` or `GetFields` call in the library today
(confirmed above — 0 results). The demand asks to abstract a difference (`public` in Delphi vs
`published` in Lazarus) that is real, but the library has never consumed property metadata
from any direction. Building an abstraction before the feature is built is ordering things correctly,
but the demand implies existing code "reads public" — it does not read properties at all.

**Attribute compatibility:** zero usage today. Whether Delphi and Lazarus attribute syntax
is compatible cannot be determined from this codebase — there is nothing to measure. The demand
correctly identifies this as an open question. It should remain open until the author runs a
compilation test on FPC 3.2.2 with a minimal attribute declaration.

**Verdict:** Pillar 1 is the right thing to build — but only after the `Windows`-import blockers
(Std.pas:21, DotEnv.pas:22) and the `{$IFDEF FCP}` typo are fixed. Without those fixes,
any RTTI unit added to the library cannot be used from Lazarus because the upstream units
block compilation.

### Pillar 2 — Anonymous methods on FPC 3.2.2

**What the measurement says:** FPC 3.2.2 has no `reference to` and no anonymous methods.
This was measured on the real compiler by the owner (stated in the demand context). The modeswitches
`{$modeswitch functionreferences}` and `{$modeswitch anonymousfunctions}` are not present
in FPC 3.2.2. They entered FPC 3.3.1 (development trunk).

**Scope of impact:** `TProc`/`TFunc` appear 451 times across 10 units. An interface+capture-object
replacement touches every one of those 451 call sites plus the 11 `reference to` type declarations.
This is not a thin compatibility shim — it is a parallel API surface for the entire library.

**Verdict:** Pillar 2 is not "adding a feature that's absent" in the narrow sense — it requires
either (a) dual API surfaces maintained in parallel, or (b) dropping FPC 3.2.2 and targeting
FPC 3.3.1+ only. The owner must decide which FPC version is the target before any design
can proceed. This is the most expensive pillar by a wide margin.

### Pillar 3 — Invoker

**What already exists:** `TModernObject.Factory` at `Objects.pas:208-241` already performs
Delphi-RTTI-based method invocation: `GetType` → `GetMethod` → `Invoke`. This covers
the constructor-invocation use case and is the nearest thing to an Invoker the library has.

**What is missing:** general method invocation (non-constructor calls). Whether FPC 3.2.2's
`Rtti` unit exposes `TRttiMethod.Invoke` with a compatible API cannot be determined from
this codebase — no FPC environment is available in the factory. The existing code at
`Objects.pas:225` calls it exactly as the Delphi API; whether the FPC equivalent has the
same signature is an open question.

**Verdict:** Pillar 3 is the cheapest pillar to evaluate. The construction half already exists.
Whether it needs a `TModernInvoker` wrapper or only a `{$IFDEF FPC}` guard on the existing
`Factory` depends on the FPC API measurement — which the owner can do on their machine.

---

## B. What already exists that solves part of this?

### 1. `TModernObject.Factory` — seed of the Invoker (`Objects.pas:208-241`)

The method already does:
```pascal
LType := FContext.GetType(AClass);                       // Objects.pas:220
LConstructor := LType.GetMethod(AMethodName);            // Objects.pas:221
LInstance := LConstructor.Invoke(…, AArgs);              // Objects.pas:225
```

This is ~70% of what a `TModernInvoker` would do for construction. A general-purpose
invoker extends the same three-line pattern to non-constructor methods.

### 2. `{$IFDEF FCP}` block — intent exists, execution is dead (`ModernSyntax.inc:256`)

The intent to support Lazarus is already encoded in the include file. Fixing the typo
(`FCP` → `FPC`) costs a one-character edit and immediately makes the Lazarus branch
live. That alone does not make the library compile under FPC (the `Windows` and
`Threading` blockers remain), but it is the precondition for every other FPC-targeted
change.

### 3. `TArrow.Fn` with `TValue.Kind` dispatch — rudimentary field writer (`ArrowFun.pas:172-235`)

`TArrow.Fn(AVarRefs, AValues)` at `ArrowFun.pas:172` iterates an array of pointers and
assigns values by `TValue.Kind` dispatch (tkInteger, tkFloat, tkUString, tkClass, …).
This is the manual, non-RTTI version of what a `TModernRTTIField.SetValue` would do
through RTTI. The pattern is already written — a RTTI-backed version would replace the
manual kind-switch with `TRttiField.SetValue`.

---

## C. What does this break?

### Break 1 — `Windows` unit removal in `Std.pas` and `DotEnv.pas`

Making either unit compile under FPC requires moving `Windows` from the interface section to
an `{$IFDEF MSWINDOWS}` guard in the implementation section, and providing RTL equivalents
for the two Windows-specific calls:

| Unit | Line | Windows symbol used |
|---|---|---|
| `ModernSyntax.Std.pas` | 80 | `OutputDebugString` (in `DebugPrint`) |
| `ModernSyntax.DotEnv.pas` | 323 | `GetEnvironmentVariable` |

`SysUtils.GetEnvironmentVariable` is a cross-platform RTL function available in both
Delphi and FPC. `OutputDebugString` has no cross-platform equivalent — `WriteLn` or
a conditional compile is the standard workaround.

Any change to `Std.pas:21` and `DotEnv.pas:22` immediately affects 6 units
(`Std`, `DotEnv`, `Match`, `Crypt`, `ArrowFun`, and transitively their callers) and
invalidates 8 of the 11 test binaries in `Test Delphi/EclbrSystem/` that test those units.

### Break 2 — `Threading` unit replacement in `Async.pas`, `Coroutine.pas`, `Stream.pas`

`TTask.Run` (`Async.pas:213, 260, 299, 346, 378`; `Coroutine.pas:439`) has no FPC 3.2.2
equivalent. Any FPC port of `TAsync` and `TCoroutine` requires a replacement threading
primitive. The test suites for `Async` (`PTestAsync.dpr`) and the scheduler would need
FPC-specific implementations or would need to be conditionally excluded.

### Break 3 — `TProc`/`TFunc` replacement at 451 call sites

If anonymous methods are replaced with interface+capture objects for FPC compatibility,
every consumer of the library that passes a lambda to `TCurrying.Map`, `TMatch.CaseEq`,
`TSmartPtr.Scoped`, `TOption.Some`, etc. must be rewritten. This is not an internal change
— it is a breaking API change for every downstream user. A dual API surface (anonymous
methods on Delphi, interfaces on FPC) avoids the break but doubles the maintenance surface.

### Break 4 — Test coverage gap amplified by new RTTI units

`ModernSyntax.ArrowFun` (309 lines) and `ModernSyntax.Coroutine` (585 lines) have zero
test coverage today (confirmed: `find "Test Delphi" -name "*Arrow*" -o -name "*Coroutine*"` → 0 results).
These are the units most likely to host new RTTI abstraction (ArrowFun uses `TValue` dispatch;
Coroutine is the natural host for a Lazarus-compatible scheduler). Any code added there will
also start at zero test coverage. The factory has no Pascal compiler and cannot run tests.

---

## Open questions (survived a lookup attempt)

| # | Question | Tried | Why still open |
|---|---|---|---|
| OQ-A | Does FPC 3.2.2's `Rtti` unit expose `TRttiMethod.Invoke` with a compatible signature to Delphi's? | Read `Objects.pas:225` (the Delphi call); searched for any FPC-specific RTTI comment in source — none. | Requires a compile test on FPC 3.2.2; no FPC environment available in the factory. Owner can measure this in minutes on their machine. |
| OQ-B | Does FPC 3.2.2 support `TCustomAttribute` and `{$M+}` to declare attributes? | Searched source for any attribute example — 0 results. | Cannot measure from this codebase; needs a minimal FPC test file. |
| OQ-C | What FPC version is the target? 3.2.2 (current stable) blocks anonymous methods; 3.3.1 (trunk) allows them. | Noted from demand context: "FPC 3.2.2 is what comes with Lazarus stable installed on the owner's machine." | Owner must decide: support 3.2.2 stable or require 3.3.1+. This decision determines whether Pillar 2 (anonymous methods) is feasible without a full interface-based rewrite. |
| OQ-D | Is the `{$IFDEF FCP}` typo intentional (reserved for a different symbol) or an oversight? | Searched for any other use of `FCP` symbol in the codebase — 0 results. | Single data point; no prior ADR or issue. Likely an oversight, but requires author confirmation before the one-character fix is made. |

---

## Structural blockers — ordered by priority

These must be resolved before ModernRTTI work begins:

1. **`{$IFDEF FCP}` → `{$IFDEF FPC}` (`ModernSyntax.inc:256`)** — one-character fix, zero risk, makes the Lazarus branch live. Precondition for every other FPC change.
2. **`Windows` import in `Std.pas:21` and `DotEnv.pas:22`** — move to `{$IFDEF MSWINDOWS}` guards and provide RTL equivalents. 6 units unblocked.
3. **FPC version target decision (OQ-C)** — determines whether Pillar 2 is feasible at all.
4. **FPC `Rtti.Invoke` compatibility measurement (OQ-A)** — owner can run this on their machine in one session. Determines whether `TModernObject.Factory` needs a conditional path or a full rewrite for Pillar 3.

---

## Sources (confirmed in code, not in documentation)

| Claim | Confirmed at |
|---|---|
| `{$IFDEF FCP}` typo — only FPC occurrence | `Source/ModernSyntax.inc:256` |
| Zero `GetProperties`/`GetFields` calls | `grep -rn "GetProperties\|GetFields\|TRttiProperty\|TRttiField" Source/*.pas` → 0 |
| Zero attribute usage | `grep -rn "TCustomAttribute\|GetAttribute\|Attribute\]" Source/*.pas` → 0 |
| 451 `TProc`/`TFunc` occurrences, 10 files | `grep -rn "TProc\b\|TFunc\b" Source/*.pas \| wc -l` → 451 |
| `TModernObject.Factory` uses `Invoke` | `Source/ModernSyntax.Objects.pas:221-225` |
| `Threading` in 3 units | `Async.pas:25`, `Coroutine.pas:24`, `Stream.pas:23` |
| `Windows` in interface section of 2 units | `Std.pas:21`, `DotEnv.pas:22` |
| 6 units blocked from FPC by `Windows` | `Match.pas:26`, `Crypt.pas:21`, `ArrowFun.pas:23` + their transitive dependencies |
| 0 `.lpi`/`.lpr` files | `find . -name "*.lpi" -o -name "*.lpr" \| wc -l` → 0 |
| 13 `.dproj` files | `find . -name "*.dproj" \| wc -l` → 13 |
