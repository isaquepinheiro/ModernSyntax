---
type: task-input
kind: artifact
title: "TASK-INPUT — Implementar TModernRTTIPointerType com property RefType no FPC, paridade no Delphi, dois cenarios e mutacao obrigatoria (issue #44)"
description: "Handoff operacional para o implementador: record publico TModernRTTIPointerType em ModernSyntax.RTTI.pas (FToken PTypeInfo, FromTypeInfo sem guarda de Kind, ReferredType); backend FPC com PointerTypeReferredType usando property RefType (nao RefTypeRef), guarda por Kind, resourcestring SPointerWrongKind e comentario MUTACAO OBRIGATORIA prescrevendo PTypeInfo(GetTypeData(P)^.RefTypeRef) com cast; backend Delphi com paridade sem is TRttiPointerType e sem try/except extra; fixture PInt44 = ^Integer em UScenarios.RTTI.pas; dois cenarios (Matches com asserção de Name cross-compiler; Nil_ForBarePointer com apenas IsNil = True); duas procedures em cada casca; mutacao provada e diff + log colados no PR body; PR unico fechando #44."
status: draft
cycle: "017"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/9af8cdc2e2a54fb129b523e483beaa2d
tags: [modernrtti, task-input, issue-44, fpc, delphi, pointer, feature]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-01T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — TModernRTTIPointerType (issue #44)"
  - id: adr
    resource: "adr.md"
    title: "ADR — TModernRTTIPointerType (issue #44)"
  - id: plan
    resource: "plan.md"
    title: "PLAN — TModernRTTIPointerType em 3 slices (issue #44)"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, mutacao, traps"
---

# TASK-INPUT — issue #44 (TModernRTTIPointerType)

## Titulo (para commit / PR)

`feat(rtti): TModernRTTIPointerType com ReferredType nos dois compiladores (Closes #44, parte de #29)`

## Tipo / labels

- Tipo: `feature`
- Labels sugeridos: `enhancement`, `rtti`, `fpc`, `delphi`
- Milestone / parent: `Parte de #29`
- Fecha: `Closes #44`

## Escopo (o que muda, arquivo por arquivo)

| Arquivo | Natureza | Delta |
|---|---|---|
| `Source/ModernSyntax.RTTI.pas` | edicao | +record `TModernRTTIPointerType` (apos :640) + 2 metodos na implementation (apos :1087); zero `{$IFDEF}` novo |
| `Source/ModernSyntax.RTTI.FPC.pas` | edicao | +1 declaracao (apos :119), +1 `resourcestring` (bloco :200), +1 funcao (apos :548) com property `RefType` e comentario `MUTACAO OBRIGATORIA` com cast |
| `Source/ModernSyntax.RTTI.Delphi.pas` | edicao | +1 declaracao (apos :98), +1 `resourcestring` local (bloco :119), +1 funcao (apos :445) com `TRttiPointerType(...).ReferredType`, sem `is`, sem `try/except` extra |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | edicao | +1 fixture `PInt44 = ^Integer;` (apos :182), +2 declaracoes (apos :246), +2 implementacoes (apos :1143) |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | edicao | +2 procedures `published` (apos :85), corpo de uma linha cada |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | edicao | +2 procedures `[Test]` (apos :142), corpo de uma linha cada |

**Nenhum arquivo novo. Nenhum arquivo removido.**

## Checklist de aceitacao (12 itens)

- [ ] `TModernRTTIPointerType` declarado apos `TModernRTTIEnumerationType`
      (:640), com `strict private FToken: PTypeInfo`, `FromTypeInfo`
      **sem** guarda de `Kind`, `ReferredType: TModernRTTIType` publico
      com XMLDoc `///` (contrato de erro, semantica de `Pointer` puro,
      nota sobre `Name` cross-compiler).
- [ ] Backend FPC: `PointerTypeReferredType` com guarda
      `if (P = nil) or (P^.Kind <> tkPointer) then raise EModernRTTIError.Create(SPointerWrongKind);`
      e corpo usando **property `RefType`** (**nao `RefTypeRef`**).
      `TRttiContext.Create` **sem** `try/finally .Free`. **Sem**
      `try/except`.
- [ ] Backend FPC: `resourcestring SPointerWrongKind` adicionado ao
      bloco existente (:200).
- [ ] Backend FPC: comentario `// MUTACAO OBRIGATORIA` acima do corpo
      prescreve **`PTypeInfo(GetTypeData(P)^.RefTypeRef)` com cast**
      (nao a forma literal da issue, que nao compila).
- [ ] Backend Delphi: `PointerTypeReferredType` com **mesma** guarda
      por `Kind`; corpo `TRttiPointerType(LCtx.GetType(P)).ReferredType`
      dentro de `try/finally LCtx.Free`. **Sem `is TRttiPointerType`**.
      **Sem `try/except`**.
- [ ] Backend Delphi: `resourcestring SPointerWrongKind` no bloco local
      (:119), mesma mensagem.
- [ ] `UScenarios.RTTI.pas`: fixture publica `PInt44 = ^Integer;` na
      secao `type` da `interface` (apos :182), **nao** `PInteger`.
- [ ] `UScenarios.RTTI.pas`: `Scenario_PointerType_ReferredType_Matches`
      declara `LType: TModernRTTIPointerType`, `LReferred: TModernRTTIType`;
      afirma `IsNil = False` e
      `Name = TModernRTTI.GetType(TypeInfo(Integer)).Name` (nao literal);
      comentario `MUTACAO OBRIGATORIA` na cabeceira.
- [ ] `UScenarios.RTTI.pas`: `Scenario_PointerType_ReferredType_Nil_ForBarePointer`
      afirma **apenas** `IsNil = True`; **nao** toca `.Name`;
      comentario `ATENCAO` explica o AV de `RTTI.pas:846` e o link
      com issue #49.
- [ ] Cascas FPC e Delphi cada uma com **duas** procedures publicadas
      (uma por cenario), corpo de uma linha delegando ao cenario
      compartilhado.
- [ ] Mutacao verificada: aplicar `RefType` -> `PTypeInfo(GetTypeData(P)^.RefTypeRef)`
      no FPC, `rm -rf /tmp/fpcbuild`, rodar suite, ver
      `Scenario_PointerType_ReferredType_Matches` vermelho por semantica
      (**nao** erro de compile); reverter, `rm -rf /tmp/fpcbuild`,
      rodar, ver verde de novo; colar diff + trecho do log no PR body.
- [ ] Zero `{$IFDEF}` novo em `ModernSyntax.RTTI.pas`; zero
      `{$IFDEF FPC}` em `UScenarios.RTTI.pas`.
- [ ] Build FPC 3.2.2 x86_64 e i386 verdes (rodados pelo implementador).
- [ ] PR body declara: `compiled on FPC 3.2.2 x86_64 e i386; Delphi
      23.0/37.0 × Win32/Win64 compilado por autor do relatorio` (nao
      "assumido"); fecha `Closes #44`; mantem `Parte de #29`.

## Convencoes obrigatorias

- **D-1 / D-25.1** — nenhum `{$IFDEF}` em `Source/ModernSyntax.RTTI.pas`
  (declaracao ou implementacao). `resourcestring` de guarda vive no
  backend, nao na unit publica.
- **D-2** — paridade de assinatura entre `ModernSyntax.RTTI.FPC.pas` e
  `ModernSyntax.RTTI.Delphi.pas`.
- **D-4** — cada funcao livre sobre `PTypeInfo` abre com
  `if (P = nil) or (P^.Kind <> tkPointer)`.
- **CA-5** — nenhum `{$IFDEF FPC}` em teste.
- **Prefixos:** `T` tipo/record, `A` parametros, `L` locais.
- **XMLDoc `///`** em todos os membros publicos novos.
- **`rm -rf /tmp/fpcbuild`** antes de cada compilacao (SKILL trap #2).
- **Nunca `Assert`; nunca `raise Exception` generica.** Usar `Fail(...)`
  em teste; `raise EModernRTTIError.Create(...)` em backend.
- **Piso Delphi 23.0** — **nao** adicionar `{$IF CompilerVersion >= ...}`
  no backend Delphi.

## Provaveis pontos de fricao (dicas do arquiteto)

- **Namespace conflict do `PInteger`.** Se o implementador digitar
  `PInteger` por reflexo, tanto `System.PInteger` quanto `SysUtils.PInteger`
  entram em jogo — nome tem que ser `PInt44`, ponto.
- **`TRttiContext.Create` no FPC nao precisa de `.Free`** — record por
  valor. Adicionar `try/finally` no FPC compila mas e ceremonia morta.
- **`GetTypeData(P)^.RefType` no FPC** e **property**, nao campo.
  Autocompletar de IDE pode mostrar `RefTypeRef` (campo bruto) —
  ignorar; `RefType` e o correto.
- **`.Name` no cenario 2 e armadilha.** Se acidentalmente escrever
  `LReferred.Name` (mesmo em `Fail(...)` de diagnostico), o teste AVs
  antes de rodar a asserção. Verificar visualmente antes de commitar.
- **Ordem de execucao da mutacao:** compilar baseline **antes** de
  mutar; se pular baseline, um build quebrado pre-existente sera
  confundido com efeito da mutacao.

## Fontes

- [esp](pipeline-esp.md) — especificacao formal.
- [adr](pipeline-adr.md) — nove decisoes derivadas do relatorio de investigacao.
- [plan](pipeline-plan.md) — tres slices com codigo de referencia.
- [/SKILL.md](/SKILL.md) — receita FPC, dois traps, comando de build.
- [/analysis/05-conventions.md](/analysis/05-conventions.md) — D-1,
  D-2, D-4, D-25.1, CA-5.
