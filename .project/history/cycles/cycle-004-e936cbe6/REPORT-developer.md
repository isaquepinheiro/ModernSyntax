---
type: cycle-report
kind: report
cycle: "004"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/e936cbe6a17a8e76ec8ca9a02ec30735
title: "REPORT — developer (cycle-004): implementação de ModernSyntax.Attributes"
description: "Implementação do Pilar 2 do ModernRTTI (atributos portáveis) em uma unit de produção, dois artefatos shared, casca DUnitX + .dpr/.dproj no Delphi e casca FPCUnit + .lpr/.lpi no FPC; gates de grep verdes."
status: draft
tags: [cycle-report, modernrtti, attributes, issue-9, cycle-004]
generated:
  by: "equipe-feature@node:implement"
  at: "2026-08-28T14:12:00Z"
sources:
  - id: esp
    resource: "pipeline-esp.md"
    title: "ESP — Atributos portáveis"
  - id: adr
    resource: "pipeline-adr.md"
    title: "ADR — Design da unit ModernSyntax.Attributes"
  - id: plan
    resource: "pipeline-plan.md"
    title: "Plan — Atributos"
  - id: task-input
    resource: "pipeline-task-input.md"
    title: "Task input — Atributos portáveis"
  - id: implement-report
    resource: "pipeline-implement-report.md"
    title: "Implement report — Atributos portáveis"
---

# REPORT — developer (cycle-004)

Contrato: [esp](pipeline-esp.md), [adr](pipeline-adr.md),
[plan](pipeline-plan.md), [task-input](pipeline-task-input.md).
Relatório operacional detalhado: [implement-report](pipeline-implement-report.md).

## Resumo

Entreguei o Pilar 2 do ModernRTTI: `Source/ModernSyntax.Attributes.pas`
com `TModernAttribute` como classe base bifurcada (herda de `TObject`
no FPC, de `TCustomAttribute` no Delphi), `TAttributeRecord` público
na `interface` por R-FPC-Generic, e o record `ModernAttributes` com
`Register` (append + dedup por identidade de referência) e
`GetAttributes` (FPC = cópia de `Owned`; Delphi = `Owned` + Native
filtrado pela **regra 2 do ADENDO**). Registry global protegida por
`TCriticalSection`; `TRttiContext` próprio da unit no Delphi;
`finalization` libera apenas `Owned`.

Testes na convenção da família ModernRTTI:
`Test Shared/EclbrSystem/UTestMS.Attributes.Symbols.inc` (uma linha
exata), `Test Shared/EclbrSystem/UTestMS.Attributes.Scenarios.pas`
(cinco cenários portáveis sem framework, sem `{$IFDEF}`), casca
DUnitX + `.dpr` + `.dproj` em `Test Delphi/EclbrSystem/` (com dois
testes Delphi-only atrás de `{$IFDEF HAS_NATIVE_ATTRS}` provando a
regra 2 do ADENDO), e casca FPCUnit + `.lpr` + `.lpi` em
`Test FPC/EclbrSystem/` (com um teste FPC-only atrás de
`{$IFDEF NO_NATIVE_ATTRS}` afirmando a fronteira portável).

## Gates verificados

Todos os greps de aceitação da [task-input](pipeline-task-input.md)
§Verificação por grep retornam **exit 1** (zero linhas):

- `grep -rn '{\$IFDEF FPC}'` nos três arquivos de teste → 0
- `grep -n '{$I ModernSyntax.inc}' Source/ModernSyntax.Attributes.pas` → 0
- `grep -n 'FCP' Source/ModernSyntax.Attributes.pas` → 0
- `grep -rn 'DUnitX' 'Test FPC/EclbrSystem/'*.pas 'Test FPC/EclbrSystem/'*.lpr` → 0

Compilação real fica com o orquestrador (FPC 3.2.2 x86_64 e i386 via
`lazbuild`) e com o autor (Delphi IDE), conforme R2 do PRD.

## Handoff

Ver [implement-report](pipeline-implement-report.md) para o checklist
detalhado por seção do task-input, decisões técnicas (DEV-1..DEV-7) e
caveats. O board local (`.project/project-evolution.md`) foi movido
para `🔄 in-review`; o card do GitHub Project é responsabilidade do
nó de release.
