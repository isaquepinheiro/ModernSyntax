---
type: cycle-report
kind: report
title: "REPORT release — ciclo 025 (issue #60)"
description: "Ciclo 025 entregue: else raise EModernRTTIError no PropertyVisibility do backend FPC; 3 lentes de qualidade APROVADAS; pronto para commit."
cycle: "025"
agent: release
workflow: equipe-bug
node: closing-record
resource: aefos://run/4c9ae8e8f3b0ca77a166f343e7d3f098
generated:
  by: "equipe-bug@node:closing-record"
  at: "2026-09-02T00:00:00Z"
tags: [cycle-025, issue-60, release, report, fpc, rtti, visibility, fail-loud]
---

# REPORT release — ciclo 025 / issue #60

## O que este ciclo entregou

O ciclo 025 implementou a mesma guarda `else raise EModernRTTIError` que o PR #59
inseriu no backend Delphi (issue #51), desta vez no backend FPC — fechando a issue #60.

A entrega compreende quatro edições em dois arquivos Pascal:

- **`Source/ModernSyntax.RTTI.FPC.pas`** recebeu a `resourcestring`
  `SFPCUnknownVisibility` na seção `implementation` (zero símbolo novo na
  interface) e o `else raise EModernRTTIError.CreateFmt(...)` dentro do `case`
  de `PropertyVisibility`, além da reescrita do comentário do procedimento para
  refletir o comportamento medido historicamente (ordinal 229/i386,
  0=`mvPrivate`/x86_64) e a linhagem #51↔#60.
- **`Source/ModernSyntax.RTTI.pas`** teve o XMLDoc de `TModernVisibility`
  (linhas 79–85) reescrito para descrever o comportamento dos dois backends após
  as guardas, com medição no passado e sem afirmação de exaustividade
  compile-time no FPC.

O ramo `else raise` é inalcançável por dado real (valor vem de RTTI real, não
injetável). Nenhum teste novo foi adicionado. O backend Delphi não foi tocado.
A suite FPC 3.2.2 x86_64 permanece em 42/42, 0 erros, 0 falhas.

## Branch e base

- **Branch de trabalho:** `aefos/cycle-4c9ae8e8-maestro-repo-isaquepinheiro-modernsyntax`
- **Base:** `main`

## Veredictos das três lentes de qualidade

| Lente | Nó | Veredicto |
|-------|----|-----------|
| Review | `review` | **APPROVED** — 10/10 critérios ESP; ADR integralmente atendido |
| Test | `test` | **APPROVED** — AC 10/10 PASS; suite 42/42 |
| Verify | `verify` | **PASSED** — compile clean, CCN 5, spec 7/7 |

Detalhes em [REPORT-quality-review](REPORT-quality-review.md),
[REPORT-quality-test](REPORT-quality-test.md) e
[REPORT-quality-verify](REPORT-quality-verify.md).

## Referências do pipeline

- [REPORT-architect](REPORT-architect.md) — decisão de escopo e abordagem
- [REPORT-planner](REPORT-planner.md) — plano de tarefa
- [REPORT-developer](REPORT-developer.md) — implementação e validação local
