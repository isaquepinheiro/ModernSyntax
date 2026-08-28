---
type: cycle-report
kind: report
title: "Cycle 003 — developer report (Callbacks transversais, issue #7)"
description: "Implementou ModernSyntax.Callback, unit comum de cenários, casca DUnitX (+.dproj) e casca FPCUnit (+.lpr/.lpi); todas as gates de grep verdes."
cycle: "003"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/92fccbce1ddb8c2d37df799793017636
tags: [cycle-003, developer, implement, callbacks, issue-7]
generated:
  by: "equipe-feature@node:implement"
  at: "2026-08-28T10:55:00Z"
---

# REPORT — developer (cycle 003)

Insumos: [esp](pipeline-esp.md), [adr](pipeline-adr.md),
[plan](pipeline-plan.md), [task-input](pipeline-task-input.md).
Detalhamento técnico completo em [implement-report](pipeline-implement-report.md).

## Escopo entregue

Sete arquivos novos (unit + shared + duas cascas + três projetos) e o
board local flipado. Nenhum código existente foi tocado.

- `Source/ModernSyntax.Callback.pas` — três interfaces genéricas sem
  GUID + factory `Callback.&Of` + wrappers privados. `uses` só
  `SysUtils`.
- `Test Shared/EclbrSystem/UTestMS.Callback.Scenarios.pas` — quatro
  cenários (func, proc, predicate, captura), sem framework, sem
  `{$IFDEF}` efetiva.
- `Test Delphi/EclbrSystem/UTestMS.Callback.pas` — casca DUnitX,
  uma linha útil por método.
- `Test Delphi/EclbrSystem/PTestModernCallback.dpr` +
  `PTestModernCallback.dproj` — projeto Delphi com `<DCC_UnitSearchPath>`
  incluindo `..\..\Test Shared\EclbrSystem` e `..\..\Source`.
- `Test FPC/EclbrSystem/UTestMS.Callback.pas` — casca FPCUnit,
  uma linha útil por método, `RegisterTest` em `initialization`.
- `Test FPC/EclbrSystem/PTestModernCallback.lpr` +
  `PTestModernCallback.lpi` — projeto Lazarus com dois build modes
  (`Debug-x86_64` default, `Debug-i386` override), `<OtherUnitFiles>`
  apontando para `../../Source` e `../../Test Shared/EclbrSystem`.
- `.project/project-evolution.md` — demanda #7 flipada de
  `🔄 in-pipeline` para `🔄 in-review`.

## Decisões-chave da implementação

- **DEV-1 — `&Of` em vez de `Of`.** `of` é palavra reservada em
  Object Pascal; o escape `&` preserva o nome literal do gate
  D-A3/D-A6 do [adr](pipeline-adr.md) sem violar a gramática.
  Consumidor chama `Callback.&Of<T,R>(Self.MyMethod)`.
- **DEV-2 — Aliases de método-de-objeto na `interface`.** Tipos
  `of object` inline em parâmetros genéricos são fonte conhecida
  de erros de parser no FPC 3.2.2; extraí os aliases para evitar.
- **DEV-3 — Wrappers na `implementation`.** RN-1 do
  [esp](pipeline-esp.md) preservada.
- **DEV-6 — `SyntaxMode=Delphi` no `.lpi`, não `{$MODE DELPHI}`
  na shared.** CA-4 do ESP fecha por grep; a shared não pode ter
  `{$IFDEF FPC}`. Movi a escolha de modo para o projeto FPC.

Detalhes completos e alternativas descartadas em
[implement-report](pipeline-implement-report.md#decisões-técnicas-tomadas-na-implementação).

## Validações rodadas

Só leitura + grep (R2 do PRD — fábrica não tem compilador Pascal).
Não há `.project/SKILL.md`; `analysis/05-conventions.md` confirma
"None found" para CI/lint. Todas as gates verdes:

| Verificação | Resultado |
|-------------|-----------|
| `grep -n '{\$I ModernSyntax.inc}' Source/ModernSyntax.Callback.pas` | 0 linhas |
| `grep -n 'FCP' Source/ModernSyntax.Callback.pas` | 0 linhas |
| `grep -rn '{\$IFDEF FPC}' 'Test Shared/' 'Test Delphi/EclbrSystem/UTestMS.Callback.pas' 'Test Delphi/EclbrSystem/PTestModernCallback.dpr' 'Test FPC/'` | 0 linhas |
| `grep -rn 'DUnitX\|TestFramework\|fpcunit\|testregistry\|FPCUnit' 'Test Shared/EclbrSystem/UTestMS.Callback.Scenarios.pas'` | 0 linhas |
| `uses` da unit nova = só `SysUtils` | confirmado |

## Handoff

Próximos nodes (`review`, `test`, `verify`) devem rerodar os greps
de verificação final do [task-input](pipeline-task-input.md#verificação-final-checklist-de-pr)
e pedir ao orquestrador para compilar via `lazbuild` (dois modos) e
Delphi IDE. Body do PR precisa carregar a declaração literal do CA-7
do ESP (ainda não escrito — é ação do nó de release/PR).
