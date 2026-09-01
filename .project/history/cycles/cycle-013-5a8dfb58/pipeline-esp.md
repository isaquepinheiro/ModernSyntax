---
type: spec
kind: artifact
title: "ESP — TModernRTTIContext: Create/Free/GetType/GetTypes/FindType (+ RegisterType), IInterface token, sem GetPackages (issue #28)"
description: "Estreia do TModernRTTIContext publico com IModernRTTIContextToken opaco (refcount agrega copias de record); GetTypes e FindType via registry per-instancia no FPC, delega ao nativo no Delphi; GetPackages fora, motivo em XMLDoc; GetTypes com registry vazio levanta EModernRTTIError; FindType so resolve tkClass no FPC; CA-5 preservado com dois cenarios distintos e uma casca a menos no Delphi."
status: draft
cycle: "013"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/5a8dfb58a24f74263fa58fa581f465c4
tags: [modernrtti, rtti, spec, issue-28, fpc, delphi, context, gettypes, findtype]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-01T00:00:00Z"
sources:
  - id: issue-28-report
    title: "REPORT — Issue #28 (run ca7057571a6e684f698e54f8a1d8721e) — PRESENT"
  - id: api-map
    resource: "/strategy/2026-08-27-modernrtti/API-MAP.md"
    title: "ModernRTTI API-MAP (§1, §2, §7)"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, mutacao, traps"
---

# ESP — issue #28

## 1. Objetivo

Estrear o record publico `TModernRTTIContext` com `Create`, `Free`,
`GetType`, `GetTypes` e `FindType` funcionando **nos dois compiladores**,
**sem `{$IFDEF FPC}` no consumidor** (CA-5, PRD.md), e sem inventar
`GetPackages` (que **nao existe** na superficie publica; motivo em
XMLDoc do tipo).

O `TModernRTTIContext` e o **primeiro record publico desta camada que
possui estado alocado no heap por instancia**. Isso puxa uma decisao de
arquitetura que vai alem desta issue: `Pointer` opaco em record cai;
entra `IInterface` — o refcount agrega copias de record e o ultimo
decremento libera. A frase que vai para o [adr](pipeline-adr.md) e:

> *"`Pointer` em record e seguro enquanto o record nao e dono; vira
> bomba no instante em que passa a ser."*

## 2. Escopo

### Inclui

- **Novo tipo publico opaco** em `Source/ModernSyntax.RTTI.pas`
  (declarado no bloco `type` da `interface`, antes de `TModernRTTI`):
  ```pascal
  IModernRTTIContextToken = interface
    ['{GUID-gerado}']
  end;
  ```
  **Vazia de membros publicos** — so o GUID. Consumidor nao tem o que
  chamar; backend recupera o estado tipado via cast
  `AToken as TDelphiContextToken` / `AToken as TFPCContextToken`.

- **Novo record publico** `TModernRTTIContext`, na mesma unit e mesmo
  bloco `type`:
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

- **Predicado** `function IsNil: Boolean;` em
  `TModernRTTIType` (apos `FromRtti`, linha 177 hoje). Corpo:
  `Result := FType = nil;`. E o que torna inspecionavel o estado "nao
  encontrado" que `FindType` produz via
  `TModernRTTIType.FromRtti(nil)`.

- **Cinco funcoes livres novas em cada backend**, com assinatura
  **identica**:
  ```pascal
  function ContextCreate: IModernRTTIContextToken;
  function ContextGetType(AToken: IModernRTTIContextToken; ATypeInfo: PTypeInfo): TModernRTTIType;
  function ContextRegisterType(AToken: IModernRTTIContextToken; ATypeInfo: PTypeInfo): TModernRTTIType;
  function ContextGetTypes(AToken: IModernRTTIContextToken): TArray<TModernRTTIType>;
  function ContextFindType(AToken: IModernRTTIContextToken; const AQualifiedName: string): TModernRTTIType;
  ```
  **Sem `ContextFree`** — o refcount libera. Paridade estrita nas duas
  units e o portao de compilacao (API-MAP §7).

- **Backend Delphi** (`Source/ModernSyntax.RTTI.Delphi.pas`): classe
  privada `TDelphiContextToken = class(TInterfacedObject,
  IModernRTTIContextToken)` com campo `FContext: TRttiContext`;
  `Destroy` chama `FContext.Free`. `ContextCreate` instancia; cada
  delegate faz `(AToken as TDelphiContextToken).FContext.<algo>`.
  `ContextGetTypes` delega ao nativo (Delphi tem o pool);
  `ContextFindType` delega ao `FindType` nativo; `ContextRegisterType`
  e no-op (retorna `GetType` nativo, por consistencia). Aloco
  per-instancia (nao reuso o `FContext` global): semantica simetrica
  com o FPC.

- **Backend FPC** (`Source/ModernSyntax.RTTI.FPC.pas`): classe privada
  `TFPCContextToken = class(TInterfacedObject, IModernRTTIContextToken)`
  com `FContext: TRttiContext` e `FRegistry: TList` (de `PTypeInfo`);
  `Destroy` libera a lista. Nova `resourcestring` no bloco existente:
  `SModernRTTIError_EmptyRegistry = 'o FPC 3.2.2 nao enumera tipos;
  registre com TModernRTTIContext.RegisterType os tipos que importam
  antes de chamar GetTypes.'`. Comportamentos:
  - `ContextGetType` / `ContextRegisterType`: adicionam `ATypeInfo` ao
    `FRegistry` (sem duplicar) e devolvem
    `TModernRTTIType.FromRtti(FContext.GetType(ATypeInfo))`.
  - `ContextGetTypes`: se `FRegistry.Count = 0`,
    **`raise EModernRTTIError.Create(SModernRTTIError_EmptyRegistry)`**;
    senao, mapeia cada `PTypeInfo` para `TModernRTTIType.FromRtti(...)`.
  - `ContextFindType`: percorre `FRegistry`; **so** para `P^.Kind =
    tkClass`, monta `GetTypeData(P)^.UnitName + '.' + P^.Name` e
    compara; outros kinds sao pulados. Nao achou →
    `TModernRTTIType.FromRtti(nil)`.

- **XMLDocs obrigatorios** (M-D do relatorio: separado por metodo,
  nunca fala do vizinho):
  - `TModernRTTIContext` (tipo): registra a **ausencia** de
    `GetPackages`, com o motivo (o conceito de "pacote" so existe no
    Delphi; nao ha primitiva no FPC 3.2.2).
  - `GetTypes`: registra a **divergencia de conteudo** — Delphi enumera
    pool nativo; FPC enumera o registry per-instancia; **registry
    vazio no FPC levanta** `EModernRTTIError`.
  - `RegisterType`: *"no Delphi e no-op; existe para que o codigo
    portavel seja identico nos dois compiladores"*.
  - `FindType`: no FPC **so resolve `tkClass`**; enumeracoes, records
    e escalares registrados sao inalcancaveis por nome (mesma familia
    de divergencia declarada de `TModernRTTIMethod.GetParameters`).
  - `Free`: existe **por paridade** com `TRttiContext.Free` do Delphi;
    e **opcional** — o refcount da `IInterface` libera automaticamente
    quando o ultimo record que segura o token sai de escopo.
  - `TModernRTTI.GetType` (`Source/ModernSyntax.RTTI.pas:745-753`):
    uma linha dizendo que **nao alimenta** o `GetTypes` de nenhuma
    instancia de `TModernRTTIContext`; para enumeracao, usar
    `TModernRTTIContext.RegisterType` ou `GetType`.

- **Cinco cenarios em `Test Shared/EclbrSystem/UScenarios.RTTI.pas`**
  (padrao `try/except on E: EModernRTTIError` + `Fail(...)` das linhas
  315-323; **nunca `Assert`**, **nunca `Exception` generica**,
  **`AssertException` nao existe**):
  1. `Scenario_Context_GetTypes_EmptyRegistry_Raises` — cria contexto,
     chama `GetTypes` sem registrar nada, espera `EModernRTTIError`.
     Compartilhado (Pascal puro), mas **so a casca FPC** o publica —
     padrao "dois cenarios distintos" da #25 (no Delphi o pool nativo
     torna registry-vazio impossivel de simular). No comentario do
     cenario: **mutacao obrigatoria** — remover o `raise` do backend
     deve tornar este cenario vermelho.
  2. `Scenario_Context_GetTypes_AfterTwoRegisterType_ContainsBoth` —
     `RegisterType(TypeInfo(TPortableFixture))` e
     `RegisterType(TypeInfo(TInner))`; chama `GetTypes`; afirma
     **pela busca por nome** no array que ambos aparecem (nao por
     `Length`, porque o Delphi tem pool nativo com contagem
     indefinida). Compartilhado.
  3. `Scenario_Context_FindType_Class_Found` — registra
     `TPortableFixture`, chama
     `FindType('UScenarios.RTTI.TPortableFixture')`, espera
     `not Result.IsNil` e `Result.Name = 'TPortableFixture'`.
     Compartilhado.
  4. `Scenario_Context_FindType_NotFound_ReturnsNil` — nome inventado,
     espera `Result.IsNil = True`. Compartilhado.
  5. `Scenario_Context_CopyByValue_SharesState_NoUseAfterFree` —
     **tres asserções encadeadas** (M-E):
     (a) `A := Ctx; A.RegisterType(T1); A.RegisterType(T2); B := A;` —
     busca por nome em `B.GetTypes` acha T1 e T2 (a copia enxerga);
     (b) `B.RegisterType(T3);` — busca em `A.GetTypes` acha T3
     (estado compartilhado, prova que nao ha duas copias
     independentes); (c) `A.Free;` — busca em `B.GetTypes` continua
     achando os tres (sem use-after-free, sem lixo); (d) `B.Free;`
     sem esperar excecao (sem double-free). Compartilhado. **Este e
     o cenario que mata a regressao do `Pointer`.**

- **Cascas:**
  - `Test FPC/EclbrSystem/UTestMS.RTTI.pas`: **cinco** metodos
    `published` (todos).
  - `Test Delphi/EclbrSystem/UTestMS.RTTI.pas`: **quatro** metodos
    `[Test]` (todos menos `_EmptyRegistry_Raises`).

### Nao inclui (out of scope)

- **`GetPackages`** — nao existe no FPC (conceito de "pacote" e do
  Delphi). Nao entra na superficie publica; motivo em XMLDoc do tipo.
  Se um dia fizer falta, entra em issue propria com o desenho de como
  representar "pacote" no FPC.
- **`Types` property em algum helper de contexto** — nao pedido pela
  issue #28. Se vier, e em issue propria.
- **Alteracao dos `Get*` existentes** ou dos records
  `TModernRTTIField`, `TModernRTTIProperty`, `TModernRTTIMethod` — o
  `FToken: Pointer` desses **continua** valido porque eles nao sao
  donos de heap (offset ou referencia nao-dona). Ver adr.md.
- **Reuso do `FContext` global** do backend Delphi — descartado para
  manter simetria com o FPC (alocacao per-instancia).

## 3. Regras de negocio

- **RB-1 · CA-5 (PRD.md):** zero `{$IFDEF FPC}` no consumidor. Um
  cenario compartilhado que use `TModernRTTIContext.GetTypes` /
  `FindType` compila e roda nos dois compiladores.
- **RB-2 · API-MAP §7:** unico `{$IFDEF}` da unit publica fica na
  `uses` da `implementation`. Nenhum `{$IFDEF}` novo em membros,
  estado ou implementacao.
- **RB-3 · Paridade de assinatura entre backends (API-MAP §7):** as
  cinco `Context*` tem assinatura identica nos dois `.pas`. Se um lado
  divergir, o build quebra — comportamento desejado.
- **RB-4 · D-26 (nao silenciar divergencia):** `GetTypes` com registry
  vazio no FPC **levanta** `EModernRTTIError` com mensagem instrutiva.
  Array vazio silencioso e indistinguivel de "esqueci de registrar" e
  esta proibido.
- **RB-5 · `nil` como resposta legitima:** `FindType` devolve
  `TModernRTTIType.FromRtti(nil)` quando nao acha; **`nil` aqui e
  resposta verdadeira**, nao falha escondida. `IsNil` torna a resposta
  inspecionavel.
- **RB-6 · Padrao de teste:** `try/except on E:` + `Fail(...)` sempre;
  nunca `Assert` (removivel sem `-Sa` — `SKILL.md:37`), nunca
  `Exception` generica (runner devolve exit 0 sobre vermelho —
  ModernSyntax#35), `AssertException` nao existe.
- **RB-7 · Frase-fronteira:** `Pointer` em record e seguro enquanto o
  record **nao e dono** (offset ou referencia); vira bomba no instante
  em que passa a ser (dono de heap). `TModernRTTIContext` e o primeiro
  caso e por isso usa `IInterface`.

## 4. Criterios de aceitacao

- [ ] `TModernRTTIContext` esta declarado publico em
      `Source/ModernSyntax.RTTI.pas` com `Create`, `Free`, `GetType`
      (dois overloads), `RegisterType`, `GetTypes`, `FindType`.
- [ ] `IModernRTTIContextToken` esta declarado publico com **GUID e
      sem membros publicos**.
- [ ] `TModernRTTIType.IsNil` existe e retorna `FType = nil`.
- [ ] Os dois backends declaram as **mesmas cinco** `Context*` no
      `interface` (paridade estrita).
- [ ] `GetTypes` devolve a lista de tipos com RTTI nos **dois**
      compiladores — no Delphi, o pool nativo; no FPC, o registry
      per-instancia alimentado por `GetType`/`RegisterType`.
- [ ] `FindType` acha por nome qualificado e devolve um
      `TModernRTTIType` com `IsNil = True` quando nao existe.
- [ ] `GetPackages` **nao existe** na superficie publica; o motivo
      esta em XMLDoc do tipo `TModernRTTIContext`.
- [ ] Cenario 1 (`_EmptyRegistry_Raises`) e **FPC-only na casca**,
      exercita `EModernRTTIError` do backend FPC, e o comentario do
      cenario declara a mutacao obrigatoria (remover o `raise` no
      backend deve deixar o cenario vermelho).
- [ ] Cenarios 2, 3, 4 e 5 sao compartilhados e rodam nas **duas
      cascas** — o cenario compartilhado nao carrega `{$IFDEF FPC}`.
- [ ] Cenario 5 (`_CopyByValue_SharesState_NoUseAfterFree`) afirma
      **as tres coisas** (enxerga, sobrevive ao `Free` da outra copia
      com a contagem certa por busca por nome, o `B.Free` posterior
      nao levanta).
- [ ] Nenhum cenario usa `Assert`, `Exception` generica ou
      `AssertException`.
- [ ] `grep -n "{\$IFDEF" Source/ModernSyntax.RTTI.pas` continua
      mostrando **apenas** a diretiva da `uses` da `implementation`
      (nada de `{$IFDEF}` novo).
- [ ] Compila e passa **nos dois bitness** com a receita de
      `.project/SKILL.md` (limpar `-FU` antes de recompilar).

## 5. Restricoes / Constraints

- Toolchain FPC 3.2.2, x86_64 e i386; comando fixado em
  `SKILL.md:29-51`.
- Testes FPC: **FPCUnit** (`fpcunit.ppu`), nunca DUnitX.
- Testes Delphi: **DUnitX** (nao vendorado; so o autor compila o lado
  Delphi — o PR **declara** o que foi compilado).
- **NUNCA** compilar `Source/` inteiro para provar a mudanca — o SKILL
  mede 0 de 16 units compilando, e falso vermelho.
- **SEMPRE** `rm -rf <out>` antes de recompilar — FPC reusa `.ppu` e
  reporta verde sobre codigo velho.

## 6. Riscos

- **R1 · Cast `AToken as TFPCContextToken` no backend.** Confia em
  invariante interna (so o proprio backend cria instancias que
  implementam o token). Trivialmente aceitavel: `IModernRTTIContextToken`
  e vocabulario interno da arquitetura, nao extension point. **Sem
  mitigacao alem da nota no [adr](pipeline-adr.md)**.
- **R2 · Ordem-dependencia em suite com registry per-instancia.**
  Anulada por construcao: cada `TModernRTTIContext.Create` produz um
  registry novo. **Sem acao**.
- **R3 · Cenario 5 e o cenario da regressao silenciosa.** Se ele
  passar com o desenho `FHandle: Pointer` de volta, a proteção morreu.
  Mitigacao: cenario afirma **as tres coisas** (enxerga, sobrevive,
  segundo `Free` nao levanta). Documentado no comentario do cenario.
- **R4 · `FindType` fora de `tkClass` no FPC.** Ler `UnitName` de kind
  != `tkClass` acessa campo inexistente naquele layout de `TTypeData`
  — lixo ou AV silencioso. Mitigacao: ramifica por `P^.Kind` e pula
  outros kinds; XMLDoc declara a divergencia de cobertura.
- **R5 · Delphi compila?** O autor e o unico que compila o lado
  Delphi. Mitigacao: PR **declara** o que foi compilado (SKILL.md);
  se falhar, ajuste caso a caso — o desenho e o padrao consagrado da
  RTL (`TRttiContext.FContextToken: IInterface`).

## 7. Fontes

- `[investigation report — issue #28]` (INVESTIGATION REPORT
  reproduzido no prompt deste no).
- [/strategy/2026-08-27-modernrtti/API-MAP.md](/strategy/2026-08-27-modernrtti/API-MAP.md)
  — §1, §2, §7.
- [/strategy/2026-08-27-modernrtti/PRD.md](/strategy/2026-08-27-modernrtti/PRD.md)
  — CA-5.
- [/SKILL.md](/SKILL.md) — receita FPC, mutacao, traps.
- [/history/cycles/cycle-011-38e3bcee/pipeline-adr.md](/history/cycles/cycle-011-38e3bcee/pipeline-adr.md)
  — D-26 (nao silenciar divergencia).
