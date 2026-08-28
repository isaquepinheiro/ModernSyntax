---
type: task
kind: artifact
title: "Task — Implementar ModernSyntax.Attributes.pas e cascas de teste (issue #9)"
description: "Criar unit de atributos portáveis com registry, fusão nativo/registrado (regra 2 do ADENDO), unit de cenários compartilhados e cascas finas DUnitX e FPCUnit."
status: draft
cycle: "004"
agent: planner
workflow: equipe-feature
node: task
resource: aefos://run/e936cbe6a17a8e76ec8ca9a02ec30735
tags: [task, modernrtti, attributes, issue-9, feature, cycle-004]
generated:
  by: "equipe-feature@node:task"
  at: "2026-08-28T14:00:00Z"
sources:
  - id: task-input
    resource: "task-input.md"
    title: "Task input — handoff do arquiteto"
  - id: esp
    resource: "esp.md"
    title: "ESP — Atributos portáveis"
  - id: adr
    resource: "adr.md"
    title: "ADR — Design da unit ModernSyntax.Attributes"
  - id: plan
    resource: "plan.md"
    title: "Plan — Atributos"
---

# Task — Atributos portáveis (issue #9, ciclo 004)

**Issue:** [isaquepinheiro/ModernSyntax#9](https://github.com/isaquepinheiro/ModernSyntax/issues/9)
**Rastreamento:** MAESTRO MODE — issue #9 é a demanda oficial deste ciclo;
nenhuma issue ou Epic adicional criada.
**Labels:** `aefos:running`, `feature`

## Briefing

Implementar o Pilar 2 do ModernSyntax: **atributos portáveis** entre Delphi e FPC.

A entrega central é `Source/ModernSyntax.Attributes.pas`, que expõe:

- `TModernAttribute` — classe-base obrigatória para atributos portáveis (herda de
  `TCustomAttribute` no Delphi, de `TObject` no FPC).
- `ModernAttributes` — record com duas class functions estáticas:
  - `Register(AClass, AInstances)` — adiciona instâncias ao registry com dedup por identidade.
  - `GetAttributes(AClass)` — retorna vista emprestada: `Owned` + `Native` filtrado
    pela **regra 2 do ADENDO** (instância nativa descartada se `Owned` já contém
    instância da mesma classe). FPC retorna apenas `Owned`.

**Divergências declaradas:** CA-2 na letra (`ModernRTTI.GetType(T).GetAttributes`) não é
entregue aqui — é ordem de entrega: esta issue entrega implementação; issue #8 entregará
a fachada. Declarar explicitamente no body do PR.

## Artefatos a criar

Conforme [task-input.md](pipeline-task-input.md):

1. `Source/ModernSyntax.Attributes.pas` — unit principal (nova)
2. `Test Shared/EclbrSystem/UTestMS.Attributes.Symbols.inc` — símbolos de compilação
3. `Test Shared/EclbrSystem/UTestMS.Attributes.Scenarios.pas` — cenários sem framework
4. `Test Delphi/EclbrSystem/UTestMS.Attributes.pas` — casca DUnitX (nova)
5. `Test Delphi/EclbrSystem/PTestAttributes.dpr` + `.dproj` + `.res`
6. `Test FPC/EclbrSystem/UTestMS.Attributes.pas` — casca FPCUnit (nova)
7. `Test FPC/EclbrSystem/PTestAttributes.lpr` + `.lpi`

## Checklist de aceite (resumido)

Conforme [task-input.md](pipeline-task-input.md):

- [ ] `TModernAttribute`: base em `TObject` (FPC) / `TCustomAttribute` (Delphi)
- [ ] `TAttributeRecord = record Owned: TArray<TObject>; end;` na interface
- [ ] Registry: `TDictionary<TClass, TAttributeRecord>` com `TCriticalSection`
- [ ] `TRttiContext` próprio da unit, criado na `initialization` / liberado na `finalization` (Delphi)
- [ ] `Register`: append com dedup por identidade de referência
- [ ] `GetAttributes` Delphi: `Owned + Native` com regra 2 do ADENDO aplicada
- [ ] `GetAttributes` FPC: cópia de `Owned` ou array vazio
- [ ] `finalization`: libera `Owned`, depois `FRegistry`, `FLock`, `FContext` (Delphi)
- [ ] Sem `{$I ModernSyntax.inc}` e sem token `FCP` na unit de produção
- [ ] Cenários sem `{$IFDEF}`, sem import de framework de teste
- [ ] Cascas com no máximo uma linha útil por método
- [ ] `.dproj` inclui `Test Shared/EclbrSystem` em search path
- [ ] `.lpi` com dois build modes (`Debug-i386`, `Debug-x86_64`)
- [ ] Body do PR carrega as três declarações mandatórias

## Não tocar neste ciclo

- `Source/ModernSyntax.RTTI.pas` — entregável da issue #8
- `Source/ModernSyntax.Objects.pas` — evitar acoplamento
- `Source/ModernSyntax.inc` — bug `FCP` fica para outra linha
- `Test Delphi/EclbrSystem/DCC.bat` — gap pós-entrega conhecido
- Nenhuma unit de `Source/` existente é modificada

## Modo de rastreamento

MAESTRO MODE (from_maestro: true). A issue #9 preexiste como intake do
maestro (`aefos:investigated` → `aefos:running`). A entrada no board de estado está em
[project-evolution.md](../../../project-evolution.md) marcada como 🔄 in-pipeline.
