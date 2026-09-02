---
type: adr
kind: decision
title: "ADR — issue #46: TModernRTTIArrayType (IsDynamic, ElementType, Size, Length) + TModernRTTISetType (ElementType); Length levanta em dinamico nos dois compiladores; leituras via property; fixture TDynByteArr46; duas mutacoes obrigatorias"
description: "Restatement das decisoes acordadas no relatorio de investigacao da issue #46 (run 03abedbe5ed05ff078e071ed503f401f, tres voltas): dois records novos com FToken PTypeInfo e FromTypeInfo sem guarda; TModernRTTIArrayType ramifica na superficie publica por IsDynamic; Length levanta EModernRTTIError com SArrayDynamicLength nos DOIS compiladores (paridade semantica); backend FPC usa properties elType2/ElType/CompType (nunca elType2Ref/elTypeRef/CompTypeRef) e ArrayData.Size/ArrayData.ElCount no estatico; backend Delphi ramifica por Kind (TRttiDynamicArrayType e TRttiArrayType sao IRMAS, nao descendente); resourcestring SArrayWrongKind/SArrayDynamicLength/SSetWrongKind com texto identico entre backends; texto curto de SArrayDynamicLength (Q4); helper unico ArrayRaiseWrongKind com guarda combinada [tkArray, tkDynArray] (drift novo D-46.4); fixture do cenario 8 e TDynByteArr46 (elSize=1 diverge de SizeOf(Pointer) nos DOIS bitness) — descarte medido de TDynIntArr46 (i386 empataria com SizeOf(Pointer)=4); comparacao de Name por referencia via TModernRTTI.GetType(TypeInfo(...)).Name (FPC=AnsiString, Delphi=string); Mutacao 1 coberta EXCLUSIVAMENTE pelo cenario 8 (cenario 9 passaria verde com codigo errado); duas mutacoes obrigatorias com log no PR; check ancorado a coluna zero para {$IFDEF} (grep cru mente por 12); contagens corretas 37 → 41 FPC e 35 → 39 Delphi."
status: stable
cycle: "019"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/0a0b1110fc1826855542e8d75c65cf65
tags: [modernrtti, adr, issue-46, fpc, delphi, array, set, d1, d2, d4, d25.1, d43.1, d43.6, d44.5, d45.1, ca4, ca5]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: issue-46-report
    title: "REPORT — Issue #46 (run 03abedbe5ed05ff078e071ed503f401f) — PRESENT"
  - id: adr-045
    resource: "/history/cycles/cycle-018-d9ace4ff/pipeline-adr.md"
    title: "ADR #45 — TModernRTTIRecordType (D-45.1, D-45.5 helper unificado, LCtx local)"
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

# ADR — issue #46 (TModernRTTIArrayType + TModernRTTISetType)

Este documento **deriva do relatorio de investigacao** que fechou a
discussao da issue #46 (tres voltas, run
`03abedbe5ed05ff078e071ed503f401f`), reproduzido verbatim no prompt do
ciclo. Registra a decisao **em vigor**, nos termos que a conversa
acertou. **Nao ha divergencia de merito** entre este ADR e o relatorio;
todos os quatro ajustes da conversa (Q1–Q4 da volta 1, fixture da volta
2, correcao de checks da volta 3) foram absorvidos como decisoes
explicitas.

## Contexto medido (do relatorio, verbatim)

Cinco familias de medicoes governam o desenho, feitas antes de cada
resposta:

- **`Size` estatico no Delphi.** Nos 4 alvos Delphi:
  `ArrayData.Size = TypeSize = SizeOf = 20` (24 em multidimensional).
  Nunca divergem. Desempate: paridade mecanica com o backend FPC.

- **`Length` estatico no Delphi.** Medido `array[0..1, 0..2] of Integer`:
  `ArrayData.ElCount = 6 = TotalElementCount`. A hipotese "correto para
  multidimensional futuro" caiu — `ElCount` ja e o produto de todos os
  graus. Desempate: paridade com FPC.

- **`ElementType.Name` para `array of string`.** FPC devolve
  `AnsiString`; Delphi devolve `string`. Comparacao por literal quebra
  num dos dois; comparacao por referencia contra
  `TModernRTTI.GetType(TypeInfo(<tipo>)).Name` absorve a divergencia sem
  `{$IFDEF}` (mesmo padrao ja usado no cenario 10 e em
  `Scenario_PointerType_ReferredType_Matches`).

- **Fixture do cenario 8.** FPC 3.2.2, dois bitness:
  ```
  array of Byte     elSize=1  elType2^.Name=Byte     elType=NIL
  array of Integer  elSize=4  elType2^.Name=LongInt  elType=NIL
  handle do dynarray: 4 em i386, 8 em x86_64
  ```
  `Byte` carrega as **duas** propriedades de uma vez: `elType = NIL`
  (mata Mutacao 1) **e** `elSize = 1` (diverge de `SizeOf(Pointer)` nos
  dois bitness). Com `Integer`, `elSize = 4` empata com o handle em
  i386 — a asserção so mata a mutacao `SizeOf(Pointer)` em x86_64.

- **Grep de `{$IFDEF}` no main `1a4323b`:**
  ```
  grep -c '{$IFDEF' Source/ModernSyntax.RTTI.pas    -> 12
  grep -cE '^[[:space:]]*\{\$(IFDEF|IFNDEF)' ...    ->  1
  mencoes em comentario/XMLDoc                      -> 11
  ```
  O grep cru mente por conta de 11 mencoes em `///`/`//`. O check
  ancorado em coluna zero e o correto — hoje da 1 e tem de continuar 1.

- **Contagens de teste no main de hoje:**
  ```
  FPC     37 published procedures
  Delphi  35 [Test]
  ```
  O "33" que aparece na issue foi repetido sem reconferir — as duas
  cascas nao empatam no total porque o Delphi carrega testes que o FPC
  nao roda.

Fontes documentais:
- API-MAP §7 (linhas 161-188): CA-4, zero `{$IFDEF}` novo na unit
  publica.
- `Source/ModernSyntax.RTTI.pas:1093-1096`: D-1/D-43.1, `FromTypeInfo`
  nao valida `Kind`.
- `Source/ModernSyntax.RTTI.Delphi.pas:115`: D-2/D-43.6, texto de erro
  identico entre backends.
- `Test Shared/EclbrSystem/UScenarios.RTTI.pas:23,136-147`: CA-5 e D-5.
- `Test FPC/EclbrSystem/UTestMS.RTTI.pas:87`: D-7 ("um cenario, duas
  cascas").
- `Source/ModernSyntax.RTTI.FPC.pas:473,577-578,614-615`: padrao de
  `*RaiseWrongKind` (issues #43, #44, #45).
- `Source/ModernSyntax.RTTI.FPC.pas:572`: D-44.5 (contexto local sem
  `try/finally` no FPC).

## Decisoes (D-46.x)

### D-46.1 — Dois records novos com `FToken: PTypeInfo` e `FromTypeInfo` sem guarda

**Contexto.** A unit publica ja hospeda quatro records da mesma familia
(`TModernRTTIType` do modulo, `TModernRTTIEnumerationType` #43,
`TModernRTTIPointerType` #44, `TModernRTTIRecordType` #45), todos com
`strict private FToken: PTypeInfo` e uma factory que apenas atribui.

**Decisao.** `TModernRTTIArrayType` e `TModernRTTISetType` seguem
**exatamente** o padrao consagrado (D-43.1/D-44.1/D-45.1). `FromTypeInfo`
faz `Result.FToken := P` sem validar `Kind`. A guarda vive nos backends
(D-4).

**Alternativas descartadas.**
- Validar `Kind` na fabrica. Rejeitada: quebraria o padrao consagrado e
  violaria D-1 (fabrica na unit publica precisaria de `resourcestring`,
  o que a unit publica proibe).
- Records separados para `tkArray` e `tkDynArray`. Rejeitada: a issue
  pede ramificacao **publica** por `IsDynamic`, nao dois tipos. Ver
  D-46.2.

### D-46.2 — `TModernRTTIArrayType` ramifica na superficie publica por `IsDynamic`; `Length` levanta em dinamico nos dois compiladores

**Contexto.** Array estatico e array dinamico compartilham o conceito
"tipo de elemento" mas divergem no que "comprimento" significa: estatico
tem comprimento em tempo de tipo (`ArrayData.ElCount`); dinamico so tem
comprimento em tempo de instancia (`System.Length(arr)`). RTTI de tipo
nao carrega contagem de instancia — pedir `Length` a `TypeInfo(TArray<T>)`
nao tem resposta significativa.

**Decisao.**
- **`IsDynamic: Boolean`** predicado publico — `Result := P^.Kind = tkDynArray`.
- **`Length` levanta `EModernRTTIError` com `SArrayDynamicLength` em
  dinamico**, nos **dois** compiladores (paridade semantica). Em estatico
  devolve `GetTypeData(P)^.ArrayData.ElCount` (produto de todos os graus,
  medido).

**Alternativas descartadas.**
- Devolver `0` ou `-1` em `Length` dinamico. Rejeitada: valor invalido
  e pior que erro; consumidor teria que checar convencao propria em vez
  de excecao.
- Dois records publicos (`TArrayType`, `TDynArrayType`). Rejeitada: a
  issue pede um so record com predicado; API publica plana.
- Levantar so no FPC (deixando Delphi devolver algo derivado do context
  RTTI). Rejeitada: quebra paridade semantica; consumidor cross-compiler
  teria que ramificar.

### D-46.3 — Texto curto em `SArrayDynamicLength`

**Contexto.** Q4 da volta 1. Texto longo ensinando "use `Length(arr)` em
runtime" foi proposto e descartado — resourcestring de RTTI nao e lugar
para ensinar API de linguagem.

**Decisao.** `SArrayDynamicLength = 'TModernRTTIArrayType.Length: nao suportado para arrays dinamicos.'`. **Identico** entre FPC e Delphi
(D-2/D-43.6).

**Alternativa descartada.**
- Texto longo com dica de `System.Length`. Rejeitada por escopo — RTTI
  reporta o que sabe do tipo, nao ensina API de instancia.

### D-46.4 — Helper `ArrayRaiseWrongKind` com guarda combinada `[tkArray, tkDynArray]` (drift novo do #46)

**Contexto.** Precedentes de guarda (`EnumRaiseWrongKind`,
`PointerRaiseWrongKind`, `RecordRaiseWrongKind`) sao guardas por **um
unico** `Kind`. Aqui, `tkArray` e `tkDynArray` compartilham helpers
(quatro funcoes livres do array), e cada funcao ramifica internamente
pelo sub-`Kind`.

**Decisao.**
```pascal
procedure ArrayRaiseWrongKind(P: PTypeInfo);
begin
  if (P = nil) or not (P^.Kind in [tkArray, tkDynArray]) then
    raise EModernRTTIError.Create(SArrayWrongKind);
end;
```

Helper **unico**, guarda combinada. Cada uma das quatro funcoes livres
(`ArrayTypeIsDynamic`, `ArrayTypeElementType`, `ArrayTypeSize`,
`ArrayTypeLength`) chama o helper como primeira instrucao e ramifica no
corpo por `P^.Kind = tkDynArray`.

`SetRaiseWrongKind` continua no padrao classico — guarda por `tkSet` so.

**Alternativas descartadas.**
- Dois helpers `ArrayStaticRaiseWrongKind` e `ArrayDynamicRaiseWrongKind`.
  Rejeitada: as quatro funcoes precisam aceitar os dois `Kind` — helper
  unico e o que o padrao pede.
- Helper por `Kind` chamado pela ramificacao interna. Rejeitada: duplica
  a guarda por chamada e nao pega o caso `Kind` fora do conjunto.

### D-46.5 — Backend FPC usa properties `elType2`, `ElType`, `CompType`; **nunca** os refs crus

**Contexto.** Padrao ja consagrado na correcao do bug do `#29` (`ElType`)
e do `#44` (`RefTypeRef`): os campos `elType2Ref`, `elTypeRef`,
`CompTypeRef` do FPC 3.2.2 sao **referencias intermediarias** cujo
layout pode divergir do `PTypeInfo` esperado. As **properties**
(`elType2`, `ElType`, `CompType`) fazem a desreferenciacao correta.

**Decisao.**
- `ArrayTypeElementType(P)`:
  - dinamico → `GetTypeData(P)^.elType2` (property).
  - estatico → `GetTypeData(P)^.ArrayData.ElType` (property).
- `SetTypeElementType(P)`: `GetTypeData(P)^.CompType` (property).
- Check de aceitacao: `grep -n 'elType2Ref\|elTypeRef\|CompTypeRef' Source/ModernSyntax.RTTI.FPC.pas` = **0** (hoje 0, tem de continuar 0).

**Alternativa descartada.**
- Ler `elType2Ref^`, `elTypeRef^`, `CompTypeRef^` com cast manual.
  Rejeitada: reintroduz a familia de bug do #29/#44. As properties ja
  existem no FPC 3.2.2 e sao o contrato certo.

### D-46.6 — `ArrayTypeSize` no estatico usa `ArrayData.Size`; `ArrayTypeLength` usa `ArrayData.ElCount` (paridade objetiva com Delphi)

**Contexto.** Medicao do Q1 (Delphi): `ArrayData.Size = TypeSize = SizeOf`
nos 4 alvos. Medicao do Q2 (Delphi): `ArrayData.ElCount = TotalElementCount`
em multidimensional; `ElCount` ja e o produto de todos os graus.

**Decisao.**
- `ArrayTypeSize` estatico: `GetTypeData(P)^.ArrayData.Size`.
- `ArrayTypeSize` dinamico: `GetTypeData(P)^.elSize` (tamanho do
  elemento no dinamico).
- `ArrayTypeLength` estatico: `GetTypeData(P)^.ArrayData.ElCount`.
- `ArrayTypeLength` dinamico: `raise` (D-46.2).

Nos **dois** compiladores. Empates semanticos foram desempatados por
**paridade mecanica** com o backend FPC.

**Alternativas descartadas.**
- `TypeSize` no Delphi. Rejeitada por Q1: empata com `ArrayData.Size`;
  desempate por paridade com FPC.
- `TotalElementCount` no Delphi. Rejeitada por Q2: empata com `ElCount`
  em multi; o argumento "correto para multidimensional futuro" caiu
  (medicao prova que `ElCount` ja e o produto de todos os graus);
  desempate por paridade com FPC.

### D-46.7 — Fixture do cenario 8 e `TDynByteArr46 = array of Byte` (nao `TDynIntArr46 = array of Integer`)

**Contexto.** Medicao FPC 3.2.2:
```
array of Byte     elSize=1  elType=NIL
array of Integer  elSize=4  elType=NIL
handle do dynarray: 4 em i386, 8 em x86_64
```
Com `Integer` (`elSize = 4`), asserção de `Size = 4` empata com
`SizeOf(Pointer) = 4` em i386. A mutacao "trocar `elSize` por
`SizeOf(Pointer)`" so morre em x86_64 — depende de o CI rodar o segundo
bitness. Ja custou tres defeitos escondendo em 32 bits: a mutacao da
#45, o `elType` do gerenciado, e este `Size`.

**Decisao.** Fixture do cenario 8 vira `TDynByteArr46 = array of Byte`.
`Byte` carrega as **duas** propriedades de uma vez:
- `elType = nil` (mata Mutacao 1: `elType2 → elType` daria AV ao
  acessar `.Name`).
- `elSize = 1` (diverge de `SizeOf(Pointer)` em i386 (4≠1) **e** em
  x86_64 (8≠1)).

Uma unica asserção de `Size = 1` passa a valer sozinha em cada bitness —
sem depender da corrida x86_64.

**Alternativa descartada.**
- `TDynIntArr46 = array of Integer` no cenario 8. Descartada por
  medicao: `elSize = 4` empata com `SizeOf(Pointer)` em i386; asserção
  de `Size` so mataria a mutacao `SizeOf(Pointer)` se x86_64 rodasse.
  Custo de trocar para `Byte`: uma linha no fixture.

### D-46.8 — Comparacao de `ElementType.Name` sempre por referencia

**Contexto.** Q3 da volta 1. Medicao: para `array of string`, FPC
devolve `AnsiString` e Delphi devolve `string`. Comparacao por literal
quebra num dos dois backends.

**Decisao.** Nos cenarios cross-compiler (8, 9, 10), comparacao de
`ElementType.Name` sempre contra `TModernRTTI.GetType(TypeInfo(<tipo>)).Name`.
Absorve a divergencia sem `{$IFDEF FPC}` (mesmo padrao ja usado no
cenario 10 e em `Scenario_PointerType_ReferredType_Matches`).

**Alternativa descartada.**
- Comparar por literal (`'Byte'`, `'string'`, `'TCor'`). Rejeitada: `'AnsiString' <> 'string'` quebra o cenario 9.

### D-46.9 — Mutacao 1 coberta **exclusivamente** pelo cenario 8; comentario do cenario 9 nao promete cobri-la

**Contexto.** Ponto (a) da volta 1. Medicao FPC 3.2.2:
```
array of Integer -> elType2^.Name=LongInt    elType=NIL
array of string  -> elType2^.Name=AnsiString elType^.Name=AnsiString
```
Trocar `elType2` por `elType` da AV **so** no unmanaged. Cenario 9
(`array of string`) passaria **verde** com o codigo errado — `elType`
do gerenciado nao e nil.

**Decisao.** O log da Mutacao 1 no PR e o do **cenario 8** sobre
`TDynByteArr46`. Comentario do fixture/cenario 9 **nao** pode prometer
cobrir a Mutacao 1; documenta apenas o path gerenciado.

**Alternativa descartada.**
- Anexar o log da Mutacao 1 do cenario 9 "por analogia". Rejeitada por
  medicao: cenario 9 nao morre com a mutacao.

### D-46.10 — Backend Delphi ramifica por `Kind` (irmas `TRttiDynamicArrayType` / `TRttiArrayType`)

**Contexto.** Q1 da volta 1 confirmou o que a issue inicialmente sugeria
errado: **`TRttiDynamicArrayType` NAO e descendente de `TRttiArrayType`**
no Delphi. Sao irmas em `System.Rtti`. Nao existe cast comum entre elas.

**Decisao.** `ArrayTypeElementType` no Delphi ramifica por `Kind`:
- dinamico → `TRttiDynamicArrayType(LCtx.GetType(P)).ElementType.Handle`.
- estatico → `TRttiArrayType(LCtx.GetType(P)).ElementType.Handle`.

`LCtx` local com `try/finally` (padrao `RecordTypeName` :505-521).

**Alternativa descartada.**
- Cast comum a um ancestral. Rejeitada por medicao: `TRttiArrayType` e
  `TRttiDynamicArrayType` sao irmas em `System.Rtti`; o cast simplesmente
  nao compila (ou compila com AV em runtime).

### D-46.11 — Checks de aceitacao ancorados (`{$IFDEF}` e refs crus)

**Contexto.** Volta 3. O grep cru `grep -c '{$IFDEF' Source/ModernSyntax.RTTI.pas` da **12** no main `1a4323b` — 11 sao mencoes em `///`/`//`.
Qualquer comentario novo que escreva `{$IFDEF}` muda o numero sem o
codigo ter mudado; uma diretiva **nova** de verdade se perde no ruido.

**Decisao.**
- Check de `{$IFDEF}` novo: `grep -cE '^[[:space:]]*\{\$(IFDEF|IFNDEF)' Source/ModernSyntax.RTTI.pas` — hoje **1**, tem de continuar **1**.
  Ancorado em coluna zero, ignora comentario, so conta diretiva real.
- Check de refs crus (ja correto no estudo): `grep -n 'elType2Ref\|elTypeRef\|CompTypeRef' Source/ModernSyntax.RTTI.FPC.pas` — hoje **0**, tem de continuar **0**.

**Alternativa descartada.**
- Grep cru `grep -c '{$IFDEF' ...`. Rejeitada por medicao: mente por
  duas razoes (conta comentario; nao distingue diretiva nova).

### D-46.12 — Contagens de teste corretas (37 → 41 FPC, 35 → 39 Delphi)

**Contexto.** Volta 3. Medido no main de hoje: FPC tem 37 publisheds;
Delphi tem 35 `[Test]`. Nao 33 nas duas cascas (numero repetido do
texto da issue sem reconferir).

**Decisao.** PR body declara **"+4 cenarios em cada casca; FPC vai de
37 para 41 published, Delphi vai de 35 para 39 `[Test]`. As contagens
absolutas divergem porque a casca Delphi hospeda testes que o FPC nao
compila — a igualdade e dos 4 cenarios adicionados, nao do total."**

**Alternativa descartada.**
- "33 → 37 nos dois". Rejeitada por medicao — numero nunca foi
  verdadeiro.

## Convencoes que governam esta feature (referencia)

- **CA-4** — zero `{$IFDEF}` novo na unit publica `ModernSyntax.RTTI.pas`.
  Fonte: API-MAP §7 em
  [/strategy/2026-08-27-modernrtti/API-MAP.md](/strategy/2026-08-27-modernrtti/API-MAP.md).
  Check ancorado a coluna zero (D-46.11).
- **D-1 / D-43.1 / D-44.1 / D-45.1** — `FromTypeInfo` nao valida `Kind`
  na fabrica. Fonte: comentario em `Source/ModernSyntax.RTTI.pas:1093-1096`.
- **D-2 / D-43.6** — texto de erro identico entre backends.
  `SArrayWrongKind`, `SArrayDynamicLength`, `SSetWrongKind` tem o mesmo
  texto nos dois lados. Fonte: comentario em
  `Source/ModernSyntax.RTTI.Delphi.pas:115`.
- **D-4** — guarda por `Kind` no ponto de uso. Aqui, centralizada em
  `ArrayRaiseWrongKind` (guarda combinada — drift D-46.4) e
  `SetRaiseWrongKind` (padrao classico).
- **D-44.5** — `TRttiContext` local no FPC sem `try/finally` (record por
  valor); no Delphi com `try/finally .Free`. Fonte:
  `Source/ModernSyntax.RTTI.FPC.pas:572` e `RecordTypeName` do Delphi
  :505-521. Nao ha `TRttiContext` no FPC para essas leituras — sao
  diretas via `GetTypeData(P)^`.
- **D-5** — fixtures com `TypeInfo()` na secao `type` da `interface` de
  `UScenarios.RTTI.pas`. Fonte: comentario em
  `UScenarios.RTTI.pas:136-147`.
- **D-7** — "um cenario, duas cascas". Fonte:
  `Test FPC/EclbrSystem/UTestMS.RTTI.pas:87`. Quatro cenarios novos,
  quatro cascas por lado.
- **CA-5** — zero `{$IFDEF FPC}` em `UScenarios.RTTI.pas`. Fonte:
  `Test Shared/EclbrSystem/UScenarios.RTTI.pas:23`.
- **Padrao de helper de guarda por backend (`*RaiseWrongKind`).**
  Fonte: `EnumRaiseWrongKind` em `Source/ModernSyntax.RTTI.FPC.pas:473`,
  `PointerRaiseWrongKind` :577-578, `RecordRaiseWrongKind` :614-615.
- **Regra de teste 3 — variar a natureza do elemento para nao passar
  por coincidencia.** Fonte: mesma familia das correcoes #29 (`ElType`),
  #44 (`Pointer` nil), #45 (fixture managed). Aqui: unmanaged/managed
  no array (cenarios 8/9), bitness no `Size` (cenario 8).
- **Piso Delphi 23.0** — sem `{$IF CompilerVersion}`. Fonte: herança de
  D-44.9/D-45.9.

## Descartadas explicitas (do relatorio, sem parafrase)

- **`TotalElementCount` no Delphi estatico** (Q2, volta 1). Descartado
  por medicao: `ArrayData.ElCount` ja e o produto de todos os graus em
  multi (`array[0..1, 0..2] of Integer` → 6 em ambos). Empate; desempate
  por paridade com FPC.
- **`TypeSize` no Delphi estatico** (Q1, volta 1). Descartado por
  medicao: `ArrayData.Size = TypeSize = SizeOf` nos 4 alvos. Paridade
  com FPC desempata.
- **Comparacao de `Name` por literal em cenario cross-compiler** (Q3,
  volta 1). Descartado por medicao: `AnsiString ≠ string` para
  `array of string`.
- **Texto longo em `SArrayDynamicLength` ensinando `System.Length`**
  (Q4, volta 1). Descartado por escopo — resourcestring de RTTI nao
  ensina API de linguagem.
- **Fixture `TDynIntArr46 = array of Integer` no cenario 8** (volta 2).
  Descartada por medicao: `elSize = 4` empata com `SizeOf(Pointer) = 4`
  em i386. `TDynByteArr46` mata em qualquer bitness sozinho.
- **Cenario 9 cobrindo Mutacao 1** (volta 1, ponto (a)). Descartado por
  medicao: `elType` do gerenciado nao e nil; cenario 9 passa verde com
  o codigo errado.
- **Grep cru `grep -c '{$IFDEF' ...`** (volta 3). Descartado por
  medicao: da 12 no main, 11 sao ruido. Substituido por regex ancorada
  em coluna zero.
- **Contagem "33 → 37" nas duas cascas** (volta 3). Descartada por
  medicao: FPC tem 37, Delphi 35 no main; contagens corretas sao
  37 → 41 e 35 → 39.

## O que este ADR nao decide (para nao invadir esp/plan/task-input)

- Ordem de execucao (e do [plan](pipeline-plan.md)).
- Numero de linhas por arquivo (e do [task-input](pipeline-task-input.md)).
- Escopo em criterio de aceitacao formatado (e do [esp](pipeline-esp.md)).

## Fontes

- Relatorio de investigacao (run `03abedbe5ed05ff078e071ed503f401f`,
  tres voltas), reproduzido verbatim no prompt do ciclo.
- ADR #45 (cycle-018) — padrao consagrado do helper unificado
  `*RaiseWrongKind`, LCtx local no Delphi, `FromTypeInfo` sem guarda.
- ADR #44 (cycle-017) — padrao aditivo, LCtx local, dois cenarios.
- ADR #43 (cycle-016) — D-43.1, D-43.6, `EnumRaiseWrongKind` (o padrao
  que `ArrayRaiseWrongKind`/`SetRaiseWrongKind` replicam).
- ADR #42 (cycle-015) — D-1 e D-2, base normativa.
- ADR #25 (cycle-010) — D-4, guarda por `Kind` no FPC.
- API-MAP §7 — CA-4 (unit publica sem `{$IFDEF}` novo).
