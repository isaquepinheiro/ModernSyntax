---
type: spec
kind: artifact
title: "ESP — TModernRTTIRecordType: Name + Size nos dois compiladores (issue #45)"
description: "Record publico TModernRTTIRecordType em ModernSyntax.RTTI.pas com FToken PTypeInfo, fabrica FromTypeInfo e metodos Name/Size (GetFields fica para issue-filha). Backend Delphi delega Name a TRttiRecordType via LCtx local com try/finally; Size via GetTypeData(P)^.RecSize. Backend FPC: Name = string(P^.Name); Size = GetTypeData(P)^.RecSize; guarda por Kind = tkRecord centralizada em helper RecordRaiseWrongKind. Duas fixtures obrigatorias em UScenarios.RTTI.pas: TRecordFixture45 (unmanaged, Size = 8 constante) e TRecordFixture45M (managed, S: string + I: Integer, Size varia 8/16 por bitness — bloqueia backend constante). Cenario compartilhado com quatro asserções (Name+Size por fixture); duas cascas de uma linha."
status: draft
cycle: "018"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/d9ace4ff9a3af56be91a8f0373cb9475
tags: [modernrtti, rtti, spec, issue-45, fpc, delphi, record, tmodernrttirecordtype]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: issue-45
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/45"
    title: "Issue #45 — TModernRTTIRecordType: Name + Size"
  - id: issue-29-parent
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/29"
    title: "Issue #29 — parent (tipos de categoria RTTI)"
  - id: adr
    resource: "adr.md"
    title: "ADR — TModernRTTIRecordType (issue #45)"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, traps"
  - id: conventions
    resource: "/analysis/05-conventions.md"
    title: "05 Conventions — ModernSyntax"
---

# ESP — issue #45 (TModernRTTIRecordType)

## 1. Objetivo

Introduzir o record publico `TModernRTTIRecordType` em
`Source/ModernSyntax.RTTI.pas`, com os observaveis **`Name` e `Size`**
apenas, comportamento observavel identico nos dois backends (Delphi
23.0/37.0 x Win32/Win64 e FPC 3.2.2 i386/x86_64).

`GetFields` fica **fora deste ciclo** e vira issue-filha condicionada a
uma medicao ainda nao feita (`TRecordElement.Name` no FPC 3.2.2) — a
issue-filha e aberta fora do commit desta entrega.

A entrega deriva do padrao consagrado do modulo
(`TModernRTTIEnumerationType` da issue #43,
`TModernRTTIPointerType` da issue #44) e completa mais uma familia de
`TypeInfo.Kind` sob o guarda-chuva da issue #29.

Aditivo puro: nenhum contrato existente muda; nenhum `{$IFDEF}` novo
entra na unit publica.

## 2. Escopo

### 2.1 Superficie publica (`Source/ModernSyntax.RTTI.pas`)

Um record novo, colocado apos `TModernRTTIPointerType` (:680), antes
do `///` de :682:

```pascal
TModernRTTIRecordType = record
strict private
  FToken: PTypeInfo;
public
  class function FromTypeInfo(P: PTypeInfo): TModernRTTIRecordType; static;
  function Name: string;
  function Size: Integer;
end;
```

XMLDoc `///` em cada membro publico. A frase-verbatim do acceptance
vive na XMLDoc do proprio record:

> esta entrega cobre `Name` e `Size` apenas; `GetFields` fica para issue
> propria condicionada a medir `TRecordElement.Name` num FPC vivo

Contratos individuais:

- `FromTypeInfo`: **nao** valida `Kind` (padrao consagrado; a guarda vive
  nos backends, D-4).
- `Name`: delega a `RecordTypeName(FToken)`. Levanta `EModernRTTIError`
  para token com `Kind <> tkRecord`.
- `Size`: delega a `RecordTypeSize(FToken)`. Levanta o mesmo erro sob a
  mesma condicao. `record end` com `Size = 0` e **valido** e nao pode ser
  rejeitado.

### 2.2 Backend FPC (`Source/ModernSyntax.RTTI.FPC.pas`)

- Duas funcoes livres declaradas na `interface`, apos
  `PointerTypeReferredType` (:123):
  ```pascal
  function RecordTypeName(P: PTypeInfo): string;
  function RecordTypeSize(P: PTypeInfo): Integer;
  ```
- Um `resourcestring SRecordWrongKind` novo, apos `SPointerWrongKind`,
  com texto **identico** ao do backend Delphi (D-2/D-43.6).
- Um helper `procedure RecordRaiseWrongKind(P: PTypeInfo);` na
  `implementation`, apos `PointerTypeReferredType` (:586), antes de
  `// --- Context`, analogo a `EnumRaiseWrongKind` (:473):
  ```pascal
  procedure RecordRaiseWrongKind(P: PTypeInfo);
  begin
    if (P = nil) or (P^.Kind <> tkRecord) then
      raise EModernRTTIError.Create(SRecordWrongKind);
  end;
  ```
  Guarda **exclusivamente** por nil ou `Kind` — **sem** condicao sobre
  `Size` (`record end` com `Size = 0` e valido).
- Corpos:
  ```pascal
  function RecordTypeName(P: PTypeInfo): string;
  begin
    RecordRaiseWrongKind(P);
    Result := string(P^.Name);
  end;

  function RecordTypeSize(P: PTypeInfo): Integer;
  begin
    RecordRaiseWrongKind(P);
    Result := GetTypeData(P)^.RecSize;
  end;
  ```

### 2.3 Backend Delphi (`Source/ModernSyntax.RTTI.Delphi.pas`)

- Paridade de assinatura (D-2): as duas mesmas assinaturas livres
  declaradas na `interface`, apos os pointer helpers (:101).
- `resourcestring SRecordWrongKind` no bloco local, com **texto identico**
  ao do FPC (D-2/D-43.6).
- Helper `RecordRaiseWrongKind` com a mesma guarda; `implementation` apos
  :481.
- Corpos:
  ```pascal
  function RecordTypeName(P: PTypeInfo): string;
  var
    LCtx: TRttiContext;
  begin
    RecordRaiseWrongKind(P);
    LCtx := TRttiContext.Create;
    try
      Result := TRttiRecordType(LCtx.GetType(P)).Name;
    finally
      LCtx.Free;
    end;
  end;

  function RecordTypeSize(P: PTypeInfo): Integer;
  begin
    RecordRaiseWrongKind(P);
    Result := GetTypeData(P)^.RecSize;
  end;
  ```

`LCtx` **local** com `try/finally` (padrao `EnumMinValue` :364-377) — nao
`FContext` global; nao acopla initialization order.

`RecordTypeSize` usa `GetTypeData(P)^.RecSize` (paridade objetiva com o
FPC; mais barato que `TRttiType.TypeSize`, permitido pela issue como
equivalente).

### 2.4 Cenario compartilhado (`Test Shared/EclbrSystem/UScenarios.RTTI.pas`)

Fixtures na secao `type` da `interface`, apos `PInt44` (~:199):

```pascal
{ Fixtures para issue #45. }
{ (1) Unmanaged: Size = 8 constante nos seis alvos (FPC i386/x86_64,
  Delphi 23.0/37.0 x Win32/Win64) — provada por medicao do relatorio. }
TRecordFixture45 = record
  FieldA, FieldB: Integer;
end;

{ (2) Managed: Size varia 8/16 por bitness (Delphi Win32/FPC i386 = 8;
  Delphi Win64/FPC x86_64 = 16). Bloqueia backend que devolva constante. }
TRecordFixture45M = record
  S: string;
  I: Integer;
end;
```

Uma procedure compartilhada declarada na `interface` (apos os cenarios
da issue #44) e implementada no bloco correspondente da `implementation`:

```pascal
procedure Scenario_RecordType_NameAndSize;
```

Corpo (padrao "raise `ETestScenarioFailed.Create(...)`" das issues
#43/#44):

```pascal
procedure Scenario_RecordType_NameAndSize;
var
  LRec, LRecM: TModernRTTIRecordType;
begin
  LRec  := TModernRTTIRecordType.FromTypeInfo(TypeInfo(TRecordFixture45));
  LRecM := TModernRTTIRecordType.FromTypeInfo(TypeInfo(TRecordFixture45M));
  if LRec.Name  <> 'TRecordFixture45' then
    raise ETestScenarioFailed.Create('Name(TRecordFixture45) inesperado.');
  if LRec.Size  <> SizeOf(TRecordFixture45) then
    raise ETestScenarioFailed.Create('Size(TRecordFixture45) != SizeOf.');
  if LRecM.Name <> 'TRecordFixture45M' then
    raise ETestScenarioFailed.Create('Name(TRecordFixture45M) inesperado.');
  if LRecM.Size <> SizeOf(TRecordFixture45M) then
    raise ETestScenarioFailed.Create('Size(TRecordFixture45M) != SizeOf.');
end;
```

**Quatro** asserções — nunca duas: uma fixture so, com `Size = 8`
constante nos seis alvos, e anulada por qualquer backend que devolva a
constante 8. A segunda fixture managed e o que **prova** leitura de
layout real.

**So igualdade** — `Size = SizeOf(T)`. Desigualdade `>=` nao prova nada
contra backend constante (`8 >= 8` tambem passa).

### 2.5 Cascas de teste

- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` — apos :149, antes do `end;`
  da classe: uma unica procedure com `[Test]`:
  ```pascal
  [Test] procedure TestRecordType_NameAndSize;
  ```
  Corpo de uma linha:
  ```pascal
  procedure TTestMS_RTTI.TestRecordType_NameAndSize;
  begin
    Scenario_RecordType_NameAndSize;
  end;
  ```
- `Test FPC/EclbrSystem/UTestMS.RTTI.pas` — em `published`, apos :89:
  uma unica procedure `procedure TestRecordType_NameAndSize;`, corpo de
  uma linha delegando ao cenario compartilhado.

### 2.6 Fora de escopo (out-of-scope, explicito)

- **`GetFields` do `TModernRTTIRecordType`.** Motivo objetivo: o
  Diretor mediu `RecSize` nos seis alvos, mas **nao mediu**
  `TRecordElement.Name` num FPC 3.2.2 vivo (limitacao F-3 do estudo). A
  issue-filha (titulo verbatim: *"`TModernRTTIRecordType.GetFields`:
  medir `TRecordElement.Name` no FPC 3.2.2 antes de entregar"*; labels
  `enhancement`, `rtti`, `fpc`, `blocked:medicao`) e aberta **fora do
  commit** desta entrega. Descricao carrega o **caveto** vetando
  `ManagedFldCount` como sinal para `tkRecord` puro (medicao: `TPlain`
  com zero campos managed retornou `ManagedFldCount = 2` — a leitura e
  da uniao do enum/set, mente para record puro).
- **Teste explicito de wrong-kind** (raise sob token com `Kind <>
  tkRecord`). Aditivo; se o revisor pedir, novo ciclo.
- **Cenarios adicionais alem do par (unmanaged, managed)** — records
  aninhados, records com variantes, records generico. O contrato cobre;
  o teste nao enumera.
- **Mutacao obrigatoria.** Ausente aqui: a issue nao pede (a delegacao a
  `TRttiRecordType`/`GetTypeData` no Delphi e a leitura direta no FPC
  nao tem contrapartida "obvia mas errada" a documentar).

## 3. Regras de negocio

- **B-45.1** — `Name` devolve o identificador do tipo record como
  ele aparece na fonte (`TRecordFixture45`, `TRecordFixture45M`). No
  Delphi, delegar a `TRttiRecordType.Name` cobre o caso generico. No
  FPC 3.2.2, `string(P^.Name)` produz o mesmo observavel (medicao do
  Diretor limitada a records simples nos alvos Delphi; a delegacao vira
  a segurança para o caso generico/aninhado).
- **B-45.2** — `Size` devolve `GetTypeData(P)^.RecSize`. Aplicando as
  duas fixtures do cenario, o observavel varia por bitness na fixture
  managed (8 em Win32/i386, 16 em Win64/x86_64) — nenhuma constante
  passa nas quatro asserções.
- **B-45.3** — `record end` (record vazio) e valido nos seis alvos e
  tem `Size = 0`. Nenhuma guarda pode rejeitar por `Size`.
- **B-45.4** — Guarda por `Kind = tkRecord` centralizada em
  `RecordRaiseWrongKind`, um helper por backend. Mesma mensagem em
  ambos (D-2/D-43.6). Abre caminho para `GetFields` da issue-filha
  reusar o mesmo helper sem duplicar guarda inline.

## 4. Criterios de aceitacao

Da issue #45, absorvendo os deltas do relatorio (volta 1):

- [ ] `TModernRTTIRecordType` declarado apos
      `TModernRTTIPointerType` (:680), com `strict private FToken:
      PTypeInfo`, `FromTypeInfo`, `Name`, `Size` — **e nada mais**.
- [ ] XMLDoc `///` do record contem a frase-verbatim do acceptance:
      *"esta entrega cobre `Name` e `Size` apenas; `GetFields` fica para
      issue propria condicionada a medir `TRecordElement.Name` num FPC
      vivo"*.
- [ ] `FromTypeInfo` **nao** valida `Kind` (D-1/D-43.1).
- [ ] Backend FPC: `RecordTypeName` e `RecordTypeSize` declaradas na
      `interface` (apos :123).
- [ ] Backend FPC: `resourcestring SRecordWrongKind` (mesma mensagem
      que no Delphi).
- [ ] Backend FPC: helper `RecordRaiseWrongKind` na implementation
      (apos :586), com guarda `(P = nil) or (P^.Kind <> tkRecord)` —
      **sem** condicao sobre `Size`.
- [ ] Backend Delphi: assinaturas espelhadas (:101), `resourcestring`
      identica, helper com mesma guarda; `RecordTypeName` usa `LCtx`
      **local** com `try/finally`; `RecordTypeSize` usa
      `GetTypeData(P)^.RecSize`.
- [ ] `UScenarios.RTTI.pas`: **duas** fixtures publicas —
      `TRecordFixture45` (unmanaged) e `TRecordFixture45M` (managed).
- [ ] `UScenarios.RTTI.pas`: `Scenario_RecordType_NameAndSize` com
      **quatro** asserções (Name+Size por fixture), padrao de falha
      `raise ETestScenarioFailed.Create(...)`.
- [ ] Cascas FPC e Delphi cada uma com **uma unica** procedure publicada
      (`TestRecordType_NameAndSize`), corpo de uma linha delegando.
- [ ] Cenario verde nos dois compiladores e nos dois bitness (`Size`
      casa com `SizeOf(T)` nas quatro asserções — a fixture managed
      varia 8/16 por bitness).
- [ ] Zero `{$IFDEF}` novo na unit publica `ModernSyntax.RTTI.pas`.
- [ ] Zero `{$IFDEF FPC}` em `UScenarios.RTTI.pas` (CA-5).
- [ ] Build FPC 3.2.2 x86_64 e i386 verdes; PR body declara compilacao
      Delphi 23.0/37.0 x Win32/Win64 (medicoes do Diretor, nao
      "assumido, confirmar no primeiro build").
- [ ] PR fecha `Closes #45`; mantem `Parte de #29`. Issue-filha
      *"`TModernRTTIRecordType.GetFields`: medir `TRecordElement.Name` no
      FPC 3.2.2 antes de entregar"* (labels `enhancement`, `rtti`, `fpc`,
      `blocked:medicao`) e **aberta fora do commit** — nao trava a
      entrega.

## 5. Restricoes (constraints)

- **D-1 / D-25.1** — a unit publica `ModernSyntax.RTTI.pas` **nao** tem
  `{$IFDEF}` em declaracao de tipo (:19). `TModernRTTIRecordType` sem
  `{$IFDEF}` interno; `resourcestring` de guarda nao vive aqui.
- **D-2** — paridade de assinatura entre backends: mesmos nomes e
  parametros; a divergencia legitima e apenas o corpo.
- **D-2/D-43.6** — texto de erro identico entre backends.
  `SRecordWrongKind` tem o mesmo texto nos dois lados.
- **D-4** — guarda por `Kind` no ponto de uso. Cada funcao publica do
  backend chama o helper de guarda antes de usar `P`. Aqui o helper e
  compartilhado (`RecordRaiseWrongKind`, padrao `EnumRaiseWrongKind`).
- **CA-4** — zero `{$IFDEF}` novo na unit publica (herda o unico
  condicional que ja seleciona backend, :715-721).
- **CA-5** — nenhum arquivo de teste tem `{$IFDEF FPC}`. Cenario
  compartilhado sem ramificacao por compilador.
- **D-5** — fixture com `TypeInfo()` na secao `type` da `interface` de
  `UScenarios.RTTI.pas` (fonte `UScenarios.RTTI.pas:136-147`). As duas
  fixtures da issue #45 seguem a regra.
- **D-7** — "um cenario, duas cascas": corpo unico em
  `UScenarios.RTTI.pas`; casca de uma linha em cada projeto.
- **Regra de teste 3** — variar a natureza do elemento para nao passar
  por coincidencia (mesma familia das correcoes #29 `ElType` e #44
  `Pointer` nil). A segunda fixture managed e a resposta arquitetural
  correta a essa regra.
- **Piso Delphi 23.0** — sem `{$IF CompilerVersion}` (compilacao provada
  pelo Diretor nos 4 alvos).

## 6. Riscos

- **R-1 — cenario com uma so fixture passa por coincidencia.** Se o
  implementador simplificar para `TRecordFixture45` sozinho (dois
  `Integer`, `Size = 8` constante nos seis alvos), qualquer backend que
  retorne 8 fixo passa e a asserção de layout vira teatro. **Mitigacao:**
  ESP §2.4 fixa duas fixtures obrigatorias; ADR D-45.4 registra o
  descarte da fixture unica; PLAN e TASK-INPUT reforcam.
- **R-2 — implementador cai em `ManagedFldCount` para derivar guarda de
  record.** Medicao mostra: `ManagedFldCount = 2` para `TPlain` (zero
  campos managed) — leitura da uniao invalida para `tkRecord` puro.
  **Mitigacao:** ESP e ADR proibem; caveto documentado sera colado na
  descricao da issue-filha de `GetFields`.
- **R-3 — implementador rejeita `record end` (Size = 0) na guarda.**
  Record vazio e valido; guarda por `Size` mata cenario legitimo.
  **Mitigacao:** helper `RecordRaiseWrongKind` restrito a `nil` ou
  `Kind`; **sem** condicao sobre `Size`.
- **R-4 — `FContext` global em vez de `LCtx` local no Delphi.**
  Acopla initialization order da unit e complica testes. **Mitigacao:**
  ESP §2.3 fixa `LCtx` local com `try/finally` (padrao `EnumMinValue`
  :364-377).
- **R-5 — texto divergente entre `SRecordWrongKind` do FPC e do Delphi.**
  Quebra D-2/D-43.6 em silencio; testes de guarda futuros seriam
  fragilizados. **Mitigacao:** ESP e TASK-INPUT prescrevem texto
  identico verbatim.
- **R-6 — guarda inline duplicada em vez do helper.** Divergencia de
  nil-handling entre `RecordTypeName` e `RecordTypeSize` vira bug latente
  (e triplicaria quando `GetFields` chegar). **Mitigacao:** helper unico
  por backend, padrao `EnumRaiseWrongKind` (D-45.5).

## 7. Fontes

- Relatorio de investigacao (run `d9ace4ff9a3af56be91a8f0373cb9475`,
  volta 1) reproduzido verbatim no prompt do ciclo — governa o
  [adr](pipeline-adr.md).
- [adr](pipeline-adr.md) — decisoes desta feature.
- [plan](pipeline-plan.md) — execucao em slices.
- [task-input](pipeline-task-input.md) — handoff operacional.
- [/analysis/05-conventions.md](/analysis/05-conventions.md) — D-1,
  D-2, D-4, D-25.1, CA-5.
- [/SKILL.md](/SKILL.md) — receita FPC, traps.
