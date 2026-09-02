---
type: task
kind: artifact
title: "TASK-018 — TModernRTTIRecordType com Name + Size nos dois compiladores (issue #45)"
description: "Implementar record publico TModernRTTIRecordType com Name e Size, backends FPC/Delphi, duas fixtures obrigatorias, cenario compartilhado com quatro asserções, issue-filha GetFields fora do commit."
cycle: "018"
agent: planner
workflow: equipe-feature
node: task
resource: aefos://run/d9ace4ff9a3af56be91a8f0373cb9475
tags: [task, modernrtti, issue-45, fpc, delphi, record, feature, cycle-018]
generated:
  by: "equipe-feature@node:task"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: task-input
    resource: "task-input.md"
    title: "TASK-INPUT — TModernRTTIRecordType (issue #45)"
  - id: gh-45
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/45"
    title: "Issue #45 — TModernRTTIRecordType"
---

# TASK-018 — TModernRTTIRecordType (issue #45)

## Rastreamento

**Modo:** MAESTRO MODE — `has_remote: true`, `from_maestro: true`.

A issue [#45](https://github.com/isaquepinheiro/ModernSyntax/issues/45) já existe
como intake do maestro (`aefos:investigated`). Nenhuma issue nova criada. Nenhum
Epic criado.

**Parent Epic:** [#29](https://github.com/isaquepinheiro/ModernSyntax/issues/29) —
link `Parte de #29` mantido no PR body.

**Board:** entrada adicionada em [../project-evolution.md](../../../project-evolution.md)
com estado 🔄 in-pipeline.

**Ciclo:** 018

## Briefing

Implementar `TModernRTTIRecordType` — record público portável que encapsula
`PTypeInfo` de um tipo record e expõe as properties `Name: string` e `Size: Integer`.
A casca pública fica em `Source/ModernSyntax.RTTI.pas` sem nenhum `{$IFDEF}` novo
(CA-4 / D-1 / D-25.1). Os backends FPC e Delphi implementam funções livres com guarda
explícita por `Kind`, centralizada em um helper `RecordRaiseWrongKind`.

Esta entrega cobre apenas `Name` e `Size`. `GetFields` fica para issue própria,
condicionada a medir `TRecordElement.Name` num FPC vivo (limitação F-3 do estudo).

## Escopo operacional (síntese)

1. **Backend FPC** (`Source/ModernSyntax.RTTI.FPC.pas`): declarar `RecordTypeName` e
   `RecordTypeSize` na `interface` (após :123). Adicionar `resourcestring SRecordWrongKind`
   após `SPointerWrongKind`. Helper `RecordRaiseWrongKind` na `implementation` (após :586,
   antes de `// --- Context`) com guarda `(P = nil) or (P^.Kind <> tkRecord)` — sem
   condição sobre Size. Corpos: `RecordTypeName` retorna `string(P^.Name)`;
   `RecordTypeSize` retorna `GetTypeData(P)^.RecSize`. Cada função chama o helper
   como primeira instrução.

2. **Backend Delphi** (`Source/ModernSyntax.RTTI.Delphi.pas`): paridade de assinatura
   (interface após :101). `resourcestring SRecordWrongKind` com texto **idêntico** ao FPC
   (D-2 / D-43.6). Helper `RecordRaiseWrongKind` com mesma guarda (após :481).
   `RecordTypeName` usa `LCtx: TRttiContext` **local** com `try/finally LCtx.Free`;
   corpo `Result := TRttiRecordType(LCtx.GetType(P)).Name`. **Não** usar `FContext` global.
   `RecordTypeSize` usa `GetTypeData(P)^.RecSize` direto — sem `TRttiContext`.

3. **Casca pública** (`Source/ModernSyntax.RTTI.pas`): declarar `TModernRTTIRecordType`
   após `TModernRTTIPointerType` (:680), com `strict private FToken: PTypeInfo`, factory
   `FromTypeInfo` **sem** guarda de `Kind` (padrão consagrado), properties `Name` e `Size`
   — **e nada mais**. XMLDoc `///` do record com frase-verbatim do acceptance sobre `GetFields`.

4. **Cenários** (`Test Shared/EclbrSystem/UScenarios.RTTI.pas`): duas fixtures públicas
   na seção `type` da `interface` após `PInt44`:
   - `TRecordFixture45 = record FieldA, FieldB: Integer end;` (unmanaged — obrigatória)
   - `TRecordFixture45M = record S: string; I: Integer end;` (managed — obrigatória)
   Cenário `Scenario_RecordType_NameAndSize` com **quatro** asserções por igualdade
   (`Name` + `Size` por fixture, `Size = SizeOf(T)` — nunca `>=`).
   `raise ETestScenarioFailed.Create(...)` como padrão de falha.

5. **Cascas** (`Test FPC/…/UTestMS.RTTI.pas` e `Test Delphi/…/UTestMS.RTTI.pas`):
   **uma** procedure em cada (`TestRecordType_NameAndSize`), corpo de uma linha
   delegando ao cenário compartilhado.

## Arquivos impactados

| Arquivo | Natureza | Delta |
|---------|----------|-------|
| `Source/ModernSyntax.RTTI.pas` | edição | +record `TModernRTTIRecordType` + 3 corpos |
| `Source/ModernSyntax.RTTI.FPC.pas` | edição | +2 declarações + 1 resourcestring + 1 helper + 2 corpos |
| `Source/ModernSyntax.RTTI.Delphi.pas` | edição | +2 declarações + 1 resourcestring + 1 helper + 2 corpos |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | edição | +2 fixtures + 1 declaração + 1 implementação |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | edição | +1 procedure published |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | edição | +1 procedure [Test] |

Nenhum arquivo novo. Nenhum arquivo removido.

## Convenções que governam a implementação

- **CA-4 / D-1 / D-25.1** — zero `{$IFDEF}` novo em `Source/ModernSyntax.RTTI.pas`
- **D-2 / D-43.6** — paridade de assinatura; `SRecordWrongKind` idêntico byte a byte
- **D-4** — guarda por `Kind` centralizada em `RecordRaiseWrongKind`
- **CA-5** — zero `{$IFDEF FPC}` em `UScenarios.RTTI.pas`
- **D-5** — fixtures na seção `type` da `interface`
- **D-7** — um cenário, duas cascas
- **Prefixos:** `T` tipo/record, `A` parâmetros, `L` locais
- **XMLDoc `///`** em todos os membros públicos novos
- **`rm -rf /tmp/fpcbuild`** antes de cada compilação (SKILL Trap #2)
- **Nunca `Assert`; nunca `raise Exception` genérica.** `raise ETestScenarioFailed.Create(...)` em teste;
  `raise EModernRTTIError.Create(...)` em backend.
- **Piso Delphi 23.0** — não adicionar `{$IF CompilerVersion >= ...}`.

## Pontos críticos de fricção (do arquiteto)

- **Duas fixtures são obrigatórias.** Uma só faz `Size = 8` coincidir por acidente.
- **`record end` com `Size = 0` é válido.** Não adicionar guarda `if RecSize = 0 then raise`.
- **`ManagedFldCount` mente para `tkRecord` puro.** Não usar esse campo.
- **`FContext` global no Delphi é cerimônia morta.** Usar `LCtx` local em `RecordTypeName`.
- **`RecordTypeSize` no Delphi não cria contexto.** `GetTypeData(P)^.RecSize` direto.
- **Texto do `SRecordWrongKind` tem que casar byte a byte.** Copiar do FPC para o Delphi.
- **Uma só procedure por casca.** Não criar `Test_*_Name` e `Test_*_Size` separadas.
- **Ordem:** backends primeiro (slice 1), casca pública (slice 2), testes (slice 3).

## Fora do commit (obrigatório, após merge)

Abrir issue-filha:
> `TModernRTTIRecordType.GetFields: medir TRecordElement.Name no FPC 3.2.2 antes de entregar`

Labels: `enhancement`, `rtti`, `fpc`, `blocked:medicao`.

Caveto na descrição:
> `ManagedFldCount` **não** vale para `tkRecord` puro. Medido: `TPlain` (zero campos
> managed) devolve `ManagedFldCount = 2`. Leitura da união do `TTypeData`, mesma família
> de bug do `ElType` (#29) e do `RefTypeRef` (#44). Bloqueio: medir `TRecordElement.Name`
> num FPC 3.2.2 vivo antes de entregar.

## Checklist de aceitação (resumido)

Ver checklist completo (16 itens) em [task-input](pipeline-task-input.md).

- [ ] `TModernRTTIRecordType` declarado após `TModernRTTIPointerType`; apenas `FToken`, `FromTypeInfo`, `Name`, `Size`
- [ ] XMLDoc do record com frase-verbatim do acceptance sobre `GetFields`
- [ ] `FromTypeInfo` sem validar `Kind` (padrão D-1/D-43.1)
- [ ] Backend FPC: `RecordTypeName`, `RecordTypeSize`, `SRecordWrongKind`, helper `RecordRaiseWrongKind`
- [ ] Backend FPC: retorna `string(P^.Name)` e `GetTypeData(P)^.RecSize`
- [ ] Backend Delphi: paridade; `SRecordWrongKind` idêntico; `LCtx` local; `GetTypeData` direto em Size
- [ ] Duas fixtures: `TRecordFixture45` (unmanaged) + `TRecordFixture45M` (managed) — ambas obrigatórias
- [ ] Cenário com 4 asserções por igualdade (não `>=`)
- [ ] Uma procedure por casca (`TestRecordType_NameAndSize`)
- [ ] Zero `{$IFDEF}` novo em `ModernSyntax.RTTI.pas`; zero `{$IFDEF FPC}` em cenários
- [ ] Build FPC 3.2.2 x86_64 e i386 verdes
- [ ] Issue-filha `GetFields` aberta após merge
- [ ] PR body fecha `Closes #45`; mantém `Parte de #29`

## Fontes

- [task-input](pipeline-task-input.md) — briefing operacional completo (16 itens de checklist)
- [esp](pipeline-esp.md), [adr](pipeline-adr.md), [plan](pipeline-plan.md) — artefatos de arquitetura do ciclo
