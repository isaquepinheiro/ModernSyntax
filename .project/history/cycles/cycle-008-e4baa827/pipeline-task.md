---
type: task
kind: artifact
title: "Task — feat(rtti): TModernRTTIField portável nos dois compiladores (issue #21)"
description: "Tornar TModernRTTIField e GetFields portáveis (Delphi + FPC): declaração pública incondicional, factories privadas distintas, loop de herança via vmtFieldTable tipada, fixture com herança, build FPC x86_64 e i386."
cycle: "008"
agent: planner
workflow: equipe-feature
node: task
resource: aefos://run/e4baa827945b3dd3a372629b831d73a9
tags: [modernrtti, task, issue-21, fpc, delphi, pilar-1, cycle-008]
generated:
  by: "equipe-feature@node:task"
  at: "2026-08-31T00:00:00Z"
sources:
  - id: task-input
    resource: "task-input.md"
    title: "Task Input — TModernRTTIField portável (issue #21)"
---

# Task — feat(rtti): TModernRTTIField portável nos dois compiladores (issue #21)

## Tracking

**Modo:** MAESTRO MODE — from_maestro: true  
**Issue original:** [#21](https://github.com/isaquepinheiro/ModernSyntax/issues/21) —
*feat(rtti): TModernRTTIField existe nos dois compiladores — mesmo tipo, dois mecanismos por dentro*
(esta issue É a demanda deste ciclo; nenhuma issue ou Epic adicional foi criada).  
**Ciclo:** 008

## Briefing resumido

A demanda é uma feature de portabilidade: `TModernRTTIField` e
`TModernRTTIType.GetFields` existem hoje apenas dentro de `{$IFNDEF FPC}` em
`Source/ModernSyntax.RTTI.pas`. O objetivo é torná-los incondicionais na
interface pública, ramificando a implementação apenas em `strict private` e
nos corpos de método — via factories privadas nomeadas de forma distinta por
compilador (`FromRaw` no FPC, `FromRtti` no Delphi) e via loop de herança FPC
usando `PVmtFieldTable` tipada e `ClassParent`.

O escopo completo está em [task-input.md](pipeline-task-input.md).

## Arquivos impactados

| Arquivo | Tipo de mudança |
|---------|----------------|
| `Source/ModernSyntax.RTTI.pas` | 6 pontos (A1..A6): declaração incondicional, factories, XMLDoc, implementação ramificada, loop FPC, cast ShortString→string |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | Nova fixture `TInner`/`TBase`/`TPortableFieldFixture` + procedure `Scenario_GetFields_EnumeratesInheritedPublishedClassFields` |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | Remove linha 16 (comentário falso) + casca fina `TestGetFields_EnumeratesInheritedPublishedClassFields` |

### Não tocar

- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas`
- Qualquer outra unit de `Source/`
- `Source/ModernSyntax.inc`
- Arquivos de projeto (`.dpr`, `.dproj`, `.lpr`, `.lpi`, `.groupproj`, `DCC.bat`)

## Critérios de aceitação

- [ ] **CA-1.** `TModernRTTIField` e `GetFields` existem e compilam nos dois compiladores; nenhuma ocorrência dentro de `{$IFNDEF FPC}`.
- [ ] **CA-2.** Zero `{$IFDEF FPC}`/`{$IFNDEF FPC}` nos três arquivos de teste.
- [ ] **CA-3.** No FPC, `GetFields` enumera campos `published` subindo por `ClassParent`; cenário passa com `Length = 2`.
- [ ] **CA-4.** XMLDoc em voz de contrato; "no FPC" aparece ≥ 2 vezes; "ordem não especificada" no XMLDoc de `GetFields`.
- [ ] **CA-5.** Build FPC verde em x86_64 e i386 (`rm -rf <out>` antes de cada run).
- [ ] **CA-6.** `git diff --name-only` mostra exatamente os três arquivos listados.
- [ ] **CA-7.** A linha "Sem TestGetFields aqui: TModernRTTIField é Delphi-only" não existe mais em `Test FPC/EclbrSystem/UTestMS.RTTI.pas`.
- [ ] **CA-8.** Corpo do PR declara build FPC 3.2.2 x86_64 e i386 verde.

## Ordem de execução

1. **F1** — 6 pontos em `Source/ModernSyntax.RTTI.pas`
2. **F2** — fixture + cenário em `Test Shared/EclbrSystem/UScenarios.RTTI.pas`
3. **F3** — remover linha 16 + casca fina em `Test FPC/EclbrSystem/UTestMS.RTTI.pas`
4. **Build FPC** — `rm -rf <out>` antes de cada bitness; declarar resultado no PR

## Regras não-negociáveis

- Zero `{$IFDEF FPC}` na declaração pública de `TModernRTTIField` ou `GetFields`
- Factories privadas com nomes distintos: `FromRaw` (FPC) / `FromRtti` (Delphi)
- FPC: `PVmtFieldTable(PVmt(LCur)^.vFieldTable)` — sempre tipado
- FPC: `LTab^.Field[i]` — sempre property (entradas têm tamanho variável)
- FPC: subir por `ClassParent`; `vFieldTable = nil` num elo = pula, não erra
- FPC: cast explícito `string(LEntry^.Name)`
- Ordem NÃO especificada no contrato público
- Fixture com herança e assertiva de contagem exata `= 2`
- Zero `{$mode objfpc}` na unit de produção
- Cabeçalho SPDX-MIT em `(* … *)` — não tocar

## Modo de rastreamento

MAESTRO MODE (from_maestro: true). A issue #21 preexiste como intake do maestro.
Nenhuma issue ou Epic adicional criada neste ciclo. O board de estado está em
[../project-evolution.md](../../../project-evolution.md) marcado como 🔄 in-pipeline.
