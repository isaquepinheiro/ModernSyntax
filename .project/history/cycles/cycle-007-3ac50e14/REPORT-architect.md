---
type: cycle-report
kind: report
title: "REPORT-architect — Ciclo 007 (issue #23): renomear variáveis locais em ModernSyntax.Invoker"
description: "Ciclo de chore trivial: 4 variáveis locais renomeadas para conformidade com a convenção L+PascalCase; uma fatia, sem ADR novo, sem alteração de API."
status: stable
cycle: "007"
agent: architect
workflow: equipe-chore
node: architect
resource: aefos://run/3ac50e14ab113cabde9efa632dc2fccf
tags: [architect, report, chore, naming-convention, invoker, modernrtti, issue-23]
generated:
  by: "equipe-chore@node:architect"
  at: "2026-08-28T00:00:00Z"
---

# REPORT-architect — Ciclo 007 (issue #23)

## Demanda

Issue #23 do repositório `isaquepinheiro/ModernSyntax`: `ModernSyntax.Invoker`
declara variáveis locais (`addr`, `m`) fora da convenção `L`+PascalCase
do projeto. É o único desvio entre as quatro units novas da ModernRTTI.

## Decisões de design

### Sem nova decisão arquitetural (D-1)

A convenção `L`+PascalCase para locais está documentada e medida em
[05-conventions](/analysis/05-conventions.md) §1.3. A correção é
mecânica: `addr` → `LAddress`, `m` → `LMethod` nos dois overloads de
`Invoke<TSignature>` (linhas ~75-77 e ~95-97 de
`Source/ModernSyntax.Invoker.pas`).

### Lacuna de processo registrada (D-2)

O ADR do ciclo do Pilar 3 não mencionou a convenção de prefixos — ao
contrário dos três outros ciclos da ModernRTTI. Nenhuma das três lentes
de qualidade (review, verify, test) capturou o desvio. O fato está
registrado no [adr](pipeline-adr.md) e em [FLOW-FEEDBACK](FLOW-FEEDBACK.md).

## Artefatos produzidos

| Artefato | Descrição |
|---|---|
| [esp](pipeline-esp.md) | Especificação formal do chore |
| [adr](pipeline-adr.md) | Registra ausência de nova decisão + lacuna de processo |
| [plan](pipeline-plan.md) | Uma fatia única (rename + verify) |
| [task-input](pipeline-task-input.md) | Handoff operacional para o implementador |

## Escopo

`fits` — mudança de nomeação em um único arquivo, sem impacto em API,
testes ou outros módulos.

## Observações

- Compilação Delphi permanece com o autor humano; fábrica valida apenas
  FPC 3.2.2 x86_64.
- A lacuna de processo (convenção de prefixos ausente do checklist de
  `verify`) deve ser tratada em issue separada de processo.
