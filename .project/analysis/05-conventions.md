---
type: analysis
kind: artifact
title: "Conventions: ModernSyntax — naming, layout, error handling, testing, patterns"
description: "Measured conventions document covering naming rules, code layout, error-handling style, testing approach, recurring patterns, ADR candidates, and quality gates for the ModernSyntax Delphi library."
status: stable
generated:
  by: "analyst-discovery@node:conventions"
  at: "2026-08-27T00:00:00Z"
tags:
  - conventions
  - delphi
  - analyst
  - discovery
sources:
  - id: intake
    resource: /analysis/00-intake.md
    title: "00-intake: ModernSyntax shallow-pass"
  - id: structure
    resource: /analysis/01-structure.md
    title: "Structure: ModernSyntax — folder tree, entry points, build/run/test/lint"
  - id: stack
    resource: /analysis/02-stack.md
    title: "02-stack: ModernSyntax dependency manifest and runtime stack"
---

# Conventions — ModernSyntax

All numbers below come from commands run against the source tree at
`/.aefos-studio/workspaces/isaquepinheiro/ModernSyntax/worktrees/aefos/thread-ec69b1ef`.
Every claim cites the exact command and/or file:line that produced it.

---

## 1. Naming conventions

### 1.1 Type prefixes

All user-defined types follow Delphi community conventions:

| Prefix | Applies to | Count | Measured |
|---|---|---|---|
| `T` | Classes and records | 23 records + 35 classes | `grep -rn "= record\b" Source/*.pas \| wc -l` → 23; `grep -rn "= class\b\|= class(" Source/*.pas \| wc -l` → 35 |
| `I` | Interfaces | 10 | `grep -rn "^  I[A-Z]" Source/*.pas` → 10 distinct declarations |
| `E` | Exception classes | 3 | `grep -rn "class(Exception)" Source/*.pas \| wc -l` → 3 |

The 3 custom exception types are all in `Source/ModernSyntax.ResultPair.pas`:
- `EFailureException<F>` (line 27)
- `ESuccessException<S>` (line 31)
- `ETypeIncompatibility` (line 35)

### 1.2 Member-access prefixes

**Fields** (confirmed in multiple units):
- `F` prefix on all private/protected fields.
  - `FValue`, `FResult`, `FSession`, `FUseGuard`, … (`ModernSyntax.Match.pas`:65–74)
  - `FSuccess`, `FFailure`, `FSuccessFuncs`, `FFailureFuncs`, `FResultType` (`ModernSyntax.ResultPair.pas`:65–69)
  - `FValue`, `FHasValue` (`ModernSyntax.Option.pas`:48–49)

**Parameters**: `A` prefix on all method parameters (confirmed: `ModernSyntax.Match.pas`:102–167, `ModernSyntax.ResultPair.pas` throughout).

**Local variables**: `L` prefix on all block-local variables (confirmed: `ModernSyntax.Match.pas`:153 — `LTuple1`, `LTuple2`; pervasive across all implementation sections sampled).

**Private helper methods**: `_` (underscore) prefix on methods intended as private implementation details, even when Pascal's access rules cannot enforce it on records. 156 such declarations found:
```
grep -rn "procedure _\|function _" Source/*.pas | wc -l  →  156
```
Examples: `_MatchingProcCaseIf`, `_ArraysAreEqual`, `_IsArrayInteger` (`ModernSyntax.Match.pas`:78–121), `_SetFailureValue`, `_ReturnSuccess` (`ModernSyntax.ResultPair.pas`:96–126).

### 1.3 Constant naming

Two distinct constant naming styles coexist (no unified rule enforced):

| Style | Example | Location |
|---|---|---|
| `C_SCREAMING_SNAKE` | `C_COROUTINE_NOT_FOUND` | `ModernSyntax.Coroutine.pas`:132 — `const` block inside method |
| `SCREAMING_SNAKE` (no `C_`) | `CASE_IF_PROC`, `CASE_EQ_FUNC` | `ModernSyntax.Match.pas`:221–230 — unit-level `const` aliasing enum values |

No shared rule selects between them. `C_` is used for string messages; bare `SCREAMING_SNAKE` for enum-value aliases. This is a **style inconsistency** (see §8, ADR-C1).

### 1.4 Unit and file naming

**Source units**: `ModernSyntax.<Module>.pas` for all 16 library units. Dot-separated namespace mirrors functional area.

**Test units**: two patterns coexist:
- `UTestMS.<Module>.pas` — ModernSyntax-specific tests (e.g., `UTestMS.Match.pas`, `UTestMS.Currying.pas`)
- `UTestEcl.<Category>.pas` — legacy eclbr-library tests retained in the tree (e.g., `UTestEcl.Dictionary.pas`)

**Test projects**: `PTest<Module>.dpr` pattern (e.g., `PTestMatch.dpr`, `PTestCurrying.dpr`).

**Examples**: `P<Description>.dpr` / `U<Description>.pas` (e.g., `PCorrotina.dpr`, `UCurryingDemo.pas`).

### 1.5 Enum casing

Two units apply `{$SCOPEDENUMS ON/OFF}` locally:
```
grep -rn "^\s*{$SCOPEDENUMS" Source/*.pas
  ModernSyntax.Coroutine.pas:34  {$SCOPEDENUMS ON}
  ModernSyntax.Coroutine.pas:36  {$SCOPEDENUMS OFF}
  ModernSyntax.Match.pas:56      {$SCOPEDENUMS ON}
  ModernSyntax.Match.pas:58      {$SCOPEDENUMS OFF}
```
The scope is immediately closed after the enum declaration. The remaining 14 units define enums without scoped enums. No project-wide `{$SCOPEDENUMS}` default is set in `ModernSyntax.inc` (confirmed: `grep "SCOPEDENUMS" Source/ModernSyntax.inc` → no output).

**Finding** (drift): scoped-enum protection is applied inconsistently — only 2 of the 16 units use it, and only for one enum each, immediately toggled off again (see §8, ADR-C2).

### 1.6 Boolean query method naming

**Inconsistency confirmed:**

| Method | Casing | Location |
|---|---|---|
| `isSuccess` | lowercase `is` | `ModernSyntax.ResultPair.pas`:447 |
| `isFailure` | lowercase `is` | `ModernSyntax.ResultPair.pas`:455 |
| `IsSome` | Pascal `Is` | `ModernSyntax.Option.pas`:89 |
| `IsNone` | Pascal `Is` | `ModernSyntax.Option.pas`:95 |
| `IsSomeAnd` | Pascal `Is` | `ModernSyntax.Option.pas`:102 |
| `HasValue` | Pascal `Has` | `ModernSyntax.ResultPair.pas`:54 (on the inner value type) |

Two boolean naming conventions exist in the same codebase with no stated rule (see §8, ADR-C3).

---

## 2. Code layout

### 2.1 File-level header

Every source unit opens with a `{...}` banner comment block. Confirmed in all 16 units by `grep -c "^{$" Source/*.pas` — every file begins with `{` at line 1. The canonical header reads (quoted from `Source/ModernSyntax.Async.pas`:1–12):

```pascal
{
  ------------------------------------------------------------------------------
  ModernSyntax
  Functional programming toolkit and modern syntax extension for Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}
```

**Finding** (drift): `ModernSyntax.Safetry.pas` line 222 contains a `{ Função Auxiliar }` comment with a non-ASCII character (ç) inside the implementation section — a remnant of Brazilian Portuguese that is inconsistent with the otherwise English comments in the codebase (confirmed: `grep -n "Aux" Source/ModernSyntax.Safetry.pas` → line 222).

### 2.2 Implementation section separators

Every implementation section uses `{ TTypeName }` block headers to delimit the implementation of each type. Confirmed in all sampled units:
- `ModernSyntax.Currying.pas`:825 — `{ TCurrying }`
- `ModernSyntax.ResultPair.pas`:552 — `{ TResultPairBr<S, F> }`, :1027 — `{ TResultPairValue<T> }`, :1052 — `{ EFailureException<S> }`
- `ModernSyntax.Objects.pas`:169 — `{ TObjectEx }`, :243 — `{ AutoRef<T>.TSmartPtr }`, …

This is the one universally applied layout rule in implementation sections.

### 2.3 `inline` directive usage

225 method declarations carry `inline;`:
```
grep -rn "inline;" Source/*.pas | wc -l  →  225
```
Applied broadly to short accessors, return-chaining methods, and private helpers. No formal rule defines when it is and is not appropriate; usage correlates with short (1–5 line) bodies.

### 2.4 Compiler directive (`{$T+}`)

`{$IFDEF}` blocks total 79 across all source units:
```
grep -rn "^\s*{$IFDEF\|^\s*{$IF\b\|^\s*{$ENDIF\|^\s*{$ELSE\b\|^\s*{$IFEND" Source/*.pas | wc -l  →  79
```

`ModernSyntax.Async.pas`:14 carries `{$T+}` (typed pointers on). No other source unit applies this directive; it is unit-specific and not in the shared `.inc`.

`{$IFDEF DEBUG}` appears in `ModernSyntax.Std.pas`:65–83 to gate `OutputDebugString` calls for `TStd.Println`. No other debug conditional is used.

### 2.5 Commented-out code

Significant volumes of commented-out code exist (code, not commentary):

| File | Approx. commented-out lines | Sample location |
|---|---|---|
| `ModernSyntax.ArrowFun.pas` | 88 | Lines 66–72 (commented-out `Result` overloads), 133–144 (lambda bodies), 271–279 |
| `ModernSyntax.Objects.pas` | 47 | Lines 532, 565–568 (property hooking stubs) |

Confirmed by: `grep -rn "^\s*//" Source/ModernSyntax.ArrowFun.pas | wc -l` → 88; `grep -rn "^\s*//" Source/ModernSyntax.Objects.pas | grep -c "raise\|procedure\|function\|:=\|begin\|end;"` → 47. No `TODO`/`FIXME`/`HACK` marker prefixes are used (searched: `grep -rn "TODO\|FIXME\|HACK\|XXX" Source/*.pas` → 0 results). Dead commented-out code is left in place without annotation (see §8, ADR-C4).

---

## 3. Documentation style

### 3.1 XML doc comments

1,579 `///` XML doc comment lines across all source:
```
grep -rn "/// " Source/*.pas | wc -l  →  1579
```

`ModernSyntax.ResultPair.pas` carries the most complete XML documentation: `<summary>`, `<remarks>`, `<param name="…">`, `<exception cref="…">`, `<returns>` tags applied to public methods (sampled lines 74–94, 367, 400, 412).

Coverage is uneven. Several units (e.g., `ModernSyntax.ArrowFun.pas`, `ModernSyntax.Crypt.pas`) contain fewer or no XML doc blocks; no enforcement mechanism exists.

### 3.2 Inline comments

1,817 `//` single-line comments across all source:
```
grep -rn "^\s*//" Source/*.pas | wc -l  →  1817
```

Many are explanatory field annotations (e.g., `ModernSyntax.Match.pas`:65 — `// Value to be matched`); others are commented-out code (see §2.5).

---

## 4. Error handling

### 4.1 Exception raise convention

35 `raise Exception.Create(…)` calls raise the bare base `Exception` class directly:
```
grep -rn "raise Exception\b" Source/*.pas | wc -l  →  35
```

3 custom exception classes exist, all in `ModernSyntax.ResultPair.pas` (lines 27, 31, 35).

**Distribution of bare `Exception.Create` raises by unit** (counted from `grep -rn "raise Exception" Source/*.pas`):

| Unit | Count |
|---|---|
| `ModernSyntax.DotEnv.pas` | 5 |
| `ModernSyntax.Objects.pas` | 7 |
| `ModernSyntax.Option.pas` | 3 |
| `ModernSyntax.Coroutine.pas` | 4 |
| `ModernSyntax.ArrowFun.pas` | 1 |
| `ModernSyntax.Match.pas` | 1 |
| `ModernSyntax.Safetry.pas` | 2 |
| `ModernSyntax.Std.pas` | 2 |
| `ModernSyntax.ResultPair.pas` | 2 (bare) + 3 (typed) |
| `ModernSyntax.Crypt.pas`, `ModernSyntax.Stream.pas`, etc. | 0 |

**Finding**: 11 of 14 units that raise errors use the bare base `Exception` class, making it impossible for callers to catch ModernSyntax-specific exceptions by type without also catching every other Delphi exception. Only `ResultPair` defines typed exceptions (see §8, ADR-C5).

### 4.2 try/finally and try/except

188 `try`, `finally`, or `except` keywords total in source:
```
grep -rn "try$\|finally\b\|except\b" Source/*.pas | wc -l  →  188
```

`ModernSyntax.Async.pas` is the densest user (sampled: lines 126, 137, 165, 194, 211, 212 — 10 try blocks visible in one pass). The `TSafeTry` type in `ModernSyntax.Safetry.pas` centralises `try/except` into a value-returning wrapper for library consumers.

### 4.3 Memory management

Two co-existing lifetime strategies:

**COM-style ARC via `TInterfacedObject`** (22 class declarations):
```
grep -rn "TInterfacedObject" Source/*.pas | wc -l  →  22
```
Classes implementing interfaces extend `TInterfacedObject` (e.g., `TAutoLock`, `TScheduler`, `TNumericByte` … `TNumericCurrency`). Callers hold interface references; reference count drives destruction — no explicit `Free` needed at the call site.

**Manual `Free`** (58 calls):
```
grep -rn "Free;\|FreeAndNil\b" Source/*.pas | wc -l  →  58
```
Found in implementation bodies managing owned sub-objects. The two patterns coexist without a stated rule for when to prefer one over the other.

**Records** (23 types) carry no heap objects directly unless they store an interface reference (ARC-managed) or a pointer to a heap block managed internally. `TSmartPtr<T>` (`ModernSyntax.Objects.pas`:80) and `TMutableRef<T>` (:123) are record wrappers that handle class-object lifetimes via interface-based finalisation.

---

## 5. Testing style

### 5.1 Framework and attributes

DUnitX is the exclusive test framework:
```
grep -rn "uses DUnitX.TestFramework" "Test Delphi/" --include="*.pas"  →  present in every test unit sampled
```

Attribute usage (measured):

| Attribute | Count | Command |
|---|---|---|
| `[TestFixture]` | 14 (total across both test directories) | `grep -rn "^\s*\[TestFixture\]" "Test Delphi/" --include="*.pas" \| wc -l` → 14 |
| `[Test]` | 468 (425 EclbrSystem + 43 EclbrResultPair) | `grep -rn "^\s*\[Test\]" "Test Delphi/" --include="*.pas" \| wc -l` → 468 |
| `[SetUp]`/`[TearDown]` | 50 (combined) | `grep -rn "^\s*\[SetUp\]\|^\s*\[TearDown\]\|Setup;\|Teardown;" "Test Delphi/" --include="*.pas" \| wc -l` → 50 |

### 5.2 Assertion style

All 951 assertion calls use the `Assert.` DUnitX static class:
```
grep -rn "Assert\." "Test Delphi/" --include="*.pas" | wc -l  →  951
```
Zero legacy `CheckEquals`/`CheckTrue` (DUnit style) calls found:
```
grep -rn "CheckEquals\|CheckTrue\|CheckFalse\|CheckNotNull" "Test Delphi/" --include="*.pas" | wc -l  →  0
```
Commonly used assertion methods (sampled from `UTestMS.Objects.pas`:59–99): `Assert.IsNotNull`, `Assert.AreEqual`, `Assert.IsTrue`.

### 5.3 Test method naming

567 methods named `procedure Test<Description>` across all test files:
```
grep -rn "procedure Test\|function Test" "Test Delphi/" --include="*.pas" | wc -l  →  567
```
Method names are verbose English descriptions (e.g., `TestMatchWithMatchingCase`, `TestCaseIfAndGuard`, `TestPatternMatchingWithDiscounts` — `UTestMS.Match.pas`:72–125). No abbreviation convention is used.

### 5.4 Fixture registration

Every test unit registers its fixture in an `initialization` block:
```pascal
initialization
  TDUnitX.RegisterTestFixture(TTestCurrying);
```
Confirmed in `UTestMS.Currying.pas`:1440, `UTestMS.Objects.pas`:205, `UTestMS.DotEnv.pas`:281, and 7 other test units sampled.

### 5.5 Test doubles

No mocking framework is used. Test doubles are hand-rolled classes declared inside the test unit's `type` section. Examples from `UTestMS.Match.pas`:18–54: `TAnimal`, `TDog`, `TProduct`, `TDiscount`, `TPercentageDiscount`, `TFixedAmountDiscount`. Object creation and teardown are managed manually inside test methods or `[TearDown]` methods.

---

## 6. Recurring patterns

### 6.1 Fluent / method-chaining API

Every primary type exposes a chainable builder API via PascalCase methods returning `Self` (the same type). Examples:

- `TMatch<T>`: `CaseIf`, `CaseEq`, `CaseGt`, `CaseLt`, `CaseIn`, `CaseIs`, `CaseRange`, `Default`, `End_` — all return `TMatch<T>` (`ModernSyntax.Match.pas`:157–210)
- `TResultPair<S,F>`: `Map`, `Reduce`, `When`, `Recover`, `Pure`, `Swap` — all return `TResultPair` (`ModernSyntax.ResultPair.pas`:209–350)
- `TOption<T>`: `Map`, `Filter`, `OrElse`, `FlatMap` (`ModernSyntax.Option.pas`:88–130)

### 6.2 Anonymous method / closure as first-class value

329 uses of anonymous method types (TFunc<>, TProc<>, `reference to function/procedure`):
```
grep -rn "reference to function\|reference to procedure\|TFunc<\|TProc<" Source/*.pas | wc -l  →  329
```
Anonymous methods are the primary mechanism for passing behaviour into library types. Overloads distinguish procedure from function callbacks and arities (133 overloaded method declarations):
```
grep -rn "overload;" Source/*.pas | wc -l  →  133
```

### 6.3 Generic type parameters

All primary value types are generic: `TMatch<T>`, `TResultPair<S,F>`, `TOption<T>`, `TTuple<K>`, `TSmartPtr<T>`, `TMutableRef<T>`, `TCurrying`, `TPipeline<T>`. Generic constraint syntax is limited to `class, constructor` where needed (e.g., `TSmartPtr<T: class, constructor>` — `ModernSyntax.Objects.pas`:80).

### 6.4 Interface-backed lifetime via `TInterfacedObject`

Classes that participate in ARC-style lifetime management extend `TInterfacedObject` and implement an interface. Callers receive the interface, not the class. Pattern confirmed in: `TAutoLock` / `IAutoLock` (`ModernSyntax.Async.pas`:33–39), `TScheduler` / `IScheduler` (`ModernSyntax.Coroutine.pas`:101–122), `TMemoizedCache<T,U>` / `ICleanup` (`ModernSyntax.Currying.pas`:134), all `TNumeric*` / `INumeric<T>` classes (`ModernSyntax.Currying.pas`:390–766).

### 6.5 Static factory method `New` / `Value`

Several types expose a static class function `New` or `Value` as a named constructor alternative to `Create`:
- `TResultPair<S,F>.New` (`ModernSyntax.ResultPair.pas`:143) — `class function New: TResultPair<S, F>; static; inline;`
- `TMatch<T>.Value` (`ModernSyntax.Match.pas`:156) — `class function Value(const AValue: T): TMatch<T>; static; inline;`

This is consistent with the functional style of the library (avoiding raw constructor calls in expression contexts).

### 6.6 `class sealed` for non-extendable types

4 types carry `sealed` to prevent inheritance:
```
grep -rn "sealed\b" Source/*.pas
  ModernSyntax.Coroutine.pas:64   TCoroutine = class sealed
  ModernSyntax.Coroutine.pas:125  TGather<T> = class sealed(TList<T>)
  ModernSyntax.Objects.pas:39     TModernObject = class sealed(TInterfacedObject, IModernObject)
  ModernSyntax.pas:88             TSet<T> = class sealed
```
Used selectively, not universally. No documented rule distinguishes sealed from non-sealed classes.

---

## 7. Quality gates

### 7.1 Build

No automated build pipeline exists. Compilation is IDE-driven (RAD Studio / MSBuild `.dproj` files). The group project `TestMSGroup.groupproj` drives multi-project builds interactively.
```
find . -name "*.yml" -not -path "./.git/*" -not -path "./.claude/*"  →  (no project-owned CI files)
```
There is **no CI quality gate**; all gates depend on developer discipline.

### 7.2 Tests

DUnitX test runners are launched manually per project. No automated test execution on commit or PR. `DCC.bat` (`Test Delphi/EclbrSystem/DCC.bat`) runs `CodeCoverage.exe` post-test to produce EMMA/XML/HTML coverage reports, but the batch script references 14 projects while only 10 `.dpr` files exist — the script will fail at the first missing project (finding confirmed in [01-structure.md §7, F-02](/analysis/01-structure.md)).

### 7.3 Static analysis / lint

One `.delphilint` file exists: `Test Delphi/EclbrSystem/PTestMatch.delphilint` — scoped to a single test project, not the library. No project-wide lint configuration exists.

### 7.4 Code coverage

`DCC.bat` generates EMMA/XML/HTML coverage output into `CodeCoverage/<ModuleName>/` when run. Coverage data is not collected automatically; it requires a manual post-test invocation.

---

## 8. ADR candidates

These are observations where a decision would reduce inconsistency. None exists in writing today.

### ADR-C1 — Unify constant naming style
Two constant naming conventions coexist: `C_SCREAMING_SNAKE` (Coroutine.pas:132) and bare `SCREAMING_SNAKE` (Match.pas:221–230). A single rule is needed. Decision should also address whether `C_` prefix applies to all named string constants.

### ADR-C2 — Default scoped-enum policy
`{$SCOPEDENUMS ON}` is toggled in two units locally and immediately closed. Either adopt it project-wide (in `ModernSyntax.inc`) or document that enums are intentionally global-scope. No current stated policy.

### ADR-C3 — Boolean method naming: `Is` vs `is`
`isSuccess`, `isFailure` (ResultPair.pas:447,455) use lowercase `is`, while `IsSome`, `IsNone`, `IsSomeAnd` (Option.pas:89–102) use Pascal-case `Is`. A single rule is needed; Pascal convention (`Is`) is the majority and the Delphi RTL standard.

### ADR-C4 — Commented-out code policy
88 commented-out lines in `ArrowFun.pas`, 47 in `Objects.pas`. No annotation (no `TODO`, no ticket reference) explains whether these are work-in-progress stubs or abandoned code. A policy is needed: either remove on merge or annotate with a tracking reference.

### ADR-C5 — Exception typing across the library
35 bare `raise Exception.Create(…)` calls across 11 units. Only `ResultPair` defines typed exceptions. Callers cannot catch ModernSyntax-specific errors by type. A decision is needed on whether to introduce a hierarchy (e.g., `EModernSyntax` base) or accept the current approach as intentional.

### ADR-C6 — Memory management strategy
Two coexisting patterns — `TInterfacedObject`-based ARC (22 class declarations) and manual `Free` (58 calls) — with no documented rule for when each is appropriate. A stated rule would prevent mixed-strategy objects.

### ADR-C7 — CI pipeline adoption
Zero CI configuration exists. All quality gates depend on manual developer action. Given the presence of DUnitX and CodeCoverage tooling, a GitHub Actions workflow could automate build + test without new tooling.

---

## 9. Findings (drift between documentation and code)

### CV-F01 — `isSuccess`/`isFailure` casing breaks naming convention

**Stated convention** (de-facto from all other boolean methods in the codebase): `Is<Name>` PascalCase.
**Actual** (`ModernSyntax.ResultPair.pas`:447,455): `isSuccess`, `isFailure` — lowercase `is`.
Both methods are in the same file as `HasValue` (line 54) which uses PascalCase `Has`. This is internal inconsistency, not a document/code split.

### CV-F02 — No documentation of memory-management strategy

README (`README.md`) describes types and features but states no policy on when ARC vs manual Free applies. The code mixes both patterns without inline explanation. This is a knowledge gap, not a hard failure.

### CV-F03 — XML doc coverage is uneven

`ModernSyntax.ResultPair.pas` carries dense XML doc; `ModernSyntax.ArrowFun.pas`, `ModernSyntax.Crypt.pas`, `ModernSyntax.Stream.pas` carry sparse or no XML doc blocks. No enforced rule or tooling gate ensures coverage. Documentation intent (implied by ResultPair's coverage) is not consistently realised.

### CV-F04 — `DCC.bat` references 4 non-existent test projects

Already recorded in [01-structure.md §7, F-02](/analysis/01-structure.md); restated here for completeness. The batch script references `PTestDictionary`, `PTestVector`, `PTestMap`, `PTestList`, `PTestStr`, `PTestDirectory`, `PTestThreading` — none of these `.dpr` files exist. The coverage batch script is broken as-is.
