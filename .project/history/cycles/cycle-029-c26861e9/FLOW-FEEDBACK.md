---
type: flow-feedback
kind: report
title: "FLOW-FEEDBACK ciclo 029 — token GitHub sem escopo read:project"
description: "O token GitHub disponível no ambiente não tem o escopo read:project, impedindo que o planner mova o card do board via aefos_gh_move_card. O tool também requer 'Project number' em SKILL.md, que está ausente."
cycle: "029"
agent: planner
workflow: equipe-feature
node: task
resource: aefos://run/c26861e980aa5045a4f8b7de8b2207c2
generated:
  by: "equipe-feature@node:task"
  at: "2026-09-03T00:00:00Z"
tags: [flow-feedback, github, board, token, cycle-029]
---

# FLOW-FEEDBACK — Ciclo 029

## Problema

Ao tentar mover o card da issue #13 para `in_progress` via
`aefos_gh_move_card`, dois erros ocorreram em sequência:

1. **`aefos_gh_move_card`**: retornou `error: 'Project number' not found
   in .project/SKILL.md`. O campo `Project number` não está declarado em
   `SKILL.md`.

2. **Fallback via `gh project list`**: o token GitHub do ambiente não tem
   os escopos `read:project`, `read:org`, `read:discussion` — a chamada
   falha com `your authentication token is missing required scopes`.

## Impacto

O card do board GitHub não foi movido para `in_progress`. O rastreamento
local (`project-evolution.md`) foi atualizado corretamente como fallback.
O ciclo não foi bloqueado.

## Sugestão de melhoria de workflow

**Opção A** — Adicionar o número do projeto GitHub ao `SKILL.md` (campo
`Project number: <N>`) para que o `aefos_gh_move_card` resolva o board
sem depender de `gh project list`.

**Opção B** — Configurar o token GitHub da factory com os escopos
`read:project` (e `write:project` para mover cards). Isso também
desbloqueia outros nós que eventualmente precisem de operações no board.

**Ação sugerida para humano:** executar manualmente no GitHub o movimento
da issue #13 para a coluna `In Progress` do board, ou adicionar o campo
`Project number` ao `SKILL.md`.
