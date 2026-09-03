---
type: verify-report
kind: artifact
title: "Verify report — cycle 029 — TModernInvoker.Invoke dinamico"
description: "FPC 3.2.2 x86_64-linux: compile clean (5 warnings pre-existentes/esperados), suite 14/14 passou, CA-5 confirmado."
cycle: "029"
agent: quality
workflow: equipe-feature
node: verify
resource: aefos://run/c26861e980aa5045a4f8b7de8b2207c2
generated:
  by: "equipe-feature@node:verify"
  at: "2026-09-03T00:00:00Z"
tags: [verify-report, fpc, invoker, dynamic-invoke, cycle-029, issue-13]
verdict: PASSED
---

# Verify Report — Cycle 029 — `TModernInvoker.Invoke` dinâmico

## Escopo

Arquivos modificados neste ciclo (via `git status`):

| Arquivo | Tipo |
|---------|------|
| `Source/ModernSyntax.Invoker.pas` | Fonte |
| `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas` | Cenários compartilhados |
| `Test FPC/EclbrSystem/UTestMS.Invoker.pas` | Casca FPCUnit |
| `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` | Casca DUnitX (Delphi, não exercitada na fábrica) |
| `.project/project-evolution.md` | Metadado do projeto |

## Compilação FPC

**Comando executado:**
```
rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild
fpc -Mdelphi \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -FU/tmp/fpcbuild -FE/tmp/fpcbuild \
    "Test FPC/EclbrSystem/PTestInvoker.lpr"
```

**Resultado:** 923 linhas compiladas, 0.3 s  
**Warnings:** 5 (todos esperados ou pré-existentes)

| Warning | Arquivo | Linha | Status |
|---------|---------|-------|--------|
| `Unit "Rtti" is experimental` | `UTestMS.Invoker.Cases.pas` | 32 | ✅ esperado (ESP §5) |
| `Unit "Rtti" is experimental` | `ModernSyntax.Invoker.pas` | 62 | ✅ esperado (ESP §5) |
| `unreachable code` | `ModernSyntax.Invoker.pas` | 129 | ✅ pré-existente (linha renumerada) |
| `unreachable code` | `ModernSyntax.Invoker.pas` | 129 | ✅ pré-existente (linha renumerada) |
| `unreachable code` | `ModernSyntax.Invoker.pas` | 149 | ✅ pré-existente (linha renumerada) |

**Confirmação de pré-existência:** stash + recompilação do estado `main` produziu idênticos 3 `unreachable code` (linhas 80, 80, 100 antes das adições). São os mesmos avisos com linhas deslocadas pelo novo código.

**Notes** (não-warnings, não bloqueantes): 3 × `Local variable "v" is assigned but never used` em `UTestMS.Invoker.Cases.pas` — esperados, documentados no implement-report.

**Zero warnings novos além dos esperados.** Gate ✅

## Execução da suite

```
/tmp/fpcbuild/PTestInvoker --all -a --format=plain
```

```
Time:00.000 N:14 E:0 F:0 I:0
  TInvokerTests Time:00.000 N:14 E:0 F:0 I:0
    Invoke_InstanceMethod_ReturnsValue          ✓
    TypedMethod_CalledWithArgs_ReturnsExpected   ✓
    Invoke_ClassMethod_Works                    ✓
    Invoke_MethodNotFound_RaisesWithActionableMessage ✓
    Invoke_NilInstance_Raises                   ✓
    Invoke_PublicMethodWithoutMPlus_RaisesNotFound ✓
    Invoke_NonMethodSignature_Raises            ✓
    InvokeDynamic_ReturnsRecordIntegerAndString ✓
    InvokeDynamic_ReturnsDouble                ✓
    InvokeDynamic_ReturnsManagedString         ✓
    InvokeDynamic_ProcedureVoid_SideEffect     ✓
    InvokeDynamic_NilInstance_Raises           ✓
    InvokeDynamic_MethodNotFound_RaisesInstructive ✓
    InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC ✓

Number of run tests: 14 | errors: 0 | failures: 0
```

**14/14 passou.** Gate ✅ (contagem subiu de 7 para 14 conforme D-13.3/ESP §6)

## Gates de aceitação (CA-5)

**`{$IFDEF FPC}` em `UTestMS.Invoker.Cases.pas`:**
```
grep -c '{$IFDEF FPC}' "Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas"
→ 0
```
Gate CA-5 ✅ (ramificações permitidas usam `{$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}` — por alvo, não por compilador)

**Casca FPC tem 14 métodos (7 originais + 7 novos `InvokeDynamic_*`):** ✅  
**Novos métodos delegam a `Case_InvokeDynamic_*` (uma linha cada):** ✅  
**Casca FPC não registra `_OKOnDelphi`:** ✅  

## Cobertura de compiladores

| Compilador | Status |
|-----------|--------|
| FPC 3.2.2 x86_64-linux (fábrica) | ✅ PASSED |
| FPC i386 | ⚠️ TOOL_MISSING — `ppc386` não disponível na fábrica (SKILL.md) |
| Delphi | ⚠️ TOOL_MISSING — Delphi não instalado na fábrica (SKILL.md) |

Ausência de FPC i386 e Delphi é estrutural e documentada; o gate de qualidade da fábrica cobre apenas `x86_64-linux`.

## Complexidade (lizard)

`lizard` não disponível na fábrica (`pip` ausente — SKILL.md §"Complexity gate"). Avaliação manual: o novo método `Invoke` usa `{$IFDEF FPC}` com dois ramos simples; CCN ≤ 5. Gate TOOL_MISSING, sem bloqueio.

## Veredicto

**PASSED** — compilação limpa (0 novos warnings), suite 14/14, CA-5 confirmado.
