---
type: analysis
title: "02 Stack: ModernSyntax"
description: Languages, runtimes, frameworks, key library units, and external integrations — all measured from manifests and source.
status: stable
tags: [stack, discovery, delphi, boss, dunitx, functional-programming]
---

# ModernSyntax — Stack

## Language and runtime

**Language:** Object Pascal (Delphi dialect)  
**Minimum compiler:** Delphi XE (CompilerVersion 22, symbol `VER220`)  
**Maximum compiler in table:** Delphi 12 (CompilerVersion 36, symbol `VER360`)

Confirmed: `Source/ModernSyntax.inc` lines 28–44 list the full compiler-version/symbol table; `VER220` at line 244 opens the first non-Lazarus block; `VER360` at line 56 opens the top block. The comment on line 28 marks Delphi 12 as `??` (version uncertain at authoring time).

**Lazarus (FPC) compatibility:** a `{$IFDEF FCP}` block at `Source/ModernSyntax.inc:256` maps FPC to `DELPHI14_UP` only. No FPC build toolchain, no `.lpr` test project (`find "Test Delphi" -name "*.lpr" | wc -l` → 0), and Windows-only RTL imports make FPC compilation non-functional. The block is dead code; FPC is not a supported target.

**Framework mode switch:** `Source/ModernSyntax.inc` lines 49–53 — default build is VCL-mode (`HAS_VCL` defined); FMX mode activated only by uncommenting `{.$DEFINE FMX}` (line 46). Neither symbol is unconditionally set; the library ships framework-agnostic at the unit level.

---

## Package managers and registries

### Boss

| Field | Value | Source |
|---|---|---|
| Manifest | `boss.json` | root — line 1 |
| Lockfile | `boss-lock.json` | root — line 1 |
| Runtime dependencies | **none** | `boss.json` line 8: `"dependencies": {}` |
| Installed modules | **none** | `boss-lock.json` line 4: `"installedModules": {}` |
| Vendor directory | absent | `modules/` not present — confirmed: `ls modules/ 2>/dev/null` produced no output |
| gitignore rule | `modules/` excluded | `.gitignore` line containing `# Boss dependency manager vendor folder` |

`boss.json` also declares `"mainsrc": "./Source"` (line 6) — this is what Boss exposes as the importable path to downstream consumers.

### PubDelphi

| Field | Value | Source |
|---|---|---|
| Manifest | `pubdelphi.json` | root — line 1 |
| Schema | `https://www.pubdelphi.dev/schema/pubdelphi.schema.json` | `pubdelphi.json` line 1 |
| Kind | `runtime` | `pubdelphi.json` line 5 |
| Declared platforms | `Win32`, `Win64` | `pubdelphi.json` line 7 |
| Runtime dependencies | **none** | `pubdelphi.json` line 8: `"dependencies": {}` |

---

## Build system

**Format:** Embarcadero MSBuild (`.dproj` files)  
Confirmed: `Examples/CurryingDemo.dproj` line 1 — XML namespace `http://schemas.microsoft.com/developer/msbuild/2003`.  
Project format version in that file: `20.4` (line containing `<ProjectVersion>20.4</ProjectVersion>`) — this is the Embarcadero project-format version, not the Delphi IDE version.

**Target platforms configured in .dproj files** (measured: grep on `CurryingDemo.dproj` for `Platform` condition attributes):

- `Win32` — default
- `Win64`
- `iOSDevice64`
- `iOSSimARM64`
- `OSX64`
- `OSXARM64`

All six appear as conditional `PropertyGroup` blocks. Only `Win32` is the default (`Platform Condition="'$(Platform)'==''">Win32`). Whether the other five actually compile is not determinable from the project file alone — no CI output is present in the repo.

**App type:** `Console` (confirmed: `Examples/CurryingDemo.dproj` — `<FrameworkType>None</FrameworkType>` and `<AppType>Console</AppType>`). Example projects are console apps; the library itself has no app type.

---

## Standard-library units used (RTL/VCL — no third-party)

Measured: `awk '/^uses/{found=1} found{print; if(/;/)exit}' Source/*.pas` — full uses blocks extracted for all 16 source units.

| RTL/VCL unit | Units that import it | Notes |
|---|---|---|
| `SysUtils` | all 16 | universal |
| `Rtti` | ArrowFun, Async, Coroutine, Currying, Match, Objects, Option, ResultPair, Safetry — **9 of 16** | counted from uses blocks above |
| `Classes` | Async, Coroutine, Crypt, Currying, DotEnv, Match, Objects, ResultPair, Std, Stream — 10 of 16 | |
| `Generics.Collections` | ArrowFun, Coroutine, Currying, DotEnv, Match, Objects, Std, Stream, Tuple — 9 of 16 | |
| `Generics.Defaults` | Currying, Match, Tuple — 3 of 16 | |
| `TypInfo` | ArrowFun, Match, Objects, ResultPair, Tuple — 5 of 16 | |
| `SyncObjs` | Async, Coroutine, Currying, Objects — 4 of 16 | threading primitives |
| `Threading` | Async, Coroutine — 2 of 16 | `System.Threading` parallel tasks |
| `System.Threading` | Stream — 1 of 16 | note: different prefix style, same unit |
| `Windows` | DotEnv, Std — **2 of 16** | **Windows-only; no conditional guard in uses clause** — see Finding F-STACK-01 |
| `RegularExpressions` | RegExpression — 1 of 16 | Delphi XE+ built-in regex |
| `DateUtils` | Coroutine, Currying, Std — 3 of 16 | |
| `Math` | Currying, Std — 2 of 16 | |
| `Variants` | Match, Objects, Option — 3 of 16 | |

**No unit outside the Delphi RTL appears in any `uses` clause in `Source/`.** Confirmed: `grep -rn "^uses" -A 20 Source/*.pas` — every import resolves to a standard RTL/VCL name.

---

## Key library modules grouped by concern

### Functional core
- `ModernSyntax.ResultPair` — `TResultPair<S,F>`: success/failure sum type; imports only RTL
- `ModernSyntax.Option` — `TOption<T>`: null-safe optional; depends on `ResultPair`
- `ModernSyntax.Safetry` — exception-to-result bridge; depends on `SysUtils`, `Rtti`

### Pattern matching
- `ModernSyntax.Match` — `TMatch<T>`; depends on `ResultPair`, `RegExpression`, `Std`

### Functional combinators
- `ModernSyntax.Currying` — partial application; pure RTL
- `ModernSyntax.ArrowFun` — lambda helpers; depends on `Std`, umbrella
- `ModernSyntax.Stream` — pipeline combinators; depends on `Objects`, umbrella

### Data structures
- `ModernSyntax.Tuple` — `TTuple<T>`; pure RTL generics
- `ModernSyntax.Objects` — object extensions/helpers; pure RTL

### Concurrency
- `ModernSyntax.Async` — `TScheduler` task scheduler; uses `Threading`, `SyncObjs`
- `ModernSyntax.Coroutine` — coroutine support; uses `Threading`, `SyncObjs`

### Platform / environment
- `ModernSyntax.DotEnv` — `.env` file parser; imports `Windows` unconditionally
- `ModernSyntax.Std` — utility functions; imports `Windows` unconditionally
- `ModernSyntax.Crypt` — Base64 + MD5; implemented over `Classes`/`SysUtils` + `Std` only (no third-party crypto)
- `ModernSyntax.RegExpression` — thin wrapper over `RegularExpressions`

### Umbrella
- `ModernSyntax` — re-export/umbrella unit; depends on `Rtti`, `Generics.Collections`, `Generics.Defaults`

---

## Test framework

**Framework:** DUnitX  
Confirmed: `Test Delphi/EclbrSystem/PTestTuple.dpr` lines 15–18 — `uses DUnitX.Loggers.Console, DUnitX.Loggers.Xml.NUnit, DUnitX.TestFramework`.

**Output format:** NUnit XML — confirmed from `DUnitX.Loggers.Xml.NUnit` import and presence of `dunitx-results.xml` in both test suites.

**TestInsight integration:** `Test Delphi/EclbrSystem/TestInsightSettings.ini` contains `BaseUrl=http://DESKTOP-ISAQUEP:8102` — developer-local IDE test runner, not CI.

**Test projects** (measured: `find "Test Delphi" -name "*.dpr" | wc -l` → **11** total across both suites):

- `EclbrSystem/` — 10 `.dpr` test projects covering: Async, Currying, DotEnv, Match, Objects, Option, SafeTry, Std, Stream, Tuple
- `EclbrResultPair/` — 1 `.dpr` project covering ResultPair

DUnitX is not declared as a Boss dependency (`boss.json` dependencies empty) — it is either bundled in the Delphi IDE installation or expected to be available globally on the developer machine. No lockfile entry exists for it.

---

## External integrations

**None.** No HTTP client, database driver, REST API, message queue, or cloud SDK unit appears in any `uses` clause. All integrations are internal to the Delphi RTL.

---

## Findings

**F-STACK-01 — `Windows` unit imported unconditionally in two cross-platform-claimed units.**  
`ModernSyntax.DotEnv.pas` line 22 and `ModernSyntax.Std.pas` line 4 (of uses block) both list `Windows` without a `{$IFDEF MSWINDOWS}` or equivalent guard. The library's README claims support for Linux, macOS, iOS, and Android. These bare imports will cause a compile error on any non-Windows target. This extends Finding F-02 from [00-intake.md](00-intake.md) with the specific lines where the drift is observable.

**F-STACK-02 — DUnitX version is uncontrolled.**  
DUnitX is not recorded in `boss.json` or `boss-lock.json` (both `dependencies: {}`). The test suite compiles only if the developer's Delphi installation includes DUnitX at a compatible version. No mechanism pins it.

**F-STACK-03 — `Threading` vs. `System.Threading` naming inconsistency.**  
`ModernSyntax.Async.pas` and `ModernSyntax.Coroutine.pas` import `Threading` (short form); `ModernSyntax.Stream.pas` imports `System.Threading` (qualified form). Both resolve to the same unit via the `DCC_Namespace` default (`System;...`) declared in the `.dproj`. The inconsistency is cosmetic but suggests the units were written independently.
