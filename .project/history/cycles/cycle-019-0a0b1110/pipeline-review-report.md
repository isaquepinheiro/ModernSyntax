---
type: review-report
kind: artifact
title: "Review Report — Cycle 019 (issue #46: TModernRTTIArrayType + TModernRTTISetType)"
description: "Quality review of cycle 019 implementation against esp.md and adr.md. Verdict: APPROVED."
cycle: "019"
agent: quality
workflow: equipe-feature
node: review
resource: aefos://run/0a0b1110fc1826855542e8d75c65cf65
status: stable
tags: [cycle-019, review, issue-46, tmodernrttiarraytype, tmodernrttisettype, approved]
generated:
  by: "equipe-feature@node:review"
  at: "2026-09-02T00:00:00Z"
---

# Review Report — Cycle 019

**Verdict: APPROVED**

Reviewed: `git diff main...HEAD` + untracked files.
Spec sources: [esp](pipeline-esp.md), [adr](pipeline-adr.md).

---

## Summary

All acceptance criteria from the ESP are satisfied. The implementation
delivers `TModernRTTIArrayType` and `TModernRTTISetType` in the public unit,
with backend FPC and Delphi functions, four shared scenarios (7–10), and
the corresponding shells in both test projects. Every anchored check passes.
No critical issues found.

---

## Acceptance Checklist

### Structure / Public API (ESP §2.1)

- [x] `TModernRTTIArrayType` and `TModernRTTISetType` declared after `TModernRTTIRecordType` with `strict private FToken: PTypeInfo`.
- [x] `FromTypeInfo` factories assign `FToken` without validating `Kind` (D-46.1 / D-1).
- [x] `TModernRTTIArrayType` exposes: `IsDynamic`, `ElementType`, `Size`, `Length`.
- [x] `TModernRTTISetType` exposes: `ElementType`.
- [x] XMLDoc on each public member. `Length`'s XMLDoc cites verbatim the raise behaviour in dynamic.

### Backend FPC (ESP §2.2)

- [x] `ArrayTypeIsDynamic`, `ArrayTypeElementType`, `ArrayTypeSize`, `ArrayTypeLength`, `SetTypeElementType` declared in `interface`.
- [x] Three `resourcestring`: `SArrayWrongKind`, `SArrayDynamicLength`, `SSetWrongKind`.
- [x] `SArrayDynamicLength` text: `'TModernRTTIArrayType.Length: nao suportado para arrays dinamicos.'` ✅
- [x] `ArrayRaiseWrongKind` — combined guard `[tkArray, tkDynArray]` (D-46.4).
- [x] `SetRaiseWrongKind` — classic single-kind guard `tkSet`.
- [x] `ArrayTypeElementType` dynamic branch: `GetTypeData(P)^.elType2` (property). Static branch: `GetTypeData(P)^.ArrayData.ElType` (property).
- [x] `ArrayTypeSize` dynamic: `elSize`. Static: `ArrayData.Size`.
- [x] `ArrayTypeLength` dynamic: raises `EModernRTTIError(SArrayDynamicLength)`. Static: `ArrayData.ElCount` (not `TotalElementCount`).
- [x] `SetTypeElementType`: `GetTypeData(P)^.CompType` (property).
- [x] **Zero raw ref field usage** (`elType2Ref`, `elTypeRef`, `CompTypeRef`) in source — only in `//` comments. `grep` = 0 in FPC.pas, 0 in RTTI.pas (comments only).

### Backend Delphi (ESP §2.3)

- [x] Five functions declared in `interface`.
- [x] Three `resourcestring` with **identical text** to FPC (D-2/D-43.6).
- [x] `ArrayRaiseWrongKind` and `SetRaiseWrongKind` same guards as FPC.
- [x] `ArrayTypeElementType` branches by `Kind`: dynamic → `TRttiDynamicArrayType(LCtx.GetType(P)).ElementType.Handle`; static → `TRttiArrayType(LCtx.GetType(P)).ElementType.Handle`. No common cast (D-46.10).
- [x] `LCtx` local with `try/finally` for `ArrayTypeElementType` and `SetTypeElementType` (D-44.5).
- [x] `ArrayTypeSize` and `ArrayTypeLength`: direct `GetTypeData(P)^` reads, no context (correct — Size/IsDynamic/dynamic-raise need no context).
- [x] `SetTypeElementType`: `TRttiSetType(LCtx.GetType(P)).ElementType.Handle` with `try/finally`.

### Anchored checks (D-46.11)

- [x] `grep -cE '^[[:space:]]*\{\$(IFDEF|IFNDEF)' Source/ModernSyntax.RTTI.pas` = **1** (unchanged). CA-4 satisfied.
- [x] `grep -n 'elType2Ref\|elTypeRef\|CompTypeRef' Source/ModernSyntax.RTTI.FPC.pas` = **0**.
- [x] No `{$IFDEF FPC}` directive in `UScenarios.RTTI.pas` — the one match at line 1245 is inside a `//` comment. CA-5 satisfied.

### Shared Scenarios (ESP §2.4)

- [x] Four fixtures declared in `interface` section `type`: `TArr5Int46`, `TDynByteArr46`, `TDynStrArr46`, `TSetCor46`.
- [x] `TDynByteArr46 = array of Byte` (not Integer) — elSize=1 diverges from SizeOf(Pointer) in both bitness (D-46.7).
- [x] Scenario 7 (`Scenario_ArrayType_Static_LengthAndSize`): `IsDynamic=False`, `Length=5`, `Size=SizeOf(TArr5Int46)`, `ElementType.IsNil` (not nil). ✅
- [x] Scenario 8 (`Scenario_ArrayType_Dynamic_LengthRaises`): `IsDynamic=True`, Length raises `EModernRTTIError`, ElementType.Name by reference against `Byte`, Size=1. Mutation 1 comment present; Mutation 1 kill documented.
- [x] Scenario 9 (`Scenario_ArrayType_Dynamic_Managed_ElementType`): `IsDynamic=True`, ElementType.Name by reference against `string`. Comment explicitly states this scenario does **not** cover Mutation 1 (D-46.9).
- [x] Scenario 10 (`Scenario_SetType_ElementType`): ElementType.Name by reference against `TCor`. Mutation 2 kill documented.
- [x] All Name comparisons by reference via `TModernRTTI.GetType(TypeInfo(<type>)).Name` (D-46.8 / B-46.6). No literal comparison.

### Test Shells (ESP §2.5)

- [x] FPC: `TestArrayType_Static_LengthAndSize`, `TestArrayType_Dynamic_LengthRaises`, `TestArrayType_Dynamic_Managed_ElementType`, `TestSetType_ElementType` — published, one-line bodies. Count: **41** (37→41). ✅
- [x] Delphi: same four `[Test]` procedures, one-line bodies. Count: **39** (35→39). ✅ (raw grep gives 46 due to 7 occurrences in comments — actual decorators = 39).

### project-evolution.md

- [x] Row 019 added to cycle table with correct issue #46 link and status `🔄 in-review`.
- [x] **Ciclo 019** narrative block added with accurate technical description matching ESP §1 and ADR.

---

## Critical Issues

**None.**

---

## Non-Blocking Observations

1. **`ElementType.IsNil` vs `ElementType.Handle = nil` (Scenario 7):** The implementation uses `LArr.ElementType.IsNil` where the ESP template shows `LArr.ElementType.Handle = nil`. Both are semantically equivalent; `IsNil` is the proper API method on `TModernRTTIType`. This is an improvement over the template.

2. **`Fail(msg)` vs `raise ETestScenarioFailed.Create(msg)`:** The implementation uses `Fail(...)` — the DUnit/FPCUnit built-in, consistent with all prior scenarios in the file. The ESP template used `raise ETestScenarioFailed.Create(...)` as a simplified schematic. No issue.

3. **Delphi Scenario 8 format strings:** Scenario uses `Format(...)` for error messages (`Length` and `Size` fail messages). This is more informative than the ESP template and is consistent with existing patterns in the file (e.g., `Scenario_EnumerationType`). No issue.

4. **Mutation documentation location:** Both mutation notes appear in the FPC backend's implementation comments, as expected (D-46.9 specifies the mutations on the FPC side). The Delphi backend also cross-references mutation 2 in a comment. Clear and consistent.

---

## Out-of-Scope Verification

- No `Bounds`/`Dims` were added (correctly excluded per ESP §2.6).
- No `SetType.Bytes` added (correctly excluded).
- No wrong-kind shells added (optional, deferred to future cycle per ESP §2.6).
- No new `{$IFDEF}` in `UScenarios.RTTI.pas` (CA-5 confirmed).
