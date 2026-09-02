---
type: cycle-report
kind: report
title: "REPORT-release — ciclo 021: Attributes nil-handle guard (issue #56)"
description: "Ciclo 021 entregou guarda de nil em PropAttributes, uniformizacao dos cinco blocos e sexto bloco no cenario compartilhado; todos os tres gates de qualidade aprovados."
cycle: "021"
agent: release
workflow: equipe-bug
node: closing-record
resource: aefos://run/09743779c7c9860b5fa380f6979d94ca
tags: [release, cycle-021, issue-56, nil-handle, modernrtti, attributes]
generated:
  by: "equipe-bug@node:closing-record"
  at: "2026-09-02T18:00:00Z"
---

# REPORT-release — ciclo 021

## O que este ciclo entregou

O ciclo 021 corrigiu o defeito residual da issue #56: `TModernRTTIType.Attributes`
devolvia vazio silenciosamente quando `FType = nil`, tornando o resultado
indistinguivel de "o tipo nao tem atributos". O contrato de nil-handle
estabelecido pela #49 (PR #55) nao havia sido aplicado a `PropAttributes`.

Tres mudancas coesas num commit unico:

1. **Guarda em `PropAttributes`** — `if FType = nil then raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['Attributes'])` inserida como primeira instrucao do corpo, antes do comentario `// Issue #27:`. O ramo `else Result := nil` (vazio legitimo para nao-classe) permanece intacto.

2. **Uniformizacao dos cinco blocos existentes** em `Scenario_NilHandle_AllMembers_Raises` — padrao `Pos(...)` substituido por igualdade estrita (`LMsg <> Format(SModernRTTINilHandle, [...])`) e mensagens de `Fail` padronizadas.

3. **Sexto bloco (`Attributes`)** inserido no cenario compartilhado apos o quinto bloco, reutilizando `LRaised` e `LMsg` ja declaradas no escopo.

Um ajuste tecnico necessario: `SModernRTTINilHandle` foi promovida de `implementation` para `interface` para que o cenario compartilhado pudesse referenciar o simbolo diretamente (exigido pelo padrao de igualdade estrita do ADR). A string nao foi criada — existia em linha 892; apenas sua visibilidade mudou. XMLDoc explica a razao no proprio arquivo. Registrado em [FLOW-FEEDBACK.md](FLOW-FEEDBACK.md).

## Ramo de trabalho

- **Branch:** `aefos/cycle-09743779-maestro-repo-isaquepinheiro-modernsyntax`
- **Base:** `main`

## Tres verdicts de qualidade

| Gate | Veredicto | Fonte |
|------|-----------|-------|
| verify | PASSED — 42 testes / 0 falhas / 0 erros, FPC 3.2.2 x86_64 | [verify-report](pipeline-verify-report.md) |
| test | APPROVED — todos os seis criterios de aceite atendidos | [test-report](pipeline-test-report.md) |
| review | APROVADO — nenhuma critica bloqueante | [review-report](pipeline-review-report.md) |

A unica observacao nao-bloqueante (promocao de `SModernRTTINilHandle`) foi
documentada e nao altera o veredicto.

## Fronteira de cobertura

O ciclo cobre FPC 3.2.2 x86_64 (fabrica). FPC i386, Delphi Win32 e Delphi
Win64 ficam com o mantenedor — padrao herdado da serie #43–#49 (D-56.6).
O committer declara essa fronteira explicitamente no corpo do PR.

## Notas para o committer

- Mensagem de commit sugerida esta em [pipeline-plan.md](pipeline-plan.md) (secao "Commit — mensagem sugerida").
- O texto do marcador em `project-evolution.md` menciona "nenhuma resourcestring nova" — tecnicamente correto quanto a criacao, mas omite a promocao ao interface; o committer pode complementar no PR (observacao 5.2 do review-report, nao-bloqueante).
- `Closes #56` deve constar no corpo do PR.
