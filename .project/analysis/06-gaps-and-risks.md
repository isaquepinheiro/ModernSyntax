---
type: analysis
kind: artifact
title: "06-gaps-and-risks: ModernSyntax — open questions, assumptions, tech-debt hotspots"
description: "Architect-ready dossier of surviving open questions, verified assumptions, risk hotspots, and drift findings across the full ModernSyntax analysis cycle."
status: stable
generated:
  by: "analyst-discovery@node:gaps"
  at: "2026-08-27T00:00:00Z"
tags:
  - gaps
  - risks
  - analyst
  - discovery
sources:
  - id: intake
    resource: /analysis/00-intake.md
    title: "00-intake: ModernSyntax shallow-pass"
  - id: structure
    resource: /analysis/01-structure.md
    title: "01-structure: folder tree, entry points, build/run/test/lint"
  - id: stack
    resource: /analysis/02-stack.md
    title: "02-stack: dependency manifest and runtime stack"
  - id: architecture
    resource: /analysis/03-architecture.md
    title: "03-architecture: module map, flows, abstractions"
  - id: domain
    resource: /analysis/04-domain.md
    title: "04-domain: entities, relationships, business rules, use cases"
  - id: conventions
    resource: /analysis/05-conventions.md
    title: "05-conventions: naming, layout, error handling, testing, patterns"
---

# Gaps and Risks — ModernSyntax

All numbers below derive from commands run in this cycle. Every claim cites
the command that produced it or the `file:line` where it was confirmed.

---

## Answered while looking

These were open questions in prior documents. A command closed each one;
they are not repeated in the open-question list.

**A-01 — FSuccessFuncs / FFailureFuncs in TResultPair ARE actively populated.**
Prior question (04-domain §7 Q1): "only declaration lines found."
Resolved: `grep -n "FSuccessFuncs\|FFailureFuncs" Source/ModernSyntax.ResultPair.pas`
— write sites at lines 763–764 (`SetLength(Result.FSuccessFuncs, …); Result.FSuccessFuncs[…] := AFunc;`)
and lines 927–928 (same pattern for `FFailureFuncs`).
Read sites iterate them at lines 638–640 and 659–661.
These arrays implement a multi-callback accumulation mechanism used by chaining
methods (likely `ThenOf`/`ExceptOf`). Not vestigial.

**A-02 — TModernStreamReader does NOT use System.Threading in its body.**
Prior question (03-architecture §8 Q1): "import may be leftover."
Resolved: `grep -n "TTask\|ITask\|TThread\|FTask" Source/ModernSyntax.Stream.pas` → no output.
`System.Threading` is imported at `Stream.pas:23` but no call site was found anywhere in
the unit. The import is a leftover; the unit runs entirely synchronously.

**A-03 — TArrow.FValue is intentionally a class var, per its own comment.**
Prior question (03-architecture §8 Q2): "design rationale absent from code comments."
Resolved: `grep -n "class var.*FValue" Source/ModernSyntax.ArrowFun.pas`
— `ArrowFun.pas:39`: `class var FValue: TValue; // Internal storage for the last processed value`.
The comment states intent. The thread-safety hazard (finding R-01 below) is real and unmitigated,
but the singleton design is deliberate per the author's comment.

**A-04 — HAS_VCL / HAS_FMX defines are consumed nowhere in Source/ .pas files.**
Prior question (02-stack §2): "switch is declared but currently inert."
Resolved: `grep -rn "HAS_VCL\|HAS_FMX" Source/` — only two hits, both in
`ModernSyntax.inc:50,52` (the definitions). No `.pas` unit reads either symbol.
The FMX/VCL switch sets a define that no production code consults; it is fully inert.

**A-05 — boss.json / boss-lock.json confirm Fluent.* / ecl.* is NOT a declared dependency.**
Prior question (01-structure §8 Q1): "removed or expected to be placed manually?"
Resolved: `cat boss.json` → `"dependencies": {}`; `boss-lock.json` `"installedModules": {}`.
Neither package manager manifest names `Fluent` or `eclbr`. The 8 test units that import
`Fluent.*` / `ecl.*` are orphaned: their dependency was removed without cleaning up the units.

---

## Risk hotspots (file : area)

Severity scale: **High** = correctness or build-breaking in realistic use;
**Medium** = maintainability or reliability gap that will compound;
**Low** = quality / consistency debt.

### R-01 — Unguarded class-level mutable state in TArrow `[High]`

`TArrow.FValue: TValue` is a process-global slot written by every `Fn` and `Result`
overload before the closure captures the value:

```pascal
class function TArrow.Fn(const AValue: TValue): TProc;
begin
  Result := procedure begin FValue := AValue; … end;   // ArrowFun.pas:98
end;
```

Two concurrent tasks calling `TArrow.Fn` will interleave writes to `FValue` with no
`TCriticalSection` or `TInterlocked` guard (`grep -n "Critical\|Lock\|Interlocked" Source/ModernSyntax.ArrowFun.pas` → 0 results).
The library's `TAsync` and `TCoroutine` both dispatch closures to `TTask` threads, so the
race is reachable in normal use. The comment at `ArrowFun.pas:39` confirms the design is
intentional; the race is a consequence of that choice, not an implementation oversight.

**Location:** `Source/ModernSyntax.ArrowFun.pas` — `TArrow` class var / all `Fn`/`Result` overloads.

### R-02 — Non-atomic sequence counter in TStd `[High]`

`TStd.FSequenceCounter: Int64` (Std.pas:41) is incremented by standard `Inc` in
`GenerateSequentialNumber` (Std.pas:58). `Inc` on a 64-bit value is not atomic on 32-bit
targets and not protected on any target:
`grep -n "FSequenceCounter\|TInterlocked\|Increment" Source/ModernSyntax.Std.pas` — only
the declaration at line 41 and the `Inc` call at line 58; no interlocked wrapper.
Concurrent callers can produce duplicate sequence numbers.

**Location:** `Source/ModernSyntax.Std.pas:41,58` — `TStd.GenerateSequentialNumber`.

### R-03 — Windows API imported unconditionally in two units `[High]`

`Source/ModernSyntax.DotEnv.pas:21` — `uses … Windows` (no guard).
Calls: `GetEnvironmentVariable` (lines 373, 400, 415, 420), `SetEnvironmentVariable` (line 427).

`Source/ModernSyntax.Std.pas:67` — `uses … Windows` (no guard).
Call: `OutputDebugString` at `Std.pas:80`, inside `{$IFDEF DEBUG}`. The `{$IFDEF}` guards the
call body but not the `uses` clause; on a non-Windows compiler the unit fails to compile before
the ifdef fires.

`pubdelphi.json:7` declares `["Win32","Win64"]` only, so these units are currently safe for
the published platform set. Risk materialises if cross-platform work begins — any non-Windows
target breaks both units at compile time, not at runtime.

**Location:** `Source/ModernSyntax.DotEnv.pas:21` and `Source/ModernSyntax.Std.pas:67`.

### R-04 — FPC/Lazarus: não existe build; `{$IFDEF FCP}` é bloco morto `[Low — informacional]`

A demanda afirmou que a biblioteca "roda em Delphi e em Lazarus/FPC". O código contradiz.
`Source/ModernSyntax.inc:255–258` contém um bloco com comment `//Lazarus` e guarda
`{$IFDEF FCP}`. `FCP` é typo para `FPC` — o símbolo que FPC/Lazarus efetivamente define;
esse bloco nunca foi compilado. A tabela de versões do `.inc` (`:27–44`) lista apenas
compiladores Delphi; `README.md:3` declara "Delphi XE or superior" — sem menção a FPC/Lazarus.
**Não existe build FPC/Lazarus desta biblioteca. Não é defeito no build atual.**

**Nota para escopo futuro (não é risco presente):** `ModernSyntax.Async.pas:25` e
`ModernSyntax.Coroutine.pas:24` importam `Threading` (`System.Threading`, `ITask`/`TTask`)
sem guarda condicional. `System.Threading` não tem equivalente padrão em FPC. Um eventual
porte FPC exigiria estratégia de compilação condicional nesses dois units — trabalho
não-trivial se pedido. Esta é informação de escopo futuro, não um defeito a corrigir.

**Location:** `Source/ModernSyntax.inc:255–258` (bloco morto); `Source/ModernSyntax.Async.pas:25`;
`Source/ModernSyntax.Coroutine.pas:24` (nota de porte futuro).

### R-05 — Orphaned test units and broken coverage script `[Medium]`

**Orphaned test units (8):** `UTestEcl.Dictionary.pas`, `UTestEcl.List.pas`,
`UTestEcl.Map.pas`, `UTestEcl.Vector.pas`, `UTestEcl.Str.pas`, `UTestEcl.Directory.pas`,
`UTestEclbr.IfThen.pas` import `Fluent.Core`, `Fluent.Collections`, `ecl.ifthen` —
none of which exist in `Source/` (confirmed: `ls Source/` shows only `ModernSyntax.*`).
These units cannot compile. They are counted in `ls "Test Delphi/EclbrSystem/"*.pas | wc -l` → 18
but inflate the apparent test-unit count; they contribute zero working tests.

**Broken coverage script:** `Test Delphi/EclbrSystem/DCC.bat` references 14 named test
projects; `ls "Test Delphi/EclbrSystem/"*.dpr | wc -l` → 10 `.dpr` files exist. The 4
missing are `PTestDictionary`, `PTestVector`, `PTestMap`, `PTestList`, `PTestStr`,
`PTestDirectory`, `PTestThreading`. The script fails at the first missing project.

**Location:** `Test Delphi/EclbrSystem/UTestEcl.*.pas`; `Test Delphi/EclbrSystem/DCC.bat`.

### R-06 — Four library modules have no test project `[Medium]`

`ls "Test Delphi/EclbrSystem/"*.dpr` (10 projects) covers:
Async, Currying, DotEnv, Match, Objects, Option, SafeTry, Std, Stream, Tuple.
ResultPair is covered by `Test Delphi/EclbrResultPair/PTestResultPair.dpr`.

Modules with **no test project found**:
`ModernSyntax.Coroutine`, `ModernSyntax.Crypt`, `ModernSyntax.RegExpression`,
`ModernSyntax.ArrowFun`.

These four include two of the highest-risk units: `ArrowFun` (thread-safety, R-01) and
`Coroutine` (cooperative scheduler, lifecycle management).

**Location:** `Test Delphi/EclbrSystem/` — absent: `PTestCoroutine.dpr`, `PTestCrypt.dpr`,
`PTestRegExpression.dpr`, `PTestArrowFun.dpr`.

### R-07 — No CI pipeline; all quality gates are manual `[Medium]`

`find . -name "*.yml" -not -path "./.git/*" -not -path "./.aefos-studio/*"` → no
project-owned CI configuration. The group project `TestMSGroup.groupproj` exists but is
IDE-only. `DCC.bat` is a post-test manual script. There is no automated build, test run,
or lint check on commit or PR.

**Location:** repository root — no `.github/workflows/`, no Makefile, no CI descriptor.

### R-08 — HAS_VCL / HAS_FMX switch is fully inert `[Medium]`

`ModernSyntax.inc:46` defines `{.$DEFINE FMX}` (commented out → VCL mode).
`ModernSyntax.inc:50,52` then defines `HAS_FMX` or `HAS_VCL` accordingly.
`grep -rn "HAS_VCL\|HAS_FMX" Source/*.pas` → no output.
No source unit reads either symbol. The FMX/VCL conditional exists in the include
but has never been wired into any `.pas` unit. FMX support, while mentioned in the README
and available via the define, provides zero compile-time difference today.

**Location:** `Source/ModernSyntax.inc:46–52` vs all 16 `.pas` units.

### R-09 — Unused import: System.Threading in Stream `[Low]`

`grep -n "TTask\|ITask\|TThread" Source/ModernSyntax.Stream.pas` → no output.
`System.Threading` appears at `Stream.pas:23` but is never called. Dead import;
harmless but misleading (implies concurrent stream processing that does not exist).

**Location:** `Source/ModernSyntax.Stream.pas:23`.

### R-10 — IMSObserver interface is declared but never used `[Low]`

`grep -rn "IMSObserver" Source/*.pas` → one hit: the declaration at `ModernSyntax.pas:27`.
No unit in `Source/` implements or calls it. Two observable types exist
(`TCoroutine`, `TModernStreamReader`) but both define their own ad-hoc callback types,
incompatible with `IMSObserver`. Dead interface surface in the foundation unit.

**Location:** `Source/ModernSyntax.pas:27`.

### R-11 — 35 bare Exception.Create raises across 11 units `[Low]`

`grep -rn "raise Exception\b" Source/*.pas | wc -l` → 35 calls.
Only `ModernSyntax.ResultPair.pas` defines typed exceptions (3, at lines 27, 31, 35).
Callers cannot catch ModernSyntax errors by type without catching every other Delphi exception.

**Location:** hotspots are `ModernSyntax.Objects.pas` (7 raises),
`ModernSyntax.DotEnv.pas` (5), `ModernSyntax.Coroutine.pas` (4).

### R-12 — Commented-out code without annotation `[Low]`

`grep -rn "^\s*//" Source/ModernSyntax.ArrowFun.pas | wc -l` → 88 lines.
`grep -rn "^\s*//" Source/ModernSyntax.Objects.pas | grep -c "raise\|procedure\|function\|:=\|begin\|end;"` → 47 code lines.
No `TODO`/`FIXME`/`HACK` marker: `grep -rn "TODO\|FIXME\|HACK\|XXX" Source/*.pas` → 0 results.
Dead code is left in place with no tracking reference.

**Location:** `Source/ModernSyntax.ArrowFun.pas:66–72, 133–144, 271–279`;
`Source/ModernSyntax.Objects.pas:532, 565–568`.

---

## Assumptions made during analysis

**AS-01** — `Threading` (bare unit name) in `Async.pas:25` and `Coroutine.pas:24` resolves to
`System.Threading` under Delphi's default namespace search list (`System;…`). Confirmed
indirectly: `find . -name "Threading.pas" -not -path "./.git/*"` → no local override.
No compiler run was performed; the assumption is high-confidence for Delphi. FPC/Lazarus
is not in scope — no FPC build of this library exists (see R-04).

**AS-02** — The active development IDE is Delphi 12. Evidence: `Delphi.Personality.12` token
in `Examples/CurryingDemo.dproj` and sampled test `.dproj` files. The `TestInsight` ini
(`BaseUrl=http://DESKTOP-ISAQUEP:8102`) carries only the hostname — no version signal.
Delphi 12 is assumed as the minimum viable target for new contributions; the code supports
back to Delphi 2010 (VER210) via `ModernSyntax.inc`.

**AS-03** — `TResultPair.FSuccessFuncs` and `FFailureFuncs` are populated by the chaining
methods whose implementation bodies include `SetLength(Result.FSuccessFuncs, …)` at
`ResultPair.pas:763–764` and `927–928`. The exact public method names were not confirmed
(the lines lie inside larger method bodies); their identity is an assumption. They are
consumed at lines 638–640 and 659–661.

**AS-04** — The `libFastMM_FullDebugMode.dylib` present in `Test Delphi/EclbrSystem/` is a
macOS FastMM debug helper. Its presence does not imply active macOS CI; no macOS build
project or CI job was found. Assumed to be a historical artefact.

---

## Open questions (survived investigation attempts)

Each entry states what was tried and why it remains open.

**OQ-01 — Should TArrow be redesigned as an instance type?**

Severity: **High**. The `class var FValue` design is confirmed intentional
(`ArrowFun.pas:39` comment). The thread-safety hazard (R-01) follows directly. The
question is whether the author accepts this as a known limitation (TArrow is for
single-threaded use only) or whether the type should carry an instance field instead.
*Tried:* searched for any thread guard or `{$IFDEF SINGLETHREADED}` in `ArrowFun.pas`
— none found. *Needs:* product-intent decision from author.

**OQ-02 — Is IMSObserver an extension point for consumers or dead code to remove?**

Severity: **Low**. `grep -rn "IMSObserver" .` (excluding `.project/`) → zero hits outside
`ModernSyntax.pas:27`. No test, no example, no TODO references it. *Tried:* looked for ADR
or comment near the declaration — none. Two observable types exist but use incompatible
ad-hoc callbacks. *Needs:* author intent — "designed for user implementation" vs "remove."

**OQ-03 — What is the minimum Delphi version for new contributions?**

Severity: **Medium**. `ModernSyntax.inc` declares support from Delphi 2010 (VER210).
`.dproj` files carry `Delphi.Personality.12`. Anonymous methods (used in 329 places,
`grep -rn "reference to function\|reference to procedure\|TFunc<\|TProc<" Source/*.pas | wc -l` → 329)
require Delphi 2009+; `System.Threading` (ITask/TTask) requires Delphi XE7+; RTTI
`TRttiContext` requires Delphi 2010. The effective minimum is XE7, not 2010. The `.inc`
header claims 2010 support, but the code cannot compile against it.
*Tried:* `grep -n "DELPHI14_UP\|DELPHI.*_UP" Source/*.pas | grep -v ".inc"` — no
version-conditional guards on Threading or anonymous-method constructs. *Needs:* author
to declare the true minimum; the VER210 block in the `.inc` should be audited or removed.

**OQ-04 — Are the Fluent.*/ecl.* orphaned test units expected to return?**

Severity: **Medium** (affects test-count accuracy and CI if adopted). `boss.json`
`"dependencies": {}` (confirmed). The 8 units import a library absent from all manifests.
*Tried:* checked boss, boss-lock, pubdelphi — no trace. *Options:* (a) delete the 8 units
and the corresponding 4 removed `.dpr` stubs from `DCC.bat`; (b) add `eclbr`/`fluent`
as a Boss dependency. *Needs:* author decision on whether this library is returning.

**OQ-05 — Is FMX support intended to be wired up in future, or permanently off?**

Severity: **Low** (product-direction question). `HAS_VCL`/`HAS_FMX` are defined in
`ModernSyntax.inc:50,52` but consumed nowhere in `Source/*.pas`. The switch fires and
produces a symbol that nobody reads. *Tried:* `grep -rn "HAS_VCL\|HAS_FMX" Source/*.pas`
→ no output. *Needs:* if FMX support is real intent, each unit that has UI-dependent
paths must add `{$IFDEF HAS_FMX}` guards. If not, the define can be removed to avoid confusion.

---

## Tech-debt register (prioritised)

| # | Area | Risk | Severity | File : line |
|---|---|---|---|---|
| TD-01 | Thread safety | TArrow class-var data race | High | `ArrowFun.pas:39,98,106,121` |
| TD-02 | Thread safety | Non-atomic TStd sequence counter | High | `Std.pas:41,58` |
| TD-03 | Platform | Windows API unconditional in DotEnv | High | `DotEnv.pas:21,373,400,415,420,427` |
| TD-04 | Platform | Windows API unconditional in Std | High | `Std.pas:67,80` |
| TD-05 | Platform | FPC/Lazarus: bloco morto (`FCP` typo); sem build FPC; `Threading` em Async/Coroutine exigiria condicional num porte futuro | Low | `ModernSyntax.inc:255–258`; `Async.pas:25`; `Coroutine.pas:24` |
| TD-06 | Testing | 4 modules with no test project (Coroutine,Crypt,RegExpression,ArrowFun) | Medium | `Test Delphi/EclbrSystem/` |
| TD-07 | Quality | No CI pipeline; all gates manual | Medium | repo root |
| TD-08 | Correctness | DCC.bat references 7 non-existent test projects | Medium | `Test Delphi/EclbrSystem/DCC.bat` |
| TD-09 | Correctness | 8 orphaned test units importing absent libraries | Medium | `Test Delphi/EclbrSystem/UTestEcl.*.pas` |
| TD-10 | Design | HAS_VCL/HAS_FMX switch inert — consumed nowhere | Medium | `ModernSyntax.inc:50,52` vs `Source/*.pas` |
| TD-11 | Design | IMSObserver declared but never implemented or used | Low | `ModernSyntax.pas:27` |
| TD-12 | Design | System.Threading unused import in Stream | Low | `Stream.pas:23` |
| TD-13 | Exception | 35 bare Exception.Create raises; no typed hierarchy | Low | 11 source units |
| TD-14 | Naming | isSuccess/isFailure lowercase breaks Is convention | Low | `ResultPair.pas:447,455` |
| TD-15 | Naming | Dual constant style: C_SCREAMING vs SCREAMING | Low | `Coroutine.pas:132`, `Match.pas:221` |
| TD-16 | Docs | 135 commented-out code lines without annotation | Low | `ArrowFun.pas:66–279`, `Objects.pas:532,565` |
| TD-17 | Docs | XML doc coverage uneven across 16 units | Low | `ArrowFun.pas`, `Crypt.pas`, `Stream.pas` |
| TD-18 | Licensing | .inc header cites LGPL; LICENSE file is MIT | Low | `ModernSyntax.inc:6–8`, `LICENSE:1` |
