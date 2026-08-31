---
type: cycle-report
kind: report
title: "REPORT-architect — cycle 009 (issue #25)"
description: "Handoff arquitetural produzido a partir do relatório de investigação da issue #25: esp, adr, plan e task-input para TModernRTTIMethod pela vmtMethodTable, com cirurgia do Fail fechando #35."
status: stable
cycle: "009"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/af5fcd28da98e98892fbe66e544b6b5c
tags: [modernrtti, cycle-report, architect, issue-25, issue-35]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-31T00:00:00Z"
---

# REPORT — architect (cycle 009, issue #25)

## Escopo desta cycle

Uma issue (#25) com **relatório de investigação PRESENT**. O arquiteto:

- restatou a decisão em vigor no [adr](pipeline-adr.md), sem
  reabertura (D-25.1 a D-25.10);
- derivou o [esp](pipeline-esp.md) da própria issue (objetivo, escopo,
  regras, critérios, restrições, riscos);
- consolidou o [plan](pipeline-plan.md) em **4 slices sequenciais
  dentro do mesmo PR** — split arquitetural + Field portado, adição de
  Method/Parameter em ambos os backends, cirurgia do `Fail` fechando
  #35, e fixture+published tests com prova de mutação;
- gerou o [task-input](pipeline-task-input.md) com checklist de
  aceitação, arquivos impactados e comandos de verificação.

## Judgment (split vs fits)

**FITS.**

- **TEST 1 — tamanho:** ~6 arquivos tocados, ~2 arquivos novos, três
  cenários novos, uma refactor + duas adições de tipo. Volume real
  cabe folgado num implement budget de ~$20. Não é tela grande.
- **TEST 2 — independência:** os quatro slices do plano são **passos
  ordenados dentro do mesmo commit-set**, não entregas paralelas. A
  slice 1 (split de backends + Field portado) não fecha sozinha porque
  a compilação atual de `PTestRTTI` já depende do `TModernRTTIField`
  presente; a slice 2 (Method/Parameter) depende do split existir; a
  slice 3 (Fail) tecnicamente shiparia sozinha, mas o próprio
  relatório de investigação (volta 2, item 1) rejeitou explicitamente
  adiar/isolar — a prova de mutação da slice 4 só vale se a slice 3
  entrou antes; a slice 4 (fixtures + tests) só existe se as 2 e 3
  existiram. Cortar em dois PRs pagaria o overhead fixo do ciclo em
  dobro para reintegrar as metades depois.

## Decisões-chave herdadas do relatório

- **§7 do API-MAP aplicada agora aos três tipos que o teste alcança**:
  `TModernRTTIField` refatorado + `TModernRTTIMethod` e
  `TModernRTTIParameter` novos, todos com estado privado neutro; único
  `{$IFDEF}` na `uses` da `implementation`.
- **Iteração por `LTab^.Entry[i]`**, sem aritmética literal — protege
  i386.
- **Lookup por nome via `MethodAddress`**, sem laço de herança próprio.
- **`EModernRTTIError` nos seis membros sem fonte no FPC** (precedente
  `GetProperties`), com XMLDoc documentando.
- **`TModernRTTIParameter` com `Name`/`ParamType` reais** (opção (a) da
  volta 2), preservando D-25.4.
- **Cirurgia do `Fail`** em `UScenarios.RTTI.pas` neste ciclo — fecha
  #35 no mesmo PR.
- **Prova de mutação declarada no PR** (M1 e M2) seguindo
  `SKILL.md:92-97`.

## Nada foi divergido do relatório

O arquiteto restatou o que a discussão fixou, nos mesmos termos. Onde a
volta 2 corrigiu a volta 1 (item 1 — Fail agora; item 2 —
`TModernRTTIParameter` opção (a)), o ADR entrega o desenho final da
volta 2. Nenhum ponto do relatório foi silenciosamente reaberto.

## Referências

- [esp](pipeline-esp.md)
- [adr](pipeline-adr.md)
- [plan](pipeline-plan.md)
- [task-input](pipeline-task-input.md)
- [API-MAP](../../strategy/2026-08-27-modernrtti/API-MAP.md)
- [SKILL](../../SKILL.md)
