---
type: cycle-report
kind: report
title: "REPORT-architect — cycle-023 — issue #57: quatro residuos dos ciclos #45/#46"
description: "Arquiteto produziu esp/adr/plan/task-input para correcao de quatro residuos cirurgicos em dois arquivos; item 3 reclassificado de cosmetico para cobertura ausente apos medicao de mutacao."
status: stable
cycle: "023"
agent: architect
workflow: equipe-chore
node: architect
resource: aefos://run/fdf49836e67b5746f5350a3fb741afd3
tags: [rtti, chore, issue-57, cycle-023, architect-report]
generated:
  by: "equipe-chore@node:architect"
  at: "2026-09-02T00:00:00Z"
---

# REPORT-architect — Cycle 023 — Issue #57

## O que foi feito

Produzidos os quatro artefatos de pipeline para a issue #57:

- [esp](pipeline-esp.md) — especificacao formal com escopo, BR, criterios de
  aceitacao e riscos derivados da issue.
- [adr](pipeline-adr.md) — seis decisoes derivadas do relatorio de investigacao
  (run `1daaaf49674847d8b1dfce5ce677b694`, PRESENT).
- [plan](pipeline-plan.md) — plano de slice unico: quatro passos cirurgicos (A/B/C/D)
  em dois arquivos, um commit.
- [task-input](pipeline-task-input.md) — handoff operacional com checklist de
  acceptance e restricoes explicitas.

## Decisoes de design

### Escopo: `fits`

Quatro mudancas de texto/assercao em dois arquivos; nenhuma toca comportamento de
producao. O item 3 ganhou uma linha nova (assercao de identidade), mas a demanda
inteira cabe em um commit e em um ciclo de implementacao.

### Item 3 reclassificado: de cosmetico para cobertura ausente

O arquiteto mediu a mutacao `GetTypeData(P)^.ArrayData.ElType => P` em
`RTTI.FPC.pas:686` antes de abrir este ciclo. Resultado: a suite passa VERDE nos
dois bitness com codigo errado — o `IsNil` engole qualquer handle nao-nulo.
A correcao deixou de ser alinhamento estetico e virou prova de identidade.
Acceptance nova: log de mutacao matando nos dois bitness anexado ao PR.

### D-57.2 — par IsNil + identidade (reverteu Volta 1)

A Volta 1 propunha descartar `IsNil` como redundante. A Volta 2 reverteu:
o vizinho `Scenario_PointerType_ReferredType_Matches:1256-1259` mantem os dois;
a pre-condicao da mensagem melhor quando o handle vem nulo.

### D-57.3 — TypeInfo(Integer) via referencia, nao literal

FPC 3.2.2 devolve `LongInt`; Delphi devolve `Integer`. Literal quebra num lado;
a forma por referencia via `TModernRTTI.GetType` absorve nos dois. Registrado no
ADR deste ciclo (nao em `cycle-019/pipeline-adr.md` — D-42.2 proibe editar ADR
de ciclo anterior).

### D-57.1 — remover comentario, nao adicionar Result := 0

Compilador nao pediu (`main 4a2a606`, 0 erros/0 warnings, 16/16 unidades).
Adicionar seria codigo morto — e simetria estetica foi exatamente o que produziu
o comentario falso.

## Artefatos produzidos

| Arquivo | Tipo |
|---------|------|
| `.project/pipeline/esp.md` | spec |
| `.project/pipeline/adr.md` | adr |
| `.project/pipeline/plan.md` | plan |
| `.project/pipeline/task-input.md` | task-input |

## Riscos residuais

**R-1:** a assercao nova do item 3 pode revelar defeito real no backend se ele
devolver handle errado para `Integer`. Nao e regressao introduzida pelo PR — e
defeito preexistente mascarado pela assercao fraca. A acceptance exige investigar
antes de fechar.
