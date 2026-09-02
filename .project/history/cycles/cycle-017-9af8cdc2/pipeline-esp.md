---
type: spec
kind: artifact
title: "ESP — TModernRTTIPointerType: ReferredType nos dois compiladores, mutacao obrigatoria RefType -> RefTypeRef (issue #44)"
description: "Record publico TModernRTTIPointerType em ModernSyntax.RTTI.pas com FToken PTypeInfo, fabrica FromTypeInfo e metodo ReferredType. Backend Delphi delega a TRttiPointerType.ReferredType. Backend FPC opera direto em PTypeInfo/GetTypeData via property RefType (nao RefTypeRef), com guarda por Kind. Dois cenarios compartilhados: fixture PInt44 = ^Integer (Matches) e TypeInfo(Pointer) puro (Nil_ForBarePointer). Mutacao obrigatoria RefType -> PTypeInfo(GetTypeData(P)^.RefTypeRef) vermelha o cenario 1."
status: draft
cycle: "017"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/9af8cdc2e2a54fb129b523e483beaa2d
tags: [modernrtti, rtti, spec, issue-44, fpc, delphi, pointer, tmodernrttipointertype]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-01T00:00:00Z"
sources:
  - id: issue-44
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/44"
    title: "Issue #44 — TModernRTTIPointerType"
  - id: issue-29-parent
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/29"
    title: "Issue #29 — parent (tipos de categoria RTTI)"
  - id: adr
    resource: "adr.md"
    title: "ADR — TModernRTTIPointerType (issue #44)"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, mutacao, traps"
  - id: conventions
    resource: "/analysis/05-conventions.md"
    title: "05 Conventions — ModernSyntax"
---

# ESP — issue #44 (TModernRTTIPointerType)

## 1. Objetivo

Introduzir o record publico `TModernRTTIPointerType` em
`Source/ModernSyntax.RTTI.pas`, com um metodo `ReferredType` que devolve
o `TModernRTTIType` do tipo apontado (o "referred" de um `^T`), com o
mesmo comportamento observavel nos dois backends (Delphi e FPC 3.2.2).
A entrega deriva do padrao consagrado do modulo (`TModernRTTIEnumerationType`,
issue #43) e completa mais uma familia de `TypeInfo.Kind` sob o guarda-chuva
da issue #29.

Aditivo puro: nenhum contrato existente muda; nenhum `{$IFDEF}` novo
entra na unit publica.

## 2. Escopo

### 2.1 Superficie publica (`Source/ModernSyntax.RTTI.pas`)

Um record novo, colocado logo apos `TModernRTTIEnumerationType` (:640):

```pascal
TModernRTTIPointerType = record
strict private
  FToken: PTypeInfo;
public
  class function FromTypeInfo(P: PTypeInfo): TModernRTTIPointerType; static;
  function ReferredType: TModernRTTIType;
end;
```

XMLDoc `///` em cada membro publico:

- `FromTypeInfo`: **nao** valida `Kind` (padrao consagrado; a guarda
  vive nos backends, D-4).
- `ReferredType`: devolve o `TModernRTTIType` do tipo apontado; para
  `PTypeInfo` de `Pointer` puro (sem tipo apontado) devolve um
  `TModernRTTIType` com `IsNil = True`; levanta `EModernRTTIError`
  para token com `Kind` errado.

### 2.2 Backend FPC (`Source/ModernSyntax.RTTI.FPC.pas`)

- Uma funcao livre `PointerTypeReferredType(P: PTypeInfo): TModernRTTIType`
  declarada apos `EnumGetNames` (:119, `interface`) e implementada apos
  o mesmo grupo na `implementation` (:548).
- Abre com guarda: `if (P = nil) or (P^.Kind <> tkPointer) then raise EModernRTTIError.Create(SPointerWrongKind);`.
- Corpo: `Result := TModernRTTIType.FromRtti(LCtx.GetType(GetTypeData(P)^.RefType));`
  onde `LCtx: TRttiContext` e criado por `TRttiContext.Create` **sem**
  `try/finally .Free` (no FPC, `TRttiContext` e record por valor).
- **`RefType` (property de `typinfo.pp`), nunca `RefTypeRef`**. Este e o
  ponto que a mutacao obrigatoria ataca.
- Um `resourcestring` novo no bloco existente (:200): `SPointerWrongKind`.
- Comentario `// MUTACAO OBRIGATORIA` acima do corpo, prescrevendo a forma
  de mutacao com cast: `GetType(PTypeInfo(GetTypeData(P)^.RefTypeRef))`.

### 2.3 Backend Delphi (`Source/ModernSyntax.RTTI.Delphi.pas`)

- Paridade de assinatura (D-2): `PointerTypeReferredType(P: PTypeInfo): TModernRTTIType`
  declarada apos os enumeration helpers na `interface` (:98) e
  implementada na `implementation` (:445).
- Abre com a mesma guarda por `Kind`; corpo:
  ```pascal
  LCtx := TRttiContext.Create;
  try
    Result := TModernRTTIType.FromRtti(TRttiPointerType(LCtx.GetType(P)).ReferredType);
  finally
    LCtx.Free;
  end;
  ```
- **Sem** `is TRttiPointerType` (medicao no relatorio prova que
  `LCtx.GetType(TypeInfo(Pointer))` sempre devolve `TRttiPointerType`,
  nunca nil, nunca levanta).
- **Sem** `try/except` extra.
- Um `resourcestring` novo no bloco local (:119): `SPointerWrongKind`.
- Comentario `// MUTACAO OBRIGATORIA` documenta o alvo (para simetria com
  o FPC; a mutacao real vive no FPC).

### 2.4 Cenarios compartilhados (`Test Shared/EclbrSystem/UScenarios.RTTI.pas`)

- Fixture na secao `type` da `interface` (:182), apos `TDia`:
  `PInt44 = ^Integer;` (rename de `PInteger` para evitar colisao com
  `System.PInteger`/`SysUtils.PInteger` e com a RTL do FPC; o sufixo `44`
  carrega a origem).
- Duas procedures declaradas apos `Scenario_Enumeration_...` (:246):
  - `procedure Scenario_PointerType_ReferredType_Matches;`
  - `procedure Scenario_PointerType_ReferredType_Nil_ForBarePointer;`
- Implementacao apos o bloco da issue #43 (:1143):
  - **Cenario 1 (`Matches`, `TypeInfo(PInt44)`):** duas asserçoes:
    (a) `LReferred.IsNil = False`; (b) `LReferred.Name = TModernRTTI.GetType(TypeInfo(Integer)).Name`.
    Comparacao contra `TModernRTTI.GetType(TypeInfo(Integer)).Name` (nao
    literal `'Integer'`/`'LongInt'`), porque a propria RTL diverge:
    Delphi diz `Integer`, FPC diz `LongInt`. Comentario
    `// MUTACAO OBRIGATORIA` na cabeceira explica a semantica cross-compiler.
  - **Cenario 2 (`Nil_ForBarePointer`, `TypeInfo(Pointer)`):** afirma
    **apenas** `LReferred.IsNil = True`. **Nunca** toca `.Name`
    (`RTTI.pas:846` faz `FType.Name` sem guarda e AVs sobre handle nil;
    fica na issue #49, fora deste ciclo).

### 2.5 Cascas de teste

- `Test FPC/EclbrSystem/UTestMS.RTTI.pas` (:85): duas procedures `published`
  (uma por cenario), corpo de uma linha delegando ao cenario compartilhado.
- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` (:142): duas procedures com
  `[Test]`, mesma forma de uma linha.

### 2.6 Fora de escopo (out-of-scope, explicito)

- **Q5 do relatorio** — teste explicito de wrong-kind (raise sob token
  com `Kind` diferente de `tkPointer`). Aditivo; se o revisor pedir,
  entra em ciclo separado.
- **`.Name` sobre handle nil** — a AV de `RTTI.pas:846` esta registrada
  na issue #49 e nao pertence a este ciclo.
- **Enums de ponteiros generalizados** (`^TRec`, `^string`, etc.) alem
  do que os dois cenarios cobrem: o contrato do metodo os aceita, mas o
  teste nao os enumera — a familia esta representada pelo par
  `PInt44` + `Pointer` puro.
- **Harness de mutacao automatizada.** Overengineering para um caso; a
  evidencia da mutacao e colada manualmente no PR body.

## 3. Regras de negocio

- **B-44.1** — `ReferredType` sobre `PTypeInfo` de `Pointer` puro
  devolve `TModernRTTIType` com `IsNil = True`, nao levanta. Cai
  sozinho pelo caminho normal (`GetTypeData^.RefType = nil` no FPC;
  `TRttiPointerType.ReferredType = nil` no Delphi).
- **B-44.2** — `Name` do tipo referido diverge por compilador (Delphi
  = `Integer`, FPC = `LongInt`). A camada publica **nao normaliza**:
  quem afirma sobre `Name` compara contra `TModernRTTI.GetType(TypeInfo(Integer)).Name`,
  nao contra literal.
- **B-44.3** — O backend FPC usa a **property** `RefType` (nao a
  variavel `RefTypeRef`). A property faz `DerefTypeInfoPtr(RefTypeRef)`
  (`typinfo.pp:3306`); usar a variavel bruta com cast le a regiao
  errada (delta 24 bytes em x86_64, medido no estudo §A-3) — que e o
  que a mutacao obrigatoria expoe.

## 4. Criterios de aceitacao

Da issue #44, checklist expandido com os deltas do relatorio (volta 1):

- [ ] `TModernRTTIPointerType` declarado em `ModernSyntax.RTTI.pas`
      com `strict private FToken: PTypeInfo` e o padrao consagrado.
- [ ] `FromTypeInfo` **nao** valida `Kind` na fabrica.
- [ ] `ReferredType: TModernRTTIType` publico, com XMLDoc `///`.
- [ ] Backend FPC: `PointerTypeReferredType` com guarda por `Kind` e
      corpo usando **property `RefType`** (nao `RefTypeRef`).
- [ ] Backend FPC: `resourcestring SPointerWrongKind` novo.
- [ ] Backend Delphi: `PointerTypeReferredType` com guarda espelhada
      e corpo `TRttiPointerType(LCtx.GetType(P)).ReferredType`, sem
      `is` e sem `try/except` extra.
- [ ] Backend Delphi: `resourcestring SPointerWrongKind` novo (bloco
      local).
- [ ] Cenario `Scenario_PointerType_ReferredType_Matches` verde nos
      dois compiladores, com asserçao de `Name` cross-compiler via
      `TModernRTTI.GetType(TypeInfo(Integer)).Name`.
- [ ] Cenario `Scenario_PointerType_ReferredType_Nil_ForBarePointer`
      verde, afirmando **apenas** `IsNil = True`.
- [ ] Fixture publica `PInt44 = ^Integer;` (nao `PInteger`).
- [ ] Cascas FPC e Delphi com **duas** procedures publicadas cada
      (uma por cenario), corpo de uma linha.
- [ ] **Mutacao verificada** — comentario `// MUTACAO OBRIGATORIA` no
      backend FPC prescreve `PTypeInfo(GetTypeData(P)^.RefTypeRef)`
      com cast; log/patch colado no PR mostrando o cenario 1 vermelho
      (por semantica, nao por erro de compile) e verde de novo apos
      reverter.
- [ ] Zero `{$IFDEF}` novo em `ModernSyntax.RTTI.pas`.
- [ ] Zero `{$IFDEF FPC}` em `UScenarios.RTTI.pas` (CA-5).
- [ ] Build FPC 3.2.2 x86_64 e i386 verdes; PR body declara a
      compilacao Delphi 23.0/37.0 x Win32/Win64 conforme relatorio.
- [ ] PR fecha `Closes #44`; mantem `Parte de #29`.

## 5. Restricoes (constraints)

- **D-1 / D-25.1** — a unit publica `ModernSyntax.RTTI.pas` **nao** tem
  `{$IFDEF}` em declaracao de tipo (:19). `TModernRTTIPointerType` sem
  `{$IFDEF}` interno; `resourcestring` de guarda nao vive aqui.
- **D-2** — paridade de assinatura entre backends: mesmos nomes e
  parametros; a divergencia legitima e apenas o corpo.
- **D-4** — toda funcao livre que toca `PTypeInfo` abre com
  `if (P = nil) or (P^.Kind <> tkPointer)` antes de qualquer operacao.
- **CA-5** — nenhum arquivo de teste tem `{$IFDEF FPC}`. Cenario
  compartilhado sem ramificacao por compilador.
- **Convencao de fixture cross-compiler** — `TypeInfo` de tipo local a
  procedure nao gera dado utilizavel no FPC 3.2.2 (estudo §D); a fixture
  `PInt44` fica na secao `type` da `interface`, seguindo `TCor`/`TDia`
  (`UScenarios.RTTI.pas:146-147`).
- **Padrao "um cenario, duas cascas"** — corpo em `UScenarios.RTTI.pas`;
  cascas de uma linha em cada projeto.
- **Piso Delphi 23.0** — sem `{$IF CompilerVersion}` para features
  garantidas em 23.0+ (compilacao provada nos 4 alvos pelo interlocutor
  do relatorio).
- **Regra de teste "cenario vermelho, nao erro de compile"** — a mutacao
  obrigatoria compila e roda; erro de compile e bug de instrucao, nao
  evidencia de guarda. Por isso o cast explicito na prescricao.

## 6. Riscos

- **R-1 — mutacao literal da issue (`RefTypeRef` sem cast) nao compila.**
  Sem o comentario `// MUTACAO OBRIGATORIA` com cast, o proximo mantenedor
  tenta a forma literal, leva erro de compile, e conclui erroneamente que
  "a guarda funcionou". **Mitigacao:** ESP §2.2 e ADR fixam a forma com
  cast; o `plan.md` reforca; o PR body cola log da mutacao rodada.
- **R-2 — asserçao literal de `Name` quebra num dos compiladores.**
  Delphi diz `Integer`, FPC diz `LongInt`. **Mitigacao:** comparacao
  contra `TModernRTTI.GetType(TypeInfo(Integer)).Name`, nao literal.
  Absorvida pela propria RTL.
- **R-3 — fixture colide com nome de RTL (`PInteger`).** **Mitigacao:**
  fixture renomeada `PInt44` (carrega a origem, distinto em ambos
  compiladores).
- **R-4 — `.Name` sobre handle nil AV no cenario 2.** **Mitigacao:**
  cenario 2 afirma **apenas** `IsNil = True`; jamais toca `.Name`.
  Issue #49 registra o bug do `.Name` sobre nil, mas nao pertence
  a este ciclo.
- **R-5 — `TRttiContext` no FPC nao suporta `.Free`.** **Mitigacao:**
  no backend FPC, `TRttiContext.Create` sem `try/finally .Free`
  (record por valor); no Delphi, `try/finally LCtx.Free` normal.

## 7. Fontes

- Relatorio de investigacao (run `7f780007e3179b6ac2dd4b2565795789`),
  reproduzido verbatim no prompt do ciclo — governa o [adr](pipeline-adr.md).
- [adr](pipeline-adr.md) — decisoes desta feature.
- [plan](pipeline-plan.md) — execucao em slices.
- [task-input](pipeline-task-input.md) — handoff operacional.
- [/analysis/05-conventions.md](/analysis/05-conventions.md) — D-1,
  D-2, D-4, D-25.1, CA-5.
- [/SKILL.md](/SKILL.md) — receita FPC, traps de build e mutacao.
