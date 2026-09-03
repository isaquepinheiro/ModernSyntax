---
type: cycle-report
kind: report
title: "REPORT quality-test — ciclo 028 — 10a entrada — REJECTED"
description: "10a rejeicao identica: suite FPC x86_64-linux 10/14 (ENotImplemented da RTL); AC-10 sem qualificacao de OS; codigo correto."
cycle: "028"
agent: quality
workflow: equipe-feature
node: test
resource: aefos://run/3973e0a8a9fb319c0e20e1154e93d8d3
generated:
  by: "equipe-feature@node:test"
  at: "2026-09-03T00:00:00Z"
tags: [report, quality, test, fpc, rtti, linux, spec, issue-13, cycle-028, iteration-10, blocked]
---

# REPORT — quality (test) — Ciclo 028 — 10ª entrada

## Veredicto

**REJECTED** — `cause: spec` — `node_blamed: architect`

## Resumo

Suite FPC 3.2.2 x86_64-linux: **10/14** (N:14 E:4 F:0).

4 falhas por `ENotImplemented: Invoke functionality is not implemented` —
todos os testes que atingem `Rtti.Invoke` livre (`rtti.pp:583`) em runtime.
`SystemInvoke` não está implementado para SysV AMD64 (Linux) no FPC 3.2.2.

## Artefatos revisados

- `Source/ModernSyntax.Invoker.pas` — overload dinâmico correto
- `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas` — 8 `Case_*` novos
- `Test FPC/EclbrSystem/UTestMS.Invoker.pas` — 14 `published procedure` (7+7)
- `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` — 14 `[Test]` (7+7)

Ver detalhe completo em [pipeline-test-report.md](pipeline-test-report.md)
e nota de rejeição em [decisions-test.md](decisions-test.md).

## Conformidade com D-13.x

D-13.1..D-13.13 todos honrados pelo implementer.
O AC não atendível é AC-10: falha de qualificação de OS no spec,
não de código Pascal.

## Histórico de rejeições neste ciclo (node: test)

| Entrada | Suite | Causa | AC-10 corrigido no spec? |
|---------|-------|-------|--------------------------|
| 1 | 10/14 | env | Não |
| 2-9 | 10/14 | spec | Não |
| **10 (esta)** | **10/14** | **spec** | **Não** |

## Opções para convergência (sem alteração de código Pascal)

- **Opção A (recomendada):** architect qualifica AC-10 por OS — fábrica prova
  compilação + guardas (10/14); invocação viva FPC delegada ao autor (Win64/i386),
  analogamente a D-13.12.
- **Opção B:** humano decide manter AC 14/14 (bloqueia merge até FPC trunk/3.3.x).
- **Opção C:** humano aceita 10/14 como verde e documenta delta no PR body.

**Nenhuma alteração de código é necessária.** O ciclo está BLOQUEADO aguardando
decisão externa (humano ou architect com direcionamento explícito).
