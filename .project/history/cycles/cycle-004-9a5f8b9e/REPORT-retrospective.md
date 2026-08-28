---
type: retrospective
kind: report
title: "Retrospective — Pilar 1 da ModernRTTI (cycle 004, issue #8)"
description: "Ciclo limpo, zero reworks, três lentes aprovadas; duas fricções de pipeline documentadas pelo developer para ajuste futuro."
cycle: "004"
agent: retrospective
workflow: equipe-feature
node: retrospective
resource: aefos://run/9a5f8b9e974c23d88b7b6aba11e2973d
tags: [retrospective, cycle-004, modernrtti, pilar-1, issue-8]
generated:
  by: "equipe-feature@node:retrospective"
  at: "2026-08-28T16:30:00Z"
---

# Retrospective — Pilar 1 da ModernRTTI (cycle 004)

## Ciclo completado sem reworks

Todas as etapas do workflow `equipe-feature` completaram em ordem:
`architect → planner → developer (implement) → quality-verify → quality-review → quality-test → release`.

Nenhuma das três lentes de qualidade rejeitou o ciclo. **Zero reworks. Zero iterações extras.**

| Lens | Iterações | Veredicto |
|------|-----------|-----------|
| verify | 1 (aprovado na primeira passagem) | APPROVED |
| review | 1 (aprovado na primeira passagem) | APPROVED |
| test | 1 (aprovado na primeira passagem) | APPROVED |

**Custo de rework: zero.** Não há loop `implement → verify → review → test` extra para reportar.

## PR do ciclo

PR aberto pelo committer: https://github.com/isaquepinheiro/ModernSyntax/pull/17

A secção **## Rework analysis** pertenceria ao corpo do PR — mas, tendo o committer já fechado o ciclo, ela vive aqui. Não há reworks a analisar: o PR foi entregue limpo.

## Fricções de pipeline (sem rework, mas com sinal de melhoria)

Embora o ciclo tenha sido limpo, o node `implement` produziu um [FLOW-FEEDBACK.md](FLOW-FEEDBACK.md) com três fricções de processo observadas durante a execução. Elas não causaram rejeição, mas representam risco latente para ciclos futuros da mesma família (Pilar 2, Pilar 3):

### Fricção 1 — Drift silencioso de contagens absolutas no plan/esp

O [esp](pipeline-esp.md) e o [plan](pipeline-plan.md) citavam contagens absolutas (`groupproj` "13 → 14"). Na execução, a base real tinha 12 entradas, não 13 — alguém havia removido um projeto entre a autoria dos artefatos e a execução. O implementador resolveu pela intenção ("+1 entrada"), mas o ambiguity foi detectado manualmente.

**Causa:** `spec` (especificação com baseline desatualizado).
**Node blamed:** `planner` / `architect` (autores do plan e do esp).

### Fricção 2 — Regra CA-5 em conflito com requisito de mode selection do FPC

O plan exigia "zero `{$IFDEF}`" nos arquivos de teste compartilhados, mas FPC 3.2.2 exige `{$mode delphi}` para aceitar a sintaxe de generics usada pelos próprios cenários (CA-3). O implementador resolveu com `{$IFDEF FPC_FULLVERSION}` — decisão de padrão de biblioteca que normalmente compete ao arquiteto, não ao developer. A decisão está pendente de ratificação antes do Pilar 2.

**Causa:** `spec` (regra CA-5 não considera a restrição do compilador FPC).
**Node blamed:** `architect` (decisão de convenção cross-compiler não foi tomada no ADR antes do ciclo).

### Fricção 3 — Dependência #7 não verificada automaticamente

O task-input declarava "assume #7 já mergeou". Na execução, #7 estava aberta. O fallback estava documentado e foi aplicado corretamente, mas a detecção foi manual. Um ciclo anterior (cycle-002, commit rejeitado `06fccea`) mostrou que implementadores sem esse contexto inventam artefatos (`.lpi`) incorretamente.

**Causa:** `flow` (ausência de passo automático de verificação de dependências antes do implement).
**Node blamed:** workflow `equipe-feature` (ausência de passo `check-dependencies`).

## Classificação de causas

| # | Causa | Node blamed | Impacto |
|---|-------|-------------|---------|
| F-1 | `spec` | planner/architect | Baixo neste ciclo; médio em cascatas de edição |
| F-2 | `spec` | architect | Médio — decisão de padrão adiada para o developer |
| F-3 | `flow` | equipe-feature workflow | Baixo neste ciclo; médio em ciclos futuros sem fallback documentado |

## Análise de custo

Como não houve reworks, não houve custo de loops extras. As fricções acima são **risco de rework futuro**, não rework atual.

A causa dominante nas fricções é `spec` (2 de 3): especificações com baselines desatualizados e regras incompatíveis com restrições do compilador. Isso aponta para um ajuste de **processo/design** (um fix de `spec`), não para um upgrade de modelo. Um modelo mais forte no node `implement` não teria evitado essas fricções — o arquiteto é quem detém a alavanca.

## Recomendação única

**Antes do Pilar 2 começar, o arquiteto deve registrar em ADR a decisão sobre mode selection em units compartilhadas cross-compiler (`{$IFDEF FPC_FULLVERSION}` vs. alternativas).**

O mesmo problema (`{$mode delphi}` obrigatório no FPC para generics) vai ocorrer em toda unit compartilhada da família ModernRTTI. Sem uma decisão registrada em ADR, cada ciclo futuro forçará o developer a re-decidir sozinho — o que é um risco de divergência e de violação silenciosa das convenções. A decisão custa minutos no node `architect`; sem ela, cada Pilar pagará uma fricção evitável.

## Cross-referências

- [REPORT-architect.md](REPORT-architect.md)
- [REPORT-planner.md](REPORT-planner.md)
- [REPORT-developer.md](REPORT-developer.md)
- [REPORT-quality-verify.md](REPORT-quality-verify.md)
- [REPORT-quality-review.md](REPORT-quality-review.md)
- [REPORT-quality-test.md](REPORT-quality-test.md)
- [REPORT-release.md](REPORT-release.md)
- [FLOW-FEEDBACK.md](FLOW-FEEDBACK.md)
