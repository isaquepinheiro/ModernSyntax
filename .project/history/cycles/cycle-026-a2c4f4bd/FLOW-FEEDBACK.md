---
type: flow-feedback
kind: report
title: "FLOW-FEEDBACK — Ciclo 026"
description: "Skill architecture-design nao encontrada; arquiteto operou sem o template de metodo."
cycle: "026"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/a2c4f4bd7a43e634bf43104b21a56468
generated:
  by: "equipe-bug@node:architect"
  at: "2026-09-02T00:00:00Z"
tags: [flow-feedback, architect, cycle-026]
---

# FLOW-FEEDBACK — Ciclo 026

## Problema

O system prompt do nó `architect` referencia a skill `architecture-design`
como portadora do "método completo e templates" do arquiteto. Ao tentar
invocá-la, o harness retornou `Unknown skill: architecture-design`.

O ciclo foi concluído com sucesso (os quatro artefatos foram produzidos com
base na memória do bundle e nos exemplos dos ciclos anteriores), mas o arquiteto
operou sem o scaffold formal que a skill deveria fornecer.

## Impacto

Baixo neste ciclo — a demanda era pequena (correção documental) e os artefatos
de ciclos anteriores em `.project/history/cycles/` forneceram exemplos suficientes
de formato e frontmatter. Em demandas maiores ou com arquitetos sem acesso ao
histórico completo, a ausência do template pode levar a artefatos incompletos ou
fora do padrão OKF.

## Sugestão de mudança no workflow

Registrar `architecture-design` como skill disponível no harness, ou remover a
referência do system prompt do nó `architect` e substituí-la por um link direto
ao template em `.project/` (e.g., um arquivo `pipeline/ARCHITECT-TEMPLATE.md`
que o nó lê explicitamente antes de escrever os artefatos). A segunda opção é
mais robusta — não depende de skill registration e fica auditável no bundle.
