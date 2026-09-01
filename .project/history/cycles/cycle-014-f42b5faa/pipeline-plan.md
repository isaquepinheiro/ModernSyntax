---
type: plan
kind: artifact
title: "PLAN — Tipos de categoria (issue #29): cinco slices independentes"
description: "Cinco slices, cada uma mergeable por si com seu proprio esp acceptance: (1) TModernVisibility + F-1 fix + F-2 add — destrava membros ja entregues; (2) TModernRTTIEnumerationType — uso mais comum na pratica; (3) TModernRTTIPointerType — o unico com subclasse no FPC; (4) TModernRTTIRecordType (Name+Size) — o mais simples; (5) TModernRTTIArrayType + TModernRTTISetType — o par que carrega a assimetria estatico/dinamico (ElType2 vs ElType) e a mutacao obrigatoria de TArray<Integer>. A ordem sugerida na issue e a mesma. Cada slice sai como sub-issue propria via split-proposal.md — este cycle NAO implementa, so desenha e delega."
status: stable
cycle: "014"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/f42b5faad0107a1daea308f52bd50ed4
tags: [modernrtti, plan, issue-29, fpc, delphi, visibility, enumeration, pointer, record, array, set, split]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-01T00:00:00Z"
---

# PLAN — issue #29

**Escopo:** a issue #29 pede seis tipos publicos (categoria de forma).
Cada tipo entrega valor por si: o consumidor pode reflect sobre enum
sem que `TModernRTTIArrayType` exista, e vice-versa. **Este ciclo
recomenda `split`**: cinco sub-issues, uma por slice deste plano — ver
[split-proposal](pipeline-split-proposal.md).

O plano abaixo descreve os cinco slices **como se fossem um PR unico**,
para dar ao arquiteto do split-driver a referencia integral. Cada slice
tem `Aceito quando` proprio e vira, no split, a acceptance da sub-issue
correspondente.

Todas as decisoes vem do [adr](pipeline-adr.md). Todos os criterios comuns e
por-fase estao no [esp](pipeline-esp.md) §4.

## Slice 1 — `TModernVisibility` + F-1 fix + F-2 add

**Fim:** o enum `TModernVisibility` esta declarado na interface publica;
`TModernRTTIMethod.Visibility` devolve `TModernVisibility` (nao mais
`TMemberVisibility`); `TModernRTTIProperty.Visibility: TModernVisibility`
existe. Backend Delphi mapeia 4 cases; backend FPC continua levantando
`EModernRTTIError`. Dois pares de cenarios FPC-only/Delphi-only.

**Por que sozinho:** a Fase 1 destrava dois membros ja entregues em
producao (F-1 corrige vazamento; F-2 fecha drift com API-MAP §2). E
independente dos cinco tipos de forma — sai por si com valor real.

**Arquivos:**

- `Source/ModernSyntax.RTTI.pas`:
  - **Bloco `type` da `interface`, antes de `TModernRTTIField`:**
    ```pascal
    TModernVisibility = (mvPrivate, mvProtected, mvPublic, mvPublished);
    ```
  - **`TModernRTTIMethod` (linha 279 hoje):** trocar `Visibility:
    TMemberVisibility` por `Visibility: TModernVisibility`.
  - **`TModernRTTIProperty` (linhas 101-126 hoje):** adicionar
    `function Visibility: TModernVisibility;` no `public`, apos
    `PropertyType`.
  - **Corpo de `TModernRTTIMethod.Visibility` (linha 866 hoje):**
    passa a chamar `MethodVisibility(FOwner, FToken)` com o novo tipo
    de retorno (assinatura da funcao livre muda).
  - **Corpo novo de `TModernRTTIProperty.Visibility`:**
    `Result := PropertyVisibility(FOwner, FToken);`.
  - **XMLDocs** de `TModernVisibility`, `Method.Visibility`,
    `Property.Visibility` (textos exatos no [esp](pipeline-esp.md) §2).

- `Source/ModernSyntax.RTTI.Delphi.pas`:
  - Assinatura de `MethodVisibility` muda: retorna `TModernVisibility`.
  - Nova funcao `PropertyVisibility` com assinatura equivalente.
  - Corpos com `case`/`if` mapeando os quatro `TypInfo.TMemberVisibility`
    para os quatro `TModernVisibility`.

- `Source/ModernSyntax.RTTI.FPC.pas`:
  - Assinatura de `MethodVisibility` muda: retorna `TModernVisibility`.
  - Nova funcao `PropertyVisibility` idem.
  - Ambos corpos: `Result := Default(TModernVisibility); raise
    EModernRTTIError.Create(SModernRTTIError_<nome>);` — usa
    `resourcestring` ja existente para `MethodVisibility`; adiciona
    `SModernRTTIError_PropertyVisibility` se ainda nao houver mensagem
    especifica.

- `Test Shared/EclbrSystem/UScenarios.RTTI.pas`:
  - Quatro procedures no `interface` (dois pares casca-especificos):
    `Scenario_MethodVisibility_FPC_Raises`,
    `Scenario_MethodVisibility_Delphi_Returns_mvPublished`,
    `Scenario_PropertyVisibility_FPC_Raises`,
    `Scenario_PropertyVisibility_Delphi_Returns_mvPublic`.
  - Corpos com padrao literal do arquivo (`try/except on E: EModernRTTIError`
    + `Fail(...)`; nunca `Assert`, nunca `Exception` generica).
  - Fixtures precisam de uma classe com metodo `published` (para
    `Method.Visibility`) e propriedade `published` (para
    `Property.Visibility`). Reusar `TPortableFixture` do #28 se
    apropriado; caso contrario, adicionar `TVisibilityFixture` no
    `Test Shared/EclbrSystem/UScenarios.RTTI.pas` (mesma unit,
    declaracao junto das outras fixtures).

- `Test FPC/EclbrSystem/UTestMS.RTTI.pas`: dois `published` (os `_FPC_Raises`).
- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas`: dois `[Test]` (os
  `_Delphi_Returns_*`).

**Aceito quando:**

- `PTestRTTI.lpr` compila em x86_64 e i386 (`SKILL.md`, `rm -rf`
  antes de recompilar).
- Delphi compila (declarado no PR).
- Cenarios `_FPC_Raises` e `_Delphi_Returns_*` verdes na sua casca
  respectiva; nao publicados na casca errada.
- `grep -rn "TMemberVisibility" Source/ModernSyntax.RTTI.pas` retorna
  **zero** (`{$IFDEF}` da uses da implementation nao conta — se
  aparecer la, ver adr §D-29.1).
- `grep -c "^function " Source/ModernSyntax.RTTI.FPC.pas` versus
  `Delphi.pas`: **paridade** para as duas novas.
- `grep -n "{\$IFDEF" Source/ModernSyntax.RTTI.pas` continua mostrando
  apenas a diretiva da `uses` da `implementation`.

## Slice 2 — `TModernRTTIEnumerationType`

**Fim:** o record `TModernRTTIEnumerationType` esta declarado no
`interface`; os seis metodos funcionam nos dois compiladores. Dois
cenarios compartilhados.

**Por que sozinho:** e o tipo de forma mais usado na pratica (M-1
sinaliza; enum aparece em quase toda serializacao). Sai por si com
valor claro.

**Arquivos:**

- `Source/ModernSyntax.RTTI.pas`:
  - `TModernRTTIEnumerationType` declarado no bloco `type` da
    `interface` (apos os tipos ja adicionados no slice 1, ou junto
    dos outros records de forma quando slice 1 nao existir).
  - Seis corpos delegam ao backend Delphi/FPC.

- `Source/ModernSyntax.RTTI.Delphi.pas`:
  - Seis funcoes livres novas (`EnumTypeName`, `EnumTypeGetNames`,
    `EnumTypeGetName`, `EnumTypeGetValue`, `EnumTypeMinValue`,
    `EnumTypeMaxValue`) delegando a `TRttiEnumerationType(Rtti.GetType(P))`.

- `Source/ModernSyntax.RTTI.FPC.pas`:
  - **As mesmas seis** assinaturas (paridade estrita).
  - Cada corpo comeca com guarda `if P^.Kind <> tkEnumeration then
    raise EModernRTTIError.CreateFmt(...)` (D-29.5).
  - `EnumTypeMinValue/MaxValue`: `GetTypeData(P)^.MinValue/MaxValue`.
  - `EnumTypeGetName`: `Result := TypInfo.GetEnumName(P, AValue);`.
  - `EnumTypeGetValue`: `Result := TypInfo.GetEnumValue(P, AName);`.
  - `EnumTypeGetNames`: itera de `MinValue` a `MaxValue` chamando
    `GetEnumName`.
  - `EnumTypeName`: `Result := string(P^.Name);` (paridade com como
    outros metodos leem o nome do tipo).

- `Test Shared/EclbrSystem/UScenarios.RTTI.pas`:
  - `type TCor = (cA, cB, cC);` como fixture perto do inicio da
    `implementation` (ou junto das outras fixtures).
  - Dois cenarios: `Scenario_EnumType_ThreeConstants_ContainsAll` e
    `Scenario_EnumType_Name_Returns_TypeName`. Afirmacoes de relacao
    (M-6).

- `Test FPC/EclbrSystem/UTestMS.RTTI.pas`: dois `published`.
- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas`: dois `[Test]`.

**Aceito quando:**

- `PTestRTTI.lpr` compila e passa em x86_64 e i386.
- Delphi compila (declarado).
- Ambos cenarios verdes; `GetValue('cB') = 1`;
  `MaxValue - MinValue + 1 = Length(GetNames)`.
- `grep -c "^function " Source/ModernSyntax.RTTI.FPC.pas` = `Delphi.pas`
  para as seis novas.
- Zero `{$IFDEF}` novo na unit publica.

## Slice 3 — `TModernRTTIPointerType`

**Fim:** o record `TModernRTTIPointerType` esta declarado; `ReferredType`
funciona nos dois compiladores. Um cenario compartilhado com mutacao
obrigatoria.

**Por que sozinho:** e o tipo mais simples do lote — um metodo unico.
Serve para **fechar** o padrao `FToken: PTypeInfo` sem complicacao
adicional; se o padrao aqui esta certo, os proximos herdam. E o candidato
natural a ir logo depois de slice 2, mas nao depende dele.

**Arquivos:**

- `Source/ModernSyntax.RTTI.pas`:
  - `TModernRTTIPointerType` declarado.
  - `ReferredType: TModernRTTIType;` corpo delega ao backend.

- `Source/ModernSyntax.RTTI.Delphi.pas`:
  - `PointerTypeReferredType` delega a `TRttiPointerType(Rtti.GetType(P)).ReferredType`
    (a subclasse existe no Delphi; a superficie publica usa
    `PTypeInfo`).

- `Source/ModernSyntax.RTTI.FPC.pas`:
  - `PointerTypeReferredType` com guarda `Kind = tkPointer`; corpo
    `Result := TModernRTTIType.FromRtti(FContext.GetType(GetTypeData(P)^.RefType));`
    — **property `RefType`**, nunca `RefTypeRef`.
  - Se nao ha `FContext` disponivel no ponto (funcao livre sem
    contexto), o padrao ja em uso e criar um `TRttiContext` local
    dentro do backend FPC — repetir o padrao das funcoes existentes.

- `Test Shared/EclbrSystem/UScenarios.RTTI.pas`:
  - `type PInteger = ^Integer;` como fixture (ou reusar existente).
  - `Scenario_PointerType_ReferredType_Matches`: afirma
    `ReferredType.Name` bate o nome do referido.
  - **Comentario obrigatorio** (mutacao):
    ```pascal
    // MUTACAO OBRIGATORIA: trocar GetTypeData(P)^.RefType por
    // GetTypeData(P)^.RefTypeRef no backend FPC (PointerTypeReferredType)
    // deve tornar este cenario vermelho ou AV. Se ficar verde, a
    // protecao do D-29.4 foi silenciada.
    ```

- `Test FPC/EclbrSystem/UTestMS.RTTI.pas`: um `published`.
- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas`: um `[Test]`.

**Aceito quando:**

- `PTestRTTI.lpr` compila e passa nos dois bitness.
- Delphi compila (declarado).
- Cenario verde.
- Mutacao verificada (trocar `RefType` por `RefTypeRef` no backend
  vira vermelho ou AV — anexar screenshot/log no PR).
- Zero `{$IFDEF}` novo na unit publica.

## Slice 4 — `TModernRTTIRecordType` (Name + Size apenas)

**Fim:** o record `TModernRTTIRecordType` esta declarado; `Name` e
`Size` funcionam. **Sem `GetFields`.** Um cenario compartilhado.

**Por que sozinho:** ate mais simples que slice 3 (dois metodos). Sai
por si; se as issues seguintes atrasarem, ele ja tem valor (permite
reflect sobre tamanho de record — `SizeOf` em tempo de compilacao ja
faz isso, mas com `PTypeInfo` em variavel e a via `Rtti`).

**Arquivos:**

- `Source/ModernSyntax.RTTI.pas`:
  - `TModernRTTIRecordType` declarado com `Name` + `Size`.

- `Source/ModernSyntax.RTTI.Delphi.pas`:
  - `RecordTypeName` delega a `TRttiRecordType(Rtti.GetType(P)).Name`.
  - `RecordTypeSize`: no Delphi, envolve `TypInfo.GetTypeData(P)^.RecSize`
    (Delphi tem o mesmo layout do FPC neste ponto — medir se
    necessario; o padrao consagrado do repo e delegar ao `System.Rtti`
    quando ha metodo, ao `TypInfo` quando nao ha).

- `Source/ModernSyntax.RTTI.FPC.pas`:
  - `RecordTypeName` com guarda `Kind = tkRecord`; retorna `string(P^.Name)`.
  - `RecordTypeSize` com guarda; retorna `GetTypeData(P)^.RecSize`.

- `Test Shared/EclbrSystem/UScenarios.RTTI.pas`:
  - `type TFixture = record A: Integer; B: string; end;` como fixture.
  - `Scenario_RecordType_Size_Equals_SizeOfT`: afirma `Name = 'TFixture'`
    e `Size = SizeOf(TFixture)` (relacao, nao numero).

- `Test FPC/EclbrSystem/UTestMS.RTTI.pas`: um `published`.
- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas`: um `[Test]`.

**Aceito quando:**

- `PTestRTTI.lpr` compila e passa nos dois bitness.
- Delphi compila (declarado).
- Cenario verde; `Size = SizeOf(TFixture)` nos dois bitness (M-6).
- Zero `{$IFDEF}` novo na unit publica.

## Slice 5 — `TModernRTTIArrayType` + `TModernRTTISetType`

**Fim:** os dois records estao declarados; `ElementType`, `Size`,
`Length`, `IsDynamic` (array) e `ElementType` (set) funcionam.
`ArrayType.Length` no dinamico levanta nos dois compiladores. Quatro
cenarios compartilhados; dois com mutacao obrigatoria (`ElType2` no
array dinamico e `CompType` no set).

**Por que sozinho:** e a slice tecnicamente mais delicada — a
assimetria estatico/dinamico do `ElType`, o `TArray<Integer>` obrigatorio,
a guarda por `Kind`, a ramificacao interna. **Concentrar aqui as
armadilhas** facilita o review focar no que importa. Set entra junto
porque compartilha a mesma familia de leitura (`GetTypeData^.<property>^`)
e o mesmo padrao de mutacao (`CompType` → `CompTypeRef`).

**Arquivos:**

- `Source/ModernSyntax.RTTI.pas`:
  - `TModernRTTIArrayType` declarado com `ElementType`, `Size`, `Length`,
    `IsDynamic`.
  - `TModernRTTISetType` declarado com `ElementType`.

- `Source/ModernSyntax.RTTI.Delphi.pas`:
  - `ArrayType*` (quatro funcoes): delegam a
    `TRttiArrayType(Rtti.GetType(P))` (a subclasse existe no Delphi).
    `ArrayTypeLength` no `IsDynamic = True` **levanta** `EModernRTTIError`
    com `SModernRTTIError_DynArrayLength` (paridade semantica).
  - `SetTypeElementType`: delega a `TRttiSetType(Rtti.GetType(P)).ElementType`.

- `Source/ModernSyntax.RTTI.FPC.pas`:
  - Nova `resourcestring` no bloco existente:
    ```pascal
    SModernRTTIError_DynArrayLength = 'comprimento de array dinamico e run-time, nao RTTI; use System.Length(oarray) sobre o valor.';
    ```
  - `ArrayTypeIsDynamic`: `Result := P^.Kind = tkDynArray;` (aceita
    `tkArray` tambem — devolve `False`; qualquer outro kind levanta com
    guarda).
  - `ArrayTypeElementType`: guarda por `Kind in [tkArray, tkDynArray]`;
    ramifica:
    - `tkArray`: `Result := TModernRTTIType.FromRtti(FContext.GetType(GetTypeData(P)^.ArrayData.ElType));`
    - `tkDynArray`: `Result := TModernRTTIType.FromRtti(FContext.GetType(GetTypeData(P)^.ElType2));`
      (**property `ElType2`, nunca o campo cru; nunca `ElType`** — RB-8, M-3).
  - `ArrayTypeSize`: guarda; ramifica `ArrayData.Size` vs `elSize`.
  - `ArrayTypeLength`: guarda; `tkArray` → `ArrayData.ElCount`;
    `tkDynArray` → **`raise EModernRTTIError.Create(SModernRTTIError_DynArrayLength);`**
    (RB-4, D-29.6).
  - `SetTypeElementType`: guarda por `Kind = tkSet`; corpo
    `Result := TModernRTTIType.FromRtti(FContext.GetType(GetTypeData(P)^.CompType));`
    (**property `CompType`, nunca `CompTypeRef`**).

- `Test Shared/EclbrSystem/UScenarios.RTTI.pas`:
  - Fixtures novas (junto das existentes):
    ```pascal
    type
      TStat = array[0..4] of Integer;   // estatico, 5 elementos
      TCoresSet = set of TCor;          // reusa TCor do slice 2 se disponivel;
                                        // senao, declara TCorLocal aqui
    ```
    (`TArray<Integer>` e `TArray<string>` sao aliases da RTL — nao
    precisam de type declarada.)
  - Cenario 7 (`_ArrayType_Static_Integer_LengthAndElementType`): afirma
    `not IsDynamic`, `Length = 5`, `ElementType.Name` = nome do inteiro,
    `Size = SizeOf(TStat)`. Compartilhado.
  - Cenario 8 (`_ArrayType_Dynamic_TArrayInteger_LengthRaises`):
    ```pascal
    // MUTACAO OBRIGATORIA: trocar ElType2 por ElType no backend FPC
    // (ArrayTypeElementType, ramo tkDynArray) deve tornar este cenario
    // vermelho (AV no deref, elemento nao-managed retorna nil).
    // Se ficar verde, a protecao do D-29.4 foi silenciada.
    ```
    Afirma `IsDynamic`, `ElementType.Name` = nome do inteiro,
    `Length` levanta `EModernRTTIError`.
  - Cenario 9 (`_ArrayType_Dynamic_TArrayString_ElementType`): afirma
    `IsDynamic`, `ElementType.Name` = nome da string.
  - Cenario 10 (`_SetType_ElementType_Is_UnderlyingEnum`):
    ```pascal
    // MUTACAO OBRIGATORIA: trocar CompType por CompTypeRef no backend
    // FPC (SetTypeElementType) deve virar vermelho ou AV. Mesma
    // protecao do D-29.4.
    ```
    Afirma `ElementType.Name = 'TCor'`.

- `Test FPC/EclbrSystem/UTestMS.RTTI.pas`: quatro `published`.
- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas`: quatro `[Test]`.

**Aceito quando:**

- `PTestRTTI.lpr` compila e passa nos dois bitness com todos os
  cenarios verdes.
- Delphi compila (declarado).
- Cenario 8 confirma que `Length` de dinamico levanta.
- **Mutacao 1 verificada** (cenario 8): `ElType2` → `ElType` no backend
  FPC vira vermelho ou AV.
- **Mutacao 2 verificada** (cenario 10): `CompType` → `CompTypeRef` no
  backend FPC vira vermelho ou AV.
- `grep -n "elType2Ref\|elTypeRef\|CompTypeRef\|RefTypeRef" Source/ModernSyntax.RTTI.FPC.pas`
  retorna **zero** (nunca campos crus — RB-8).
- Zero `{$IFDEF}` novo na unit publica.

## Ordem sugerida (dentro de qualquer estrategia de split)

1. **Slice 1** — destrava o que ja esta em producao (F-1, F-2). Baixo
   risco, alto sinal.
2. **Slice 2** — Enumeration, o mais comum. Estabelece o padrao
   `FToken: PTypeInfo` + `FromTypeInfo` em um record real.
3. **Slice 3 ou 4** — indiferente; ambos sao simples e independentes.
4. **Slice 5** — o mais delicado (armadilhas concentradas). Deixar por
   ultimo aproveita a familiaridade adquirida nos anteriores.

Se o `split` for aprovado, cada slice vira sub-issue e a ordem acima
vira a sugestao de execucao das sub-issues.

## Nao regressao

- Zero regressao esperada nos 23+ cenarios existentes em
  `UScenarios.RTTI.pas` — os cenarios existentes nao tocam
  `TModernRTTIMethod.Visibility` (`grep -rn "\.Visibility" Test*` = 0 no
  relatorio) e nao usam nenhum dos tipos novos.
- API-MAP §1 recebe uma edicao em prosa (nota "adiada" para
  `IndexedProperty`); §2 fica consistente com o codigo apos a Fase 1.
- `TModernRTTI.GetType` global intocado.
- Runners (`PTestRTTI.lpr`/`.dpr`) nao mudam.
