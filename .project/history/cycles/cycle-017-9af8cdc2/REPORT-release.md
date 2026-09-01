---
type: cycle-report
kind: report
title: "REPORT-release — cycle 017 (TModernRTTIPointerType, issue #44)"
description: "Closing record for cycle 017: TModernRTTIPointerType delivered across six files with FPC suite 36/36 green and all three quality gates approved."
cycle: "017"
agent: release
workflow: equipe-feature
node: closing-record
resource: aefos://run/9af8cdc2e2a54fb129b523e483beaa2d
tags: [cycle-017, issue-44, modernrtti, pointer, release, fpc, delphi]
generated:
  by: "equipe-feature@node:closing-record"
  at: "2026-09-01T00:00:00Z"
---

# REPORT-release — cycle 017

## What this cycle delivered

Cycle 017 implements `TModernRTTIPointerType` for issue #44, completing the
pointer-type surface of the ModernRTTI API. The record is declared in the public
shell (`Source/ModernSyntax.RTTI.pas`) with no new `{$IFDEF}` — honouring D-1
and D-25.1. The factory method `FromTypeInfo` accepts any `PTypeInfo` without
validating `Kind` (D-44.1). The public method `ReferredType` delegates to the
backend function `PointerTypeReferredType`, which carries the `Kind` guard and
raises `EModernRTTIError` with `SPointerWrongKind` on a bad token (D-4).

Two backends were delivered in parallel form:

- **FPC** (`Source/ModernSyntax.RTTI.FPC.pas`): uses the `RefType` _property_
  (not the raw `RefTypeRef` field), with `TRttiContext.Create` as a plain record
  value — no `try/finally .Free`. A mandatory mutation comment prescribes the
  `PTypeInfo(GetTypeData(P)^.RefTypeRef)` cast, pinpointing the ~24-byte
  mis-read that makes scenario 1 fail by semantics, not compile error.
- **Delphi** (`Source/ModernSyntax.RTTI.Delphi.pas`): symmetric signature (D-2),
  same `Kind` guard, `TRttiPointerType(LCtx.GetType(P)).ReferredType` inside
  `try/finally LCtx.Free`. No `is`-cast, no extra `try/except`.

Both backends received `resourcestring SPointerWrongKind` in their respective
local blocks, keeping the public unit free of new strings (D-1).

The shared scenario file (`Test Shared/EclbrSystem/UScenarios.RTTI.pas`) gained
the `PInt44 = ^Integer` fixture (not `PInteger`, to avoid collision with
`System`/`SysUtils`) and two shared procedures:
- `Scenario_PointerType_ReferredType_Matches` — asserts `IsNil = False` and
  `Name` matches `TModernRTTI.GetType(TypeInfo(Integer)).Name` (cross-compiler
  safe; no hardcoded literal — D-44.7 / B-44.2).
- `Scenario_PointerType_ReferredType_Nil_ForBarePointer` — asserts only
  `IsNil = True`; deliberately does not touch `.Name` to avoid the AV at
  `RTTI.pas:846` documented as issue #49 (out of scope this cycle).

Test shells in both `Test FPC/` and `Test Delphi/` received two thin procedures
each, delegating to the shared scenarios in a single line (one scenario, two
shells — CA-5 honoured, zero `{$IFDEF FPC}` in any shared file).

The mandatory mutation was executed: `RefType` → `PTypeInfo(GetTypeData(P)^.RefTypeRef)`
applied to the FPC backend, `/tmp/fpcbuild` cleared, suite rerun — scenario 1
turned red by semantics. After revert and rebuild, all 36 tests returned green.
Evidence is in [REPORT-developer.md](REPORT-developer.md).

## Work branch

- **Branch:** `aefos/cycle-9af8cdc2-maestro-repo-isaquepinheiro-modernsyntax`
- **Base:** `main`

## Quality gate verdicts

| Gate | Verdict |
|------|---------|
| verify | **PASSED** — FPC 3.2.2 x86_64: 3819 lines compiled, 0 errors, 36/36 tests green. See [REPORT-quality-verify.md](REPORT-quality-verify.md). |
| review | **APPROVED** — All 14 checklist items from ESP §4 satisfied; ADR D-44.1..D-44.9 honoured without deviation. See [REPORT-quality-review.md](REPORT-quality-review.md). |
| test | **APPROVED** — 16/16 acceptance criteria passed; two new pointer-type scenarios green. See [REPORT-quality-test.md](REPORT-quality-test.md). |

## Environmental limitations (non-blocking, declared in SKILL.md)

- `ppc386` absent in the factory container — i386 build not exercised this cycle.
- `dcc32`/`bcc32` absent — Delphi compilation attested by interlocutor report
  (run `7f780007e3179b6ac2dd4b2565795789`), not live this cycle. The PR body
  must state this provenance explicitly per the note in [REPORT-quality-review.md](REPORT-quality-review.md).

## Sources

- [REPORT-architect.md](REPORT-architect.md)
- [REPORT-planner.md](REPORT-planner.md)
- [REPORT-developer.md](REPORT-developer.md)
- [REPORT-quality-verify.md](REPORT-quality-verify.md)
- [REPORT-quality-review.md](REPORT-quality-review.md)
- [REPORT-quality-test.md](REPORT-quality-test.md)
- [pipeline-plan.md](pipeline-plan.md)
- [pipeline-task.md](pipeline-task.md)
