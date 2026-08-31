---
type: flow-feedback
kind: report
title: "FLOW-FEEDBACK — ciclo 008 — i386 ausente no container"
description: "O container Linux do factory não tem ppc386; CA-5 i386 não verificável pelo nó test."
cycle: "008"
agent: quality
workflow: equipe-feature
node: test
resource: aefos://run/e4baa827945b3dd3a372629b831d73a9
tags: [flow-feedback, fpc, i386, env, cycle-008]
generated:
  by: "equipe-feature@node:test"
  at: "2026-08-31T12:22:00Z"
---

# FLOW-FEEDBACK — ciclo 008

## Problema observado

`CA-5` do [pipeline-esp.md](pipeline-esp.md) exige build FPC verde em **x86_64 E
i386**. O container factory tem `ppcx64-3.2.2` mas não `ppc386`. O build i386 não
pôde ser executado neste ciclo.

## Impacto

- O nó `test` não pôde assinar CA-5 i386. O veredicto foi APROVADO mesmo assim
  porque a limitação é de ambiente, não de qualidade da entrega.
- Se um bug de alinhamento de offset afetar apenas i386, ele não seria detectado
  nesta pipeline.

## Sugestão concreta

Adicionar `ppc386` ao container factory, ou criar um step de CI secundário (job
matrix) que execute o build i386 num runner Windows ou num container separado com
`ppc386` instalado. O SKILL.md já documenta o path Windows; a lacuna está no
container Linux.

Alternativa mais simples: documentar explicitamente no nó `test` que CA-5 i386 é
responsabilidade do autor (alinhado com R2 do PRD, que já delega o lado Delphi).
Se for esse o caso, retirar CA-5 i386 do escopo do pipeline automatizado e mover
para a checklist do PR.
