---
type: task-input
kind: artifact
title: "Task-input #6 — 10 correcoes de texto no bundle OKF"
description: "Handoff operacional para o implementador: 10 edicoes de texto em 4 arquivos de analise, 1 commit, sem toque em Source/."
cycle: "026"
agent: architect
workflow: equipe-chore
node: architect
resource: aefos://run/0ed0e9cf6250cee7ab26731ee07d3ccc
generated:
  by: "equipe-chore@node:architect"
  at: "2026-09-02T00:00:00Z"
tags: [task-input, okf, bundle, text-correction, chore, issue-6, cycle-026]
---

# Task-input #6 — 10 correções de texto no bundle OKF

## Titulo

chore(docs): corrigir 10 itens de texto no bundle OKF (#6)

## Tipo / labels

- `chore`
- `documentation`
- `okf`

## Escopo em uma linha

Aplicar 10 edições de texto em `.project/analysis/` (números divergentes,
âncoras fora do lugar); 1 commit; zero mudanças em `Source/`.

## Arquivos impactados

| Arquivo | Itens |
|---------|-------|
| `.project/analysis/03-architecture.md` | 1, 2, 3, 7 |
| `.project/analysis/02-stack.md` | 4 |
| `.project/analysis/04-domain.md` | 5, 6, 9 |
| `.project/analysis/05-conventions.md` | 8, 10 |

Itens 11 e `.inc` → verificados, **sem edição**.

## Checklist de aceitação

- [ ] Rodar varredura antes de iniciar:
      `grep -rn "593|597|1 581|14-variant|12.*INumeric|FError|Byte>" .project/analysis/`
- [ ] **03-architecture.md** — "17-variant enum, lines 32-50" (item 1)
- [ ] **03-architecture.md** — "17 _Matching* private methods" (item 2)
- [ ] **03-architecture.md** — "14 INumeric<T> implementors" nos dois sitios (item 3)
- [ ] **03-architecture.md** — FMatch descrito como class var escrita no inicio de Value() em Match.pas:242 (item 7)
- [ ] **02-stack.md** — TAsync em Async.pas:50 na entrada Async; TScheduler/IScheduler em Coroutine.pas:173 na entrada Coroutine (item 4)
- [ ] **04-domain.md** — FErr: String (nao FError) (item 5)
- [ ] **04-domain.md** — TDictionary<T, Boolean> (nao Byte) (item 6)
- [ ] **04-domain.md** — nota G-08 "has not been measured" nos dois sitios de deadlock (item 9)
- [ ] **05-conventions.md** — ancoras :581/_DestroySuccess, :622/Dispose, :666/_DestroyFailure + frase citando PR #7 (item 8)
- [ ] **05-conventions.md** — "→ 2 475 (medido 2026-09-02: grep -rc '///' Source/*.pas)" + nota 16→22 unidades (item 10)
- [ ] Varredura pos-edicao retorna zero
- [ ] Nenhum arquivo em `Source/` modificado
- [ ] Commit unico; mensagem registra itens 1..10 como editados e itens 11+.inc como "verificado, nao editado"

## Issues-companheiras a abrir (fora deste PR)

1. **Finding A** — `Map<R>` faz re-cast silencioso (`ResultPair.pas:832-844`);
   corpo com medicao: `grep -rn "Map<R\|EInvalidCast" .project/analysis/` → 0.
2. **Cadencia de re-medicao** — bundle fechou em 27/08; `Source/` teve 8 PRs
   desde entao; titulo: "convencao: cadencia de re-medicao do dossie quando Source/ muda".

## Contexto de referencia

- Investigacao: run `0bc05ff9b241c9abcd326272568f1086`, issue #6 comentario.
- Bundle: `.project/analysis/` (auditado 2026-08-27, tres rodadas).
- PR #7 em `ResultPair.pas` — causou o deslocamento das ancoras do item 8.
