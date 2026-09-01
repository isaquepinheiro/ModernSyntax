---
type: plan
kind: artifact
title: "PLAN — TModernRTTIContext (issue #28)"
description: "Um unico PR em tres slices ordenadas: (1) IModernRTTIContextToken + TModernRTTIContext + IsNil na unit publica, mas ainda SEM chamar backend (compila sozinho, sem teste); (2) as cinco Context* nos dois backends em paralelo (paridade estrita — portao de compilacao) e wire dos metodos do record aos backends; (3) cinco cenarios em UScenarios + wrappers (5 na casca FPC, 4 na Delphi), mutacao obrigatoria. Ordem deixa o compilador falar em cada etapa."
status: stable
cycle: "013"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/5a8dfb58a24f74263fa58fa581f465c4
tags: [modernrtti, plan, issue-28, fpc, delphi, context, slices]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-01T00:00:00Z"
---

# PLAN — issue #28

**Escopo:** um unico PR. As slices sao **passos ordenados dentro do
mesmo commit-set**, nao entregas independentes — a issue so esta
fechada quando as tres fecham (a slice 2 sem a slice 1 nao compila,
e a slice 3 sem a slice 2 fica vermelha por delegacao inexistente).

Ordem escolhida para deixar o compilador falar em cada etapa: se algo
quebra, a slice em curso e a culpada.

Todas as decisoes vem do [adr](pipeline-adr.md). Todos os criterios de
`Aceito quando` estao no [esp](pipeline-esp.md).

## Slice 1 — Unit publica: interface opaca, record e IsNil (SEM chamar backend ainda)

**Fim:** o bloco `type` da `interface` de
`Source/ModernSyntax.RTTI.pas` ja carrega `IModernRTTIContextToken`,
`TModernRTTIContext` e `TModernRTTIType.IsNil`. Corpos dos metodos do
record ficam **em stub temporario** que compila (por exemplo,
`function GetTypes: TArray<TModernRTTIType>; begin SetLength(Result,
0); end;` — a slice 2 substitui pela delegacao). Nenhum teste ainda.

**Por que separar:** provar em isolado que a **superficie publica**
compila nos dois compiladores antes de introduzir aresta nova nos
backends. Se a unit publica quebrar aqui, o problema e no
tipo/interface — nao no backend.

**Arquivos:**

- `Source/ModernSyntax.RTTI.pas`:
  - **Bloco `type` da `interface`, antes de `TModernRTTI` (linha 410
    hoje, ou logo apos `TModernRTTIMethod`):**
    ```pascal
    IModernRTTIContextToken = interface
      ['{GUID-gerado-uma-vez}']
    end;

    TModernRTTIContext = record
    private
      FToken: IModernRTTIContextToken;
    public
      class function Create: TModernRTTIContext; static;
      procedure Free;
      function GetType(AClass: TClass): TModernRTTIType; overload;
      function GetType(ATypeInfo: PTypeInfo): TModernRTTIType; overload;
      function RegisterType(ATypeInfo: PTypeInfo): TModernRTTIType;
      function GetTypes: TArray<TModernRTTIType>;
      function FindType(const AQualifiedName: string): TModernRTTIType;
    end;
    ```
    XMLDocs obrigatorios do tipo, `GetTypes`, `RegisterType`,
    `FindType`, `Free` (textos exatos em [esp](pipeline-esp.md) §2 e nos D-28.4,
    D-28.5, D-28.6, D-28.7, D-28.8 do [adr](pipeline-adr.md)). **Nao** falar do
    vizinho — cada XMLDoc so descreve o proprio metodo (M-D).
  - **`TModernRTTIType` (linha 139–176 hoje):** adicionar
    `function IsNil: Boolean;` no `public`, apos `FromRtti`.
  - **`implementation`, apos `TModernRTTIType.FromRtti`:**
    `function TModernRTTIType.IsNil: Boolean; begin Result := FType =
    nil; end;`.
  - **Corpos stub temporarios** para `Create/Free/GetType(2)/
    RegisterType/GetTypes/FindType` — todos com valor neutro que
    compile (`Result := ...; end;`). **Nao chamar nada dos backends
    ainda.** Comentario `// STUB slice 1` em cada corpo.
  - **XMLDoc de `TModernRTTI.GetType` (linhas 745–753):** adicionar
    linha unica: *"Nao alimenta `TModernRTTIContext.GetTypes` de
    nenhuma instancia; para enumeracao, use
    `TModernRTTIContext.RegisterType` ou `GetType`."*
  - **`uses` da `implementation` (linhas 428–433):** **nao mexer**.
    Continua o unico `{$IFDEF}` da unit publica.

**Aceito quando:**

- `PTestRTTI.lpr` compila em x86_64 na fabrica
  (`SKILL.md:29-51`, `rm -rf` antes) — verde por proteção dos
  cenarios existentes (nenhum toca `TModernRTTIContext`).
- `grep -n "{\$IFDEF" Source/ModernSyntax.RTTI.pas` continua
  mostrando **apenas** a diretiva da `uses` da `implementation`.

## Slice 2 — Dois backends em paridade (portao de compilacao)

**Fim:** os dois `.pas` de backend declaram as **mesmas cinco**
`Context*` no `interface`, com classe interna `T<...>ContextToken`
implementando `IModernRTTIContextToken`. Os corpos stub da slice 1
sao substituidos por delegacao real.

**Por que juntos:** paridade e o portao de compilacao (API-MAP §7).
Adicionar em um so faz o build quebrar — **e isso e o desejado**, mas
so quando os dois estao la em paralelo o build fica verde.

**Arquivos:**

- `Source/ModernSyntax.RTTI.Delphi.pas` — antes de `implementation`
  (linha 86 hoje):
  ```pascal
  function ContextCreate: IModernRTTIContextToken;
  function ContextGetType(AToken: IModernRTTIContextToken; ATypeInfo: PTypeInfo): TModernRTTIType;
  function ContextRegisterType(AToken: IModernRTTIContextToken; ATypeInfo: PTypeInfo): TModernRTTIType;
  function ContextGetTypes(AToken: IModernRTTIContextToken): TArray<TModernRTTIType>;
  function ContextFindType(AToken: IModernRTTIContextToken; const AQualifiedName: string): TModernRTTIType;
  ```
  **Sem `ContextFree`.** No `implementation` (apos linha 265, junto
  aos outros helpers do backend):
  - Classe privada `TDelphiContextToken = class(TInterfacedObject,
    IModernRTTIContextToken)` com `FContext: TRttiContext`, `Create`
    faz `FContext := TRttiContext.Create;`, `Destroy` faz
    `FContext.Free; inherited;`.
  - `ContextCreate` instancia `TDelphiContextToken.Create`.
  - Cada delegate faz `(AToken as TDelphiContextToken).FContext.<algo>`
    e envolve com `TModernRTTIType.FromRtti(...)` quando precisar.
  - `ContextRegisterType` no Delphi delega ao `GetType(ATypeInfo)`
    nativo (no-op logico; consistente com D-28.7).
  - `ContextGetTypes` delega ao `TRttiContext.GetTypes` nativo (o
    pool esta la).
  - `ContextFindType` delega ao `TRttiContext.FindType` nativo.

- `Source/ModernSyntax.RTTI.FPC.pas` — antes de `implementation`
  (linha 108 hoje), as **mesmas cinco** assinaturas (paridade). Na
  `resourcestring` do bloco existente (apos linha 149), acrescentar:
  ```pascal
  SModernRTTIError_EmptyRegistry = 'o FPC 3.2.2 nao enumera tipos; registre com TModernRTTIContext.RegisterType os tipos que importam antes de chamar GetTypes.';
  ```
  No `implementation`, apos linha 372 (antes de `end.`):
  - `uses TypInfo, Classes;` ja presente — nada a adicionar so por
    isto; conferir se `TList` esta acessivel (esta, via `Classes`).
  - Classe privada `TFPCContextToken = class(TInterfacedObject,
    IModernRTTIContextToken)` com `FContext: TRttiContext` **e**
    `FRegistry: TList` (de `PTypeInfo`). `Create` inicializa
    `FContext := TRttiContext.Create; FRegistry := TList.Create;`;
    `Destroy` faz `FRegistry.Free; inherited;`.
  - `ContextCreate` instancia.
  - `ContextGetType` e `ContextRegisterType` acrescentam `ATypeInfo`
    ao `FRegistry` **se ainda nao estiver** (evita duplicar; loop
    simples com `IndexOf`) e devolvem
    `TModernRTTIType.FromRtti(FContext.GetType(ATypeInfo))`.
  - `ContextGetTypes`: se `FRegistry.Count = 0`,
    `raise EModernRTTIError.Create(SModernRTTIError_EmptyRegistry)`.
    Senao, monta `TArray<TModernRTTIType>` mapeando cada `PTypeInfo`
    para `TModernRTTIType.FromRtti(FContext.GetType(PTypeInfo(FRegistry[i])))`.
  - `ContextFindType`: percorre `FRegistry`; para cada `P` com
    `P^.Kind = tkClass`, monta
    `GetTypeData(P)^.UnitName + '.' + P^.Name`; compara com
    `AQualifiedName`. Kinds diferentes de `tkClass` sao **pulados**
    (nao ler `UnitName` — D-28.5). Nao achou:
    `Result := TModernRTTIType.FromRtti(nil);`.

- `Source/ModernSyntax.RTTI.pas` — substituir os stubs da slice 1
  pela delegacao real:
  ```pascal
  class function TModernRTTIContext.Create: TModernRTTIContext;
  begin
    Result.FToken := ContextCreate;
  end;

  procedure TModernRTTIContext.Free;
  begin
    FToken := nil;
  end;

  function TModernRTTIContext.GetType(AClass: TClass): TModernRTTIType;
  begin
    Result := ContextGetType(FToken, AClass.ClassInfo);
  end;

  function TModernRTTIContext.GetType(ATypeInfo: PTypeInfo): TModernRTTIType;
  begin
    Result := ContextGetType(FToken, ATypeInfo);
  end;

  function TModernRTTIContext.RegisterType(ATypeInfo: PTypeInfo): TModernRTTIType;
  begin
    Result := ContextRegisterType(FToken, ATypeInfo);
  end;

  function TModernRTTIContext.GetTypes: TArray<TModernRTTIType>;
  begin
    Result := ContextGetTypes(FToken);
  end;

  function TModernRTTIContext.FindType(const AQualifiedName: string): TModernRTTIType;
  begin
    Result := ContextFindType(FToken, AQualifiedName);
  end;
  ```

**Aceito quando:**

- `PTestRTTI.lpr` compila em x86_64 e i386 (`SKILL.md`, `rm -rf`
  antes) — verde por proteção dos cenarios existentes.
- `grep -c "^function Context" Source/ModernSyntax.RTTI.FPC.pas`
  = `grep -c "^function Context" Source/ModernSyntax.RTTI.Delphi.pas`
  = **5** (paridade).
- `grep -n "{\$IFDEF" Source/ModernSyntax.RTTI.pas` continua
  mostrando **apenas** a diretiva da `uses` da `implementation`.

## Slice 3 — Cenarios + wrappers + mutacao

**Fim:** cinco cenarios em `UScenarios.RTTI.pas` (Pascal puro,
compartilhado), cinco `published` na casca FPC, quatro `[Test]` na
casca Delphi. Comentario do cenario 1 declara a mutacao obrigatoria.

**Arquivos:**

- `Test Shared/EclbrSystem/UScenarios.RTTI.pas` — apos linha 746
  (antes de `end.`):
  - Declaracoes das cinco procedures no `interface`.
  - Corpos no `implementation`, cada um com o padrao das linhas
    315–323 (`try ... except on E: EModernRTTIError do ... end; Fail(...)`
    quando cabe; `Fail(...)` direto quando a condicao e escalar). **Zero
    `Assert`**, **zero `Exception` generica**, **zero
    `AssertException`**, **zero `{$IFDEF FPC}`**.
  - **Cenario 1 (`_EmptyRegistry_Raises`)** — comentario logo acima:
    ```pascal
    // MUTACAO OBRIGATORIA: remover o `raise EModernRTTIError` do
    // ContextGetTypes no backend FPC (ModernSyntax.RTTI.FPC.pas)
    // deve tornar este cenario vermelho. Se ficar verde, a proteção
    // do D-28.4 do ADR do ciclo 013 foi silenciada.
    ```
  - **Cenario 2:** `TCtx := TModernRTTIContext.Create;
    TCtx.RegisterType(TypeInfo(TPortableFixture));
    TCtx.RegisterType(TypeInfo(TInner));` — chama `GetTypes`, monta
    dois flags `LFoundFixture`, `LFoundInner` percorrendo o array por
    `.Name`. Fail se algum flag ficar `False`.
  - **Cenario 3:** registra `TPortableFixture`, chama
    `FindType('UScenarios.RTTI.TPortableFixture')`, Fail se `IsNil`
    ou se `Name` nao bate.
  - **Cenario 4:** `FindType('UScenarios.RTTI.QueNaoExiste_' +
    IntToStr(GetTickCount64))`; Fail se `IsNil = False`.
  - **Cenario 5 (`_CopyByValue_SharesState_NoUseAfterFree`)** — as
    quatro asserções encadeadas do D-28.10:
    (a) `LA := TModernRTTIContext.Create; LA.RegisterType(T1);
    LA.RegisterType(T2); LB := LA;` — busca por nome em `LB.GetTypes`
    acha T1 e T2 (Fail se nao); (b) `LB.RegisterType(T3);` — busca
    em `LA.GetTypes` acha T3 (Fail se nao); (c) `LA.Free;` — busca em
    `LB.GetTypes` continua achando os tres (Fail se nao); (d)
    `LB.Free;` — dentro de `try/except` **sem** o `Fail(...)` do
    padrao (queremos que nao levante):
    ```pascal
    try
      LB.Free;
    except
      on E: Exception do
        Fail('B.Free levantou ' + E.ClassName + ': ' + E.Message +
             ' — regressao do desenho Pointer (M-E do relatorio).');
    end;
    ```

- `Test FPC/EclbrSystem/UTestMS.RTTI.pas` — **cinco** metodos
  `published` (um por cenario). Cada corpo delega ao cenario
  compartilhado. Padrao literal do arquivo (mesmo shape das
  wrappers existentes).

- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` — **quatro** metodos
  `[Test]` (todos menos `_EmptyRegistry_Raises`). Padrao literal do
  arquivo.

- `Test FPC/EclbrSystem/PTestRTTI.lpr` — **nao alterar** (ja usa
  `UScenarios.RTTI` e `UTestMS.RTTI`).

**Aceito quando:**

- `PTestRTTI.lpr` compila e passa em x86_64 e i386 com os cinco novos
  wrappers (mais os existentes).
- Delphi compila (declarado no PR — `SKILL.md`).
- **Mutacao verificada**: remover o `raise` em
  `ContextGetTypes` do backend FPC faz o cenario
  `_EmptyRegistry_Raises` ficar vermelho.
- `grep -n "{\$IFDEF FPC" "Test Shared/EclbrSystem/UScenarios.RTTI.pas"`
  nao mostra ocorrencia nova.
- `grep -nE "AssertException|Assert\(|raise Exception\." "Test Shared/EclbrSystem/UScenarios.RTTI.pas"`
  nao mostra ocorrencia nova.

## Ordem e por que

1. **Slice 1 antes de 2** — a slice 2 nao compila sem a
   `IModernRTTIContextToken` da 1. Ademais, a 1 nao introduz aresta
   nos backends: se falhar, o problema e na unit publica.
2. **Slice 2 antes de 3** — a 3 exige `GetTypes/FindType/RegisterType`
   funcionando; sobre stubs, os cenarios ficariam vermelhos por
   motivo errado (stub, nao logica).
3. **Slice 3 fecha o ciclo** — os cenarios provam nos dois
   compiladores, e a mutacao prova que a proteção do D-28.4 nao
   foi silenciada.

## Nao regressao

- Zero regressao esperada nos 23 cenarios existentes em
  `UScenarios.RTTI.pas` — nenhum toca `TModernRTTIContext`,
  `GetTypes` ou `FindType`. Adicao e estritamente aditiva.
- `TModernRTTI.GetType` global intocado (so um XMLDoc a mais).
- Nenhum `{$IFDEF}` novo em membros, estado ou implementacao da unit
  publica (API-MAP §7 preservado).
