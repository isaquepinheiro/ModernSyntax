---
type: flow-feedback
kind: report
title: "FLOW-FEEDBACK — Ciclo 012 / nó review: skill 'review' invoca template de PR review em vez de método AEFOS"
description: "O harness invocou a skill 'review' no início do nó quality, carregando um template de revisão de PR do GitHub em vez do método de revisão de qualidade AEFOS. Fricção leve; não bloqueou o ciclo."
cycle: "012"
agent: quality
workflow: equipe-feature
node: review
resource: aefos://run/d3f7942e59d0ba69094d93420fef84db
tags: [flow-feedback, cycle-012, pipeline-improvement]
generated:
  by: "equipe-feature@node:review"
  at: "2026-08-31T00:00:00Z"
---

# FLOW-FEEDBACK — Ciclo 012 / nó review

## Problema observado

O harness invocou a Skill `review` no início da execução do nó `review`.
Essa skill carrega um template de **revisão de PR do GitHub** (executando
`gh pr list` / `gh pr diff`), que não é o método de revisão de qualidade
AEFOS.

O método real do nó (`quality-review` no system prompt) descreve o processo
correto: ler o diff do ciclo (`git diff main...HEAD`), revisar contra
`esp.md`/`adr.md`/`SKILL.md`, escrever `review-report.md` e
`REPORT-quality-review.md`. A skill genérica de PR review sobrepôs esse
fluxo por um momento antes de ser ignorada.

O nó conseguiu proceder corretamente porque o system prompt do agente
contém o método completo — a skill foi descartada como irrelevante e o
review real foi executado a partir das instruções do prompt. **Não houve
impacto no resultado**, mas a fricção acrescentou latência e um bloco de
output irrelevante.

## Causa raiz

A Skill `review` registrada no harness tem o mesmo nome curto que o nó
`review` do pipeline. A lógica de invocação automática de skills pode estar
acionando matches por nome de nó sem verificar se a skill é do contexto
correto.

## Sugestão de melhoria

1. **Renomear a skill de PR review** para `gh-pr-review` ou `pr-review`,
   evitando colisão com o nome do nó `review` no pipeline.
2. **Alternativamente**, adicionar no prompt do nó `review` uma instrução
   explícita: `DO NOT invoke the 'review' skill — it is a GitHub PR review
   tool, not the AEFOS quality method.`
3. **Não modificar o workflow** — apenas a nomenclatura da skill ou a
   instrução de guarda no prompt do nó.

O item 2 é a mudança mais barata e mais imediata; o item 1 é a correção
estrutural.
