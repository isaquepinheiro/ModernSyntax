---
type: cycle-report
kind: report
title: "REPORT planner — ciclo 029 — TModernInvoker.Invoke dinamico cross-compiler"
description: "Planner formalizou a demanda da issue #13 (re-entrada ciclo 028) como task rastreável; board atualizado com estado in-pipeline; GitHub card não movido por ausência de escopo read:project no token."
cycle: "029"
agent: planner
workflow: equipe-feature
node: task
resource: aefos://run/c26861e980aa5045a4f8b7de8b2207c2
generated:
  by: "equipe-feature@node:task"
  at: "2026-09-03T00:00:00Z"
tags: [report, planner, invoker, tvalue, issue-13, cycle-029]
---

# REPORT — Planner — Ciclo 029

## O que foi feito

### 1. Leitura da demanda

O planner leu [pipeline-task-input.md](pipeline-task-input.md) (ciclo 028,
re-entrada via `plan-gate:on_reject`). A demanda é idêntica ao ciclo 028:
entregar o overload dinâmico `TModernInvoker.Invoke(AInstance, AMethodName,
AArgs, AResultType): TValue` com assinatura pública idêntica nos dois
compiladores e backend divergente por `{$IFDEF FPC}`.

### 2. Rastreamento local

- **`project-evolution.md`**: nova linha adicionada para o ciclo 029, issue
  #13, estado `🔄 in-pipeline`. Nota descritiva do ciclo anexada ao bloco de
  notas de rastreamento.
- **`pipeline-task.md`**: metadados atualizados (`cycle: "029"`,
  `resource: aefos://run/c26861e980aa5045a4f8b7de8b2207c2`,
  tags atualizadas para `cycle-029`). Conteúdo da demanda permanece igual
  ao ciclo 028 — sem mudança de escopo.

### 3. GitHub (MAESTRO MODE)

- Modo: **MAESTRO MODE** — issue #13 é a demanda canônica (criada pelo
  maestro como `aefos:investigated`). Nenhuma issue ou Epic adicional criada.
- Tentativa de mover card do board para `in_progress`: **falhou** por ausência
  de escopo `read:project` no token GitHub do ambiente. Registrado em
  FLOW-FEEDBACK.md para ação humana ou correção de configuração.

## Decisões pré-fechadas relevantes (da issue #13)

| ID | Decisão |
|----|---------|
| D-13.1 | Assinatura única, sem `{$IFDEF}` na declaração |
| D-13.3 | Alcance por compilador: FPC `published`; Delphi `public`+`published` |
| D-13.5 | Self como `[0]` da TValueArray no FPC |
| D-13.9/D-13.10 | Mensagens de guarda reusadas do portável #10 |
| D-13.11 | Fixture `TDateAndTag` (Integer+string) exercita ABI divergente |
| D-13.13 | Overload portável `Invoke<TSignature>` byte-por-byte idêntico |

## Referências

- [pipeline-task.md](pipeline-task.md) — task formalizada neste ciclo.
- [pipeline-task-input.md](pipeline-task-input.md) — handoff do arquiteto.
