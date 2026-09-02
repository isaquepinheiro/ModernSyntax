---
type: cycle-report
kind: report
title: "REPORT (architect) — issue #46: TModernRTTIArrayType + TModernRTTISetType; Length levanta em dinamico; duas mutacoes obrigatorias"
description: "Design dossier do ciclo 019 (issue #46): quatro artefatos em .project/pipeline/ derivados do relatorio de investigacao PRESENT (run 03abedbe5ed05ff078e071ed503f401f, tres voltas). ADR absorveu integralmente as decisoes acordadas nas voltas: Q1 (ArrayData.Size no Delphi), Q2 (ArrayData.ElCount, nao TotalElementCount), Q3 (Name por referencia), Q4 (texto curto de SArrayDynamicLength), volta 2 (fixture do cenario 8 = TDynByteArr46, nao TDynIntArr46; elSize=1 diverge de SizeOf(Pointer) nos DOIS bitness), volta 3 (check {$IFDEF} ancorado a coluna zero; contagens 37 → 41 FPC e 35 → 39 Delphi, nao 33 → 37 nas duas cascas). Split guard: fits (6 arquivos, mesmo pattern das issues #43/#44/#45; nenhum slice mergeavel sozinho)."
status: stable
cycle: "019"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/0a0b1110fc1826855542e8d75c65cf65
tags: [modernrtti, cycle-report, issue-46, architect, fpc, delphi, array, set]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: esp
    resource: "pipeline-esp.md"
    title: "ESP — issue #46"
  - id: adr
    resource: "pipeline-adr.md"
    title: "ADR — issue #46 (deriva do relatorio PRESENT)"
  - id: plan
    resource: "pipeline-plan.md"
    title: "PLAN — issue #46 em 3 slices"
  - id: task-input
    resource: "pipeline-task-input.md"
    title: "TASK-INPUT — issue #46"
---

# REPORT (architect) — ciclo 019, issue #46

## Contexto

Issue #46 pede duas categorias RTTI novas — `TModernRTTIArrayType`
(cobrindo `tkArray` e `tkDynArray`) e `TModernRTTISetType` — com
paridade semantica entre FPC 3.2.2 e Delphi 23.0+, sob o guarda-chuva
da issue #29. Investigacao feita e presente (run
`03abedbe5ed05ff078e071ed503f401f`, tres voltas), com decisoes ja
fechadas com o humano nas quatro perguntas da volta 1 (Q1–Q4), na troca
de fixture da volta 2, e nas duas correcoes de check da volta 3.

## Entregas deste ciclo (todas em `.project/pipeline/`)

- [pipeline-esp.md](pipeline-esp.md) — spec formal derivada da issue.
  Sete secoes: objetivo, escopo (superficie publica + backends +
  cenarios), regras de negocio, criterios de aceitacao (20 itens),
  restricoes, riscos, fontes.
- [pipeline-adr.md](pipeline-adr.md) — doze decisoes (D-46.1..D-46.12)
  derivadas do relatorio de investigacao. Sem divergencia de merito;
  todos os pontos das tres voltas foram absorvidos como decisoes
  explicitas.
- [pipeline-plan.md](pipeline-plan.md) — plano de execucao em tres
  slices tightly coupled (backends → casca → testes), com codigo de
  referencia por slice e receita das duas mutacoes obrigatorias.
- [pipeline-task-input.md](pipeline-task-input.md) — handoff operacional
  para o implementador com escopo por arquivo, checklist de aceitacao
  linha a linha, convencoes obrigatorias e pontos de fricao.

## Split guard verdict: `fits`

- **Test 1 (SIZE):** 6 arquivos, ~180-220 linhas liquidas estimadas. Um
  `implement` cobre com folga (~40-50% do orcamento $20). Escopo
  comparavel ao das issues #43, #44, #45 — todas entregues em ciclo
  unico.
- **Test 2 (INDEPENDENCE):** nao. Os quatro cenarios formam um so
  contrato observavel (array estatico, array dinamico + mutacao 1,
  array dinamico gerenciado, set + mutacao 2). Slice 2 (casca) depende
  da slice 1 (backends); slice 3 (testes) depende das duas. Nenhum
  slice merge sozinho.

**Decisao:** manter o ciclo inteiro. Nenhum `split-proposal.md`
produzido.

## Como o relatorio de investigacao governou o ADR

Status: **PRESENT**. Regra: ADR **deriva** do relatorio; divergencia
tem que ser explicita e justificada. **Sem divergencia** neste ciclo —
os doze `D-46.x` reproduzem, nos termos da conversa, as decisoes que a
discussao fechou:

- D-46.1: `FromTypeInfo` sem guarda (herança do padrao #43/#44/#45).
- D-46.2: `Length` levanta em dinamico nos dois compiladores (paridade
  semantica; sem divergencia por backend).
- D-46.3: texto curto de `SArrayDynamicLength` (Q4).
- D-46.4: helper unico `ArrayRaiseWrongKind` com guarda combinada
  `[tkArray, tkDynArray]` — drift novo do #46 sobre o padrao classico.
- D-46.5: leitura via **properties** `elType2`/`ElType`/`CompType`;
  nunca refs crus.
- D-46.6: `ArrayData.Size` (Q1) e `ArrayData.ElCount` (Q2) no estatico,
  paridade objetiva com FPC.
- D-46.7: fixture do cenario 8 = `TDynByteArr46` (volta 2). `Byte`
  carrega `elType = nil` (mata Mutacao 1) **e** `elSize = 1` (diverge
  de `SizeOf(Pointer)` nos dois bitness — sem depender da corrida
  x86_64).
- D-46.8: comparacao de `Name` por referencia (Q3).
- D-46.9: Mutacao 1 exclusivamente no cenario 8; comentario do 9 nao
  promete cobri-la.
- D-46.10: Delphi ramifica por `Kind` — `TRttiDynamicArrayType` e
  `TRttiArrayType` sao **irmas**, nao ha cast comum.
- D-46.11: check `{$IFDEF}` ancorado a coluna zero (volta 3 — grep cru
  da 12 no main; 11 sao ruido de comentario).
- D-46.12: contagens 37 → 41 FPC, 35 → 39 Delphi (volta 3 — nao
  "33 → 37" nas duas cascas).

## Riscos e mitigacoes

Nove riscos catalogados na [esp](pipeline-esp.md) §6, com mitigacao
concreta em cada. Os cinco mais relevantes:

- **R-1 / R-2:** implementador troca `elType2 → elType` ou
  `CompType → CompTypeRef`. Mitigadas pelas duas mutacoes obrigatorias
  (cenarios 8 e 10) com log no PR.
- **R-3:** volta ao `TDynIntArr46` no cenario 8 — `elSize = 4` empata
  com `SizeOf(Pointer)` em i386. Mitigada por D-46.7 + destaque no
  task-input.
- **R-5:** cast comum entre `TRttiArrayType` e `TRttiDynamicArrayType`
  no Delphi (nao existe — sao irmas). Mitigada por D-46.10 + destaque
  no task-input.
- **R-8:** confiar no grep cru `{$IFDEF}`. Mitigada por D-46.11 + check
  ancorado documentado no acceptance.

## Convencoes reusadas

Toda a familia consagrada do modulo — D-1 (casca publica sem
`{$IFDEF}`), D-2/D-43.6 (paridade de texto de erro), D-4 (guarda por
`Kind`), D-5 (`TypeInfo` na `interface`), D-7 (um cenario, duas
cascas), D-25.1, D-43.1/D-44.1/D-45.1 (`FromTypeInfo` sem guarda),
D-44.5 (`TRttiContext` local), CA-4 (zero `{$IFDEF}` novo), CA-5 (zero
`{$IFDEF FPC}` em teste). Um drift novo: **D-46.4** — helper unico
`ArrayRaiseWrongKind` com guarda combinada `[tkArray, tkDynArray]`,
justificado pela superficie publica que ramifica por `IsDynamic`.

## Follow-ups fora do commit

Nenhum. A issue e completa em si; nao ha issue-filha necessaria (ao
contrario do ciclo #45 que abriu `GetFields`).

## Fontes

- Relatorio de investigacao (run `03abedbe5ed05ff078e071ed503f401f`,
  tres voltas), reproduzido verbatim no prompt do ciclo.
- ADR #45 (cycle-018) — padrao mais recente da familia
  `TModernRTTI*Type`; herança direta.
- [pipeline-esp.md](pipeline-esp.md), [pipeline-adr.md](pipeline-adr.md),
  [pipeline-plan.md](pipeline-plan.md),
  [pipeline-task-input.md](pipeline-task-input.md) — os quatro
  artefatos deste ciclo.
