---
type: retrospective
kind: report
title: "Retrospective — ModernSyntax.Callback (ciclo 004, issue #7)"
description: "Ciclo 004 completou sem reworks nos quality gates; dois bloqueios de infraestrutura (SKILL.md ausente, token sem read:project) impediram movimentação automática de card no ProjectV2."
cycle: "004"
agent: retrospective
workflow: equipe-feature
node: retrospective
resource: aefos://run/24c962dcc2be1819336ca1fea18ae949
generated:
  by: "equipe-feature@node:retrospective"
  at: "2026-08-28T17:00:00Z"
tags: [retrospective, cycle-004, callbacks, modernrtti, issue-7, flow-feedback]
---

# Retrospective — ciclo 004

## Status geral

Todos os nós do pipeline produziram relatório neste ciclo:
`REPORT-planner.md`, `REPORT-architect.md`, `REPORT-developer.md`,
`REPORT-quality-review.md`, `REPORT-quality-test.md`,
`REPORT-quality-verify.md`, `REPORT-release.md`.

**Nenhum nó falhou ou foi bloqueado.** O build não foi dividido (não há
`split-proposal.md`). O ciclo chegou ao committer e o PR foi aberto:
<https://github.com/isaquepinheiro/ModernSyntax/pull/18>.

## Iterações por lens

| Lens | Rejeições / Reworks | Resultado final |
|------|---------------------|-----------------|
| review | 0 | APROVADO |
| test | 0 | PASSED |
| verify | 0 | PASSED |

**Clean pass em todos os quality gates. Zero reworks. Custo de rework: nulo.**

## Bloqueios de infraestrutura (não são reworks — causa: `env`)

O ciclo registrou dois bloqueios ambientais no [FLOW-FEEDBACK.md](FLOW-FEEDBACK.md),
reportados pelo nó `task` (planner):

### B-1 — `.project/SKILL.md` ausente

- **cause:** `env`
- **node_blamed:** `task` (planner ao chamar `aefos_gh_move_card` /
  `aefos_gh_find_item_id`)
- **impacto:** toda chamada `aefos_gh_*` termina imediatamente com
  `error: .project/SKILL.md not found`; movimentação de card no
  ProjectV2 impossível pelo caminho oficial.

### B-2 — token GitHub sem scope `read:project`

- **cause:** `env`
- **node_blamed:** `task` (fallback via `gh api graphql` também falhou:
  `INSUFFICIENT_SCOPES` — token tem `read:user`, `repo`, `workflow`
  mas não `read:project`)
- **impacto:** fallback via CLI também inoperante; card teve de ser
  movido manualmente.

Estes bloqueios não geraram reworks de implement → review → test → verify
e, portanto, não tiveram custo de ciclo adicional. São problemas de
configuração de ambiente que afetam apenas a automação do board.

## Causa dominante

`env` — a ausência de `SKILL.md` e o scope de token insuficiente são
condições de ambiente, não falhas de modelo ou especificação. Não há
indicação de que um modelo mais forte teria contornado nenhum dos dois.
A alavanca corretiva é de **infra/processo**, não de LLM.

## Divergência formal documentada (não é bloqueio)

O método factory foi declarado `&Of` em lugar de `Of` (ADR D-A3) porque
`of` é palavra reservada em Pascal. A divergência foi classificada como
inevitável pelos três nós de quality (review → O-2; test → seção 5;
verify → DT-1) e aceita sem rework.

## PR aberto neste ciclo

PR <https://github.com/isaquepinheiro/ModernSyntax/pull/18> foi aberto
pelo committer. Uma seção **"## Rework analysis"** pertenceria ao corpo
desse PR, mas este relatório não altera o PR (o committer já encerrou o
ciclo); a análise vive aqui.

O PR body deve conter a declaração honesta sobre i386 e Delphi
recomendada em [REPORT-quality-review.md](REPORT-quality-review.md)
(observação O-1) e mencionar a fuga `&Of` (O-2). O merge humano aguarda
confirmação do autor sobre i386 e Delphi.

## Recomendação única (sugestão ao humano)

**Criar `.project/SKILL.md` com os IDs do ProjectV2 e regenerar o token
com scope `project` (leitura + escrita) antes do próximo ciclo.**

Sem `SKILL.md`, qualquer nó que precise mover um card falha
silenciosamente; sem o scope `project` no token, o fallback CLI também
falha. Os dois problemas somados tornam a automação do board totalmente
inoperante, exigindo intervenção manual em todo ciclo. A correção é
pontual e elimina a classe inteira de bloqueios B-1/B-2 documentados no
[FLOW-FEEDBACK.md](FLOW-FEEDBACK.md).
