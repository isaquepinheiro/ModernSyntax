---
type: task
kind: artifact
title: "Task — Reimplementar Source/ModernSyntax.Callback.pas e testes (ciclo 004)"
description: "Nova iteração após plan-gate:on_reject: criar a unit de callbacks portáveis, a unit comum de cenários e as cascas finas DUnitX/FPCUnit, com os mesmos contratos do ciclo 003 refinados pelo architect."
cycle: "004"
agent: planner
workflow: equipe-feature
node: task
resource: aefos://run/24c962dcc2be1819336ca1fea18ae949
tags: [task, modernrtti, callbacks, issue-7, feature, cycle-004]
generated:
  by: "equipe-feature@node:task"
  at: "2026-08-28T14:00:00Z"
sources:
  - id: task-input
    resource: "task-input.md"
    title: "Task input — Callbacks transversais (handoff do architect, ciclo 004)"
  - id: esp
    resource: "esp.md"
    title: "ESP — Callbacks transversais"
  - id: adr
    resource: "adr.md"
    title: "ADR — Design da unit ModernSyntax.Callback"
  - id: plan
    resource: "plan.md"
    title: "Plan — Callbacks"
---

# Task — Reimplementar Callbacks Transversais (ciclo 004)

**Issue:** [isaquepinheiro/ModernSyntax#7](https://github.com/isaquepinheiro/ModernSyntax/issues/7)
**Rastreamento:** MAESTRO MODE — issue #7 é a demanda oficial; nenhuma issue
ou Epic adicional criada. Card movido para **in_progress** no board GitHub.
**Labels:** `aefos:running`, `feature`
**Origem do ciclo:** `plan-gate:on_reject` — o plano do ciclo 003 foi rejeitado
pelo gate; o architect gerou novo [task-input.md](pipeline-task-input.md) para esta iteração.

## Briefing

Criar `Source/ModernSyntax.Callback.pas` com três interfaces genéricas sem
GUID (`IModernFunc<T,R>`, `IModernProc<T>`, `IModernPredicate<T>`) e o
factory `Callback` com três sobrecargas `Of` para método de objeto. A unit
usa apenas `SysUtils` e contém `{$IFDEF FPC}` direto — sem
`{$I ModernSyntax.inc}`. Compilação idêntica em Delphi e FPC 3.2.2.

**Divergência declarada:** nomes de interface divergem do texto original da
issue #7 (`IMSFunc` → `IModernFunc`, etc.). Decisão sustentada pelo padrão
vivo do repositório (`IModern*`) — ver [adr.md](pipeline-adr.md) D-A9.

## Artefatos a criar

Conforme [task-input.md](pipeline-task-input.md):

1. `Source/ModernSyntax.Callback.pas` — unit principal (nova)
2. `Test Shared/EclbrSystem/UTestMS.Callback.Scenarios.pas` — cenários
   sem framework (diretório novo)
3. `Test Delphi/EclbrSystem/UTestMS.Callback.pas` — casca DUnitX (nova)
4. `Test Delphi/EclbrSystem/PTestModernCallback.dpr` + `.dproj` + `.res`
5. `Test FPC/EclbrSystem/UTestMS.Callback.pas` — casca FPCUnit (nova,
   diretório novo)
6. `Test FPC/EclbrSystem/PTestModernCallback.lpr` + `.lpi`

## Checklist de aceite (resumido)

Conforme [task-input.md](pipeline-task-input.md):

- [ ] `Source/ModernSyntax.Callback.pas`: somente `SysUtils` na `uses`
- [ ] Três interfaces genéricas sem GUID (D-A2 do adr)
- [ ] Factory `Callback` com três sobrecargas `Of` — somente método de objeto
- [ ] Sem `{$I ModernSyntax.inc}` nem token `FCP` (D-A5/D-A11 do adr)
- [ ] Wrappers declarados na seção `interface`, não na `implementation` (D-A13)
- [ ] `UTestMS.Callback.Scenarios.pas` sem framework, sem `{$IFDEF}`
- [ ] Casca DUnitX com até uma linha útil por método (D-A7 do adr)
- [ ] `.dproj` inclui `..\..\Test Shared\EclbrSystem` em search path
- [ ] Casca FPCUnit com `RegisterTest` no `initialization`
- [ ] `.lpi` com dois build modes (`Debug-i386`, `Debug-x86_64`)
- [ ] Body do PR declara compilação em FPC 3.2.2 x86_64 e i386 (CA-7 do esp)

## Modo de rastreamento

MAESTRO MODE (from_maestro: true). A issue #7 preexiste como intake do
maestro. Card movido para `in_progress` no board. Entrada do ciclo 004
registrada em [project-evolution.md](../../../project-evolution.md) com marcador 🔄 in-pipeline.
