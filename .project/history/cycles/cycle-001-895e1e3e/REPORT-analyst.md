---
type: cycle-report
kind: report
title: "Analyst Cycle-001 Report — ModernSyntax"
description: Discovery run report covering intake through gap analysis for the ModernSyntax Delphi functional-programming library.
cycle: cycle-001-895e1e3e
agent: analyst
workflow: analyst-existing-project
node: synthesis
resource: aefos://run/895e1e3e3cd5c3c50b9218ed2a0b398c
generated:
  by: analyst-existing-project@node:synthesis
  at: "2026-08-27T00:00:00Z"
tags: [cycle-001, analyst, modernsyntax, delphi, functional-programming]
---

# Analyst Cycle-001 Report — ModernSyntax

## Goal

Perform a full discovery pass on the ModernSyntax codebase and produce an
architect-ready dossier. The workflow covered intake, structure, stack,
architecture, domain, conventions, and gaps/risks — six numbered section
files plus this consolidated synthesis.

## What was done

Six section files were written under `.project/analysis/`:

| File | Scope |
|------|-------|
| [00-intake](/analysis/00-intake.md) | Project identity, primary stack, top-level tree, measured unit sizes, claims from README vs. code |
| [01-structure](/analysis/01-structure.md) | Folder tree, entry points (Boss/PubDelphi), test projects (11 runners), build / test / lint commands, platform targets |
| [02-stack](/analysis/02-stack.md) | Language/runtime, package managers, build system (.dproj / MSBuild), RTL unit dependency table, DUnitX test framework |
| [03-architecture](/analysis/03-architecture.md) | Module map with confirmed internal dependency edges, DAG graph, key abstractions, primary data/control flows, cross-cutting concerns |
| [04-domain](/analysis/04-domain.md) | Entities (19 public types), entity relationships, business rules (RN-001–RN-010), 12 use cases |
| [05-conventions](/analysis/05-conventions.md) | Naming conventions, error-handling idioms, test style (431 [Test] cases, 951 assertions), recurring patterns, quality gates, ADR candidates |
| [06-gaps-and-risks](/analysis/06-gaps-and-risks.md) | 15 findings (1 CRITICAL, 1 HIGH, 3 MEDIUM-HIGH, 4 MEDIUM, 6 LOW), 8 answered questions, 5 surviving open questions |

Every number stated in those files is grounded in a shell command, with the
command printed beside the number.

## What was produced

- [project-overview.md](project-overview.md) — consolidated architect dossier
- [handoff-to-architect.md](handoff-to-architect.md) — executive summary and handoff
- `/analysis/index.md` — refreshed directory index

## Findings summary

| Severity | Count | Top item |
|----------|-------|----------|
| CRITICAL | 1 | G-01: `TMatch.FMatch` class variable — unguarded shared state, data race under concurrent use |
| HIGH | 1 | G-02: `Windows` unconditional import in interface section of `Std` and `DotEnv`; 6/16 units blocked from non-Windows compilation |
| MEDIUM-HIGH | 3 | G-03 (unbounded memoize cache), G-04 (1 557 lines with no tests), G-05 (no CI) |
| MEDIUM | 4 | G-06 (rtNone undetectable), G-07 (three incompatible result carriers), G-08 (TAsync main-thread queue dependency), G-09 (Finally exception suppression) |
| LOW | 6 | G-10 through G-15 |

## Open questions for the architect

Five questions survived code-search attempts — see [handoff-to-architect.md](handoff-to-architect.md) §Open Questions and [06-gaps-and-risks](/analysis/06-gaps-and-risks.md) §Open Questions for the full "tried / why still open" breakdown. (OQ-6 on Lazarus/FPC was closed: the `{$IFDEF FCP}` block is dead code; FPC is not a supported target.)

## Decisions made during this pass

None requiring an ADR: all calls were methodological (measure-then-report, not
design-then-implement). The findings are observations, not recommendations
implemented as code.

## Risks to the architect

1. The G-01 thread race in `TMatch` requires a design decision before any
   multi-threaded consumer is built or recommended.
2. The cross-platform claim in README contradicts the measured code for 6 units;
   any roadmap item that targets Linux/macOS/iOS/Android must address G-02 first.
3. The three result-carrier types (G-07) impose a conversion burden on any
   consumer that combines Async + Match + SafeTry paths; consolidation is a
   breaking API change — the sooner it is decided, the cheaper it is.

## Handoff

See [handoff-to-architect.md](handoff-to-architect.md).
