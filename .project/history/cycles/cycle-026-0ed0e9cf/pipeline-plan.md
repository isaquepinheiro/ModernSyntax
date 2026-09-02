---
type: plan
kind: artifact
title: "Plano #6 — 10 correcoes de texto no bundle OKF"
description: "Plano de execucao: um unico slice com varredura de cross-refs, 10 edicoes em 4 arquivos, 1 commit."
cycle: "026"
agent: architect
workflow: equipe-chore
node: architect
resource: aefos://run/0ed0e9cf6250cee7ab26731ee07d3ccc
generated:
  by: "equipe-chore@node:architect"
  at: "2026-09-02T00:00:00Z"
tags: [plan, okf, bundle, text-correction, chore, issue-6, cycle-026]
---

# Plano #6 — 10 correções de texto no bundle OKF

## Avaliação de escopo

**`fits`** — uma mudança coesa, um commit.

- **TEST 1 (tamanho):** 10 edições de texto em 4 arquivos markdown. Nenhuma
  linha de código de produção. Implementação bem abaixo do orçamento típico.
- **TEST 2 (independência):** Todas as edições formam um conjunto atômico
  (um commit, mensagem enumerando todos os itens). Não há dois subconjuntos
  que sejam cada um mergeável de forma independente com sentido próprio.
  Cortar em partes pagaria o overhead fixo do ciclo duas vezes por uma única
  peça de trabalho.

## Slice único — corrigir os 10 itens em `.project/analysis/`

### Pré-condição

Rodar varredura de cross-refs antes de iniciar qualquer edição:

```
grep -rn "593\|597\|1 581\|14-variant\|12.*INumeric\|FError\|Byte>" .project/analysis/
```

Registrar quais arquivos e linhas aparecem; confirmar que todas estão
cobertas pelos 10 itens abaixo (ou são cross-refs de itens já tratados).

### Edições — `03-architecture.md` (itens 1, 2, 3, 7)

1. Substituir "14-variant enum, lines 32-51" por
   "17-variant enum, lines 32-50".
2. Substituir "14 `_Matching*` private methods" por
   "17 `_Matching*` private methods".
3. Substituir "12 `INumeric<T>` implementors" (dois sítios) por
   "14 `INumeric<T>` implementors" / "14 concrete `INumeric<T>` implementors".
4. Revisar a frase de `FMatch` para descrever a class var que carrega o
   registro `TMatch<T>` através de fronteiras de cópia por valor, escrita
   no **início** da sessão em `Value()` (`Match.pas:242`), não no final.

### Edições — `02-stack.md` (item 4)

5. Entrada `ModernSyntax.Async` passa a descrever `TAsync` (`Async.pas:50`).
   `TScheduler`/`IScheduler` vão para a entrada de `ModernSyntax.Coroutine`
   (`Coroutine.pas:173`).

### Edições — `04-domain.md` (itens 5, 6, 9)

6. Substituir `FError: String` por `FErr: String`.
7. Substituir `TDictionary<T,Byte>` por `TDictionary<T, Boolean>`.
8. Acrescentar nos dois sítios de deadlock do `TThread.Queue` a nota:
   - Sítio 1: "G-08 notes this has not been measured."
   - Sítio 2: "See G-08 (`06-gaps-and-risks.md:268`), which rebuffs this
     to 'has not been measured'."

### Edições — `05-conventions.md` (itens 8, 10)

9. Atualizar as três referências de âncora para:
   - `Dispose (ResultPair.pas:622)`
   - `_DestroySuccess (ResultPair.pas:581)`
   - `_DestroyFailure (ResultPair.pas:666)`
   Acrescentar: "posições atualizadas após PR #7 no bloco de `ResultPair.pas`".
10. Substituir "→ 1 581" por:
    "→ 2 475 (medido 2026-09-02: `grep -rc '///' Source/*.pas`)"
    Acrescentar nota de que a contagem de unidades cresceu de 16 para 22.

### Pós-edição

- Rodar varredura novamente: `grep -rn "593\|597\|1 581\|14-variant\|12.*INumeric\|FError\|Byte>" .project/analysis/` — deve retornar zero.
- Confirmar que nenhum arquivo em `Source/` foi tocado.

### Commit

Um único commit. Mensagem enumera:

```
chore(docs): corrigir 10 itens de texto no bundle OKF (#6)

itens 1..10 editados (03-architecture.md, 02-stack.md, 04-domain.md, 05-conventions.md)
item 11 (05-conventions.md:247) verificado, nao editado — correcao ja presente
item .inc (ModernSyntax.inc:266-270) verificado, nao editado — nunca foi verdade
```

### Issues-companheiras (fora deste PR)

- **Finding A:** `Map<R>` faz re-cast silencioso (`ResultPair.pas:832-844`) —
  abrir issue própria com corpo medido.
- **Cadência de re-medição:** bundle fechou em 27/08; `Source/` teve 8 PRs
  desde então — abrir issue-companheira com corpo medido.
