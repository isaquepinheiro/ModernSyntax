---
type: cycle-report
kind: report
title: "REPORT — architect (cycle-004, issue #8 Pilar 1 da ModernRTTI)"
description: "Handoff do arquiteto: esp, adr (derivado do relatório de investigação PRESENT), plan em 5 fatias sequenciais (scope=fits) e task-input, para o Pilar 1 da ModernRTTI (leitura de RTTI portável Delphi+FPC)."
cycle: "004"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/9a5f8b9e974c23d88b7b6aba11e2973d
tags: [architect, modernrtti, rtti, pilar-1, issue-8, cycle-report]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-28T00:00:00Z"
---

# REPORT — architect (cycle-004)

## Contexto

Issue #8 do `isaquepinheiro/ModernSyntax`: implementar o **Pilar 1**
da camada ModernRTTI — leitura de RTTI portável Delphi+FPC. O
[PRD](/strategy/2026-08-27-modernrtti/PRD.md) organiza a entrega em
três pilares; este ciclo entrega o primeiro. A investigação da issue
produziu um **relatório PRESENT** (run `6326ac737a`) que fechou nome
da unit, formato da API de valor (genéricos + `TValue` como escape
hatch), contrato de ownership, contexto RTTI próprio, e a dependência
da issue #7 para a infra FPC.

O ciclo **anterior** desta mesma issue #8 falhou (commit `06fccea`
importava DUnitX inexistente no FPC 3.2.2; PR fechado sem merge). O
relatório de investigação registra a lição, e este ADR reforça: FPCUnit
no lado FPC, `.lpi` da #7 é reutilizado (não inventamos um próprio).

## Entregáveis

Quatro artefatos em `.project/pipeline/`, mais este report:

- [esp](pipeline-esp.md) — objetivo, escopo, RN-1..RN-10, CA-1..CA-10,
  restrições, RSK-1..RSK-8.
- [adr](pipeline-adr.md) — deriva do relatório PRESENT; 12 decisões
  (D-1..D-12) restauradas nos termos que a discussão fechou. Extensão
  explícita em D-9/D-10/D-11 para amarrar às convenções fixadas pelo
  cycle-003 (issue #7).
- [plan](pipeline-plan.md) — cinco fatias sequenciais (`scope=fits`):
  unit de produção; cenários compartilhados; casca DUnitX; runner
  Delphi + registro em `groupproj`/`DCC.bat`; casca FPCUnit + registro
  no `.lpi` da #7.
- [task-input](pipeline-task-input.md) — checklist operacional,
  divergência declarada do texto original da issue, plano de fallback
  se a #7 não mergear, três pendências para o dono ratificar antes do
  merge.

## Scope estimate

**`fits`.**

- **Test 1 (SIZE):** unit greenfield ~200-300 linhas com XML doc,
  cenários ~150 linhas, cascas finas ~30-50 linhas cada, edição de 3
  arquivos de projeto. Cabe num orçamento de implementação normal —
  **não** exaure um budget de implementação.
- **Test 2 (INDEPENDENCE):** as 5 fatias **não** são independentes.
  A unit sem os testes não prova portabilidade; os testes sem a unit
  não compilam; a casca FPC sem o registro no `.lpi` não roda (CA-10).
  Sequência obrigatória.

Splitting seria puro overhead — pagaria 5× a taxa fixa de ciclo por
uma única unidade de trabalho. Um ciclo, cinco fatias.

## Decisões-chave (resumo, todas em [adr](pipeline-adr.md))

- **D-1** — Nome `Source/ModernSyntax.RTTI.pas`, entry point `TModernRTTI`.
- **D-3** — API de valor: `GetValue<T>`/`SetValue<T>` genéricos;
  overloads `TValue` como escape hatch documentado. Evita vazar
  `Rtti` (marcada `experimental` no FPC 3.2.2) para o consumidor.
- **D-4** — Retorno `TArray<...>` com contrato de ownership em
  `/// <remarks>`. Sem enumerator custom.
- **D-5** — Contexto RTTI **próprio da unit** (`class var
  TModernRTTI.FContext`). Não reusa `TModernObject.FContext` (importar
  `ModernSyntax.Objects` arrasta dependências Delphi-only — C-3 do STUDY).
- **D-6** — Ausência de `{$M+}` no FPC: `EModernRTTIError` **sempre**,
  nunca lista vazia silenciosa (R4 do PRD). Mensagem instrutiva
  ("diz o que fazer, não só o que houve") — texto rascunho, pendente
  de ratificação do dono.
- **D-7** — `{$IFDEF FPC}` direto, sem `{$I ModernSyntax.inc}` (R3
  do PRD — contorna o bug `{$IFDEF FCP}` de `ModernSyntax.inc:256`).
- **D-8** — `uses` da `interface`: `Rtti, TypInfo, SysUtils` — nada
  mais.
- **D-9** — Testes na convenção do cycle-003 (D-A7/D-A8 do
  [adr #7](/history/cycles/cycle-003-92fccbce/pipeline-adr.md)):
  cenários compartilhados + cascas finas + FPCUnit no lado FPC.
- **D-11** — Prefixo de interface (`IMS`/`IModern`/bare `I*`) fica
  fora do escopo desta issue (Pilar 1 só introduz records). Trava a
  próxima issue da família que introduzir interface.

## Divergências declaradas

- **Do texto original da issue #8:** a issue diz "testes DUnitX" e
  "adicionados ao projeto Lazarus criado na issue de Callbacks". A
  decisão em vigor (relatório de investigação + adr #7) é FPCUnit
  no lado FPC; o runner FPC entra no `.lpi` versionado pela #7 sem
  invenção de `.lpi` próprio. Motivo em [adr, D-9](pipeline-adr.md).

**Nenhuma divergência silenciosa** do relatório de investigação. Onde
este ADR estende (D-9/D-10/D-11), é para amarrar às convenções do
cycle-003 que o relatório também assume.

## Pendências para o dono (registradas no [task-input](pipeline-task-input.md))

Nenhuma bloqueia a implementação:

1. Texto exato da mensagem da `EModernRTTIError` (rascunho em
   [adr, D-6](pipeline-adr.md)). Recomendação: unificar.
2. Prefixo de interface da família ModernRTTI. Não bloqueia esta
   issue; trava a próxima que introduzir interface. Medições
   registradas: 7 bare `I*` / 1 `IModern*` / 1 `IMS*` morto.
3. Nomenclatura opcional do arquivo de cenários — `UScenarios.RTTI.pas`
   (adotado) vs `UTestMS.RTTI.Scenarios.pas` (padrão da #7).

## Dependência de ordem

Depende de **issue #7** para infra FPC (`Test FPC/`, `Test Shared/`,
`.lpi`). Se não mergear, PR desta declara *"CA-7/CA-10 pendentes:
bloqueado por #7. Compilado em Delphi; não compilado em FPC."* Não
inventamos infra alheia (lição do commit rejeitado `06fccea`).

## Cross-links

- [esp](pipeline-esp.md)
- [adr](pipeline-adr.md)
- [plan](pipeline-plan.md)
- [task-input](pipeline-task-input.md)
- [PRD ModernRTTI](/strategy/2026-08-27-modernrtti/PRD.md)
- [STUDY ModernRTTI](/strategy/2026-08-27-modernrtti/STUDY.md)
- [ADR cycle-003 (issue #7)](/history/cycles/cycle-003-92fccbce/pipeline-adr.md)
- [03 Architecture](/analysis/03-architecture.md)
- [05 Convenções](/analysis/05-conventions.md)
