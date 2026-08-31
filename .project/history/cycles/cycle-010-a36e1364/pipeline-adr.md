---
type: adr
kind: decision
title: "ADR — TModernRTTIMethod: enumerar published pela vmtMethodTable, com falha honesta onde não há dado (issue #25)"
description: "Restatement da decisão aprovada na discussão da issue #25: property indexada Entry[i], separação lookup/enum, EModernRTTIError para os seis membros sem fonte no FPC, TModernRTTIParameter com Name/ParamType reais, e cirurgia do Fail em UScenarios.RTTI.pas fechando #35."
status: stable
cycle: "010"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/a36e13649de2fc026303074567d63275
tags: [modernrtti, adr, issue-25, fpc, delphi, vmtmethodtable]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-31T00:00:00Z"
sources:
  - id: issue-25-comment
    title: "Comentário de decisão em ModernSyntax#25 (run c5271fa423a4d7a85c53f313bfb2159c)"
  - id: api-map
    resource: "/strategy/2026-08-27-modernrtti/API-MAP.md"
    title: "ModernRTTI API-MAP §§1,2,4,7"
  - id: study
    resource: "/strategy/2026-08-27-modernrtti/STUDY.md"
    title: "STUDY ModernRTTI (§F-4 vira errata)"
---

# ADR — issue #25

Este documento **deriva do relatório de investigação** que fechou a
discussão da issue #25. Ele registra a decisão em vigor, nos termos que a
conversa acertou. Nada aqui é reabertura — os pontos abaixo já foram
concordados humano+agente e o próximo portão é escrever código.

## Contexto medido

- `TRttiMethod` do FPC 3.2.2 **tem todos os membros** que a issue lista;
  o que falta é dado: `TRttiType.GetMethods` devolve **0** para qualquer
  classe. A lista vem da `vmtMethodTable` e ela enumera (medido:
  `TSubject` publicou 2 métodos).
- `TVmtMethodEntry` (`typinfo.pp:388-396`) **só** carrega `Name` e
  `CodeAddress`. `ResultType`, `ParamCount`, `Kind`, `CallConv` só
  existem em `TIntfMethodEntry` (interface), nunca para classe.
- `SizeOf(TVmtMethodTable)` e `SizeOf(TVmtMethodEntry)` mudam por
  bitness (20/12 e 16/8). Aritmética literal quebra i386.
- `TObject.MethodAddress` sobe a cadeia por conta própria (medido:
  `TDerived.MethodAddress('Alpha')` acha método herdado).
- `Assert(...)` é removido sem `-Sa`, e a receita do repo
  (`SKILL.md:37`) não passa `-Sa`.
- `UScenarios.RTTI.pas:95` levanta `Exception` genérica; isso faz
  `PTestRTTI` devolver **exit 0 mesmo com cenário reprovado** (matriz
  medida).

## Decisão D-25.1 — arquitetura §7 aplicada agora

`Source/ModernSyntax.RTTI.pas` é a **casca pública**: zero `{$IFDEF}` em
declaração de tipo, único `{$IFDEF}` na `uses` da `implementation`
selecionando `ModernSyntax.RTTI.Delphi` ou `ModernSyntax.RTTI.FPC`.
Backends expõem a **mesma superfície de funções livres** — a compilação
é o portão que garante paridade de assinatura.

Este ciclo aplica a §7 aos três tipos que o teste alcança:
`TModernRTTIField` (removendo o `{$IFDEF}` atual do `strict private`),
`TModernRTTIMethod` (novo) e `TModernRTTIParameter` (novo). O estado
privado dos três é neutro (`FOwner: TClass`, `FName: string`,
`FToken: Pointer`; `Parameter` acresce `FTypeToken: Pointer`).

**Descartado:** manter `{$IFDEF FPC}` no `strict private` de
`TModernRTTIField` — é o defeito que a issue explicitamente ataca.

## Decisão D-25.2 — iteração por `LTab^.Entry[i]`, sem aritmética

`MethodTokens(AClass)` no backend FPC itera com a property indexada:

```pascal
LTab := PVmtMethodTable(PVmt(LCur)^.vMethodTable);
if LTab <> nil then
  for i := 0 to LTab^.Count - 1 do
    ...LTab^.Entry[i]...
```

**Descartado:** `PByte(LTab) + 4 + i * SizeOf(TVmtMethodEntry)`. Motivo
medido: `Count` é `LongWord` (`typinfo.pp:407`), não `Word` — não há
padding de 2 bytes; `SizeOf(TVmtMethodEntry)` = 16 em x86_64 e 8 em
i386 — literal quebra. STUDY §F-4 vira errata; o agente reconheceu que
`20 = 4+16 = 2+2+16` foi coincidência aritmética, não prova de layout.

## Decisão D-25.3 — separar `MethodTokens` (enum) de `MethodToken` (lookup)

`MethodTokens(AClass)` faz o laço por `ClassParent` (necessário para
enumeração). `MethodToken(AClass, AName)` é uma linha — usa
`MethodAddress`, que sobe a cadeia sozinho. `TModernRTTIType.GetMethod`
delega a `MethodToken`; não replica o laço de herança.

**Descartado:** replicar o loop em `GetMethod`. Medido:
`TObject.MethodAddress` já resolve herança.

## Decisão D-25.4 — `EModernRTTIError` nos seis membros sem fonte no FPC

`IsConstructor`, `IsClassMethod`, `IsStatic`, `Visibility`,
`ReturnType`, `GetParameters` levantam `EModernRTTIError` no FPC com
mensagem instrutiva. Precedente: `TModernRTTIType.GetProperties`
(`Source/ModernSyntax.RTTI.pas:296,:359`).

**Descartado:** devolver `False`/`0`/`nil`/vazio. Motivo:
`IsConstructor=False` para um construtor real é **mentira
indistinguível da verdade**. O consumidor não tem como distinguir
"não sei" de "não é". Precedente `GetProperties` fixa o padrão.

## Decisão D-25.5 — cobertura declarada em XMLDoc

XMLDoc de `TModernRTTIType.GetMethods` declara em voz alta: "Delphi
enumera `public` e `published`; FPC enumera apenas `published`. Para a
mesma classe, `Length(GetMethods)` pode diferir entre os compiladores."
XMLDoc dos seis membros sem fonte no FPC documenta o `raise`.

Fixture compartilhada de teste usa **apenas `published`** para que
asserção de contagem exata funcione nos dois. Cenários que exercem
`public` ficam isolados no lado Delphi.

## Decisão D-25.6 — `TModernRTTIParameter` com `Name` + `ParamType` reais

Escolhida opção **(a)** da volta 2 do relatório. Record com
`FOwner: TClass`, `FName: string`, `FTypeToken: Pointer`; expõe `Name`
e `ParamType`. No Delphi, `FromToken` popula ambos com dado real de
`TRttiParameter.Name` e `TRttiParameter.ParamType`. No FPC, `Name` e
`ParamType` levantam `EModernRTTIError` — mesma disciplina de D-25.4.

**Descartadas:**
- Stub com zero membros públicos: `GetParameters` no Delphi devolveria
  N elementos que não respondem nada — inútil nos dois lados.
- `Name` populado no Delphi e string vazia no FPC: repete a
  mentira-indistinguível-da-verdade que D-25.4 rejeitou.
- Empurrar `GetParameters`/`TModernRTTIParameter` para issue própria:
  a issue #25 lista `GetParameters` no escopo, e D-25.4 basta para
  cobrir sem desenho novo.

## Decisão D-25.7 — cirurgia do `Fail` neste ciclo, fecha #35

`UScenarios.RTTI.pas` declara `ETestScenarioFailed = class(Exception);`
no bloco `type` da `interface` (padrão de
`UTestMS.Attributes.Scenarios.pas:31` e
`UTestMS.Callback.Scenarios.pas:42`). A linha 95 troca
`raise Exception.Create(AMsg)` por `raise ETestScenarioFailed.Create(AMsg)`.
Os 12 cenários existentes não mudam.

**Descartado:** adiar para "quando #35 for resolvida". Motivo: sem
isso, `PTestRTTI` devolve `exit 0` sobre vermelho (matriz medida), e a
prova de mutação deste ciclo (M1/M2) não vale nada num CI que lê exit
code. **PR body declara `Closes #35`.**

## Decisão D-25.8 — `Assert` proibido em cenários; testes usam `Fail`

Cenários levantam via `Fail(...)` (que passa a levantar
`ETestScenarioFailed`). Zero `Assert(...)`. Motivo: `SKILL.md:37` não
passa `-Sa`; sem `-Sa`, `Assert` vira no-op silencioso.

## Decisão D-25.9 — assinatura de `Invoke` segue o padrão do Pilar 3

`TModernRTTIMethod.Invoke` usa a mesma superfície de `TSignature<T>` do
`TModernInvoker.Invoke<T>` (Pilar 3). Motivo: coerência com a
superfície existente e não prometer o que o FPC não pode entregar
(`vmtMethodTable` não dá lista de tipos de parâmetro).

**Descartado:** `TArray<TValue>` como assinatura. Seria mentira no FPC
— aceitaria args que não pode empilhar sem metadata de parâmetros.

## Decisão D-25.10 — prova de mutação declarada no PR

O corpo do PR declara duas mutações que os testes devem pegar:

- **M1:** desligar a subida por `ClassParent` em `MethodTokens` →
  `Scenario_GetMethods_CountsPublishedInherited_Exact` **tem de falhar**.
- **M2:** trocar `LTab^.Entry[i]` por `PByte(LTab) + 4 + i * 16` →
  **tem de falhar no i386**. Autor declara a prova; fábrica não roda
  ppc386 (SKILL.md:122-124). Segue SKILL.md:92-97 — "silêncio não é
  sucesso".

## Consequências

- `TModernRTTIField` muda de layout binário privado (R1 do
  [esp](pipeline-esp.md)). Recompilação obrigatória; nenhuma ABI publicada.
- `FromRaw`/`FromRtti` deixam de existir por nome — substituídas por
  `FromToken`. Zero callers externos.
- CI que dependia do exit 0 falso de `PTestRTTI` passa a reportar
  vermelho como vermelho — quebra desejada (Closes #35).
- Consumidor portable dos seis membros sem dado passa a receber
  `EModernRTTIError`. Nenhum consumidor conhecido hoje.
- `.lpi` de `PTestRTTI` não muda; `fpc -Fu"Source"` acha os backends
  novos automaticamente.

## Errata do STUDY

O §F-4 do [study](/strategy/2026-08-27-modernrtti/STUDY.md) concluiu
"offset 4 fixo" em `TVmtMethodTable` a partir de `SizeOf = 20` em
x86_64. **É errado.** O agente registrou a autocrítica na volta 1 da
discussão: `20 = 4 + 16 = 2 + 2 + 16` é coincidência aritmética, não
evidência de layout, e não protegia o i386. A implementação usa
`LTab^.Entry[i]` e ignora o §F-4.
