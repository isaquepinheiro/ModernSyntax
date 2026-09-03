---
type: task
kind: artifact
title: "Task #6 — chore(docs): corrigir 10 itens de texto no bundle OKF"
description: "Aplicar 10 edicoes de texto em .project/analysis/ (numeros divergentes, ancoras fora do lugar); 1 commit; zero mudancas em Source/."
cycle: "026"
agent: planner
workflow: equipe-chore
node: task
resource: aefos://run/0ed0e9cf6250cee7ab26731ee07d3ccc
generated:
  by: "equipe-chore@node:task"
  at: "2026-09-02T00:00:00Z"
tags: [task, chore, okf, bundle, text-correction, issue-6, cycle-026]
---

# Task — Ciclo 026 / Issue #6

## Tracking

- **Modo:** MAESTRO MODE
- **Issue original:** [#6](https://github.com/isaquepinheiro/ModernSyntax/issues/6)
  (demanda criada pelo maestro — `aefos:investigated`)
- **Epic:** nenhum Epic criado (MAESTRO MODE — não criar Epic sem correspondência óbvia pré-existente)
- **Board local:** 🔄 in-pipeline

## Demanda em uma linha

Aplicar 10 correções de texto em `.project/analysis/` — números divergentes e âncoras
fora do lugar em 4 arquivos; 1 commit; zero mudanças em `Source/`.

## Arquivos impactados

| Arquivo | Itens |
|---------|-------|
| `.project/analysis/03-architecture.md` | 1, 2, 3, 7 |
| `.project/analysis/02-stack.md` | 4 |
| `.project/analysis/04-domain.md` | 5, 6, 9 |
| `.project/analysis/05-conventions.md` | 8, 10 |

Itens 11 e `.inc` → verificados, **sem edição**.

## Checklist de aceitação

- [ ] Varredura pré-edição: `grep -rn "593|597|1 581|14-variant|12.*INumeric|FError|Byte>" .project/analysis/`
- [ ] **03-architecture.md** — "17-variant enum, lines 32-50" (item 1)
- [ ] **03-architecture.md** — "17 _Matching* private methods" (item 2)
- [ ] **03-architecture.md** — "14 INumeric<T> implementors" nos dois sítios (item 3)
- [ ] **03-architecture.md** — FMatch descrito como class var escrita no início de Value() em Match.pas:242 (item 7)
- [ ] **02-stack.md** — TAsync em Async.pas:50; TScheduler/IScheduler em Coroutine.pas:173 (item 4)
- [ ] **04-domain.md** — FErr: String (não FError) (item 5)
- [ ] **04-domain.md** — TDictionary<T, Boolean> (não Byte) (item 6)
- [ ] **04-domain.md** — nota G-08 "has not been measured" nos dois sítios de deadlock (item 9)
- [ ] **05-conventions.md** — âncoras :581/_DestroySuccess, :622/Dispose, :666/_DestroyFailure + frase citando PR #7 (item 8)
- [ ] **05-conventions.md** — "→ 2 475 (medido 2026-09-02: grep -rc '///' Source/*.pas)" + nota 16→22 unidades (item 10)
- [ ] Varredura pós-edição retorna zero
- [ ] Nenhum arquivo em `Source/` modificado
- [ ] Commit único; mensagem registra itens 1..10 editados e itens 11+.inc como "verificado, não editado"

## Issues-companheiras (fora deste PR)

1. **Finding A** — `Map<R>` faz re-cast silencioso (`ResultPair.pas:832-844`); abrir após merge.
2. **Cadência de re-medição** — bundle fechou 27/08; `Source/` teve 8 PRs desde então; abrir após merge.

## Referências

- [task-input](pipeline-task-input.md)
- Investigação: run `0bc05ff9b241c9abcd326272568f1086`, issue #6 comentário
- Bundle: `.project/analysis/` (auditado 2026-08-27, três rodadas)
- PR #7 em `ResultPair.pas` — causou deslocamento das âncoras do item 8
