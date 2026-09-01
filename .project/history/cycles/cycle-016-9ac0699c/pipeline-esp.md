---
type: spec
kind: artifact
title: "ESP — TModernRTTIEnumerationType: nome, faixa e nomes de constantes nos dois compiladores (issue #43)"
description: "Introducao do record publico TModernRTTIEnumerationType em ModernSyntax.RTTI.pas com FToken: PTypeInfo, fabrica FromTypeInfo e seis metodos (Name, MinValue, MaxValue, GetName, GetValue, GetNames). Backend Delphi delega a TRttiEnumerationType espelhando guards de M-1 (ordinal fora de faixa) e M-2 (nome desconhecido). Backend FPC opera direto sobre PTypeInfo/GetTypeData com guarda por Kind em cada funcao livre e as mesmas guardas de M-1/M-2 antes de delegar a TypInfo.GetEnumName/Value; tres resourcestring novas ficam isoladas no backend FPC. Quatro cenarios compartilhados em UScenarios.RTTI.pas com fixture TCor + TDia; um deles e negativo (raises); um deles quebra sob mutacao MaxValue-1."
status: draft
cycle: "016"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/9ac0699c1b65c18950220f022dfbb179
tags: [modernrtti, rtti, spec, issue-43, fpc, delphi, enumeration, tmodernrttienumerationtype]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-01T00:00:00Z"
sources:
  - id: issue-43
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/43"
    title: "Issue #43 — TModernRTTIEnumerationType"
  - id: issue-29-parent
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/29"
    title: "Issue #29 — parent (tipos de categoria RTTI)"
  - id: adr
    resource: "adr.md"
    title: "ADR — TModernRTTIEnumerationType (issue #43)"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, mutacao, traps"
---

# ESP — TModernRTTIEnumerationType (issue #43)

## 1. Objetivo

Entregar a promessa da API-MAP §3 sobre o tipo de categoria
**Enumeration** na casca de RTTI: um record publico proprio,
`TModernRTTIEnumerationType`, que expoe `Name`, `MinValue`, `MaxValue`,
`GetName`, `GetValue` e `GetNames` de forma **identica na superficie** e
com **paridade de contrato de erros** nos dois compiladores (FPC 3.2.2 e
Delphi). Esta e a segunda entrega do parent #29 (Enumeration), depois de
#42 (Visibility).

## 2. Escopo

### 2.1 `Source/ModernSyntax.RTTI.pas` (casca publica)

- Declarar `TModernRTTIEnumerationType = record` na `interface`, **antes
  de `TModernRTTI` (:561)**, com:
  - `strict private FToken: PTypeInfo;`
  - `class function FromTypeInfo(P: PTypeInfo): TModernRTTIEnumerationType; static;`
    — **sem** validar `Kind` na fabrica (D-4/AC exigem guarda por metodo;
    duplicar aqui contaminaria a unit publica com `resourcestring`).
  - Seis metodos de instancia — `function Name: string;`,
    `function MinValue: Integer;`, `function MaxValue: Integer;`,
    `function GetName(AOrdinal: Integer): string;`,
    `function GetValue(const AName: string): Integer;`,
    `function GetNames: TArray<string>;` — cada corpo delega direto ao
    backend (`EnumName(FToken)`, `EnumMinValue(FToken)`, etc.).
- XMLDoc `///` em cada membro publico: declarar contrato de erros —
  `GetName` levanta `EModernRTTIError` para ordinal fora de faixa;
  `GetValue` levanta para nome desconhecido; os quatro demais nao
  levantam.
- **Zero `{$IFDEF}` novo** nesta unit (D-1).

### 2.2 `Source/ModernSyntax.RTTI.FPC.pas` (backend FPC)

- Novo grupo `// --- Enumeration (issue #43) --------` na interface e na
  implementation, com **seis funcoes livres** de assinatura:
  - `function EnumName(P: PTypeInfo): string;`
  - `function EnumMinValue(P: PTypeInfo): Integer;`
  - `function EnumMaxValue(P: PTypeInfo): Integer;`
  - `function EnumGetName(P: PTypeInfo; AOrdinal: Integer): string;`
  - `function EnumGetValue(P: PTypeInfo; const AName: string): Integer;`
  - `function EnumGetNames(P: PTypeInfo): TArray<string>;`
- **Cada** funcao abre com guarda por `Kind`:
  `if (P = nil) or (P^.Kind <> tkEnumeration) then raise
  EModernRTTIError.CreateFmt(SEnumWrongKind, [...]);`
- `EnumName` — `Result := string(P^.Name);`.
- `EnumMinValue`/`EnumMaxValue` — apos o guard, `Result :=
  GetTypeData(P)^.MinValue`/`.MaxValue`.
- `EnumGetName(P, AOrdinal)` — apos o guard, valida
  `(AOrdinal < GetTypeData(P)^.MinValue) or (AOrdinal >
  GetTypeData(P)^.MaxValue)` e levanta `SEnumOrdinalOutOfRange` **antes**
  de chamar `TypInfo.GetEnumName` (M-1: `GetEnumName(P,-1)` devolve
  `'cA'` silenciosamente).
- `EnumGetValue(P, AName)` — apos o guard, captura o retorno de
  `TypInfo.GetEnumValue`; **se `= -1` levanta** `SEnumNameUnknown`
  (M-2: `-1` colide com "enum poderia ter ordinal negativo").
- `EnumGetNames` — apos o guard, `for i := GetTypeData(P)^.MinValue to
  GetTypeData(P)^.MaxValue do Result[...] := TypInfo.GetEnumName(P, i);`
  (M-3: FPC 3.2.2 recusa `TypeInfo(TCod = (kX=5))`, logo faixa e
  contigua por construcao — mas isso e o *porque* do laco, nao licenca
  para "otimizar").
- **Tres `resourcestring` novas** no bloco existente (`RTTI.FPC.pas:125`):
  - `SEnumWrongKind = 'TModernRTTIEnumerationType: PTypeInfo %s tem Kind %d; esperado tkEnumeration.'`
  - `SEnumOrdinalOutOfRange = 'TModernRTTIEnumerationType(%s).GetName(%d): ordinal fora de [MinValue..MaxValue].'`
  - `SEnumNameUnknown = 'TModernRTTIEnumerationType(%s).GetValue(''%s''): nome desconhecido.'`
  (Redacao final e liberdade editorial do implementador dentro destas
  balizas; o **conteudo** — nome do tipo + valor recebido — e obrigatorio
  para diagnostico.)

### 2.3 `Source/ModernSyntax.RTTI.Delphi.pas` (backend Delphi)

- Novo grupo `// --- Enumeration (issue #43) --------` com as **mesmas
  seis assinaturas** (paridade por compilacao, D-2).
- Delegam a `TRttiEnumerationType(FContext.GetType(P))` no padrao ja
  usado em `FieldEnumerate` (`RTTI.Delphi.pas:113–136`).
- **Espelhar os dois guards de M-1/M-2** antes de delegar ao RTL do
  Delphi, para que o contrato de erros seja identico nos dois backends
  por construcao (D-2). Sem isso, os cenarios negativos ficariam
  FPC-only e a mutacao seria vermelha em um so lado.
- Se algum nome de metodo em `TRttiEnumerationType` do Delphi divergir
  do esperado, resolver com `{$IF Declared(...)}` **dentro deste
  backend** — D-1 (casca publica sem `{$IFDEF}` novo) segue honrado.
- **Sem resourcestring nova no backend Delphi**: reutiliza as tres do
  FPC via unit compartilhada? **NAO** — cada backend tem seu proprio
  bloco `resourcestring` (padrao vigente do repo). O implementador
  duplica as tres constantes no bloco `resourcestring` do Delphi com o
  mesmo texto, para paridade de mensagem.

### 2.4 `Test Shared/EclbrSystem/UScenarios.RTTI.pas` (compartilhado)

- Adicionar `TypInfo` a `uses` da **`interface`** (o `TypeInfo(TCor)`/
  `TypeInfo(TDia)` dos cenarios precisa desse simbolo).
- Declarar no bloco `type` da `interface`, **apos `TColor` (:134)**:
  - `TCor = (cA, cB, cC);`
  - `TDia = (dSeg, dTer, dQua, dQui, dSex, dSab, dDom);`
- Quatro procedures compartilhadas na `implementation` (apos :997, padrao
  vigente: `Fail(...)` sempre, nunca `Assert`, sem `{$IFDEF}` — CA-5):
  1. **`Scenario_EnumerationType_NameAndBounds`** — sobre `TDia`:
     afirma `Name = 'TDia'`, `MinValue = 0`, `MaxValue = 6` (M-4
     autoriza valores absolutos: `MinValue`/`MaxValue` sao iguais nos
     dois bitness).
  2. **`Scenario_EnumerationType_GetNameGetValue`** — sobre `TDia`:
     roundtrip por **presenca** de todos os 7 nomes (`for i in
     0..MaxValue do assert nome existe e GetValue(nome) = i`), padrao
     D-6: assertivas por relacao, nao por posicao fragil.
  3. **`Scenario_EnumerationType_GetNames_LengthAndPresence`** — sobre
     `TDia`: `Length(GetNames) = 7` e cada um dos 7 nomes esperados
     esta presente no array. **Este cenario deve ficar vermelho sob a
     mutacao `MaxValue -> MaxValue - 1` em `EnumGetNames`** (M-4). Nao
     usar `TCor` (3 elementos) porque um off-by-one no fim passaria
     verde.
  4. **`Scenario_EnumerationType_OutOfRangeAndUnknownRaises`** — sobre
     `TDia`: **tres afirmacoes independentes** (cada uma em seu proprio
     `try/except on EModernRTTIError do end; Fail(...)`):
     `GetName(-1)` levanta; `GetName(MaxValue+1)` levanta;
     `GetValue('naoExiste')` levanta. Cobre M-1 e M-2 juntos.

### 2.5 `Test FPC/EclbrSystem/UTestMS.RTTI.pas` (casca FPC, FPCUnit)

- Quatro metodos `published` em `TTestModernRTTI`, cada um chamando o
  cenario correspondente (padrao vigente `UTestMS.RTTI.pas:88–95`):
  - `TestEnumerationType_NameAndBounds`
  - `TestEnumerationType_GetNameGetValue`
  - `TestEnumerationType_GetNames_LengthAndPresence`
  - `TestEnumerationType_OutOfRangeAndUnknownRaises`

### 2.6 `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` (casca Delphi, DUnitX)

- Quatro metodos `[Test]` em `TTestModernRTTI`, mesmo padrao das linhas
  128–131 (nomes identicos aos do FPC, sem sufixo por compilador).

## 3. Out of scope

- Cobrir enum com valores explicitos (`TCod = (kX=5, kY=6)`) num cenario
  — impossivel no FPC 3.2.2 (M-3: `TypeInfo(TCod)` nao compila).
- Trocar `FToken` por qualquer outro handle (`TRttiType`,
  `TRttiEnumerationType`) — AC explicito da issue: `FToken: PTypeInfo`.
- Ampliar API-MAP §3 no mesmo PR — decisao editorial deixada ao proximo
  ciclo (herdado do #42).
- Atacar as demais categorias (Pointer, Record, Array, Set) — cada uma
  tem sua propria sub-issue (#44–#46).
- Atacar Trap #1 do SKILL (compilacao da arvore inteira em FPC).

## 4. Regras de negocio (contratos publicos)

- **R1.** `TModernRTTIEnumerationType.FromTypeInfo(P)` **nao valida
  `Kind`**; validar ali obrigaria `resourcestring` na unit publica,
  violando D-1. Guarda por metodo (D-4) e obrigatoria e suficiente.
- **R2.** `Name`, `MinValue`, `MaxValue`, `GetNames` nao levantam nada
  quando o `Kind` esta correto. Em `Kind` errado, levantam
  `EModernRTTIError` com `SEnumWrongKind`.
- **R3.** `GetName(AOrdinal)` levanta `EModernRTTIError` com
  `SEnumOrdinalOutOfRange` para `AOrdinal < MinValue` ou
  `AOrdinal > MaxValue`. Motivo: M-1 — nao devolver valor que tambem e
  resposta legitima (D-26).
- **R4.** `GetValue(AName)` levanta `EModernRTTIError` com
  `SEnumNameUnknown` quando o nome nao existe. Motivo: M-2 — `-1` colide
  com "enum poderia ter ordinal negativo"; `raise` torna a garantia
  local, nao dependente de M-3.
- **R5.** Contrato de erros e **identico nos dois compiladores** por
  construcao (D-2). O backend Delphi espelha os guards antes de delegar
  a `TRttiEnumerationType`.
- **R6.** Mapeamento e feito por delegacao direta ao RTL de cada
  compilador (`TypInfo` no FPC, `TRttiEnumerationType` no Delphi). Nao
  ha `case` sobre valores do enum na camada — o record e polimorfico
  sobre `PTypeInfo`.

## 5. Criterios de aceitacao

- [ ] **CA-1.** `TModernRTTIEnumerationType` declarado com
  `strict private FToken: PTypeInfo;` (nao `FType: TRttiType`, AC
  explicito da issue), antes de `TModernRTTI` na `interface`.
- [ ] **CA-2.** `class function FromTypeInfo(P: PTypeInfo): TModernRTTIEnumerationType; static;`
  publico, **sem** validar `Kind` na fabrica.
- [ ] **CA-3.** Backend FPC: cada uma das seis funcoes livres abre com
  guarda por `Kind`.
- [ ] **CA-4.** Backend FPC: `EnumGetName` valida `[MinValue..MaxValue]`
  antes de delegar; `EnumGetValue` captura retorno de `GetEnumValue` e
  levanta em `-1`. Tres `resourcestring` novas isoladas em `RTTI.FPC.pas`
  (nao na unit publica).
- [ ] **CA-5.** Backend Delphi: seis funcoes com **paridade de
  assinatura** e **paridade de guards** (M-1 e M-2) antes de delegar a
  `TRttiEnumerationType`. Se necessario, `{$IF Declared(...)}` local
  dentro deste backend.
- [ ] **CA-6.** Zero `{$IFDEF}` novo em `Source/ModernSyntax.RTTI.pas`.
- [ ] **CA-7.** Cenario `Scenario_EnumerationType_NameAndBounds` verde
  em `TDia`: `Name='TDia'`, `MinValue=0`, `MaxValue=6`.
- [ ] **CA-8.** Cenario `Scenario_EnumerationType_GetNameGetValue` verde
  em `TDia`: roundtrip por presenca dos 7 nomes.
- [ ] **CA-9.** Cenario `Scenario_EnumerationType_GetNames_LengthAndPresence`
  verde em `TDia`: `Length(GetNames)=7` e presenca dos 7 nomes.
- [ ] **CA-10.** Cenario `Scenario_EnumerationType_OutOfRangeAndUnknownRaises`
  verde: as tres afirmacoes independentes (GetName(-1),
  GetName(MaxValue+1), GetValue('naoExiste')) levantam
  `EModernRTTIError`.
- [ ] **CA-11.** **AC da issue reescrito nos termos da ampliacao:** o
  original `GetName(1)='cB'`, `GetValue('cC')=2`, `MaxValue-MinValue+1 =
  Length(GetNames)` sobre `TCor` fica **coberto por CA-8/CA-9** com
  `TDia`. `TCor` continua na fixture (declarada) e disponivel para
  qualquer cenario futuro; nao ha cenario que o exercite hoje. Motivo:
  `TCor` (3 elementos) nao mata a mutacao `MaxValue-1` (M-4).
- [ ] **CA-12.** Mutacao de sanidade obrigatoria documentada no PR:
  trocar `MaxValue` por `MaxValue - 1` no laco de `EnumGetNames` (FPC
  ou Delphi) → `Scenario_EnumerationType_GetNames_LengthAndPresence`
  fica vermelho. Reverter, reprovar verde.
- [ ] **CA-13.** Compila FPC 3.2.2 nos dois bitness (x86_64 e i386) sem
  erro; suites verdes. Delphi: compilado apenas pelo autor (nao pelo
  container Aefos) — o PR declara explicitamente o que foi compilado
  (SKILL §"What a PR must declare").
- [ ] **CA-14.** XMLDoc `///` em cada membro publico novo, declarando
  contrato de erros (quais levantam, com qual `EModernRTTIError`).

## 6. Convencoes que governam

- **D-1 / D-25.1** — casca publica sem `{$IFDEF}` novo em tipo publico
  (`Source/ModernSyntax.RTTI.pas:18–23`). Governa a declaracao
  incondicional de `TModernRTTIEnumerationType` e a proibicao de
  `{$IFDEF}` na unit publica.
- **D-2** — paridade de assinatura nos dois backends
  (`Source/ModernSyntax.RTTI.pas:22–23`). Governa os guards espelhados
  no backend Delphi.
- **D-4** — guarda explicita por `Kind` no FPC, cada funcao
  (`Source/ModernSyntax.RTTI.FPC.pas:355–411`, padrao vigente). Governa
  o abre-com-guarda em cada uma das seis funcoes.
- **D-6** — assertivas por relacao, nao por posicao fragil
  (`Test Shared/EclbrSystem/UScenarios.RTTI.pas:411–429`, padrao busca
  por nome). Governa `GetNameGetValue` e `GetNames_LengthAndPresence`.
- **D-26** — nao devolver valor que tambem e resposta legitima. Governa
  M-1 (guarda de faixa em `GetName`) e M-2 (raise em `GetValue`).
- **CA-5 (padrao do repo)** — zero `{$IFDEF}` em `UScenarios.RTTI.pas`
  (`Test Shared/EclbrSystem/UScenarios.RTTI.pas:16`). Governa os quatro
  cenarios: `try/except + Fail(...)`, sem diretiva por compilador.
- **Nomenclatura** — [conventions](../../../analysis/05-conventions.md) §1.3:
  prefixo `T` no tipo, `A` em parametros, `L` em locais; XMLDoc `///`
  em membros publicos novos (§4.3).

## 7. Riscos

- **R-1.** Consumidor externo que hoje escreva `TRttiEnumerationType(...)`
  a mao nao ganha o guard novo. Nao ha caller no repo
  (`grep -rn "TModernRTTIEnumerationType"` → 0), logo nao ha risco de
  regressao interna. Fora do repo e obrigacao de changelog no proximo
  release.
- **R-2.** Divergencia futura entre RTL do FPC e do Delphi em enums
  descontinuos (M-3): se um dia o FPC passar a emitir RTTI para
  `TCod = (kX=5, kY=6)`, o laco `MinValue..MaxValue` de `EnumGetNames`
  reintroduz o risco de indices fantasma. **Mitigacao:** o ADR desta
  issue registra M-3 como *o motivo* do laco; o proximo agente que ler
  vera o alarme.
- **R-3.** Cenario que passa por caminho errado (fixture sem `TDia`
  com 7 elementos, ou assertiva por posicao). **Mitigacao:** CA-12
  (mutacao de sanidade obrigatoria) obriga o cenario a pagar por si.
- **R-4.** Nome de metodo em `TRttiEnumerationType` do Delphi divergir
  do esperado (versao antiga do Delphi). **Mitigacao:** resolucao
  dentro do backend Delphi com `{$IF Declared(...)}`; D-1 segue
  honrado.

## 8. Restricoes

- Nenhuma diretiva de compilador nova em `Source/ModernSyntax.RTTI.pas`
  (D-1, AC explicito da issue).
- Zero `{$IFDEF FPC}`/`{$IFDEF DELPHI}` em `UScenarios.RTTI.pas` (CA-5
  do repo).
- PR unico fechando `#43` inteiro.
- Toolchain FPC 3.2.2 nos dois bitness, com `rm -rf` do output antes de
  cada build (Trap #2 do SKILL).
- `TypInfo` **ja** esta na `uses` da `implementation` de
  `UScenarios.RTTI.pas`? Verificar — se sim, mover para `interface`
  nao e permitido sem justificativa; se nao, adicionar a `interface` e
  concluido.
