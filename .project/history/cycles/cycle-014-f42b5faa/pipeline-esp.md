---
type: spec
kind: artifact
title: "ESP — Tipos de categoria: Visibility, Enumeration, Pointer, Record (Name+Size), Array, Set (issue #29)"
description: "Estreia dos seis tipos publicos que fecham a categoria de forma da ModernRTTI: TModernVisibility (com fix de vazamento em Method.Visibility e adicao em Property.Visibility), TModernRTTIEnumerationType, TModernRTTIPointerType, TModernRTTIRecordType (Name+Size apenas), TModernRTTIArrayType (com predicado IsDynamic e Length que levanta em dinamico), TModernRTTISetType. Todos os records de forma guardam FToken: PTypeInfo (nao FType: TRttiType, porque as subclasses correspondentes nao existem no FPC 3.2.2). Backend FPC le tudo via GetTypeData(P), sempre pelas properties (nunca campos *Ref crus), sempre com guarda por Kind (D-27 novo). IndexedProperty sai desta issue e vira issue propria com label blocked:fpc-3.4."
status: draft
cycle: "014"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/f42b5faad0107a1daea308f52bd50ed4
tags: [modernrtti, rtti, spec, issue-29, fpc, delphi, visibility, enumeration, pointer, record, array, set]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-01T00:00:00Z"
sources:
  - id: issue-29-report
    title: "REPORT — Issue #29 (run 92a207d48a895a4eee7c18abae08aea8) — PRESENT"
  - id: api-map
    resource: "/strategy/2026-08-27-modernrtti/API-MAP.md"
    title: "ModernRTTI API-MAP (§1, §2, §7)"
  - id: prd
    resource: "/strategy/2026-08-27-modernrtti/PRD.md"
    title: "PRD — CA-5"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, mutacao, traps"
  - id: adr-025
    resource: "/history/cycles/cycle-010-a36e1364/pipeline-adr.md"
    title: "D-25 — Fail(...) sempre; dois cenarios distintos"
  - id: adr-026
    resource: "/history/cycles/cycle-011-38e3bcee/pipeline-adr.md"
    title: "D-26 — nao silenciar divergencia"
  - id: adr-028
    resource: "/history/cycles/cycle-013-5a8dfb58/pipeline-adr.md"
    title: "D-28.2 — Pointer em record e seguro enquanto o record nao e dono"
---

# ESP — issue #29

## 1. Objetivo

Fechar a **categoria de forma** da ModernRTTI: seis tipos publicos que
descrevem a FORMA de um tipo (nao um membro dele) — todos compilando e
funcionando **nos dois compiladores** e **nos dois bitness**, sem
`{$IFDEF FPC}` no consumidor (CA-5 do PRD) e sem `{$IFDEF}` fora da
`uses` da `implementation` (API-MAP §7).

Os seis tipos, na ordem entregue:

1. **`TModernVisibility`** — enum publico proprio; fecha o vazamento
   de `TMemberVisibility` (do `TypInfo`) em
   `TModernRTTIMethod.Visibility` (F-1) e adiciona
   `TModernRTTIProperty.Visibility` que a API-MAP §2 promete e o codigo
   nao entrega (F-2).
2. **`TModernRTTIEnumerationType`** — `Name`, `GetNames`, `GetName`,
   `GetValue`, `MinValue`, `MaxValue`.
3. **`TModernRTTIPointerType`** — `ReferredType`.
4. **`TModernRTTIRecordType`** — `Name` + `Size` **apenas** (sem
   `GetFields`, que vira issue propria condicionada a medir
   `TRecordElement.Name` num FPC vivo).
5. **`TModernRTTIArrayType`** — `ElementType`, `Size`, `Length`,
   `IsDynamic`. `Length` **levanta** `EModernRTTIError` em dinamico
   nos dois compiladores (capacidade e run-time, nao RTTI).
6. **`TModernRTTISetType`** — `ElementType`.

**`TModernRTTIIndexedProperty` fica fora desta issue** — `IndexedProperty`
nao aparece uma vez em `rtti.pp` do FPC 3.2.2; 100% da superficie
publica seria D-25.4 no FPC, qualitativamente diferente dos outros
seis (que entregam fonte real em pelo menos um membro). Vira issue
propria com label `blocked:fpc-3.4`. A API-MAP §1 recebe nota "adiada".

## 2. Escopo

### Inclui

- **Novo enum publico** em `Source/ModernSyntax.RTTI.pas`, declarado no
  bloco `type` da `interface` **antes de `TModernRTTIField`**:
  ```pascal
  TModernVisibility = (mvPrivate, mvProtected, mvPublic, mvPublished);
  ```

- **Alteracao de assinatura publica** em `TModernRTTIMethod`
  (`Source/ModernSyntax.RTTI.pas:279` hoje): `Visibility:
  TMemberVisibility` vira `Visibility: TModernVisibility`. Isso **quebra
  o contrato binario interno** — busca `\.Visibility` em `Test*` da
  arvore retorna 0 resultados hoje; nenhum teste existente quebra.

- **Novo membro publico** em `TModernRTTIProperty` (linhas 101-126 hoje):
  `Visibility: TModernVisibility` — a API-MAP §2 promete que este membro
  existe e "esta OK"; o codigo nao o tem (F-2). A entrega remove o drift.

- **Seis novos records publicos** de forma, todos na mesma unit e mesmo
  bloco `type`, todos com o mesmo shape:
  ```pascal
  TModernRTTIEnumerationType = record
  private
    FToken: PTypeInfo;
  public
    class function FromTypeInfo(P: PTypeInfo): TModernRTTIEnumerationType; static;
    function Name: string;
    function GetNames: TArray<string>;
    function GetName(AValue: Integer): string;
    function GetValue(const AName: string): Integer;
    function MinValue: Integer;
    function MaxValue: Integer;
  end;

  TModernRTTIPointerType = record
  private
    FToken: PTypeInfo;
  public
    class function FromTypeInfo(P: PTypeInfo): TModernRTTIPointerType; static;
    function ReferredType: TModernRTTIType;
  end;

  TModernRTTIRecordType = record
  private
    FToken: PTypeInfo;
  public
    class function FromTypeInfo(P: PTypeInfo): TModernRTTIRecordType; static;
    function Name: string;
    function Size: Integer;
  end;

  TModernRTTIArrayType = record
  private
    FToken: PTypeInfo;
  public
    class function FromTypeInfo(P: PTypeInfo): TModernRTTIArrayType; static;
    function ElementType: TModernRTTIType;
    function Size: Integer;
    function Length: Integer;
    function IsDynamic: Boolean;
  end;

  TModernRTTISetType = record
  private
    FToken: PTypeInfo;
  public
    class function FromTypeInfo(P: PTypeInfo): TModernRTTISetType; static;
    function ElementType: TModernRTTIType;
  end;
  ```
  Nenhum destes records e dono de heap: `FToken` aponta para `PTypeInfo`
  **estatico do binario** (referencia nao-dona; D-28.2). Copia por valor
  e trivialmente segura. Duas fabricas convivem: `TModernRTTIType` segue
  com `FromRtti(TRttiType)` (inalterado); os seis novos usam
  `FromTypeInfo(P: PTypeInfo)`. Custo aceito na volta 1 do relatorio.

- **Nova exception publica**: reusar `EModernRTTIError` (ja existe).
  Nenhuma exception nova.

- **Backend Delphi** (`Source/ModernSyntax.RTTI.Delphi.pas`):
  - `MethodVisibility` (linhas 74/236 hoje) muda o **tipo de retorno**
    para `TModernVisibility`; corpo mapeia os 4 cases 1-para-1
    (`mvPrivate` ↔ `TypInfo.mvPrivate`, `mvProtected` ↔ `mvProtected`,
    `mvPublic` ↔ `mvPublic`, `mvPublished` ↔ `mvPublished`).
  - Nova funcao `PropertyVisibility(AOwner: TClass; AToken: Pointer):
    TModernVisibility` — le do RTTI nativo do Delphi (a mesma familia
    de dado que `MethodVisibility` le).
  - **Doze novas funcoes livres** em paridade estrita com o backend FPC,
    uma por membro dos cinco records de forma:
    ```pascal
    function EnumTypeName(P: PTypeInfo): string;
    function EnumTypeGetNames(P: PTypeInfo): TArray<string>;
    function EnumTypeGetName(P: PTypeInfo; AValue: Integer): string;
    function EnumTypeGetValue(P: PTypeInfo; const AName: string): Integer;
    function EnumTypeMinValue(P: PTypeInfo): Integer;
    function EnumTypeMaxValue(P: PTypeInfo): Integer;
    function PointerTypeReferredType(P: PTypeInfo): TModernRTTIType;
    function RecordTypeName(P: PTypeInfo): string;
    function RecordTypeSize(P: PTypeInfo): Integer;
    function ArrayTypeElementType(P: PTypeInfo): TModernRTTIType;
    function ArrayTypeSize(P: PTypeInfo): Integer;
    function ArrayTypeLength(P: PTypeInfo): Integer;
    function ArrayTypeIsDynamic(P: PTypeInfo): Boolean;
    function SetTypeElementType(P: PTypeInfo): TModernRTTIType;
    ```
    Corpos delegam a `TRttiEnumerationType(Rtti.GetType(P))`,
    `TRttiPointerType(Rtti.GetType(P))`, etc. `ArrayTypeLength` no
    dinamico **levanta** `EModernRTTIError` (paridade semantica com o
    FPC — length de dinamico e run-time nos dois lados).

- **Backend FPC** (`Source/ModernSyntax.RTTI.FPC.pas`):
  - `MethodVisibility` (linhas 96/356 hoje) muda o **tipo de retorno**
    para `TModernVisibility`; corpo **continua levantando**
    `EModernRTTIError` (D-25.4 preservado); usa `Result := Default(TModernVisibility)`
    apenas para o tipo do Result compilar antes do `raise`.
  - `PropertyVisibility` **existe** no FPC como funcao livre com a mesma
    assinatura publica que o Delphi (paridade estrita — API-MAP §7); o
    corpo levanta `EModernRTTIError` porque `TypInfo.TPropInfo` do FPC
    3.2.2 nao expoe visibilidade, exatamente como acontece com
    `MethodVisibility` hoje.
  - As **mesmas doze funcoes livres** em paridade estrita, cada uma
    comecando com **guarda por `Kind`** (D-27 novo). Origem dos dados
    (medida no relatorio, seccao "Tabela de origem"):
    | funcao | leitura no FPC |
    |---|---|
    | `EnumTypeMinValue/MaxValue` | `GetTypeData(P)^.MinValue/MaxValue` (guarda por `tkEnumeration`) |
    | `EnumTypeGetName/GetValue/Names` | `TypInfo.GetEnumName(P,N)` / `TypInfo.GetEnumValue(P,S)` |
    | `PointerTypeReferredType` | `GetTypeData(P)^.RefType^` **(property, nunca `RefTypeRef`)** |
    | `RecordTypeSize` | `GetTypeData(P)^.RecSize` (guarda por `tkRecord`) |
    | `ArrayTypeIsDynamic` | `P^.Kind = tkDynArray` |
    | `ArrayTypeElementType` (estatico) | `GetTypeData(P)^.ArrayData.ElType^` |
    | `ArrayTypeElementType` (dinamico) | **`GetTypeData(P)^.ElType2^`** (property; `ElType` retorna `nil` para elemento nao-managed e da AV no deref) |
    | `ArrayTypeSize` (estatico) | `GetTypeData(P)^.ArrayData.Size` |
    | `ArrayTypeSize` (dinamico) | `GetTypeData(P)^.elSize` |
    | `ArrayTypeLength` (estatico) | `GetTypeData(P)^.ArrayData.ElCount` |
    | `ArrayTypeLength` (dinamico) | **`raise EModernRTTIError`** (D-26; sem `Result := 0` silencioso) |
    | `SetTypeElementType` | `GetTypeData(P)^.CompType^` **(property, nunca `CompTypeRef`)** |
  - Nova `resourcestring` no bloco existente:
    `SModernRTTIError_DynArrayLength = 'comprimento de array dinamico e run-time, nao RTTI; use System.Length(oarray) sobre o valor.'`.

- **Corpos dos metodos dos records** em
  `Source/ModernSyntax.RTTI.pas` delegam ao par backend:
  ```pascal
  function TModernRTTIEnumerationType.MinValue: Integer;
  begin
    Result := EnumTypeMinValue(FToken);
  end;
  // e assim por diante para os catorze metodos dos cinco records
  ```

- **XMLDocs obrigatorios** (padrao M-D do ciclo 013 — cada XMLDoc so
  descreve o proprio metodo, nunca fala do vizinho):
  - `TModernVisibility` (tipo): "enum proprio da camada; nao vaza
    `System.TypInfo.TMemberVisibility` para o consumidor. Ordem
    e semantica identicas a `TypInfo` (mvPrivate < mvProtected <
    mvPublic < mvPublished)".
  - `TModernRTTIMethod.Visibility`: no FPC 3.2.2 **levanta**
    `EModernRTTIError` (`TypInfo.TMethodInfo` nao expoe visibilidade
    — divergencia declarada, D-25.4).
  - `TModernRTTIProperty.Visibility`: no FPC 3.2.2 **levanta**
    `EModernRTTIError` (mesmo motivo).
  - `TModernRTTIArrayType.Length`: no **dinamico** levanta
    `EModernRTTIError` **nos dois compiladores** (semantica identica);
    capacidade e run-time, use `System.Length(oarray)`.
  - `TModernRTTIArrayType.IsDynamic`: predicado — quando `True`,
    `Length` levanta e `Size` devolve o tamanho do **elemento**
    (`elSize`), nao da colecao.
  - `TModernRTTIRecordType`: entrega `Name` + `Size` apenas.
    `GetFields` **nao esta na superficie desta camada** enquanto nao
    for medido `TRecordElement.Name` num FPC vivo (issue propria).

- **Cenarios em `Test Shared/EclbrSystem/UScenarios.RTTI.pas`**
  (Pascal puro, `try/except on E: EModernRTTIError` + `Fail(...)`;
  **nunca `Assert`**, **nunca `Exception` generica**, **`AssertException`
  nao existe** — RB-6):

  Fase 1 — `TModernVisibility` (F-1 + F-2):
  1. `Scenario_MethodVisibility_TypeIsModernVisibility` — reflete um
     metodo publicado; espera `EModernRTTIError` no FPC; espera valor
     `mvPublished` no Delphi (cenario compartilhado; casca ramifica).
     Alternativa preferida (para manter CA-5 dentro do cenario):
     `Scenario_MethodVisibility_ReturnsModernVisibility` compartilhado
     que **espera `EModernRTTIError`** — no FPC passa por levantar; no
     Delphi passa por levantar tambem? Nao — no Delphi devolve o valor.
     **Solucao: dois cenarios distintos** (padrao #25), um por casca:
     `Scenario_MethodVisibility_FPC_Raises` (so casca FPC),
     `Scenario_MethodVisibility_Delphi_Returns_mvPublished` (so casca
     Delphi). Ambos vivem no `UScenarios.RTTI.pas` sem `{$IFDEF FPC}`.
  2. `Scenario_PropertyVisibility_FPC_Raises` (so casca FPC) /
     `Scenario_PropertyVisibility_Delphi_Returns_mvPublic` (so casca
     Delphi) — mesmo padrao.

  Fase 2 — `TModernRTTIEnumerationType`:
  3. `Scenario_EnumType_ThreeConstants_ContainsAll` — enum com >= 3
     constantes (ex.: `TCor = (cA, cB, cC)`); afirma `GetNames` traz os
     tres nomes, `GetName(1) = 'cB'`, `GetValue('cC') = 2`, e a
     **relacao** `MaxValue - MinValue + 1 = Length(GetNames)`. Sem
     numero absoluto (M-6). Compartilhado.
  4. `Scenario_EnumType_Name_Returns_TypeName` — `Name = 'TCor'`.
     Compartilhado.

  Fase 3 — `TModernRTTIPointerType`:
  5. `Scenario_PointerType_ReferredType_Matches` — `type PInteger = ^Integer;`;
     afirma `ReferredType.Name = 'Integer'` (ou `LongInt`, dependendo do
     alias). Compartilhado. Comentario acima do cenario declara a
     **mutacao obrigatoria**: trocar `GetTypeData(P)^.RefType^` por
     `GetTypeData(P)^.RefTypeRef` no backend FPC deve virar vermelho ou
     AV — se ficar verde, a proteção do M-2 foi silenciada.

  Fase 4 — `TModernRTTIRecordType`:
  6. `Scenario_RecordType_Size_Equals_SizeOfT` — record com >= 2 campos;
     afirma `Name = 'TFixture'` e `Size = SizeOf(TFixture)` (relacao,
     nao numero — nos 32/64 os dois valores mudam juntos). Compartilhado.

  Fase 5 — `TModernRTTIArrayType` + `TModernRTTISetType`:
  7. `Scenario_ArrayType_Static_Integer_LengthAndElementType` — `type TStat
     = array[0..4] of Integer;`; afirma `not IsDynamic`, `Length = 5`,
     `ElementType.Name` = nome do inteiro, `Size = SizeOf(TStat)`.
     Compartilhado.
  8. `Scenario_ArrayType_Dynamic_TArrayInteger_LengthRaises` —
     **`TArray<Integer>`** (nao-managed) — o unico cenario que separa
     `ElType2` (certo) de `ElType` (AV) (M-3/M-4). Afirma
     `IsDynamic = True`, `ElementType.Name` = nome do inteiro, e que
     `Length` **levanta** `EModernRTTIError`. Compartilhado.
     **Comentario obrigatorio** acima do cenario:
     ```pascal
     // MUTACAO OBRIGATORIA: trocar ElType2 por ElType no backend FPC
     // (ArrayTypeElementType, ramo tkDynArray) deve tornar este cenario
     // vermelho (AV no deref, elemento nao-managed retorna nil).
     // Se ficar verde, a proteção do M-3 foi silenciada.
     ```
  9. `Scenario_ArrayType_Dynamic_TArrayString_ElementType` —
     `TArray<string>` (managed) — cobre o outro lado da assimetria de
     M-4; `ElType` funcionaria tambem, mas o teste continua fixado em
     `ElType2` (paridade com o cenario 8). Compartilhado.
  10. `Scenario_SetType_ElementType_Is_UnderlyingEnum` — `type TCoresSet
      = set of TCor;`; afirma `ElementType.Name = 'TCor'`. Compartilhado.
      Comentario acima declara a **mutacao obrigatoria**: trocar
      `GetTypeData(P)^.CompType^` por `GetTypeData(P)^.CompTypeRef` no
      backend FPC deve virar vermelho ou AV — mesma protecao de M-2.

- **Cascas:**
  - `Test FPC/EclbrSystem/UTestMS.RTTI.pas`: publica **todos** os cenarios
    compartilhados via `published`; adiciona os dois FPC-only da Fase 1.
  - `Test Delphi/EclbrSystem/UTestMS.RTTI.pas`: publica **todos** os
    cenarios compartilhados via `[Test]`; adiciona os dois Delphi-only
    da Fase 1.
  - Runners (`PTestRTTI.lpr`/`.dpr`) **nao mudam** — `UTestMS.RTTI` ja
    esta no `uses`.

- **Atualizacao da API-MAP** (§1): linha do `TRttiIndexedProperty` recebe
  nota "**adiada** — issue propria, `blocked:fpc-3.4`". Edicao em prosa,
  nao muda a arquitetura.

### Nao inclui (out of scope)

- **`TModernRTTIIndexedProperty`** — vira issue propria com label
  `blocked:fpc-3.4` (M-7). Justificativa: `IndexedProperty` nao aparece
  uma vez em `rtti.pp` do FPC 3.2.2; 100% da superficie publica seria
  D-25.4 — diferenca qualitativa com os outros seis, que entregam
  fonte real em pelo menos um membro.
- **`TModernRTTIRecordType.GetFields`** — vira issue propria condicionada
  a medir `TRecordElement.Name` num FPC vivo (F-3 do estudo, mantida).
- **`TModernRTTIEnumerationType` sobre `Boolean`/`ByteBool`/etc.** — o
  tipo funciona (sao `tkEnumeration`), mas os cenarios nao entram por
  eles; ficam para cobertura futura.
- **Alteracao do backend Delphi para reusar RTTI global** ou coisa
  similar — fora do escopo desta issue.
- **Enumerator sobre `GetNames`/`ElementType`/similares** (API-MAP §3) —
  a camada `Enumerators` ainda nao chegou; entra depois em issue propria.
- **Refactor de `TModernRTTIField`/`TModernRTTIProperty`/`TModernRTTIMethod`**
  para `IInterface` — `FToken: Pointer` deles continua valido (D-28.2:
  nao donos de heap; referencia nao-dona ou offset).

## 3. Regras de negocio

- **RB-1 · CA-5 (PRD.md):** zero `{$IFDEF FPC}` em `UScenarios.RTTI.pas`.
  Onde o comportamento diverge por compilador (visibilidade), sao **dois
  cenarios distintos** — padrao consagrado do ciclo 010 (D-25) e do
  ciclo 013 (D-28.10). Cada cenario compartilhado compila e roda nos
  dois lados sem ramificar.
- **RB-2 · API-MAP §7:** o unico `{$IFDEF}` da unit publica continua na
  `uses` da `implementation`. Nenhum `{$IFDEF}` novo em declaracao de
  tipo, membro ou implementacao.
- **RB-3 · Paridade estrita entre backends:** as **catorze** funcoes
  novas de tipo de forma + `MethodVisibility` (assinatura alterada) +
  `PropertyVisibility` (nova) tem assinatura identica nos dois `.pas`.
  Se um lado divergir, o build quebra — comportamento desejado
  (portao de compilacao).
- **RB-4 · D-26 (nao silenciar divergencia):** `ArrayTypeLength` no
  dinamico **levanta** `EModernRTTIError` nos dois compiladores. Sem
  `Result := 0` silencioso. `MethodVisibility` e `PropertyVisibility`
  no FPC **levantam** (D-25.4). Nunca retorno zero, string vazia ou
  default silencioso.
- **RB-5 · D-25.4 preservado:** onde o FPC 3.2.2 nao tem o dado,
  `EModernRTTIError` com mensagem instrutiva. XMLDoc do metodo declara
  a divergencia.
- **RB-6 · Padrao de teste:** `try/except on E:` + `Fail(...)` sempre;
  **nunca `Assert`** (removido sem `-Sa`); **nunca `Exception` generica**
  (runner devolve exit 0 sobre vermelho — #35); **`AssertException` nao
  existe** (#27).
- **RB-7 · Guarda por `Kind` no backend FPC (D-27 novo):** cada funcao
  livre do backend FPC comeca inspecionando `P^.Kind` e levanta se o
  kind nao bate. `TTypeData` e registro variante; ler o campo do Kind
  errado devolve lixo sem erro de compilacao. Falha silenciosa e
  proibida — voz alta ou nada.
- **RB-8 · Sempre pelas properties, nunca pelos campos `*Ref` crus
  (M-2):** `CompType`, `ElType2`, `ElType`, `RefType` — resolvem
  `TypeInfoPtr` para `PTypeInfo`. Ler `CompTypeRef`/`elTypeRef`/
  `elType2Ref`/`RefTypeRef` cru sai errado sem erro de compilacao
  (mesmo modo de falha do `UnitName` #28 M-B).
- **RB-9 · Multiplicidade + relacao nos testes:** enum com >= 3
  constantes; record com >= 2 campos; array com contagem definida;
  afirmacoes de tamanho por **relacao** (`Size = SizeOf(T)`,
  `MaxValue - MinValue + 1 = N`), **nunca numero absoluto** (M-6 —
  bitness).
- **RB-10 · Cenario com `TArray<Integer>` e obrigatorio:** e o unico
  que separa `ElType2` (certo) de `ElType` (AV). So com `TArray<string>`
  passa verde com o bug dentro (M-3/M-4). Cenario 8 do §2 cumpre isso;
  seu comentario declara a mutacao obrigatoria.
- **RB-11 · Frase-fronteira D-28.2 preservada:** os seis records novos
  guardam `FToken: PTypeInfo` — referencia nao-dona ao RTTI **estatico
  do binario**. Nenhum e dono de heap; copia por valor e segura por
  construcao. Se um dia `GetFields` precisar materializar array proprio,
  o array segue as regras normais de `TArray<T>` (owned pelo caller);
  o record continua nao-dono.

## 4. Criterios de aceitacao

### Comuns (aplicam ao PR inteiro, independente do slice)

- [ ] `grep -n "{\$IFDEF" Source/ModernSyntax.RTTI.pas` continua mostrando
      **apenas** a diretiva da `uses` da `implementation` (nenhum
      `{$IFDEF}` novo).
- [ ] `grep -n "{\$IFDEF FPC" "Test Shared/EclbrSystem/UScenarios.RTTI.pas"`
      nao mostra ocorrencia nova.
- [ ] `grep -nE "AssertException|Assert\(|raise Exception\." "Test Shared/EclbrSystem/UScenarios.RTTI.pas"`
      nao mostra ocorrencia nova.
- [ ] `grep -c "^function " Source/ModernSyntax.RTTI.FPC.pas` menos o
      valor de antes da issue = `grep -c "^function " Source/ModernSyntax.RTTI.Delphi.pas`
      menos o valor de antes (paridade estrita).
- [ ] Compila e passa **nos dois bitness** FPC (x86_64 e i386) com a
      receita de `.project/SKILL.md` (`rm -rf` do `-FU` antes de cada
      recompilar; **nao** compilar `Source/` inteiro).
- [ ] PR **declara em palavras** o que foi compilado (`SKILL.md`).

### Fase 1 — `TModernVisibility` (F-1 + F-2)

- [ ] `TModernVisibility = (mvPrivate, mvProtected, mvPublic, mvPublished);`
      declarado no `interface` de `Source/ModernSyntax.RTTI.pas`, **antes**
      de `TModernRTTIField`.
- [ ] `TModernRTTIMethod.Visibility: TModernVisibility` (linha 279 hoje;
      **NAO mais** `TMemberVisibility`).
- [ ] `TModernRTTIProperty.Visibility: TModernVisibility` **existe**
      (F-2 — hoje ausente).
- [ ] Backend Delphi: `MethodVisibility` e `PropertyVisibility` mapeiam
      1-para-1 `TypInfo.TMemberVisibility → TModernVisibility`.
- [ ] Backend FPC: `MethodVisibility` e `PropertyVisibility` levantam
      `EModernRTTIError` com mensagem instrutiva.
- [ ] Cenarios da Fase 1 (dois pares casca-especificos) presentes em
      `UScenarios.RTTI.pas` e publicados corretamente (FPC-only na casca
      FPC, Delphi-only na casca Delphi).

### Fase 2 — `TModernRTTIEnumerationType`

- [ ] `TModernRTTIEnumerationType` declarado no `interface` com
      `FToken: PTypeInfo`, `FromTypeInfo`, `Name`, `GetNames`,
      `GetName`, `GetValue`, `MinValue`, `MaxValue`.
- [ ] Backend FPC: cada uma das seis funcoes livres comeca com guarda
      por `Kind = tkEnumeration` e usa `TypInfo.GetEnumName`/`GetEnumValue`
      /`GetTypeData(P)^.MinValue/MaxValue`.
- [ ] Backend Delphi: delega a `TRttiEnumerationType(Rtti.GetType(P))`.
- [ ] Cenarios 3 e 4 compartilhados e verdes nos dois compiladores.

### Fase 3 — `TModernRTTIPointerType`

- [ ] `TModernRTTIPointerType` declarado no `interface` com
      `FToken: PTypeInfo`, `FromTypeInfo`, `ReferredType`.
- [ ] Backend FPC: `PointerTypeReferredType` usa
      `GetTypeData(P)^.RefType^` (**property**, nunca `RefTypeRef`), com
      guarda por `Kind = tkPointer`.
- [ ] Backend Delphi: delega a `TRttiPointerType(Rtti.GetType(P))`.
- [ ] Cenario 5 compartilhado e verde nos dois compiladores.
- [ ] Comentario do cenario 5 declara a **mutacao obrigatoria** (M-2:
      `RefType` → `RefTypeRef` deve virar vermelho ou AV).

### Fase 4 — `TModernRTTIRecordType`

- [ ] `TModernRTTIRecordType` declarado no `interface` com
      `FToken: PTypeInfo`, `FromTypeInfo`, `Name`, `Size` **e nada mais**
      (sem `GetFields`).
- [ ] Backend FPC: `RecordTypeSize` usa `GetTypeData(P)^.RecSize` com
      guarda por `Kind = tkRecord`.
- [ ] Backend Delphi: delega a `TRttiRecordType(Rtti.GetType(P))`.
- [ ] Cenario 6 compartilhado, verde nos dois compiladores, com
      `Size = SizeOf(TFixture)` (relacao, nao numero — M-6).

### Fase 5 — `TModernRTTIArrayType` + `TModernRTTISetType`

- [ ] `TModernRTTIArrayType` declarado no `interface` com `FToken`,
      `FromTypeInfo`, `ElementType`, `Size`, `Length`, `IsDynamic`.
- [ ] `TModernRTTISetType` declarado no `interface` com `FToken`,
      `FromTypeInfo`, `ElementType`.
- [ ] Backend FPC (array):
      - `ArrayTypeIsDynamic` compara `P^.Kind = tkDynArray`.
      - `ArrayTypeElementType` ramifica: `tkArray` usa
        `GetTypeData(P)^.ArrayData.ElType^`; `tkDynArray` usa
        **`GetTypeData(P)^.ElType2^`** (property).
      - `ArrayTypeSize` ramifica: `tkArray` usa `ArrayData.Size`;
        `tkDynArray` usa `elSize`.
      - `ArrayTypeLength` no `tkArray` usa `ArrayData.ElCount`; no
        `tkDynArray` **levanta** `EModernRTTIError` com
        `SModernRTTIError_DynArrayLength`.
- [ ] Backend FPC (set): `SetTypeElementType` usa
      `GetTypeData(P)^.CompType^` (**property**, nunca `CompTypeRef`),
      com guarda por `Kind = tkSet`.
- [ ] Backend Delphi: `ArrayTypeLength` no dinamico **tambem levanta**
      `EModernRTTIError` (paridade semantica; length de dinamico e
      run-time nos dois lados).
- [ ] Cenarios 7, 8, 9 e 10 compartilhados; verdes nos dois compiladores.
- [ ] Cenario 8 (`_Dynamic_TArrayInteger_LengthRaises`) **existe** e
      afirma que `Length` **levanta** `EModernRTTIError`; seu comentario
      declara a **mutacao obrigatoria** (`ElType2` → `ElType` deve virar
      vermelho/AV — M-3/M-4).
- [ ] Cenario 10 (`_SetType_ElementType`) declara a mutacao `CompType` →
      `CompTypeRef` como M-2.

## 5. Restricoes / Constraints

- Toolchain FPC 3.2.2, x86_64 e i386; comando fixado em
  `SKILL.md:29-51`.
- Testes FPC: **FPCUnit** (`fpcunit.ppu`), nunca DUnitX.
- Testes Delphi: **DUnitX** (nao vendorado; so o autor compila; o PR
  declara).
- **NUNCA** compilar `Source/` inteiro para provar a mudanca — SKILL
  mede 0 de 16 units compilando, e falso vermelho.
- **SEMPRE** `rm -rf <out>` antes de recompilar — FPC reusa `.ppu` e
  reporta verde sobre codigo velho.
- **Sempre `-Fi"Test Shared/EclbrSystem"`** ao compilar
  `PTestRTTI.lpr` que dependa de `.inc` — regra descoberta no ciclo 008.

## 6. Riscos

- **R1 · Assinatura de `TModernRTTIMethod.Visibility` muda de
  `TMemberVisibility` para `TModernVisibility`.** Contrato binario
  interno; `grep -rn "\.Visibility" "Test*"` = 0 hoje (medido no
  relatorio). Consumidor externo que atribuisse a `TMemberVisibility`
  quebraria — sendo interno ate aqui, impacto zero fora do repo. **Sem
  mitigacao alem da nota nas Consequencias do [adr](pipeline-adr.md).**
- **R2 · `TypInfo.GetEnumName` e sensivel a alias sensivel a case.**
  Enum `(cA, cB, cC)` — `GetEnumValue('cB')` deve devolver 1.
  Mitigacao: cenario 3 afirma exatamente essa relacao. Se falhar num
  caso especifico, cenario ganha nome mais defensivo.
- **R3 · `ElType` do dinamico e `nil` para elemento nao-managed —
  regressao silenciosa se alguem "consertar" para `ElType`.** Mitigacao:
  cenario 8 (`TArray<Integer>`) + comentario de mutacao obrigatoria.
- **R4 · Backend Delphi de `ArrayTypeLength` no dinamico.** Ha risco
  do consumidor no Delphi esperar contagem — mas capacidade e run-time
  nos dois lados (variavel `Length(oarray)`), nao propriedade do tipo.
  Semantica identica FPC/Delphi e melhor que assimetria; XMLDoc declara
  em voz alta.
- **R5 · Delphi compila?** O autor e o unico que compila o lado
  Delphi. Mitigacao: PR declara o que foi compilado (SKILL); se falhar,
  ajuste caso a caso — o desenho segue o padrao dos backends anteriores.
- **R6 · Guarda por `Kind` esquecida numa das doze funcoes do backend
  FPC.** Mitigacao: RB-7 explicita; revisor procura por
  `if <token>^.Kind <>` em cada funcao antes de aceitar.
- **R7 · Escopo grande — a issue #29 promete seis tipos.** Mitigacao:
  o plano quebra em cinco slices, cada uma **mergeable por si**; ver
  [split-proposal](pipeline-split-proposal.md) e [plan](pipeline-plan.md).

## 7. Fontes

- `[investigation report — issue #29]` (INVESTIGATION REPORT reproduzido
  no prompt deste no).
- [/strategy/2026-08-27-modernrtti/API-MAP.md](/strategy/2026-08-27-modernrtti/API-MAP.md)
  — §§1, 2, 7.
- [/strategy/2026-08-27-modernrtti/PRD.md](/strategy/2026-08-27-modernrtti/PRD.md)
  — CA-5.
- [/SKILL.md](/SKILL.md) — receita FPC, mutacao, traps.
- [/history/cycles/cycle-010-a36e1364/pipeline-adr.md](/history/cycles/cycle-010-a36e1364/pipeline-adr.md)
  — D-25 (Fail sempre; dois cenarios distintos).
- [/history/cycles/cycle-011-38e3bcee/pipeline-adr.md](/history/cycles/cycle-011-38e3bcee/pipeline-adr.md)
  — D-26 (nao silenciar divergencia).
- [/history/cycles/cycle-013-5a8dfb58/pipeline-adr.md](/history/cycles/cycle-013-5a8dfb58/pipeline-adr.md)
  — D-28.2 (Pointer em record e seguro enquanto nao e dono).
