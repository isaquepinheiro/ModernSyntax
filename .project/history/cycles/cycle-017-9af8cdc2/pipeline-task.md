---
type: task
kind: artifact
title: "TASK-017 — TModernRTTIPointerType com ReferredType nos dois compiladores (issue #44)"
description: "Implementar record publico TModernRTTIPointerType com property ReferredType, backends FPC (RefType + MUTACAO OBRIGATORIA) e Delphi (TRttiPointerType), fixture PInt44, dois cenarios compartilhados e mutacao de sanidade."
cycle: "017"
agent: planner
workflow: equipe-feature
node: task
resource: aefos://run/9af8cdc2e2a54fb129b523e483beaa2d
tags: [task, modernrtti, issue-44, fpc, delphi, pointer, feature, cycle-017]
generated:
  by: "equipe-feature@node:task"
  at: "2026-09-01T00:00:00Z"
sources:
  - id: task-input
    resource: "task-input.md"
    title: "TASK-INPUT — TModernRTTIPointerType (issue #44)"
  - id: gh-44
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/44"
    title: "Issue #44 — TModernRTTIPointerType"
---

# TASK-017 — TModernRTTIPointerType (issue #44)

## Rastreamento

**Modo:** MAESTRO MODE — `has_remote: true`, `from_maestro: true`.

A issue [#44](https://github.com/isaquepinheiro/ModernSyntax/issues/44) já existe
como intake do maestro (`aefos:running`). Nenhuma issue nova criada. Nenhum Epic
criado. O card já está em `aefos:running` — estado correto para ciclo in-pipeline.

**Parent Epic:** [#29](https://github.com/isaquepinheiro/ModernSyntax/issues/29) —
link `Parte de #29` mantido no PR body.

**Board:** entrada adicionada em [../project-evolution.md](../../../project-evolution.md)
com estado 🔄 in-pipeline.

**Ciclo:** 017

## Briefing

Implementar `TModernRTTIPointerType` — record público portável que encapsula
`PTypeInfo` de um tipo ponteiro e expõe a property `ReferredType: TModernRTTIType`.
A casca pública fica em `Source/ModernSyntax.RTTI.pas` sem nenhum `{$IFDEF}` novo
(D-1 / D-25.1). Os backends FPC e Delphi implementam a função `PointerTypeReferredType`
com guarda explícita por `Kind` antes de qualquer operação.

## Escopo operacional (síntese)

1. **Casca pública** (`Source/ModernSyntax.RTTI.pas`): declarar
   `TModernRTTIPointerType` com `strict private FToken: PTypeInfo`, após
   `TModernRTTIEnumerationType` (:640); factory `FromTypeInfo` **sem** guarda de
   `Kind`; property pública `ReferredType: TModernRTTIType` com XMLDoc `///`
   (contrato de erro, semântica de `Pointer` puro, nota sobre `Name` cross-compiler).

2. **Backend FPC** (`Source/ModernSyntax.RTTI.FPC.pas`): função livre
   `PointerTypeReferredType` com guarda
   `if (P = nil) or (P^.Kind <> tkPointer) then raise EModernRTTIError.Create(SPointerWrongKind);`
   e corpo usando **property `RefType`** (não `RefTypeRef`).
   `TRttiContext.Create` **sem** `try/finally .Free`. **Sem** `try/except`.
   Comentário `// MUTACAO OBRIGATORIA` acima do corpo prescreve
   `PTypeInfo(GetTypeData(P)^.RefTypeRef)` com cast.
   `resourcestring SPointerWrongKind` adicionado ao bloco existente (:200).

3. **Backend Delphi** (`Source/ModernSyntax.RTTI.Delphi.pas`): paridade de
   assinatura (D-2); mesma guarda por `Kind`; corpo
   `TRttiPointerType(LCtx.GetType(P)).ReferredType` dentro de
   `try/finally LCtx.Free`. **Sem `is TRttiPointerType`**. **Sem `try/except`**.
   `resourcestring SPointerWrongKind` no bloco local (:119), mesma mensagem.

4. **Cenários** (`Test Shared/EclbrSystem/UScenarios.RTTI.pas`): fixture pública
   `PInt44 = ^Integer;` na seção `type` da `interface` (após :182) — **não**
   `PInteger`. Dois cenários compartilhados:
   - `Scenario_PointerType_ReferredType_Matches`: afirma `IsNil = False` e
     `Name = TModernRTTI.GetType(TypeInfo(Integer)).Name` (não literal).
     Comentário `MUTACAO OBRIGATORIA` na cabeça.
   - `Scenario_PointerType_ReferredType_Nil_ForBarePointer`: afirma **apenas**
     `IsNil = True`; **não** toca `.Name`. Comentário `ATENCAO` explica o AV
     de `RTTI.pas:846` e link com issue #49.

5. **Cascas** (`Test FPC/…/UTestMS.RTTI.pas` e `Test Delphi/…/UTestMS.RTTI.pas`):
   duas procedures em cada (`published` no FPC, `[Test]` no Delphi), mesmos nomes,
   corpo de uma linha delegando ao cenário compartilhado.

6. **Mutação de sanidade**: aplicar `RefType` → `PTypeInfo(GetTypeData(P)^.RefTypeRef)`
   no FPC; `rm -rf /tmp/fpcbuild`; rodar suite; ver `Matches` vermelho por semântica
   (não erro de compile); reverter; `rm -rf /tmp/fpcbuild`; rodar; verde.
   Diff + log colados no PR body.

## Arquivos impactados

| Arquivo | Natureza | Delta |
|---------|----------|-------|
| `Source/ModernSyntax.RTTI.pas` | edição | +record + 2 métodos |
| `Source/ModernSyntax.RTTI.FPC.pas` | edição | +1 declaração + 1 resourcestring + 1 função |
| `Source/ModernSyntax.RTTI.Delphi.pas` | edição | +1 declaração + 1 resourcestring + 1 função |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | edição | +PInt44 + 2 declarações + 2 implementações |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | edição | +2 procedures published |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | edição | +2 procedures [Test] |

Nenhum arquivo novo. Nenhum arquivo removido.

## Convenções que governam a implementação

- **D-1 / D-25.1** — zero `{$IFDEF}` novo em `Source/ModernSyntax.RTTI.pas`
- **D-2** — paridade de assinatura nos dois backends
- **D-4** — guarda explícita por `Kind` no FPC
- **CA-5** — zero `{$IFDEF FPC}` em `UScenarios.RTTI.pas`
- **Prefixos:** `T` tipo/record, `A` parâmetros, `L` locais
- **XMLDoc `///`** em todos os membros públicos novos
- **`rm -rf /tmp/fpcbuild`** antes de cada compilação (SKILL Trap #2)
- **Nunca `Assert`; nunca `raise Exception` genérica.** `Fail(...)` em teste;
  `raise EModernRTTIError.Create(...)` em backend.
- **Piso Delphi 23.0** — não adicionar `{$IF CompilerVersion >= ...}` no Delphi.

## Pontos críticos de fricção (do arquiteto)

- **`PInt44`, não `PInteger`** — `PInteger` cria conflito com `System`/`SysUtils`.
- **`TRttiContext.Create` no FPC** não precisa de `.Free` — record por valor.
- **`GetTypeData(P)^.RefType` no FPC é property**, não campo. `RefTypeRef` é o campo
  bruto (autocompletar de IDE pode sugerir — ignorar).
- **`.Name` no cenário 2 é armadilha** — causa AV antes da asserção. Verificar visualmente.
- **Baseline antes de mutar** — compilar verde antes de aplicar mutação.

## Checklist de aceitação (resumido)

Ver checklist completo (14 itens) em [task-input](pipeline-task-input.md).

- [ ] `TModernRTTIPointerType` com `strict private FToken: PTypeInfo` após `TModernRTTIEnumerationType`
- [ ] `FromTypeInfo` sem validar `Kind` na fábrica
- [ ] Property `ReferredType` com XMLDoc `///`
- [ ] Backend FPC: `PointerTypeReferredType` com guarda por `Kind`
- [ ] Backend FPC: body usa property `RefType` (não `RefTypeRef`)
- [ ] Backend FPC: comentário `MUTACAO OBRIGATORIA` com cast correto
- [ ] Backend FPC: `resourcestring SPointerWrongKind`
- [ ] Backend Delphi: paridade + guarda + `TRttiPointerType` sem `is` + `resourcestring`
- [ ] Zero `{$IFDEF}` novo em `Source/ModernSyntax.RTTI.pas`
- [ ] Fixture `PInt44 = ^Integer` (não `PInteger`)
- [ ] 2 cenários compartilhados; cenário 2 **não** toca `.Name`
- [ ] 2 procedures published FPC; 2 [Test] Delphi; mesmos nomes
- [ ] Mutação executada e registrada no PR body
- [ ] Build FPC 3.2.2 x86_64 e i386 verdes
- [ ] PR body declara compilação; fecha `Closes #44`; mantém `Parte de #29`

## Fontes

- [task-input](pipeline-task-input.md) — briefing operacional completo (14 itens de checklist)
- [esp](pipeline-esp.md), [adr](pipeline-adr.md), [plan](pipeline-plan.md) — artefatos de arquitetura do ciclo
