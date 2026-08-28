---
type: task
kind: artifact
title: "Task — Pilar 1 da ModernRTTI (cycle 004, issue #8)"
description: "Criar Source/ModernSyntax.RTTI.pas com TModernRTTI, cenários compartilhados e cascas de teste DUnitX + FPCUnit."
cycle: "004"
agent: planner
workflow: equipe-feature
node: task
resource: aefos://run/9a5f8b9e974c23d88b7b6aba11e2973d
tags: [task, modernrtti, rtti, pilar-1, issue-8, feature, cycle-004]
generated:
  by: "equipe-feature@node:task"
  at: "2026-08-28T13:40:00Z"
sources:
  - id: task-input
    resource: "task-input.md"
    title: "Task Input — Pilar 1 da ModernRTTI"
  - id: esp
    resource: "esp.md"
    title: "ESP — Pilar 1 da ModernRTTI"
  - id: plan
    resource: "plan.md"
    title: "Plan — Pilar 1 da ModernRTTI"
  - id: adr
    resource: "adr.md"
    title: "ADR — Design da unit ModernSyntax.RTTI"
---

# Task — Pilar 1 da ModernRTTI (cycle 004)

## Rastreamento

**Modo:** MAESTRO MODE — issue GitHub já existe.
**Issue de demanda:** [isaquepinheiro/ModernSyntax#8](https://github.com/isaquepinheiro/ModernSyntax/issues/8)
**Labels:** `aefos:running`, `feature`
**Board:** 🔄 in-pipeline (ver [project-evolution.md](../../../project-evolution.md))
**Nenhuma** nova issue ou Epic criada (MAESTRO MODE — não duplicar).

## Objetivo

Criar `Source/ModernSyntax.RTTI.pas` (Pilar 1 da ModernRTTI) com API
idêntica em Delphi e FPC 3.2.2, incluindo detecção obrigatória de `{$M+}`
ausente no FPC, cenários compartilhados framework-agnósticos, e cascas
finas de teste para os dois compiladores.

## Contexto do ciclo

Este ciclo retoma a issue #8 após o PR #11 ter sido fechado sem merge no
ciclo 002 (unit criada importava DUnitX no lado FPC, que não existe no
FPC 3.2.2). A decisão vigente (D-A7 do [adr](pipeline-adr.md)) é usar FPCUnit no
lado FPC e DUnitX no lado Delphi, unificando a lógica nos cenários
compartilhados.

A issue #7 (ciclo 003) cria a infra FPC (`Test FPC/EclbrSystem/`,
`Test Shared/EclbrSystem/`, `.lpi` FPCUnit). Este ciclo assume que ela
mergeou. Caso contrário, o PR declara o bloqueio explicitamente (ver
[task-input.md](pipeline-task-input.md) §"Dependência declarada").

## Fatias de entrega (ordem de implementação)

1. `Source/ModernSyntax.RTTI.pas` — unit de produção.
2. `Test Shared/EclbrSystem/UScenarios.RTTI.pas` — cenários sem framework.
3. `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` — casca fina DUnitX.
4. `Test Delphi/EclbrSystem/PTestRTTI.dpr` + `.dproj` + groupproj/DCC.bat.
5. `Test FPC/EclbrSystem/UTestMS.RTTI.pas` + registro no `.lpi` da #7.

## Restrições críticas

- `uses` da unit nova: **`Rtti, TypInfo, SysUtils`** — exatamente essas três.
- `{$I ModernSyntax.inc}` e o token `FCP` estão proibidos na unit nova.
- Ramificação FPC/Delphi via `{$IFDEF FPC}` direto no arquivo.
- `{$IFDEF}` proibido nos cenários compartilhados e nas cascas.
- Não tocar em `Source/ModernSyntax.Objects.pas`, `.inc`, `.Std.pas`,
  `.DotEnv.pas` nem em testes existentes.

## Referências

- [task-input.md](pipeline-task-input.md) — briefing completo com checklist de aceite
- [esp.md](pipeline-esp.md) — especificação e critérios de aceite (CA-1…CA-10)
- [plan.md](pipeline-plan.md) — plano de implementação passo a passo
- [adr.md](pipeline-adr.md) — decisões de design (D-1…D-11)
