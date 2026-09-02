---
type: adr
kind: decision
title: "ADR — TModernRTTIPointerType: dois cenarios (Matches + Nil_ForBarePointer), convergencia sem is/try/except, mutacao com cast, fixture PInt44, piso Delphi 23.0 (issue #44)"
description: "Restatement das decisoes acordadas no relatorio de investigacao da issue #44 (run 7f780007e3179b6ac2dd4b2565795789, volta 1): TModernRTTIPointerType com FToken PTypeInfo e FromTypeInfo sem guarda de Kind na fabrica; backend FPC com property RefType (nao RefTypeRef) e resourcestring SPointerWrongKind isolado; backend Delphi com paridade de assinatura, sem is TRttiPointerType e sem try/except extra; dois cenarios em UScenarios.RTTI.pas (fixture PInt44 renomeada de PInteger para eliminar colisao de RTL; cenario 2 obrigatorio com TypeInfo(Pointer) puro afirmando apenas IsNil = True); comentario MUTACAO OBRIGATORIA prescrevendo PTypeInfo(GetTypeData(P)^.RefTypeRef) com cast (a forma literal da issue nao compila); asserção de Name via TModernRTTI.GetType(TypeInfo(Integer)).Name para absorver a divergencia Delphi/FPC; piso Delphi 23.0 sem {$IF CompilerVersion}."
status: stable
cycle: "017"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/9af8cdc2e2a54fb129b523e483beaa2d
tags: [modernrtti, adr, issue-44, fpc, delphi, pointer, d1, d2, d4, d25.1, ca5]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-01T00:00:00Z"
sources:
  - id: issue-44-report
    title: "REPORT — Issue #44 (run 7f780007e3179b6ac2dd4b2565795789) — PRESENT"
  - id: adr-043
    resource: "/history/cycles/cycle-016-9ac0699c/pipeline-adr.md"
    title: "ADR #43 — TModernRTTIEnumerationType (padrao consagrado)"
  - id: adr-042
    resource: "/history/cycles/cycle-015-bb89abe1/pipeline-adr.md"
    title: "ADR #42 — D-1 (casca publica sem {$IFDEF}), D-2 (paridade de assinatura)"
  - id: adr-025
    resource: "/history/cycles/cycle-010-a36e1364/pipeline-adr.md"
    title: "ADR #25 — D-4 (guarda por Kind no FPC)"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, mutacao, traps"
---

# ADR — issue #44 (TModernRTTIPointerType)

Este documento **deriva do relatorio de investigacao** que fechou a
discussao da issue #44 (uma volta, run
`7f780007e3179b6ac2dd4b2565795789`), reproduzido verbatim no prompt do
ciclo. Registra a decisao **em vigor**, nos termos que a conversa
acertou. **Nao ha divergencia de merito** entre este ADR e o relatorio;
todos os deltas da volta 1 (correcoes 1-6) estao absorvidos.

## Contexto medido (do relatorio, verbatim)

Duas famılias de medicoes convergem para o mesmo desenho, uma no
Delphi (nos 4 alvos: 23.0/37.0 × Win32/Win64) e uma no FPC 3.2.2 (nos
dois bitness, x86_64 e i386):

- **FPC 3.2.2, cinco tipos-alvo:**
  ```
  ^Integer  -> RefType->Name = 'LongInt'   (Kind = tkPointer)
  ^string   -> RefType->Name = 'AnsiString'
  ^TRec     -> RefType->Name = 'TRec'
  PChar     -> RefType->Name = 'Char'
  Pointer   -> RefType         = NIL       (Kind = tkPointer, PASSA na guarda)
  ```
  Ou seja: a familia `tkPointer` inclui `Pointer` puro, cuja
  `RefType` cai a `nil` sem AV — o caminho normal ja produz o
  observavel correto (`IsNil = True`).
- **Delphi (4 alvos):**
  ```
  TypeInfo(Pointer):
    LCtx.GetType(...) = TRttiPointerType  (nunca nil)
    .ReferredType     = nil               (nunca levanta)
  ```
  Convergencia por construcao: mesmo padrao (nil no `Referred`), sem
  precisar de `is TRttiPointerType`, sem `try/except` extra.

- **Nome do referido diverge:** Delphi diz `Integer`, FPC diz
  `LongInt`. A asserção via `TModernRTTI.GetType(TypeInfo(Integer)).Name`
  absorve a divergencia pela propria RTL.

- **Mutacao literal da issue (`RefTypeRef` sem cast) NAO compila:**
  `Error: Incompatible type for arg no. 1: Got "PPTypeInfo"`. Erro de
  compile e bug de instrucao, nao "cenario vermelho" — nao satisfaz a
  acceptance. A forma que satisfaz e `PTypeInfo(GetTypeData(P)^.RefTypeRef)`,
  que compila, roda, le a regiao errada (delta 24 bytes em x86_64) e
  vermelha por semantica.

- **Fixture `PInteger` colide com `System.PInteger`/`SysUtils.PInteger`
  (Delphi) e com a RTL do FPC.** Rename para `PInt44` elimina a
  ambiguidade e carrega a origem.

- **Piso Delphi 23.0 provado por compilacao** nos 4 alvos —
  `TRttiPointerType` esta garantido desde XE2. Sem `{$IF CompilerVersion}`
  no backend Delphi.

## Decisoes (D-44.x)

### D-44.1 — `TModernRTTIPointerType` com `FToken: PTypeInfo` e `FromTypeInfo` sem guarda de `Kind`

**Contexto.** A unit publica `ModernSyntax.RTTI.pas` ja hospeda dois
records da mesma familia (`TModernRTTIEnumerationType` da issue #43;
`TModernRTTIType` do modulo inteiro), todos com `strict private FToken`
e uma factory que apenas atribui.

**Decisao.** `TModernRTTIPointerType` segue **exatamente** o padrao
consagrado do `TModernRTTIEnumerationType`: `strict private FToken: PTypeInfo`,
`class function FromTypeInfo(P: PTypeInfo): TModernRTTIPointerType; static`
que faz `Result.FToken := P` sem validar `Kind`.

**Alternativas descartadas.**

- Validar `Kind` na fabrica. Rejeitada: fabrica passa a lancar excecao
  antes que o consumidor chame o metodo — quebra o padrao consagrado
  e viola D-1 (a fabrica na unit publica precisaria de `resourcestring`,
  o que a unit publica proibe).
- Passar `PTypeInfo` diretamente sem record wrapper. Rejeitada: o
  wrapper existe para expor XMLDoc de contrato e para reservar espaco
  para membros futuros da familia — quebrar aqui quebraria toda a
  linhagem.

### D-44.2 — Backend FPC usa **property `RefType`** (nao `RefTypeRef`)

**Contexto.** `typinfo.pp:563` declara `property RefType: PTypeInfo read GetRefType`;
`typinfo.pp:3306` mostra `GetRefType := DerefTypeInfoPtr(RefTypeRef)`.
A variavel bruta `RefTypeRef` e `PPTypeInfo` — um nivel de indirecao
acima. Ler `RefTypeRef` como `PTypeInfo` (com ou sem cast) le a regiao
errada (delta 24 bytes em x86_64 medido no estudo §A-3).

**Decisao.** O corpo do backend FPC e:
`Result := TModernRTTIType.FromRtti(LCtx.GetType(GetTypeData(P)^.RefType));`.
**Sempre a property**; a mutacao obrigatoria ataca este ponto.

**Alternativas descartadas.**

- Usar `RefTypeRef` sem cast. Rejeitada: erro de compile (`PPTypeInfo`
  vs `PTypeInfo`) — a "mutacao literal" da issue nem passa pelo
  compilador; nao serve como evidencia.
- Usar `RefTypeRef` com cast como forma canonica. Rejeitada: le lixo
  em runtime — o proposito da property e justamente derreferenciar
  uma vez a mais.

### D-44.3 — Comentario `// MUTACAO OBRIGATORIA` prescreve a forma **com cast**

**Contexto.** O acceptance da issue exige "cenario vermelho ou AV". A
forma literal da issue (`RefTypeRef` sem cast) e erro de compile — nao
satisfaz. Sem prescricao explicita, o proximo mantenedor tenta a forma
literal, leva erro de compile, e conclui erroneamente que "a guarda
funcionou".

**Decisao.** O comentario no backend FPC prescreve a mutacao **com
cast explicito**:
```
// MUTACAO OBRIGATORIA: trocar `RefType` por
//   PTypeInfo(GetTypeData(P)^.RefTypeRef)
// deixa Scenario_PointerType_ReferredType_Matches vermelho.
```
Assim compila, roda, le regiao errada, e o cenario 1 vermelha por
semantica — o criterio que a issue pede.

**Alternativas descartadas.**

- Colar a forma literal (sem cast) no comentario. Rejeitada: erro de
  compile nao e bug de guarda; a acceptance quer "vermelho ou AV",
  nao "quebra compile".
- Nao colocar comentario (deixar o proximo mantenedor descobrir).
  Rejeitada: o proprio nome da issue promove a mutacao a "obrigatoria" —
  sem receita, ela vira lore oral.

### D-44.4 — Backend Delphi **sem** `is TRttiPointerType`, **sem** `try/except` extra

**Contexto.** Medicao do interlocutor nos 4 alvos Delphi:
`LCtx.GetType(TypeInfo(Pointer))` sempre devolve `TRttiPointerType`,
nunca `nil`, nunca levanta. `TRttiPointerType(...).ReferredType` para
`Pointer` puro retorna `nil` sem AV.

**Decisao.** Corpo minimo:
```pascal
LCtx := TRttiContext.Create;
try
  Result := TModernRTTIType.FromRtti(TRttiPointerType(LCtx.GetType(P)).ReferredType);
finally
  LCtx.Free;
end;
```
Sem `is` (o cast e seguro por construcao), sem `try/except` (nada a
capturar). A convergencia `IsNil = True` cai sozinha no cenario 2.

**Alternativas descartadas.**

- `is TRttiPointerType` como cinto de seguranca. Rejeitada: cinto que
  nunca aperta e ceremonia. Medicao prova.
- `try/except EInvalidCast` extra. Rejeitada: mesma razao.

### D-44.5 — **Dois** cenarios: `Matches` e `Nil_ForBarePointer`

**Contexto.** A issue prescreve um cenario (`Matches` com fixture
`^Integer`). Um so cenario nao testa a **familia `tkPointer`**: valida
so a fixture. `TypeInfo(Pointer)` passa a guarda `Kind = tkPointer` e
leva ao caminho normal — se o backend nao tratasse esse caso, o
cenario 1 verde nao acusaria. O padrao da issue #29 (a regra que pegou
o AV do `ElType`) exige o segundo cenario.

**Decisao.** Dois cenarios em `UScenarios.RTTI.pas`:

- `Scenario_PointerType_ReferredType_Matches` — `TypeInfo(PInt44)`,
  afirma `IsNil = False` e `Name = TModernRTTI.GetType(TypeInfo(Integer)).Name`.
- `Scenario_PointerType_ReferredType_Nil_ForBarePointer` —
  `TypeInfo(Pointer)`, afirma **apenas** `IsNil = True`.

Cada casca (FPC e Delphi) publica **duas** procedures, uma por cenario,
corpo de uma linha delegando.

**Alternativas descartadas.**

- Cenario unico (so `Matches`). Rejeitada: valida fixture, nao familia.
- Fundir os dois num cenario so com duas asserçoes. Rejeitada: perde
  o padrao "um cenario, um observavel"; o relatorio ordena separacao.

### D-44.6 — Cenario 2 **nunca** toca `.Name` sobre handle nil

**Contexto.** `Source/ModernSyntax.RTTI.pas:846` faz `FType.Name` sem
guarda; sobre handle nil ha AV. A issue #49 registra este bug e o
mantem fora deste ciclo.

**Decisao.** `Scenario_PointerType_ReferredType_Nil_ForBarePointer`
afirma **exclusivamente** `LReferred.IsNil = True`. Nao chama `.Name`,
`.Handle`, nem qualquer membro que force materializacao de `FType.Name`.

**Alternativa descartada.**

- Adicionar `LReferred.Name = ''` como sanidade extra. Rejeitada: AV
  imediata; o teste que deveria proteger vira o teste que quebra.

### D-44.7 — Asserção de `Name` cross-compiler via `TModernRTTI.GetType(TypeInfo(Integer)).Name`

**Contexto.** Delphi diz `Integer`, FPC diz `LongInt` (medicao). Literal
`'Integer'` quebra no FPC; literal `'LongInt'` quebra no Delphi. A
propria RTL absorve a divergencia se o teste comparar contra o
`Name` do proprio `Integer` visto pelo compilador atual.

**Decisao.** Cenario 1 afirma:
`LReferred.Name = TModernRTTI.GetType(TypeInfo(Integer)).Name`.

**Alternativas descartadas.**

- Literal `'Integer'`. Rejeitada: quebra no FPC.
- `Name <> ''` (asserção fraca). Rejeitada: passa verde sobre qualquer
  tipo, nao valida "o referido de `^Integer` e Integer".
- `{$IFDEF FPC}` no teste para bifurcar o literal. Rejeitada: CA-5
  proibe `{$IFDEF}` em teste; a indirecao pela RTL e a resposta
  arquitetural correta.

### D-44.8 — Fixture renomeada `PInteger` → `PInt44`

**Contexto.** `System.PInteger` e `SysUtils.PInteger` no Delphi; a
RTL do FPC tambem exporta `PInteger`. Resolucao por pilha de `uses`
gera cenario fragil: o teste pode acabar apontando para o `PInteger`
errado.

**Decisao.** Fixture publica em `UScenarios.RTTI.pas`:
`PInt44 = ^Integer;`. O sufixo `44` carrega a origem (issue #44) e
elimina qualquer possibilidade de colisao.

**Alternativa descartada.**

- Manter `PInteger` e resolver por ordem de `uses`. Rejeitada:
  fragilidade sem beneficio; o rename custa zero.

### D-44.9 — Piso Delphi 23.0 sem `{$IF CompilerVersion}`

**Contexto.** Compilacao provada pelo interlocutor nos 4 alvos
(23.0/37.0 × Win32/Win64). `TRttiPointerType` esta garantido desde
XE2 (que ja e 23.0). Guarda de versao seria supersticiao.

**Decisao.** Backend Delphi **nao** carrega `{$IF CompilerVersion >= ...}`.
Se um mantenedor futuro precisar suportar Delphi anterior a 23.0, esta
sera uma issue nova.

**Alternativa descartada.**

- `{$IF CompilerVersion >= 23}` "por caridade" com pre-XE2. Rejeitada:
  piso medido; XE2+ e herança nao requisito.

## Convencoes que governam esta feature (referencia)

- **D-1** — `resourcestring` de guarda vive nos backends, nunca na
  unit publica. `SPointerWrongKind` fica em
  `ModernSyntax.RTTI.FPC.pas:200` e `ModernSyntax.RTTI.Delphi.pas:119`.
  Declarado por [/analysis/05-conventions.md](/analysis/05-conventions.md).
- **D-2** — paridade de assinatura entre backends.
- **D-4** — funcao livre sobre `PTypeInfo` abre com
  `if (P = nil) or (P^.Kind <> tkPointer)`.
- **D-25.1** — unit publica sem `{$IFDEF}` em declaracao de tipo (:19).
- **CA-5** — zero `{$IFDEF FPC}` em arquivo de teste.
- **Padrao "um cenario, duas cascas"** — corpo unico em
  `UScenarios.RTTI.pas`; casca de uma linha em cada projeto.
- **Regra de teste "cenario vermelho, nao erro de compile"** — mutacao
  compila e roda; cast explicito quando a forma literal quebra o
  compilador.

## Descartadas explicitas (do relatorio, sem parafrase)

- **Cenario unico (`PInt44`).** Sem cenario 2, `TypeInfo(Pointer)`
  passa a guarda verde e valida so a fixture.
- **Guarda `is TRttiPointerType` no backend Delphi.** Medida nos 4
  alvos: sempre `TRttiPointerType`, nunca nil, nunca levanta.
- **`try/except` extra no backend FPC.** `IsNil = True` cai sem
  excecao.
- **Asserção literal `'Integer'`/`'LongInt'`.** Divergencia por
  compilador absorvida por indireção.
- **Mutacao literal da issue (`RefTypeRef` sem cast).** Erro de compile.
- **Fixture `PInteger`.** Colisao com RTL.
- **`{$IF CompilerVersion}` no backend Delphi.** Piso 23.0 medido.
- **Q5 do plano original (teste de guarda por kind).** Aditivo; fora
  deste ciclo.
- **Harness de mutacao automatica.** Overengineering para um caso.

## O que este ADR nao decide (para nao invadir esp/plan/task-input)

- Ordem de execucao (isso e do [plan](pipeline-plan.md)).
- Numero de linhas por arquivo (isso e do [task-input](pipeline-task-input.md)).
- Escopo em criterio de aceitacao formatado (isso e do [esp](pipeline-esp.md)).

## Fontes

- Relatorio de investigacao (run `7f780007e3179b6ac2dd4b2565795789`),
  reproduzido verbatim no prompt do ciclo.
- ADR #43 (cycle-016) — padrao consagrado que este ADR replica com
  as adaptacoes especificas de `tkPointer`.
- ADR #42 (cycle-015) — D-1 e D-2, base normativa desta feature.
- ADR #25 (cycle-010) — D-4, guarda por `Kind` no FPC.
