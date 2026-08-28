---
type: cycle-report
kind: report
title: "Release report — ModernSyntax.Callback (ciclo 004, issue #7)"
description: "Ciclo 004 entregou a unit ModernSyntax.Callback.pas com três interfaces genéricas portáveis, factory Callback e suite de testes DUnitX/FPCUnit; todos os quality gates passaram."
cycle: "004"
agent: release
workflow: equipe-feature
node: closing-record
resource: aefos://run/24c962dcc2be1819336ca1fea18ae949
tags: [release, callbacks, modernrtti, issue-7, cycle-004]
generated:
  by: "equipe-feature@node:closing-record"
  at: "2026-08-28T16:30:00Z"
sources:
  - id: plan
    resource: pipeline-plan.md
    title: "Plan — Callbacks transversais"
  - id: review-report
    resource: pipeline-review-report.md
    title: "Review report — ciclo 004"
  - id: verify-report
    resource: pipeline-verify-report.md
    title: "Verify report — ciclo 004"
---

# Release report — ciclo 004

## O que este ciclo entregou

O ciclo 004 implementou o módulo de callbacks transversais para o
repositório `ModernSyntax` (issue #7). A entrega cobre quatro fatias
planejadas:

- **Unit de produção** `Source/ModernSyntax.Callback.pas` com três
  interfaces genéricas sem GUID (`IModernFunc<T,R>`, `IModernProc<T>`,
  `IModernPredicate<T>`), o factory `Callback` com três sobrecargas
  `&Of` (uma por tipo de método de objeto) e os três wrappers
  (`TFuncOfObjectWrapper`, `TProcOfObjectWrapper`,
  `TPredicateOfObjectWrapper`) declarados na seção `interface` por
  exigência do FPC 3.2.2. A unit usa apenas `SysUtils`, sem
  `{$I ModernSyntax.inc}` e sem o token `FCP`.

- **Unit de cenários compartilhados**
  `Test Shared/EclbrSystem/UTestMS.Callback.Scenarios.pas`, sem
  nenhuma dependência de framework de teste e sem `{$IFDEF}`, contendo
  quatro cenários que levantam exceção em falha.

- **Casca DUnitX** em `Test Delphi/EclbrSystem/`, com `.dproj`
  configurado com o search path para `Test Shared\EclbrSystem`.

- **Casca FPCUnit** em `Test FPC/EclbrSystem/`, com `.lpi` declarando
  dois build modes (`Debug-i386` e `Debug-x86_64`) e apontando para
  `Source/` e `Test Shared/EclbrSystem/` em `<OtherUnitFiles>`.

A divergência formal `Callback.&Of` em lugar de `Callback.Of` foi
necessária e inevitável: `of` é palavra reservada em Pascal (Delphi e
FPC) e o escape com `&` é o mecanismo padrão da linguagem. O ADR D-A3
não previu a colisão; a solução preserva o nome do símbolo.

## Work branch

- **Branch:** `aefos/cycle-24c962dc-maestro-repo-isaquepinheiro-modernsyntax`
- **Base:** `develop`

## Veredictos dos quality gates

| Gate | Veredicto |
|------|-----------|
| review | **APROVADO** — implementação conforme [pipeline-review-report.md](pipeline-review-report.md). Duas observações pré-merge: O-1 (declaração honesta sobre i386 no PR body) e O-2 (`&Of` mencionado no PR). |
| verify | **PASSED** — `Source/ModernSyntax.Callback.pas` compilou sem erros em FPC 3.2.2 x86_64; 4/4 testes FPCUnit x86_64 passaram. i386 e Delphi permanecem com o autor (ppc386 ausente na fábrica). Ver [pipeline-verify-report.md](pipeline-verify-report.md). |
| test | **PASSED** — ver [REPORT-quality-test.md](REPORT-quality-test.md). |

## Nota ao committer / PR body

O PR body deve incluir a declaração honesta recomendada no
[pipeline-review-report.md](pipeline-review-report.md) (observação O-1):

> *"Compilado em FPC 3.2.2 x86_64-linux (4/4 testes passaram). Build
> i386: configurado no .lpi (build mode Debug-i386); ppc386 ausente
> na fábrica — autor valida antes do merge. Não compilado em Delphi —
> Delphi permanece com o autor."*

O merge humano aguarda confirmação do autor sobre i386 e Delphi.
