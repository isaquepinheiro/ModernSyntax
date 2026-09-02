---
type: cycle-report
kind: report
title: "REPORT-architect — issue #45 (TModernRTTIRecordType), cycle-018"
description: "Handoff arquitetural do ciclo-018 (issue #45): quatro artefatos derivados do relatorio de investigacao PRESENT (run d9ace4ff9a3af56be91a8f0373cb9475, volta 1). Escopo confirmado fits (3 slices tightly coupled em 6 arquivos). Nove decisoes D-45.x no ADR, com duas fixtures obrigatorias no cenario (uma unmanaged constante + uma managed que varia por bitness), helper unico RecordRaiseWrongKind por backend, LCtx local no Delphi, veto explicito a ManagedFldCount, superficie publica restrita a Name+Size (GetFields fica para issue-filha aberta fora do commit)."
status: stable
cycle: "018"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/d9ace4ff9a3af56be91a8f0373cb9475
tags: [architect, cycle-018, issue-45, modernrtti, record, fits, report]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: esp
    resource: "pipeline-esp.md"
    title: "ESP — TModernRTTIRecordType (issue #45)"
  - id: adr
    resource: "pipeline-adr.md"
    title: "ADR — TModernRTTIRecordType (issue #45)"
  - id: plan
    resource: "pipeline-plan.md"
    title: "PLAN — TModernRTTIRecordType em 3 slices (issue #45)"
  - id: task-input
    resource: "pipeline-task-input.md"
    title: "TASK-INPUT — TModernRTTIRecordType (issue #45)"
---

# REPORT-architect — cycle-018

## O que foi entregue

Quatro artefatos em `.project/pipeline/` (mirror sob este diretorio):

- [ESP](pipeline-esp.md) — especificacao formal derivada da issue #45:
  objetivo, escopo (6 arquivos), tres regras B-45.x, criterios de
  aceitacao (15 itens), restricoes (CA-4/D-1/D-2/D-4/D-5/D-7/CA-5 +
  piso Delphi 23.0), seis riscos com mitigacao.
- [ADR](pipeline-adr.md) — **derivado do relatorio de investigacao
  PRESENT** (run `d9ace4ff9a3af56be91a8f0373cb9475`, volta 1); nove
  decisoes D-45.1 a D-45.9, cada uma com alternativas descartadas e
  ancoragem na medicao do Diretor.
- [PLAN](pipeline-plan.md) — verdict `fits` do split guard; 3 slices
  sequenciais tightly coupled com codigo de referencia; ordem
  1 (backends) → 2 (casca) → 3 (testes).
- [TASK-INPUT](pipeline-task-input.md) — handoff operacional com
  tabela arquivo-a-arquivo, checklist de 14 itens + 1 item fora do
  commit (issue-filha), convencoes obrigatorias e 8 pontos de fricao
  sinalizados.

## Verdict do split guard

**`fits`.** Mesma forma das issues #43 (cycle-016) e #44 (cycle-017) —
o proprio relatorio diz que a mudanca e "puramente aditiva".

- **Test 1 (SIZE):** ~120-130 linhas liquidas em 6 arquivos, cabe em
  um `implement` com folga (~30-40% do orçamento $20). Ligeiramente
  maior que #44 pela dupla-funcao por backend + helper + segunda
  fixture, ainda longe do teto.
- **Test 2 (INDEPENDENCE):** falha — casca chama simbolo do backend;
  teste afirma sobre a saida da casca; nenhum slice mergea sozinho.

Um so ciclo, um so PR. Sem `split-proposal.md`.

## Como o ADR deriva do relatorio

O relatorio estava PRESENT (LAST comment com marker `aefos:investigate
run=d9ace4ff9a3af56be91a8f0373cb9475`, uma volta com sete correcoes
do Diretor). Nao ha divergencia de merito entre este ADR e o
relatorio: todas as sete correcoes da volta 1 foram absorvidas como
decisoes:

| Correcao do relatorio (volta 1) | Decisao no ADR |
|---|---|
| Fixture managed obrigatoria alem da unmanaged | D-45.4 |
| Asserção so por igualdade (sem `>=`) | D-45.4 (final) |
| Veto explicito a `ManagedFldCount` para `tkRecord` | D-45.7 |
| `record end` (Size = 0) valido; sem guarda por Size | D-45.8 |
| `LCtx` local com `try/finally` no Delphi (nao `FContext` global) | D-45.6 |
| `SRecordWrongKind` unico + helper `RecordRaiseWrongKind` | D-45.5 |
| Nomes `RecordTypeName`/`RecordTypeSize`; XMLDoc verbatim; issue-filha fora do commit | D-45.2 + D-45.3 |

D-45.1 e D-45.9 sao decisoes de forma que o relatorio ja pressupoe
(padrao consagrado das issues #43/#44; piso Delphi 23.0 medido).

## Decisoes que nao fui eu que tomei

Nenhuma. Todas as nove D-45.x vem do relatorio ou da linhagem de ADRs
anteriores (D-1/D-2/D-4 de #25/#42, D-43.1/D-43.6 e padrao
`EnumRaiseWrongKind` de #43, `LCtx` local e padrao aditivo de #44).
Este ADR e um **restatement**, nao um documento inaugural.

## Fora deste ciclo (explicito)

- **`TModernRTTIRecordType.GetFields`.** Motivo objetivo: o Diretor
  mediu `RecSize` mas nao mediu `TRecordElement.Name` num FPC 3.2.2
  vivo (limitacao F-3 do estudo). Issue-filha (titulo verbatim:
  *"`TModernRTTIRecordType.GetFields`: medir `TRecordElement.Name` no
  FPC 3.2.2 antes de entregar"*; labels `enhancement`, `rtti`, `fpc`,
  `blocked:medicao`) e aberta **fora do commit** desta entrega —
  o TASK-INPUT tem esse item marcado.
- **Teste explicito de wrong-kind** (raise sob `Kind <> tkRecord`).
  Aditivo; se o revisor pedir, novo ciclo.
- **Cenarios adicionais** (records aninhados, com variantes, genericos).
  O contrato cobre; o teste nao enumera.
- **Mutacao obrigatoria.** Ausente — a issue nao pede (delegacao a
  `TRttiRecordType`/`GetTypeData` no Delphi e leitura direta no FPC nao
  tem contrapartida "obvia mas errada" a documentar).

## Fricao ou observacoes para os proximos nos

- Nenhuma fricao com a pipeline em si neste ciclo. O relatorio de
  investigacao chegou completo, absorveu 7 correcoes numa volta so, e o
  handoff arquitetural foi direto.
- O implementador deve ler o [`pipeline-task-input.md`](pipeline-task-input.md)
  §"Provaveis pontos de fricao" antes de comecar: os 8 pontos ali sao
  os que historicamente pegam quem executa esse tipo de mudanca — em
  particular a tentacao de "duas fixtures e overkill" (item #1) e o
  veto ao `ManagedFldCount` (item #3), ambos com custo alto se
  ignorados.
- Recomendacao para o `implement`: seguir a ordem `backends → casca →
  testes` do PLAN. E o oposto de #44 (que fez `casca → backend →
  teste`), e existe por causa da dupla-funcao + helper por backend
  desta issue.
- Recomendacao para o `release`: o item "Fora do commit da entrega" do
  TASK-INPUT (abrir issue-filha de `GetFields`) e obrigatorio apos
  merge. Se o release node esquecer, o proximo consumidor de
  `TModernRTTIRecordType` vai reclamar da falta de `GetFields` sem
  saber que ha bloqueio de medicao.
