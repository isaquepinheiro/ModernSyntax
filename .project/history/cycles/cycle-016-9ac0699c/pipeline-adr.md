---
type: adr
kind: decision
title: "ADR — TModernRTTIEnumerationType: guards por medicao (M-1..M-4), paridade FPC/Delphi, fixture TDia (issue #43)"
description: "Restatement das decisoes acordadas no relatorio de investigacao da issue #43 (run b8a0a2127f0d65070d91cfa172df44ac, volta 1): TModernRTTIEnumerationType com FToken PTypeInfo e FromTypeInfo sem guarda de Kind na fabrica (D-1 proibe resourcestring na unit publica); backend FPC com seis funcoes livres, cada uma abrindo com guarda por Kind; EnumGetName validando [MinValue..MaxValue] antes de TypInfo.GetEnumName (M-1: -1 devolve 'cA' silenciosamente) e EnumGetValue levantando quando GetEnumValue devolve -1 (M-2: colide com ordinal negativo); backend Delphi espelha os dois guards antes de delegar a TRttiEnumerationType para paridade por construcao (D-2); tres resourcestring novas isoladas no backend FPC (SEnumWrongKind, SEnumOrdinalOutOfRange, SEnumNameUnknown); quatro cenarios em UScenarios.RTTI.pas com fixture TCor + TDia (7 elementos), sendo TDia obrigatorio no cenario de contagem para matar a mutacao MaxValue-1 (M-4); enums descontinuos ficam fora por M-3 (FPC 3.2.2 recusa TypeInfo)."
status: stable
cycle: "016"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/9ac0699c1b65c18950220f022dfbb179
tags: [modernrtti, adr, issue-43, fpc, delphi, enumeration, m1, m2, m3, m4, d26]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-01T00:00:00Z"
sources:
  - id: issue-43-report
    title: "REPORT — Issue #43 (run b8a0a2127f0d65070d91cfa172df44ac) — PRESENT"
  - id: adr-042
    resource: "/history/cycles/cycle-015-bb89abe1/pipeline-adr.md"
    title: "ADR #42 — D-1 (casca publica sem {$IFDEF}), D-2 (paridade de assinatura)"
  - id: adr-025
    resource: "/history/cycles/cycle-010-a36e1364/pipeline-adr.md"
    title: "ADR #25 — D-4 (guarda por Kind no FPC), D-25.4"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, mutacao, traps"
---

# ADR — issue #43 (TModernRTTIEnumerationType)

Este documento **deriva do relatorio de investigacao** que fechou a
discussao da issue #43 (uma volta, run
`b8a0a2127f0d65070d91cfa172df44ac`), reproduzido verbatim no prompt do
ciclo. Registra a decisao **em vigor**, nos termos que a conversa
acertou. **Nao ha divergencia de merito** entre este ADR e o relatorio;
todos os deltas da volta 1 estao absorvidos.

## Contexto medido (do relatorio, verbatim)

Quatro medicoes do FPC 3.2.2, executadas nos dois bitness (x86_64 e
i386), que definem o contrato desta issue:

- **M-1 · `GetEnumName` com ordinal FORA DA FAIXA nao levanta — devolve
  lixo silencioso.**
  `GetEnumName(TCor, 99) = ''` (string vazia);
  `GetEnumName(TCor, -1) = 'cA'` (o primeiro nome, nao erro). O `-1` e
  o pior: um indice invalido devolve um **nome valido** —
  indistinguivel de resposta legitima.

- **M-2 · `GetEnumValue` com nome inexistente devolve `-1`.**
  `GetEnumValue(TCor, 'naoExiste') = -1`;
  `GetEnumValue(TCor, 'cB') = 1`. `-1` e sentinela, nao erro — colide
  com "enum poderia ter ordinal negativo" se enums descontinuos
  existissem.

- **M-3 · Enum com valores EXPLICITOS nao tem RTTI no FPC 3.2.2.**
  `TCod = (kX = 5, kY = 6); TypeInfo(TCod)` -> erro de compilacao "No
  type info available for this type". Consequencia boa: todo enum que
  chega ao backend tem `MinValue = 0` e faixa contigua (medido: `TCor`
  0..2, `TDia` 0..6). O `for i := MinValue to MaxValue` de
  `EnumGetNames` **e seguro hoje** — mas por essa razao, e nao por
  outra. Se o FPC passar a emitir RTTI para enums descontinuos, o laco
  reintroduz o risco: este ADR e o alarme.

- **M-4 · `MinValue`/`MaxValue` sao iguais nos dois bitness** (`TCor`
  0..2, `TDia` 0..6). Ao contrario de `RecSize`/`ArrayData.Size`, aqui
  o cenario **pode** afirmar valor absoluto.

## Decisao

### D-43.1 — Record publico com `FToken: PTypeInfo` e fabrica sem guarda de `Kind`

Declarar `TModernRTTIEnumerationType` em
`Source/ModernSyntax.RTTI.pas` antes de `TModernRTTI` (:561), com
`strict private FToken: PTypeInfo;` e `class function
FromTypeInfo(P: PTypeInfo): TModernRTTIEnumerationType; static;`.

**A fabrica NAO valida `Kind`.** Motivo: D-4 e o acceptance da issue ja
exigem a guarda por metodo em cada uma das seis funcoes do backend
FPC; duplicar na fabrica **obrigaria** declarar `resourcestring` na
unit publica, violando D-1. Custo por zero ganho de deteccao (o
primeiro metodo chamado ja levanta).

Governado por **D-1 / D-25.1** (casca publica sem `{$IFDEF}` novo).

### D-43.2 — Backend FPC: seis funcoes livres, cada uma abre com guarda por `Kind`

Novo grupo `// --- Enumeration (issue #43) ---` em
`Source/ModernSyntax.RTTI.FPC.pas` (interface + implementation).
Padrao vigente do arquivo (por D-4): cada funcao livre abre com

```
if (P = nil) or (P^.Kind <> tkEnumeration) then
  raise EModernRTTIError.CreateFmt(SEnumWrongKind, [...]);
```

Motivo: o record e polimorfico sobre `PTypeInfo`; sem guarda por metodo,
uma chamada com token errado desce ate `GetTypeData` e o
comportamento vira UB do RTL do FPC.

Governado por **D-4** e o padrao ja materializado em
`MethodIsConstructor/IsClassMethod/IsStatic` no FPC
(`RTTI.FPC.pas:355–411`).

### D-43.3 — `EnumGetName` valida `[MinValue..MaxValue]` antes de delegar (M-1)

Apos o guard de `Kind`, `EnumGetName(P, AOrdinal)` avalia
`(AOrdinal < GetTypeData(P)^.MinValue) or (AOrdinal >
GetTypeData(P)^.MaxValue)` e levanta `EModernRTTIError` com
`SEnumOrdinalOutOfRange` **antes** de chamar `TypInfo.GetEnumName`.

Motivo: M-1 — `TypInfo.GetEnumName(P, -1)` devolve o primeiro nome
silenciosamente no FPC 3.2.2. Sentinela indistinguivel de valor
legitimo e veneno (**D-26**).

### D-43.4 — `EnumGetValue` levanta quando `GetEnumValue` devolve `-1` (M-2)

Apos o guard de `Kind`, `EnumGetValue(P, AName)` captura o retorno de
`TypInfo.GetEnumValue`; se `= -1` levanta `EModernRTTIError` com
`SEnumNameUnknown`.

Motivo: M-2 — `-1` colide com "enum poderia ter ordinal negativo" se
enums descontinuos existissem. Mesmo que M-3 diga que hoje nao podem
existir, `raise` torna a garantia **local** e nao dependente de outra
propriedade do FPC (**D-26**).

### D-43.5 — Tres `resourcestring` novas ficam no backend FPC, nao na unit publica

`SEnumWrongKind`, `SEnumOrdinalOutOfRange`, `SEnumNameUnknown`
declaradas no bloco `resourcestring` ja existente em
`RTTI.FPC.pas:125`.

Motivo: manter `Source/ModernSyntax.RTTI.pas` **sem** `resourcestring`
novo — a fabrica nao valida `Kind` (D-43.1) exatamente para nao
precisar. Estas tres constantes sao detalhe de backend, nao contrato
publico.

Governado por **D-1**.

### D-43.6 — Backend Delphi espelha os dois guards antes de delegar (D-2)

Novo grupo `// --- Enumeration (issue #43) ---` em
`Source/ModernSyntax.RTTI.Delphi.pas` com as **mesmas seis
assinaturas**. Antes de delegar a `TRttiEnumerationType(FContext.GetType(P))`,
o backend Delphi **espelha os guards de M-1 e M-2** (faixa em
`EnumGetName`, `= -1` em `EnumGetValue`) com o mesmo texto de
`resourcestring` (duplicado no bloco `resourcestring` do backend
Delphi — cada backend tem o seu, padrao vigente do repo).

Motivo: nao confiar que `TRttiEnumerationType.GetName(-1)` guarda a
faixa da mesma forma; se levantasse `EInvalidCast` ou devolvesse `''`,
o contrato de erros ficaria assimetrico e o cenario negativo
`OutOfRangeAndUnknownRaises` seria FPC-only. **Paridade por
construcao** — a mutacao `MaxValue-1` fica vermelha nos dois lados.

Governado por **D-2** (paridade de assinatura nos dois backends).

### D-43.7 — Quatro cenarios em `UScenarios.RTTI.pas`, `TCor` + `TDia` na fixture

Os "dois cenarios compartilhados" da issue original viram **quatro**
(volta 1). Fixture ganha `TDia = (dSeg..dDom)` alem de `TCor = (cA, cB,
cC)`. Os quatro cenarios:

1. `Scenario_EnumerationType_NameAndBounds` — `TDia`.
2. `Scenario_EnumerationType_GetNameGetValue` — `TDia`, roundtrip por
   presenca.
3. `Scenario_EnumerationType_GetNames_LengthAndPresence` — **`TDia`
   obrigatorio**: com `TCor` (3 elementos), a mutacao `MaxValue-1` no
   laco de `EnumGetNames` passaria verde por off-by-one no fim; com
   `TDia` (7 elementos), fica vermelha.
4. `Scenario_EnumerationType_OutOfRangeAndUnknownRaises` — tres
   afirmacoes independentes com `try/except + Fail(...)`: `GetName(-1)`,
   `GetName(MaxValue+1)`, `GetValue('naoExiste')`. Cobre M-1 e M-2
   juntos.

Motivo: os dois cenarios do estudo (M-6 na issue) usavam so `TCor` e
nao verificavam raise. Com M-1/M-2 no contrato, o cenario negativo se
torna obrigatorio; com M-4 no laco de `GetNames`, `TDia` se torna
obrigatorio para matar a mutacao.

Governado por **D-6** (assertivas por relacao, nao por posicao fragil).

### D-43.8 — Mutacao de sanidade obrigatoria: `MaxValue` -> `MaxValue - 1`

O implementador **deve** validar `Scenario_EnumerationType_GetNames_LengthAndPresence`
com mutacao: trocar o `MaxValue` do laco de `EnumGetNames` (FPC ou
Delphi) por `MaxValue - 1` e recompilar. O cenario deve ficar vermelho.
`Fail(...)` sempre, nunca `Assert`. Sem essa validacao o cenario nao
paga por si.

### D-43.9 — `TCor` fica na fixture mas nao e exercitada por cenario hoje

O `Scenario 3` do acceptance original da issue (sobre `TCor`: `GetName(1)='cB'`,
`GetValue('cC')=2`, `MaxValue-MinValue+1 = Length(GetNames)`, tres
nomes presentes) foi absorvido pelos cenarios 2 e 3 acima, com `TDia`
em vez de `TCor`. `TCor` permanece **declarado** na fixture (uma linha,
`type` da `interface`) para uso futuro; nao ha cenario que o exercite
neste PR.

Motivo: `TCor` (3 elementos) nao mata a mutacao `MaxValue-1` (M-4);
manter o cenario original com `TCor` seria cerimonia sem valor de
deteccao.

## Descartado, e o motivo medido

- **Delegar `EnumGetName` direto a `TypInfo.GetEnumName` sem guarda de
  faixa** — recusado por **M-1**: `GetEnumName(TCor, -1) = 'cA'` no FPC
  3.2.2 (medido nos dois bitness). Sentinela indistinguivel de valor
  legitimo (**D-26**).
- **Devolver `-1` documentado em `EnumGetValue`** — recusado por
  **M-2**: `-1` colide com "enum poderia ter ordinal negativo"; ainda
  que M-3 diga que hoje nao pode, o `raise` torna a garantia **local**
  e nao dependente de outra propriedade do FPC.
- **Fixture so com `TCor` (3 elementos) para o cenario de contagem** —
  recusado por **M-4**: a mutacao `MaxValue-1` em `EnumGetNames`
  passaria verde com 3 elementos (off-by-one no fim). `TDia` (7
  elementos) mata a mutacao.
- **Duplicar a guarda de `Kind` na fabrica `FromTypeInfo`** — recusado:
  exigiria nova `resourcestring` na unit publica `RTTI.pas`, violando
  **D-1** sem ganho de deteccao (o guard por metodo, D-4, ja e
  obrigatorio).
- **Deixar os guards de M-1/M-2 apenas no backend FPC** — recusado por
  **D-2**: quebraria paridade semantica; a mutacao `MaxValue-1` e o
  cenario negativo tem que ser vermelhos nos dois bitness (Delphi
  inclusive).
- **Cobrir enum descontinuo (`TCod = (kX=5, kY=6)`) num cenario** —
  recusado por **M-3**: FPC 3.2.2 nao compila `TypeInfo(TCod)`. Nao ha
  como o cenario existir. Fica declarado neste ADR: se o FPC passar a
  emitir RTTI para enums descontinuos, o laco `MinValue..MaxValue`
  reintroduz o risco e este ADR e o alarme.
- **Nomes de metodo de `TRttiEnumerationType` divergentes tratados na
  unit publica** — recusado por **D-1**: qualquer `{$IF Declared(...)}`
  para lidar com divergencia de assinatura Delphi fica **dentro do
  backend Delphi**, nao em `RTTI.pas`.

## Perguntas em aberto

Nenhuma. O relatorio de investigacao (volta 1) fechou todas as questoes
levantadas pelo estudo original (Q1, Q3) na propria conversa; este ADR
apenas registra as respostas.

## Convencoes que governam isto

- **D-1** — zero `{$IFDEF}` em tipo publico (`RTTI.pas:18–22`, cycle
  015). Governa D-43.1 (fabrica sem `resourcestring`) e D-43.5
  (`resourcestring` no backend).
- **D-2** — paridade de assinatura nos dois backends (cycle 015).
  Governa D-43.6 (guards espelhados no Delphi).
- **D-4** — guarda explicita por `Kind` no FPC, cada funcao
  (`RTTI.FPC.pas:355–411`, cycle 010). Governa D-43.2.
- **D-6** — assertivas por relacao, nao por posicao fragil
  (`UScenarios.RTTI.pas:411–429`). Governa D-43.7 (cenarios 2 e 3).
- **D-26** — nao devolver valor que tambem e resposta legitima. Governa
  D-43.3 (M-1) e D-43.4 (M-2).
- **CA-5 do repo** — zero `{$IFDEF}` em `UScenarios.RTTI.pas`
  (`UScenarios.RTTI.pas:16`). Governa a escrita dos quatro cenarios.
