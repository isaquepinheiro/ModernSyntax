---
type: plan
kind: artifact
title: "PLAN — TModernRTTIPointerType em 3 slices sequenciais tightly coupled (issue #44)"
description: "Tres slices interdependentes: (1) casca publica com TModernRTTIPointerType + FromTypeInfo + ReferredType; (2) backends FPC (property RefType + resourcestring novo + comentario MUTACAO OBRIGATORIA com cast) e Delphi (paridade sem is/try-except); (3) fixture PInt44 + dois cenarios em UScenarios.RTTI.pas + duas procedures em cada casca + evidencia de mutacao no PR body. Verdict do split guard: fits (6 arquivos, escopo aditivo mesmo pattern da issue #43, nenhum slice mergeavel isoladamente)."
status: draft
cycle: "017"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/9af8cdc2e2a54fb129b523e483beaa2d
tags: [modernrtti, plan, issue-44, fpc, delphi, pointer]
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
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, mutacao, traps"
---

# PLAN — issue #44 (TModernRTTIPointerType)

## Verdict do split guard

**`fits`** — 3 slices tightly coupled em 6 arquivos, nenhum mergeavel
sozinho. Mesma forma da issue #43 (cycle-016). Ver [`esp.md`](pipeline-esp.md)
§2 para o escopo completo e [`adr.md`](pipeline-adr.md) para o racional das
nove decisoes (D-44.1..D-44.9).

- **Test 1 (SIZE):** 6 arquivos, ~110 linhas de mudanca liquida
  estimada, uma funcao nova por backend + um `resourcestring` novo +
  dois cenarios + duas procedures publicadas por casca. **Menor** que
  a issue #43 (que teve 6 funcoes por backend). Um `implement` cobre
  com folga, ~30-40% do orçamento $20.
- **Test 2 (INDEPENDENCE):** nao. Slice 1 declara o record cujo metodo
  chama simbolo declarado na slice 2 (backend). Slice 3 afirma sobre
  comportamento produzido pelas slices 1 e 2. Nenhum slice merge
  sozinho: a casca sem backend nao liga; o backend sem casca nao tem
  chamador; o teste sem os dois nao ha o que testar.

**Decisao:** `fits`. Continuar neste ciclo.

## Slice 1 — Casca publica: `TModernRTTIPointerType` + `ReferredType`

**Arquivo:** `Source/ModernSyntax.RTTI.pas`.

**O que muda:**

1. Declarar o record na `interface`, apos `TModernRTTIEnumerationType`
   (:640):
   ```pascal
   TModernRTTIPointerType = record
   strict private
     FToken: PTypeInfo;
   public
     class function FromTypeInfo(P: PTypeInfo): TModernRTTIPointerType; static;
     function ReferredType: TModernRTTIType;
   end;
   ```
2. Implementacao na `implementation`, apos os metodos de
   `TModernRTTIEnumerationType` (:1087):
   - `FromTypeInfo` apenas seta `Result.FToken := P` (**sem** guarda
     de `Kind`, D-44.1).
   - `ReferredType` delega: `Result := PointerTypeReferredType(FToken);`.
3. XMLDoc `///` em cada membro publico, cobrindo:
   - Contrato de erros (`ReferredType` levanta `EModernRTTIError` para
     token com `Kind <> tkPointer`).
   - Semantica de `Pointer` puro (`ReferredType` devolve
     `TModernRTTIType` com `IsNil = True`, nao levanta).
   - Divergencia de `Name` cross-compiler (Delphi = `Integer`, FPC =
     `LongInt`) — quem afirmar sobre `Name` deve indireta via
     `TModernRTTI.GetType(TypeInfo(Integer)).Name`.

**Estado ao fim da slice:** casca compila **somente** com a slice 2
(o simbolo `PointerTypeReferredType` vive no backend).

## Slice 2 — Backends FPC e Delphi com paridade

**Arquivos:** `Source/ModernSyntax.RTTI.FPC.pas`, `Source/ModernSyntax.RTTI.Delphi.pas`.

### 2.1 Backend FPC (`ModernSyntax.RTTI.FPC.pas`)

1. Na `interface`, apos `EnumGetNames` (:119), declarar:
   ```pascal
   function PointerTypeReferredType(P: PTypeInfo): TModernRTTIType;
   ```
2. No bloco `resourcestring` existente (:200), adicionar:
   ```pascal
   SPointerWrongKind = 'TModernRTTIPointerType: TypeInfo does not describe a pointer type (Kind <> tkPointer).';
   ```
3. Na `implementation`, apos os enumeration helpers (:548):
   ```pascal
   function PointerTypeReferredType(P: PTypeInfo): TModernRTTIType;
   var
     LCtx: TRttiContext;
   begin
     if (P = nil) or (P^.Kind <> tkPointer) then
       raise EModernRTTIError.Create(SPointerWrongKind);
     LCtx := TRttiContext.Create;
     // MUTACAO OBRIGATORIA (issue #44): trocar `RefType` por
     //   PTypeInfo(GetTypeData(P)^.RefTypeRef)
     // faz Scenario_PointerType_ReferredType_Matches ficar vermelho.
     // A property `RefType` deref-a `RefTypeRef` (typinfo.pp:3306).
     // Usar `RefTypeRef` com cast le regiao errada (delta 24 bytes em x86_64).
     Result := TModernRTTIType.FromRtti(LCtx.GetType(GetTypeData(P)^.RefType));
   end;
   ```
   **Sem `try/finally .Free`** no FPC (record valor). **Sem
   `try/except`** — `IsNil = True` cai sozinho para `Pointer` puro.

### 2.2 Backend Delphi (`ModernSyntax.RTTI.Delphi.pas`)

1. Na `interface`, apos os enumeration helpers (:98), declarar a
   mesma funcao (D-2).
2. No bloco `resourcestring` local (:119), adicionar `SPointerWrongKind`
   (mesma mensagem).
3. Na `implementation` (:445):
   ```pascal
   function PointerTypeReferredType(P: PTypeInfo): TModernRTTIType;
   var
     LCtx: TRttiContext;
   begin
     if (P = nil) or (P^.Kind <> tkPointer) then
       raise EModernRTTIError.Create(SPointerWrongKind);
     LCtx := TRttiContext.Create;
     try
       // MUTACAO OBRIGATORIA (issue #44): documentacao de simetria com o backend FPC.
       // A mutacao real vive em ModernSyntax.RTTI.FPC.pas (property RefType vs RefTypeRef).
       Result := TModernRTTIType.FromRtti(TRttiPointerType(LCtx.GetType(P)).ReferredType);
     finally
       LCtx.Free;
     end;
   end;
   ```
   **Sem `is TRttiPointerType`** (medido nos 4 alvos). **Sem
   `try/except`** extra (medido: nunca levanta).

**Estado ao fim da slice:** unit publica + backends compilam juntos;
testes ainda nao existem.

## Slice 3 — Cenarios compartilhados + cascas + evidencia de mutacao

**Arquivos:** `Test Shared/EclbrSystem/UScenarios.RTTI.pas`,
`Test FPC/EclbrSystem/UTestMS.RTTI.pas`,
`Test Delphi/EclbrSystem/UTestMS.RTTI.pas`.

### 3.1 Fixture publica em `UScenarios.RTTI.pas`

Apos `TDia` na secao `type` da `interface` (:182):
```pascal
{ Fixture para issue #44 (rename de PInteger para evitar colisao
  com System.PInteger/SysUtils.PInteger e a RTL do FPC). Padrao de
  fixture cross-compiler herdado da issue #43. }
PInt44 = ^Integer;
```

### 3.2 Duas procedures compartilhadas

Declaracoes apos os `Scenario_Enumeration_...` (:246):
```pascal
procedure Scenario_PointerType_ReferredType_Matches;
procedure Scenario_PointerType_ReferredType_Nil_ForBarePointer;
```

Implementacao apos o bloco da issue #43 (:1143):

**Cenario 1 — `Matches` (fixture `PInt44`):**
```pascal
procedure Scenario_PointerType_ReferredType_Matches;
var
  LType: TModernRTTIPointerType;
  LReferred: TModernRTTIType;
begin
  // MUTACAO OBRIGATORIA (issue #44): se o backend FPC trocar `RefType` por
  //   PTypeInfo(GetTypeData(P)^.RefTypeRef)
  // este cenario vermelha por semantica (le regiao errada; ~24 bytes em x86_64).
  //
  // Nota cross-compiler: Delphi diz 'Integer', FPC diz 'LongInt' — por isso
  // a asserção compara contra TModernRTTI.GetType(TypeInfo(Integer)).Name,
  // que a propria RTL absorve em cada compilador.
  LType := TModernRTTIPointerType.FromTypeInfo(TypeInfo(PInt44));
  LReferred := LType.ReferredType;
  if LReferred.IsNil then
    Fail('ReferredType(PInt44).IsNil deveria ser False.');
  if LReferred.Name <> TModernRTTI.GetType(TypeInfo(Integer)).Name then
    Fail('ReferredType(PInt44).Name deveria coincidir com Integer.Name da RTL local.');
end;
```

**Cenario 2 — `Nil_ForBarePointer` (`TypeInfo(Pointer)` puro):**
```pascal
procedure Scenario_PointerType_ReferredType_Nil_ForBarePointer;
var
  LType: TModernRTTIPointerType;
  LReferred: TModernRTTIType;
begin
  // ATENCAO: NAO tocar em LReferred.Name aqui — RTTI.pas:846 faz FType.Name
  // sem guarda e AVs sobre handle nil (issue #49 registra e fica fora deste ciclo).
  LType := TModernRTTIPointerType.FromTypeInfo(TypeInfo(Pointer));
  LReferred := LType.ReferredType;
  if not LReferred.IsNil then
    Fail('ReferredType(Pointer) deveria ter IsNil = True.');
end;
```

### 3.3 Cascas de teste

`Test FPC/EclbrSystem/UTestMS.RTTI.pas` (apos linha 85):
```pascal
published
  procedure Test_PointerType_ReferredType_Matches;
  procedure Test_PointerType_ReferredType_Nil_ForBarePointer;
```
```pascal
procedure TTestMS_RTTI.Test_PointerType_ReferredType_Matches;
begin
  UScenarios.RTTI.Scenario_PointerType_ReferredType_Matches;
end;

procedure TTestMS_RTTI.Test_PointerType_ReferredType_Nil_ForBarePointer;
begin
  UScenarios.RTTI.Scenario_PointerType_ReferredType_Nil_ForBarePointer;
end;
```

`Test Delphi/EclbrSystem/UTestMS.RTTI.pas` (apos linha 142) — mesma forma
com atributo `[Test]` em cada procedure.

### 3.4 Mutacao obrigatoria (evidencia manual)

Antes de abrir o PR:

1. `rm -rf /tmp/fpcbuild` (SKILL trap #2).
2. Rodar suite FPC (x86_64 e i386) verde — baseline.
3. Aplicar mutacao no backend FPC:
   trocar `GetTypeData(P)^.RefType` por `PTypeInfo(GetTypeData(P)^.RefTypeRef)`.
4. `rm -rf /tmp/fpcbuild`, recompilar, rodar.
5. Esperar: `Scenario_PointerType_ReferredType_Matches` vermelho por
   semantica (lê 24 bytes adiante).
6. Reverter, `rm -rf /tmp/fpcbuild`, recompilar — verde de novo.
7. Colar `diff` + trecho do log `red -> reverted -> green` no corpo do PR.

**Estado ao fim da slice:** todos os cenarios verdes nos dois
compiladores; mutacao provada e reversao provada.

## Ordem e dependencias

Slices **estritamente sequenciais**: 1 → 2 → 3. Nenhuma paralelizacao
util (todos os arquivos sao pequenos e a compilacao FPC exige a
propria unit `ModernSyntax.RTTI.FPC.pas` completa antes de o teste
linkar).

## Encerramento

- Build FPC 3.2.2 x86_64 e i386 verdes (obrigatorio).
- Delphi 23.0/37.0 × Win32/Win64: **relatorio ja atesta compilacao**;
  o PR body cita isso literalmente, sem "assumido, confirmar no
  primeiro build".
- PR unico com `Closes #44` e `Parte de #29`.
- Diff + log da mutacao colados no PR body.
