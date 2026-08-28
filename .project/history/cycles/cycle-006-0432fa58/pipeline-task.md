---
type: task
kind: artifact
title: "Task — Pilar 1 ModernRTTI: Source/ModernSyntax.RTTI.pas + cascas de teste (issue #8)"
description: "Criar unit RTTI portável (TModernRTTI/Property/Field/Error), cenários compartilhados, cascas DUnitX e FPCUnit, runner Delphi e PTestRTTI.lpr+.lpi standalone FPC; compilar FPC antes de entregar."
cycle: "006"
agent: planner
workflow: equipe-feature
node: task
resource: aefos://run/0432fa58eb504d5fa522f3e710649a41
tags: [modernrtti, task, pilar-1, issue-8, fpc, delphi, cycle-006]
generated:
  by: "equipe-feature@node:task"
  at: "2026-08-28T00:00:00Z"
sources:
  - id: task-input
    resource: "task-input.md"
    title: "Task Input — Pilar 1 ModernRTTI (issue #8)"
  - id: esp
    resource: "esp.md"
    title: "ESP — Pilar 1"
  - id: adr
    resource: "adr.md"
    title: "ADR — Pilar 1"
  - id: plan
    resource: "plan.md"
    title: "Plan — Pilar 1"
---

# Task — Pilar 1 ModernRTTI (issue #8)

## Tracking

**Modo:** MAESTRO MODE — from_maestro: true  
**Issue original:** [#8](https://github.com/isaquepinheiro/ModernSyntax/issues/8) —
*Implementar Pilar 1 — Leitura de RTTI* (esta issue É a demanda deste ciclo;
nenhuma issue ou Epic adicional foi criada).  
**Ciclo:** 006 (re-entrada pós plan-gate:on_reject)

## Briefing resumido

A demanda é a implementação completa do Pilar 1 ModernRTTI. O escopo está
totalmente especificado no [task-input.md](pipeline-task-input.md) e nos artefatos
do Arquiteto ([esp.md](pipeline-esp.md), [adr.md](pipeline-adr.md), [plan.md](pipeline-plan.md)).

### Arquivos novos

| Arquivo | Propósito |
|---------|-----------|
| `Source/ModernSyntax.RTTI.pas` | TModernRTTI, TModernRTTIType, TModernRTTIProperty (portáveis); TModernRTTIField + GetFields em `{$IFNDEF FPC}` (Delphi-only); EModernRTTIError |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | Cenários portáveis (CA-1, CA-3, CA-4) |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | Casca DUnitX + TestGetFields (CA-2 Delphi) |
| `Test Delphi/EclbrSystem/PTestRTTI.dpr` | Runner Delphi |
| `Test Delphi/EclbrSystem/PTestRTTI.dproj` | Projeto Delphi |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | Casca FPCUnit portável |
| `Test FPC/EclbrSystem/PTestRTTI.lpr` | Runner FPCUnit (padrão commit 7114cdc) |
| `Test FPC/EclbrSystem/PTestRTTI.lpi` | Projeto Lazarus (SyntaxMode Delphi em ambos os modos) |

### Arquivos modificados

| Arquivo | Mudança |
|---------|---------|
| `Test Delphi/EclbrSystem/TestMSGroup.groupproj` | Adiciona PTestRTTI.dproj (13→14 entradas) |
| `Test Delphi/EclbrSystem/DCC.bat` | Adiciona PTestRTTI (13→14 projetos) |

### Não tocar

- `Source/ModernSyntax.inc` — typo `FCP:256` não é consertado aqui (R3 do PRD)
- `Source/ModernSyntax.Objects.pas` — não estender Factory (D5 do PRD)
- Qualquer outra unit de `Source/`

## Ordem de execução

1. **F1** — `Source/ModernSyntax.RTTI.pas` skeleton + valores
2. **F2** — R4: detecção de `{$M+}` ausente + `EModernRTTIError`
3. **F3** — `UScenarios.RTTI.pas` + casca DUnitX + runner Delphi + entradas em `groupproj`/`DCC.bat`
4. **F4** — casca FPCUnit + `PTestRTTI.lpr` + `PTestRTTI.lpi` standalone

## Critérios de aceitação (11 CAs)

Lista completa em [task-input.md](pipeline-task-input.md). Pontos críticos:

- **CA-5:** zero `{$IFDEF FPC}` nos arquivos de teste
- **CA-6:** zero `{$I ModernSyntax.inc}` e token `FCP` na unit nova
- **CA-8:** FPC 3.2.2 constrói PTestRTTI.lpr em i386 **e** x86_64 (`rm -rf <out>` antes)
- **CA-11:** PTestRTTI.lpr + .lpi próprios; não depende do merge da #7

## Regras estruturais críticas (não negociáveis)

- Zero `{$I ModernSyntax.inc}` na unit nova (R3 do PRD)
- Zero `{$mode objfpc}` na unit de produção — se necessário: `{$mode delphi}{$H+}` (RN-4a do ESP)
- `TModernRTTIField`/`GetFields` dentro de `{$IFNDEF FPC}…{$ENDIF}` (D12 do ADR)
- Zero `{$IFDEF FPC}` nos três arquivos de teste (CA-5)
- Zero units de `Source/` no `uses` de ModernSyntax.RTTI.pas (STUDY §C-4)
- Cabeçalho SPDX-MIT em `(* … *)` — nunca `{ … }` (RN-11 do ESP)
- API pública NÃO expõe `TValue` como caminho principal; `GetValue<T>`/`SetValue<T>` genéricos
- Contrato de ownership em `<remarks>` de GetType/GetProperties/GetFields (RN-9 do ESP)
- `initialization`/`finalization` para `class var TModernRTTI.FContext` (RN-5)
- `PTestRTTI.lpi` com `<SyntaxMode Value="Delphi"/>` em ambos os build modes (D7, D8 do ADR)
- Compilar FPC antes de abrir o PR; `rm -rf <out>` antes de cada build (SKILL.md trap 2)

## Riscos declarados

- **RSK-1:** detecção `PropCount == 0` no FPC 3.2.2 precisa de confirmação no primeiro build
- **RSK-2:** `TValue.AsType<T>` no FPC 3.2.2 pode falhar para `T` não trivial
- **RSK-3:** aviso `experimental` no build da unit
- **RSK-4:** build incremental mentiroso no FPC — mitigação: `rm -rf <out>` obrigatório
- **RSK-5:** arrastar dependência transitiva — grep no `uses` cobre

## Modo de rastreamento

MAESTRO MODE (from_maestro: true). A issue #8 preexiste como intake do maestro.
Nenhuma issue ou Epic adicional criada neste ciclo. O board de estado está em
[../project-evolution.md](../../../project-evolution.md) marcado como 🔄 in-pipeline.
