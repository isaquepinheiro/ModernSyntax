---
type: adr
kind: decision
title: "ADR — issue #49: contrato unico de handle nil em TModernRTTIType; opcao (a) levantar EModernRTTIError; cinco membros (Name, GetProperties, GetFields, GetMethods, GetMethod); SModernRTTINilHandle com %s; guarda em GetFields antes do is check; desbloqueio D-44.6"
description: "Restatement das decisoes acordadas no relatorio de investigacao da issue #49 (run 14c0a137db091a773582148509b38bea, uma volta): opcao (a) levantar EModernRTTIError.CreateFmt(SModernRTTINilHandle, [membro]) em todos os cinco membros afetados (incluindo GetMethod singular, medido na conversa); guarda em GetFields ANTES do is TRttiInstanceType check para preservar silencio legitimo sobre records/enums com FType valido; resourcestring nomeada com %s; cenario Scenario_NilHandle_AllMembers_Raises pelo caminho publico; desbloqueio da divida D-44.6/R-4 (LReferred.Name agora afirma EModernRTTIError); opcao (b) descartada por contagem 29 raise vs 2 Result nil na unit publica e por paridade com comportamento barulhento da RTL Delphi 37.0."
status: stable
cycle: "020"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/fd87755097391831d283adc83e6b8813
tags: [modernrtti, adr, issue-49, bug, nil-handle, emodernrttierror, d-49, fpc, delphi]
generated:
  by: "equipe-bug@node:architect"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: issue-49-report
    title: "REPORT — Issue #49 (run 14c0a137db091a773582148509b38bea) — PRESENT"
  - id: esp
    resource: "esp.md"
    title: "ESP — issue #49"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, traps"
  - id: conventions
    resource: "/analysis/05-conventions.md"
    title: "05 Conventions — ModernSyntax"
---

# ADR — issue #49 (contrato de handle nil em `TModernRTTIType`)

Este documento **deriva do relatorio de investigacao** que fechou a
discussao da issue #49 (uma volta, run `14c0a137db091a773582148509b38bea`),
reproduzido verbatim no prompt do ciclo. Registra a decisao **em vigor**,
nos termos que a conversa acertou. **Nao ha divergencia de merito** entre
este ADR e o relatorio — todas as decisoes da conversa foram absorvidas
como decisoes explicitas.

## Contexto medido (do relatorio, verbatim)

Cinco bases de medicao governam o desenho:

- **Contagem de idioma da casa na unit publica.**
  `grep -c 'raise EModernRTTIError' Source/ModernSyntax.RTTI.pas` → **29**
  nos dois backends. `grep -c 'Result := nil\|Result := .*Empty'` →
  **2**. O idioma dominante e levantamento.

- **RTL do Delphi 37.0 medida nos dois bitness.** `FindType` de nome
  inexistente devolve `nil`; `.Name` e `.GetFields` sobre o resultado
  dao `EAccessViolation` em i386 e x86_64. A RTL foi barulhenta porque
  **nao teve escolha** (referencia de objeto nula); nosso record com
  ponteiro interno **pode** escolher — e essa escolha deve ser
  barulhenta e tipada em vez de opaca.

- **`GetMethod` singular medido na conversa (Volta 1).**
  ```
  FindType('NaoExisteEsteTipo_49') -> IsNil=TRUE
  GetMethod(nome) -> EAccessViolation [i386 e x86_64]
  ```
  Causa: `FType.Name` aparece **dentro** do `raise SModernRTTIGetMethodsNotClass`
  em `:1075` e `:1077` sem guarda. O mesmo padrao do `GetMethods` (:1068).

- **`IsNil` e consumido nos cenarios, nao ausente.** `UScenarios.RTTI.pas:942`
  e `:958-959` chamam `IsNil`. Quem nao consome e codigo de producao — o
  que reforca a opcao (a): a suite ja trata `IsNil` como a checagem devida,
  levantar quando alguem a pula e coerente.

- **`GetFields` hoje retorna vazio silenciosamente** — detectado na issue.
  A causa e diferente das outras (sem acesso nu a `FType.Name`), mas o
  resultado e ainda pior: o consumidor recebe vazio indistinguivel de
  "o tipo nao tem campos".

## Decisoes (D-49.x)

### D-49.1 — Opcao (a): levantar `EModernRTTIError` nos cinco membros

**Contexto.** A issue oferecia duas saidas:
- **(a)** levantar `EModernRTTIError` com mensagem propria;
- **(b)** devolver vazio/`''` em todos.

**Decisao.** Opcao **(a)**. `EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['<membro>'])` como primeira instrucao de cada um dos cinco membros quando `FType = nil`.

**Alternativa descartada — opcao (b).**
Recusada por duas razoes medidas:
1. Contagem de idioma da casa: **29** `raise EModernRTTIError` na unit
   publica contra **2** retornos silenciosos — opcao (b) nadaria contra
   a corrente do proprio codigo.
2. A RTL do Delphi 37.0 e barulhenta (AV medida nos dois bitness) — o
   produto ficaria **mais silencioso que a RTL** numa situacao equivalente,
   o que e regressao de UX.

### D-49.2 — Cinco membros, nao quatro

**Contexto.** A issue nomeia quatro membros (`Name`, `GetProperties`,
`GetFields`, `GetMethods`). A Volta 1 do humano trouxe medicao de
`GetMethod` singular:
```
GetMethod(nome) sobre handle nil -> EAccessViolation nos dois bitness
```
Causa: `FType.Name` sem guarda dentro dos dois `raise` em `:1075` e `:1077`.

**Decisao.** `GetMethod` e incluido como **quinto membro**. Excluir um
membro com o mesmo defeito recriaria a inconsistencia que a issue existe
para eliminar.

**Alternativa descartada.**
Excluir `GetMethod` seguindo literalmente a acceptance de quatro membros.
Recusada por medicao direta — mesmo padrao, mesmo defeito, mesma causa.

### D-49.3 — `SModernRTTINilHandle` com `%s` para o nome do membro

**Contexto.** O `%s` permite que a mensagem de erro identifique o membro
chamado sem uma `resourcestring` por membro, preservando diagnosabilidade.
Precedentes com mensagens que nomeiam o contexto existem na unit publica.

**Decisao.**
```pascal
SModernRTTINilHandle =
  'handle nao inicializado (IsNil = True). Verifique IsNil antes de chamar %s.';
```
Vive em `Source/ModernSyntax.RTTI.pas` junto com `SModernRTTIMissingProps`
(`:861`) e `SModernRTTIGetMethodsNotClass` (`:870`).

**Alternativas descartadas.**
- Uma `resourcestring` por membro (cinco strings). Rejeitada por
  redundancia desnecessaria.
- `resourcestring` nos backends (FPC/Delphi). Rejeitada: `TModernRTTIType`
  vive na unit publica; coerente com o precedente `SModernRTTIMissingProps`.

### D-49.4 — Guarda em `GetFields` **antes** do `is TRttiInstanceType` check

**Contexto.** `GetFields` tem dois caminhos possiveis:
1. `FType = nil` — bug ativo (devolve vazio silenciosamente).
2. `FType <> nil` mas nao-`TRttiInstanceType` — comportamento legitimo
   atual (records, enums genuinamente sem campos de instancia RTTI).

**Decisao.** A guarda `if FType = nil then raise ...` precede o `is` check.
O caminho 2 (`FType valido mas nao-classe`) continua retornando `nil`
silenciosamente — contrato atual preservado.

**Alternativa descartada.**
Colapsar `FType = nil` com `not (FType is TRttiInstanceType)` em uma
unica condicao. Rejeitada: quebraria o contrato atual sobre handles
validos de records/enums (tipos que genuinamente nao tem campos de
instancia RTTI). Confunde nil-handle com tipo-sem-campos.

### D-49.5 — Desbloqueio da divida D-44.6 / R-4

**Contexto.** `Scenario_PointerType_ReferredType_Nil_ForBarePointer`
(`:1254-1269`) tem um comentario "NAO tocar em `LReferred.Name`" porque,
antes desta correcao, fazer isso levantaria `EAccessViolation`. A divida
cita #49 pelo nome como bloqueio. Medicao (Volta 1):
```
ReferredType(Pointer) -> IsNil=TRUE; .Name -> EAccessViolation [i386 e x86_64]
```

**Decisao.** Com D-49.1 em vigor, `LReferred.Name` passa a levantar
`EModernRTTIError` — o contrato certo. A divida e desbloqueada:
- Remover o comentario "NAO tocar".
- Adicionar `try LReferred.Name; Fail(...) except on EModernRTTIError do ...`.
- Reescrever comentarios `D-44.6 / R-4` em `:310-311` e `:1259-1265`
  citando #49 como *resolvido*.

**Alternativa descartada.**
Deixar a divida para um ciclo futuro. Rejeitada: o desbloqueio e duas
linhas e citar #49 como bloqueio apos resolver #49 seria inconsistencia
documentada.

### D-49.6 — Nome do cenario: `Scenario_NilHandle_AllMembers_Raises`

**Contexto.** A convencao viva do arquivo usa o padrao
`Scenario_<Assunto>_<Comportamento>` e `_Raises` como sufixo para
cenarios que afirmam levantamento (`:327`, `:304`, `:284`, `:293`).
"AllMembers" em vez de "FourMembers" porque a contagem virou cinco (D-49.2).

**Decisao.** `Scenario_NilHandle_AllMembers_Raises`.

**Alternativas descartadas.**
- `Scenario_NilHandle_FourMembers_Raises` — falso apos D-49.2.
- Sem sufixo `_Raises` — quebra a convencao viva do arquivo.

### D-49.7 — Correto factual: `IsNil` e consumido nos cenarios

**Contexto.** A issue afirma "`IsNil` nao e consumido por ninguem". A
Volta 1 (humano) corrigiu: `UScenarios.RTTI.pas:942` e `:958-959`
consomem `IsNil`. Quem nao consome e codigo de producao.

**Registro.** Esta correcao factual **reforca** D-49.1: a suite ja trata
`IsNil` como a checagem devida; levantar quando alguem a pula e
coerente, nao arbitrario.

## Convencoes que governam esta correcao (referencia)

- **CA-5** — zero `{$IFDEF FPC}` em `UScenarios.RTTI.pas`; `if FType = nil`
  e Pascal puro.
- **D-7** — "um cenario, duas cascas" — padrao das issues #25-#28,
  #42-#46.
- **Construcao pelo caminho publico** — acceptance criterion explicito;
  precedente `Scenario_Context_FindType_NotFound_ReturnsNil` (`:949-961`).
- **`EModernRTTIError` para uso indevido** — padrao da unit; **29**
  `raise EModernRTTIError` medidos contra **2** retornos silenciosos.
- **`resourcestring` na unit publica** — precedente `SModernRTTIMissingProps`
  (`:861`) e `SModernRTTIGetMethodsNotClass` (`:870`).
- **Sufixo `_Raises` na convencao de nome de cenario** — verificado em
  `:327`, `:304`, `:284`, `:293`.

## Descartadas explicitas (do relatorio, sem parafrase)

- **Opcao (b) — devolver vazio/`''` em silencio.** Contagem medida na
  unit publica (**29** `raise` contra **2** `Result silencioso`);
  RTL do Delphi 37.0 tambem e barulhenta (AV nos dois bitness).
- **Excluir `GetMethod` singular da correcao.** Medicao direta:
  `GetMethod` sobre handle nil levanta `EAccessViolation` nos dois
  bitness — mesmo defeito, mesma causa.
- **Nomes `Scenario_NilHandle_FourMembers_Raises` ou sem `_Raises`.**
  `FourMembers` e falso (sao cinco); `_Raises` e a convencao viva.
- **Colapsar nil-guard com `is TRttiInstanceType` em `GetFields`.**
  Quebraria o contrato sobre records/enums com `FType` valido.
- **`resourcestring` por membro (cinco strings).** Redundante; `%s`
  resolve com uma unica string.
- **Manter a divida D-44.6 para ciclo futuro.** Duas linhas para
  apagar uma divida que cita #49 pelo nome — faz sentido fazer agora.

## O que este ADR nao decide

- Ordem de execucao (e do [plan](pipeline-plan.md)).
- Formato exato do XMLDoc por linha (e do [esp](pipeline-esp.md)).
- Checklist de aceitacao formatada (e do [esp](pipeline-esp.md)).

## Fontes

- Relatorio de investigacao (run `14c0a137db091a773582148509b38bea`,
  uma volta), reproduzido verbatim no prompt do ciclo.
- [esp](pipeline-esp.md) — especificacao formal desta correcao.
- [/analysis/05-conventions.md](/analysis/05-conventions.md) — CA-5, D-7,
  convencao de nomes.
- [/SKILL.md](/SKILL.md) — receita FPC, traps, dois bitness.
