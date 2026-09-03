---
type: cycle-report
kind: report
title: "Release Report — Cycle 027 / Issue #53 (GetFields de record)"
description: "Cycle 027 delivers TModernRTTIRecordType.GetFields (tipo + offset cross-compiler) across FPC and Delphi backends; all three quality lenses passed."
cycle: "027"
agent: release
workflow: equipe-feature
node: closing-record
resource: aefos://run/2fd5bdc50ab343e460eeca5becd7afbf
generated:
  by: "equipe-feature@node:closing-record"
  at: "2026-09-03T00:00:00Z"
tags: [release, rtti, record, get-fields, issue-53, cycle-027]
---

# Release Report — Cycle 027 / Issue #53

## What this cycle delivered

Cycle 027 implements `TModernRTTIRecordType.GetFields: TArray<TModernRTTIRecordField>`,
a new cross-compiler API that returns the fields of a Pascal `record` type, each
carrying its `PTypeInfo` handle and byte offset. The new value type
`TModernRTTIRecordField` (immutable; `FieldType` + `Offset` only; no `GetValue`/`SetValue`)
is introduced in the public unit `ModernSyntax.RTTI.pas`.

**Why the design is shaped the way it is:** The FPC backend reads
`TTypeData.TotalFieldCount` directly — not `RecInitData^.ManagedFieldCount`, which
would silently discard unmanaged fields in a mixed record (Q1, closed before implementation
began). It then walks the `PManagedField` array that immediately follows that field in
memory. The Delphi backend delegates to `TRttiRecordType.GetFields` inside a scoped
`TRttiContext` with `try/finally`. Both backends share the same public signature (D-2)
and call `RecordRaiseWrongKind` as their first statement (D-4).

The shared scenario `Scenario_RecordType_GetFields_TipoEOffset` exercises a four-field
mixed fixture (`TRecordFixture53`: `Integer`, `string`, `Double`, `string`) whose offsets
diverge between i386 and x86_64. Offsets are measured at runtime via pointer arithmetic
(`NativeInt(@R.X) - NativeInt(@R)`) rather than hardcoded literals, satisfying CA-5 and
D-53.5. Type identity is checked against `TypeInfo(...)` handles — not `.Name` strings —
avoiding the Delphi/FPC "Integer" vs. "LongInt" divergence (D-57.3).

`Name` is intentionally absent from `TModernRTTIRecordField`. It is deferred to a
child issue (to be opened by the author), conditioned on FPC ≥ 3.3 exposing field names
in the managed-field structure. The XMLDoc of `TModernRTTIRecordType` was rewritten to
cover all three public methods and reference the child issue.

## Work branch

- **Branch:** `aefos/cycle-2fd5bdc5-maestro-repo-isaquepinheiro-modernsyntax`
- **Base:** `main`

## Quality verdicts

| Lens | Verdict | Report |
|------|---------|--------|
| Review | **APPROVED** — all in-repo acceptance criteria met; no new banned patterns | [REPORT-quality-review.md](REPORT-quality-review.md) |
| Test | **APPROVED** — FPC 3.2.2 x86_64: 43/43 pass (up from 42); 8 expected pointer-cast warnings documented | [REPORT-quality-test.md](REPORT-quality-test.md) |
| Verify | **PASSED** — compile clean; 43/43; CCN manual ≤ 3 (lizard absent from factory) | [REPORT-quality-verify.md](REPORT-quality-verify.md) |

Non-factory targets (FPC i386, Delphi Win32/Win64) remain with the author per D-53.12
and SKILL.md.

## References

- [pipeline-plan.md](pipeline-plan.md)
- [pipeline-task.md](pipeline-task.md)
- [REPORT-developer.md](REPORT-developer.md)
- [REPORT-architect.md](REPORT-architect.md)
- [REPORT-planner.md](REPORT-planner.md)
