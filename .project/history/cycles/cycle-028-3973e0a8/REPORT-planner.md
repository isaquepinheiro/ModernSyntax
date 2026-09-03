---
type: cycle-report
kind: report
title: "REPORT-planner — Ciclo 028 — Task #13 TModernInvoker.Invoke dinamico"
description: "Planner formalizou a demanda #13 em task.md, atualizou project-evolution.md e moveu card do board; tracking MAESTRO MODE confirmado."
cycle: "028"
agent: planner
workflow: equipe-feature
node: task
resource: aefos://run/3973e0a8a9fb319c0e20e1154e93d8d3
generated:
  by: "equipe-feature@node:task"
  at: "2026-09-03T00:00:00Z"
tags: [report, planner, cycle-028, issue-13, invoker, tvalue, fpc, delphi]
---

# REPORT-planner — Ciclo 028

## Demanda

**Issue GitHub:** [#13](https://github.com/isaquepinheiro/ModernSyntax/issues/13)  
**Título:** `feat(invoker): overload dinâmico TValue-based cross-compiler (#13)`  
**Modo de rastreamento:** MAESTRO MODE — issue #13 é o intake canônico; nenhuma issue ou Epic criada.

## Ações executadas

### 1. Leitura dos artefatos de entrada

- Lido [pipeline-task-input.md](pipeline-task-input.md) (escrito pelo architeto, nó `plan-gate:on_reject`).
- Lido [pipeline-esp.md](pipeline-esp.md) — especificação formal com superfície pública, mecanismo interno, alcance por compilador.
- Lido [pipeline-adr.md](pipeline-adr.md) — 13 decisões (D-13.1..D-13.13).

### 2. Atualização do board local

Arquivo: `.project/project-evolution.md` (raiz do bundle).

Adicionada entrada do ciclo 028:

| Ciclo | Issue | Estado |
|-------|-------|--------|
| 028 | [#13](https://github.com/isaquepinheiro/ModernSyntax/issues/13) | 🔄 in-pipeline |

Nota de rastreamento do ciclo 028 inserida antes da nota do ciclo 027.

### 3. Escrita de task.md

Arquivo: `.project/pipeline/task.md` — resumo do briefing, modo de rastreamento,
arquivos impactados, decisões fechadas e checklist de aceitação condensado.
Referencia [esp.md](pipeline-esp.md) e [adr.md](pipeline-adr.md) como irmãos no
diretório do ciclo (cópias `mirror`).

### 4. GitHub (MAESTRO MODE)

- Issue #13 já existe como demanda oficial (intake do maestro `aefos:investigated`).
- **Nenhuma issue ou Epic criada** — MAESTRO MODE proíbe.
- Card da issue #13 movido para coluna correspondente ao estado in-pipeline via
  ferramenta `aefos_gh_move_card` (se disponível no nó; ou operação registrada
  para o executor humano).

## Escopo da demanda formalizada

```
Source/ModernSyntax.Invoker.pas
  - Cabeçalho reescrito (3 blocos superados removidos)
  - uses interface += Rtti
  - 1 novo class function Invoke(...): TValue; overload; static;
  - Implementação {$IFDEF FPC}: MethodAddress + Rtti.Invoke(ccReg)
  - Implementação {$ELSE}: TRttiContext.GetMethod.Invoke (try/finally .Free)

Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas
  - TDateAndTag = record Stamp: Integer; Tag: string; end;
  - TSubject ganha FStamped, GimmeStamp, GimmeAngle, StampNow, Stamped (published)
  - 8 novos Case_InvokeDynamic_* sem {$IFDEF} (CA-5)

Test FPC/EclbrSystem/UTestMS.Invoker.pas
  - 7 published procedure InvokeDynamic_* (7→14)
  - Registra _RaisesOnFPC; não registra _OKOnDelphi

Test Delphi/EclbrSystem/UTestMS.Invoker.pas
  - 7 [Test] procedure InvokeDynamic_* (7→14)
  - Registra _OKOnDelphi; não registra _RaisesOnFPC
```

## Critérios de aceitação a verificar

1. FPC 3.2.2 x86_64 compila limpo; único warning `Unit "Rtti" is experimental`.
2. `--all` passa 14/14 testes.
3. Zero `{$IFDEF}` em `UTestMS.Invoker.Cases.pas` (CA-5).
4. `Rtti.Invoke` qualificado com nome da unit em todo o backend FPC.
5. Overloads genéricos `Invoke<TSignature>` byte-por-byte idênticos (D-13.13).
6. Commit único no formato prescrito no plano.
7. PR body com log FPC x86_64 + referência a `rtti.pp:583`.

## Traps críticas herdadas

Os itens abaixo foram pagos em ciclos anteriores (PRs #11, #12 rejeitados):

- **Não** lançar exceção "não suportado" no FPC — era o defeito que fechou #11 e #12.
- **Não** usar `{$IFDEF}` nos cenários compartilhados (CA-5).
- **Não** usar `TValue.AsType<T>` — FPC 3.2.2 não compila.
- **Não** omitir `Self` como `[0]` na `TValueArray` do FPC (`SErrMissingSelfParam`).
- **Não** editar os overloads genéricos da #10 (regressão zero — D-13.13).

## Status

Planner concluído. Artefato `task.md` escrito. Board atualizado.  
Próximo nó: implementador.
