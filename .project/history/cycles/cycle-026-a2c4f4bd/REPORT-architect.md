---
type: cycle-report
kind: report
title: "REPORT-architect — Ciclo 026 (issue #66)"
description: "Arquitetura da correcao documental de RTTI.pas:161-167: remarks falso corrigido, assimetria descrita estruturalmente, citacao de ADR alinhada em :987-990."
cycle: "026"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/a2c4f4bd7a43e634bf43104b21a56468
generated:
  by: "equipe-bug@node:architect"
  at: "2026-09-02T00:00:00Z"
tags: [report, architect, rtti, xmldoc, documentation, bug, issue-66, modernrtti, cycle-026]
---

# REPORT-architect — Ciclo 026 / Issue #66

## O que foi decidido

Este ciclo produz os quatro artefatos de pipeline para a issue #66:
[esp](pipeline-esp.md), [adr](pipeline-adr.md), [plan](pipeline-plan.md),
[task-input](pipeline-task-input.md).

A demanda é **exclusivamente documental**: 2 edições em 1 arquivo
(`Source/ModernSyntax.RTTI.pas`), zero linhas executáveis, nenhum teste novo.

### Diagnóstico

O PR #65 (issue #60, ciclo 025) inseriu `else raise EModernRTTIError` no
`PropertyVisibility` do backend FPC (`RTTI.FPC.pas:505-507`). O bloco `<remarks>`
de `TModernRTTIProperty.Visibility` em `RTTI.pas:161-167` — não tocado pelo PR #65 —
continuou afirmando "aqui NAO ha raise no FPC", criando contradição com
`RTTI.pas:79-81` (editado pelo #65) dentro da mesma `interface` pública.

**Causa raiz:** ponto cego de varredura — `RTTI.pas:163` não cita número de issue nem
palavra-chave de exaustividade; grep por `#60` ou `exaustividade` a ignora. Gatilho
correto: quando um backend ganha um `raise` novo, varrer a casca por afirmações de
**ausência** (`NAO ha raise`, `nao levanta`, `nunca levanta`, `sem raise`).

### Decisões principais (derivadas da investigação run `815396d406c2e93390d527508f06e778`)

| ID | Decisão |
|----|---------|
| D-66.1 | Citação canônica `D-42.2/D-51.1/D-60.1 do ADR issues #42/#51/#60` (barra, sem colchetes, nome das issues uma vez só ao final). |
| D-66.2 | `<remarks>` descreve assimetria estruturalmente: Method levanta SEMPRE no FPC; Property levanta APENAS no ramo `else`, inalcançável com `TMemberVisibility` atual (`rtti.pp:308`). Sem `SFPCNoVisibility`. |
| D-66.3 | Âncora `rtti.pp:308` permitida no header público — precedente em `:157`, `:280`, `:335`. |
| D-66.4 | Um único commit para as duas edições (`:161-167` bloqueante + `:987-990` free-ride). |
| D-66.5 | Varredura em `Source/` inteira; achados fora do escopo desta issue vão no PR como "Achado — nova issue", não no diff. |

### Convenção nova registrada

**Gatilho de varredura por afirmação de ausência:** sempre que um backend ganha um
`raise` novo, varrer a casca pública por `NAO ha raise`, `nao levanta`, `nunca levanta`,
`sem raise`. Registrada no [adr](pipeline-adr.md) para ciclos futuros.

## Scope verdict

`fits` — 2 substituições em comentários, 1 arquivo, 1 commit. Custo estimado < $2.
As duas edições não são independentes (reverter uma deixa a citação de ADR incoerente),
logo o teste de independência não é satisfeito; split não aplicável.

## O que NÃO muda

Backends (`RTTI.FPC.pas`, `RTTI.Delphi.pas`), assinaturas, `<summary>` de `:155-160`,
header da unit (`:19-21`), suite de testes (contagem FPC permanece 42).

## Pré-condição para o implementador

Mergear o PR #65 antes de abrir o PR desta issue — os dois tocam `RTTI.pas` e conflitam
sem o merge.
