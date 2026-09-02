---
type: cycle-report
kind: report
title: "REPORT-planner — ciclo 020 (issue #49 nil-handle contract)"
description: "Planner formalizou task.md para o ciclo 020; atualizou project-evolution.md; modo MAESTRO confirmado — issue #49 e a demanda oficial."
cycle: "020"
agent: planner
workflow: equipe-bug
node: task
resource: aefos://run/fd87755097391831d283adc83e6b8813
tags: [report, planner, cycle-020, issue-49, nil-handle, modernrtti]
generated:
  by: "equipe-bug@node:task"
  at: "2026-09-02T00:00:00Z"
---

# REPORT-planner — ciclo 020

## Resumo

O Planner recebeu a demanda via `task-input.md` preparado pelo Arquiteto e
formalizou as tarefas do ciclo 020 no board local e nos artefatos de pipeline.

## Demanda

**Issue GitHub:** [#49](https://github.com/isaquepinheiro/ModernSyntax/issues/49)
— `nil-handle contract for TModernRTTIType`

**Tipo:** `bug`

**Escopo em uma linha:** cinco guardas identicas de nil + resourcestring + XMLDocs
em `ModernSyntax.RTTI.pas`; cenario `Scenario_NilHandle_AllMembers_Raises` + desbloqueio
D-44.6 em `UScenarios.RTTI.pas`; duas cascas de uma linha cada.

## Modo de rastreamento

**MAESTRO MODE** — `has_remote: true`, `from_maestro: true`.

A issue #49 foi criada pelo maestro como `aefos:investigated` e e a demanda
oficial deste ciclo. Nenhuma issue nova foi criada. Nenhum Epic foi criado.

Epic parent nao identificado com certeza; nenhuma ligacao criada para evitar
associacao errada (regra: so ligar a Epic OBVIAMENTE matching ja existente).

## Acoes executadas

1. **`project-evolution.md` atualizado** — nova entrada para ciclo 020, issue #49,
   estado 🔄 in-pipeline.

2. **`pipeline/task.md` escrito** — resumo operacional da tarefa com instrucoes
   criticas, arquivos impactados, traps e checklist de aceitacao; referencia
   [task-input](pipeline-task-input.md).

3. **`REPORT-planner.md` escrito** (este arquivo) — no diretorio do ciclo 020.

## Artefatos referenciados

- [pipeline-task-input.md](pipeline-task-input.md) — briefing operacional do arquiteto
- [pipeline-esp.md](pipeline-esp.md) — especificacao formal
- [pipeline-plan.md](pipeline-plan.md) — plano de implementacao
- [pipeline-adr.md](pipeline-adr.md) — decisoes de arquitetura

## Contexto da demanda

Cinco membros de `TModernRTTIType` (`Name`, `GetProperties`, `GetFields`,
`GetMethods`, `GetMethod`) nao levantam excecao quando `FType = nil` (handle
nao inicializado). O contrato correto e levantar `EModernRTTIError` com
`SModernRTTINilHandle` formatando o nome do membro como `%s`.

Ponto critico: a guarda de `GetFields` deve preceder o `is TRttiInstanceType`
check; records/enums com `FType <> nil` continuam retornando `nil` silenciosamente.

A divida D-44.6 (`Scenario_PointerType_ReferredType_Nil_ForBarePointer` que
tinha comentario "NAO tocar em `LReferred.Name`") e desbloqueada por este ciclo.

## Estado do board ao fechar o no

| Ciclo | Issue | Estado |
|-------|-------|--------|
| 020 | [#49](https://github.com/isaquepinheiro/ModernSyntax/issues/49) | 🔄 in-pipeline |
