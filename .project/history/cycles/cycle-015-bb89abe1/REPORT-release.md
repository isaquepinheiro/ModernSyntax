---
type: cycle-report
kind: report
title: "REPORT-release — cycle 015 (issue #42, TModernVisibility)"
description: "Cycle 015 delivered TModernVisibility enum, Method.Visibility type fix, and new Property.Visibility across both backends; all three quality lenses passed."
cycle: "015"
agent: release
workflow: equipe-feature
node: closing-record
resource: aefos://run/bb89abe1aa455add801745cb2a527e99
tags: [cycle-015, release, issue-42, tmodernvisibility, fpc, delphi]
generated:
  by: "equipe-feature@node:closing-record"
  at: "2026-09-01T00:00:00Z"
sources:
  - id: plan
    resource: "pipeline-plan.md"
    title: "PLAN — TModernVisibility em 3 slices sequenciais"
  - id: task
    resource: "pipeline-task.md"
    title: "TASK-015 — TModernVisibility completo nos dois compiladores"
  - id: review
    resource: "REPORT-quality-review.md"
    title: "Quality Review — cycle 015"
  - id: test
    resource: "REPORT-quality-test.md"
    title: "Quality Test — cycle 015"
  - id: verify
    resource: "REPORT-quality-verify.md"
    title: "Quality Verify — cycle 015"
---

# REPORT-release — Cycle 015

## What this cycle delivered

Cycle 015 closes [issue #42](https://github.com/isaquepinheiro/ModernSyntax/issues/42),
part of Epic #29.

**The problem:** `TMemberVisibility` (a Delphi RTTI internal type) was leaking
through the public interface of `TModernRTTIMethod.Visibility`, and
`TModernRTTIProperty.Visibility` did not exist at all.

**What changed, in prose:**

- A new public enum `TModernVisibility = (mvPrivate, mvProtected, mvPublic, mvPublished)`
  was declared in the shell (`ModernSyntax.RTTI.pas`) before `TModernRTTIField`,
  honouring convention D-25.1 (no `{$IFDEF}` in public type declarations).
- `TModernRTTIMethod.Visibility` now returns `TModernVisibility` instead of
  `TMemberVisibility`. No `TMemberVisibility` reference survives in executable
  code of the shell (CA-7 confirmed zero hits).
- `TModernRTTIProperty.Visibility` was added as a new public method, delegating
  to each backend.
- The Delphi backend (`ModernSyntax.RTTI.Delphi.pas`) received a rewritten
  `MethodVisibility` and a new `PropertyVisibility`, each with an explicit
  `case` of exactly four arms — no `mvAutomated`, no `else`-raise.
- The FPC backend (`ModernSyntax.RTTI.FPC.pas`) had `MethodVisibility` updated
  to match the new signature (still raises `EModernRTTIError`; `SFPCNoVisibility`
  rewritten per D-42.5), and a new `PropertyVisibility` with a `case` of four
  arms — `mvAutomated` deliberately absent (identifier does not exist in FPC 3.2.2).
- Three test scenarios were added to `UScenarios.RTTI.pas` (zero `{$IFDEF}`, per CA-5):
  FPC-only raise scenario, Delphi-only mvPublished scenario, and a cross-compiler
  property-visibility scenario (fixture uses `{$M+}` with a `published` property).
  Each scenario is published in the correct test shell.

## Work branch

- **Branch:** `aefos/cycle-bb89abe1-maestro-repo-isaquepinheiro-modernsyntax`
- **Base:** `main`

## Quality verdicts

| Lens | Verdict |
|------|---------|
| [Review](REPORT-quality-review.md) | **APPROVED** — all 10 acceptance criteria satisfied; mutation CA-9 verified |
| [Test](REPORT-quality-test.md) | **APPROVED** — FPC 3.2.2 x86_64 suite 30/30 (2 new tests); CA-9 revalidated |
| [Verify](REPORT-quality-verify.md) | **PASSED** — FPC compilation 0 errors; 30/30 tests green |

**Caveats (factory limitations, not implementation defects):** FPC i386 and
Delphi (`dcc32`) could not be tested in this factory. Author is responsible for
confirming those builds, as documented in the quality reports above.

## References

- [pipeline-plan.md](pipeline-plan.md) — three-slice delivery plan
- [pipeline-task.md](pipeline-task.md) — full acceptance checklist
- [REPORT-quality-review.md](REPORT-quality-review.md) — review verdict detail
- [REPORT-quality-test.md](REPORT-quality-test.md) — test verdict detail
- [REPORT-quality-verify.md](REPORT-quality-verify.md) — verify verdict detail
