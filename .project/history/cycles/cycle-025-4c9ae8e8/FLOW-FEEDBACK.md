---
type: flow-feedback
kind: report
title: "FLOW-FEEDBACK — ciclo 025, node task"
description: "Atrito no move de card do board GitHub: project number ausente em SKILL.md impede aefos_gh_move_card."
cycle: "025"
agent: planner
workflow: equipe-bug
node: task
resource: aefos://run/4c9ae8e8f3b0ca77a166f343e7d3f098
generated:
  by: "equipe-bug@node:task"
  at: "2026-09-02T00:00:00Z"
tags: [flow-feedback, cycle-025, github, board]
---

# FLOW-FEEDBACK — ciclo 025 / node task

## Problema

`aefos_gh_move_card` retornou `error: 'Project number' not found in .project/SKILL.md`
ao tentar mover o card da issue #60 para `in_progress`. A ferramenta depende de um
campo de número de projeto configurado no `SKILL.md`, que aparentemente está ausente
ou usa um nome de campo diferente do esperado.

O estado do ciclo não foi comprometido — a issue #60 já carregava o label
`aefos:running` no GitHub, e o board local (`project-evolution.md`) foi atualizado
corretamente com `🔄 in-pipeline`.

## Sugestão de mudança no workflow

1. **Verificar e popular o campo de project number em `.project/SKILL.md`** com o ID
   numérico do ProjectV2 do repositório `isaquepinheiro/ModernSyntax`, para que
   `aefos_gh_move_card` funcione sem erro.
2. **Alternativa**: se o project number variar por workspace, considerar torná-lo um
   parâmetro do workflow injetado em runtime em vez de um campo estático em SKILL.md.
3. **Fallback no nó task**: se `aefos_gh_move_card` falhar com erro de configuração,
   o workflow poderia tentar `gh project item-edit` via CLI como fallback, em vez de
   silenciar o erro.
