---
type: cycle-report
kind: report
cycle: "002"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/fa369bfebcbab23d74f445cede226eb0
title: "Cycle 002 — architect report (Pilar 1 da ModernRTTI)"
description: "Desenho da unit ModernSyntax.RTTI: superficie fechada, ramificacao com {$IFDEF FPC} direto, deteccao de ausencia de {$M+} no FPC; scope = fits."
tags: [architect, modernrtti, pilar-1, issue-8, cycle-002]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-28T00:50:00Z"
---

# Architect report — cycle 002

Issue tratada: [isaquepinheiro/ModernSyntax#8 — Pilar 1 da ModernRTTI].
Investigation report: **NONE** (o issue chegou a fabrica sem
investigacao; o ADR foi decidido neste ciclo, dentro do quadro ja
fixado pelo PRD e pelo Study).

## Artefatos produzidos

- [esp](pipeline-esp.md) — objetivo, escopo, regras, criterios,
  restricoes e riscos.
- [adr](pipeline-adr.md) — nove decisoes (D-A1 a D-A9), com
  alternativas descartadas.
- [plan](pipeline-plan.md) — tres fatias: tipos+GetProperties;
  fields; projeto Lazarus.
- [task-input](pipeline-task-input.md) — checklist e arquivos
  impactados.

## Decisoes-chave

- **Unit nova**, superficie fechada em `ModernSyntax.RTTI` — nao
  estende `TModernObject.Factory` (D5 do PRD, D-A1 do ADR).
- **`{$IFDEF FPC}` direto**, sem `{$I ModernSyntax.inc}`, para nao
  herdar o bug `{$IFDEF FCP}` de `ModernSyntax.inc:256` (R3 do PRD,
  D-A2).
- **Wrapper records** (nao classes/interfaces) mantem o padrao de
  valor-tipo do resto da biblioteca (D-A4).
- **Deteccao de `{$M+}` ausente no FPC** por heuristica que combina
  `TypInfo.PropCount` ao longo da hierarquia com o retorno do
  `TRttiContext.GetType.GetProperties`; nunca devolve lista vazia
  silenciosa (R4 do PRD, D-A5).
- **Fatia 3** cobre o `.lpi` dos testes com fallback: reusa o da
  issue #7 (callbacks) se existir; caso contrario cria um minimo.

## Scope estimate

`fits`. TEST 1 (SIZE): uma unit, tres wrappers, um erro dedicado,
uma suite DUnitX e um `.lpi` minimo — cabe folgado em um implement
budget. TEST 2 (INDEPENDENCE): property/field/tests so fazem sentido
juntos como leitura de RTTI; nao ha duas fatias mergeaveis sozinhas.
Nao ha `split-proposal.md`.

## Referencias

- PRD: `../../strategy/2026-08-27-modernrtti/PRD.md`
- Study: `../../strategy/2026-08-27-modernrtti/STUDY.md`
- Arquitetura: `../../analysis/03-architecture.md`
