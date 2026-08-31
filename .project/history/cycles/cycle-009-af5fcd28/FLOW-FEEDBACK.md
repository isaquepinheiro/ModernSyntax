---
type: flow-feedback
kind: report
title: "FLOW-FEEDBACK — cycle 009 board-card move failure"
description: "aefos_gh_move_card falha silenciosamente quando o número do projeto não está em SKILL.md e o token não tem escopo read:project."
cycle: "009"
agent: planner
workflow: equipe-feature
node: task
resource: aefos://run/af5fcd28da98e98892fbe66e544b6b5c
tags: [flow-feedback, cycle-009, board, github]
generated:
  by: "equipe-feature@node:task"
  at: "2026-08-31T00:00:00Z"
---

# FLOW-FEEDBACK — cycle 009

## Problema

A tool `aefos_gh_move_card` retornou `error: 'Project number' not found in
.project/SKILL.md`. A tentativa de consulta via GraphQL do GitHub falhou
porque o token tem apenas os escopos `read:user`, `repo`, `workflow` — sem
`read:project`. O card da issue #25 não foi movido para `in_progress` no
board ProjectV2.

## Impacto

Nenhum no artefato — o board local em `project-evolution.md` está correto.
O board GitHub diverge do estado real do ciclo até movimentação manual.

## Sugestão de melhoria de workflow

**Opção A (preferida):** adicionar o número do projeto GitHub em
`.project/SKILL.md` sob uma chave padronizada (ex.: `github_project_number:
<N>`), de modo que `aefos_gh_move_card` não precise de escopo GraphQL para
descobri-lo.

**Opção B:** expandir o escopo do token para incluir `read:project` e
`write:project` — habilita a movimentação mas amplia a superfície de
permissões.

**Opção C (mínima):** o nó `task` pode verificar se a movimentação é possível
antes de tentar, e emitir apenas um warning no relatório em vez de deixar o
estado implicitamente pendente.

## Ação esperada do humano

Adicionar `github_project_number: <N>` em `.project/SKILL.md` (ou autorizar o
escopo) antes do próximo ciclo que precise mover cards.
