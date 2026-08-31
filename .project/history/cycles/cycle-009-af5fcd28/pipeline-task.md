---
type: task
kind: artifact
title: "Task — feat(rtti): TModernRTTIMethod pela vmtMethodTable (issue #25)"
description: "Adicionar TModernRTTIMethod/TModernRTTIParameter, GetMethods/GetMethod nos dois compiladores, split de backends RTTI, migrar TModernRTTIField, fechar #35."
cycle: "009"
agent: planner
workflow: equipe-feature
node: task
resource: aefos://run/af5fcd28da98e98892fbe66e544b6b5c
tags: [modernrtti, task, issue-25, fpc, delphi, pilar-4, cycle-009]
generated:
  by: "equipe-feature@node:task"
  at: "2026-08-31T00:00:00Z"
sources:
  - id: task-input
    resource: "task-input.md"
    title: "Task Input — TModernRTTIMethod pela vmtMethodTable (issue #25)"
---

# Task — feat(rtti): TModernRTTIMethod pela vmtMethodTable (issue #25)

## Tracking

**Modo:** MAESTRO MODE — from_maestro: true  
**Issue original:** [#25](https://github.com/isaquepinheiro/ModernSyntax/issues/25) —
*feat(rtti): TModernRTTIMethod pela vmtMethodTable*
(esta issue É a demanda deste ciclo; nenhuma issue ou Epic adicional foi criada).  
**Issue relacionada fechada:** [#35](https://github.com/isaquepinheiro/ModernSyntax/issues/35) — cirurgia do `Fail` em `UScenarios.RTTI.pas`.  
**Ciclo:** 009

## Briefing resumido

A demanda é uma extensão do Pilar 4 RTTI: enumerar métodos `published` de uma
classe via `vmtMethodTable` (FPC) e `TRttiMethod` (Delphi), expondo uma API
pública uniforme — `TModernRTTIMethod` com oito propriedades e
`TModernRTTIParameter` com duas.

Simultaneamente, o ciclo exige:
- **Split de backends**: criar `ModernSyntax.RTTI.Delphi.pas` e
  `ModernSyntax.RTTI.FPC.pas` para eliminar o `{$IFDEF}` do `strict private`
  de `TModernRTTIField` (pré-condição arquitetural § 7 do API-MAP).
- **Migração de `TModernRTTIField`**: campos neutros, método `FromToken`.
- **Fechamento de #35**: declarar `ETestScenarioFailed` em `UScenarios.RTTI.pas`
  e usá-la no `Fail` da linha 95.

O escopo completo está em [task-input.md](pipeline-task-input.md).

## Arquivos impactados

| Arquivo | Tipo de mudança |
|---------|----------------|
| `Source/ModernSyntax.RTTI.pas` | Refactor: remover `{$IFDEF}` do strict private, adicionar `GetMethods`/`GetMethod`, `TModernRTTIMethod`, `TModernRTTIParameter` |
| `Source/ModernSyntax.RTTI.Delphi.pas` | **NOVO** — backend Delphi com funções livres |
| `Source/ModernSyntax.RTTI.FPC.pas` | **NOVO** — backend FPC com `vmtMethodTable` |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | Cirurgia `Fail` + fixture `TMethodBase`/`TMethodDerived` + três cenários compartilhados |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | Três published tests |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | Três published tests + fix linha 59 |

### Não tocar

- `Test FPC/EclbrSystem/PTestRTTI.lpr` (o `-Fu"Source"` já acha os backends)
- Qualquer outra unit de `Source/`
- Arquivos de projeto (`.dpr`, `.dproj`, `.lpi`, `.groupproj`, `DCC.bat`)

## Checklist de aceitação

- [ ] `TModernRTTIMethod` e `TModernRTTIParameter` compilam em Delphi e FPC; zero `{$IFDEF}` na declaração pública.
- [ ] `Source/ModernSyntax.RTTI.pas` tem o único `{$IFDEF}` da unit na `uses` da `implementation`.
- [ ] `Source/ModernSyntax.RTTI.Delphi.pas` e `Source/ModernSyntax.RTTI.FPC.pas` existem e expõem a mesma superfície de funções livres.
- [ ] `TModernRTTIField` migrado para o novo desenho (campos neutros, `FromToken`).
- [ ] `MethodTokens` no backend FPC itera com `LTab^.Entry[i]`; nenhum `PByte(LTab) + N` ou `i * SizeOf(TVmtMethodEntry)`.
- [ ] `MethodToken(AClass, AName)` no backend FPC é uma linha usando `MethodAddress`; sem laço próprio.
- [ ] Seis membros sem fonte no FPC levantam `EModernRTTIError` com mensagem apontando `vmtMethodTable + TIntfMethodEntry`.
- [ ] `TModernRTTIParameter.Name`/`.ParamType` levantam `EModernRTTIError` no FPC.
- [ ] XMLDoc de `GetMethods` declara a divergência de cobertura (Delphi: `public`+`published`; FPC: só `published`).
- [ ] `UScenarios.RTTI.pas` declara `ETestScenarioFailed = class(Exception);` e o `Fail` da linha 95 levanta essa classe.
- [ ] Fixture com herança `TMethodBase`/`TMethodDerived` (só `published`).
- [ ] Três cenários compartilhados: `Scenario_GetMethods_CountsPublishedInherited_Exact`, `Scenario_GetMethod_ByName_FindsInherited`, `Scenario_Method_Invoke_NoArgs`. Zero `Assert`. Zero `{$IFDEF FPC}`.
- [ ] `Test FPC/EclbrSystem/UTestMS.RTTI.pas` e `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` recebem três published tests cada.
- [ ] `Test Delphi/EclbrSystem/UTestMS.RTTI.pas:59` — comentário stale corrigido.
- [ ] `PTestRTTI` compila e passa em x86_64 (fábrica) e i386 (autor).
- [ ] Corpo do PR declara `Closes #25` e `Closes #35`.
- [ ] Corpo do PR declara mutações M1 (desligar `ClassParent`) e M2 (aritmética literal no i386) que os cenários pegam.

## Slices de execução (ver plan.md)

| Slice | Entregável | Dependência |
|-------|-----------|-------------|
| S1 | Cirurgia do `Fail` em `UScenarios.RTTI.pas` (fecha #35) | nenhuma |
| S2 | Split backends + migrar `TModernRTTIField` | S1 |
| S3 | `TModernRTTIMethod` + `TModernRTTIParameter` + `GetMethods`/`GetMethod` | S2 |
| S4 | Fixture, três cenários, cascas de teste, build FPC x86_64 + i386 | S3 |

## Modo de rastreamento

MAESTRO MODE (from_maestro: true). A issue #25 preexiste como intake do maestro.
Nenhuma issue ou Epic adicional criada neste ciclo. O board de estado está em
[../project-evolution.md](../../../project-evolution.md) marcado como 🔄 in-pipeline.
