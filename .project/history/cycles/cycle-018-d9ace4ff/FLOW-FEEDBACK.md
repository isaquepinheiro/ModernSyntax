---
type: flow-feedback
kind: report
title: "FLOW-FEEDBACK — ciclo 018 (issue #45)"
description: "Friccao no pipeline: aefos_gh_move_card exige 'Project number' em .project/SKILL.md e falha; tools que dependem de metadata implicito precisam declarar a chave em algum lugar (SKILL.md agent-discovered ou pipeline node)."
cycle: "018"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/d9ace4ff9a3af56be91a8f0373cb9475
tags: [flow-feedback, pipeline, tooling, gh, project-board]
generated:
  by: "equipe-feature@node:implement"
  at: "2026-09-02T00:00:00Z"
---

# FLOW-FEEDBACK — ciclo 018

## Problema

O prompt do nó `implement` diz:

> Advance the local board: flip this demand's marker appropriately in
> `.project/project-evolution.md`. **If true is true, move the GitHub
> card to the in-progress/review column.**

Ao chamar `mcp__aefos-dynamic-tools__aefos_gh_move_card`
(`issue: 45, status_key: in_review`), o tool falha com:

```
error: 'Project number' not found in .project/SKILL.md
```

O SKILL.md **nao carrega** a chave "Project number" em lugar nenhum
(medido: `grep -n "Project number" .project/SKILL.md` → 0 linhas). O
tool depende de metadata implicito que o repositorio nao publica.

Consequencia: o implementer nao consegue mover o card. O board local
(`.project/project-evolution.md`) foi atualizado; a atualizacao no
ProjectV2 fica pendente (silencio, nao erro visivel para o usuario que
le so o board local).

## Sugestao concreta

Duas opcoes, sem preferencia — o humano decide:

1. **Publicar a chave em `.project/SKILL.md`** — bloco
   "agent-discovered YYYY-MM-DD" com `Project number: <n>` e
   `Project owner: <owner>` (o que o tool le). Cada novo repo que quiser
   usar `aefos_gh_move_card` levanta esses dois campos uma vez.

2. **Passar o project number pelo prompt do node** — o prompt ja carrega
   `resource: aefos://run/<id>`; adicionar `github.project_number: <n>`
   quando o repo tem ProjectV2 ativado e ajustar o tool para aceitar
   parametro explicito (ou fallback a SKILL.md).

Recomendo (1): configuracao vive no proprio bundle do projeto, o tool
fica sem parametro novo, e SKILL.md ja tem convencao "agent-discovered"
para esse tipo de metadata (ver bloco 2026-08-28 sobre FPC).

## Escopo

**Nao modificar o workflow eu mesmo** — este documento sinaliza; um
humano revisa e aplica. O board local ja carrega o estado correto
(🔄 in-review), o que satisfaz a rastreabilidade obrigatoria por
[pipeline-implement-report](pipeline-implement-report.md).
