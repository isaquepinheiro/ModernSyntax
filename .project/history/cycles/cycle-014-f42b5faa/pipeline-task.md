---
type: task
kind: artifact
title: "TASK-013 — TModernRTTIContext: GetTypes, FindType, token opaco IInterface, registry FPC, cinco cenarios"
description: "Adicionar TModernRTTIContext publico com GetTypes/FindType portaveis, IModernRTTIContextToken opaco, registry per-instancia no FPC, GetPackages declarado-ausente, cinco cenarios compartilhados."
cycle: "013"
agent: planner
workflow: equipe-feature
node: task
resource: aefos://run/5a8dfb58a24f74263fa58fa581f465c4
tags: [modernrtti, task, issue-28, fpc, delphi, context, gettypes, findtype, feature, cycle-013]
generated:
  by: "equipe-feature@node:task"
  at: "2026-09-01T00:00:00Z"
sources:
  - id: task-input
    resource: "task-input.md"
    title: "TASK-INPUT — TModernRTTIContext: GetTypes e FindType (issue #28)"
  - id: gh-28
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/28"
    title: "Issue #28 — TModernRTTIContext: GetTypes e FindType, os dois membros ausentes no FPC"
---

# TASK-013 — TModernRTTIContext completo nos dois compiladores

## Rastreamento

**Modo:** MAESTRO MODE — issue #28 já existe no GitHub como intake do
maestro (`aefos:running`). Nenhuma issue ou Epic adicional criada.

**Issue de referência:** [#28](https://github.com/isaquepinheiro/ModernSyntax/issues/28) — TModernRTTIContext: GetTypes e FindType, os dois membros ausentes no FPC

**Board:** entrada adicionada em [../project-evolution.md](../../../project-evolution.md) com estado 🔄 in-pipeline.

**Ciclo:** 013

## Briefing

O FPC 3.2.2 expõe apenas três dos seis membros do `TRttiContext` do Delphi:
`Create`, `Free` e `GetType`. `GetTypes` e `FindType` estão ausentes; `GetPackages`
não tem par no FPC e fica deliberadamente fora de escopo — declarado ausente com
motivo em XMLDoc.

Este ciclo entrega `TModernRTTIContext` — record público em
`Source/ModernSyntax.RTTI.pas` — com superfície portável zero `{$IFDEF}`:

- `class function Create: TModernRTTIContext` (static)
- `procedure Free` (opcional; refcount libera automaticamente)
- `function GetType(AClass: TClass): TModernRTTIType` (overload)
- `function GetType(ATypeInfo: PTypeInfo): TModernRTTIType` (overload)
- `function RegisterType(ATypeInfo: PTypeInfo): TModernRTTIType`
- `function GetTypes: TArray<TModernRTTIType>`
- `function FindType(const AQualifiedName: string): TModernRTTIType`

O estado vive atrás de `IModernRTTIContextToken` (interface opaca, só GUID,
sem membros públicos) — refcount elimina use-after-free por construção.
É o primeiro record público dono de heap da camada, por isso usa `IInterface`
(frase-fronteira D-28.2 do [adr](pipeline-adr.md)).

### Backend Delphi

`TDelphiContextToken = class(TInterfacedObject, IModernRTTIContextToken)`
com `FContext: TRttiContext` per-instância. Cinco funções livres `Context*`
(sem `ContextFree`):

- `ContextGetType`: delega ao `FContext.GetType`
- `ContextRegisterType`: no-op documentado em XMLDoc
- `ContextGetTypes`: delega ao pool nativo
- `ContextFindType`: delega ao `FindType` nativo
- `ContextCreate`: cria e retorna instância

### Backend FPC

`TFPCContextToken = class(TInterfacedObject, IModernRTTIContextToken)`
com `FContext: TRttiContext` + `FRegistry: TList` de `PTypeInfo`.

- `ContextGetType`/`ContextRegisterType`: alimentam o registry sem duplicar
- `ContextGetTypes`: **levanta** `EModernRTTIError` com
  `SModernRTTIError_EmptyRegistry` quando `FRegistry.Count = 0`
  (D-26 — não silenciar divergência)
- `ContextFindType`: só resolve `tkClass` por `UnitName + '.' + Name`;
  outros kinds pulados; não achou → `TModernRTTIType.FromRtti(nil)`

Nova resourcestring após linha 149 do FPC:
```pascal
SModernRTTIError_EmptyRegistry = 'o FPC 3.2.2 nao enumera tipos; registre com TModernRTTIContext.RegisterType os tipos que importam antes de chamar GetTypes.';
```

### TModernRTTIType

Recebe `function IsNil: Boolean` (corpo: `Result := FType = nil`).

### Cenários compartilhados

Cinco procedures em `Test Shared/EclbrSystem/UScenarios.RTTI.pas`
(zero `{$IFDEF FPC}`, zero `Assert`, zero `Exception` genérica,
zero `AssertException`):

1. `Scenario_Context_GetTypes_EmptyRegistry_Raises`
2. `Scenario_Context_GetTypes_AfterTwoRegisterType_ContainsBoth`
3. `Scenario_Context_FindType_Class_Found`
4. `Scenario_Context_FindType_NotFound_ReturnsNil`
5. `Scenario_Context_CopyByValue_SharesState_NoUseAfterFree`

Casca FPC: 5 published. Casca Delphi: 4 [Test] (sem `_EmptyRegistry_Raises`).

## Checklist de aceitação resumido

Ver checklist completo em [task-input](pipeline-task-input.md).

- [ ] `IModernRTTIContextToken` com GUID, sem membros públicos
- [ ] `TModernRTTIContext` no `interface`, zero `{$IFDEF}` em membros
- [ ] `TModernRTTIType.IsNil` adicionado
- [ ] XMLDocs de `GetTypes`, `FindType`, `RegisterType`, `Free`, `GetPackages` (ausente com motivo)
- [ ] `TModernRTTI.GetType` XMLDoc: não alimenta nenhuma instância de `TModernRTTIContext`
- [ ] Cinco `Context*` idênticas nos dois backends (paridade — API-MAP §7)
- [ ] `SModernRTTIError_EmptyRegistry` no FPC; raise quando registry vazio
- [ ] `ContextFindType` FPC só resolve `tkClass`
- [ ] Cinco cenários compartilhados (padrão D-25/D-26)
- [ ] Cenário 2: busca por nome no array (não por Length)
- [ ] Cenário 5: três afirmações encadeadas (copy vê estado original; Free-safe; B.Free não levanta)
- [ ] Comentário cenário 1: mutação obrigatória declarada
- [ ] FPC casca: 5 published; Delphi casca: 4 [Test]
- [ ] Build FPC x86_64 e i386; PR declara o que foi compilado

## Arquivos impactados

- `Source/ModernSyntax.RTTI.pas` — declarações públicas, XMLDocs, delegações
- `Source/ModernSyntax.RTTI.Delphi.pas` — `TDelphiContextToken` + cinco `Context*`
- `Source/ModernSyntax.RTTI.FPC.pas` — `TFPCContextToken` + cinco `Context*` + resourcestring
- `Test Shared/EclbrSystem/UScenarios.RTTI.pas` — cinco cenários
- `Test FPC/EclbrSystem/UTestMS.RTTI.pas` — cinco published
- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` — quatro [Test]

## Não tocar

- `Source/ModernSyntax.RTTI.Delphi.pas` fora das cinco `Context*` + classe
- `Source/ModernSyntax.RTTI.FPC.pas` fora das cinco `Context*` + classe + resourcestring
- Records `TModernRTTIField`, `TModernRTTIProperty`, `TModernRTTIMethod`
- `Test FPC/EclbrSystem/PTestRTTI.lpr`

## Fontes

- [task-input](pipeline-task-input.md) — briefing operacional completo
- [esp](pipeline-esp.md), [adr](pipeline-adr.md), [plan](pipeline-plan.md) — artefatos de arquitetura do ciclo
