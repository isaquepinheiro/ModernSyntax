---
type: task-input
kind: artifact
title: "TASK-INPUT — TModernRTTIContext: GetTypes e FindType nos dois compiladores, IInterface token, GetPackages fora (issue #28)"
description: "Handoff operacional: estreia TModernRTTIContext com IModernRTTIContextToken opaco (refcount, use-after-free impossivel por construcao); registry per-instancia no FPC alimentado por GetType/RegisterType; GetTypes com registry vazio no FPC LEVANTA EModernRTTIError; FindType so resolve tkClass no FPC; GetPackages fora com motivo em XMLDoc; ContextFree eliminado, Free publico opcional; cinco cenarios em UScenarios (um FPC-only na casca), cenario 5 afirma tres coisas para matar regressao do Pointer; mutacao obrigatoria: remover o raise deve virar vermelho."
status: stable
cycle: "013"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/5a8dfb58a24f74263fa58fa581f465c4
tags: [modernrtti, task-input, issue-28, fpc, delphi, context, gettypes, findtype, feature]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-01T00:00:00Z"
---

# TASK-INPUT — issue #28

## Titulo

TModernRTTIContext: `GetTypes` e `FindType`, os dois membros ausentes
no FPC — token opaco por `IInterface`, registry per-instancia no FPC,
`GetPackages` fora com motivo declarado.

## Tipo / labels

- `type: feature`
- `route: feature`
- labels: `enhancement`, `rtti`, `fpc`, `delphi`, `pilar-4`

## Escopo curto

Adicionar `TModernRTTIContext` publico em
`Source/ModernSyntax.RTTI.pas` com `Create`, `Free`, `GetType` (dois
overloads), `RegisterType`, `GetTypes`, `FindType`, e o predicado
`TModernRTTIType.IsNil`.

O estado do contexto vive atras de `IModernRTTIContextToken` (opaca,
so GUID) — refcount agrega copias do record e o ultimo decremento
libera. **Pointer nao entra**: e o primeiro record publico dono de
heap desta camada, e por isso usa `IInterface` (frase-fronteira do
[adr](pipeline-adr.md), D-28.2).

Nos backends, cinco funcoes livres com **assinatura identica**
(`ContextCreate`, `ContextGetType`, `ContextRegisterType`,
`ContextGetTypes`, `ContextFindType`) — sem `ContextFree`, o refcount
libera. Classe interna privada em cada backend
(`TDelphiContextToken`, `TFPCContextToken`), acessada pelo backend
via `AToken as T<...>ContextToken`.

No **FPC**, registry per-instancia (`TList` de `PTypeInfo` alimentada
por `GetType`/`RegisterType`). `GetTypes` sobre registry vazio
**levanta** `EModernRTTIError` com `SModernRTTIError_EmptyRegistry`
(D-26 do ciclo 011 — nao silenciar divergencia). `FindType` ramifica
por `Kind` e **so resolve `tkClass`**; outros kinds sao pulados. Nao
achou → `TModernRTTIType.FromRtti(nil)`.

No **Delphi**, delega ao `TRttiContext` nativo per-instancia
(simetria com o FPC — nao reusa o `FContext` global).
`ContextRegisterType` e no-op (documentado em XMLDoc).

`GetPackages` **nao entra** na superficie publica. O motivo (o
conceito de "pacote" e do Delphi; nao ha primitiva no FPC) esta em
XMLDoc do proprio `TModernRTTIContext`.

Cinco cenarios compartilhados em
`Test Shared/EclbrSystem/UScenarios.RTTI.pas`; casca FPC publica os
cinco; casca Delphi publica quatro (todos menos
`_EmptyRegistry_Raises`, porque o pool nativo do Delphi torna
registry-vazio impossivel de simular — padrao "dois cenarios
distintos" da #25).

## Checklist de aceitacao

- [ ] `Source/ModernSyntax.RTTI.pas` declara no `interface`:
      ```pascal
      IModernRTTIContextToken = interface
        ['{GUID-gerado}']
      end;
      ```
      **Vazia de membros publicos** — so o GUID.
- [ ] `Source/ModernSyntax.RTTI.pas` declara no `interface`:
      ```pascal
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
      **Zero `{$IFDEF}`** em qualquer membro.
- [ ] `TModernRTTIType` recebe `function IsNil: Boolean;` apos
      `FromRtti` (linha 177 hoje); corpo `Result := FType = nil;`.
- [ ] XMLDoc do tipo `TModernRTTIContext` registra a **ausencia** de
      `GetPackages`, com o motivo (o conceito de "pacote" so existe
      no Delphi; nao ha primitiva no FPC).
- [ ] XMLDoc de `GetTypes` registra a divergencia de conteudo (Delphi
      = pool nativo; FPC = registry per-instancia) e que **registry
      vazio no FPC levanta** `EModernRTTIError`.
- [ ] XMLDoc de `RegisterType`: *"no Delphi e no-op; existe para que
      o codigo portavel seja identico nos dois compiladores"*.
- [ ] XMLDoc de `FindType`: no FPC **so resolve `tkClass`**;
      enumeracoes, records e escalares registrados sao inalcancaveis
      por nome.
- [ ] XMLDoc de `Free`: **opcional**, existe por paridade com
      `TRttiContext.Free` do Delphi — o refcount da `IInterface`
      libera automaticamente.
- [ ] XMLDoc de `TModernRTTI.GetType`
      (`Source/ModernSyntax.RTTI.pas:745-753`): uma linha declarando
      que **nao alimenta** `TModernRTTIContext.GetTypes` de nenhuma
      instancia.
- [ ] `Source/ModernSyntax.RTTI.Delphi.pas` declara no `interface`
      as **cinco** funcoes `Context*` (assinatura identica ao FPC) e
      **NAO** declara `ContextFree`. Classe privada
      `TDelphiContextToken = class(TInterfacedObject,
      IModernRTTIContextToken)` com `FContext: TRttiContext`
      alocado per-instancia; `Destroy` chama `FContext.Free`. Cada
      delegate faz `(AToken as TDelphiContextToken).FContext.<algo>`.
      `ContextGetTypes` delega ao pool nativo. `ContextFindType`
      delega ao `FindType` nativo. `ContextRegisterType` retorna
      `GetType(ATypeInfo)` nativo.
- [ ] `Source/ModernSyntax.RTTI.FPC.pas` declara no `interface` as
      **mesmas cinco** funcoes `Context*` (paridade estrita). Nova
      `resourcestring` no bloco existente (apos linha 149):
      ```pascal
      SModernRTTIError_EmptyRegistry = 'o FPC 3.2.2 nao enumera tipos; registre com TModernRTTIContext.RegisterType os tipos que importam antes de chamar GetTypes.';
      ```
      Classe privada `TFPCContextToken = class(TInterfacedObject,
      IModernRTTIContextToken)` com `FContext: TRttiContext` e
      `FRegistry: TList` de `PTypeInfo`; `Destroy` libera a lista.
      `ContextGetType`/`ContextRegisterType` alimentam o registry
      (sem duplicar) e devolvem
      `TModernRTTIType.FromRtti(FContext.GetType(ATypeInfo))`.
      `ContextGetTypes` **levanta** `EModernRTTIError` quando
      `FRegistry.Count = 0`. `ContextFindType` **so resolve
      `P^.Kind = tkClass`** montando `UnitName + '.' + Name`; outros
      kinds pulados; nao achou → `TModernRTTIType.FromRtti(nil)`.
- [ ] `Test Shared/EclbrSystem/UScenarios.RTTI.pas` recebe cinco
      procedures declaradas no `interface`, todas usando o padrao
      `try/except on E: EModernRTTIError` + `Fail(...)` (linhas
      315–323), **zero `{$IFDEF FPC}`**, **zero `Assert`**, **zero
      `Exception` generica**, **zero `AssertException`**:
      - `Scenario_Context_GetTypes_EmptyRegistry_Raises`
      - `Scenario_Context_GetTypes_AfterTwoRegisterType_ContainsBoth`
      - `Scenario_Context_FindType_Class_Found`
      - `Scenario_Context_FindType_NotFound_ReturnsNil`
      - `Scenario_Context_CopyByValue_SharesState_NoUseAfterFree`
- [ ] Comentario do cenario 1 declara a **mutacao obrigatoria**:
      remover o `raise` do `ContextGetTypes` no backend FPC deve
      tornar o cenario vermelho.
- [ ] Cenario 2 verifica presenca dos dois tipos registrados **por
      busca por nome** no array (nao por `Length`) — o pool nativo
      do Delphi tem contagem indefinida.
- [ ] Cenario 5 afirma **as tres coisas** encadeadas: (a) a copia
      enxerga o que a outra registrou; (b) o estado e compartilhado
      (o que a copia registrou aparece no original); (c) apos
      `A.Free`, `B.GetTypes` continua com a **contagem certa por
      busca por nome**; (d) `B.Free` posterior **nao levanta**.
- [ ] `Test FPC/EclbrSystem/UTestMS.RTTI.pas` recebe **cinco**
      metodos `published` (um por cenario).
- [ ] `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` recebe **quatro**
      metodos `[Test]` (todos menos `_EmptyRegistry_Raises`).
- [ ] `grep -n "{\$IFDEF" Source/ModernSyntax.RTTI.pas` continua
      mostrando **apenas** a diretiva da `uses` da `implementation`.
- [ ] `grep -c "^function Context"` das duas units de backend e
      **igual** (paridade estrita — API-MAP §7).
- [ ] Compila e passa nos **dois bitness** FPC (x86_64 e i386),
      receita de `.project/SKILL.md` (`rm -rf <out>` antes de
      recompilar).
- [ ] O PR **declara em palavras** o que foi compilado (SKILL.md
      exige) — no minimo FPC nos dois bitness; Delphi se o autor
      compilou.

## Arquivos provavelmente impactados

- `Source/ModernSyntax.RTTI.pas` — declaracoes publicas, XMLDocs,
  corpos delegando aos backends.
- `Source/ModernSyntax.RTTI.Delphi.pas` — cinco `Context*` +
  `TDelphiContextToken`.
- `Source/ModernSyntax.RTTI.FPC.pas` — cinco `Context*` +
  `TFPCContextToken` + `SModernRTTIError_EmptyRegistry`.
- `Test Shared/EclbrSystem/UScenarios.RTTI.pas` — cinco cenarios
  compartilhados (interface + implementation).
- `Test FPC/EclbrSystem/UTestMS.RTTI.pas` — cinco wrappers `published`.
- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` — quatro wrappers `[Test]`.

**Nao mexer**: `Source/ModernSyntax.RTTI.Delphi.pas` fora do escopo
das cinco `Context*` + classe; `Source/ModernSyntax.RTTI.FPC.pas` fora
das cinco `Context*` + classe + resourcestring; os records
`TModernRTTIField`, `TModernRTTIProperty`, `TModernRTTIMethod` (seus
`FToken: Pointer` continuam validos — nao sao donos de heap; ver
D-28.2 do [adr](pipeline-adr.md)); `Test FPC/EclbrSystem/PTestRTTI.lpr` (ja
usa as duas units modificadas).

## Convencoes de codigo aplicaveis

- **CA-5 (PRD.md):** zero `{$IFDEF FPC}` no consumidor. O cenario 1
  fica FPC-only **na casca** (nao dentro do cenario compartilhado).
- **API-MAP §7:** unico `{$IFDEF}` da unit publica na `uses` da
  `implementation`; paridade estrita entre backends.
- **D-25 / D-26:** `Fail(...)` sempre, nunca `Assert`, nunca
  `Exception` generica; `AssertException` **nao existe**. Nao
  silenciar divergencia — `GetTypes` sobre registry vazio **levanta**.
- **SKILL.md:** limpar `-FU` antes de recompilar; nao compilar
  `Source/` inteiro; PR declara o que foi compilado.
- **Frase-fronteira (D-28.2):** `Pointer` em record e seguro
  enquanto o record **nao e dono**; `TModernRTTIContext` seria o
  primeiro dono de heap, por isso usa `IInterface`.

## Fontes

- [esp](pipeline-esp.md), [adr](pipeline-adr.md), [plan](pipeline-plan.md).
- [/strategy/2026-08-27-modernrtti/API-MAP.md](/strategy/2026-08-27-modernrtti/API-MAP.md)
  §§1, 2, 7.
- [/strategy/2026-08-27-modernrtti/PRD.md](/strategy/2026-08-27-modernrtti/PRD.md)
  — CA-5.
- [/SKILL.md](/SKILL.md) — toolchain, mutacao, traps.
