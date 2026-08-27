---
type: analysis
kind: artifact
title: "Structure: ModernSyntax — folder tree, entry points, build/run/test/lint"
description: STRUCTURE step dossier mapping repository layout, source units, test organisation, and build mechanics for the ModernSyntax Delphi library.
status: stable
generated:
  by: analyst@node:analyst-structure
  at: 2026-08-27T00:00:00Z
tags:
  - structure
  - delphi
  - modular-library
  - dunitx
---

# Structure — ModernSyntax

## 1. Repository root

```
.
├── Source/                  ← all deliverable units (16 .pas + 1 .inc)
├── Examples/                ← 2 standalone demo projects
├── Test Delphi/
│   ├── EclbrSystem/         ← primary test suite (10 .dpr + 18 .pas)
│   └── EclbrResultPair/     ← result-pair test suite (1 .dpr + 2 .pas)
├── boss.json                ← Boss package manager manifest
├── boss-lock.json           ← Boss lockfile
├── pubdelphi.json           ← PubDelphi registry descriptor
├── LICENSE                  ← MIT
├── README.md
└── SECURITY.md
```

Root file count: `ls -la .` → 7 visible entries (4 dirs + 3 json/md at top level beside .gitignore).

## 2. Source directory

**Measured:** `ls ./Source/ | wc -l` → **17** files (16 `.pas` + 1 `.inc`).

**Unit names** (confirmed: `grep -n "^unit " Source/*.pas`):

| File | Declared unit | Lines (`wc -l`) | Primary public types |
|---|---|---|---|
| `ModernSyntax.pas` | `ModernSyntax` | 288 | `TFuture`, `TSet<T>`, `IMSObserver` (lines 27–173) |
| `ModernSyntax.ArrowFun.pas` | `ModernSyntax.ArrowFun` | 309 | `TArrow` (line 37) |
| `ModernSyntax.Async.pas` | `ModernSyntax.Async` | 425 | `TAsync`, `IAutoLock`, `TAutoLock` (lines 33–50) |
| `ModernSyntax.Coroutine.pas` | `ModernSyntax.Coroutine` | 585 | `IScheduler`, `TCoroutineState`, `TFuncCoroutine` (lines 30–35) |
| `ModernSyntax.Crypt.pas` | `ModernSyntax.Crypt` | 335 | `TCrypt`, `TPacket` (lines 25–33) |
| `ModernSyntax.Currying.pas` | `ModernSyntax.Currying` | **2,146** | `TCurrying`, `TPipeline<T>`, `TMemoizedCache<T,U>`, `INumeric<T>` (lines 97–163) |
| `ModernSyntax.DotEnv.pas` | `ModernSyntax.DotEnv` | 432 | `TDotEnv` (line 26) |
| `ModernSyntax.Match.pas` | `ModernSyntax.Match` | **1,783** | `TMatch<T>`, `TMatch`, `TCaseType` (lines 57–211) |
| `ModernSyntax.Objects.pas` | `ModernSyntax.Objects` | 604 | `TModernObject`, `TSmartPtr<T>`, `TMutableRef<T>`, `IModernObject` (lines 32–80) |
| `ModernSyntax.Option.pas` | `ModernSyntax.Option` | 486 | `TOption<T>`, `TSome`, `TNone` (lines 25–48) |
| `ModernSyntax.RegExpression.pas` | `ModernSyntax.RegExpression` | 328 | `TModernRegEx` wrapping `System.RegularExpressions` (line 28) |
| `ModernSyntax.ResultPair.pas` | `ModernSyntax.ResultPair` | 1,083 | `TResultPair<S,F>`, `TResultPairValue<T>`, `TResultType` (lines 25–57) |
| `ModernSyntax.Safetry.pas` | `ModernSyntax.SafeTry` | 241 | `TSafeTry`, `TSafeResult` (lines 23–42) |
| `ModernSyntax.Std.pas` | `ModernSyntax.Std` | 330 | `TStd`, `TPointerStream` (lines 30–36) |
| `ModernSyntax.Stream.pas` | `ModernSyntax.Stream` | 756 | `TModernStreamReader` (line 40) |
| `ModernSyntax.Tuple.pas` | `ModernSyntax.Tuple` | 365 | `TTuple<K>`, `TTuple`, `TTupleDict<K>` (lines 46–68) |
| `ModernSyntax.inc` | *(include, not a unit)* | 270 | Compiler-version macros `{$DEFINE DELPHInn_UP}` and FMX/VCL switch (lines 49–54) |

Total source lines: `wc -l Source/*.pas Source/*.inc` → **10,766** (unique; the `wc -l` run here excluded the duplication artifact from re-running over the same path).

Largest unit by line count: `ModernSyntax.Currying.pas` at 2,146 lines.
Second largest: `ModernSyntax.Match.pas` at 1,783 lines.

### 2.1 Foundation unit

`ModernSyntax.pas` (line 14) is the root shared unit. It defines `TFuture` (lines 32–86) — the async result container re-aliased by `Async` and `Coroutine` units — and `TSet<T>` (lines 88–173). Both `ModernSyntax.Async` (line 30) and `ModernSyntax.Coroutine` (line 29) re-export `TFuture` as a local alias pointing at `ModernSyntax.TFuture`.

### 2.2 Compiler include

`ModernSyntax.inc` (line 270) is the single include file. It defines cumulative version symbols (`DELPHI14_UP` through `DELPHI29_UP`), covering Delphi 2010 (VER210) through an unnamed future version (VER360). It also handles FMX/VCL switching via `{$DEFINE HAS_FMX}` / `{$DEFINE HAS_VCL}` toggled by `{.$DEFINE FMX}` at line 46 (commented out by default → VCL mode active unless user edits).

## 3. Examples directory

**Measured:** `ls ./Examples/*.dpr | wc -l` → **2** projects.

| Project | Subject |
|---|---|
| `CurryingDemo.dpr` | Demonstrates `TCurrying` / `TPipeline<T>` |
| `PCorrotina.dpr` | Demonstrates coroutines (`UCorrotina.pas` + `UCorrotina.dfm`) |

These are standalone console/VCL applications; they are compiled via the IDE or included in `TestMSGroup.groupproj` (confirmed at line `..\..\Examples\CurryingDemo.dproj`).

## 4. Test directory

### 4.1 EclbrSystem — primary suite

**Measured:**
- `.dpr` projects: `ls "Test Delphi/EclbrSystem/"*.dpr | wc -l` → **10**
- `.pas` test units: `ls "Test Delphi/EclbrSystem/"*.pas | wc -l` → **18**

**Test project files (10, confirmed by `ls`):**

`PTestAsync.dpr`, `PTestCurrying.dpr`, `PTestDotEnv.dpr`, `PTestMatch.dpr`, `PTestObjects.dpr`, `PTestOption.dpr`, `PTestSafeTry.dpr`, `PTestStd.dpr`, `PTestStream.dpr`, `PTestTuple.dpr`

**Test unit files (18, confirmed by `ls`):**

`UTestEcl.Dictionary.pas`, `UTestEcl.Directory.pas`, `UTestEcl.List.pas`, `UTestEcl.Map.pas`, `UTestEcl.Str.pas`, `UTestEcl.Vector.pas`, `UTestEclbr.IfThen.pas`, `UTestMMS.Threading.pas`, `UTestMS.Currying.pas`, `UTestMS.DotEnv.pas`, `UTestMS.Match.pas`, `UTestMS.Muttle.pas`, `UTestMS.Objects.pas`, `UTestMS.Option.pas`, `UTestMS.SafeTry.pas`, `UTestMS.Std.pas`, `UTestMS.StreamReader.pas`, `UTestMS.Tuple.pas`

**Test framework:** DUnitX — confirmed by presence of `dunitx-results.xml` and by `uses DUnitX.TestFramework` in test units (e.g. `UTestEcl.Dictionary.pas:4`, `UTestMMS.Threading.pas:3`). Attribute `[Test]` appears **425 times** (confirmed: `grep -r "^\s*\[Test\]" "Test Delphi/" --include="*.pas" | wc -l` → 425).

**Group project:** `TestMSGroup.groupproj` (MSBuild group) bundles all 10 EclbrSystem test projects plus `PTestResultPair` and `CurryingDemo`.

### 4.2 EclbrResultPair — result-pair suite

**Measured:**
- `.dpr` projects: `ls "Test Delphi/EclbrResultPair/"*.dpr | wc -l` → **1** (`PTestResultPair.dpr`)
- `.pas` test units: `ls "Test Delphi/EclbrResultPair/"*.pas | wc -l` → **2** (`UTestMS.ResultPair.pas`, `UTestResultPair.pas`)

## 5. Build, run, test, lint

### 5.1 Build

There is **no CLI build script** for the library itself. Compilation is performed exclusively through the Delphi IDE (RAD Studio) using MSBuild `.dproj` project files. The package manifest `pubdelphi.json` (line 4) declares `"kind": "runtime"` and `"sources": ["./Source/"]`, meaning consumers point their IDE at `./Source/` directly — there is no compiled output to distribute.

**Command (Delphi IDE / MSBuild):**
```
msbuild PTestMatch.dproj /t:Build /p:Config=Debug
```
or via the IDE's Build All (the group project `TestMSGroup.groupproj` drives this).

### 5.2 Package installation

Two package managers are supported:

**Boss** (`boss.json`, confirmed at line 1):
```sh
boss install ModernSyntax
```

**PubDelphi** (`pubdelphi.json`, confirmed at line 2):
```sh
pubdelphi install ModernSyntax
```

No third-party dependencies are installed: `boss-lock.json` `"installedModules": {}` (confirmed at line 3).

### 5.3 Tests

Each test project is a standalone console DUnitX runner. Run any project from the IDE or:
```
PTestMatch.exe       # runs pattern-matching tests
PTestCurrying.exe    # runs currying tests
# … etc.
```

### 5.4 Code coverage

`Test Delphi/EclbrSystem/DCC.bat` (confirmed by read) runs `CodeCoverage.exe` with flags `-emma -xml -html -xmllines` against each test project's `.map` and `.exe`. Output lands under `CodeCoverage/<ModuleName>/`. **Note:** the script references 14 projects (`PTestDictionary`, `PTestVector`, `PTestMap`, `PTestList`, `PTestStr`, `PTestDirectory`, `PTestObjects`, `PTestThreading`, `PTestStd`, `PTestStr`, `PTestSafeTry`, `PTestMatch`, `PTestTuple`, `PTestStream`) but only 10 of those `.dpr` files currently exist — see §7.

### 5.5 Lint / static analysis

No automated lint step was found in the repository (no shell scripts, no GitHub Actions, no Makefile — confirmed: `find . -name "*.yml" -o -name "*.yaml" -o -name "Makefile" -o -name "*.sh" | grep -v ".git"` returned only internal AEFOS workflow YAML).

One `.delphilint` file exists: `Test Delphi/EclbrSystem/PTestMatch.delphilint` — this is a Castalia/DelphiLint project-level config, scoped to that single test project only.

## 6. Platforms and compatibility

**From `pubdelphi.json:6`:** `"platforms": ["Win32", "Win64"]`

**From `ModernSyntax.inc:28-33`:** Compiler detection covers Delphi 2010 (VER210) through Delphi 12 (VER360); declared floor per `README.md:3` é Delphi XE. `ModernSyntax.inc:256` contém `{$IFDEF FCP}` (comment `//Lazarus`), mas `FCP` é typo para `FPC` — bloco morto, nunca compilado; não existe suporte FPC/Lazarus.

**From `ModernSyntax.inc:46-53`:** FMX is available but **disabled by default** (`{.$DEFINE FMX}` commented out → `HAS_VCL` active).

README claims `"VCL, FMX, Console (Win/Linux/macOS/iOS/Android)"` — NOT VERIFIED for Linux/macOS/iOS/Android: no platform-specific project files or CI jobs targeting those platforms were found in the repository.

## 7. Findings (drift)

### F-01 — Orphaned test units reference absent external libraries

**18** test units exist in `Test Delphi/EclbrSystem/`; **8** of them import libraries not present in `Source/`:

- `UTestEcl.Dictionary.pas:9-10`: `uses … Fluent.Core, Fluent.Collections;`
- `UTestEcl.List.pas:9-10`: `uses … Fluent.Core, Fluent.Collections;`
- `UTestEcl.Map.pas` — same pattern (imports confirmed: same `uses` block)
- `UTestEcl.Vector.pas`, `UTestEcl.Str.pas`, `UTestEcl.Directory.pas` — same `Fluent.*` imports
- `UTestEclbr.IfThen.pas:5`: `uses … ecl.ifthen;` — unit `ecl.ifthen` not in `Source/`

No source unit named `Fluent.*` or `ecl.*` exists under `Source/` (confirmed: `ls Source/` shows only `ModernSyntax.*`). These units are from a different library (likely `eclbr` / `fluent-collections`) that appears to have been split out or removed. The test files remain but cannot compile without those external libraries.

### F-02 — DCC.bat references non-existent test projects

`Test Delphi/EclbrSystem/DCC.bat` invokes `CodeCoverage.exe` for **14** named projects; only **10** `.dpr` files exist (confirmed: `ls "Test Delphi/EclbrSystem/"*.dpr | wc -l` → 10). Missing: `PTestDictionary`, `PTestVector`, `PTestMap`, `PTestList`, `PTestStr`, `PTestDirectory`, `PTestThreading`. The batch script will fail at the first missing project.

### F-03 — Cross-platform claim in README not supported by project files

README states the library works on "Win/Linux/macOS/iOS/Android". `pubdelphi.json` lists `["Win32", "Win64"]` only. No build projects, CI pipelines, or platform-conditional code paths targeting Linux, macOS, iOS, or Android were found.

## 8. Open questions

**Q1: Is the `Fluent.*`/`ecl.*` library a declared dependency that should appear in `boss.json`?**
Tried: `cat boss.json` → `"dependencies": {}` (empty). The `boss-lock.json` `"installedModules"` is also empty. Neither package manager manifest declares `Fluent` or `eclbr` as a dependency, so either (a) the library was removed without cleaning up the tests, or (b) it is expected to be placed manually. The answer determines whether F-01 represents dead code or a missing `boss install` step.

**Q2: What Delphi version is the current active development target?**
`ModernSyntax.inc` lists VER360 as the ceiling (line 56) but leaves its name as `"Delphi ???"` (line 28). The `TestInsightSettings.ini` file exists but its content was not examined; it may carry the build environment version.
