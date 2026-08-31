---
type: spec
kind: artifact
title: "ESP — TModernRTTIMethod: enumerar published pela vmtMethodTable (issue #25)"
description: "TModernRTTIMethod passa a existir nos dois compiladores com Name/Invoke reais em ambos, e GetMethods/GetMethod alimentados: no FPC pela vmtMethodTable + MethodAddress. Membros sem fonte no FPC levantam EModernRTTIError."
status: draft
cycle: "009"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/af5fcd28da98e98892fbe66e544b6b5c
tags: [modernrtti, rtti, spec, issue-25, fpc, delphi, vmtmethodtable]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-31T00:00:00Z"
sources:
  - id: issue-25
    title: "Issue #25 — TModernRTTIMethod: a API existe no FPC, falta o DADO"
  - id: api-map
    resource: "/strategy/2026-08-27-modernrtti/API-MAP.md"
    title: "ModernRTTI API-MAP (§1, §2, §4, §7)"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — toolchain e receita de build"
---

# ESP — TModernRTTIMethod (issue #25)

## 1. Objetivo

Fazer `TModernRTTIMethod` **existir e compilar** nos dois compiladores com a
mesma superfície pública, e alimentar `TModernRTTIType.GetMethods` /
`GetMethod` com dado real. No FPC, o dado vem da `vmtMethodTable`
(enumeração) e de `TObject.MethodAddress` (lookup por nome, invocação). No
Delphi, é o envolvimento direto de `TRttiMethod`.

`TModernRTTIParameter` entra junto, também nos dois compiladores, para que
`GetParameters` faça sentido no Delphi.

## 2. Escopo

Inclui:

- Novo tipo público `TModernRTTIMethod` com os oito membros da issue:
  `Name`, `Invoke`, `GetParameters`, `ReturnType`, `IsConstructor`,
  `IsClassMethod`, `IsStatic`, `Visibility`.
- Novo tipo público `TModernRTTIParameter` com `Name` e `ParamType`.
- `TModernRTTIType.GetMethods` e `TModernRTTIType.GetMethod(AName)` reais
  nos dois compiladores.
- Adoção da arquitetura §7 do [API-MAP](../../../strategy/2026-08-27-modernrtti/API-MAP.md):
  unit pública sem `{$IFDEF}` na declaração; backends `Delphi` e `FPC`
  expõem a mesma superfície de funções livres; único `{$IFDEF}` mora na
  `uses` da `implementation`.
- Refactoring de `TModernRTTIField` para remover `{$IFDEF}` do
  `strict private` — pré-condição arquitetural desta issue.
- Cirurgia em `UScenarios.RTTI.pas`: declarar `ETestScenarioFailed` e fazer
  o `Fail` existente levantá-la (fecha ModernSyntax#35).
- Fixture com herança e três cenários compartilhados; três published tests
  em cada um dos dois runners (FPC e Delphi).

Fora de escopo:

- Retrofit de qualquer outra unit do `Source/` para o FPC.
- Ampliar `TModernRTTIParameter` para além de `Name`/`ParamType`.
- Enumeradores (`Methods`, `Parameters`) do §3 do API-MAP — ficam para
  issue própria.
- Qualquer alteração em `ModernSyntax.Invoker.pas`.
- `.lpi` de `PTestRTTI` — `fpc -Fu"Source"` acha os backends novos.

## 3. Regras de negócio

- **§7 do API-MAP é lei:** tipo público **jamais** sob `{$IFDEF}` de
  compilador. Estado privado é neutro (`FOwner: TClass; FName: string;
  FToken: Pointer` + em `Parameter` também `FTypeToken: Pointer`). O
  único `{$IFDEF}` da unit pública fica na `uses` da `implementation`.
- **Onde o dado não existe, não retornar valor que também é resposta
  legítima.** No FPC, a `vmtMethodTable` carrega apenas `Name` +
  `CodeAddress` (`typinfo.pp:388-396`); os seis membros sem fonte
  (`IsConstructor`, `IsClassMethod`, `IsStatic`, `Visibility`,
  `ReturnType`, `GetParameters`) levantam `EModernRTTIError` com mensagem
  instrutiva, no precedente de `GetProperties`
  (`Source/ModernSyntax.RTTI.pas:296,:359`). `TModernRTTIParameter.Name`
  e `.ParamType` levantam pelo mesmo motivo no FPC.
- **Cobertura difere de mecanismo:** no Delphi `GetMethods` alcança
  `public` + `published`; no FPC, só `published`. `Length(GetMethods)`
  pode divergir entre compiladores para a mesma classe — é limite honesto,
  não bug, e XMLDoc diz isso em voz alta.
- **Nada de aritmética manual sobre `TVmtMethodTable`:** iteração é pela
  property indexada `LTab^.Entry[i]` (declarada em `typinfo.pp:399-410`),
  que resolve offset e padding por arquitetura. Aritmética literal quebra
  i386 (`SizeOf(TVmtMethodEntry)` = 16 em x86_64, 8 em i386).
- **Lookup por nome não replica laço de herança.** `TObject.MethodAddress`
  sobe a cadeia sozinho (medido); o loop por `ClassParent` fica **só** em
  `MethodTokens` (enumeração).
- **Sem `Assert(...)` em cenários.** A receita de build (`SKILL.md:37`)
  não passa `-Sa`; `Assert` vira no-op silencioso. Cenários levantam
  `ETestScenarioFailed` via `Fail`.
- **CA-5 — zero `{$IFDEF FPC}` no código de teste compartilhado.**

## 4. Critérios de aceitação

- [ ] `TModernRTTIMethod` compila e funciona nos dois compiladores; **zero
      `{$IFDEF}` na declaração pública**.
- [ ] `TModernRTTIParameter` compila e funciona nos dois compiladores;
      **zero `{$IFDEF}` na declaração pública**.
- [ ] No FPC, `TModernRTTIType.GetMethods(AClass)` enumera os métodos
      `published` da `vmtMethodTable`, subindo a cadeia por `ClassParent`.
- [ ] No FPC, `TModernRTTIType.GetMethod(AName)` usa `MethodAddress`
      (sem laço de herança próprio) e devolve um `TModernRTTIMethod`
      cujo `Invoke` funciona.
- [ ] `Invoke` funciona nos dois — no FPC via `MethodAddress`, delegado
      ao mecanismo do `ModernSyntax.Invoker.pas`.
- [ ] Iteração da `vmtMethodTable` usa `LTab^.Entry[i]`. Nenhum literal
      `PByte(LTab) + N` ou `i * SizeOf(TVmtMethodEntry)` no código.
- [ ] Os seis membros sem fonte no FPC (`IsConstructor`, `IsClassMethod`,
      `IsStatic`, `Visibility`, `ReturnType`, `GetParameters`) levantam
      `EModernRTTIError` com mensagem que explica o porquê.
- [ ] `TModernRTTIParameter.Name` e `.ParamType` levantam
      `EModernRTTIError` no FPC.
- [ ] XMLDoc dos oito membros de `TModernRTTIMethod` documenta o
      comportamento em cada compilador; XMLDoc de `GetMethods` declara a
      divergência de cobertura Delphi (`public` + `published`) vs FPC
      (`published`).
- [ ] `UScenarios.RTTI.pas` declara `ETestScenarioFailed = class(Exception);`
      e o `Fail` da linha 95 passa a levantá-la. Os 12 cenários existentes
      não mudam. **PR body declara `Closes ModernSyntax#35`.**
- [ ] Fixture compartilhada em `UScenarios.RTTI.pas` com `{$M+} TMethodBase
      published procedure Alpha; TMethodDerived = class(TMethodBase)
      published procedure Gama; {$M-}`.
- [ ] Três cenários compartilhados novos, todos usando `Fail`:
      `Scenario_GetMethods_CountsPublishedInherited_Exact`,
      `Scenario_GetMethod_ByName_FindsInherited`,
      `Scenario_Method_Invoke_NoArgs`.
- [ ] `Test FPC/EclbrSystem/UTestMS.RTTI.pas` e
      `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` recebem três published
      tests que delegam aos cenários compartilhados.
- [ ] `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` linha 59: comentário
      stale ("TModernRTTIField e GetFields não existem no FPC 3.2.2")
      corrigido.
- [ ] Um teste que use `TModernRTTIMethod` compila **sem nenhum
      `{$IFDEF FPC}` no código do teste** (CA-5).
- [ ] `Test FPC/EclbrSystem/PTestRTTI.lpr` compila e passa nos dois
      bitness (o autor prova i386; a fábrica prova x86_64).
- [ ] Prova de mutação **declarada no corpo do PR** (SKILL.md:92-97):
      - M1: desligar a subida por `ClassParent` em `MethodTokens` faz
        `Scenario_GetMethods_CountsPublishedInherited_Exact` falhar.
      - M2: trocar `LTab^.Entry[i]` por `PByte(LTab) + 4 + i * 16` quebra
        i386 (declarado pelo autor; fábrica não tem `ppc386`).

## 5. Restrições

- **Sem `{$mode}` em `Source/ModernSyntax.RTTI.pas`.** Records com
  `strict private` derretem sob `{$MODE DELPHI}` (defeito do PR #17).
  Backends só declaram funções livres — podem levar
  `{$IFDEF FPC}{$MODE DELPHI}{$H+}` no cabeçalho.
- **Sem alterar `ModernSyntax.Invoker.pas`.** `Invoke` no FPC delega a
  ele; não introduzir mecanismo paralelo.
- **Não retrofitar outras units do `Source/`.** Apenas o que a issue
  reachou pelo `uses` do teste (SKILL.md:57-77).

## 6. Riscos

- **R1 — layout binário de `TModernRTTIField` muda:** remover
  `{$IFDEF FPC}` do `strict private` altera a representação privada.
  Quebra é de recompilação, não silenciosa; nenhum consumidor externo
  publica ABI. Mitigação: nota no corpo do PR.
- **R2 — factories `FromRaw`/`FromRtti` sumindo por nome:** substituídas
  por `FromToken`. Verificado no STUDY: zero callers fora de
  `ModernSyntax.RTTI.pas`.
- **R3 — CI que dependia do exit 0 falso do `PTestRTTI`:** passa a
  reportar exit != 0 sobre vermelho. Quebra é desejada
  (`Closes ModernSyntax#35`).
- **R4 — consumidor portable chamando um dos seis membros sem dado no
  FPC:** passa a receber `EModernRTTIError`. XMLDoc avisa; padrão herdado
  de `GetProperties`. Zero consumidores conhecidos hoje.
- **R5 — mutação M2 (i386) só verificável pelo autor:** fábrica não tem
  `ppc386` (SKILL.md:122-124). Mitigação: declaração no corpo do PR
  seguindo SKILL.md:92-97 ("silêncio não é sucesso").
