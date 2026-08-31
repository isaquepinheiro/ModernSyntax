---
type: cycle-report
kind: report
title: "REPORT-release — cycle 009 (af5fcd28)"
description: "Cycle 009 delivers TModernRTTIMethod/TModernRTTIParameter via vmtMethodTable, §7 backend split, and ETestScenarioFailed surgery; all three quality gates passed."
cycle: "009"
agent: release
workflow: equipe-feature
node: closing-record
resource: aefos://run/af5fcd28da98e98892fbe66e544b6b5c
tags: [cycle-009, release, issue-25, issue-35, modernrtti, fpc, delphi]
generated:
  by: "equipe-feature@node:closing-record"
  at: "2026-08-31T00:00:00Z"
---

# REPORT-release — cycle 009 (af5fcd28)

## What this cycle delivered

Cycle 009 closes **issue #25** (`feat(rtti): TModernRTTIMethod pela vmtMethodTable`) and **issue #35** (cirurgia do `Fail` em `UScenarios.RTTI.pas`).

The work introduces `TModernRTTIMethod` (eight members) and `TModernRTTIParameter` (two members) behind a unified public API that carries zero `{$IFDEF}` in its type declarations. To achieve that, the cycle first performs the §7 architectural split: two new backend units (`ModernSyntax.RTTI.Delphi.pas` for Delphi's `System.Rtti`, `ModernSyntax.RTTI.FPC.pas` for `vmtMethodTable`/`MethodAddress`) absorb all compiler-specific logic, and the public shell `ModernSyntax.RTTI.pas` is left with a single `{$IFDEF FPC}` confined to the `uses` clause of its `implementation` section. `TModernRTTIField` is migrated to neutral fields plus `FromToken` as a prerequisite of that split.

On the FPC side, `MethodTokens` walks the inheritance chain via `ClassParent` and iterates entries with `LTab^.Entry[i]` — no pointer arithmetic. Six members that have no FPC source (`IsConstructor`, `IsClassMethod`, `IsStatic`, `Visibility`, `ReturnType`, `GetParameters`) raise `EModernRTTIError` with an instructive message. `ParameterName` and `ParameterType` do the same.

For test integrity (#35), `UScenarios.RTTI.pas` now declares `ETestScenarioFailed = class(Exception)` and `Fail` raises it instead of a bare `Exception`, making CI exit codes reliable. Three shared scenarios (`Scenario_GetMethods_CountsPublishedInherited_Exact`, `Scenario_GetMethod_ByName_FindsInherited`, `Scenario_Method_Invoke_NoArgs`) exercise method enumeration through a fixture with inheritance (`TMethodBase` / `TMethodDerived`), with zero `Assert` and zero `{$IFDEF FPC}`. Three published tests were added to each runner (FPC and Delphi).

## Work branch

- **Branch:** `aefos/cycle-af5fcd28-maestro-repo-isaquepinheiro-modernsyntax`
- **Base:** `develop`

## Quality gate verdicts

| Gate | Verdict |
|------|---------|
| review | **APPROVED** — 17/17 ACs passed; 3 non-blocking observations; no critical issues. See [REPORT-quality-review.md](REPORT-quality-review.md). |
| test | **APPROVED** — FPC 3.2.2 x86_64: 8/8 green, exit 0; M1 mutation confirmed (exit 2). See [REPORT-quality-test.md](REPORT-quality-test.md). |
| verify | **PASSED** — 0 compilation errors; single `{$IFDEF FPC}` in `uses`/`implementation` confirmed by grep. See [REPORT-quality-verify.md](REPORT-quality-verify.md). |

## References

- [pipeline-plan.md](pipeline-plan.md)
- [pipeline-task.md](pipeline-task.md)
- [pipeline-esp.md](pipeline-esp.md)
- [pipeline-adr.md](pipeline-adr.md)
- [pipeline-implement-report.md](pipeline-implement-report.md)
- [REPORT-developer.md](REPORT-developer.md)
- [REPORT-quality-review.md](REPORT-quality-review.md)
- [REPORT-quality-test.md](REPORT-quality-test.md)
- [REPORT-quality-verify.md](REPORT-quality-verify.md)
