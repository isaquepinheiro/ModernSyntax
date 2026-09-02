---
type: cycle-report
kind: report
title: "REPORT-architect — cycle-020 — issue #49: contrato unico de handle nil em TModernRTTIType"
description: "Arquiteto derivou esp/adr/plan/task-input para o bug #49: cinco membros de TModernRTTIType passam a levantar EModernRTTIError quando FType = nil, opcao (a) confirmada pelo relatorio de investigacao; GetMethod singular incluido como quinto membro; desbloqueio da divida D-44.6; scope = fits (slice unico, quatro arquivos)."
cycle: "020"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/fd87755097391831d283adc83e6b8813
tags: [modernrtti, rtti, issue-49, bug, nil-handle, cycle-020, architect-report]
generated:
  by: "equipe-bug@node:architect"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: investigation-report
    title: "REPORT — Issue #49 (run 14c0a137db091a773582148509b38bea) — PRESENT"
  - id: esp
    resource: "pipeline-esp.md"
    title: "ESP — issue #49"
  - id: adr
    resource: "pipeline-adr.md"
    title: "ADR — issue #49"
  - id: plan
    resource: "pipeline-plan.md"
    title: "PLAN — issue #49"
  - id: task-input
    resource: "pipeline-task-input.md"
    title: "TASK-INPUT — issue #49"
---

# REPORT-architect — cycle-020 — issue #49

## O que foi decidido

### Demanda

Bug #49: `TModernRTTIType` expoe `IsNil` mas cinco membros se comportam
de tres jeitos diferentes sobre um handle nil — tres levantam
`EAccessViolation`, um devolve vazio silencioso (`GetFields`), e um
(`GetMethod` singular) nao estava nem na lista original mas foi medido
com o mesmo defeito na investigacao.

### Decisao central (do relatorio de investigacao)

**Opcao (a):** levantar `EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['<membro>'])`
em todos os cinco membros quando `FType = nil`. A opcao (b) — devolver
vazio em silencio — foi descartada pelo relatorio com base em contagem
medida: **29** `raise EModernRTTIError` na unit publica contra **2**
retornos silenciosos, e pela paridade com o comportamento da RTL do
Delphi 37.0 (barulhenta nos dois bitness).

### Decisoes arquiteturais derivadas do relatorio

| Decisao | Resumo |
|---------|--------|
| D-49.1 | Opcao (a) — levantar `EModernRTTIError` nos cinco membros |
| D-49.2 | Cinco membros, nao quatro — `GetMethod` singular incluido por medicao |
| D-49.3 | `SModernRTTINilHandle` com `%s` para o nome do membro; vive na unit publica |
| D-49.4 | Guarda em `GetFields` **antes** do `is TRttiInstanceType` check; silencio legitimo para records/enums preservado |
| D-49.5 | Desbloqueio da divida D-44.6 — `LReferred.Name` agora afirma `EModernRTTIError` |
| D-49.6 | Cenario nomeado `Scenario_NilHandle_AllMembers_Raises` (convencao `_Raises` viva no arquivo) |
| D-49.7 | Correto factual: `IsNil` e consumido nos cenarios; quem nao consome e codigo de producao |

### Escopo de entrega: `fits`

- **TEST 1 (SIZE):** Quatro arquivos, mudancas cirurgicas — uma
  `resourcestring`, cinco guardas identicas, cinco XMLDocs, um cenario,
  duas cascas de uma linha, desbloqueio de divida.
- **TEST 2 (INDEPENDENCE):** Producao e testes sao inseparaveis — nenhum
  slice e mergeavel sozinho.

## Documentos produzidos

- [esp](pipeline-esp.md) — especificacao formal: objetivo, escopo, regras
  de negocio B-49.1–B-49.6, criterios de aceitacao, riscos.
- [adr](pipeline-adr.md) — derivado do relatorio de investigacao; registra
  D-49.1–D-49.7 e o descarte medido da opcao (b).
- [plan](pipeline-plan.md) — slice unico com quatro passos ordenados e
  tabela de 12 mudancas (A1-A7, B1-B3, C1, D1).
- [task-input](pipeline-task-input.md) — handoff operacional com o codigo
  exato das guardas, corpo completo do cenario, e traps documentadas.

## Pontos de atencao para o implementador

1. **`GetFields` guarda ANTES do `is` check** — e o risco mais facil
   de acertar errado. Se inserida depois, records/enums validos passam
   a levantar em vez de retornar `nil`, quebrando o contrato atual.

2. **`GetMethod` e o quinto membro** — a issue nomeia quatro; o relatorio
   de investigacao mediu um quinto. O cenario afirma os cinco.

3. **Verificacao de mensagem no `except`** — o cenario nao so afirma que
   `EModernRTTIError` e levantada, mas que a mensagem contem o nome do
   membro. Isso mata a mutacao "levantar com mensagem generica".

4. **Desbloqueio D-44.6** — duas linhas para apagar uma divida que
   cita #49 pelo nome; incluido no mesmo slice para nao deixar o
   comentario "bloqueado por #49" apos #49 estar resolvido.

## Sem divergencia do relatorio de investigacao

Este ciclo nao diverge de nenhuma decisao do relatorio. O `adr.md`
registra o que foi acertado; qualquer mudanca futura parte daqui.
