---
type: spec
kind: artifact
title: "ESP — Contrato unico de handle nil em TModernRTTIType (Name, GetProperties, GetFields, GetMethods, GetMethod) — issue #49"
description: "Cinco membros de TModernRTTIType passam a levantar EModernRTTIError com resourcestring nomeada quando FType = nil (IsNil = True), em vez de tres AVs e um vazio silencioso; XMLDoc em cada declaracao; cenario compartilhado pelo caminho publico; desbloqueio da divida D-44.6."
status: draft
cycle: "020"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/fd87755097391831d283adc83e6b8813
tags: [modernrtti, rtti, spec, issue-49, bug, nil-handle, emodernrttierror, fpc, delphi]
generated:
  by: "equipe-bug@node:architect"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: issue-49
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/49"
    title: "Issue #49 — TModernRTTIType sobre handle nil"
  - id: investigation
    title: "REPORT — Issue #49 (run 14c0a137db091a773582148509b38bea) — PRESENT"
  - id: adr
    resource: "adr.md"
    title: "ADR — issue #49"
  - id: plan
    resource: "plan.md"
    title: "PLAN — issue #49"
  - id: task-input
    resource: "task-input.md"
    title: "TASK-INPUT — issue #49"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, traps"
  - id: conventions
    resource: "/analysis/05-conventions.md"
    title: "05 Conventions — ModernSyntax"
---

# ESP — issue #49 (contrato de handle nil em `TModernRTTIType`)

## 1. Objetivo

Estabelecer um **contrato unico e explicito** para os cinco membros de
`TModernRTTIType` que hoje se comportam de formas diferentes sobre um
handle com `IsNil = True`:

| Membro | Comportamento atual | Comportamento exigido |
|--------|--------------------|-----------------------|
| `Name` | `EAccessViolation` | `EModernRTTIError` |
| `GetProperties` | `EAccessViolation` | `EModernRTTIError` |
| `GetMethods` | `EAccessViolation` | `EModernRTTIError` |
| `GetMethod` (singular) | `EAccessViolation` | `EModernRTTIError` |
| `GetFields` | vazio silencioso | `EModernRTTIError` |

A excecao e levantada via
`EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['<membro>'])`, onde
`SModernRTTINilHandle` e uma nova `resourcestring` com `%s` para o nome
do membro chamado. XMLDoc em cada declaracao documenta o contrato. Um
cenario compartilhado constroi o handle pelo caminho publico e afirma o
comportamento nos cinco membros.

## 2. Escopo

### 2.1 `Source/ModernSyntax.RTTI.pas`

**Nova `resourcestring`** no bloco existente em torno de `:860-873`
(onde vivem `SModernRTTIMissingProps` e `SModernRTTIGetMethodsNotClass`):

```pascal
SModernRTTINilHandle =
  'handle nao inicializado (IsNil = True). Verifique IsNil antes de chamar %s.';
```

**Guardas** — inseridas como **primeira instrucao** de cada membro
(antes de qualquer acesso a `FType`):

```pascal
if FType = nil then
  raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['<nome>']);
```

| Membro | Linha de referencia | Parametro `%s` |
|--------|---------------------|----------------|
| `TModernRTTIType.Name` | `:1022` | `'Name'` |
| `TModernRTTIType.GetProperties` | `:1033` | `'GetProperties'` |
| `TModernRTTIType.GetFields` | `:1053` — **antes** do `is` check | `'GetFields'` |
| `TModernRTTITypeHelper.GetMethods` | `:1067` | `'GetMethods'` |
| `TModernRTTITypeHelper.GetMethod` | `:1074` | `'GetMethod'` |

**Nota critica para `GetFields` (B-49.3):** a guarda precede o
`is TRttiInstanceType` check. O caminho `FType <> nil` mas
nao-`TRttiInstanceType` (records, enums) **continua retornando `nil`
silenciosamente** — comportamento correto para tipos genuinamente sem
campos de instancia RTTI, preservado intacto.

**XMLDoc `<remarks>`** adicionado (ou somado ao existente) em cinco
declaracoes da `interface`:

| Declaracao | Linha de referencia |
|------------|---------------------|
| `Name` | `:176` |
| `GetProperties` | `:193` |
| `GetFields` | `:205` |
| `GetMethods` | `:373` |
| `GetMethod` | `:380` |

Texto do `<remarks>` novo em cada um:

```
/// <remarks>
/// Quando <c>IsNil = True</c>, levanta <c>EModernRTTIError</c>;
/// verifique <c>IsNil</c> antes de chamar.
/// </remarks>
```

Em `GetMethod` (`:380`), o `<remarks>` novo **soma** ao bloco existente
sobre `MethodAddress`/D-25.3; nao substitui.

### 2.2 `Test Shared/EclbrSystem/UScenarios.RTTI.pas`

**Novo cenario** declarado na `interface` perto de `:305-311` (apos os
cenarios das issues #44/#45):

```pascal
procedure Scenario_NilHandle_AllMembers_Raises;
```

Corpo na `implementation`: constroi o handle pelo caminho publico,

```pascal
var
  LCtx: TModernRTTIContext;
  LType: TModernRTTIType;
begin
  LCtx := TModernRTTIContext.Create;
  LType := LCtx.FindType('TipoQueNaoExiste_Issue49');
  { LType.IsNil = True — pelo caminho publico documentado }
```

e afirma `EModernRTTIError` nos **cinco** membros. Cada bloco
`try/except` verifica que a mensagem contem o nome do membro chamado:

```pascal
  try
    LType.Name;
    raise ETestScenarioFailed.Create('Name nao levantou sobre handle nil.');
  except
    on E: EModernRTTIError do
      if Pos('Name', E.Message) = 0 then
        raise ETestScenarioFailed.Create('Mensagem de Name nao cita o membro.');
  end;
  { idem para GetProperties, GetFields, GetMethods, GetMethod }
end;
```

Padrao de construcao identico a `Scenario_Context_FindType_NotFound_ReturnsNil`
(`:949-961`); padrao `_Raises` identico aos existentes (`:327`, `:304`,
`:284`, `:293`).

**Desbloqueio da divida D-44.6 / R-4** em
`Scenario_PointerType_ReferredType_Nil_ForBarePointer` (`:1254-1269`):
remover o comentario "NAO tocar em `LReferred.Name`" e adicionar:

```pascal
try
  LReferred.Name;
  raise ETestScenarioFailed.Create('Name sobre Pointer nil nao levantou.');
except
  on EModernRTTIError do { pass };
end;
```

**Reescrita dos comentarios `D-44.6 / R-4`** em `:310-311` e
`:1259-1265`: citar #49 como *resolvido*, nao como bloqueio. O Drift 2
(numero de linha `:846` obsoleto nos comentarios) some junto sem esforco
extra.

### 2.3 `Test FPC/EclbrSystem/UTestMS.RTTI.pas`

Um `published TestNilHandle_AllMembers_Raises` de uma linha, inserido
apos o padrao de `TestPointerType_ReferredType_Nil_ForBarePointer`
(`:329-331`):

```pascal
procedure TestTModernRTTI.TestNilHandle_AllMembers_Raises;
begin
  Scenario_NilHandle_AllMembers_Raises;
end;
```

### 2.4 `Test Delphi/EclbrSystem/UTestMS.RTTI.pas`

Um `[Test] TestNilHandle_AllMembers_Raises` de uma linha, inserido apos
o padrao de `:364-366`:

```pascal
[Test]
procedure TestNilHandle_AllMembers_Raises;
begin
  Scenario_NilHandle_AllMembers_Raises;
end;
```

### 2.5 Fora de escopo (out-of-scope, explicito)

- A guarda de nil dentro de `ReferredType` da issue #44 — la o
  `GetType(nil)` ja produz `IsNil = True` corretamente; esta issue e
  sobre o que acontece **depois**.
- Qualquer membro de `TModernRTTI*Type` derivado (`TModernRTTIEnumerationType`,
  `TModernRTTIPointerType`, `TModernRTTIRecordType`, `TModernRTTIArrayType`,
  `TModernRTTISetType`) — esses records tem `FToken: PTypeInfo`, nao
  `FType: TRttiType`.
- Novos testes de "wrong-kind" para os demais tipos — fora do escopo
  desta issue.

## 3. Regras de negocio

- **B-49.1** — Quando `FType = nil` (`IsNil = True`), `Name`,
  `GetProperties`, `GetFields`, `GetMethods` e `GetMethod` levantam
  `EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['<membro>'])`.
  Zero `EAccessViolation` a partir da API publica.
- **B-49.2** — O parametro `%s` recebe o nome literal do membro chamado
  para diagnosabilidade direta na mensagem de erro.
- **B-49.3** — Em `GetFields`, a guarda de nil **precede** o
  `is TRttiInstanceType` check. Handles validos de tipos nao-classe
  (records, enums) continuam retornando `nil` — contrato preservado.
- **B-49.4** — `GetMethod` (singular) esta incluido como quinto membro.
  Medicao da investigacao confirmou o mesmo defeito em `:1072-1078`.
- **B-49.5** — `SModernRTTINilHandle` vive em `ModernSyntax.RTTI.pas`
  (unit publica), junto com os precedentes `SModernRTTIMissingProps`
  (`:861`) e `SModernRTTIGetMethodsNotClass` (`:870`).
- **B-49.6** — O cenario constroi o handle nil pelo caminho publico
  (`TModernRTTIContext.Create` + `FindType` de nome inexistente). Nenhum
  acesso direto a campos internos nos testes.

## 4. Criterios de aceitacao

- [ ] Os cinco membros (`Name`, `GetProperties`, `GetFields`, `GetMethods`,
      `GetMethod`) tratam `FType = nil` do **mesmo** jeito: levantam
      `EModernRTTIError`.
- [ ] Zero `EAccessViolation` a partir da API publica sobre um handle
      com `IsNil = True`.
- [ ] `Scenario_NilHandle_AllMembers_Raises` constroi o handle via
      `FindType('TipoQueNaoExiste_Issue49')` e afirma `EModernRTTIError`
      nos cinco membros; cada `except` verifica que a mensagem contem o
      nome do membro chamado.
- [ ] XMLDoc `<remarks>` em cada uma das cinco declaracoes (`:176`, `:193`,
      `:205`, `:373`, `:380`) declarando o comportamento sobre `IsNil`.
- [ ] `TestNilHandle_AllMembers_Raises` presente em cada casca (FPC e
      Delphi), delegando ao cenario em uma linha.
- [ ] `GetFields` sobre handle valido nao-classe (record, enum) continua
      retornando `nil` silenciosamente (contrato preservado).
- [ ] `Scenario_PointerType_ReferredType_Nil_ForBarePointer` afirma
      `EModernRTTIError` em `LReferred.Name` (divida D-44.6 desbloqueada).
- [ ] Comentarios `D-44.6 / R-4` em `:310-311` e `:1259-1265` reescritos
      citando #49 como resolvido.
- [ ] Zero `{$IFDEF FPC}` no cenario compartilhado (CA-5).
- [ ] Build FPC 3.2.2 x86_64 verde na fabrica; PR body declara resultado
      i386 e Delphi.

## 5. Restricoes (constraints)

- **CA-5** — zero `{$IFDEF FPC}` em `UScenarios.RTTI.pas`; `if FType = nil`
  e Pascal puro, identico nos dois compiladores.
- **D-7** — padrao "um cenario, duas cascas": corpo em `UScenarios.RTTI.pas`,
  casca de uma linha em cada runner.
- Construcao do handle nil sempre pelo **caminho publico** (acceptance
  criterion explicito; precedente `:949-961`).
- `resourcestring` nova na unit publica, nao nos backends — precedente
  `SModernRTTIMissingProps` (`:861`) confirma o lugar.

## 6. Riscos

- **R-49.1** — Guarda de `GetFields` inserida APOS o `is TRttiInstanceType`
  check, quebrando o contrato atual sobre records/enums com `FType <> nil`.
  **Mitigacao:** ESP §2.1 e B-49.3 fixam a ordem; acceptance verifica o
  contrato preservado.
- **R-49.2** — Implementador omite `GetMethod` (singular), recriando
  divergencia. **Mitigacao:** acceptance cita explicitamente cinco membros;
  cenario afirma os cinco.
- **R-49.3** — Cenario usa acesso direto ao campo `FType` em vez do
  caminho publico. **Mitigacao:** B-49.6 proibe; modelo e `:949-961`.
- **R-49.4** — Bloco `except` verifica so o tipo, nao a mensagem.
  **Mitigacao:** acceptance cita explicitamente a verificacao do nome
  do membro na mensagem.
- **R-49.5** — Reescrita dos comentarios D-44.6 omite a conexao com #49.
  **Mitigacao:** ESP §2.2 especifica citar "#49 como resolvido".

## 7. Fontes

- Relatorio de investigacao (run `14c0a137db091a773582148509b38bea`,
  uma volta), reproduzido verbatim no prompt — governa o [adr](pipeline-adr.md).
- [adr](pipeline-adr.md) — decisoes desta correcao.
- [plan](pipeline-plan.md) — execucao em slice unico.
- [task-input](pipeline-task-input.md) — handoff operacional.
- [/analysis/05-conventions.md](/analysis/05-conventions.md) — CA-5, D-7.
- [/SKILL.md](/SKILL.md) — receita FPC, traps.
