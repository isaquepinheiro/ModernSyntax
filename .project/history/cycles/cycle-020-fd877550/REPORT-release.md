---
type: cycle-report
kind: report
title: "REPORT-release — cycle 020: nil-handle contract em TModernRTTIType (issue #49)"
description: "Cycle 020 entregou o contrato de handle nil nos cinco membros publicos de TModernRTTIType; todos os tres gates de qualidade aprovados; branch pronta para commit."
cycle: "020"
agent: release
workflow: equipe-bug
node: closing-record
resource: aefos://run/fd87755097391831d283adc83e6b8813
tags: [release, nil-handle, issue-49, modernrtti, cycle-020]
generated:
  by: "equipe-bug@node:closing-record"
  at: "2026-09-02T00:00:00Z"
---

# REPORT-release — cycle 020 (issue #49)

## O que este ciclo entregou

A issue [#49](https://github.com/isaquepinheiro/ModernSyntax/issues/49) exigia que
cinco membros públicos de `TModernRTTIType` (`Name`, `GetProperties`, `GetFields`,
`GetMethods`, `GetMethod`) levantassem `EModernRTTIError` com mensagem padronizada
sempre que o handle interno `FType` fosse `nil`, eliminando o risco de
`EAccessViolation` silencioso na API pública.

Este ciclo implementou exatamente isso: uma nova `resourcestring SModernRTTINilHandle`
com placeholder `%s` para o nome do membro; cinco guardas idênticas `if FType = nil then`
inseridas como primeira instrução de cada membro; e cinco blocos XMLDoc `<remarks>`
nas declarações de interface correspondentes.

A guarda em `GetFields` foi posicionada antes do check `is TRttiInstanceType`,
preservando o contrato pré-existente de retorno `nil` silencioso para handles válidos
de records e enums (decisão ADR D-49.4).

A dívida técnica D-44.6 foi desbloqueada: `Scenario_PointerType_ReferredType_Nil_ForBarePointer`
agora afirma `EModernRTTIError` em `LReferred.Name` em vez de suprimir o acesso.

O cenário compartilhado `Scenario_NilHandle_AllMembers_Raises` cobre os cinco membros
via caminho público (`TModernRTTIContext.Create` + `FindType`), com verificação da
mensagem por `Pos`. Duas cascas de uma linha cada (FPC e Delphi) registram o cenário
nos respectivos runners. A contagem FPCUnit passou de 41 para 42 testes.

## Branch e base

- **Branch de trabalho:** `aefos/cycle-fd877550-maestro-repo-isaquepinheiro-modernsyntax`
- **Base:** `main`

## Três verdicts de qualidade

| Gate | Agente | Veredicto |
|------|--------|-----------|
| Review | quality / node:review | **APROVADO** — todos os critérios do ESP §4 atendidos; zero problemas críticos. Ver [REPORT-quality-review.md](REPORT-quality-review.md). |
| Test | quality / node:test | **APPROVED** — 9/9 critérios verificáveis por análise estática passaram; AC-10 (CI build) delegado ao gate de CI. Ver [REPORT-quality-test.md](REPORT-quality-test.md). |
| Verify | quality / node:verify | **PASSED** — FPC 3.2.2 x86_64: 42/42 testes verdes, 0 erros, 0 falhas; análise estrutural confirmou 5 guardas, 6 usos de `SModernRTTINilHandle`, XMLDoc e D-44.6 desbloqueada. Ver [REPORT-quality-verify.md](REPORT-quality-verify.md). |

## Itens pendentes ao autor humano

- Declarar resultados de i386 e Delphi no corpo do PR antes do merge
  (compiladores ausentes na fábrica AEFOS, conforme SKILL.md).
- O PR deve fechar com `Closes #49`.

## Fontes

- [REPORT-architect.md](REPORT-architect.md)
- [REPORT-planner.md](REPORT-planner.md)
- [REPORT-developer.md](REPORT-developer.md)
- [REPORT-quality-review.md](REPORT-quality-review.md)
- [REPORT-quality-test.md](REPORT-quality-test.md)
- [REPORT-quality-verify.md](REPORT-quality-verify.md)
- [pipeline-plan.md](pipeline-plan.md)
- [pipeline-task.md](pipeline-task.md)
