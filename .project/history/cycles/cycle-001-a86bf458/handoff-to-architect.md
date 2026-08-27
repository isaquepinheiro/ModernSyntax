---
type: handoff
kind: artifact
title: "Handoff to architect — ModernSyntax cycle-001"
description: "Executive summary, must-know decisions, section-file pointers, and the five open questions requiring author input before architectural work can proceed."
cycle: cycle-001-a86bf458
agent: analyst
workflow: analyst-existing-project
node: synthesis
resource: aefos://run/a86bf45888f6ba01995864dedfeb1f9c
generated:
  by: "analyst-existing-project@node:synthesis"
  at: "2026-08-27T00:00:00Z"
tags:
  - cycle-001
  - analyst
  - handoff
---

# Handoff to Architect — ModernSyntax

## Executive summary

**ModernSyntax** is a zero-dependency Delphi library that brings functional-programming
idioms (pattern matching, Railway error handling, option types, currying, async/await,
cooperative coroutines) to Object Pascal. Its 16 source units total 10,766 lines;
it is distributed as source (no compiled output). The library has no server runtime, no
external integrations, and no persisted entities — the only actor is the Delphi developer
consuming it.

The library's foundation is structurally sound: the intra-library dependency graph is a
clean DAG with no cycles; the records-for-API / classes-for-state pattern is applied
consistently; generics and anonymous methods are used throughout. The critical engineering
issues are in the concurrency layer: two unguarded shared-state defects (TD-01, TD-02)
are reachable from the library's own async/coroutine machinery and will produce data races
under concurrent use. The published platform list (Win32/Win64) contradicts the README's
cross-platform claims, and two units will not compile on any non-Windows target without
guard changes. Five open questions require author intent before architectural decisions
can be finalised.

**Overall health:** structurally clean; concurrency layer has correctness defects;
test tooling is partially broken; no CI exists.

---

## Must-know decisions

These are measured facts — each carries a citation. They are architectural inputs, not
opinions.

**1. The effective minimum Delphi version is XE7, not 2010.**
`System.Threading` (`ITask`/`TTask`) is used unconditionally in `Async.pas:25` and
`Coroutine.pas:24`. `System.Threading` requires Delphi XE7. Anonymous methods (329 uses)
require Delphi 2009+. The `ModernSyntax.inc` VER210 block is a false floor.

**2. Two concurrency defects are reachable in normal library use.**
- `TArrow.FValue: TValue` (class var, `ArrowFun.pas:39`) is written by every `Fn`/`Result`
  overload with zero synchronization (`grep -n "Critical\|Lock\|Interlocked" Source/ModernSyntax.ArrowFun.pas` → 0). Concurrent `TTask` closures (via `TAsync` or `TCoroutine`) produce a data race.
- `TStd.FSequenceCounter: Int64` (`Std.pas:41`) is incremented by `Inc` (`Std.pas:58`) — not
  `TInterlocked.Increment`. Non-atomic on Win32; duplicate values under concurrency on all targets.

**3. The library is Win32/Win64-only today; `pubdelphi.json:7` confirms this.**
`ModernSyntax.DotEnv.pas:21` and `ModernSyntax.Std.pas:67` import `Windows` unconditionally.
Any non-Windows build fails at compile time before any `{$IFDEF}` fires.

**4. The FMX/VCL switch (`ModernSyntax.inc:46–52`) is fully inert.**
`grep -rn "HAS_VCL\|HAS_FMX" Source/*.pas` → no output. No production unit reads either
symbol. Enabling FMX mode currently produces zero compile-time difference.

**5. 8 test units cannot compile; `DCC.bat` is broken.**
`UTestEcl.*.pas` import `Fluent.Core`, `Fluent.Collections`, `ecl.ifthen` — absent from
all manifests and from `Source/`. `DCC.bat` references 14 test projects; only 10 `.dpr`
files exist. Coverage tooling does not work as shipped.

**6. 4 library modules have no test project.**
`ModernSyntax.Coroutine`, `ModernSyntax.Crypt`, `ModernSyntax.RegExpression`,
`ModernSyntax.ArrowFun` — none has a `.dpr` in `Test Delphi/EclbrSystem/`.
`ArrowFun` and `Coroutine` are the two highest-risk untested modules.

**7. The library's internal dependency graph is a clean DAG.**
No circular imports. `ModernSyntax.pas` is the hub (5 importers); `ResultPair` and `Std`
are secondary hubs (2 and 3 importers). Adding imports upstream of the hub creates coupling risk.

**8. `TResultPair.FSuccessFuncs`/`FFailureFuncs` are actively used (not vestigial).**
Write sites at `ResultPair.pas:763–764, 927–928`; read sites at lines 638–640, 659–661.
They implement a multi-callback accumulation mechanism for chaining methods. Any refactor of
`TResultPair` must account for these arrays.

---

## Section files

All detail lives in `.project/analysis/`. Read in dependency order for maximum context:

| File | What it covers |
|---|---|
| [00-intake](/analysis/00-intake.md) | Project identity, 16-unit inventory, initial findings and priority order |
| [01-structure](/analysis/01-structure.md) | Folder tree, all 17 source files measured, 11 test projects, 20 test units, build/test mechanics, findings |
| [02-stack](/analysis/02-stack.md) | Compiler range, RTL units consumed, package managers, UI framework switch, test toolchain |
| [03-architecture](/analysis/03-architecture.md) | 16-unit dependency graph, primary data/control flows, key abstractions, 6 cross-cutting concerns |
| [04-domain](/analysis/04-domain.md) | 18 entity definitions with fields and API counts, entity relationship map, 9 business rules, 10 use cases |
| [05-conventions](/analysis/05-conventions.md) | Naming prefixes (all measured), code layout, error handling, testing style, 6 recurring patterns, 7 ADR candidates |
| [06-gaps-and-risks](/analysis/06-gaps-and-risks.md) | 5 resolved questions, 12 risk hotspots, 4 assumptions, 5 surviving open questions, 18-item tech-debt register |

The consolidated dossier is [project-overview.md](project-overview.md) (this directory).

---

## Open questions — require author input

These five questions survived investigation attempts. They are listed in priority order
(highest-severity first). The architect cannot fully close the corresponding design
decisions without author intent.

**OQ-01 — Is `TArrow` a single-threaded-only type, or should `FValue` become an instance field?**
Severity: **High.**
The `class var FValue: TValue` design is confirmed deliberate (`ArrowFun.pas:39` comment).
The thread-safety hazard follows unavoidably from that design when `TArrow` is used inside
async closures. The architect needs to know: (a) "TArrow is documented single-threaded only —
document it and add a warning," or (b) "redesign `TArrow` to carry instance state."

**OQ-03 — What is the declared minimum Delphi version for new contributions?**
Severity: **Medium.**
The `.inc` header says 2010 (VER210); the code compiles only on XE7+ (`System.Threading`)
and practically targets Delphi 12 (`.dproj` files). The architect needs a single stated
minimum to determine which RTL features are safe to use and which VER blocks in `.inc`
can be removed.

**OQ-04 — Should the 8 orphaned `UTestEcl.*` test units be deleted or restored?**
Severity: **Medium.**
`boss.json` `"dependencies": {}` — `eclbr`/`fluent` are not declared dependencies.
Options: (a) delete the 8 units and remove their stubs from `DCC.bat`; (b) re-add
the dependency. The architect needs this resolved before recommending test infrastructure work.

**OQ-05 — Is FMX support a near-term deliverable or an aspirational future item?**
Severity: **Low** (but gates cross-platform work).
`HAS_VCL`/`HAS_FMX` are defined but consumed nowhere. If FMX is real intent, each unit
with UI-path dependencies must add `{$IFDEF HAS_FMX}` guards. If it is aspirational only,
the inert define and README claim should be corrected.

**OQ-02 — Is `IMSObserver` an extension point for consumers, or dead code to remove?**
Severity: **Low.**
`grep -rn "IMSObserver" .` → one hit, the declaration. No test, no example, no ADR
references it. The architect needs to know whether to design a new observable abstraction
around it or delete it.
