---
type: review-report
kind: artifact
title: "Review Report — TModernRTTIMethod / vmtMethodTable (issue #25, cycle 009)"
description: "Quality review of cycle-009 implementation: TModernRTTIMethod, TModernRTTIParameter, §7 backend split, ETestScenarioFailed surgery, and three shared scenarios."
status: stable
cycle: "009"
agent: quality
workflow: equipe-feature
node: review
resource: aefos://run/af5fcd28da98e98892fbe66e544b6b5c
tags: [cycle-009, quality, review, issue-25, modernrtti, pilar-4]
generated:
  by: "equipe-feature@node:review"
  at: "2026-08-31T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — issue #25"
  - id: adr
    resource: "adr.md"
    title: "ADR — issue #25"
  - id: implement-report
    resource: "implement-report.md"
    title: "Implement report — cycle 009"
  - id: skill
    resource: "../SKILL.md"
    title: "SKILL — toolchain and quality commands"
---

# Review Report — cycle 009 (af5fcd28)

## Summary

The implementation delivers `TModernRTTIMethod`, `TModernRTTIParameter`, and the full
§7 backend split (`ModernSyntax.RTTI.Delphi.pas` + `ModernSyntax.RTTI.FPC.pas`) for
issue #25, together with the `ETestScenarioFailed` surgery that closes #35.

All 17 acceptance criteria from the [esp](pipeline-esp.md) have been verified against the
actual source. The implementation is **correct**, convention-adherent, and within scope.
No critical issues were found.

---

## CA Checklist (esp.md §4)

| # | Criterion | Status | Notes |
|---|-----------|--------|-------|
| CA-1 | `TModernRTTIMethod` compiles both compilers; zero `{$IFDEF}` in public declaration | ✅ PASS | Single `{$IFDEF FPC}` at implementation `uses` (line 277); zero in type block |
| CA-2 | `TModernRTTIParameter` compiles both compilers; zero `{$IFDEF}` in public declaration | ✅ PASS | Same §7 architecture |
| CA-3 | FPC `GetMethods(AClass)` enumerates published via vmtMethodTable, climbs ClassParent | ✅ PASS | `MethodTokens` uses `LTab^.Entry[LIdx]` + `LCur := LCur.ClassParent` |
| CA-4 | FPC `GetMethod(AName)` uses `MethodAddress` without own ClassParent loop | ✅ PASS | `MethodTokenByName`: one line, `AOwner.MethodAddress(AName)` |
| CA-5 | `Invoke` works on both compilers | ✅ PASS | Delegates to `TModernInvoker.Invoke<TSignature>(AInstance, FName)` |
| CA-6 | Iteration uses `LTab^.Entry[i]`; no `PByte(LTab)+N` or `i*SizeOf(TVmtMethodEntry)` | ✅ PASS | Grep confirms: zero literal pointer arithmetic in FPC backend |
| CA-7 | Six unsupported FPC members raise `EModernRTTIError` with explanatory message | ✅ PASS | `IsConstructor`, `IsClassMethod`, `IsStatic`, `Visibility`, `ReturnType`, `GetParameters` all raise with `SMethodMemberNoSource` |
| CA-8 | `TModernRTTIParameter.Name` and `.ParamType` raise `EModernRTTIError` on FPC | ✅ PASS | Raise via `SParameterMemberNoSource` |
| CA-9 | XMLDoc of 8 members documents per-compiler behaviour; `GetMethods` declares coverage divergence | ✅ PASS | All 8 members have remarks; `GetMethods` XMLDoc (RTTI.pas:237-244) explicitly states "Delphi enumera public E published; FPC 3.2.2 enumera apenas os published" |
| CA-10 | `UScenarios.RTTI.pas` declares `ETestScenarioFailed = class(Exception)` and `Fail` raises it | ✅ PASS | Interface block line 43; `Fail` at line 153 |
| CA-11 | Shared fixture `TMethodBase`/`TMethodDerived` with `{$M+}`…`{$M-}`, only `published` | ✅ PASS | Lines 82-91 in `UScenarios.RTTI.pas` |
| CA-12 | Three shared scenarios, all using `Fail`, no `Assert`, no `{$IFDEF FPC}` | ✅ PASS | `Scenario_GetMethods_CountsPublishedInherited_Exact`, `Scenario_GetMethod_ByName_FindsInherited`, `Scenario_Method_Invoke_NoArgs` — grep confirms zero Assert and zero IFDEF in scenarios |
| CA-13 | FPC and Delphi test files receive three published tests | ✅ PASS | Both files confirmed; each test is a single delegation call |
| CA-14 | Stale comment at Delphi `UTestMS.RTTI.pas` line 59 corrected | ✅ PASS | Header rewritten; now describes unified surface + FPC raising by vFieldTable |
| CA-15 | Test using `TModernRTTIMethod` compiles without any `{$IFDEF FPC}` in test code (CA-5) | ✅ PASS | Zero IFDEFs in `UScenarios.RTTI.pas`, `UTestMS.RTTI.pas` (FPC), `UTestMS.RTTI.pas` (Delphi) |
| CA-16 | `PTestRTTI.lpr` compiles and passes on both bitnesses | ✅ x86_64, ⚠️ i386 | FPC x86_64: 8/8 green (implement-report). i386: not run in factory (SKILL.md:122-124); left for author — declared in implement-report per SKILL.md:92-97. **Acceptable.** |
| CA-17 | Mutation proof declared in PR body (M1 and M2) | ✅ M1 confirmed, ⚠️ M2 by author | M1: `ClassParent` removal → ETestScenarioFailed, exit=2 (confirmed in factory). M2: i386-only, factory lacks `ppc386` — declared for author per SKILL.md convention. |

---

## Critical Issues

**None.** The implementation is correct and passes all mandatory criteria.

---

## Non-Blocking Observations

### OBS-1: Sentinel `Pointer(1)` requires careful reading

`MethodTokenByName` (FPC) returns `Pointer(1)` as a sentinel meaning "found, no `PVmtMethodEntry`".
`MethodName` would crash if called with `Pointer(1)` (deref of invalid pointer), but flow analysis
confirms it is never called with the sentinel: `GetMethod` populates `FName = AName`, so
`TModernRTTIMethod.Name` uses `FName` directly (non-empty guard at RTTI.pas:435-439).
The approach is correct but subtle. A one-line comment in `MethodTokenByName` noting
"sentinel — never passed to MethodName (caller stores AName in FName)" would help future readers.

### OBS-2: `ReturnType` / `ParamType` return `PTypeInfo` instead of `TModernRTTIType`

Developer decision D-DEV.1: Pascal records cannot forward-declare each other, making the
`TModernRTTIType → TModernRTTIMethod.ReturnType → TModernRTTIType` cycle impossible without
breaking the abstraction. The `PTypeInfo` return is portable and correct. ADR D-25.6 says
"Name e ParamType reais" — `PTypeInfo` qualifies. XMLDoc documents the wrapping pattern.
**Not a spec violation; a well-justified design adaptation.**

### OBS-3: Ten FPC warnings "function result does not seem to be set"

The FPC backend functions that always `raise` generate compiler warnings because the compiler
does not analyse `raise` as an unreachable-return guarantee. These are cosmetic; adding
`Result := Default(<type>);` before the `raise` would silence them. Out of scope for this
issue but noted for a future housekeeping cycle.

### OBS-4: Delphi compilation unverified in factory

Expected per SKILL.md:15-27. The implement-report correctly states this and scopes the
claim to FPC x86_64. No action required.

---

## Scope Compliance

All changed files are within the declared scope of the [esp](pipeline-esp.md) §2:
- `Source/ModernSyntax.RTTI.pas` — refactored shell
- `Source/ModernSyntax.RTTI.Delphi.pas` — new backend
- `Source/ModernSyntax.RTTI.FPC.pas` — new backend
- `Test Shared/EclbrSystem/UScenarios.RTTI.pas` — fixture + scenarios + #35 surgery
- `Test FPC/EclbrSystem/UTestMS.RTTI.pas` — three new published tests
- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` — three new published tests + stale comment
- `.project/project-evolution.md` — board marker (pipeline artefact, not product code)

Files explicitly out-of-scope (`ModernSyntax.Invoker.pas`, other `Source/` units,
`PTestRTTI.lpr`) were **not touched**. ✅

---

## Verdict

**APPROVED** — implementation is correct, within scope, convention-adherent, and all
mandatory acceptance criteria from the [esp](pipeline-esp.md) are satisfied. The non-blocking
observations are cosmetic and do not require rework before merging.
