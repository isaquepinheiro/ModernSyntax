---
type: flow-feedback
kind: report
title: "FLOW-FEEDBACK — Ciclo 004: SKILL.md ausente e token sem read:project"
description: "Dois bloqueios de infraestrutura impediram o planner de mover o card GitHub: SKILL.md não existe no bundle e o token não tem scope read:project."
cycle: "004"
agent: planner
workflow: equipe-feature
node: task
resource: aefos://run/24c962dcc2be1819336ca1fea18ae949
generated:
  by: "equipe-feature@node:task"
  at: "2026-08-28T14:00:00Z"
tags: [flow-feedback, infrastructure, github, skill-md, token-scope]
---

# FLOW-FEEDBACK — Ciclo 004

## Problema 1 — `.project/SKILL.md` ausente

**O que aconteceu:** `aefos_gh_move_card` (e `aefos_gh_find_item_id`)
terminaram imediatamente com `error: .project/SKILL.md not found`. O arquivo
não existe em `.project/`.

**Impacto:** todo nó do pipeline que precisa mover cards no GitHub ProjectV2
fica bloqueado silenciosamente; o fallback via `gh` CLI é inevitável e também
pode falhar (ver Problema 2).

**Sugestão:** o nó de inicialização do pipeline (ou o maestro, no intake)
deve verificar a existência de `.project/SKILL.md` e criar / atualizar o
arquivo com os IDs do projeto antes de chamar qualquer nó que use as
ferramentas `aefos_gh_*`. Alternativamente, as ferramentas devem aceitar os
IDs por parâmetro direto como fallback quando `SKILL.md` não existe.

---

## Problema 2 — token GitHub sem scope `read:project`

**O que aconteceu:** após a falha do Problema 1, o planner tentou mover o
card via `gh api graphql`. A API retornou `INSUFFICIENT_SCOPES`: o token
possui `read:user`, `repo`, `workflow` mas NÃO `read:project`.

**Impacto:** qualquer operação de board ProjectV2 via CLI também falha.

**Sugestão:** documentar nos pré-requisitos do pipeline que o token
configurado em `GITHUB_TOKEN` (ou equivalente) deve incluir o scope
`read:project` (e `project` para escrita). Adicionar verificação no nó de
setup ou no maestro que valide os scopes antes de iniciar o ciclo.

---

## Ação manual necessária (ciclo 004)

Mover manualmente o card da issue #7 para a coluna **In Progress** no board
do repositório `isaquepinheiro/ModernSyntax`.
