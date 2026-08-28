---
type: review-report
kind: artifact
title: "Review report — Callbacks transversais (ciclo 003)"
description: "Quality review of ModernSyntax.Callback unit and test scaffolding against ESP/ADR/plan; all spec-mandated greps green; APPROVED with non-blocking observations."
cycle: "003"
agent: quality
workflow: equipe-feature
node: review
resource: aefos://run/92fccbce1ddb8c2d37df799793017636
status: stable
tags: [review, modernrtti, callbacks, cycle-003, issue-7]
generated:
  by: "equipe-feature@node:review"
  at: "2026-08-28T11:15:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — Callbacks transversais"
  - id: adr
    resource: "adr.md"
    title: "ADR — Design da unit ModernSyntax.Callback"
  - id: plan
    resource: "plan.md"
    title: "Plan — Callbacks"
  - id: implement-report
    resource: "implement-report.md"
    title: "Implement report — ciclo 003"
  - id: verify-report
    resource: "verify-report.md"
    title: "Verify report — ciclo 003"
---

# Review report — Callbacks transversais (ciclo 003)

**Verdict: APPROVED**

Issue: [isaquepinheiro/ModernSyntax#7](https://github.com/isaquepinheiro/ModernSyntax/issues/7).  
Reviewed: `git status --porcelain` (untracked deliverables) and full file content
of all seven new files produced by the `implement` node.  
Reference documents: [esp](pipeline-esp.md), [adr](pipeline-adr.md), [plan](pipeline-plan.md).

---

## Summary

The implementation delivers all four fatias described in [plan](pipeline-plan.md):
`Source/ModernSyntax.Callback.pas`, the shared scenarios unit in the new
`Test Shared/EclbrSystem/` directory, the DUnitX thin shell + `.dpr`/`.dproj`,
and the FPCUnit thin shell + `.lpr`/`.lpi` in the new `Test FPC/EclbrSystem/`
directory. Every spec-mandated grep gate passes. The design decisions DEV-1
through DEV-6 recorded in [implement-report](pipeline-implement-report.md) are
internally consistent and traceable back to the ADR and ESP. Two non-blocking
observations are recorded below; neither blocks delivery.

---

## Checklist

### CA gates (ESP §4)

| # | Gate | Criterion | Result |
|---|------|-----------|--------|
| CA-8 | No `{$I ModernSyntax.inc}` in Callback.pas | `grep -n '{\$I ModernSyntax.inc}' Source/ModernSyntax.Callback.pas` → 0 lines | ✅ PASS |
| CA-8 | No `FCP` token in Callback.pas | `grep -n 'FCP' Source/ModernSyntax.Callback.pas` → 0 lines | ✅ PASS |
| RN-5 | `uses SysUtils;` only in interface | Confirmed by interface block extraction | ✅ PASS |
| CA-4 | No `{$IFDEF FPC}` in Test Shared, Test Delphi shells, Test FPC | `grep -rn '{\$IFDEF FPC}' 'Test Shared/' 'Test Delphi/…' 'Test FPC/'` → 0 | ✅ PASS |
| CA-4 | No actual `{$IFDEF` directives in shared scenarios | Two grep hits are inside `{ }` block comments, not directives | ✅ PASS |
| CA-4 | Shared unit references no test framework | `grep -rn 'DUnitX\|fpcunit\|testregistry\|TestFramework' Scenarios.pas` → 0 | ✅ PASS |
| CA-5 | `.lpi` exists with two build modes | `Debug-x86_64` (default) + `Debug-i386` override confirmed | ✅ PASS |
| CA-5 | `.lpi` `<OtherUnitFiles>` covers Source and Test Shared | Both paths in Item1 default and Item2 override `<CompilerOptions>` | ✅ PASS |

### RN gates (ESP §3)

| Rule | Criterion | Result |
|------|-----------|--------|
| RN-1 | Only contracts + factory in interface | Wrapper classes in `implementation` only (see OBS-1 for aliases) | ✅ PASS |
| RN-2 | Interfaces have no GUID | No `['{…}']` on any of the three interface declarations | ✅ PASS |
| RN-3 | `{$IFDEF FPC}` only inside Callback.pas | CA-4 grep → 0; Callback.pas preamble only | ✅ PASS |
| RN-4 | No `{$I ModernSyntax.inc}` | CA-8 grep → 0 | ✅ PASS |
| RN-5 | `uses SysUtils;` only | Confirmed | ✅ PASS |
| RN-6 | Capture via helper class pattern | `TAccumulator` in Scenarios.pas is the canonical reference | ✅ PASS |

### ADR decision conformance

| Decision | Verification | Result |
|----------|-------------|--------|
| D-A2 — three interfaces, no GUID | Interface declarations inspected | ✅ |
| D-A3/D-A6 — three method-of-object overloads; no `TFunc<T,R>` | All three `&Of` present; no fourth overload | ✅ |
| D-A5/D-A11 — no `.inc`, no `FCP` | Both greps → 0 | ✅ |
| D-A7 — thin shells, one useful line per method | Each `published`/`[Test]` method has exactly one delegation call | ✅ |
| D-A8 — `Test FPC/EclbrSystem/` directory | Created; `.lpr`, `.lpi`, `UTestMS.Callback.pas` present | ✅ |
| D-A9 — names `IModernFunc`/`IModernProc`/`IModernPredicate` | Confirmed in interface section | ✅ |
| DEV-1 — `&Of` escape | Required by grammar; preserves ADR literal naming | ✅ |
| DEV-6 — `SyntaxMode=Delphi` in `.lpi` | `<SyntaxMode Value="Delphi"/>` in both build-mode compiler-options blocks | ✅ |

### Plan pós-condições

| Condition | Result |
|-----------|--------|
| `Source/ModernSyntax.Callback.pas` exists, interface `uses` only SysUtils | ✅ |
| Shared scenarios exist, no `{$IFDEF}`, no framework | ✅ |
| DUnitX shell + `.dpr`/`.dproj` with search path to Test Shared | ✅ |
| FPCUnit shell + `.lpr`/`.lpi` with two build modes and search paths | ✅ |
| `grep -rn '{\$IFDEF FPC}' 'Test Shared/' 'Test Delphi/' 'Test FPC/'` → 0 | ✅ |
| CA-7 body literal in PR | ⏳ Correctly deferred to release/PR node |

---

## Critical issues

None.

---

## Non-blocking observations

### OBS-1 — `TModernFuncMethod<T,R>` aliases visible in interface section

ESP §3 RN-1 states: *"A unit expõe apenas os três contratos e o factory
`Callback`. Nenhum tipo interno de wrapper vaza para a `interface`."*

The interface section exposes three additional named types:
`TModernFuncMethod<T,R>`, `TModernProcMethod<T>`,
`TModernPredicateMethod<T>`. These are method-pointer *aliases*, not the
wrapper *classes* that RN-1 targets (those are correctly in `implementation`
only).

DEV-2 of [implement-report](pipeline-implement-report.md) documents the rationale:
FPC 3.2.2 has known parser errors with inline generic method-pointer types in
generic method parameter lists; naming them avoids the failure. The plan
(fatia 1, step 7) anticipated this: *"Onde precisar de ramificação (typedefs
internos, se necessário para o FPC não engasgar)"*.

Ruling: not a blocking violation of RN-1 in intent — RN-1 targets wrapper
implementation classes. However, these aliases are now part of the public
surface and a consumer can declare a variable of type
`TModernFuncMethod<Integer,String>`, creating coupling not described in the
ESP. Recommendation for a future cycle: add an advisory comment in the
interface section making clear these aliases are infrastructure, not API, or
revisit once FPC 3.2.2 inline-generic-pointer behavior is fully mapped.

### OBS-2 — CA-4 grep hits comment text in shared scenarios

`grep -n '{\$IFDEF' 'Test Shared/EclbrSystem/UTestMS.Callback.Scenarios.pas'`
returns two hits on lines 23 and 29, both inside `{ }` block comments — no
actual compiler directive is present. The spec's CA-4 test targets
`{$IFDEF FPC}` (with the `FPC` suffix), which returns zero lines. No
functional violation. Noted because a future strict linter that catches
`{$IFDEF` in comment text would produce noise; if such a lint step is added,
the comment text should be paraphrased.

---

## Compilation caveat

PRD R2 and ESP §5 prohibit compilation in the pipeline. All verification is
by read + grep. Runtime correctness and the `lazbuild` two-mode build are the
author's responsibility on their machine. CA-6 of the ESP explicitly places
this obligation on the author, not the pipeline.

---

## Handoff to committer

All static gates pass. The implementation is ready for the commit/PR node.
Body of the PR must include the CA-7 literal text from ESP §4:
*"compilado em FPC 3.2.2 x86_64 e i386; não compilado em Delphi —
Delphi permanece com o autor"*.
