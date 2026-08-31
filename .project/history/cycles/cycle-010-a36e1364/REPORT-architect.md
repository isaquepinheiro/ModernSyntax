---
type: cycle-report
kind: report
title: "REPORT-architect — cycle 010 (issue #25)"
description: "Handoff arquitetural para o re-run da issue #25: esp, adr, plan e task-input restatam a decisão do relatório de investigação PRESENT, com cirurgia do Fail fechando #35."
status: stable
cycle: "010"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/a36e13649de2fc026303074567d63275
tags: [modernrtti, cycle-report, architect, issue-25, issue-35]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-31T00:00:00Z"
---

# REPORT — architect (cycle 010, issue #25)

## Escopo desta cycle

Uma issue (#25) com **relatório de investigação PRESENT** (mesmo relatório
que guiou o ciclo 009). Como a decisão em vigor não mudou, o arquiteto:

- restatou a decisão no [adr](pipeline-adr.md), sem reabertura
  (D-25.1 a D-25.10) — nenhum ponto foi silenciosamente reaberto;
- derivou o [esp](pipeline-esp.md) da issue (objetivo, escopo,
  regras, critérios, restrições, riscos);
- consolidou o [plan](pipeline-plan.md) em **4 slices sequenciais dentro
  do mesmo PR** — split arquitetural + Field portado, adição de
  Method/Parameter em ambos os backends, cirurgia do `Fail` fechando
  #35, e fixture+published tests com prova de mutação;
- gerou o [task-input](pipeline-task-input.md) com checklist de
  aceitação, arquivos impactados e comandos de verificação.

## Judgment (split vs fits)

**FITS.**

- **TEST 1 — tamanho:** ~6 arquivos tocados, ~2 arquivos novos, três
  cenários novos, uma refactor + duas adições de tipo. Volume cabe
  folgado num implement budget de ~$20.
- **TEST 2 — independência:** os quatro slices são passos ordenados
  dentro do mesmo commit-set, não entregas paralelas. Slice 1 sozinha
  não fecha (Field portado sem os backends é build quebrado); Slice 2
  depende do split; Slice 3 tecnicamente shiparia sozinha mas o
  relatório rejeitou explicitamente adiar; Slice 4 só existe se 2 e 3
  entraram. Cortar em dois PRs pagaria o overhead fixo duas vezes para
  reintegrar as metades.

## Decisões-chave (herdadas do relatório, nada divergido)

- **§7 do API-MAP** aplicada aos três tipos que o teste alcança:
  `TModernRTTIField` refatorado + `TModernRTTIMethod` e
  `TModernRTTIParameter` novos, todos com estado privado neutro; único
  `{$IFDEF}` na `uses` da `implementation`.
- **Iteração por `LTab^.Entry[i]`**, sem aritmética literal — protege
  i386.
- **Lookup por nome via `MethodAddress`**, sem laço de herança próprio.
- **`EModernRTTIError` nos seis membros sem fonte no FPC** (precedente
  `GetProperties`), com XMLDoc documentando.
- **`TModernRTTIParameter` com `Name`/`ParamType` reais** (opção (a) da
  volta 2), preservando D-25.6.
- **Cirurgia do `Fail`** em `UScenarios.RTTI.pas` neste ciclo — fecha
  #35 no mesmo PR.
- **Prova de mutação declarada no PR** (M1 e M2) seguindo
  `SKILL.md:92-97`.

## Referências

- [esp](pipeline-esp.md)
- [adr](pipeline-adr.md)
- [plan](pipeline-plan.md)
- [task-input](pipeline-task-input.md)
- [API-MAP](/strategy/2026-08-27-modernrtti/API-MAP.md)
- [SKILL](/SKILL.md)
