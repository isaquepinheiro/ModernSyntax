---
type: task
kind: artifact
title: "Task — Implementar TModernInvoker (issue #10)"
description: "Criar ModernSyntax.Invoker.pas com TModernInvoker (record, dois overloads Invoke<TSignature> sobre MethodAddress), unit compartilhada de sete cenários e cascas finas DUnitX + FPCUnit."
cycle: "005"
agent: planner
workflow: equipe-feature
node: task
resource: aefos://run/2ef372d993ff75b8dcd8c707bb79d636
tags: [task, modernrtti, invoker, issue-10, feature, cycle-005]
generated:
  by: "equipe-feature@node:task"
  at: "2026-08-28T14:20:00Z"
sources:
  - id: task-input
    resource: "task-input.md"
    title: "Task input — handoff do arquiteto"
  - id: esp
    resource: "esp.md"
    title: "ESP — TModernInvoker"
  - id: adr
    resource: "adr.md"
    title: "ADR — Design da unit ModernSyntax.Invoker"
  - id: plan
    resource: "plan.md"
    title: "Plan — TModernInvoker"
---

# Task — TModernInvoker (issue #10, ciclo 005)

**Issue:** [isaquepinheiro/ModernSyntax#10](https://github.com/isaquepinheiro/ModernSyntax/issues/10)
**Rastreamento:** MAESTRO MODE — issue #10 é a demanda oficial deste ciclo;
nenhuma issue ou Epic adicional criada.
**Labels:** `aefos:running`, `feature`

## Briefing

O Pilar 3 do PRD exige a mesma chamada de método nos dois compiladores (CA-3).
A investigação de volta 1 mediu que `TRttiContext.GetType(...).GetMethods`
retorna 0 no FPC 3.2.2 x86_64 mesmo com `{$M+}` e `published`. O mecanismo
escolhido é `TObject.MethodAddress`, símbolo comum a Delphi e FPC com a
mesma assinatura.

A entrega central é `Source/ModernSyntax.Invoker.pas`, que expõe:

- `TModernInvoker` — `record` com dois `class function Invoke<TSignature>`:
  - `Invoke<TSignature>(AInstance: TObject; AMethodName: string): TSignature;`
  - `Invoke<TSignature>(AClass: TClass; AMethodName: string): TSignature;`
- Guarda `SizeOf(TSignature) <> SizeOf(TMethod)` como **primeira linha** de cada corpo.
- Guarda de `nil` imediatamente depois.
- Mensagem de "não encontrado" cita explicitamente `{$M+}` e `published`.

**Divergências declaradas:** API dinâmica no padrão da RTTI nova do Delphi
(`GetType(T).GetMethod('X').Invoke(obj,[args]): TValue`) não é entregue — fica
para issue irmã futura (ver [adr.md](pipeline-adr.md) D-A9). Declarar no body do PR.

## Artefatos a criar

Conforme [task-input.md](pipeline-task-input.md):

1. `Source/ModernSyntax.Invoker.pas` — unit de produção (nova)
2. `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas` — cenários sem framework de teste
3. `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` — casca DUnitX (nova)
4. `Test Delphi/EclbrSystem/PTestInvoker.dpr` + `.dproj` — projeto Delphi (novo)
5. `Test FPC/EclbrSystem/UTestMS.Invoker.pas` — casca FPCUnit (nova)
6. `Test FPC/EclbrSystem/PTestInvoker.lpr` + `.lpi` — projeto FPC (novo)

## Checklist de aceite (resumido)

Conforme [task-input.md](pipeline-task-input.md) — lista completa lá:

- [ ] `TModernInvoker`: dois overloads `Invoke<TSignature>`; `uses SysUtils` apenas.
- [ ] Zero `{$IFDEF FPC}`, zero `{$I ModernSyntax.inc}`, zero token `FCP`.
- [ ] Guarda `SizeOf` é primeira linha; guarda `nil` é segunda.
- [ ] Mensagem de "não encontrado" cita `{$M+}` e `published`.
- [ ] 7 cenários em `UTestMS.Invoker.Cases.pas`; sem import de framework.
- [ ] Cascas com no máximo uma linha útil por método de teste.
- [ ] `.dproj` baseia-se em `PTestObjects.dproj`; `.lpi` com dois build modes.
- [ ] Greps de aceitação retornam 0.
- [ ] Body do PR carrega as quatro declarações mandatórias.

## Não tocar neste ciclo

- `Source/ModernSyntax.Objects.pas` — D5 do PRD.
- `Source/ModernSyntax.RTTI.pas` — issue #8.
- `Source/ModernSyntax.Attributes.pas` — issue #9.
- `Source/ModernSyntax.inc` — R3 do PRD.
- `Test Delphi/EclbrSystem/DCC.bat` e `TestMSGroup.groupproj` — passo manual pós-entrega.

## Modo de rastreamento

MAESTRO MODE (from_maestro: true). A issue #10 preexiste como intake do
maestro (`aefos:investigated` → `aefos:running`). A entrada no board de estado está em
[../project-evolution.md](../../../project-evolution.md) marcada como 🔄 in-pipeline.
