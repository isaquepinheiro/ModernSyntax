---
type: analysis
title: "05 Conventions: ModernSyntax"
description: Naming, layout, error handling, testing style, recurring patterns, ADR candidates, and quality gates — all measured from source.
status: stable
tags: [conventions, discovery, delphi, dunitx, functional-programming, naming, testing]
sources:
  - id: structure
    resource: /analysis/01-structure.md
    title: "01 Structure — ModernSyntax"
  - id: stack
    resource: /analysis/02-stack.md
    title: "02 Stack — ModernSyntax"
---

# ModernSyntax — Conventions

## 1. Naming and layout

### 1.1 Module naming

Every production source file under `Source/` follows the scheme `ModernSyntax.<Feature>.pas`
(all PascalCase words, dot-separated). The root umbrella unit drops the feature segment:
`ModernSyntax.pas`.

Measured: `ls Source/*.pas | wc -l` → **16** files, all matching the pattern above. One
supplementary file — `ModernSyntax.inc` — carries compiler-directive blocks and does not
participate in the naming scheme.

### 1.2 Test-file naming

Two parallel schemes appear in `Test Delphi/`:

| Kind | Pattern | Example |
|------|---------|---------|
| Test unit | `UTest<Feature>.pas` | `UTestMS.Option.pas` |
| Test project | `PTest<Feature>.dpr` | `PTestOption.dpr` |

Measured: `find "Test Delphi" -name "*.pas" | wc -l` → **20** test units;
`find "Test Delphi" -name "*.dpr" | wc -l` → **11** test runner projects.

The `UTest` prefix is used consistently across both sub-directories (`EclbrSystem/` and
`EclbrResultPair/`). Confirmed at `Test Delphi/EclbrSystem/UTestMS.Option.pas` line 1
and `Test Delphi/EclbrResultPair/UTestMS.ResultPair.pas` line 1.

### 1.3 Identifier prefixes (enforced by code, not by tooling)

| Prefix | Meaning | Evidence |
|--------|---------|---------|
| `T` | Type or record | `TResultPair`, `TOption<T>`, `TSafeTry` — `Source/ModernSyntax.ResultPair.pas` line 23 |
| `I` | Interface | `IMSObserver` — `Source/ModernSyntax.pas` line 12 |
| `E` | Exception class | `EFailureException<F>`, `ETypeIncompatibility` — `Source/ModernSyntax.ResultPair.pas` lines 26–36 |
| `F` | Record/object field | `FHasValue`, `FValue`, `FException` — `Source/ModernSyntax.SafeTry.pas` lines 22–24 |
| `L` | Local variable | `LItem`, `LCoroutine`, `LResultValue` — `Source/ModernSyntax.Coroutine.pas` lines 211, 239, 360 |
| `A` | Parameter | `AValue`, `ASuccess`, `AFailure` — `Source/ModernSyntax.ResultPair.pas` lines 70+ |
| `_` | Private implementation method | `_DestroySuccess`, `_DestroyFailure`, `_EndExecute` — `Source/ModernSyntax.ResultPair.pas` lines 76–77; `Source/ModernSyntax.SafeTry.pas` line 42 |

Measured: `grep -rn 'procedure _\|function _' Source/ | wc -l` → **101** underscore-prefixed
private method declarations across all 16 .pas files. This is a project-wide pattern.

### 1.4 Access control

`strict private` is used across records to lock down implementation details from subclasses
and units. Measured: `grep -rn 'strict private' Source/ | wc -l` → **21** `strict private`
sections. `TResultPair<S,F>` at `Source/ModernSyntax.ResultPair.pas` line 62 uses two
consecutive `strict private` blocks: one for nested type aliases, one for data fields.

### 1.5 File header

All 16 `.pas` files carry a standardised block-comment header followed by an SPDX tag:

```
{
  ------------------------------------------------------------------------------
  ModernSyntax
  Functional programming toolkit and modern syntax extension for Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro
  ...
  ------------------------------------------------------------------------------
}
```

Measured: `grep -rn 'SPDX-License-Identifier' Source/ | wc -l` → **16** (one per .pas file).

**FINDING — drift:** `Source/ModernSyntax.inc` retains an older header that declares the GNU
Lesser General Public License (LGPL v3), not MIT. Confirmed at `Source/ModernSyntax.inc`
lines 1–16. The `.inc` file was not updated when the licence changed (git log entry
`"docs: standardize and update headers in all .pas files to MIT"` names `.pas` files
explicitly; `.inc` is not mentioned).

---

## 2. Error handling

Three independent error-handling idioms coexist; no single one is mandated project-wide.

### 2.1 Railway-oriented (result type)

`TResultPair<S, F>` — a tagged union of success value (`S`) and failure value (`F`) —
is the primary domain-error idiom. The sole factory is the `class function New: TResultPair<S,F>`
(`ResultPair.pas:143`, static). `.Success(ASuccess)` and `.Failure(AFailure)` are **instance
methods** that mutate Self and return Self (`ResultPair.pas:674, 617` — no `class`, no `static`).
The correct construction idiom is `.New.Success(x)` (confirmed: `Test Delphi/EclbrResultPair/UTestMS.ResultPair.pas:105`).
Consumers chain `.ThenOf(...)` / `.ExceptOf(...)` instead of raw `try/except`.

Confirmed: `Source/ModernSyntax.ResultPair.pas` lines 23–80. The discriminant is
`TResultType = (rtNone, rtSuccess, rtFailure)` at line 23.

Two thin exception wrappers exist for interop with Delphi's exception model:
`EFailureException<F>` (line 26) and `ESuccessException<S>` (line 31). They are raised
when a caller tries to unwrap the wrong rail.

### 2.2 Option type (null-safety)

`TOption<T>` wraps nullable values as `Some(value)` or `None`. It imports `ModernSyntax.ResultPair`
(confirmed at `Source/ModernSyntax.Option.pas` line 7) and exposes the same chaining style
(`AndThen`, `OrElse`, `Unwrap`, `Match`). Confirmed at `Source/ModernSyntax.Option.pas` lines 31–70.

### 2.3 Fluent try/catch wrapper

`TSafeTry` at `Source/ModernSyntax.SafeTry.pas` lines 44–58 offers a builder-style API:

```pascal
TSafeTry.&Try(func).&Except(handler).&Finally(cleanup).&End
```

`&End` returns `TSafeResult` (lines 31–42) with `IsOk` / `IsErr` / `GetValue` /
`ExceptionMessage` so callers can interrogate the outcome without re-raising.

**FINDING — silent suppression:** The `_EndExecute` implementation at
`Source/ModernSyntax.SafeTry.pas` lines 128–141 catches any exception thrown by the
`&Finally` handler and discards it without notifying the caller (comment in code:
`// Ignora exceções em Finally silenciosamente`). Secondary failures are invisible to
callers and undocumented in the public API.

### 2.4 Future / async result

`TFuture` in `Source/ModernSyntax.pas` lines 18–38 is a lightweight promise-like record
with `IsOk`, `IsErr`, `Ok<T>`, `Err`. It carries the same shape as `TSafeResult` but is
independent of it — no shared base type or interface links them. The similarity is by
convention.

### 2.5 Memory ownership — `TResultPair.Dispose`

`TResultPair<S,F>` is the **owner** of the objects carried on either rail when `S` or `F`
is a class type. `Dispose` (`ResultPair.pas:622`) unconditionally calls both
`_DestroySuccess` (`ResultPair.pas:581`) and `_DestroyFailure` (`ResultPair.pas:666`).
Each destroyer checks `TypeInfo(S).Kind = tkClass` and calls `.Free` on the boxed object.
This means:

- A consumer who passes a class instance to `.Success(obj)` or `.Failure(obj)` transfers
  ownership. The object will be freed when `Dispose` is called.
- `Dispose` frees **both** rails regardless of which is set — a container in `rtSuccess`
  state still calls `_DestroyFailure`, which is safe because the destroyer short-circuits
  when the rail was never populated (`ResultPair.pas:676`: `if not FFailure.HasValue then Exit`).
- Not calling `Dispose` on a class-typed `TResultPair` leaks the carried object.
  There is no destructor or finalizer (it is a record).

Confirmed: `Source/ModernSyntax.ResultPair.pas:581, 622, 666`. Positions were updated
after PR #7 in the `ResultPair.pas` block, which shifted the anchors of
`_DestroySuccess` and `_DestroyFailure`.

---

## 3. Testing style

### 3.1 Framework

**DUnitX** — confirmed at `Test Delphi/EclbrSystem/PTestMatch.dpr` lines 17–19
(`DUnitX.TestFramework`, `DUnitX.Loggers.Console`, `DUnitX.Loggers.Xml.NUnit`).

Each runner also configures an NUnit-compatible XML logger (`TDUnitXXMLNUnitFileLogger`),
enabling external CI consumption even though no CI pipeline exists.

A `{$DEFINE CI}` directive at `PTestMatch.dpr` line 3 (currently commented out) would
suppress the end-of-run key-press pause. The CI define is dead code: no pipeline was found
(measured: `find . -name ".github" | wc -l` → 0).

### 3.2 Fixture and test annotations

DUnitX attribute-driven discovery: `[TestFixture]`, `[Setup]`, `[TearDown]`, `[Test]`.
Confirmed at `Test Delphi/EclbrSystem/UTestMS.Option.pas` lines 4–8.

Measured: `grep -r '\[Test\]' "Test Delphi/" | wc -l` → **431** individual test cases
across all 20 test units.

Selected per-file counts (measured: `grep -c '\[Test\]' <file>`):
- `UTestMS.Currying.pas` → 58
- `UTestMS.Option.pas` → 50
- `UTestMS.Match.pas` → 42

### 3.3 Test structure

Each fixture follows the pattern:

```pascal
[TestFixture]
TestT<Feature> = class
private
  F<Subject>: T<Subject>;   // field per SUT instance
public
  [Setup]    procedure SetUp;
  [TearDown] procedure TearDown;
  [Test]     procedure Test<Behaviour>;
end;
```

Confirmed at `Test Delphi/EclbrSystem/UTestMS.Option.pas` lines 4–14: `TestTOption`
holds `FOptInt: TOption<Integer>` and `FOptStr: TOption<string>`.

Assertion style: DUnitX `Assert.*` static methods.
Measured: `grep -rn 'Assert\.' "Test Delphi/" | wc -l` → **951** assertion call sites.

### 3.4 Coverage gaps

Each `.dpr` runner names its units explicitly (confirmed: `PTestMatch.dpr` lines 21–27
list 8 units). There is no single aggregate runner. Modules without a dedicated runner:

- `ModernSyntax.Coroutine.pas`
- `ModernSyntax.Crypt.pas`
- `ModernSyntax.ArrowFun.pas`
- `ModernSyntax.RegExpression.pas`

Confirmed absent: `find "Test Delphi" -name "*Coroutine*" -o -name "*Crypt*" -o -name "*Arrow*" -o -name "*RegExp*"` → no output.

---

## 4. Recurring patterns

### 4.1 Fluent / builder chains

Methods that return `Self` (or a value-copy of `Self` for records) to enable chaining.
Measured: `grep -rn 'Result := Self' Source/ | wc -l` → **30** sites. Predominant in
`TSafeTry` and container-like types.

### 4.2 Class operators for implicit conversion

`class operator Implicit(...)` provides ergonomic type coercion at assignment sites.
Confirmed at `Source/ModernSyntax.Objects.pas` lines 101–102 (`TSmartPtr<T>`),
`Source/ModernSyntax.Tuple.pas` lines 52–55 (`TTuple<K>`), and
`Source/ModernSyntax.Option.pas` lines 26–30 (`TSome`).
`Equal` / `NotEqual` operators appear alongside `Implicit` for value-type equality.

### 4.3 XML doc comments

Public API is extensively documented with `///` XML-doc triple-slash comments following
Delphi's `<summary>`, `<param name="...">`, `<returns>`, `<remarks>` schema.
Measured: `grep -rn '///' Source/ | wc -l` → **2 475** (measured 2026-09-02: `grep -rc '///' Source/*.pas`) lines carrying doc comments. Note: unit count in `Source/` grew from 16 to 22 since the initial measurement, which accounts for most of the delta.
Confirmed at `Source/ModernSyntax.ResultPair.pas` lines 81–90 and
`Source/ModernSyntax.Option.pas` lines 46–61.

### 4.4 Anonymous-function type aliases

Nested `type` aliases inside records name anonymous-function signatures for readability:

```pascal
TMapFunc<Return> = reference to function(const ASelf: TResultPair<S,F>): Return;
TFuncOk          = reference to function(const ASuccess: S): TResultPair<S,F>;
```

Confirmed at `Source/ModernSyntax.ResultPair.pas` lines 65–68.
Measured: `grep -rn 'reference to function\|reference to procedure' Source/ | wc -l`
→ **11** type-declaration sites.

### 4.5 Compiler-version ladder in `ModernSyntax.inc`

A single include file carries a version ladder from Delphi XE (VER220) through Delphi 12
(VER360). Each `{$IFDEF VER<N>}` block defines cumulative `DELPHI<N>_UP` symbols so
conditional code reads `{$IFDEF DELPHI27_UP}` rather than checking a raw version number.
The ladder starts at Delphi XE (`VER220` is the first non-Lazarus entry, `ModernSyntax.inc:244`);
VER210 (Delphi 2010) entries in the file are Lazarus-only blocks.
Confirmed: `Source/ModernSyntax.inc` lines 57–256.

VCL/FMX selection is controlled by `{.$DEFINE FMX}` (commented out = VCL default) at
`Source/ModernSyntax.inc` lines 49–54, which resolves to either `HAS_FMX` or `HAS_VCL`.
These symbols are defined only in the `.inc` file (`ModernSyntax.inc:50,52`);
`grep -rn "HAS_FMX\|HAS_VCL" Source/*.pas` → **0** results — no `.pas` file references
them directly (the symbols are only active inside `ModernSyntax.Objects` because that is
the sole unit that includes the `.inc` file).

---

## 5. Quality gates

### 5.1 Automated checks

**None found.** No CI pipeline, no linter config, no formatter config, no static-analysis
script.

Measured:
- `find . -name ".github" | wc -l` → 0
- No `.yml`/`.yaml` outside `.claude/` internal infrastructure
- No `Makefile`, `.editorconfig`, `.dof`-level custom compiler settings

### 5.2 Manual process

DUnitX is the only formal gate. Each feature has an independent runner project requiring
manual execution in the Delphi IDE or at a console. The NUnit XML output path is configured
(`TDUnitX.Options.XMLOutputFile`) but no consumer for it exists in the repository.

**How to run a single test suite (Windows, command line):**

```
cd "Test Delphi\EclbrSystem"
dcc32 PTestMatch.dpr -u"..\..\Source" -E. && PTestMatch.exe
```

Replace `PTestMatch` with any of the 10 `EclbrSystem` project names or
`PTestResultPair` (in `EclbrResultPair\`). `dcc32` must be on `PATH`
(e.g., add `C:\Program Files (x86)\Embarcadero\Studio\22.0\bin` for Delphi XE).
No aggregate runner script exists in the repository (measured:
`find "Test Delphi" -name "DCC.bat" | wc -l` → 1, covering only 13 of 21 targets
and requiring manual path edits).

### 5.3 Package registry metadata

`boss.json` and `pubdelphi.json` describe the library for the Boss and PubDelphi package
managers respectively. No external runtime dependencies are declared in either file
(`"dependencies": {}` confirmed at `boss.json` lines 7–8 and `pubdelphi.json`). Only
Delphi RTL units are used at runtime.

---

## 6. ADR candidates

The following decisions are visible in the code but no written ADR exists
(measured: `find . -path "*decisions*" -name "*.md" | grep -v ".project"` → 0):

| # | Decision visible in code | Where |
|---|--------------------------|-------|
| A | Three independent error idioms without a shared abstraction | `Source/ModernSyntax.ResultPair.pas`, `Option.pas`, `SafeTry.pas`, `ModernSyntax.pas` |
| B | Silent suppression of exceptions thrown inside `&Finally` handlers | `Source/ModernSyntax.SafeTry.pas` line 141 |
| C | `ModernSyntax.inc` LGPL header not updated to MIT when licence changed | `Source/ModernSyntax.inc` lines 1–16 |
| D | No aggregate test runner; 4 modules have zero test coverage | `Test Delphi/` (Coroutine, Crypt, ArrowFun, RegExpression) |
| E | FMX/VCL toggle is compile-time only, defaulting to VCL | `Source/ModernSyntax.inc` lines 49–54 |

---

## 7. Open questions

| # | Question | What was tried |
|---|----------|----------------|
| Q1 | Are the `.dpr` test projects ever run in batch? | Searched for `.sh`, `.bat`, `.ps1` at repo root and under `Test Delphi/` — none found |
| Q2 | Is `ModernSyntax.inc` deliberately excluded from the licence-header update, or was it missed? | Git log entry `"docs: standardize and update headers in all .pas files to MIT"` names `.pas` files; `.inc` not mentioned |
| Q3 | Does `TFuture` intentionally duplicate `TSafeResult`, or should one replace the other? | Both expose `IsOk/IsErr`; `TFuture` is used by `ModernSyntax.Async.pas`; no comment explains the split |
