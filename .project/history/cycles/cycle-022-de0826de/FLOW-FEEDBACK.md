---
type: flow-feedback
kind: report
title: "FLOW-FEEDBACK — ciclo 022 — skill architecture-design nao encontrada"
description: "O no architect invoca a skill architecture-design mas ela nao existe no harness; retorna erro e o fluxo continua sem o metodo e templates prometidos."
cycle: "022"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/de0826deb51365cb442a8acd3e0fd103
generated:
  by: "equipe-bug@node:architect"
  at: "2026-09-02T00:00:00Z"
---

# FLOW-FEEDBACK — ciclo 022

## Problema

O prompt do no `architect` instrui: "The 'architecture-design' skill carries
your full method and templates." O harness, ao invocar essa skill, retorna
`Unknown skill: architecture-design`. A skill nao esta registrada.

Consequencia: o no prosseguiu sem o metodo e os templates prometidos,
produzindo os artefatos com base no contexto do projeto e nas convencoes OKF
ja conhecidas. O resultado e funcionalmente correto (os 4 artefatos foram
escritos), mas o no dependeu de conhecimento interno ao modelo em vez do
metodo explicitamente referenciado pelo workflow.

## Sugestao

Registrar a skill `architecture-design` no harness (ou remover a referencia
do prompt se a skill foi descontinuada). Se os templates relevantes estao
em outro lugar (ex.: documento no `.project/`), atualizar o prompt do no
para apontar o caminho correto.

---

## Problema 2 — skill `quality-review` nao encontrada (no review)

O prompt do no `review` instrui: "The 'quality-review' skill carries your full
method and templates." O harness, ao invocar essa skill no no review, retorna
`Unknown skill: quality-review`. A skill nao esta registrada.

Consequencia: o no prosseguiu sem o metodo e os templates prometidos,
executando a revisao com base no contexto do projeto e nas convencoes OKF
ja conhecidas. O resultado e funcionalmente correto (todos os artefatos foram
escritos e o veredicto foi produzido), mas o no dependeu de conhecimento
interno ao modelo em vez do metodo explicitamente referenciado pelo workflow.

Este e o mesmo padrao do problema 1 (`architecture-design`): multiplos nos
referenciam skills que nao existem no harness.

## Sugestao 2

Auditar todos os nos do workflow `equipe-bug` e listar as skills referenciadas
nos prompts. Registrar as que nao existem ou removê-las/substituí-las por
referencias a documentos no `.project/` que carreguem os mesmos templates.
