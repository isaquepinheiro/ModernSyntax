---
type: task
kind: artifact
title: "Task — feat(rtti): Enumerators nas colecoes for..in sobre Fields, Properties, Methods, Parameters, Attributes (issue #27)"
description: "Adicionar cinco properties alias ao ModernSyntax.RTTI.pas, GetAttributes privado, sete cenarios compartilhados e seis wrappers por casca FPC e Delphi."
cycle: "012"
agent: planner
workflow: equipe-feature
node: task
resource: aefos://run/d3f7942e59d0ba69094d93420fef84db
tags: [modernrtti, task, issue-27, fpc, delphi, enumerators, for-in, feature, pilar-4, cycle-012]
generated:
  by: "equipe-feature@node:task"
  at: "2026-08-31T00:00:00Z"
sources:
  - id: task-input
    resource: "task-input.md"
    title: "TASK-INPUT — Enumerators nas colecoes (issue #27)"
  - id: gh-27
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/27"
    title: "Issue #27 — Enumerators nas colecoes: for..in sobre Fields, Properties, Methods, Parameters, Attributes"
---

# Task — feat(rtti): Enumerators nas coleções `for..in` (issue #27)

## Tracking

**Modo:** MAESTRO MODE — from_maestro: true  
**Issue original:** [#27](https://github.com/isaquepinheiro/ModernSyntax/issues/27) —
*Enumerators nas coleções: `for..in` sobre `Fields`, `Properties`, `Methods`,
`Parameters`, `Attributes`* (esta issue É a demanda deste ciclo; nenhuma issue
ou Epic adicional foi criada).  
**Ciclo:** 012

## Briefing resumido

`for..in` sobre `TArray<T>` já compila e roda nos dois compiladores. O que falta
são as **property aliases** que expõem os arrays diretamente: hoje o consumidor
deve chamar `LType.GetFields`, amanhã escreve `for LField in LType.Fields do`.

A entrega é cirúrgica: cinco properties alias (zero enumerator, zero collection
nova, zero `TModernXxxEnumerator`), um método privado `GetAttributes`, e a
importação de `ModernSyntax.Attributes` na `uses` da interface.

`Parameters` no FPC continua levantando `EModernRTTIError` (comportamento
herdado do D-26 do [adr](pipeline-adr.md)); a property é alias puro e o XMLDoc declara
explicitamente.

`Types` fica **fora** — vai com a issue #28 (aberta), que entrega
`TModernRTTI.GetTypes` primeiro.

## Arquivos impactados

| Arquivo | Mudança |
|---------|---------|
| `Source/ModernSyntax.RTTI.pas` | Importa `ModernSyntax.Attributes` na `uses` da `interface`; adiciona `GetAttributes` privado + 4 properties a `TModernRTTITypeHelper`; adiciona `Parameters` a `TModernRTTIMethod` com XMLDoc |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | 7 cenários novos; zero `{$IFDEF FPC}`; usa `Fail(...)` |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | 6 `published` (5 comuns + `TestParameters_ForIn_RaisesOnFPC`) |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | 6 `[Test]` (5 comuns + `TestParameters_ForIn_IteratesRealParameters`) |

### Não tocar

- `Source/ModernSyntax.RTTI.Delphi.pas`, `Source/ModernSyntax.RTTI.FPC.pas`
- `Source/ModernSyntax.Attributes.pas`
- `Test FPC/EclbrSystem/PTestRTTI.lpr`, `Test Delphi/EclbrSystem/PTestRTTI.dpr`
- `TModernRTTIField.GetValue<T>`
- Todos os `Get*` existentes (inalterados)

## Checklist de aceitação

- [ ] `TModernRTTITypeHelper` recebe `property Fields`, `Properties`, `Methods`,
      `Attributes` — zero `{$IFDEF}` em qualquer uma.
- [ ] `TModernRTTITypeHelper` recebe método privado
      `function GetAttributes: TArray<TObject>` delegando a
      `ModernAttributes.GetAttributes(FType.Handle)`.
- [ ] `TModernRTTIMethod` recebe `property Parameters: TArray<TModernRTTIParameter> read GetParameters`
      com XMLDoc avisando sobre `EModernRTTIError` no FPC 3.2.2.
- [ ] `ModernSyntax.Attributes` adicionado na `uses` da `interface`.
- [ ] `grep -n "{\$IFDEF" Source/ModernSyntax.RTTI.pas` mostra APENAS a diretiva
      da `uses` da `implementation`.
- [ ] Os quatro `Get*` existentes permanecem inalterados.
- [ ] Sete cenários em `UScenarios.RTTI.pas` (zero `{$IFDEF FPC}`, usando `Fail(...)`):
      `Scenario_Fields_ForIn_IteratesFields`,
      `Scenario_Properties_ForIn_IteratesProperties`,
      `Scenario_Methods_ForIn_IteratesMethods`,
      `Scenario_Attributes_ForIn_IteratesAttributes`,
      `Scenario_EmptyCollection_ForIn_DoesNotLoop`,
      `Scenario_Parameters_ForIn_RaisesOnFPC`,
      `Scenario_Parameters_ForIn_IteratesRealParameters`.
- [ ] `Scenario_Parameters_ForIn_RaisesOnFPC` usa padrão try/except + `Fail(...)`.
      NÃO usa `AssertException`.
- [ ] `grep -c "IFDEF" "Test Shared/EclbrSystem/UScenarios.RTTI.pas"` não aumenta.
- [ ] `grep -n "AssertException" "Test Shared/" "Test FPC/" "Test Delphi/"` continua vazio.
- [ ] FPC: 6 `published` (5 comuns + `RaisesOnFPC`); NÃO publica o irmão que itera.
- [ ] Delphi: 6 `[Test]` (5 comuns + `IteratesRealParameters`); NÃO publica o irmão que levanta exceção.
- [ ] `PTestRTTI` compila e passa em x86_64 (fábrica); autor confirma i386 e Delphi 12.
- [ ] Mutação obrigatória: `read GetFields` → `read GetFieldsNil` (retorna `nil`) faz
      `TestFields_ForIn_IteratesFields` vermelho (`exit != 0`). Reverter antes de commitar.
- [ ] Corpo do PR: `Closes #27`.
- [ ] Corpo do PR declara a mutação executada.
- [ ] Corpo do PR declara disclaimer sobre `property alias read Get*` no Delphi 12.
- [ ] Corpo do PR registra nota para issue #28: expor `property Types` junto com `GetTypes`.

## Slices de execução (ver [plan](pipeline-plan.md))

| Slice | Entregável | Dependência |
|-------|-----------|-------------|
| S1 | `Source/ModernSyntax.RTTI.pas` — 5 properties + `GetAttributes` + `uses` | nenhuma |
| S2 | `UScenarios.RTTI.pas` — 7 cenários + cascas FPC/Delphi + build FPC x86_64 | S1 |

## Modo de rastreamento

MAESTRO MODE (from_maestro: true). A issue #27 preexiste como intake do maestro
(label `aefos:investigated`). Nenhuma issue ou Epic adicional criada neste ciclo.
O board de estado está em [../project-evolution.md](../../../project-evolution.md)
marcado como 🔄 in-pipeline.
