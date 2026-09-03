---
type: rejection
kind: rejection
title: "Rejection verify — Ciclo 028 — 8a execucao — BLOCKED (env: Rtti.Invoke nao implementado em FPC 3.2.2 Linux)"
description: "8a rejeicao verify no ciclo 028. Compilacao limpa (0 erros). Suite 10/14: 4 ENotImplemented da RTL. Codigo correto. Nenhuma acao disponivel ao implement. Escalacao humana obrigatoria."
cycle: "028"
agent: quality
workflow: equipe-feature
node: verify
resource: "aefos://run/3973e0a8a9fb319c0e20e1154e93d8d3"
generated:
  by: "equipe-feature@node:verify"
  at: "2026-09-03T16:10:00Z"
cause: env
node_blamed: architect
tags: [rejection, verify, blocked, anti-loop, fpc, rtti, env, cycle-028, issue-13, loop-8]
---

# Rejection — verify — Ciclo 028 (8a execucao, BLOCKED)

## Veredicto: FAILED

**Causa:** `env` | **Node_blamed:** `architect`

Esta e a **oitava** rejeicao do verify no ciclo 028 para a mesma causa.
Anti-loop BLOCKED. **Pipeline em estado de impasse — escalacao humana obrigatoria.**

## Resultado da verificacao

| Gate | Resultado |
|---|---|
| Compilacao FPC x86_64 | OK 0 erros, 0 warnings |
| Suite FPCUnit | FAIL 10/14 (4 ENotImplemented) |
| Complexidade | TOOL_MISSING (trivialmente OK por inspecao) |

## Raiz do problema

`Rtti.Invoke` livre nao esta implementado em FPC 3.2.2 para `x86_64-linux` (SysV ABI).
Qualquer teste que invoca o backend FPC dinamico cai em `ENotImplemented` da RTL.
O codigo da feature esta correto; o bloqueio e externo ao repositorio.

Ver [SKILL.md](../../../SKILL.md) secao
*"Rtti.Invoke livre nao esta implementado em FPC 3.2.2 x86_64-linux"*.

## O codigo do developer NAO deve ser alterado

Todas as tres lentes de qualidade (review, verify, test) confirmaram nas iteracoes
anteriores: D-13.1..D-13.13 todos cumpridos. Editar o Pascal seria introduzir
divergencia do plano por motivo nao-tecnico.

## Opcoes para o humano

- **A** — architect qualifica AC-10 por OS (recomendada).
- **B** — humano aceita 10/14 na fabrica; PR carrega nota declarativa.
- **C** — humano provisiona ambiente com `SystemInvoke` para SysV AMD64.

Ver [FLOW-FEEDBACK](FLOW-FEEDBACK.md) para contexto acumulado das 8 iteracoes.
