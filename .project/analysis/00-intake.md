---
type: analysis
title: "00 Intake: ModernSyntax"
description: Shallow discovery pass — project name, primary stack, top-level areas, and prioritized areas to examine.
status: stable
tags: [intake, discovery, delphi, functional-programming]
---

# ModernSyntax — Intake

## Project identity

**Name:** ModernSyntax  
**Version:** 1.0.0 (confirmed: `boss.json` key `"version"`)  
**Author:** Isaque Pinheiro  
**License:** MIT (confirmed: `LICENSE` line 1 — "MIT License"; `boss.json` carries no `license` key)  
**Homepage:** https://github.com/ModernDelphiWorks/ModernSyntax (confirmed: `boss.json` `"homepage"`)  
**Package registries:** Boss (`boss.json`) + PubDelphi (`pubdelphi.json`)

## Primary stack

- **Language:** Object Pascal (Delphi), minimum Delphi XE (confirmed: `Source/ModernSyntax.inc` — compiler-version table starting at `VER220`)
- **Generics:** used throughout (`Generics.Collections`, `Generics.Defaults` — confirmed: `Source/ModernSyntax.pas` lines 17–20)
- **RTTI:** `Rtti` unit present in umbrella unit (confirmed: `Source/ModernSyntax.pas` line 15)
- **Test framework:** DUnitX (confirmed: `Test Delphi/EclbrSystem/dunitx-results.xml` present; test projects follow `PTest*.dpr` naming)
- **No external runtime dependencies** (confirmed: `boss.json` `"dependencies": {}` and `pubdelphi.json` `"dependencies": {}`)

## Measured top-level structure

```
. (project root)
├── Source/          — 16 .pas units + 1 .inc  (ls -1 Source/ | wc -l → 17)
├── Examples/        — 2 example projects: CurryingDemo, PCorrotina
├── Test Delphi/     — 2 test sub-suites: EclbrSystem, EclbrResultPair
├── boss.json        — Boss package manifest
├── pubdelphi.json   — PubDelphi registry manifest
├── LICENSE          — MIT
└── README.md        — bilingual (EN + PT-BR)
```

Total source lines: **10 496** (measured: `wc -l Source/*.pas | tail -1`)

## Source units — 16 units (confirmed: `grep -r "^unit" Source/`)

| Unit | Lines | Role |
|---|---|---|
| `ModernSyntax.Currying` | 2 146 | Partial application / currying |
| `ModernSyntax.Match` | 1 783 | Pattern matching (`TMatch<T>`) |
| `ModernSyntax.ResultPair` | 1 083 | Functional error handling (`TResultPair<S,F>`) |
| `ModernSyntax.Stream` | 756 | Stream / pipeline combinators |
| `ModernSyntax.Objects` | 604 | Object extensions |
| `ModernSyntax.Coroutine` | 585 | Coroutine support |
| `ModernSyntax.Option` | 486 | Null-safe optional (`TOption<T>`) |
| `ModernSyntax.DotEnv` | 432 | `.env` file loader |
| `ModernSyntax.Async` | 425 | Async scheduler (`TScheduler`) |
| `ModernSyntax.Tuple` | 365 | Tuple types (`TTuple<T>`) |
| `ModernSyntax.Crypt` | 335 | Cryptography helpers |
| `ModernSyntax.Std` | 330 | Standard utilities |
| `ModernSyntax.RegExpression` | 328 | Regex wrapper |
| `ModernSyntax.ArrowFun` | 309 | Arrow-function / lambda helpers |
| `ModernSyntax` (umbrella) | 288 | Central re-export unit |
| `ModernSyntax.Safetry` | 241 | Safe-try exception wrapper |

Line counts from: `wc -l Source/*.pas | sort -rn`

## Test coverage areas (measured: `ls "Test Delphi/EclbrSystem/"`)

**EclbrSystem** suite covers: Async, Currying, DotEnv, Match, Objects, Option, SafeTry, Std, Stream, Tuple — plus legacy ECL-BR helpers (Dictionary, Directory, List, Map, Str, Vector, IfThen).  
**EclbrResultPair** suite covers: ResultPair only (`UTestMS.ResultPair.pas`, `UTestResultPair.pas`).

Units with **no visible test file**: Coroutine, Crypt, RegExpression, ArrowFun (names absent from `ls` output above — not counted, needs explicit `grep`).

## Claims to verify

All entries below are from `README.md`; none yet confirmed in code.

| # | Claim | Source location | Where to check |
|---|---|---|---|
| C1 | Supports Win / Linux / macOS / iOS / Android | README.md compatibility table | `pubdelphi.json` lists only `Win32`/`Win64` — **possible drift** |
| C2 | `TScheduler` provides async/await-style scheduling | README.md §Key Features | `Source/ModernSyntax.Async.pas` — confirm class name and public API |
| C3 | `TMatch<T>` exposes `CaseOf` / `ElseOf` / `MatchValue` | README.md §Quick Start | `Source/ModernSyntax.Match.pas` — confirm method names |
| C4 | `TOption<T>` exposes `Some`, `HasValue`, `Value`, `ValueOrElse` | README.md §Quick Start | `Source/ModernSyntax.Option.pas` — confirm public interface |
| C5 | `TResultPair<S,F>` exposes `Success` and `Failure` constructors | README.md §Quick Start | `Source/ModernSyntax.ResultPair.pas` |
| C6 | License is MIT | README.md footer | `Source/ModernSyntax.inc` header says LGPL 3 — **drift detected** (see F-01) |

## Findings from this pass

**F-01 — License header inconsistency.**  
`LICENSE` (root, line 1) and README both declare MIT. `Source/ModernSyntax.inc` (lines 7–18, read directly) declares "GNU Lesser General Public License / Versão 3". The `.inc` comment predates the MIT re-licensing and was not updated. Architect must decide whether to purge or align.

**F-02 — Platform scope narrower in registry than in documentation.**  
`pubdelphi.json` `"platforms": ["Win32", "Win64"]` (line 6, confirmed) contradicts README compatibility table which claims Win/Linux/macOS/iOS/Android. May be a registry limitation rather than a compiler-conditional gap — requires reading compiler-guard blocks in source.

**F-03 — 10 undocumented units.**  
README §Key Features names 6 constructs (Option, ResultPair, Match, Scheduler, Tuple, Currying). Source tree has 10 more units (Coroutine, Crypt, DotEnv, Objects, RegExpression, ArrowFun, SafeTry, Std, Stream, umbrella). Their public APIs and stability are undocumented.

## Prioritized areas for deep examination

1. **`ModernSyntax.Currying.pas`** (2 146 lines — largest) — arity handling, type safety, partial application internals
2. **`ModernSyntax.Match.pas`** (1 783 lines) — matching strategy, exhaustiveness enforcement, generic constraints
3. **`ModernSyntax.ResultPair.pas`** (1 083 lines) — monadic chaining, bind/map API
4. **`ModernSyntax.Option.pas`** (486 lines) — confirm C4; relationship to Safetry
5. **`ModernSyntax.Async.pas` + `ModernSyntax.Coroutine.pas`** — threading model and the relationship between the two async mechanisms
6. **`Source/ModernSyntax.inc`** — resolve F-01 (LGPL vs. MIT license header)
