---
type: task
kind: artifact
title: "Task — Implementar Source/ModernSyntax.RTTI.pas (Pilar 1)"
description: "Formaliza a demanda do ciclo 002 como tarefa rastreavel: criar a unit de leitura de RTTI, wrappers, deteccao FPC de {$M+} ausente, testes DUnitX e projeto Lazarus."
cycle: "002"
agent: planner
workflow: equipe-feature
node: task
resource: aefos://run/fa369bfebcbab23d74f445cede226eb0
tags: [task, modernrtti, pilar-1, issue-8, feature, cycle-002]
generated:
  by: "equipe-feature@node:task"
  at: "2026-08-28T01:00:00Z"
sources:
  - id: task-input
    resource: "task-input.md"
    title: "Task input — Pilar 1 (handoff do architect)"
  - id: plan
    resource: "plan.md"
    title: "Plan — tres fatias de implementacao"
  - id: esp
    resource: "esp.md"
    title: "ESP — Pilar 1 da ModernRTTI"
---

# Task — Implementar Pilar 1 da ModernRTTI

**Issue:** [isaquepinheiro/ModernSyntax#8](https://github.com/isaquepinheiro/ModernSyntax/issues/8)
**Rastreamento:** MAESTRO MODE — issue #8 é a demanda oficial deste ciclo;
nenhuma issue ou Epic adicional criada.
**Labels:** `aefos:running`, `feature`

## Briefing

Criar `Source/ModernSyntax.RTTI.pas` expondo uma API unificada de leitura
de RTTI que funcione identicamente no Delphi e no FPC 3.2.2, com deteccao
ativa de ausencia de `{$M+}` no FPC (nunca devolve lista vazia silenciosa).

## Fatias de implementacao

Conforme [plan.md](pipeline-plan.md):

1. **Fatia 1** — Unit + tipos base + `GetProperties` com deteccao FPC
   - `Source/ModernSyntax.RTTI.pas` (novo)
   - `EModernRTTIError`, `TModernRTTIType`, `TModernRTTIProperty`, `ModernRTTI`
   - `{$IFDEF FPC}` direto, sem `{$I ModernSyntax.inc}` (CA-3)

2. **Fatia 2** — `GetFields`
   - Mesma unit; adiciona `GetFields`/`GetField(Name)` e `TModernRTTIField`

3. **Fatia 3** — Testes DUnitX + projeto FPC
   - `Test Delphi/EclbrSystem/UTestMS.RTTI.pas`
   - `Test Delphi/EclbrSystem/PTestModernRTTI.dpr` (+ `.dproj`, `.res`)
   - Projeto Lazarus: reusa `.lpi` da issue #7 se existir; cria minimo se nao

## Checklist de aceite (resumido)

Conforme [task-input.md](pipeline-task-input.md):

- [ ] `Source/ModernSyntax.RTTI.pas` criado, sem `{$I ModernSyntax.inc}`
- [ ] `ModernRTTI.GetType(T).GetProperties` funciona em Delphi e FPC com a mesma chamada
- [ ] FPC sem `{$M+}` gera `EModernRTTIError` (nunca lista vazia silenciosa)
- [ ] Nenhum `{$IFDEF FPC}` nos arquivos de teste/consumidor
- [ ] Suite DUnitX: 1 teste positivo property, 1 positivo field, 1 negativo
- [ ] Projeto Lazarus presente e listando `UTestMS.RTTI.pas`
- [ ] Body do PR declara compilacao em FPC 3.2.2 x86_64 e i386

## Modo de rastreamento

MAESTRO MODE (from_maestro: true). A issue #8 preexiste como intake do
maestro. A entrada no board de estado esta em
[project-evolution.md](../../../project-evolution.md) marcada como 🔄 in-pipeline.
