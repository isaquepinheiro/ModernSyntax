---
type: analysis
title: "02-stack: ModernSyntax dependency manifest and runtime stack"
description: "Languages, runtimes, frameworks, RTL units, tooling, and external integrations measured from manifests and source."
status: stable
tags:
  - stack
  - analyst
  - discovery
generated:
  by: "analyst-discovery@node:stack"
  at: "2026-08-27T16:10:00Z"
sources:
  - id: intake
    resource: /analysis/00-intake.md
    title: "00-intake: ModernSyntax shallow-pass"
---

# ModernSyntax — Stack

## 1. Language and runtime

| Attribute | Value | Measured from |
|---|---|---|
| Language | Object Pascal (Delphi dialect) | `ls Source/*.pas \| wc -l` → 16 units; `ls Examples/*.dpr \| wc -l` → 2 programs |
| Compiler family | Embarcadero Delphi (RAD Studio) | `grep "Delphi.Personality" Examples/CurryingDemo.dproj` → `Delphi.Personality.12` |
| Project-file IDE version | Delphi 12 (personality token `Delphi.Personality.12`) | confirmed in all sampled `.dproj` files: `Examples/CurryingDemo.dproj`, `Test Delphi/EclbrSystem/PTestMatch.dproj` |
| Minimum supported compiler | Delphi 2010 (VER210 → symbol `DELPHI14_UP`) | `Source/ModernSyntax.inc` lines 228–231 — VER210 block is the lowest defined |
| Maximum declared compiler | Delphi 12 (VER360 → cumulative `DELPHI29_UP`) | `Source/ModernSyntax.inc` lines 56–87 — VER360 block is the highest |
| Also mentions Lazarus/FPC | **Não existe build FPC/Lazarus.** `{$IFDEF FCP}` em `ModernSyntax.inc:256` é bloco permanentemente morto — `FCP` é typo para `FPC` (símbolo que FPC/Lazarus define); o bloco nunca foi compilado. Demanda afirmou suporte FPC; o código contradiz. Tabela de versões do `.inc` (`:27–44`) lista apenas Delphi. | `Source/ModernSyntax.inc:255–258` (bloco morto); tabela `:27–44` |
| Declared output kind | `runtime` library (no executable entry point in Source) | `pubdelphi.json`:5 — `"kind": "runtime"` |
| Published target platforms | Win32, Win64 only | `pubdelphi.json`:7 — `"platforms": ["Win32", "Win64"]` |

> **Finding (drift):** README badges claim "VCL, FMX, Console (Win/Linux/macOS/iOS/Android)" — `README.md`:28.  
> The publish manifest restricts to Win32/Win64: `pubdelphi.json`:7.  
> Two source units call Windows-only API directly: `SetEnvironmentVariable`/`GetEnvironmentVariable` in `Source/ModernSyntax.DotEnv.pas`:408,415,420,427 and `OutputDebugString` in `Source/ModernSyntax.Std.pas`:80.  
> Cross-platform claim is INTENT, not code state; non-Windows platforms are unguarded in those two units.

---

## 2. UI framework switch

The library carries one conditional-compilation switch for the UI framework:

```pascal
{.$DEFINE FMX}     -- Source/ModernSyntax.inc:46 (commented out → inactive)
```

When `FMX` is NOT defined (the default), `HAS_VCL` is set (`Source/ModernSyntax.inc`:51).  
When `FMX` IS defined, `HAS_FMX` is set (`Source/ModernSyntax.inc`:48).

Neither define is consumed by any unit in `Source/` at the time of this analysis — no `{$IFDEF HAS_VCL}` or `{$IFDEF HAS_FMX}` block appears in `Source/*.pas` (confirmed: `grep -r "HAS_VCL\|HAS_FMX" Source/*.pas` → no output). The switch is declared but currently inert.

---

## 3. Package managers and registries

| Tool | Role | Manifest file | Lock file |
|---|---|---|---|
| **Boss** | Delphi dependency manager (open-source, HashLoad org) | `boss.json` | `boss-lock.json` |
| **PubDelphi** | Package-registry publisher (`pubdelphi.dev`) | `pubdelphi.json` | — |

### 3.1 Boss manifest (boss.json)

```
name: ModernSyntax
version: 1.0.0
mainsrc: ./Source
dependencies: {}     ← zero runtime dependencies declared
```

### 3.2 Boss lock (boss-lock.json)

```
installedModules: {}     ← zero modules installed
hash: d41d8cd98f00b204e9800998ecf8427e   (MD5 of empty string)
```

`installedModules` is empty: confirmed zero vendored dependencies.  
Command run: `cat boss-lock.json` — output shows `"installedModules": {}`.

Boss vendors into `modules/` (`.gitignore` excludes it: `modules/` on its own line). The directory does not exist: `find . -maxdepth 2 -name "modules" -type d` → no output.

### 3.3 PubDelphi manifest (pubdelphi.json)

```
dependencies: {}     ← zero registry dependencies
```

**Conclusion:** the library has **zero external dependencies** in all three manifests. It relies exclusively on the Delphi RTL.

---

## 4. Delphi RTL units consumed

Extracted by scanning `uses` clauses of all 16 source units (`awk '/^uses/,/;/' Source/*.pas | grep -oE '^ {2}[A-Za-z][A-Za-z0-9.]*' | tr -d ' ' | sort -u`):

| RTL unit | Concern | Used in |
|---|---|---|
| `Rtti` | Runtime type inspection (TValue, TRttiContext) | `ModernSyntax.pas`, `ModernSyntax.Async.pas`, `ModernSyntax.Coroutine.pas` |
| `SysUtils` | Strings, exceptions, date/time formatting | present in nearly every unit |
| `Classes` | TStream, TStringStream, TStreamReader | `ModernSyntax.Stream.pas`, `ModernSyntax.Async.pas`, `ModernSyntax.Coroutine.pas`, `ModernSyntax.Crypt.pas` |
| `SyncObjs` | TCriticalSection (thread synchronisation) | `ModernSyntax.Async.pas`, `ModernSyntax.Coroutine.pas` |
| `Threading` | ITask, TTask, thread pool | `ModernSyntax.Async.pas`:25, `ModernSyntax.Coroutine.pas`:24 |
| `Generics.Collections` | TDictionary, TList, TObjectList | `ModernSyntax.pas`, `ModernSyntax.Coroutine.pas`, `ModernSyntax.Tuple.pas` |
| `Generics.Defaults` | IEqualityComparer, TEqualityComparer | `ModernSyntax.pas` |
| `RegularExpressions` | TRegEx, TMatch, TRegExOptions | `ModernSyntax.RegExpression.pas` |
| `DateUtils` | Date arithmetic | `ModernSyntax.Coroutine.pas`, `ModernSyntax.Std.pas` |
| `Math` | Numeric helpers | `ModernSyntax.Std.pas` |
| `Variants` | Variant type support | `ModernSyntax.Tuple.pas` |
| `TypInfo` | RTTI type information (legacy) | `ModernSyntax.Match.pas` |
| `RTLConsts` | Shared RTL string constants | `ModernSyntax.Match.pas` |
| `Windows` | Win32 API: `SetEnvironmentVariable`, `GetEnvironmentVariable`, `OutputDebugString` | `ModernSyntax.DotEnv.pas`:408,415,420,427; `ModernSyntax.Std.pas`:80 |

All units above are part of the Delphi RTL/VCL standard library. No third-party Pascal unit is imported by any source file.

---

## 5. Test toolchain

| Tool | Role | Evidence |
|---|---|---|
| **DUnitX** | Unit test framework | `uses DUnitX.TestFramework` in every test unit sampled; `TDUnitX.RegisterTestFixture(...)` calls throughout `Test Delphi/**/*.pas` |
| **TestInsight** | IDE-integrated test runner | `Test Delphi/EclbrSystem/TestInsightSettings.ini` — `BaseUrl=http://DESKTOP-ISAQUEP:8102` (local dev machine) |
| **CodeCoverage** | Code-coverage reporting (external `.exe`) | `Test Delphi/EclbrSystem/DCC.bat` — calls `CodeCoverage.exe` with `-emma -xml -html` flags for 13 target projects |
| **FastMM** (partial) | Memory debugging dylib (macOS only) | `Test Delphi/EclbrSystem/libFastMM_FullDebugMode.dylib` present; no FastMM unit in `Source/` |

### 5.1 Test project count

```
find "Test Delphi" -name "*.dpr" | wc -l  →  11
find "Test Delphi" -name "U*.pas" | wc -l  →  20
```

11 test projects, 20 test unit files across two subdirectories (`EclbrSystem/`, `EclbrResultPair/`).

### 5.2 DUnitX version

DUnitX is referenced as a bare unit name (`DUnitX.TestFramework`) with no version qualifier. No standalone DUnitX package appears in `boss.json` or `boss-lock.json`. The version used is whatever ships with the installed Delphi 12 IDE — not pinned, not independently versioned.

---

## 6. Build system

| Artifact | Role |
|---|---|
| `*.dproj` | MSBuild-compatible project files (Embarcadero build system) |
| `*.dpr` | Delphi program/library root source file |
| `*.groupproj` | Multi-project group: `Test Delphi/EclbrSystem/TestMSGroup.groupproj` |
| `DCC.bat` | Manual batch script to invoke `CodeCoverage.exe` post-test |

No CI pipeline configuration file (GitHub Actions `.yml`, Jenkinsfile, etc.) exists in the repository. Command: `find . -name "*.yml" -not -path "./.git/*" -not -path "./.claude/*"` → no project-owned results. Builds are triggered manually via the IDE or `DCC.bat`.

---

## 7. External integrations

None at runtime. Confirmed by:
- `boss-lock.json` → `"installedModules": {}`
- `boss.json` → `"dependencies": {}`
- `pubdelphi.json` → `"dependencies": {}`
- No HTTP client, database driver, or third-party API client unit referenced in `Source/*.pas`

`pubdelphi.json` references `https://www.pubdelphi.dev/schema/pubdelphi.schema.json` — this is a tooling schema URL used at publish time, not a runtime integration.

---

## 8. Open questions

**Q1 — `Threading` unit name resolution.** Both `ModernSyntax.Async.pas`:25 and `ModernSyntax.Coroutine.pas`:24 import a bare unit named `Threading`. In Delphi's default namespace search list (`System;…` — confirmed in `.dproj` `DCC_Namespace` element), `Threading` resolves to `System.Threading`. Attempted to find a local override: `find . -name "Threading.pas" -not -path "./.git/*"` → no results. Assumed to be `System.Threading`; cannot confirm without a compiler run.

**Q2 — Lazarus/FPC: bloco morto, não gap de compatibilidade. FECHADO.** `Source/ModernSyntax.inc:255–258` contém `{$IFDEF FCP}` (comment `//Lazarus`). `FCP` é typo para `FPC` — o símbolo que FPC/Lazarus define; esse bloco nunca foi compilado. Não há drift entre intenção e código: a demanda afirmou suporte FPC; o código diz não. A leitura correta é: não existe build FPC/Lazarus desta biblioteca, e o bloco morto é um artefato documentado — não é trabalho a fazer. **Nota para escopo futuro:** `Async.pas:25` e `Coroutine.pas:24` importam `Threading` (`System.Threading`, `ITask`/`TTask`) sem guarda; `System.Threading` não tem equivalente padrão em FPC. Um eventual porte FPC exigiria estratégia de compilação condicional nesses dois units — trabalho não-trivial se algum dia pedido. Isso é informação de escopo futuro, não defeito presente.
