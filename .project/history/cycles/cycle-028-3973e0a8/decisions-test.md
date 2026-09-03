---
type: rejection
kind: rejection
title: "Rejeicao TEST — ciclo 028 — spec: AC-10 sem qualificacao de OS (decima rejeicao)"
description: "Suite FPC 10/14 na fabrica; 4 ENotImplemented RTL (SystemInvoke nao portado para SysV AMD64). Codigo correto. AC-10 continua sem qualificacao de OS. Ciclo BLOQUEADO ha 10 iteracoes; escalacao critica ao humano."
cycle: "028"
agent: quality
workflow: equipe-feature
node: test
resource: aefos://run/3973e0a8a9fb319c0e20e1154e93d8d3
generated:
  by: "equipe-feature@node:test"
  at: "2026-09-03T00:00:00Z"
tags: [rejection, quality, test, fpc, rtti, linux, spec, issue-13, cycle-028, blocked, iteration-10]
cause: spec
node_blamed: architect
---

# Nota de Rejeição — TEST lens — Ciclo 028 (10ª rejeição)

## Veredicto

**REJECTED** — causa `spec` — node blamed: `architect`

## Critério não satisfeito

**AC-10** ([pipeline-esp.md](pipeline-esp.md) §6): `PTestInvoker --all` deve
passar integralmente no FPC 3.2.2 x86_64.

Resultado obtido na fábrica `x86_64-linux`: **10/14** (4 `Error: ENotImplemented`).

## Resultado da execução (executado nesta entrada)

```
Time:00.000 N:14 E:4 F:0 I:0
  TInvokerTests Time:00.000 N:14 E:4 F:0 I:0
    InvokeDynamic_ReturnsRecordIntegerAndString  Error: ENotImplemented
      Exception: Invoke functionality is not implemented
    InvokeDynamic_ReturnsDouble                  Error: ENotImplemented
      Exception: Invoke functionality is not implemented
    InvokeDynamic_ReturnsManagedString           Error: ENotImplemented
      Exception: Invoke functionality is not implemented
    InvokeDynamic_ProcedureVoid_SideEffect       Error: ENotImplemented
      Exception: Invoke functionality is not implemented
```

## Causa raiz (inalterada desde a 1ª rejeição)

`SystemInvoke` em FPC 3.2.2 não está implementado para `x86_64-linux`
(SysV AMD64 ABI). Disponível apenas em `x86_64-win64` (Microsoft x64 ABI).
O dono mediu em Windows; a fábrica roda Linux.

O AC-10 da ESP tem dois problemas inalterados desde a 1ª rejeição:

1. **Contagem errada**: diz "13/13" mas o total real é 14
   (7 originais + 7 novos conforme breakdown do próprio ESP).
2. **Sem qualificação de OS**: "x86_64" sem OS não distingue
   `x86_64-linux` (fábrica) de `x86_64-win64` (onde funciona).

## Histórico de rejeições neste ciclo (node: test)

| Rejeição | Causa | AC-10 corrigido no spec? |
|----------|-------|--------------------------|
| 1ª | `env` | Não |
| 2ª | `spec` | Não |
| 3ª | `spec` | Não |
| 4ª | `spec` | Não |
| 5ª | `spec` | Não |
| 6ª | `spec` | Não |
| 7ª | `spec` | Não |
| 8ª | `spec` | Não |
| 9ª | `spec` | Não |
| **10ª (esta)** | **`spec`** | **Não** |

## O que NÃO é defeito

- **A implementação está correta.** D-13.1..D-13.13 todos honrados.
- **Todos os outros ACs passam** (compilação, guardas, portável, regressão zero).
- **Nenhuma alteração de código Pascal é necessária.**

## Opções para convergência (sem alteração de código)

- **Opção A (recomendada por todas as 3 lentes de qualidade):** architect atualiza
  AC-10 para qualificar por OS — fábrica prova compilação + guardas (10/14);
  invocação viva delegada ao autor (FPC Win64 e i386), análogo a D-13.12.
  Corrige também a contagem 13→14.
- **Opção B:** humano decide manter AC 14/14, bloqueando merge até FPC trunk/3.3.x
  ou cross-compiler Win64 na fábrica.
- **Opção C:** humano aceita 10/14 como verde e documenta o delta no PR body.

Ver [FLOW-FEEDBACK.md](FLOW-FEEDBACK.md) para histórico completo de achados
de pipeline (18+ entradas).
