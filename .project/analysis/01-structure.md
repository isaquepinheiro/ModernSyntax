---
type: analysis
title: "01 Structure: ModernSyntax"
description: "Folder tree, entry points, build/test/lint commands, and structural unknowns for ModernSyntax."
status: stable
tags: [structure, discovery, delphi, functional-programming]
sources:
  - id: intake
    resource: /analysis/00-intake.md
    title: "00 Intake — ModernSyntax"
---

# ModernSyntax — Structure

## 1. Folder tree

Measured: `find . -maxdepth 3 -not -path './.git/*' -not -path './node_modules/*' | sort`

```
. (project root)
├── .claude/workflows/runs/        — AEFOS pipeline artefacts
├── .gitignore                     — Delphi-standard; excludes *.exe, *.dcu, *.map, modules/
├── .project/                      — OKF bundle (pipeline memory)
│   ├── analysis/
│   │   ├── 00-intake.md           — prior intake pass
│   │   └── 01-structure.md        — this document
│   └── history/
│       ├── changes/ decisions/ incidents/
│       └── cycles/
├── Examples/
│   ├── CurryingDemo.dpr / .dproj  — currying demo console app
│   ├── PCorrotina.dpr / .dproj    — coroutine demo console app
│   └── UCurryingDemo.pas / UCorrotina.pas / UCorrotina.dfm
├── Source/                        — 17 files total (ls -1 Source/ | wc -l → 17)
│   ├── ModernSyntax.inc           — compiler-version conditional defines
│   ├── ModernSyntax.pas           — umbrella unit; defines TFuture, TSet<T>
│   ├── ModernSyntax.ArrowFun.pas
│   ├── ModernSyntax.Async.pas
│   ├── ModernSyntax.Coroutine.pas
│   ├── ModernSyntax.Crypt.pas
│   ├── ModernSyntax.Currying.pas
│   ├── ModernSyntax.DotEnv.pas
│   ├── ModernSyntax.Match.pas
│   ├── ModernSyntax.Objects.pas
│   ├── ModernSyntax.Option.pas
│   ├── ModernSyntax.RegExpression.pas
│   ├── ModernSyntax.ResultPair.pas
│   ├── ModernSyntax.Safetry.pas
│   ├── ModernSyntax.Std.pas
│   ├── ModernSyntax.Stream.pas
│   └── ModernSyntax.Tuple.pas
├── Test Delphi/
│   ├── EclbrResultPair/           — 2 test .pas, 1 .dpr, 1 .dproj
│   └── EclbrSystem/               — 18 test .pas, 10 .dpr, 10 .dproj, 1 .groupproj
│       └── DCC.bat                — CodeCoverage.exe runner (post-build, Windows only)
├── LICENSE                        — MIT
├── README.md                      — bilingual (EN + PT-BR)
├── SECURITY.md
├── boss.json                      — Boss package manager manifest
├── boss-lock.json                 — Boss lock file
└── pubdelphi.json                 — PubDelphi registry manifest
```

---

## 2. Source units — 16 units (measured: `ls ./Source/*.pas | wc -l → 16`)

Total source lines: **10 496** (measured: `wc -l ./Source/*.pas | tail -1`)

Sorted by size (measured: `wc -l ./Source/*.pas | sort -rn`):

| Unit | Lines | Primary exported type(s) |
|---|---|---|
| `ModernSyntax.Currying` | 2 146 | `TCurrying`, `ICleanup`, `TNumeric*` implementations |
| `ModernSyntax.Match` | 1 783 | `TMatch`, `TCaseGroup`, `TMatchSession`, `TCaseType` |
| `ModernSyntax.ResultPair` | 1 083 | `TResultPair<S,F>`, `TResultValue`, `TResultType` |
| `ModernSyntax.Stream` | 756 | `TModernStreamReader`, `TStreamReaderListenerEvent` |
| `ModernSyntax.Objects` | 604 | `TModernObject`, `IModernObject`, `TAutoRefLock`, smart-pointer helpers |
| `ModernSyntax.Coroutine` | 585 | `TCoroutine`, `IScheduler`, `TScheduler`, `TCoroutineState` |
| `ModernSyntax.Option` | 486 | `TSome`, `TNone`, `TNoneProc` |
| `ModernSyntax.DotEnv` | 432 | `TDotEnv` |
| `ModernSyntax.Async` | 425 | `TAsync`, `IAutoLock`, `TAutoLock` |
| `ModernSyntax.Tuple` | 365 | `TTuple<T>`, type aliases `TTuplu*` |
| `ModernSyntax.Crypt` | 335 | `TCrypt`, `TPacket` |
| `ModernSyntax.Std` | 330 | `TStd`, `TPointerStream` |
| `ModernSyntax.RegExpression` | 328 | `TModernRegEx` |
| `ModernSyntax.ArrowFun` | 309 | `TArrow` |
| `ModernSyntax` (umbrella) | 288 | `TFuture`, `TSet<T>`, `Tuple` alias |
| `ModernSyntax.Safetry` | 241 | `TSafeTry`, `TSafeResult` |

**Note:** The umbrella unit (`ModernSyntax.pas`) does **not** re-export the sub-units via `uses`; it defines `TFuture` and `TSet<T>` directly (confirmed: `Source/ModernSyntax.pas` lines 18–145 — no `uses` clause referencing other `ModernSyntax.*` units). Consumers must add individual sub-units to their own `uses` clause.

---

## 3. Entry points

### Library consumers
There is no compiled binary entry point. The library is source-only; consumers add `./Source` to their Delphi library path (confirmed: `boss.json` `"mainsrc": "./Source"` line 6; `pubdelphi.json` `"sources": ["./Source/"]` line 5).

**Install command** (Boss package manager, stated in README — no local automation script confirmed):
```sh
boss install ModernSyntax
```

### Example programs
Measured: `ls ./Examples/*.dpr | wc -l → 2`

| File | Program name |
|---|---|
| `Examples/CurryingDemo.dpr` | `CurryingDemo` (confirmed: `grep 'program ' Examples/CurryingDemo.dpr`) |
| `Examples/PCorrotina.dpr` | `PCorrotina` (confirmed: `grep 'program ' Examples/PCorrotina.dpr`) |

Both are console applications. No shell wrapper; built through the Delphi IDE or `dcc32`/`dcc64` directly.

### Test programs
Measured: `find 'Test Delphi' -name '*.dpr' | wc -l → 11`

| Program | Suite | Filename-inferred coverage |
|---|---|---|
| `PTestAsync` | EclbrSystem | `ModernSyntax.Async` |
| `PTestCurrying` | EclbrSystem | `ModernSyntax.Currying` |
| `PTestDotEnv` | EclbrSystem | `ModernSyntax.DotEnv` |
| `PTestMatch` | EclbrSystem | `ModernSyntax.Match` |
| `PTestObjects` | EclbrSystem | `ModernSyntax.Objects` |
| `PTestOption` | EclbrSystem | `ModernSyntax.Option` |
| `PTestSafeTry` | EclbrSystem | `ModernSyntax.Safetry` |
| `PTestStd` | EclbrSystem | `ModernSyntax.Std` |
| `PTestStream` | EclbrSystem | `ModernSyntax.Stream` |
| `PTestTuple` | EclbrSystem | `ModernSyntax.Tuple` |
| `PTestResultPair` | EclbrResultPair | `ModernSyntax.ResultPair` |

Test group project: `Test Delphi/EclbrSystem/TestMSGroup.groupproj` groups all 11 test .dproj plus `Examples/CurryingDemo.dproj` (confirmed: `grep 'Include=' TestMSGroup.groupproj` — 12 entries).

Test framework: **DUnitX** (confirmed: `dunitx-results.xml` present in both `EclbrSystem/` and `EclbrResultPair/`).

Units with **no test program found** (names absent from `find 'Test Delphi' -name '*.dpr'` output): `ModernSyntax.ArrowFun`, `ModernSyntax.Coroutine`, `ModernSyntax.Crypt`, `ModernSyntax.RegExpression`.

---

## 4. Build, run, test, lint commands

### Build
**Tool:** Delphi IDE (RAD Studio) or `dcc32.exe` / `dcc64.exe` command-line compiler.  
**No Makefile, shell script, or CI config exists** (confirmed: `find . -maxdepth 2 -name 'Makefile' -o -name '*.yml' -o -name '*.yaml' -o -name 'Dockerfile' -o -name '*.sh'` returned no output).

Minimum compiler: **Delphi XE** (VER220) — confirmed at `Source/ModernSyntax.inc` line ~203 (`{$IFDEF VER220}` block defining `DELPHI14_UP` and `DELPHI15_UP`).

### Run tests
No automated test-runner script. Tests are built and executed individually or via the group project in the Delphi IDE. DUnitX writes XML results to `dunitx-results.xml` per suite.

### Coverage
`Test Delphi/EclbrSystem/DCC.bat` — Windows batch script invoking `CodeCoverage.exe` for 13 named projects (Match, Tuple, Stream, Directory, Objects, Threading, Std, Str, SafeTry, Dictionary, Vector, Map, List). Absent from this script: Coroutine, Crypt, RegExpression, ArrowFun, Option, DotEnv, Currying, ResultPair (confirmed by reading `DCC.bat` fully — only the 13 targets listed are present).

### Lint / static analysis
One DelphiLint config found: `Test Delphi/EclbrSystem/PTestMatch.delphilint` (confirmed: `find . -name '*.delphilint'`). No project-wide lint automation.

### Package publish
UNKNOWN — no publish script in the repository. `pubdelphi.json` is the registry manifest; the PubDelphi CLI publish command was not confirmed locally.

---

## 5. Platform targets

`pubdelphi.json` line 6 declares `"platforms": ["Win32", "Win64"]`.

Delphi `.dproj` files inside `Test Delphi/` declare **14 platform targets** (measured: `grep -rh 'Platform Name=' 'Test Delphi/' --include='*.dproj' | grep -oE '"[^"]+"' | sort -u`):

`Android`, `Android64`, `Linux64`, `OSX32`, `OSX64`, `OSXARM64`, `Win32`, `Win64`, `Win64x`, `WinARM64EC`, `iOSDevice32`, `iOSDevice64`, `iOSSimARM64`, `iOSSimulator`

**Drift (F-02):** `pubdelphi.json` restricts to Win32/Win64, while `.dproj` files carry multi-platform configurations aligning with README's Win/Linux/macOS/iOS/Android claim. This is a registry metadata gap — the source itself carries no OS-conditional guards beyond the Delphi version blocks in `ModernSyntax.inc`.

---

## 6. Dependency graph (runtime)

`boss.json` `"dependencies": {}` — confirmed empty (line 8).  
`pubdelphi.json` `"dependencies": {}` — confirmed empty (line 7).  
`boss-lock.json` `"installedModules": {}` — no external modules installed (confirmed).

All units depend exclusively on Delphi RTL standard units (`Rtti`, `SysUtils`, `Generics.Collections`, `Generics.Defaults`, `Classes`, `RegularExpressions` — sampled from `uses` clauses in source file headers). No third-party runtime dependency exists.

---

## 7. Structural findings and unknowns

### F-01 — License header in `.inc` contradicts root `LICENSE`
`Source/ModernSyntax.inc` lines 7–18 declare GNU LGPL v3. `LICENSE` (root) and README declare MIT. The `.inc` comment is a leftover from an earlier licensing era; see [intake](00-intake.md) F-01.

### F-02 — `pubdelphi.json` platform scope narrower than `.dproj` targets
Resolved as registry metadata gap (see §5). Source code carries no platform-specific conditionals that would block non-Windows compilation.

### F-03 — No automated test runner or CI pipeline
Test execution requires Delphi IDE or manual binary invocation. No CI configuration was found. Automated testing in a pipeline would require scripting `dcc32`/`dcc64` and binary execution — all UNKNOWN for this repo.

### F-04 — Umbrella unit does not re-export sub-units
`ModernSyntax.pas` defines `TFuture` and `TSet<T>` inline and does not `uses` any sub-unit (confirmed: `Source/ModernSyntax.pas` lines 14–20 — `uses` clause lists only `Rtti`, `SysUtils`, `Generics.Collections`, `Generics.Defaults`). Consumers cannot `uses ModernSyntax` to gain the full API.

### F-05 — DCC.bat coverage gap
`DCC.bat` invokes CodeCoverage for 13 of the testable modules but omits 8 source units entirely (ArrowFun, Coroutine, Crypt, RegExpression, Option, DotEnv, Currying, ResultPair). Coverage data for those units is not generated.

### UNKNOWN — `uses` clause verification inside test files
Test-to-unit mapping in §3 is inferred from filenames, not confirmed by reading `uses` clauses inside each `.dpr`. The actual sub-unit coverage of each test binary may differ.

### UNKNOWN — Delphi 12 VER constant
`Source/ModernSyntax.inc` labels the VER360 block as `"Delphi ???"`; the comment does not confirm whether VER360 is Delphi 12. Correct version-detection coverage for Delphi 12 is unverified.
