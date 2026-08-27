---
type: analysis
title: "00-intake: ModernSyntax shallow-pass"
description: "Intake overview of project structure, primary stack, top-level areas, and prioritised examination targets."
status: stable
tags:
  - intake
  - analyst
  - shallow-pass
generated:
  by: "analyst-discovery@node:intake"
  at: "2026-08-27T00:00:00Z"
---

# ModernSyntax — Intake

## Project identity

**Name**: ModernSyntax
**Stated purpose**: Functional programming and modern syntax extension toolkit for Delphi.
**Version**: 1.0.0 (`boss.json`:3, `pubdelphi.json`:3 — both agree).
**License**: MIT (`LICENSE`:1 — confirmed in file; `README.md` badge agrees).
**Author**: Isaque Pinheiro (`ModernSyntax.inc`:23 — email `isaquepsp@gmail.com`).
**Homepage**: `https://github.com/ModernDelphiWorks/ModernSyntax` (`boss.json`:5).
**Package managers**: Boss (`boss.json`, `boss-lock.json`) and PubDelphi (`pubdelphi.json`).
**Dependencies**: none (`boss.json`:8 — `"dependencies": {}`; `pubdelphi.json`:8 — same).

## Primary stack at a glance

- **Language**: Object Pascal / Delphi (`.pas`, `.dpr`, `.dproj`)
- **Runtime target**: library, `kind: "runtime"` (`pubdelphi.json`:5)
- **UI frameworks**: VCL (default) or FMX (opt-in via `{$DEFINE FMX}` in `Source/ModernSyntax.inc`:46, commented-out by default)
- **Compiler range**: Delphi XE or superior (`README.md`:3 badge — confirmed). `Source/ModernSyntax.inc` defines VER blocks from VER220 (Delphi XE) through VER360 (Delphi 12); VER210 (Delphi 2010) also has a block, below the declared floor. **Demanda afirmou "roda em Lazarus/FPC"; o código contradiz:** `ModernSyntax.inc`:255–258 contém `{$IFDEF FCP}` (comment `//Lazarus`), mas `FCP` é typo para `FPC` — o símbolo que FPC/Lazarus efetivamente define; esse bloco nunca foi compilado. Tabela de versões do `.inc` (`:27–44`) lista apenas compiladores Delphi. Adota-se a declaração do código: não existe build Lazarus/FPC desta biblioteca.
- **Test framework**: DUnitX (confirmed: `Test Delphi/EclbrSystem/TestInsightSettings.ini` present; `UTestMS.*.pas` files follow DUnitX conventions)

## Top-level areas

| Directory | Contents | Measured |
|---|---|---|
| `Source/` | 16 `.pas` library units + 1 `.inc` compiler-version file | `ls Source/*.pas \| wc -l` → 16; `ls Source/*.inc \| wc -l` → 1 |
| `Examples/` | 2 demo projects (CurryingDemo, Coroutine) | `ls Examples/*.dpr \| wc -l` → 2 |
| `Test Delphi/EclbrSystem/` | 10 DUnitX test projects | `ls "Test Delphi/EclbrSystem/"*.dpr \| wc -l` → 10 |
| `Test Delphi/EclbrResultPair/` | 1 DUnitX test project (ResultPair) | `ls "Test Delphi/EclbrResultPair/"*.dpr \| wc -l` → 1 |
| `.project/` | AEFOS OKF knowledge bundle | bundle root |

## Source modules (16 units)

Sorted by line count (`wc -l Source/*.pas | sort -rn`):

| Unit | Lines | Stated responsibility |
|---|---|---|
| `ModernSyntax.Currying.pas` | 2,146 | Partial application / currying (TCurrying) |
| `ModernSyntax.Match.pas` | 1,783 | Pattern matching (TMatch\<T\>) |
| `ModernSyntax.ResultPair.pas` | 1,083 | Functional error handling (TResultPair\<S,F\>) |
| `ModernSyntax.Stream.pas` | 756 | Stream processing |
| `ModernSyntax.Objects.pas` | 604 | Object utilities |
| `ModernSyntax.Coroutine.pas` | 585 | Coroutine support |
| `ModernSyntax.Option.pas` | 486 | Null safety (TOption\<T\>) |
| `ModernSyntax.DotEnv.pas` | 432 | .env file parsing |
| `ModernSyntax.Async.pas` | 425 | Async/await style scheduler (TScheduler) |
| `ModernSyntax.Tuple.pas` | 365 | Anonymous tuples (TTuple\<T\>) |
| `ModernSyntax.Crypt.pas` | 335 | Cryptography utilities |
| `ModernSyntax.Std.pas` | 330 | Standard library extensions |
| `ModernSyntax.RegExpression.pas` | 328 | Regular expressions |
| `ModernSyntax.ArrowFun.pas` | 309 | Arrow functions |
| `ModernSyntax.Safetry.pas` | 241 | Safe try/except wrapper |
| `ModernSyntax.pas` | 288 | Base types: TFuture (record), TSet\<T\> (class), IMSObserver (interface) |

## Findings (drift between documents and code)

### F-01 — License mismatch in .inc header

**Intent** (`Source/ModernSyntax.inc`:6-8): states "GNU Lesser General Public License, Version 3".
**Actual** (`LICENSE`:1): file contains the MIT License text.
`README.md` badge and `ModernSyntax.pas`:9 both reference MIT.
The `.inc` header text is stale / copied from an older codebase; the governing license is MIT, confirmed in the `LICENSE` file.

### F-02 — Platform claim wider than published target

**Intent** (`README.md`:28): "VCL, FMX, Console (Win/Linux/macOS/iOS/Android)".
**Actual** (`pubdelphi.json`:7): `"platforms": ["Win32", "Win64"]` — two platforms only.
Cross-platform reality is unverified in this pass; must be confirmed against compiler conditionals in each module.

### F-03 — FMX support is opt-in, off by default

`Source/ModernSyntax.inc`:46 — `{.$DEFINE FMX}` is commented out, making `HAS_VCL` the active define (`ModernSyntax.inc`:52). The README presents FMX as an equal first-class option without noting it requires a manual define.

### F-04 — Test coverage gap

11 test files cover the modules below; `ModernSyntax.Coroutine`, `ModernSyntax.Crypt`, `ModernSyntax.RegExpression`, `ModernSyntax.ArrowFun`, and `ModernSyntax.Objects` appear to have no corresponding test `.dpr` in either test folder. Confirmed by listing: `ls "Test Delphi/EclbrSystem/"*.dpr` — no file for Coroutine, Crypt, RegExpression, ArrowFun. `PTestObjects.dpr` exists for Objects.

> Correction after recount: `PTestObjects.dpr` IS present (confirmed listing above). Gap is: Coroutine, Crypt, RegExpression, ArrowFun — 4 modules with no test project found.

## Claims to verify (leads only — not yet confirmed in code)

- `README.md`:13 — "high-performance" — no benchmark present; not verifiable at shallow pass.
- `README.md`:17 — TOption\<T\> prevents null-reference errors "at compile-time or runtime" — compile-time enforcement depends on Delphi generics constraints; needs code-level check in `Source/ModernSyntax.Option.pas`.
- `README.md`:22 — TScheduler provides "async/await style" without "manual thread synchronization" — thread model used by `ModernSyntax.Async.pas` and `ModernSyntax.Coroutine.pas` not examined at this pass.
- `README.md`:32 — installable via `boss install ModernSyntax` — assumes registry publication; `boss-lock.json` is present but not checked against a live registry.
- `ModernSyntax.inc`:23 — copyright year "2016" — `.inc` header says 2016, but `LICENSE`:3 and `ModernSyntax.pas`:7 say 2025-2026. The `.inc` header's year is likely stale.

## Prioritised areas for deep analysis

1. **`ModernSyntax.Currying.pas`** (2,146 lines) — largest unit; currying/partial-application design, type safety, and memory handling.
2. **`ModernSyntax.Match.pas`** (1,783 lines) — second largest; pattern-matching engine correctness and exhaustiveness.
3. **`ModernSyntax.ResultPair.pas`** (1,083 lines) — core error-handling contract; API surface and exception-escape paths.
4. **`ModernSyntax.Async.pas` + `ModernSyntax.Coroutine.pas`** — concurrency model; thread safety, platform portability, and the "no manual synchronization" claim.
5. **License / platform header audit** — resolve F-01 and F-02; check all `.pas` file headers for lingering LGPL text.
6. **Test coverage** — map each module to its test file; identify untested units and blank test stubs.
