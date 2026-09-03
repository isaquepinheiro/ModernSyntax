---
type: cycle-report
kind: report
title: "REPORT quality-review — cycle 029"
description: "Revisao do cycle 029 (#13): overload dinamico TValue-based aprovado — todos os criterios criticos do ESP satisfeitos, CA-5 preservado (0 IFDEF FPC no Cases.pas), suite 14/14 verde na fabrica FPC 3.2.2 x86_64-linux."
cycle: "029"
agent: quality
workflow: equipe-feature
node: review
resource: aefos://run/c26861e980aa5045a4f8b7de8b2207c2
generated:
  by: "equipe-feature@node:review"
  at: "2026-09-03T00:00:00Z"
tags: [cycle-report, quality, review, rtti, invoker, issue-13, cycle-029]
---

# REPORT quality-review — cycle 029

## Veredito

**APPROVED**

## Resumo da revisao

A entrega do cycle 029 (issue #13 — `TModernInvoker.Invoke` dinamico com
fronteira POR ALVO) cumpre todos os criterios criticos do [ESP](pipeline-esp.md)
e do [ADR](pipeline-adr.md):

- **4 arquivos no escopo** — todos modificados conforme declarado no ESP §3.
- **Assinatura publica identica** (D-13.1): declaracao unica sem `{$IFDEF}` na
  interface; corpo diverge por `{$IFDEF FPC}`.
- **XMLDoc por ALVO** (D-29.1): tres linhas de fronteira (Delphi / FPC-Windows /
  FPC-outros), citando `SErrInvokeNotImplemented`, `rtti.pp:583` e
  `packages/rtl-objpas/src/<arch>/invoke.inc`.
- **CA-5 preservado**: `grep -c "{\$IFDEF FPC}"` no `Cases.pas` = **0** (zero);
  ramificacao por alvo usa `{$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}`.
- **Suite 14/14 verde** na fabrica FPC 3.2.2 x86_64-linux: 4 cenarios de valor
  asserem `ENotImplemented` da RTL (D-29.2), 10 restantes passam com valor /
  guarda conforme especificado.
- **Sem warnings novos impermissiveis**: 2 "Unit Rtti is experimental" (esperados
  per D-29.3 e ESP §5.13); 3 "unreachable code" sao pre-existentes (baseline
  medido via `git stash`).
- **Regressao zero**: overload portavel `Invoke<TSignature>` intocado; 7/7 cenarios
  existentes verdes.

## Observacoes nao-bloqueantes

1. **`TypInfo` no `uses`** — `PTypeInfo` nao e reexportado por `Rtti` no FPC
   3.2.2; adicao obrigatoria, documentada no [implement-report](pipeline-implement-report.md).
2. **ESP §6 vs ADR D-29.2** — texto do ESP omite `defined(FPC)` na condicao de
   alvo; implementacao segue o ADR (correto). Omissao tipografica no ESP; ADR
   e a fonte de autoridade.
3. **3 FPC Notes "assigned but never used"** — intencional; nao sao warnings;
   estrutura permanece identica ao que rodara em alvo Windows.

## Escopo verificado

| Arquivo | Resultado |
|---------|-----------|
| `Source/ModernSyntax.Invoker.pas` | ✅ Conforme ESP |
| `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas` | ✅ Conforme ESP + CA-5 |
| `Test FPC/EclbrSystem/UTestMS.Invoker.pas` | ✅ 14 testes, `_RaisesOnFPC` registrado |
| `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` | ✅ 14 testes, `_OKOnDelphi` registrado |
| `.project/project-evolution.md` | ✅ Linha 40 `in-review` |

## Links

- [pipeline-esp](pipeline-esp.md)
- [pipeline-adr](pipeline-adr.md)
- [pipeline-implement-report](pipeline-implement-report.md)
- [pipeline-plan](pipeline-plan.md)
