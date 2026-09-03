---
type: cycle-report
kind: report
title: "REPORT quality-review — ciclo 028, iteracao 9"
description: "Implementacao Pascal correta; AC-10 do ESP falha na fabrica (10/14, ENotImplemented RTL FPC x86_64-linux). Nona rejeicao identica com causa spec, node_blamed architect."
cycle: "028"
agent: quality
workflow: equipe-feature
node: review
resource: aefos://run/3973e0a8a9fb319c0e20e1154e93d8d3
generated:
  by: "equipe-feature@node:review"
  at: "2026-09-03T00:00:00Z"
tags: [cycle-report, quality, invoker, rtti, fpc, delphi, issue-13, cycle-028, iteration-9, rejection]
---

# REPORT — quality-review, ciclo 028 (iteracao 9)

**Veredicto: REJECTED**
**Causa:** `spec`
**Node blamed:** `architect`

## O que foi revisado

Quatro arquivos modificados neste ciclo (confirmado por `git status --porcelain`):

- `Source/ModernSyntax.Invoker.pas`
- `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas`
- `Test FPC/EclbrSystem/UTestMS.Invoker.pas`
- `Test Delphi/EclbrSystem/UTestMS.Invoker.pas`

Artefatos do bundle do pipeline: [esp](pipeline-esp.md), [adr](pipeline-adr.md),
[implement-report](pipeline-implement-report.md).

## Resultado

A implementacao Pascal esta **correta em todos os D-13.x** (ver
[review-report](pipeline-review-report.md) para checklist completo). O
overload dinamico `TModernInvoker.Invoke(AInstance, AMethodName, AArgs,
AResultType): TValue` foi entregue com assinatura identica cross-compiler,
corpo divergente por `{$IFDEF FPC}`, XMLDoc por compilador e fronteiras
medidas. Zero regressao nos 7 cenarios existentes.

**Bloqueio:** AC-10 do [esp](pipeline-esp.md) exige `13/13` na fabrica FPC
3.2.2 x86_64, sem distinguir Linux de Win64. A fabrica (`x86_64-linux`)
entrega **10/14** porque `SystemInvoke` (backend assembly de `Rtti.Invoke`
livre) nao foi portado para SysV AMD64 na FPC 3.2.2 — apenas para
`x86_64-win64`. Os 4 testes de invocacao real levantam `ENotImplemented` da
RTL antes de qualquer codigo da nossa unit.

## Rework necessario

Tres edicoes redatorias no architect (zero Pascal):

1. ESP AC-10: qualificar por target OS (delegacao analogamente a D-13.12).
2. ESP AC-10: corrigir contagem de 13 para 14.
3. ADR Contexto/D-13.2: erratum distinguindo `x86_64-win64` de `x86_64-linux`.

## Nota de escalacao

Esta e a **nona** rejeicao identica. O `FLOW-FEEDBACK.md` deste ciclo
registra 17+ achados recomendando gate automatico de escalacao apos N=3
rejeicoes com mesmo `cause + node_blamed` sem diff no artefato causador.
O ciclo nao pode convergir sem input externo (Opcao A, B ou C — detalhadas
em [decisions-review](decisions-review.md)).
