---
type: cycle-report
kind: report
title: "Analyst run report — ModernSyntax cycle-001"
description: "What the analyst did in cycle-001: goal, method, files produced, decisions, open questions, and handoff status."
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
  - report
---

# Analyst Run Report — cycle-001

## Goal

Produce a complete architect-ready discovery dossier for the **ModernSyntax** repository
— a Delphi functional-programming extension library — from a cold-start (no prior bundle
knowledge). The deliverable is a consolidated set of measured analysis files and three
cycle artefacts enabling the architect to proceed without re-reading source code.

## What was done

The run executed seven sequential analysis nodes:

| Node | Section file produced | Scope |
|---|---|---|
| `intake` | `00-intake.md` | Repository identity, 16-unit inventory, top-level findings, examination priority order |
| `structure` | `01-structure.md` | Folder tree, all 17 source files measured, 11 test projects, 20 test units, build/run/test/lint mechanics |
| `stack` | `02-stack.md` | Language, compiler range, UI framework switch, package managers (Boss + PubDelphi), RTL units consumed, test toolchain, external integrations |
| `architecture` | `03-architecture.md` | 16-unit dependency graph (uses-clause scan), primary data/control flows for Async/Coroutine/Match/Stream, key abstractions, 6 cross-cutting concerns |
| `domain` | `04-domain.md` | 18 entity definitions (primary types, fields, public API counts), entity relationship map, 3 actors, 9 confirmed business rules, 10 primary use cases, 4 domain-level findings |
| `conventions` | `05-conventions.md` | Naming prefixes (T/I/E/F/A/L/_), layout rules, documentation style, error handling (35 bare raises), testing (468 `[Test]` methods, 951 `Assert.` calls), 6 recurring patterns, 7 ADR candidates |
| `gaps` | `06-gaps-and-risks.md` | 5 questions answered during investigation, 12 risk hotspots (R-01–R-12), 4 assumptions, 5 surviving open questions, 18-item tech-debt register |

Every number in every section was produced by a command run against the source tree.
No claim was carried forward from README or doc comments without code confirmation.

## Findings resolved during the run

Five open questions raised in earlier nodes were closed before synthesis:

- **FSuccessFuncs / FFailureFuncs** in `TResultPair` — confirmed actively populated
  at `ResultPair.pas:763–764, 927–928`; consumed at lines 638–640, 659–661.
- **System.Threading import in Stream** — confirmed dead (`grep` found no call site);
  the unit runs synchronously.
- **TArrow.FValue singleton** — confirmed intentional by author comment at `ArrowFun.pas:39`;
  the thread-safety hazard is real and unmitigated, not an oversight.
- **HAS_VCL / HAS_FMX** — confirmed inert: the defines appear only in `ModernSyntax.inc`;
  no `.pas` unit reads either symbol.
- **Fluent.*/ecl.* dependency** — confirmed absent from all manifests; 8 test units
  are orphaned.

## Decisions made

**D-01** — Drift between document and code is recorded as a FINDING, not a constraint.
There are 18 items in the tech-debt register; none is elevated to a constraint because
none represents intentional behaviour that the architect must preserve.

**D-02** — The `.inc` copyright year (2016) vs `LICENSE` (2025–2026) is noted as a
stale-header issue (TD-18) but does not affect the governing license, which is MIT
(confirmed in `LICENSE:1` and `ModernSyntax.pas:9`).

**D-03** — The "VER210 support" claim in `ModernSyntax.inc` is recorded as declared intent
that the code does not honour: `System.Threading` (required by `Async` and `Coroutine`)
demands XE7 minimum; anonymous methods require Delphi 2009+. This is open question OQ-03
for the architect.

## Open questions handed to architect

Five questions survived investigation (see [project-overview.md](project-overview.md) §7 and
[handoff-to-architect.md](handoff-to-architect.md) for full detail):

| ID | Subject | Severity |
|---|---|---|
| OQ-01 | TArrow thread-safety: known limitation or redesign? | High |
| OQ-02 | IMSObserver: extension point or dead code? | Low |
| OQ-03 | True minimum Delphi version (inc says 2010; code needs XE7) | Medium |
| OQ-04 | Fluent.*/ecl.* orphaned tests: delete or restore? | Medium |
| OQ-05 | FMX support: future intent or remove the inert switch? | Low |

## Risks flagged

Three High-severity risks, four Medium-severity risks, and one Low informational note were measured:

- **R-01** `TArrow` — unguarded class-var data race reachable from TTask threads
- **R-02** `TStd.GenerateSequentialNumber` — non-atomic `Inc` on `Int64` counter
- **R-03** — `Windows` API imported unconditionally in `DotEnv` and `Std`
- **R-04** — FPC/Lazarus: bloco morto (`{$IFDEF FCP}` typo); não existe build FPC; `Threading` em Async/Coroutine exigiria condicional num eventual porte (Low, informacional — não é defeito presente)
- **R-05** — 8 orphaned test units + broken `DCC.bat` coverage script
- **R-06** — 4 modules (Coroutine, Crypt, RegExpression, ArrowFun) have no test project
- **R-07** — No CI pipeline

## Files produced

```
.project/analysis/
  00-intake.md         — intake: identity, 16-unit inventory, priorities
  01-structure.md      — structure: folder tree, build/test mechanics
  02-stack.md          — stack: compiler, RTL, tooling, integrations
  03-architecture.md   — architecture: dependency graph, flows, abstractions
  04-domain.md         — domain: entities, rules, use cases
  05-conventions.md    — conventions: naming, layout, testing, patterns
  06-gaps-and-risks.md — gaps: risks, assumptions, open questions, tech-debt
  index.md             — directory index (no frontmatter)

.project/history/cycles/cycle-001-a86bf458/
  REPORT-analyst.md         ← this file
  project-overview.md       — consolidated architect dossier
  handoff-to-architect.md   — executive summary + pointers
```

## Handoff status

**Complete.** The architect can proceed from [handoff-to-architect.md](handoff-to-architect.md)
and use [project-overview.md](project-overview.md) as the primary reference.
The five open questions above require product-intent input from the author before
architectural decisions on TArrow, IMSObserver, min Delphi version, orphaned tests,
and FMX wiring can be closed.
