---
type: plan
kind: artifact
title: "PLAN — issue #46 em 3 slices sequenciais tightly coupled (TModernRTTIArrayType + TModernRTTISetType)"
description: "Tres slices interdependentes: (1) backends FPC e Delphi (cinco funcoes livres cada, tres resourcestrings identicos, helpers ArrayRaiseWrongKind com guarda combinada [tkArray, tkDynArray] e SetRaiseWrongKind; FPC via properties elType2/ElType/CompType; Delphi delega a TRttiDynamicArrayType/TRttiArrayType (irmas) e TRttiSetType via LCtx local; Length dinamico levanta EModernRTTIError nos dois compiladores); (2) casca publica em ModernSyntax.RTTI.pas (dois records novos com FToken PTypeInfo e FromTypeInfo sem guarda; corpos delegam as funcoes livres); (3) quatro fixtures (TArr5Int46, TDynByteArr46, TDynStrArr46, TSetCor46) + quatro cenarios compartilhados (7, 8, 9, 10) + quatro publisheds em cada casca; comparacao de Name por referencia; mutacoes 1 e 2 documentadas com log no PR. Verdict do split guard: fits (6 arquivos, mesmo pattern das issues #43/#44/#45; nenhum slice mergeavel sozinho)."
status: draft
cycle: "019"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/0a0b1110fc1826855542e8d75c65cf65
tags: [modernrtti, plan, issue-46, fpc, delphi, array, set]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — issue #46"
  - id: adr
    resource: "adr.md"
    title: "ADR — issue #46"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, traps"
---

# PLAN — issue #46 (TModernRTTIArrayType + TModernRTTISetType)

## Verdict do split guard

**`fits`** — 3 slices tightly coupled em 6 arquivos, nenhum mergeavel
sozinho. Mesma forma das issues #43, #44, #45 (cycle-016/017/018). Ver
[`esp.md`](pipeline-esp.md) §2 para o escopo completo e [`adr.md`](pipeline-adr.md) para o
racional das doze decisoes (D-46.1..D-46.12).

- **Test 1 (SIZE):** 6 arquivos, ~180-220 linhas liquidas estimadas
  (cinco funcoes livres + tres resourcestrings + dois helpers por backend
  = 4 arquivos backend, ~40 linhas cada; +2 records + 6 corpos + XMLDoc
  na unit publica, ~40 linhas; +4 fixtures + 4 cenarios (com raises e
  comparacao por referencia) em UScenarios, ~80 linhas; +4 procedures de
  uma linha por casca, ~10 linhas cada). Um pouco maior que #45 (~120
  linhas) por conta das quatro funcoes + quatro cenarios + duas mutacoes,
  mas ainda dentro do que um `implement` cobre com folga — estimativa
  ~40-50% do orcamento $20. Bem abaixo do teto de "cinco slices" ou
  "mais de dois pacotes".
- **Test 2 (INDEPENDENCE):** nao. Slice 2 (casca) declara os records
  cujos metodos chamam simbolos declarados na slice 1 (backends). Slice
  3 (fixtures + cenarios + cascas) afirma sobre comportamento produzido
  pelas slices 1 e 2. Nenhum slice merge sozinho: backends sem casca nao
  tem chamador publico; casca sem backend nao liga; testes sem os dois
  nao tem o que testar. Alem disso, os quatro cenarios formam **um so
  contrato observavel** (array estatico, array dinamico + mutacao 1,
  array dinamico gerenciado, set + mutacao 2) — separa-los em issues
  distintas pagaria a sobrecarga fixa quatro vezes por uma feature
  aditiva.

**Decisao:** `fits`. Continuar neste ciclo.

## Ordem das slices

Slices **estritamente sequenciais**: 1 → 2 → 3.

A ordem `backends → casca → teste` (mesma de #45) evita o vai-e-vem
quando a casca for delegar as cinco funcoes por backend. Nao muda
contrato, so ordem de escrita.

## Slice 1 — Backends FPC e Delphi com paridade

**Arquivos:** `Source/ModernSyntax.RTTI.FPC.pas`,
`Source/ModernSyntax.RTTI.Delphi.pas`.

### 1.1 Backend FPC (`ModernSyntax.RTTI.FPC.pas`)

1. Na `interface`, apos o bloco `-- Record (issue #45)` (:129),
   declarar as cinco assinaturas:
   ```pascal
   { -- Array & Set (issue #46) }
   function ArrayTypeIsDynamic(P: PTypeInfo): Boolean;
   function ArrayTypeElementType(P: PTypeInfo): PTypeInfo;
   function ArrayTypeSize(P: PTypeInfo): Integer;
   function ArrayTypeLength(P: PTypeInfo): Integer;
   function SetTypeElementType(P: PTypeInfo): PTypeInfo;
   ```
2. No bloco `resourcestring` (apos `SRecordWrongKind`), adicionar as
   tres mensagens (com anchor de comentario "issue #46"):
   ```pascal
   SArrayWrongKind      = 'TModernRTTIArrayType: TypeInfo does not describe an array type (Kind not in [tkArray, tkDynArray]).';
   SArrayDynamicLength  = 'TModernRTTIArrayType.Length: nao suportado para arrays dinamicos.';
   SSetWrongKind        = 'TModernRTTISetType: TypeInfo does not describe a set type (Kind <> tkSet).';
   ```
   **Textos identicos** no backend Delphi (D-2/D-43.6). Copiar-colar
   entre backends para nao divergir por typo.
3. Na `implementation`, apos `RecordTypeSize` (:1195-1214) e antes do
   proximo bloco (`// --- Context` ou equivalente), adicionar helpers
   e corpos:
   ```pascal
   { -- Array (issue #46) }

   procedure ArrayRaiseWrongKind(P: PTypeInfo);
   begin
     if (P = nil) or not (P^.Kind in [tkArray, tkDynArray]) then
       raise EModernRTTIError.Create(SArrayWrongKind);
   end;

   function ArrayTypeIsDynamic(P: PTypeInfo): Boolean;
   begin
     ArrayRaiseWrongKind(P);
     Result := P^.Kind = tkDynArray;
   end;

   function ArrayTypeElementType(P: PTypeInfo): PTypeInfo;
   begin
     ArrayRaiseWrongKind(P);
     if P^.Kind = tkDynArray then
       Result := GetTypeData(P)^.elType2   { property; NAO elType2Ref }
     else
       Result := GetTypeData(P)^.ArrayData.ElType;   { property; NAO elTypeRef }
   end;

   function ArrayTypeSize(P: PTypeInfo): Integer;
   begin
     ArrayRaiseWrongKind(P);
     if P^.Kind = tkDynArray then
       Result := GetTypeData(P)^.elSize
     else
       Result := GetTypeData(P)^.ArrayData.Size;
   end;

   function ArrayTypeLength(P: PTypeInfo): Integer;
   begin
     ArrayRaiseWrongKind(P);
     if P^.Kind = tkDynArray then
       raise EModernRTTIError.Create(SArrayDynamicLength);
     Result := GetTypeData(P)^.ArrayData.ElCount;
   end;

   { -- Set (issue #46) }

   procedure SetRaiseWrongKind(P: PTypeInfo);
   begin
     if (P = nil) or (P^.Kind <> tkSet) then
       raise EModernRTTIError.Create(SSetWrongKind);
   end;

   function SetTypeElementType(P: PTypeInfo): PTypeInfo;
   begin
     SetRaiseWrongKind(P);
     Result := GetTypeData(P)^.CompType;   { property; NAO CompTypeRef }
   end;
   ```
   Guarda **exclusivamente** por nil ou `Kind` no set; guarda combinada
   `[tkArray, tkDynArray]` no array (D-46.4). **Zero** leitura de
   `elType2Ref`, `elTypeRef`, `CompTypeRef`.

### 1.2 Backend Delphi (`ModernSyntax.RTTI.Delphi.pas`)

1. Na `interface`, apos o bloco `-- Record (issue #45)` (:107),
   declarar as **mesmas** cinco assinaturas (D-2).
2. No bloco `resourcestring` local, adicionar as tres mensagens com
   **texto identico** ao FPC. **Copiar-colar** — nao redigitar.
3. Na `implementation` (apos `RecordTypeSize`), adicionar helpers e
   corpos:
   ```pascal
   { -- Array (issue #46) }

   procedure ArrayRaiseWrongKind(P: PTypeInfo);
   begin
     if (P = nil) or not (P^.Kind in [tkArray, tkDynArray]) then
       raise EModernRTTIError.Create(SArrayWrongKind);
   end;

   function ArrayTypeIsDynamic(P: PTypeInfo): Boolean;
   begin
     ArrayRaiseWrongKind(P);
     Result := P^.Kind = tkDynArray;
   end;

   function ArrayTypeElementType(P: PTypeInfo): PTypeInfo;
   var
     LCtx: TRttiContext;
   begin
     ArrayRaiseWrongKind(P);
     LCtx := TRttiContext.Create;
     try
       if P^.Kind = tkDynArray then
         Result := TRttiDynamicArrayType(LCtx.GetType(P)).ElementType.Handle
       else
         Result := TRttiArrayType(LCtx.GetType(P)).ElementType.Handle;
     finally
       LCtx.Free;
     end;
   end;

   function ArrayTypeSize(P: PTypeInfo): Integer;
   begin
     ArrayRaiseWrongKind(P);
     if P^.Kind = tkDynArray then
       Result := GetTypeData(P)^.elSize
     else
       Result := GetTypeData(P)^.ArrayData.Size;
   end;

   function ArrayTypeLength(P: PTypeInfo): Integer;
   begin
     ArrayRaiseWrongKind(P);
     if P^.Kind = tkDynArray then
       raise EModernRTTIError.Create(SArrayDynamicLength);
     Result := GetTypeData(P)^.ArrayData.ElCount;
   end;

   { -- Set (issue #46) }

   procedure SetRaiseWrongKind(P: PTypeInfo);
   begin
     if (P = nil) or (P^.Kind <> tkSet) then
       raise EModernRTTIError.Create(SSetWrongKind);
   end;

   function SetTypeElementType(P: PTypeInfo): PTypeInfo;
   var
     LCtx: TRttiContext;
   begin
     SetRaiseWrongKind(P);
     LCtx := TRttiContext.Create;
     try
       Result := TRttiSetType(LCtx.GetType(P)).ElementType.Handle;
     finally
       LCtx.Free;
     end;
   end;
   ```
   `LCtx` **local** com `try/finally` em `ArrayTypeElementType` e
   `SetTypeElementType` (padrao `RecordTypeName` :505-521). Onde nao
   ha `LCtx` (`IsDynamic`, `Size`, `Length`), leitura direta via
   `GetTypeData(P)^`.

**Estado ao fim da slice:** backends compilam entre si; sem casca
publica nem teste, nada chama esses simbolos ainda. Compilar isolado
confirma sintaxe. Rodar suite completa e proibido: ela ainda nao muda.

## Slice 2 — Casca publica: `TModernRTTIArrayType` + `TModernRTTISetType`

**Arquivo:** `Source/ModernSyntax.RTTI.pas`.

**O que muda:**

1. Declarar os dois records na `interface`, apos `TModernRTTIRecordType`
   (:699-731), antes de `TModernRTTI`:
   ```pascal
   /// <summary>
   ///  Categoria RTTI para <c>tkArray</c> e <c>tkDynArray</c>. Ramifica
   ///  publicamente por <see cref="IsDynamic"/>.
   /// </summary>
   /// <remarks>
   ///  <see cref="Length"/> levanta <see cref="EModernRTTIError"/>
   ///  (<c>SArrayDynamicLength</c>) quando o array e dinamico — em ambos
   ///  os compiladores (paridade semantica). Use <c>System.Length(arr)</c>
   ///  em runtime para contar instancias.
   /// </remarks>
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

   /// <summary>
   ///  Categoria RTTI para <c>tkSet</c>.
   /// </summary>
   TModernRTTISetType = record
   strict private
     FToken: PTypeInfo;
   public
     class function FromTypeInfo(P: PTypeInfo): TModernRTTISetType; static;
     function ElementType: TModernRTTIType;
   end;
   ```
   XMLDoc `///` em cada membro publico. XMLDoc do `Length` cita, verbatim,
   o comportamento em dinamico.

2. Implementacao na `implementation`, apos os metodos de
   `TModernRTTIRecordType` (:1195-1214):
   ```pascal
   { -- TModernRTTIArrayType (issue #46) }

   class function TModernRTTIArrayType.FromTypeInfo(P: PTypeInfo): TModernRTTIArrayType;
   begin
     Result.FToken := P;
   end;

   function TModernRTTIArrayType.IsDynamic: Boolean;
   begin
     Result := ArrayTypeIsDynamic(FToken);
   end;

   function TModernRTTIArrayType.ElementType: TModernRTTIType;
   begin
     Result := TModernRTTIType.FromTypeInfo(ArrayTypeElementType(FToken));
   end;

   function TModernRTTIArrayType.Size: Integer;
   begin
     Result := ArrayTypeSize(FToken);
   end;

   function TModernRTTIArrayType.Length: Integer;
   begin
     Result := ArrayTypeLength(FToken);
   end;

   { -- TModernRTTISetType (issue #46) }

   class function TModernRTTISetType.FromTypeInfo(P: PTypeInfo): TModernRTTISetType;
   begin
     Result.FToken := P;
   end;

   function TModernRTTISetType.ElementType: TModernRTTIType;
   begin
     Result := TModernRTTIType.FromTypeInfo(SetTypeElementType(FToken));
   end;
   ```
3. **Zero `{$IFDEF}` novo** — herda o unico condicional que ja seleciona
   backend (unico condicional real na coluna zero, ver check ancorado
   D-46.11). Ver [`adr.md`](pipeline-adr.md) §D-46.1.

**Estado ao fim da slice:** unit publica + backends compilam juntos.
Ainda sem teste que chame os records novos.

## Slice 3 — Quatro fixtures + quatro cenarios compartilhados + cascas

**Arquivos:** `Test Shared/EclbrSystem/UScenarios.RTTI.pas`,
`Test FPC/EclbrSystem/UTestMS.RTTI.pas`,
`Test Delphi/EclbrSystem/UTestMS.RTTI.pas`.

### 3.1 Fixtures publicas em `UScenarios.RTTI.pas`

Na secao `type` da `interface`, apos `TRecordFixture45M` (:218):

```pascal
{ Fixtures para issue #46. }

{ Cenario 7 (array estatico) — Length = 5, Size = SizeOf(TArr5Int46). }
TArr5Int46 = array[0..4] of Integer;

{ Cenario 8 (array dinamico UNMANAGED) — mata Mutacao 1 (elType2 ->
  elType daria AV: Byte tem elType = NIL). Size = 1 diverge de
  SizeOf(Pointer) nos DOIS bitness (i386: 4!=1; x86_64: 8!=1). }
TDynByteArr46 = array of Byte;

{ Cenario 9 (array dinamico MANAGED) — cobre path gerenciado.
  Comparacao de Name por referencia (FPC = AnsiString, Delphi = string).
  NAO cobre Mutacao 1: elType do gerenciado nao e nil. }
TDynStrArr46 = array of string;

{ Cenario 10 (set) — mata Mutacao 2 (CompType -> CompTypeRef le regiao
  errada). TCor ja e reusado de cenarios anteriores. }
TSetCor46 = set of TCor;
```

### 3.2 Quatro procedures compartilhadas

Declaracoes na `interface`, apos os cenarios da issue #45:
```pascal
procedure Scenario_ArrayType_Static_LengthAndSize;
procedure Scenario_ArrayType_Dynamic_LengthRaises;
procedure Scenario_ArrayType_Dynamic_Managed_ElementType;
procedure Scenario_SetType_ElementType;
```

Implementacoes na `implementation`, apos o bloco correspondente. Padrao
de falha: `raise ETestScenarioFailed.Create(...)`. Corpos canonicos ja
em [`esp.md`](pipeline-esp.md) §2.4. Reforcos importantes:

- **Cenario 8** carrega **quatro** asserções: `IsDynamic = True`,
  `Length` levanta `EModernRTTIError`, `ElementType.Name` por referencia
  a `TypeInfo(Byte)`, `Size = 1`. **NAO** simplificar para "so raises" —
  as tres outras asserções sao o que mata as mutacoes.
- **Cenario 9** compara `ElementType.Name` por referencia a
  `TypeInfo(string)`. Comentario **NAO** promete cobrir Mutacao 1
  (D-46.9).
- **Cenario 10** compara `ElementType.Name` por referencia a
  `TypeInfo(TCor)`. Mata a Mutacao 2 (`CompType -> CompTypeRef`).

**So igualdade** — `Length = 5`, `Size = 1`, `Size = SizeOf(TArr5Int46)`.
Desigualdade `>=` nao prova nada contra backend constante.

### 3.3 Casca Delphi (`Test Delphi/EclbrSystem/UTestMS.RTTI.pas`)

Apos `TestRecordType_NameAndSize` (:155), antes do `end;` da classe:
```pascal
[Test] procedure TestArrayType_Static_LengthAndSize;
[Test] procedure TestArrayType_Dynamic_LengthRaises;
[Test] procedure TestArrayType_Dynamic_Managed_ElementType;
[Test] procedure TestSetType_ElementType;
```
Implementacoes de uma linha:
```pascal
procedure TTestMS_RTTI.TestArrayType_Static_LengthAndSize;
begin Scenario_ArrayType_Static_LengthAndSize; end;

procedure TTestMS_RTTI.TestArrayType_Dynamic_LengthRaises;
begin Scenario_ArrayType_Dynamic_LengthRaises; end;

procedure TTestMS_RTTI.TestArrayType_Dynamic_Managed_ElementType;
begin Scenario_ArrayType_Dynamic_Managed_ElementType; end;

procedure TTestMS_RTTI.TestSetType_ElementType;
begin Scenario_SetType_ElementType; end;
```

### 3.4 Casca FPC (`Test FPC/EclbrSystem/UTestMS.RTTI.pas`)

Em `published`, apos `TestRecordType_NameAndSize` (:93):
```pascal
procedure TestArrayType_Static_LengthAndSize;
procedure TestArrayType_Dynamic_LengthRaises;
procedure TestArrayType_Dynamic_Managed_ElementType;
procedure TestSetType_ElementType;
```
Corpos identicos aos do Delphi (uma linha delegando).

**Estado ao fim da slice:** todos os cenarios verdes nos dois
compiladores e nos dois bitness. Quatro `[Test]`/`published` novas por
casca (uma so procedure por cenario, com asserções internas).

## Ordem e dependencias

Slices **estritamente sequenciais**: 1 → 2 → 3. Nenhuma paralelizacao
util. O runner de teste (`PTestRTTI.lpr` no FPC, `PTestRTTI.dpr` no
Delphi) tem que ser recompilado do zero (SKILL trap #2:
`rm -rf /tmp/fpcbuild` antes de cada compilacao; senao FPC reporta
verde sobre `.ppu` stale).

## Verificacao das duas mutacoes obrigatorias

**Mutacao 1 (cenario 8, backend FPC):**
1. Trocar em `ArrayTypeElementType` (FPC), no ramo dinamico:
   `GetTypeData(P)^.elType2` → `GetTypeData(P)^.elType`.
2. Recompilar `PTestRTTI` do zero (`rm -rf /tmp/fpcbuild`).
3. Rodar. Cenario 8 deve **falhar** com AV (acesso a `.Name` sobre
   `nil`, porque `Byte` unmanaged tem `elType = nil`).
4. Log copiado para o PR.
5. Reverter a mutacao antes de commitar.

**Mutacao 2 (cenario 10, backend FPC):**
1. Trocar em `SetTypeElementType` (FPC):
   `GetTypeData(P)^.CompType` → `PTypeInfo(GetTypeData(P)^.CompTypeRef)`.
2. Recompilar `PTestRTTI` do zero.
3. Rodar. Cenario 10 deve **falhar** (AV ou nome lixo).
4. Log copiado para o PR.
5. Reverter a mutacao antes de commitar.

## Encerramento

- Build FPC 3.2.2 x86_64 e i386 verdes (obrigatorio; rodados pelo
  implementador).
- Delphi 23.0/37.0 x Win32/Win64: **Diretor mede antes do PR** (nao
  "assumido, confirmar no primeiro build"). PR body cita as medicoes.
- Checks de aceitacao no PR (ancorados):
  - `grep -cE '^[[:space:]]*\{\$(IFDEF|IFNDEF)' Source/ModernSyntax.RTTI.pas` → hoje 1, tem de continuar **1**.
  - `grep -n 'elType2Ref\|elTypeRef\|CompTypeRef' Source/ModernSyntax.RTTI.FPC.pas` → hoje 0, tem de continuar **0**.
- Contagens declaradas: **FPC 37 → 41 publisheds**, **Delphi 35 → 39 `[Test]`**.
  Nao afirmar empate absoluto entre as duas cascas.
- Logs das duas mutacoes obrigatorias anexados ao PR.
- PR unico com `Closes #46` e `Parte de #29`.
