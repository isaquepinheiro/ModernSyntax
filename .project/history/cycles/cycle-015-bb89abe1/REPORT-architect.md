---
type: cycle-report
kind: report
title: "Cycle 015 — architect report (issue #42, TModernVisibility)"
description: "Arquiteto entregou esp/adr/plan/task-input para a issue #42 (primeira sub-issue do split de #29): TModernVisibility como enum publico, fecha vazamento de TMemberVisibility em Method.Visibility, adiciona Property.Visibility. ADR deriva do relatorio de investigacao PRESENT (run e7efef2f8eb436a389aef737d1640c95), sem divergencia. Escopo classificado 'fits' pelo split guard: 6 arquivos, 3 slices sequenciais interdependentes, nenhum mergeavel isoladamente."
status: stable
cycle: "015"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/bb89abe1aa455add801745cb2a527e99
tags: [modernrtti, architect, issue-42, cycle-015, fpc, delphi, visibility]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-01T00:00:00Z"
sources:
  - id: issue-42-report
    title: "REPORT — Issue #42 (run e7efef2f8eb436a389aef737d1640c95) — PRESENT"
  - id: esp
    resource: "pipeline-esp.md"
    title: "ESP — TModernVisibility (issue #42)"
  - id: adr
    resource: "pipeline-adr.md"
    title: "ADR — TModernVisibility (issue #42)"
  - id: plan
    resource: "pipeline-plan.md"
    title: "PLAN — TModernVisibility em 3 slices"
  - id: task-input
    resource: "pipeline-task-input.md"
    title: "TASK-INPUT — issue #42"
---

# Architect report — cycle 015 (issue #42)

## Demanda

Issue #42 — `TModernVisibility`: enum proprio, fecha vazamento de
`TMemberVisibility` em `TModernRTTIMethod.Visibility` e adiciona
`TModernRTTIProperty.Visibility` (hoje ausente do codigo, prometido
pela API-MAP §2). Primeira sub-issue do split de #29 (cycle-014).

## Entregas neste ciclo

Quatro artefatos em `.project/pipeline/`:

- [esp](pipeline-esp.md) — especificacao formal com 10 criterios de
  aceitacao, escopo, riscos, restricoes.
- [adr](pipeline-adr.md) — nove decisoes (D-42.1..D-42.9) derivadas do
  relatorio de investigacao PRESENT (run
  `e7efef2f8eb436a389aef737d1640c95`, volta 1). **Sem divergencia** —
  restatement do que foi acordado com o humano.
- [plan](pipeline-plan.md) — plano de 3 slices sequenciais
  interdependentes: (1) casca publica; (2) backends Delphi e FPC; (3)
  cenarios + cascas de teste + mutacao.
- [task-input](pipeline-task-input.md) — handoff operacional com titulo
  de commit/PR, checklist de aceitacao pronto para colar no PR body,
  arquivos impactados, convencoes.

## Verdict do split guard

**`fits`** — nao ha independencia entre slices; toda a mudanca cabe em
um PR. Ver [plan](pipeline-plan.md) §"Verdict do split guard" para o
raciocinio detalhado.

- **Test 1 (SIZE):** 6 arquivos, mudancas curtas em cada, uma resource
  string nova e uma reescrita — um `implement` cobre com folga.
- **Test 2 (INDEPENDENCE):** falha. As slices 1/2/3 nao podem mergear
  isoladamente: a slice 1 chama simbolos com assinatura antiga ate a
  slice 2 aterrissar; a slice 3 nao afirma nada sem a slice 2.

## Decisoes materiais do ADR

Sintese das decisoes derivadas do relatorio de investigacao (ver
[adr](pipeline-adr.md) para o texto completo):

- **D-42.1** — enum publico proprio, ordem `mvPrivate < mvProtected <
  mvPublic < mvPublished`.
- **D-42.2** — `case` explicito em todos os backends que devolvem valor
  real; `Ord` proibido.
- **D-42.3** — `mvAutomated` no Delphi levanta (default seguro).
- **D-42.4** — `PropertyVisibility` no FPC devolve dado real (nao
  levanta); `TRttiProperty.Visibility` existe em `rtti.pp:340,3776`.
- **D-42.5** — `MethodVisibility` no FPC continua levantando; raiz
  reescrita em `SFPCNoVisibility` para expor D-25 (vmtMethodTable).
- **D-42.6** — assinatura `PropertyVisibility(AToken: Pointer)` puro;
  sem `AOwner`.
- **D-42.7** — cenario de Property e cross-compiler; par de Method fica
  assimetrico (FPC-only + Delphi-only).
- **D-42.8** — cenario afirma apenas `mvPublished`; outros 3 valores
  cobertos por inspecao.
- **D-42.9** — mutacao de sanidade obrigatoria em `PropertyVisibility`.

## Riscos que sobem para os proximos nos

- **Ausencia de compilador Delphi no ambiente Aefos** — SKILL Trap: PR
  precisa declarar explicitamente o que foi compilado. O task-input ja
  carrega a frase pronta para o PR body.
- **Fixture do cenario cross-compiler** precisa incluir propriedade
  `published` em classe `{$M+}`; sem isso, o cenario nao afirma nada real
  no FPC. Enderecado por CA-9 (mutacao obrigatoria) — se o implementador
  esquecer da fixture, a mutacao NAO ficaria vermelha (porque o teste ja
  estava passando por caminho errado).
- **API-MAP §2** promete `TModernRTTIProperty.Visibility "todos OK"`
  hoje. Este PR fecha esse drift; se o revisor pedir atualizacao textual
  da API-MAP, e commit adicional no mesmo PR (registrado como pergunta
  em aberto no ADR).

## Nada de novo em pilar de conhecimento

Nao ha convencao inedita a promover para `.project/analysis/*`. As
convencoes governantes ja estao registradas (D-25.1, D-25.4, CA-5,
padrao "dois cenarios distintos", nomenclatura §1.3). O ADR desta issue
tambem materializa a extensao **local** de "nunca silencie o caso
ausente" para o ramo `mvAutomated` no Delphi (D-42.3), mas isso e
aplicacao direta de politica ja escrita — nao pede analise nova.
