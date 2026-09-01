---
type: cycle-report
kind: report
title: "REPORT-release — cycle 013 — TModernRTTIContext (issue #28)"
description: "Release closing record: TModernRTTIContext public API delivered on branch aefos/cycle-5a8dfb58-maestro-repo-isaquepinheiro-modernsyntax; all three quality lenses passed."
cycle: "013"
agent: release
workflow: equipe-feature
node: closing-record
resource: aefos://run/5a8dfb58a24f74263fa58fa581f465c4
status: stable
tags: [cycle-013, release, issue-28, modernrtti, fpc, delphi, context]
generated:
  by: "equipe-feature@node:closing-record"
  at: "2026-09-01T00:00:00Z"
---

# Release record — cycle 013 (issue #28)

## What this cycle delivered

Cycle 013 introduced the public `TModernRTTIContext` API to ModernSyntax.RTTI,
resolving issue #28. The delivery covers three tightly ordered slices:

**Public surface.** `TModernRTTIContext` is now declared in the `interface`
section of `ModernSyntax.RTTI.pas` with seven public members (`Create`, `Free`,
`GetType` ×2, `RegisterType`, `GetTypes`, `FindType`). `IModernRTTIContextToken`
(GUID `{9D4E0C7C-2F0D-4E0A-9C7A-2D5F1A028E13}`, no public members) is the
opaque lifetime handle. `TModernRTTIType.IsNil` was added as a nil predicate.
`GetPackages` is intentionally absent; XMLDoc explains the reason.

**Backend parity.** Both the FPC and Delphi backends expose the same five
`Context*` free functions (`ContextCreate`, `ContextFree`, `ContextGetType`,
`ContextGetTypes`, `ContextFindType`) with identical signatures. The FPC backend
uses a per-instance `TList`-backed registry; the Delphi backend delegates to the
native `TRttiContext`. `ContextGetTypes` on FPC raises `EModernRTTIError` when
the registry is empty. `ContextFindType` on FPC resolves `tkClass` only. The
single `{$IFDEF}` in `ModernSyntax.RTTI.pas` remains in the `uses` clause of
the `implementation` section.

**Test coverage.** Five new shared scenarios live in `UScenarios.RTTI.pas` with
zero `{$IFDEF FPC}` and no forbidden `Assert`/`AssertException` patterns. The
FPC shell exposes five `published` wrappers; the Delphi shell exposes four
`[Test]` methods (the empty-registry scenario is FPC-only because the Delphi
native pool cannot be emptied). PTestRTTI FPC x86_64 advanced from 23 to 28
passing tests.

## Work branch

- **Branch:** `aefos/cycle-5a8dfb58-maestro-repo-isaquepinheiro-modernsyntax`
- **Base:** `main`

## Quality verdicts

| Lens | Verdict |
|---|---|
| Review | **APPROVED** — all acceptance criteria met; one non-blocking XMLDoc imprecision noted (OBS-1) |
| Test | **APPROVED** — 28/28 FPC x86_64; five new Context scenarios green; mutation verified |
| Verify | **PASSED** — clean build, `{$IFDEF}` guardrail, backend parity, regression runners green |

## Caveats carried forward

Delphi (dcc32) and FPC i386 were not compiled in the factory (factory constraint).
The author must confirm both on first PR checkout. The XMLDoc imprecision in
`GetType(AClass: TClass)` on FPC (OBS-1 from review) is recommended for a
follow-up polish issue.

## Cross-references

- [REPORT-architect.md](REPORT-architect.md) — architecture rationale
- [REPORT-planner.md](REPORT-planner.md) — plan and slices
- [REPORT-developer.md](REPORT-developer.md) — implementation detail and mutation evidence
- [REPORT-quality-review.md](REPORT-quality-review.md) — review lens
- [REPORT-quality-test.md](REPORT-quality-test.md) — test lens
- [REPORT-quality-verify.md](REPORT-quality-verify.md) — verify lens
- [pipeline-esp.md](pipeline-esp.md) — acceptance criteria
- [pipeline-adr.md](pipeline-adr.md) — decisions D-28.1 through D-28.11
