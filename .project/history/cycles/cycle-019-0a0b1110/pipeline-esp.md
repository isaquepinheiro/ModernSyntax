---
type: spec
kind: artifact
title: "ESP — TModernRTTIArrayType (ElementType, Size, Length, IsDynamic) + TModernRTTISetType (ElementType) nos dois compiladores; duas mutacoes obrigatorias (issue #46)"
description: "Dois records novos em ModernSyntax.RTTI.pas (TModernRTTIArrayType, TModernRTTISetType) com FToken PTypeInfo, factory FromTypeInfo sem guarda; array ramifica publicamente por IsDynamic e Length levanta EModernRTTIError em dinamico nos dois compiladores (paridade semantica); backend FPC usa properties (elType2, ElType, CompType — nunca elType2Ref/elTypeRef/CompTypeRef); backend Delphi delega a TRttiDynamicArrayType/TRttiArrayType (irmas, nao descendente) e TRttiSetType via LCtx local com try/finally; quatro cenarios compartilhados (7 estatico Length=5, 8 TDynByteArr46 com mutacao 1, 9 TDynStrArr46 gerenciado, 10 set of TCor com mutacao 2), asserção de Name por referencia via TModernRTTI.GetType(TypeInfo(...)).Name; +4 publisheds no FPC (37 -> 41), +4 [Test] no Delphi (35 -> 39); duas mutacoes obrigatorias com log no PR; zero {$IFDEF} novo na unit publica (check ancorado em coluna zero, hoje = 1)."
status: draft
cycle: "019"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/0a0b1110fc1826855542e8d75c65cf65
tags: [modernrtti, rtti, spec, issue-46, fpc, delphi, array, set, tmodernrttiarraytype, tmodernrttisettype]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: issue-46
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/46"
    title: "Issue #46 — TModernRTTIArrayType + TModernRTTISetType"
  - id: issue-29-parent
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/29"
    title: "Issue #29 — parent (tipos de categoria RTTI)"
  - id: adr
    resource: "adr.md"
    title: "ADR — issue #46"
  - id: plan
    resource: "plan.md"
    title: "PLAN — issue #46 em 3 slices"
  - id: task-input
    resource: "task-input.md"
    title: "TASK-INPUT — issue #46"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, traps"
  - id: conventions
    resource: "/analysis/05-conventions.md"
    title: "05 Conventions — ModernSyntax"
---

# ESP — issue #46 (TModernRTTIArrayType + TModernRTTISetType)

## 1. Objetivo

Introduzir **dois** records publicos em `Source/ModernSyntax.RTTI.pas`:

- `TModernRTTIArrayType` cobrindo `tkArray` e `tkDynArray`, com
  `IsDynamic`, `ElementType`, `Size` e `Length`. **`Length` levanta
  `EModernRTTIError` em dinamico nos dois compiladores** (paridade
  semantica).
- `TModernRTTISetType` cobrindo `tkSet`, com `ElementType`.

Aditivo puro sob o guarda-chuva da issue #29. Nenhum contrato existente
muda. Zero `{$IFDEF}` novo na unit publica.

## 2. Escopo

### 2.1 Superficie publica (`Source/ModernSyntax.RTTI.pas`)

Declaracoes apos `TModernRTTIRecordType` (issue #45, :699-731), antes
de `TModernRTTI`:

```pascal
TModernRTTIArrayType = record
strict private
  FToken: PTypeInfo;
public
  class function FromTypeInfo(P: PTypeInfo): TModernRTTIArrayType; static;
  function IsDynamic: Boolean;
  function ElementType: TModernRTTIType;
  function Size: Integer;
  function Length: Integer;
end;

TModernRTTISetType = record
strict private
  FToken: PTypeInfo;
public
  class function FromTypeInfo(P: PTypeInfo): TModernRTTISetType; static;
  function ElementType: TModernRTTIType;
end;
```

Corpos na `implementation` apos os do `TModernRTTIRecordType` (:1195-1214):
factories triviais e delegacao as funcoes livres do backend importado.

XMLDoc `///` em cada membro publico. XMLDoc do `Length` cita, verbatim,
o comportamento em dinamico: *"levanta `EModernRTTIError` (`SArrayDynamicLength`) quando o array e dinamico — em ambos os compiladores"*.

### 2.2 Backend FPC (`Source/ModernSyntax.RTTI.FPC.pas`)

Cinco funcoes livres declaradas na `interface`, apos o bloco `-- Record
(issue #45)` (linha 129):

```pascal
function ArrayTypeIsDynamic(P: PTypeInfo): Boolean;
function ArrayTypeElementType(P: PTypeInfo): PTypeInfo;
function ArrayTypeSize(P: PTypeInfo): Integer;
function ArrayTypeLength(P: PTypeInfo): Integer;
function SetTypeElementType(P: PTypeInfo): PTypeInfo;
```

Tres novos `resourcestring` apos `SRecordWrongKind`, com texto identico
ao backend Delphi (D-2/D-43.6):

- `SArrayWrongKind` — mensagem de kind incorreto para array.
- `SArrayDynamicLength = 'TModernRTTIArrayType.Length: nao suportado para arrays dinamicos.'`
- `SSetWrongKind` — mensagem de kind incorreto para set.

Helpers de guarda:

- `ArrayRaiseWrongKind(P)` — guarda **combinada** `(P = nil) or not (P^.Kind in [tkArray, tkDynArray])`. Helper unico ramificando internamente pelo sub-Kind (drift novo do #46; ver [`adr.md`](pipeline-adr.md) §D-46.4).
- `SetRaiseWrongKind(P)` — guarda por `(P = nil) or (P^.Kind <> tkSet)`.

Corpos (chamam o helper como primeira instrucao):

- `ArrayTypeIsDynamic(P)`: `Result := P^.Kind = tkDynArray`.
- `ArrayTypeElementType(P)`:
  - dinamico → `GetTypeData(P)^.elType2` (**propriedade**, nunca
    `elType2Ref` cru).
  - estatico → `GetTypeData(P)^.ArrayData.ElType` (**propriedade**,
    nunca `elTypeRef` cru).
- `ArrayTypeSize(P)`:
  - dinamico → `GetTypeData(P)^.elSize`.
  - estatico → `GetTypeData(P)^.ArrayData.Size` (paridade com Delphi).
- `ArrayTypeLength(P)`:
  - dinamico → `raise EModernRTTIError.Create(SArrayDynamicLength)`.
  - estatico → `GetTypeData(P)^.ArrayData.ElCount` (paridade com Delphi;
    **nao** `TotalElementCount`).
- `SetTypeElementType(P)`: `GetTypeData(P)^.CompType` (**propriedade**,
  nunca `CompTypeRef` cru).

Contexto RTTI: nao ha `TRttiContext` no FPC para essas leituras — todas
sao diretas via `GetTypeData(P)^`.

### 2.3 Backend Delphi (`Source/ModernSyntax.RTTI.Delphi.pas`)

Cinco assinaturas espelhadas na `interface`, apos o bloco `-- Record
(issue #45)` (linha 107).

Tres `resourcestring` locais com **texto identico** ao FPC (D-2/D-43.6).

Helpers `ArrayRaiseWrongKind` e `SetRaiseWrongKind` com as mesmas
guardas do FPC.

Corpos:

- `ArrayTypeIsDynamic(P)`: `Result := P^.Kind = tkDynArray` (identico ao
  FPC — objeto de linguagem).
- `ArrayTypeElementType(P)`: `LCtx` local com `try/finally`; ramifica
  por `Kind`:
  - dinamico → `TRttiDynamicArrayType(LCtx.GetType(P)).ElementType.Handle` (ou property equivalente que devolva `PTypeInfo`).
  - estatico → `TRttiArrayType(LCtx.GetType(P)).ElementType.Handle`.
  - **`TRttiDynamicArrayType` NAO e descendente de `TRttiArrayType`** —
    sao irmas em `System.Rtti` (confirmado na volta 1 da discussao); nao
    existe cast comum, ramifica-se por `Kind` explicitamente.
- `ArrayTypeSize(P)`: paridade objetiva com FPC —
  - dinamico → `GetTypeData(P)^.elSize`.
  - estatico → `GetTypeData(P)^.ArrayData.Size`.
- `ArrayTypeLength(P)`: paridade semantica —
  - dinamico → `raise EModernRTTIError.Create(SArrayDynamicLength)`.
  - estatico → `GetTypeData(P)^.ArrayData.ElCount` (**nao**
    `TotalElementCount` — medicao mostra que `ElCount` ja e o produto de
    todos os graus).
- `SetTypeElementType(P)`: `LCtx` local com `try/finally`;
  `Result := TRttiSetType(LCtx.GetType(P)).ElementType.Handle`.

`LCtx` local com `try/finally` (padrao `RecordTypeName` :505-521 do
Delphi). Onde nao ha `LCtx` (Size, IsDynamic, Length dinamico raise),
nao criar contexto — leitura direta.

### 2.4 Cenarios compartilhados (`Test Shared/EclbrSystem/UScenarios.RTTI.pas`)

Fixtures publicas na secao `type` da `interface`, apos `TRecordFixture45M`
(:218):

```pascal
{ Fixtures para issue #46. }
{ (1) Array estatico — cenario 7. Length = 5, Size = SizeOf(TArr5Int46). }
TArr5Int46 = array[0..4] of Integer;

{ (2) Array dinamico UNMANAGED — cenario 8. Mata Mutacao 1 (elType2 ->
  elType daria AV: Byte tem elType = NIL). Size = 1 mata mutacao
  elSize -> SizeOf(Pointer) sozinha em i386 (4!=1) e x86_64 (8!=1). }
TDynByteArr46 = array of Byte;

{ (3) Array dinamico MANAGED — cenario 9. Cobre path gerenciado.
  Comentario NAO promete cobrir Mutacao 1 (elType do gerenciado nao e
  nil). Comparacao de Name por referencia (FPC = AnsiString, Delphi =
  string). }
TDynStrArr46 = array of string;

{ (4) Set — cenario 10. Mata Mutacao 2 (CompType -> CompTypeRef le
  regiao errada). TCor ja existe em UScenarios.RTTI.pas. }
TSetCor46 = set of TCor;
```

Quatro procedures compartilhadas declaradas na `interface`, apos os
cenarios da issue #45:

```pascal
procedure Scenario_ArrayType_Static_LengthAndSize;
procedure Scenario_ArrayType_Dynamic_LengthRaises;
procedure Scenario_ArrayType_Dynamic_Managed_ElementType;
procedure Scenario_SetType_ElementType;
```

Corpos (padrao `raise ETestScenarioFailed.Create(...)`), com assinaturas
canonicas:

**Cenario 7 — `Scenario_ArrayType_Static_LengthAndSize`:**
```pascal
var LArr: TModernRTTIArrayType;
begin
  LArr := TModernRTTIArrayType.FromTypeInfo(TypeInfo(TArr5Int46));
  if LArr.IsDynamic then
    raise ETestScenarioFailed.Create('TArr5Int46 nao deveria ser dinamico.');
  if LArr.Length <> 5 then
    raise ETestScenarioFailed.Create('Length(TArr5Int46) != 5.');
  if LArr.Size <> SizeOf(TArr5Int46) then
    raise ETestScenarioFailed.Create('Size(TArr5Int46) != SizeOf.');
  if LArr.ElementType.Handle = nil then
    raise ETestScenarioFailed.Create('ElementType(TArr5Int46) nulo.');
end;
```

**Cenario 8 — `Scenario_ArrayType_Dynamic_LengthRaises`** (o que carrega
a Mutacao 1, sobre `TDynByteArr46`):
```pascal
var
  LArr: TModernRTTIArrayType;
  LRaised: Boolean;
begin
  LArr := TModernRTTIArrayType.FromTypeInfo(TypeInfo(TDynByteArr46));
  if not LArr.IsDynamic then
    raise ETestScenarioFailed.Create('TDynByteArr46 deveria ser dinamico.');
  LRaised := False;
  try
    LArr.Length;
  except
    on E: EModernRTTIError do LRaised := True;
  end;
  if not LRaised then
    raise ETestScenarioFailed.Create('Length em dinamico nao levantou.');
  { Mata Mutacao 1: elType2 -> elType daria AV em Byte (elType = NIL). }
  if LArr.ElementType.Name <> TModernRTTI.GetType(TypeInfo(Byte)).Name then
    raise ETestScenarioFailed.Create('ElementType(TDynByteArr46).Name != Byte por referencia.');
  { Mata mutacao elSize -> SizeOf(Pointer): 1 diverge nos dois bitness. }
  if LArr.Size <> 1 then
    raise ETestScenarioFailed.Create('Size(TDynByteArr46) != 1.');
end;
```

**Cenario 9 — `Scenario_ArrayType_Dynamic_Managed_ElementType`**
(comentario **NAO** promete cobrir Mutacao 1):
```pascal
var LArr: TModernRTTIArrayType;
begin
  LArr := TModernRTTIArrayType.FromTypeInfo(TypeInfo(TDynStrArr46));
  if not LArr.IsDynamic then
    raise ETestScenarioFailed.Create('TDynStrArr46 deveria ser dinamico.');
  { Comparacao por referencia — FPC=AnsiString, Delphi=string; absorve
    a divergencia sem {$IFDEF}, mesmo padrao do cenario 10 e do
    Scenario_PointerType_ReferredType_Matches. }
  if LArr.ElementType.Name <> TModernRTTI.GetType(TypeInfo(string)).Name then
    raise ETestScenarioFailed.Create('ElementType(TDynStrArr46).Name != string por referencia.');
end;
```

**Cenario 10 — `Scenario_SetType_ElementType`** (Mutacao 2):
```pascal
var LSet: TModernRTTISetType;
begin
  LSet := TModernRTTISetType.FromTypeInfo(TypeInfo(TSetCor46));
  if LSet.ElementType.Name <> TModernRTTI.GetType(TypeInfo(TCor)).Name then
    raise ETestScenarioFailed.Create('ElementType(TSetCor46).Name != TCor por referencia.');
end;
```

### 2.5 Cascas de teste

- `Test FPC/EclbrSystem/UTestMS.RTTI.pas`: quatro `published procedures`
  novas apos `TestRecordType_NameAndSize` (:93). Cada uma delega em uma
  linha ao cenario compartilhado. Contagem passa de **37 → 41 publisheds**.
- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas`: quatro `[Test]` novos apos
  `TestRecordType_NameAndSize` (:155). Mesma forma. Contagem passa de
  **35 → 39 `[Test]`**.

**As duas cascas nao empatam no total** — o Delphi carrega testes que o
FPC nao compila. A paridade e dos 4 cenarios adicionados, nao do total.

### 2.6 Fora de escopo (out-of-scope, explicito)

- Contagem `Length` em array dinamico. **Explicitamente proibida** — a
  API certa e `System.Length(arr)` em runtime; RTTI de tipo nao carrega
  contagem de instancia. Levanta `EModernRTTIError` nos dois backends.
- `Bounds`/`Dims` de array multidimensional. Nao pedido pela issue; o
  contrato cobre `Length = ElCount` (produto de todos os graus, medido);
  enumerar dimensoes fica para issue nova.
- `SetType.Bytes` / representacao low-level de set. Nao pedido.
- `TypeInfo` de sub-tipos gerenciados alem de `string` (`AnsiString`,
  `UnicodeString`, `WideString`, `TArray<T>` custom). O cenario 9
  compara por referencia — a expansao para outros gerenciados nao muda o
  contrato.
- Cascas extras testando wrong-kind (raise sob `Kind` invalido). Aditivo;
  se o revisor pedir, novo ciclo.

## 3. Regras de negocio

- **B-46.1** — `TModernRTTIArrayType.IsDynamic` devolve `True` se e so se
  `P^.Kind = tkDynArray`; `False` se `Kind = tkArray`; levanta para
  qualquer outro `Kind`.
- **B-46.2** — `Length` **levanta** `EModernRTTIError` com mensagem
  `SArrayDynamicLength` quando `IsDynamic = True`, **nos dois
  compiladores**. Em estatico devolve `GetTypeData(P)^.ArrayData.ElCount`
  (produto de todos os graus para multidimensional).
- **B-46.3** — `Size` no estatico devolve
  `GetTypeData(P)^.ArrayData.Size` (paridade objetiva com Delphi); no
  dinamico devolve `GetTypeData(P)^.elSize` (tamanho do elemento).
- **B-46.4** — `ElementType` no array dinamico e lido via **property**
  `elType2` (FPC) / `TRttiDynamicArrayType.ElementType` (Delphi); no
  estatico via **property** `ArrayData.ElType` (FPC) /
  `TRttiArrayType.ElementType` (Delphi). **Nunca** ler os campos crus
  `elType2Ref`, `elTypeRef`.
- **B-46.5** — `SetType.ElementType` e lido via **property** `CompType`
  (FPC) / `TRttiSetType.ElementType` (Delphi). **Nunca** ler o campo cru
  `CompTypeRef`.
- **B-46.6** — Comparacao de `ElementType.Name` em cenario cross-compiler
  sempre **por referencia** contra `TModernRTTI.GetType(TypeInfo(<tipo>)).Name`.
  FPC devolve `AnsiString`, Delphi devolve `string` para `array of string`;
  literal quebra num dos dois backends.

## 4. Criterios de aceitacao

Absorvem os itens do acceptance da issue #46 mais os deltas fechados nas
tres voltas da discussao:

- [ ] Ambos os records declarados com `strict private FToken: PTypeInfo`
      apos `TModernRTTIRecordType` (:699-731).
- [ ] `TModernRTTIArrayType.IsDynamic` predicado publico.
- [ ] `TModernRTTIArrayType.Length` em dinamico **levanta**
      `EModernRTTIError` (com `SArrayDynamicLength`) **nos dois
      compiladores**.
- [ ] Backend FPC usa **properties** `elType2`, `ElType`, `CompType`;
      **zero** leitura de `elType2Ref`, `elTypeRef`, `CompTypeRef`.
      Check: `grep -n 'elType2Ref\|elTypeRef\|CompTypeRef' Source/ModernSyntax.RTTI.FPC.pas` = **0** (hoje 0, tem de continuar 0).
- [ ] Backend Delphi: `TRttiDynamicArrayType` no dinamico,
      `TRttiArrayType` no estatico (irmas; ramificacao explicita por
      `Kind`, sem cast comum).
- [ ] `resourcestring` `SArrayWrongKind`, `SArrayDynamicLength`,
      `SSetWrongKind` com **texto identico** entre FPC e Delphi
      (D-2/D-43.6). Texto de `SArrayDynamicLength` curto (Q4 da volta 1):
      *"TModernRTTIArrayType.Length: nao suportado para arrays dinamicos."*.
- [ ] Cenario 7 (`Scenario_ArrayType_Static_LengthAndSize`): verde
      (`Length = 5`, `Size = SizeOf(TArr5Int46)`, `IsDynamic = False`,
      `ElementType.Handle <> nil`).
- [ ] Cenario 8 (`Scenario_ArrayType_Dynamic_LengthRaises`) sobre
      `TDynByteArr46`: verde nos quatro checks (`IsDynamic = True`,
      `Length` levanta, `ElementType.Name = TModernRTTI.GetType(TypeInfo(Byte)).Name`, `Size = 1`).
- [ ] Cenario 9 (`Scenario_ArrayType_Dynamic_Managed_ElementType`) sobre
      `TDynStrArr46`: verde. Comentario **NAO** promete cobrir Mutacao 1.
- [ ] Cenario 10 (`Scenario_SetType_ElementType`) sobre `TSetCor46`:
      verde por referencia.
- [ ] **Mutacao 1 verificada** (cenario 8, backend FPC): trocar
      `GetTypeData(P)^.elType2` por `GetTypeData(P)^.elType` em
      `ArrayTypeElementType` deixa o cenario **vermelho/AV** (Byte,
      unmanaged, tem `elType = nil` → acesso a `.Name` sobre `nil`
      levanta AV). Log **do cenario 8** anexado ao PR.
- [ ] **Mutacao 2 verificada** (cenario 10, backend FPC): trocar
      `GetTypeData(P)^.CompType` por
      `PTypeInfo(GetTypeData(P)^.CompTypeRef)` em `SetTypeElementType`
      le regiao errada → cenario **vermelho/AV**. Log **do cenario 10**
      anexado ao PR.
- [ ] Cascas: `TestArrayType_Static_LengthAndSize`,
      `TestArrayType_Dynamic_LengthRaises`,
      `TestArrayType_Dynamic_Managed_ElementType`, `TestSetType_ElementType`
      em cada casca. Corpo de uma linha cada.
- [ ] Contagens: **FPC 37 → 41 publisheds**, **Delphi 35 → 39 `[Test]`**.
      Contagens absolutas divergem — a paridade e dos 4 cenarios novos.
- [ ] **Zero `{$IFDEF}` novo** na unit publica. Check ancorado:
      `grep -cE '^[[:space:]]*\{\$(IFDEF|IFNDEF)' Source/ModernSyntax.RTTI.pas`
      hoje = **1**, tem de continuar **1**.
- [ ] Zero `{$IFDEF FPC}` em `UScenarios.RTTI.pas` (CA-5).
- [ ] Build FPC 3.2.2 x86_64 e i386 verdes; PR body declara compilacao
      Delphi 23.0/37.0 x Win32/Win64 (Diretor mede antes do PR).
- [ ] PR fecha `Closes #46`; mantem `Parte de #29`.

## 5. Restricoes (constraints)

- **D-1 / D-25.1** — a unit publica `ModernSyntax.RTTI.pas` **nao** tem
  `{$IFDEF}` em declaracao de tipo (comentario `:19`).
  `resourcestring` de guarda vive nos backends, nao na unit publica.
- **D-2 / D-43.6** — paridade de assinatura entre backends; texto de
  `resourcestring` de erro identico.
- **D-4** — guarda por `Kind` no ponto de uso. Aqui, dois helpers por
  backend: `ArrayRaiseWrongKind` (guarda combinada `[tkArray,
  tkDynArray]` — drift novo do #46) e `SetRaiseWrongKind` (guarda por
  `tkSet`).
- **D-43.1 / D-44.1 / D-45.1** — `FromTypeInfo` sem guarda de `Kind`.
  Guard exigiria `resourcestring` publica (viola D-1).
- **D-44.5** — Delphi cria `TRttiContext` local; usa `try/finally .Free`.
- **D-5** — fixtures com `TypeInfo()` na secao `type` da `interface` de
  `UScenarios.RTTI.pas`.
- **D-7** — "um cenario, duas cascas": corpo unico em `UScenarios`;
  casca de uma linha em cada projeto (quatro cenarios, quatro cascas
  por lado).
- **CA-4** — zero `{$IFDEF}` novo na unit publica (check ancorado a
  coluna zero — grep cru mente por 11 mencoes em comentario).
- **CA-5** — nenhum `{$IFDEF FPC}` em `UScenarios.RTTI.pas`.
- **Regra de teste 3** — variar a natureza do elemento para nao passar
  por coincidencia (unmanaged/managed, i386/x86_64).
- **Piso Delphi 23.0** — sem `{$IF CompilerVersion}`.

## 6. Riscos

- **R-1 — Implementador troca `elType2` por `elType` no dinamico.**
  Bug latente: `array of Integer` continuaria funcionando (`elType` do
  gerenciado nao e nil), mas `array of Byte` e `array of Integer`
  unmanaged devolveriam `nil`. **Mitigacao:** Mutacao 1 obrigatoria,
  cenario 8 sobre `TDynByteArr46` — mata em qualquer bitness.
- **R-2 — Implementador troca `CompType` por `CompTypeRef` no set.**
  Le regiao errada da uniao. **Mitigacao:** Mutacao 2 obrigatoria,
  cenario 10 sobre `TSetCor46`.
- **R-3 — Fixture do cenario 8 volta a ser `TDynIntArr46 = array of Integer`.**
  Em i386, `elSize(array of Integer) = 4` empata com `SizeOf(Pointer) = 4`;
  a asserção de `Size` so mataria a mutacao `SizeOf(Pointer)` em x86_64.
  **Mitigacao:** ESP §2.4 fixa `TDynByteArr46 = array of Byte`
  (`elSize = 1` diverge nos dois bitness); ADR §D-46.7 registra o
  descarte.
- **R-4 — Implementador escreve `Length` sem levantar em dinamico** ou
  levanta so num backend. Quebra paridade semantica. **Mitigacao:**
  ESP §2.2/2.3 fixa `raise EModernRTTIError.Create(SArrayDynamicLength)`
  nos dois backends; acceptance cita paridade explicita.
- **R-5 — Implementador tenta cast comum entre `TRttiArrayType` e
  `TRttiDynamicArrayType` no Delphi.** Nao existe: sao irmas em
  `System.Rtti`. **Mitigacao:** ESP §2.3 fixa ramificacao por `Kind`.
- **R-6 — Comparacao de `ElementType.Name` por literal.** `array of string`
  produz `AnsiString` no FPC e `string` no Delphi — literal quebra num
  dos dois. **Mitigacao:** ESP §2.4 fixa comparacao por referencia via
  `TModernRTTI.GetType(TypeInfo(<tipo>)).Name`.
- **R-7 — Comentario do cenario 9 promete cobrir Mutacao 1.** Cenario 9
  (`array of string`) passa VERDE com o codigo errado. **Mitigacao:**
  comentario do fixture/cenario 9 diz explicitamente que nao cobre
  Mutacao 1; o log da mutacao no PR e o do cenario 8.
- **R-8 — Implementador confia no grep cru `{$IFDEF}`.** Hoje da 12 no
  main (`1a4323b`), 11 sao mencoes em `///`/`//`. **Mitigacao:** check
  ancorado a coluna zero: `grep -cE '^[[:space:]]*\{\$(IFDEF|IFNDEF)' Source/ModernSyntax.RTTI.pas`.
- **R-9 — PR anuncia "33 → 37 nos dois compiladores".** Numero errado
  (repetido do texto da issue sem reconferir). **Mitigacao:** ESP §2.5
  fixa "37 → 41 FPC, 35 → 39 Delphi".

## 7. Fontes

- Relatorio de investigacao (run `03abedbe5ed05ff078e071ed503f401f`,
  tres voltas) reproduzido verbatim no prompt do ciclo — governa o
  [adr](pipeline-adr.md).
- [adr](pipeline-adr.md) — decisoes desta feature.
- [plan](pipeline-plan.md) — execucao em slices.
- [task-input](pipeline-task-input.md) — handoff operacional.
- [/analysis/05-conventions.md](/analysis/05-conventions.md) — D-1,
  D-2, D-4, D-25.1, CA-5.
- [/SKILL.md](/SKILL.md) — receita FPC, traps.
- [/project-evolution.md](/project-evolution.md) — historico da familia
  `TModernRTTI*Type` sob a issue #29.
