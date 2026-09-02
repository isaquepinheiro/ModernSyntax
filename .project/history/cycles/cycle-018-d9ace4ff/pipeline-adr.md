---
type: adr
kind: decision
title: "ADR — TModernRTTIRecordType: Name + Size (issue #45), duas fixtures obrigatorias, helper RecordRaiseWrongKind, LCtx local, veto a ManagedFldCount"
description: "Restatement das decisoes acordadas no relatorio de investigacao da issue #45 (run d9ace4ff9a3af56be91a8f0373cb9475, volta 1): TModernRTTIRecordType com FToken PTypeInfo, FromTypeInfo sem guarda de Kind, Name e Size apenas (GetFields fica para issue-filha); backend FPC com string(P^.Name) e GetTypeData(P)^.RecSize, resourcestring SRecordWrongKind isolado, helper unificado RecordRaiseWrongKind; backend Delphi com delegacao a TRttiRecordType via LCtx local com try/finally (nao FContext global), GetTypeData(P)^.RecSize para paridade objetiva; duas fixtures obrigatorias em UScenarios.RTTI.pas (TRecordFixture45 unmanaged + TRecordFixture45M managed) porque uma fixture so com Size = 8 constante nos seis alvos anula o teste; asserção so por igualdade (Size = SizeOf(T)); veto explicito a ManagedFldCount como sinal para tkRecord puro; record end (Size = 0) tratado como valido; issue-filha para GetFields aberta fora do commit."
status: stable
cycle: "018"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/d9ace4ff9a3af56be91a8f0373cb9475
tags: [modernrtti, adr, issue-45, fpc, delphi, record, d1, d2, d4, d25.1, d43.1, d43.6, ca4, ca5]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: issue-45-report
    title: "REPORT — Issue #45 (run d9ace4ff9a3af56be91a8f0373cb9475) — PRESENT"
  - id: adr-044
    resource: "/history/cycles/cycle-017-9af8cdc2/pipeline-adr.md"
    title: "ADR #44 — TModernRTTIPointerType (padrao aditivo, LCtx local, dois cenarios)"
  - id: adr-043
    resource: "/history/cycles/cycle-016-9ac0699c/pipeline-adr.md"
    title: "ADR #43 — TModernRTTIEnumerationType (D-43.1, D-43.6, EnumRaiseWrongKind)"
  - id: adr-042
    resource: "/history/cycles/cycle-015-bb89abe1/pipeline-adr.md"
    title: "ADR #42 — D-1 (casca publica sem {$IFDEF}), D-2 (paridade de assinatura)"
  - id: adr-025
    resource: "/history/cycles/cycle-010-a36e1364/pipeline-adr.md"
    title: "ADR #25 — D-4 (guarda por Kind no FPC)"
  - id: api-map
    resource: "/strategy/2026-08-27-modernrtti/API-MAP.md"
    title: "API-MAP §7 (CA-4)"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, traps"
---

# ADR — issue #45 (TModernRTTIRecordType)

Este documento **deriva do relatorio de investigacao** que fechou a
discussao da issue #45 (uma volta, run
`d9ace4ff9a3af56be91a8f0373cb9475`), reproduzido verbatim no prompt do
ciclo. Registra a decisao **em vigor**, nos termos que a conversa
acertou. **Nao ha divergencia de merito** entre este ADR e o relatorio;
todos os sete pontos da volta 1 (Diretor) foram absorvidos como
decisoes explicitas.

## Contexto medido (do relatorio, verbatim)

Tres familias de medicoes governam o desenho, feitas pelo Diretor nos
seis alvos (FPC 3.2.2 i386/x86_64 + Delphi 23.0/37.0 x Win32/Win64):

- **Fixtures de record — `Size` por alvo:**
  ```
                     FPC/i386 FPC/x64  D23/32 D23/64  D37/32 D37/64
  TRecordFixture45      8       8       8      8       8      8    <- constante
  TManagedFix(str+int)  8      16       8     16       8     16    <- varia
  TNested(rec+str)     12      16      12     16      12     16    <- varia
  ```
  A fixture unmanaged sozinha e insuficiente: um backend que devolvesse
  `8` constante passaria por coincidencia. A fixture managed varia por
  bitness — nenhuma constante passa nas duas.

- **`ManagedFldCount` mente para `tkRecord`:**
  ```
  TPlain   (ZERO campos managed) -> ManagedFldCount = 2
  TManaged (UM campo managed)    -> ManagedFldCount = 2
  ```
  Leitura da uniao invalida para `tkRecord` puro (mesma familia do
  `ElType`/`RefTypeRef` que ja pegou #29/#44). **Nao deriva** nada
  desse campo.

- **`record end` (Size = 0) e valido nos seis alvos.** Nenhuma guarda
  pode rejeitar por `Size`.

Fontes documentais:
- API-MAP §7 (linhas 161-188): CA-4, zero `{$IFDEF}` novo na unit
  publica.
- `Source/ModernSyntax.RTTI.pas:1093-1096`: D-1/D-43.1, `FromTypeInfo`
  nao valida `Kind`.
- `Source/ModernSyntax.RTTI.Delphi.pas:115`: D-2/D-43.6, texto de erro
  identico entre backends.
- `Test Shared/EclbrSystem/UScenarios.RTTI.pas:23,136-147`: CA-5 (zero
  `{$IFDEF FPC}` em teste) e D-5 (fixture com `TypeInfo()` na secao
  `type` da `interface`).
- `Test FPC/EclbrSystem/UTestMS.RTTI.pas:87`: D-7 ("um cenario, duas
  cascas").
- `Source/ModernSyntax.RTTI.FPC.pas:473`: padrao consagrado do helper
  `EnumRaiseWrongKind`.

## Decisoes (D-45.x)

### D-45.1 — `TModernRTTIRecordType` com `FToken: PTypeInfo` e `FromTypeInfo` sem guarda de `Kind`

**Contexto.** A unit publica `ModernSyntax.RTTI.pas` ja hospeda tres
records da mesma familia (`TModernRTTIEnumerationType` #43,
`TModernRTTIPointerType` #44, `TModernRTTIType` do modulo), todos com
`strict private FToken` e uma factory que apenas atribui.

**Decisao.** `TModernRTTIRecordType` segue **exatamente** o padrao
consagrado: `strict private FToken: PTypeInfo`, `class function
FromTypeInfo(P: PTypeInfo): TModernRTTIRecordType; static` que faz
`Result.FToken := P` sem validar `Kind`.

**Alternativas descartadas.**

- Validar `Kind` na fabrica. Rejeitada: quebraria o padrao consagrado e
  violaria D-1 (fabrica na unit publica precisaria de `resourcestring`,
  o que a unit publica proibe).
- Passar `PTypeInfo` diretamente sem wrapper. Rejeitada: o wrapper existe
  para expor XMLDoc de contrato e reservar espaco para `GetFields` da
  issue-filha.

### D-45.2 — Superficie publica minima: `Name` e `Size` apenas (nada mais)

**Contexto.** A issue e explicita: `TModernRTTIRecordType` cobre `Name`
e `Size` **apenas**; `GetFields` fica para issue propria. O motivo
objetivo esta na medicao do Diretor: `RecSize` foi medido nos seis
alvos, `TRecordElement.Name` no FPC 3.2.2 **nao foi** (limitacao F-3
do estudo). Entregar `GetFields` sem essa medicao seria falar do que
nao se pode citar.

**Decisao.** O record publico expõe **exclusivamente**: `FromTypeInfo`,
`Name`, `Size`. XMLDoc do record carrega, verbatim, a frase do
acceptance: *"esta entrega cobre `Name` e `Size` apenas; `GetFields`
fica para issue propria condicionada a medir `TRecordElement.Name` num
FPC vivo"*. A issue-filha (titulo verbatim: *"`TModernRTTIRecordType.
GetFields`: medir `TRecordElement.Name` no FPC 3.2.2 antes de
entregar"*; labels `enhancement`, `rtti`, `fpc`, `blocked:medicao`) e
aberta **fora do commit**.

**Alternativas descartadas.**

- Entregar `GetFields` "provisorio" sem medicao. Rejeitada: o proprio
  historico da issue-mae #29 mostra que APIs entregues sem medicao
  viram `ElType`/`RefTypeRef` — bugs latentes que caem na cabeca de
  quem consome.
- Atrasar `Name`/`Size` esperando `GetFields`. Rejeitada: `Name` e
  `Size` estao medidos; segurar o que ja e seguro por causa do que
  ainda nao e seguro e desperdicio de ciclo.

### D-45.3 — Backend FPC: `string(P^.Name)` para `Name`, `GetTypeData(P)^.RecSize` para `Size`

**Contexto.** Medicao do Diretor confirma no FPC 3.2.2 (x86_64 e i386)
que `P^.Name` produz o identificador do record e
`GetTypeData(P)^.RecSize` produz o `Size` correto para ambas as
fixtures.

**Decisao.** Corpos minimos:
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

**Alternativas descartadas.**

- Delegar `Name` a `LCtx.GetType(P).Name` no FPC. Rejeitada: `TRttiContext`
  no FPC e mais caro (cria contexto por chamada) e o observavel e o
  mesmo — a leitura direta cabe.
- Derivar `Size` de contagem de campos. Rejeitada: `ManagedFldCount`
  mente para `tkRecord` puro (veto D-45.7); `RecSize` e o campo canonico
  do `TTypeData` para records.

### D-45.4 — Duas fixtures obrigatorias no cenario: `TRecordFixture45` (unmanaged) + `TRecordFixture45M` (managed)

**Contexto.** Medicao do Diretor:
`TRecordFixture45 = record FieldA, FieldB: Integer end;` da `Size = 8`
constante nos seis alvos. Um backend que devolvesse a constante 8
passaria por coincidencia — o teste nao valida leitura de layout, valida
"o backend nao mente sobre o valor 8".

**Decisao.** O cenario compartilhado constroi **duas** fixtures:
```pascal
TRecordFixture45  = record FieldA, FieldB: Integer end;   // unmanaged
TRecordFixture45M = record S: string; I: Integer end;      // managed
```
Faz **quatro** asserções (`Name`+`Size` por fixture), com padrao de
falha `raise ETestScenarioFailed.Create(...)`. Asserções **so por
igualdade** (`Size = SizeOf(T)`) — desigualdade `>=` nao prova nada
contra constante (`8 >= 8` tambem passa).

Regra: **variar a natureza do elemento** para nao passar por
coincidencia — a mesma regra que pegou o `ElType` na issue #29 e o
`Pointer` nil na issue #44.

**Alternativas descartadas.**

- Fixture unica `TRecordFixture45`. Rejeitada por medicao: um backend
  constante-8 passa em todos os seis alvos.
- Asserção `Size >= 2*SizeOf(Integer)`. Rejeitada: `8 >= 8` e verdade
  para a constante; desigualdade nao prova layout.
- Fixture aninhada (`record contendo record`) em vez da managed.
  Rejeitada: o observavel-chave e o `Size` variar por **bitness**;
  aninhamento diverge por outras razoes (alinhamento, padding) que nao
  fecham a mesma conta.

### D-45.5 — Helper `RecordRaiseWrongKind` por backend, `SRecordWrongKind` unico

**Contexto.** Padrao consagrado do modulo: `EnumRaiseWrongKind` em
`Source/ModernSyntax.RTTI.FPC.pas:473` (issue #43). Guarda inline
duplicada em `RecordTypeName` e `RecordTypeSize` divergiria em
nil-handling em silencio; e triplicaria quando `GetFields` da
issue-filha chegar. O argumento antecipatorio (quatro consumidores em
vez de dois) fecha a conta contra a economia de 5 linhas de codigo.

**Decisao.** Um helper por backend:
```pascal
procedure RecordRaiseWrongKind(P: PTypeInfo);
begin
  if (P = nil) or (P^.Kind <> tkRecord) then
    raise EModernRTTIError.Create(SRecordWrongKind);
end;
```
`SRecordWrongKind` **unico** por backend, com **texto identico** entre
FPC e Delphi (D-2/D-43.6). Cada funcao publica do backend chama
`RecordRaiseWrongKind(P);` como primeira instrucao.

**Alternativas descartadas.**

- Guarda inline duplicada. Rejeitada: divergencia latente de
  nil-handling; nao escala para `GetFields`.
- `SRecordWrongKind` diferente por backend. Rejeitada: quebra
  D-2/D-43.6 e testes de guarda futuros (comparariam contra texto
  literal) ficariam fragilizados.

### D-45.6 — Backend Delphi: `LCtx` local com `try/finally` (nao `FContext` global)

**Contexto.** Padrao Delphi do proprio modulo em `EnumMinValue`
(:364-377): `TRttiContext` local, `try/finally .Free`. O `FContext`
global existe em outros pontos mas acopla initialization order da unit
e complica testes.

**Decisao.** `RecordTypeName` no Delphi:
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
```
`RecordTypeSize` **nao** cria contexto — usa `GetTypeData(P)^.RecSize`
direto (paridade objetiva com o FPC; mais barato que `TRttiType.
TypeSize`, e a issue permite equivalente).

Delegacao a `TRttiRecordType` para `Name` mantida como seguranca para o
caso generico/aninhado (a medicao do Diretor cobriu so records simples
nos 4 alvos Delphi; a delegacao vira a rede para o que nao foi medido).

**Alternativas descartadas.**

- `FContext` global. Rejeitada: acoplamento; leitura transiente nao
  merece estado global.
- `TRttiType.TypeSize` no lugar de `GetTypeData(P)^.RecSize`.
  Rejeitada: mais caro, sem observavel diferente; quebra paridade
  objetiva com o FPC.
- `Result := string(P^.Name)` no Delphi. Rejeitada: no Delphi
  `TRttiRecordType.Name` cobre generico/aninhado sem medicao adicional;
  descer para `P^.Name` deixaria a delegacao morta.

### D-45.7 — Veto explicito a `ManagedFldCount` como sinal para `tkRecord`

**Contexto.** Medicao no FPC:
```
TPlain   (ZERO campos managed) -> ManagedFldCount = 2
TManaged (UM campo managed)    -> ManagedFldCount = 2
```
`ManagedFldCount` e leitura da uniao do `TTypeData` que **nao vale**
para `tkRecord` puro — mesma familia de bug do `ElType` (#29) e do
`RefTypeRef` (#44). Ler esse campo para record e ler lixo.

**Decisao.** **Nenhum** consumidor deste modulo deriva algo de
`ManagedFldCount` para `tkRecord`. Aqui, isso ja e verdade por
construcao (nao ha nenhuma leitura desse campo). Mas o **caveto** e
registrado na descricao da issue-filha *"`TModernRTTIRecordType.
GetFields`: medir `TRecordElement.Name` no FPC 3.2.2 antes de
entregar"* — para que o implementador de `GetFields` nao caia na
armadilha.

**Alternativa descartada.**

- Usar `ManagedFldCount` para pular passos de iteracao de campos.
  Rejeitada: medicao prova que o valor mente. O caveto e explicito na
  issue-filha.

### D-45.8 — `record end` (Size = 0) e valido; nao rejeitar por Size

**Contexto.** Medicao nos seis alvos: `record end` (record vazio) tem
`Size = 0` e passa por `Kind = tkRecord`.

**Decisao.** `RecordRaiseWrongKind` guarda **apenas** por
`(P = nil) or (P^.Kind <> tkRecord)`. **Nenhuma** condicao adicional
sobre `Size`. Um record legitimo com `Size = 0` produz
`RecordTypeSize = 0` (e o `Name` do record) sem levantar.

**Alternativa descartada.**

- Rejeitar `Size = 0` como "nao inicializado". Rejeitada por medicao:
  `record end` e valido.

### D-45.9 — Piso Delphi 23.0 sem `{$IF CompilerVersion}`

**Contexto.** Compilacao provada pelo Diretor nos 4 alvos Delphi (23.0
e 37.0 x Win32/Win64). `TRttiRecordType` e garantido desde XE2 (23.0).
Herança de #44/D-44.9.

**Decisao.** Backend Delphi **nao** carrega
`{$IF CompilerVersion >= ...}`. Se um mantenedor futuro precisar
suportar Delphi anterior a 23.0, sera issue nova.

**Alternativa descartada.**

- `{$IF CompilerVersion >= 23}` "por caridade" com pre-XE2. Rejeitada:
  piso medido; XE2+ e herança nao requisito.

## Convencoes que governam esta feature (referencia)

- **CA-4** — zero `{$IFDEF}` novo na unit publica `ModernSyntax.RTTI.pas`
  (herda o unico condicional que ja seleciona backend, :715-721). Fonte:
  API-MAP §7 (linhas 161-188) em
  [/strategy/2026-08-27-modernrtti/API-MAP.md](/strategy/2026-08-27-modernrtti/API-MAP.md).
- **D-1 / D-43.1** — `FromTypeInfo` nao valida `Kind` na fabrica.
  Fonte: comentario em `Source/ModernSyntax.RTTI.pas:1093-1096`.
- **D-2 / D-43.6** — texto de erro identico entre backends. Fonte:
  comentario em `Source/ModernSyntax.RTTI.Delphi.pas:115`.
  `SRecordWrongKind` tem o mesmo texto nos dois lados.
- **D-4** — guarda por `Kind` no ponto de uso. Fonte:
  `Source/ModernSyntax.RTTI.pas:1093-1096` e implementacoes #43/#44.
  Aqui, centralizada em `RecordRaiseWrongKind`.
- **D-5** — fixture com `TypeInfo()` na secao `type` da `interface` de
  `UScenarios.RTTI.pas`. Fonte: comentario em
  `UScenarios.RTTI.pas:136-147`.
- **D-7** — "um cenario, duas cascas". Fonte:
  `Test FPC/EclbrSystem/UTestMS.RTTI.pas:87`.
- **CA-5** — zero `{$IFDEF FPC}` em `UScenarios.RTTI.pas`. Fonte:
  `Test Shared/EclbrSystem/UScenarios.RTTI.pas:23`.
- **Padrao de helper de guarda por backend (`*RaiseWrongKind`).**
  Fonte: `EnumRaiseWrongKind` em `Source/ModernSyntax.RTTI.FPC.pas:473`.
- **Regra de teste 3 — variar a natureza do elemento para nao passar
  por coincidencia.** Fonte: mesma familia das correcoes #29 (`ElType`)
  e #44 (`Pointer` nil).

## Descartadas explicitas (do relatorio, sem parafrase)

- **Fixture unica `TRecordFixture45` (2 x Integer, `Size = 8`).**
  Descartada por medicao — constante nos seis alvos.
- **Asserção `Size >= 2*SizeOf(Integer)`.** Descartada — desigualdade
  nao prova layout.
- **Derivar qualquer coisa de `ManagedFldCount` para `tkRecord`.**
  Descartado por medicao — o valor mente.
- **Guarda inline duplicada** em `RecordTypeName` e `RecordTypeSize`.
  Descartada em favor do helper `RecordRaiseWrongKind`.
- **`FContext` global** para `TRttiContext` no `RecordTypeName` do
  Delphi. Descartado — acopla initialization order; padrao do backend
  Delphi ja e `LCtx` local (ex. `EnumMinValue` :364-377).
- **Guarda `Size = 0 → erro`.** Descartada — `record end` e valido.
- **"Assumido, confirmar no primeiro build"** nas notas de plano.
  Descartado — Diretor mede antes do PR.
- **`GetFields` nesta entrega.** Descartado por escopo objetivo:
  `TRecordElement.Name` no FPC 3.2.2 nao foi medido; issue-filha aberta
  fora do commit.

## O que este ADR nao decide (para nao invadir esp/plan/task-input)

- Ordem de execucao (e do [plan](pipeline-plan.md)).
- Numero de linhas por arquivo (e do [task-input](pipeline-task-input.md)).
- Escopo em criterio de aceitacao formatado (e do [esp](pipeline-esp.md)).

## Fontes

- Relatorio de investigacao (run `d9ace4ff9a3af56be91a8f0373cb9475`),
  reproduzido verbatim no prompt do ciclo.
- ADR #44 (cycle-017) — padrao aditivo, LCtx local, dois cenarios;
  esta entrega replica com a adaptacao de `tkRecord` e helper unificado.
- ADR #43 (cycle-016) — D-43.1, D-43.6, `EnumRaiseWrongKind` (o padrao
  que `RecordRaiseWrongKind` replica).
- ADR #42 (cycle-015) — D-1 e D-2, base normativa.
- ADR #25 (cycle-010) — D-4, guarda por `Kind` no FPC.
- API-MAP §7 — CA-4 (unit publica sem `{$IFDEF}` novo).
