---
type: spec
kind: artifact
title: "ESP #6 — 10 correcoes de texto no bundle OKF"
description: "Especificacao formal: corrigir 10 itens de texto em .project/analysis/ verificados contra main 8d4275b, em um unico commit."
cycle: "026"
agent: architect
workflow: equipe-chore
node: architect
resource: aefos://run/0ed0e9cf6250cee7ab26731ee07d3ccc
generated:
  by: "equipe-chore@node:architect"
  at: "2026-09-02T00:00:00Z"
tags: [spec, okf, bundle, text-correction, chore, issue-6, cycle-026]
---

# ESP #6 — 10 correções de texto no bundle OKF

## 1. Objetivo

Corrigir 10 itens de texto no bundle `.project/analysis/` — números
divergentes, âncoras fora do lugar e ausências declaradas — todos medidos
contra `main 8d4275b`. Dois itens adicionais (item 11 e `.inc`) foram
verificados e descartados: a afirmação da issue não se sustenta no código atual.

## 2. Contexto

O bundle foi auditado em três rodadas (2026-08-27). As ressalvas aprovadas
não bloqueiam design nem implementação. A raiz da drift foi PR #7 em
`ResultPair.pas` (deslocou âncoras de linha) e a adição de 6 novas unidades
em `Source/` (elevou a contagem de `///` de 1 581 para 2 475). Nenhuma das
10 edições altera uma decisão de arquitetura.

## 3. Escopo

**4 arquivos, 10 itens editados, 1 commit.**

| # | Arquivo | Desfecho |
|---|---------|---------|
| 1 | `03-architecture.md` | "14-variant enum, lines 32-51" → "17-variant enum, lines 32-50" |
| 2 | `03-architecture.md` | "14 _Matching* private methods" → "17 _Matching* private methods" |
| 3 | `03-architecture.md` | "12 INumeric<T> implementors" → "14 INumeric<T> implementors" (dois sitios) |
| 4 | `02-stack.md` | TAsync vai para entrada de Async; TScheduler/IScheduler vao para Coroutine |
| 5 | `04-domain.md` | FError: String → FErr: String |
| 6 | `04-domain.md` | TDictionary<T,Byte> → TDictionary<T, Boolean> |
| 7 | `03-architecture.md` | descrever FMatch como class var escrita no inicio da sessao em Value() |
| 8 | `05-conventions.md` | ancoras → :581/:622/:666; acrescentar nota de PR #7 |
| 9 | `04-domain.md` | acrescentar nota dupla remetendo a G-08 "has not been measured" |
| 10 | `05-conventions.md` | "→ 1 581" → "→ 2 475 (medido 2026-09-02: grep -rc '///' Source/*.pas)" + nota 16→22 |
| 11 | `05-conventions.md` | verificado, NAO editado — a correcao pedida ja esta no arquivo |
| .inc | `ModernSyntax.inc` | verificado, NAO editado — {$ELSEIF} e valido; HAS_ENCDDECD alcancavel |

## 4. Fora do escopo

- Codigo de producao — zero mudancas em `Source/`.
- `Map<R>` faz re-cast silencioso (`ResultPair.pas:832-844`) — achado de
  codigo novo; vira issue propria (licao aefos-studio#375).
- Cadencia de re-medicao do bundle — raiz estrutural da drift; vira
  issue-companheira propria com corpo medido.
- Testes, interfaces, contratos, schemas ou APIs — nenhum destes muda.

## 5. Regras de negocio e restricoes

1. **Um unico commit** — mensagem enumera itens 1..10 como editados; item 11
   e `.inc` como "verificado, nao editado".
2. **Varredura de cross-refs** antes de cada edicao:
   `grep -rn "593|597|1 581|14-variant|12.*INumeric|FError|Byte>" .project/analysis/`.
3. **Correcao vai para o medido**, nao para o valor da issue nem para o
   valor original do dossie (item 1: intervalo 32-50, nao 33-49 nem 32-51).
4. **Item 10 leva numero datado com comando** —
   "→ 2 475 (medido 2026-09-02: grep -rc '///' Source/*.pas)" — convencao
   da casa (todo numero vem com o comando ao lado).
5. **Item 8 cita PR #7** como causa do deslocamento de
   _DestroySuccess/_DestroyFailure, preservando a trilha de causa.
6. **Nenhuma nota de rodape de cadencia em `05-conventions.md`** — o
   argumento vive inteiro na issue-companheira.

## 6. Criterios de aceitacao

- [ ] `03-architecture.md` diz "17-variant enum, lines 32-50".
- [ ] `03-architecture.md` diz "17 _Matching* private methods".
- [ ] `03-architecture.md` diz "14 INumeric<T> implementors" nos dois sitios.
- [ ] `03-architecture.md` descreve FMatch como class var escrita no inicio da sessao em Value() (Match.pas:242), nao no final.
- [ ] `02-stack.md` entrada ModernSyntax.Async descreve TAsync (Async.pas:50); entrada ModernSyntax.Coroutine menciona TScheduler/IScheduler (Coroutine.pas:173).
- [ ] `04-domain.md` diz FErr: String (nao FError).
- [ ] `04-domain.md` diz TDictionary<T, Boolean> (nao Byte).
- [ ] `04-domain.md` (dois sitios) contem nota remetendo a G-08 "has not been measured".
- [ ] `05-conventions.md` referencia :581 (_DestroySuccess), :622 (Dispose), :666 (_DestroyFailure) e inclui frase citando PR #7.
- [ ] `05-conventions.md` exibe "→ 2 475 (medido 2026-09-02: grep -rc '///' Source/*.pas)" e nota que unidades cresceram de 16 para 22.
- [ ] Varredura de cross-refs retorna zero apos o commit.
- [ ] Nenhum arquivo em `Source/` foi modificado.
- [ ] Mensagem do commit identifica itens 1..10 como editados; item 11 e `.inc` como "verificado, nao editado".

## 7. Riscos

| Risco | Prob | Impacto | Mitigacao |
|-------|------|---------|-----------|
| Cross-ref perdida (numero antigo citado em outro arquivo) | Media | Baixa | Varredura obrigatoria antes de cada edicao |
| Item 8 apodrecer com novo PR em ResultPair.pas | Media | Baixa | Nota de PR #7 preserva trilha; issue-companheira de cadencia e resposta duravel |
| Item 10 (2 475) apodrecer com proximo commit em Source/ | Alta | Baixa | Issue-companheira de cadencia cobre isso; numero datado com comando ao lado |
