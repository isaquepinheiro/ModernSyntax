---
type: task
kind: artifact
title: "TASK-019 — TModernRTTIArrayType + TModernRTTISetType nos dois compiladores (issue #46)"
description: "Implementar TModernRTTIArrayType e TModernRTTISetType com Length levantando em dinamico; quatro cenarios compartilhados; duas mutacoes obrigatorias com log no PR."
cycle: "019"
agent: planner
workflow: equipe-feature
node: task
resource: aefos://run/0a0b1110fc1826855542e8d75c65cf65
status: draft
tags: [task, modernrtti, issue-46, array, set, fpc, delphi, cycle-019]
generated:
  by: "equipe-feature@node:task"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: task-input
    resource: "task-input.md"
    title: "TASK-INPUT — issue #46"
  - id: gh-46
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/46"
    title: "Issue #46 — TModernRTTIArrayType + TModernRTTISetType"
---

# TASK-019 — issue #46 (TModernRTTIArrayType + TModernRTTISetType)

## Rastreamento

**Modo:** MAESTRO MODE — `has_remote: true`, `from_maestro: true`.

A issue [#46](https://github.com/isaquepinheiro/ModernSyntax/issues/46) já existe
como intake do maestro (`aefos:investigated`). Nenhuma issue nova criada. Nenhum
Epic criado.

**Parent Epic:** [#29](https://github.com/isaquepinheiro/ModernSyntax/issues/29) —
link `Parte de #29` mantido no PR body.

**Board:** entrada adicionada em `project-evolution.md` com estado 🔄 in-pipeline.

**Ciclo:** 019

## Briefing

Implementar dois records públicos novos em `Source/ModernSyntax.RTTI.pas`:

- **`TModernRTTIArrayType`** — após `TModernRTTIRecordType` (linhas 699–731), com
  `strict private FToken: PTypeInfo`, `FromTypeInfo` (sem guarda de Kind), `IsDynamic`,
  `ElementType`, `Size` e `Length` (levanta `EModernRTTIError` com `SArrayDynamicLength`
  quando array é dinâmico — nos DOIS compiladores).
- **`TModernRTTISetType`** — logo após, com `strict private FToken: PTypeInfo`,
  `FromTypeInfo` e `ElementType`.

A casca pública fica em `Source/ModernSyntax.RTTI.pas` sem nenhum `{$IFDEF}` novo
(CA-4 / D-1 / D-25.1). Os backends FPC e Delphi implementam funções livres com guardas
centralizadas em helpers.

## Escopo operacional (síntese)

### Slice 1 — Backends FPC e Delphi

**FPC** (`Source/ModernSyntax.RTTI.FPC.pas`):
- +5 declarações na `interface` após bloco Record (:129):
  `ArrayTypeIsDynamic`, `ArrayTypeElementType`, `ArrayTypeSize`, `ArrayTypeLength`, `SetTypeElementType`
- +3 `resourcestring` após `SRecordWrongKind`:
  `SArrayWrongKind`, `SArrayDynamicLength`, `SSetWrongKind`
  - Texto `SArrayDynamicLength`: `'TModernRTTIArrayType.Length: nao suportado para arrays dinamicos.'`
- +2 helpers: `ArrayRaiseWrongKind` (guarda `(P = nil) or not (P^.Kind in [tkArray, tkDynArray])`),
  `SetRaiseWrongKind` (guarda `(P = nil) or (P^.Kind <> tkSet)`)
- +5 corpos após `RecordTypeSize`:
  - `ArrayTypeIsDynamic` → `P^.Kind = tkDynArray`
  - `ArrayTypeElementType` → `GetTypeData(P)^.elType2` (dinâmico) / `GetTypeData(P)^.ArrayData.ElType` (estático)
  - `ArrayTypeSize` → `GetTypeData(P)^.elSize` (dinâmico) / `GetTypeData(P)^.ArrayData.Size` (estático)
  - `ArrayTypeLength` → levanta `EModernRTTIError(SArrayDynamicLength)` no dinâmico;
    `GetTypeData(P)^.ArrayData.ElCount` no estático
  - `SetTypeElementType` → `GetTypeData(P)^.CompType`
- **NUNCA**: `elType2Ref`, `elTypeRef`, `CompTypeRef`

**Delphi** (`Source/ModernSyntax.RTTI.Delphi.pas`):
- +5 declarações na `interface` após bloco Record (:107); paridade de assinatura com FPC
- +3 `resourcestring` com **texto idêntico** ao FPC (copiar-colar)
- +2 helpers com mesmas guardas
- Corpos:
  - `ArrayTypeElementType` e `SetTypeElementType`: `LCtx: TRttiContext` **local** + `try/finally LCtx.Free`
  - `ArrayTypeElementType` ramifica por Kind: dinâmico → `TRttiDynamicArrayType`, estático → `TRttiArrayType`
    (são **irmãs** — não há herança entre elas)
  - `ArrayTypeSize` e `ArrayTypeLength`: leitura direta via `GetTypeData(P)^` (sem TRttiContext)
  - `SetTypeElementType`: `TRttiSetType(LCtx.GetType(P)).ElementType.Handle`

### Slice 2 — Casca pública

`Source/ModernSyntax.RTTI.pas`:
- +2 records após `TModernRTTIRecordType` (:699-731), antes de `TModernRTTI`
- +7 corpos na `implementation` após os do `TModernRTTIRecordType` (:1195-1214)
- XMLDoc `///` do `TModernRTTIArrayType.Length` cita: *"levanta `EModernRTTIError`
  (`SArrayDynamicLength`) quando o array é dinâmico — em ambos os compiladores"*
- Zero `{$IFDEF}` novo

### Slice 3 — Testes

`Test Shared/EclbrSystem/UScenarios.RTTI.pas`:
- +4 fixtures públicas após `TRecordFixture45M` (:218):
  - `TArr5Int46 = array[0..4] of Integer;`
  - `TDynByteArr46 = array of Byte;` (**não** `TDynIntArr46` — `elSize=1` diverge de
    `SizeOf(Pointer)` nos dois bitness; decisão D-46.7)
  - `TDynStrArr46 = array of string;`
  - `TSetCor46 = set of TCor;`
- +4 procedimentos compartilhados:
  - `Scenario_ArrayType_Static_LengthAndSize` (cenário 7): `IsDynamic=False`, `Length=5`, `Size=SizeOf(Integer)`
  - `Scenario_ArrayType_Dynamic_LengthRaises` (cenário 8): **quatro** asserções obrigatórias:
    `IsDynamic=True`; `Length` levanta `EModernRTTIError`; `ElementType.Name` por referência
    (não literal); `Size=1`. **Não simplificar para "só raises".**
  - `Scenario_ArrayType_Dynamic_Managed_ElementType` (cenário 9): `ElementType.Name` por
    referência (`TModernRTTI.GetType(TypeInfo(string)).Name`). **Não** prometer cobrir Mutação 1.
  - `Scenario_SetType_ElementType` (cenário 10): `ElementType.Name` por referência
    (`TModernRTTI.GetType(TypeInfo(TCor)).Name`)

`Test FPC/EclbrSystem/UTestMS.RTTI.pas`: +4 published (37→41), corpo de uma linha
`Test Delphi/EclbrSystem/UTestMS.RTTI.pas`: +4 [Test] (35→39), corpo de uma linha

## Arquivos impactados

| Arquivo | Natureza | Delta |
|---------|----------|-------|
| `Source/ModernSyntax.RTTI.pas` | edição | +2 records + 7 corpos |
| `Source/ModernSyntax.RTTI.FPC.pas` | edição | +5 decl + 3 resourcestring + 2 helpers + 5 corpos |
| `Source/ModernSyntax.RTTI.Delphi.pas` | edição | +5 decl + 3 resourcestring + 2 helpers + 5 corpos |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | edição | +4 fixtures + 4 decl + 4 impl |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | edição | +4 published |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | edição | +4 [Test] |

**Nenhum arquivo novo. Nenhum arquivo removido.**

## Mutações obrigatórias

1. **Mutação 1** (cenário 8): trocar `elType2` por `elType` em `ArrayTypeElementType` FPC
   → cenário vermelho/AV. Log copiado ao PR body. **Reverter antes de commitar.**
2. **Mutação 2** (cenário 10): trocar `CompType` por `PTypeInfo(CompTypeRef)` em
   `SetTypeElementType` FPC → cenário vermelho/AV. Log copiado ao PR body. **Reverter antes de commitar.**

## Convenções mandatórias

| Código | Regra |
|--------|-------|
| CA-4 / D-1 / D-25.1 | Zero `{$IFDEF}` novo em `Source/ModernSyntax.RTTI.pas` |
| D-2 / D-43.6 | Paridade de assinatura entre backends; texto das resourcestrings idêntico |
| D-4 | Guarda por Kind via helpers; `ArrayRaiseWrongKind` com guarda combinada (drift D-46.4) |
| D-44.5 | `TRttiContext` local no Delphi com `try/finally .Free` |
| CA-5 | Zero `{$IFDEF FPC}` em teste |
| D-5 | Fixtures com `TypeInfo()` na seção `type` da `interface` |
| D-7 | "Um cenário, duas cascas" — quatro cenários, quatro procedures por casca |
| SKILL #2 | `rm -rf /tmp/fpcbuild` antes de cada `fpc` |

## Pontos críticos de fricção (do arquiteto)

- `TDynByteArr46`, **não** `TDynIntArr46`. `Byte` (`elSize=1`) diverge de `SizeOf(Pointer)`
  nos dois bitness. `Integer` empata em i386.
- `TRttiDynamicArrayType` e `TRttiArrayType` são **irmãs** no Delphi. Ramificar por Kind.
- Comparação de `ElementType.Name` sempre por **referência**, nunca literal `'string'`
  ou `'AnsiString'` (o nome difere entre compiladores).
- `Length` no dinâmico levanta nos **dois** backends — paridade semântica é o contrato.
- `ArrayData.ElCount`, **não** `TotalElementCount` no Delphi.
- Cenário 9 **não** cobre Mutação 1. Log da Mutação 1 vem do cenário 8 (`TDynByteArr46`).
- Check `{$IFDEF}` ancorado à coluna zero:
  `grep -cE '^[[:space:]]*\{\$(IFDEF|IFNDEF)' Source/ModernSyntax.RTTI.pas` = **1**
- Contagens no PR: **FPC 37→41, Delphi 35→39** (as duas cascas não empatam no total).

## Checks de aceitação (resumo executivo)

Ver checklist completo em [task-input](pipeline-task-input.md).

- [ ] Dois records declarados: `TModernRTTIArrayType` + `TModernRTTISetType`
- [ ] `FromTypeInfo` sem validar `Kind` em nenhum dos dois
- [ ] XMLDoc de `Length` cita levantamento em dinâmico nos dois compiladores
- [ ] Backend FPC: cinco funções livres + dois helpers + três resourcestrings
- [ ] Backend FPC: ZERO leitura de `elType2Ref`, `elTypeRef`, `CompTypeRef`
- [ ] Backend Delphi: paridade; texto idêntico; LCtx local onde aplicável
- [ ] Quatro fixtures em UScenarios; cenário 8 com quatro asserções
- [ ] FPC 37→41 published; Delphi 35→39 [Test]
- [ ] Mutação 1 verificada (cenário 8 vermelho/AV) — log no PR
- [ ] Mutação 2 verificada (cenário 10 vermelho/AV) — log no PR
- [ ] Build FPC 3.2.2 x86_64 e i386 verdes
- [ ] PR body: `Closes #46`, `Parte de #29`; contagens explícitas com nota de não-empate

## Fontes

- [task-input](pipeline-task-input.md) — briefing operacional completo do arquiteto
- [esp](pipeline-esp.md) — especificação formal
- [plan](pipeline-plan.md) — três slices com código de referência e receita das mutações
