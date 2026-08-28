---
type: review-report
kind: artifact
title: "Review Report — TModernInvoker (cycle 005, issue #10)"
description: "Quality-review lens verdict for cycle 005: APPROVED. All 12 acceptance criteria met or correctly deferred; FPC 3.2.2 x86_64 binary proof 7/7 green."
cycle: "005"
agent: quality
workflow: equipe-feature
node: review
resource: aefos://run/2ef372d993ff75b8dcd8c707bb79d636
tags: [review, cycle-005, modernrtti, invoker, issue-10]
generated:
  by: "equipe-feature@node:review"
  at: "2026-08-28T15:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — TModernInvoker"
  - id: adr
    resource: "adr.md"
    title: "ADR — Design da unit ModernSyntax.Invoker"
  - id: skill
    resource: "../SKILL.md"
    title: "SKILL — toolchain and quality commands"
  - id: implement-report
    resource: "implement-report.md"
    title: "Implement report — TModernInvoker"
---

# Review Report — TModernInvoker (cycle 005, issue #10)

## Verdict: APPROVED

All verifiable acceptance criteria pass. Binary proof provided for FPC 3.2.2 x86_64
(7/7 tests green). Non-binary criteria (Delphi, FPC i386) are explicitly and correctly
deferred to the author per SKILL §"Delphi" and §"The command", which is the documented
protocol for this project.

## Scope reviewed

### Tracked changes (`git diff develop...HEAD`)

| File | Change | Status |
|------|--------|--------|
| `.project/SKILL.md` | New — executable build/test recipe | ✓ Correct |
| `.project/analysis/02-stack.md` | Supersedes false FPC-not-supported claim; links SKILL | ✓ Correct |
| `.project/index.md` | Links SKILL.md, analysis/, strategy/ | ✓ Correct |

### Untracked deliverables

| File | Status |
|------|--------|
| `Source/ModernSyntax.Invoker.pas` | ✓ All RN/CA verified |
| `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas` | ✓ 7 cases, no framework |
| `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` | ✓ Thin DUnitX shell |
| `Test Delphi/EclbrSystem/PTestInvoker.dpr` | ✓ ReportMemoryLeaksOnShutdown present |
| `Test Delphi/EclbrSystem/PTestInvoker.dproj` | ✓ Pattern of family |
| `Test Delphi/EclbrSystem/PTestInvoker.res` | ✓ Present |
| `Test FPC/EclbrSystem/UTestMS.Invoker.pas` | ✓ Thin FPCUnit shell |
| `Test FPC/EclbrSystem/PTestInvoker.lpr` | ✓ consoletestrunner pattern |
| `Test FPC/EclbrSystem/PTestInvoker.lpi` | ✓ Two build modes |

## Acceptance criteria checklist

| CA | Description | Result |
|----|-------------|--------|
| CA-1 | `Invoke<TFn>(AInstance, 'Nome')` works on both compilers | ✓ `Case_Invoke_InstanceMethod_ReturnsValue` |
| CA-2 | `Invoke<TFn>(AClass, 'Nome')` works on both compilers | ✓ `Case_Invoke_ClassMethod_Works` |
| CA-3 | Method callable with args, returns expected value | ✓ `Case_TypedMethod_CalledWithArgs_ReturnsExpected` |
| CA-4 | Not-found raises with actionable message citing `{$M+}` and `published` | ✓ `Case_Invoke_MethodNotFound_RaisesWithActionableMessage` |
| CA-5 | Nil instance raises before touching memory | ✓ `Case_Invoke_NilInstance_Raises`; nil guard is line 2, before `MethodAddress` |
| CA-6 | Public method without `{$M+}` raises "not found" | ✓ `Case_Invoke_PublicMethodWithoutMPlus_RaisesNotFound` via `TNoM` |
| CA-7 | `Invoke<Integer>` fails with SizeOf guard message | ✓ `Case_Invoke_NonMethodSignature_Raises` |
| CA-8 | Zero `{$IFDEF FPC}` in all three test files | ✓ grep → 0 (verified) |
| CA-9 | `.lpi` with Debug-x86_64 and Debug-i386 build modes | ✓ Both present; x86_64 default |
| CA-10 | Invoker.pas: no `{$I ModernSyntax.inc}`, no `FCP`, no `{$IFDEF` | ✓ grep → 0 (verified) |
| CA-11 | Invoker.pas `uses` = `SysUtils` only | ✓ grep → 1 line, `SysUtils` only |
| CA-12 | PR body declares compiler scope | ✓ Deferred to committer per task-input |

## Business rules (RN) checklist

| RN | Rule | Result |
|----|------|--------|
| RN-1 | `TModernInvoker` is `record` | ✓ |
| RN-2 | Two overloads `Invoke<TSignature>` only — no leaked types | ✓ |
| RN-3 | SizeOf guard is first line of both overloads | ✓ Lines 79 and 99 |
| RN-4 | Body: guard → MethodAddress → nil check → TMethod → Move | ✓ Correct shape; nil guard added as line 2 per plan |
| RN-5 | Unit autocontained, `uses SysUtils;` only in interface | ✓ |
| RN-6 | Zero `{$I ModernSyntax.inc}` | ✓ |
| RN-7 | Zero `{$IFDEF FPC}` in unit body | ✓ |
| RN-8 | Header in `(* ... *)`, no `{ }` comment | ✓ |
| RN-9 | Generic body only instantiates `TMethod` (RTL) — no local type | ✓ |
| RN-10 | Shell tests: exactly one useful line per `[Test]`/`published` | ✓ Both DUnitX and FPCUnit shells verified |

## Non-blocking observations

1. **FPC warning "unreachable code" in `Case_Invoke_NonMethodSignature_Raises`** — expected
   and documented in implement-report §"Caveats". The warning arises because `SizeOf(Integer)`
   is always < `SizeOf(TMethod)`, so the guard always triggers and the rest of
   `Invoke<Integer>` is unreachable. The warning *validates* the guard; it is not a defect.
   If a zero-warning policy is adopted in future, `{$WARN 5024 OFF}` can silence it locally.

2. **FPC shell `UTestMS.Invoker.pas` lists `ModernSyntax.Invoker` in `uses`** — redundant
   (already imported transitively via `UTestMS.Invoker.Cases`) but harmless. Consistent
   with making the shell self-documenting about its dependencies.

3. **`PTestInvoker.dpr` is richer than the family minimum** — includes TestInsight and
   NUnit logger conditional blocks. This matches the existing family pattern
   (e.g., `PTestObjects.dpr`) and is correct. No action needed.

4. **`project-evolution.md` is untracked** — mentioned in implement-report as modified to
   `🔄 in-review`. Not reviewed here (bundle-root state file, not a code deliverable);
   committer should verify it reaches `✅ done` post-merge.

## Critical issues

None. The delivery is complete, coherent, and correctly bounded.
