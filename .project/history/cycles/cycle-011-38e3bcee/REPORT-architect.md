---
type: cycle-report
kind: report
title: "REPORT — architect — cycle-011 (issue #26)"
description: "Restatement da decisão da #26 em ESP/ADR/plan/task-input: TModernValue mínimo, TValueOps record em cada backend, delegação pura no Delphi e IsType+ExtractRawData no FPC, alargamento como issue própria, cenário de exceção local ao FPC preservando CA-5."
status: stable
cycle: "011"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/38e3bcee8cdc184a2977006358812748
tags: [modernrtti, cycle-report, issue-26, fpc, delphi, tvalue, astype]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-31T00:00:00Z"
sources:
  - id: issue-26-report
    title: "Investigation REPORT — issue #26 (run e34527b70259d01ff46bef0971b2d033)"
  - id: api-map
    resource: "/strategy/2026-08-27-modernrtti/API-MAP.md"
    title: "ModernRTTI API-MAP (§2, §7)"
---

# REPORT — architect — cycle-011

## Demanda

Issue #26 — `TModernValue.AsType<T>`: o membro mais usado do `TValue`,
único ausente no FPC 3.2.2. Envolver `TValue` nos dois compiladores,
entregar `AsType<T>` com paridade de assinatura e paridade de caso
exato, sem `{$IFDEF FPC}` no código do consumidor (CA-5), passando nos
dois bitness.

Investigation report: **PRESENT** (4 voltas, run
`e34527b70259d01ff46bef0971b2d033`).

## O que entreguei

Quatro artefatos no `.project/pipeline/`, mais este relatório:

- [pipeline-esp](pipeline-esp.md) — 16 critérios de aceitação, escopo
  mínimo, restrições explícitas, 6 riscos (R1 = confirmação Delphi;
  R2/R3 = mudança de mensagem no FPC; R4 = armadilha de nome; R5 =
  programa de medição fica na issue de alargamento; R6 = mutação
  obrigatória).
- [pipeline-adr](pipeline-adr.md) — restatement da decisão acordada
  nas 4 voltas, com 10 decisões (D-1 superfície mínima; D-2 `TValueOps`
  record em cada backend; D-3/D-4 corpos Delphi/FPC; D-5 alargamento
  fora; D-6 XMLDoc; D-7 fecha drift §7; D-8 exceção única; D-9 testes
  com CA-5 preservado; D-10 armadilha de nome). Duas divergências
  editoriais (não de mérito) do relatório de investigação declaradas em
  voz alta no topo do ADR.
- [pipeline-plan](pipeline-plan.md) — três slices coordenadas em UM PR:
  (1) `TValueOps` nos backends; (2) `TModernValue` público + fecha
  drift; (3) cenários compartilhados + published + exceção local FPC.
- [pipeline-task-input](pipeline-task-input.md) — handoff operacional
  com checklist granular, comandos FPC x86_64 e menção explícita à
  próxima issue a abrir (alargamento).

## Scope estimate

**`fits`.** Justificativa:

- **TEST 1 (SIZE):** trivial-a-médio. 3 arquivos de `Source/`
  (edição, não reescrita) + 3 arquivos de teste. Muito abaixo do budget
  de um `implement`. Um único slice honesto atende, e escolhi 3 apenas
  para permitir ao compilador falar em cada etapa.
- **TEST 2 (INDEPENDENCE):** falha por design. As 3 slices são
  coordenadas — o build só volta a passar quando todas fecham
  (superfície pública sem cliente = teste morto; teste sem superfície =
  não compila; drift do §7 fecha exatamente quando `TModernValue`
  existe). Cortar em issues separadas pagaria overhead 3x sem retorno.

**Não** escrevo `split-proposal.md`.

## Decisões-chave e por que estão como estão

1. **`adr.md` DERIVA do relatório de investigação**, restatement das
   4 voltas nos termos que a discussão acertou. Divirjo em dois pontos
   editoriais (não de mérito):
   - Referência `UScenarios.RTTI.pas:168` — mantida com nota "verificar
     no primeiro edit se o número da linha bateu" (padrão é o mesmo
     mesmo se o número tiver drift).
   - Programa de medição de alargamento (`.dpr` com `TMeasure` record)
     NÃO é entregue nesta issue. A conversa (volta 3 + rodapé) deixou
     em aberto e delegou ao plano formal — decido: fica com a **issue
     de alargamento** quando abrir. Motivo: nasce lá com a matriz medida
     como pré-requisito, no lugar onde o dado importa; carregá-lo aqui
     aumenta a superfície da #26 sem retorno.

2. **`esp.md` NÃO deriva do report** — vem da issue e das convenções
   (§7 API-MAP, CA-5, SKILL.md). É o documento contra o qual review/test
   julgam a entrega, e não pode ser espelho do plan.

3. **Cenário de exceção fica LOCAL ao runner FPC** (não no shared).
   No Delphi tipo diferente pode passar por alargamento nativo; testar
   "levanta OU converte" não vale nada. Essa foi a auto-correção do
   arquiteto na volta 2 do relatório e permanece.

4. **Armadilha de nome `TValueOps`** documentada explicitamente no ADR
   (D-10) e no ESP (restrições): proibido introduzir terceira unit
   fazendo `uses` das duas `ModernSyntax.RTTI.Delphi/FPC`.

## O que continua não medido, sem suavizar

Frase do relatório copiada literal para o ESP (critério de aceitação)
e para o corpo do PR (task-input): *"assumido pelo padrão do repo que
`TValueOps` como record com `class function ... static` genérico
compila no Delphi 12; primeira coisa a confirmar no build Delphi do
ciclo de implementação"*. Evidência forte por analogia (6 casos em
`Source/`), mas evidência por analogia não é medição.

## Cross-links

- [pipeline-esp](pipeline-esp.md)
- [pipeline-adr](pipeline-adr.md)
- [pipeline-plan](pipeline-plan.md)
- [pipeline-task-input](pipeline-task-input.md)
- [API-MAP §§2, 7](../../../strategy/2026-08-27-modernrtti/API-MAP.md)
- [SKILL](../../../SKILL.md)
