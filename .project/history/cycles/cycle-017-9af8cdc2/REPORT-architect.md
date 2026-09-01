---
type: cycle-report
kind: report
title: "REPORT-architect — issue #44 (TModernRTTIPointerType), cycle-017"
description: "Handoff arquitetural do ciclo-017 (issue #44): quatro artefatos derivados do relatorio de investigacao PRESENT (run 7f780007e3179b6ac2dd4b2565795789), escopo confirmado fits (3 slices tightly coupled em 6 arquivos), nove decisoes D-44.x no ADR, mutacao obrigatoria prescrita com cast explicito, dois cenarios de teste, fixture PInt44 renomeada."
status: stable
cycle: "017"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/9af8cdc2e2a54fb129b523e483beaa2d
tags: [architect, cycle-017, issue-44, modernrtti, pointer, fits, report]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-01T00:00:00Z"
sources:
  - id: esp
    resource: "pipeline-esp.md"
    title: "ESP — TModernRTTIPointerType (issue #44)"
  - id: adr
    resource: "pipeline-adr.md"
    title: "ADR — TModernRTTIPointerType (issue #44)"
  - id: plan
    resource: "pipeline-plan.md"
    title: "PLAN — TModernRTTIPointerType em 3 slices (issue #44)"
  - id: task-input
    resource: "pipeline-task-input.md"
    title: "TASK-INPUT — TModernRTTIPointerType (issue #44)"
---

# REPORT-architect — cycle-017

## O que foi entregue

Quatro artefatos em `.project/pipeline/` (mirror sob este diretorio):

- [ESP](pipeline-esp.md) — especificacao formal derivada da issue:
  objetivo, escopo (6 arquivos), regras de negocio (B-44.1 a B-44.3),
  criterios de aceitacao (14 itens), restricoes (D-1/D-2/D-4/D-25.1/CA-5
  + convencoes cross-compiler), 5 riscos com mitigacao.
- [ADR](pipeline-adr.md) — **derivado do relatorio de investigacao
  PRESENT** (run `7f780007e3179b6ac2dd4b2565795789`); nove decisoes
  D-44.1 a D-44.9, cada uma com alternativas descartadas.
- [PLAN](pipeline-plan.md) — verdict `fits` do split guard; 3 slices
  sequenciais tightly coupled com codigo de referencia; ordem
  1 -> 2 -> 3 estritamente sequencial.
- [TASK-INPUT](pipeline-task-input.md) — handoff operacional com
  tabela arquivo-a-arquivo, checklist de 14 itens, convencoes
  obrigatorias e 5 pontos de fricao sinalizados.

## Verdict do split guard

**`fits`.** Mesma forma da issue #43 (cycle-016) — o proprio relatorio
diz que a mudanca e "estritamente aditiva". Test 1 (SIZE): ~110 linhas
liquidas em 6 arquivos, cabe em um `implement`. Test 2 (INDEPENDENCE):
falha — casca chama simbolo do backend; teste afirma sobre a saida da
casca; nenhum slice mergea sozinho. Um so ciclo, um so PR.

## Como o ADR deriva do relatorio

O relatorio estava PRESENT (LAST comment com marker `aefos:investigate
run=7f780007e3179b6ac2dd4b2565795789`, uma volta com seis correcoes).
Nao ha divergencia de merito entre este ADR e o relatorio: todas as
seis correcoes da volta 1 foram absorvidas como decisoes:

| Correcao do relatorio | Decisao no ADR |
|---|---|
| Cenario 2 (`TypeInfo(Pointer)` puro) obrigatorio | D-44.5 |
| Convergencia sem `is`/`try/except` | D-44.4 |
| Asserção de `Name` via indirecao pela RTL | D-44.7 |
| Mutacao com cast explicito | D-44.2 + D-44.3 |
| Fixture `PInteger` -> `PInt44` | D-44.8 |
| Piso Delphi 23.0 sem `{$IF CompilerVersion}` | D-44.9 |

D-44.1 e D-44.6 sao decisoes de forma que o relatorio ja pressupoe
(padrao consagrado do `TModernRTTIEnumerationType`; nao tocar `.Name`
sobre nil).

## Decisoes que nao fui eu que tomei

Nenhuma. Todas as nove D-44.x vem do relatorio ou da linhagem de ADRs
anteriores (#42 D-1/D-2, #25 D-4, #43 padrao consagrado). Este ADR e
um **restatement**, nao um documento inaugural.

## Fora deste ciclo (explicito)

- **Q5** — teste explicito de wrong-kind (raise sob `Kind` diferente
  de `tkPointer`). Aditivo; se o revisor pedir, novo ciclo.
- **Issue #49** — AV em `RTTI.pas:846` (`FType.Name` sem guarda sobre
  handle nil). Registrada; o cenario 2 evita tocar o bug.
- **Enums de ponteiros generalizados** (`^TRec`, `^string`, `PChar`
  alem do `PInt44`). O contrato cobre; o teste nao enumera. Aditivo.
- **Harness de mutacao automatica.** Overengineering para um caso.

## Fricao ou observacoes para os proximos nos

- Nenhuma fricao com a pipeline em si neste ciclo. O relatorio de
  investigacao chegou completo e absorviu 6 correcoes numa volta so —
  o handoff arquitetural foi direto.
- O implementador deve ler o `TASK-INPUT` §"Provaveis pontos de
  fricao" antes de comecar: os cinco pontos ali sao os que
  historicamente pegam quem executa esse tipo de mudanca.
- Recomendacao para o `implement`: fazer a mutacao **antes** de abrir
  o PR (nao depois), para que o log `red -> reverted -> green` ja
  esteja no corpo do primeiro push.
