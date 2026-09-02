---
type: task
kind: artifact
title: "TASK #60 — else raise no PropertyVisibility do backend FPC"
description: "4 edicoes em 2 arquivos Pascal: resourcestring SFPCUnknownVisibility + else raise + comentario reescrito + XMLDoc corrigido em TModernVisibility."
cycle: "025"
agent: planner
workflow: equipe-bug
node: task
resource: aefos://run/4c9ae8e8f3b0ca77a166f343e7d3f098
generated:
  by: "equipe-bug@node:task"
  at: "2026-09-02T00:00:00Z"
tags: [task, fpc, rtti, visibility, bug, issue-60, modernrtti, cycle-025]
---

# TASK — Ciclo 025 / Issue #60

## Tracking

- **Modo:** MAESTRO MODE
- **Issue original:** [#60](https://github.com/isaquepinheiro/ModernSyntax/issues/60)
  (demanda criada pelo maestro — `aefos:investigated`)
- **Epic:** nenhum Epic criado (MAESTRO MODE — não criar Epic sem correspondência óbvia)
- **Board local:** 🔄 in-pipeline

## Demanda em uma linha

Aplicar no `PropertyVisibility` do backend FPC a mesma guarda `else raise EModernRTTIError`
que o PR #59 inseriu no backend Delphi (issue #51); corrigir simultaneamente o XMLDoc
de `TModernVisibility` em `RTTI.pas`.

## Escopo

| Arquivo | Edições | Descrição |
|---------|---------|-----------|
| `Source/ModernSyntax.RTTI.FPC.pas` | 3 | + `SFPCUnknownVisibility` (resourcestring na implementation); reescrita do comentário de `PropertyVisibility`; + `else raise EModernRTTIError.CreateFmt(...)` |
| `Source/ModernSyntax.RTTI.pas` | 1 | reescrita do XMLDoc de `TModernVisibility` (linhas 79–85) |

## Acceptance checklist

- [ ] `PropertyVisibility` em `RTTI.FPC.pas` tem `else raise EModernRTTIError.CreateFmt(SFPCUnknownVisibility, [Ord(TRttiProperty(AToken).Visibility), 'PropertyVisibility'])` dentro do `case`.
- [ ] `SFPCUnknownVisibility` na seção `resourcestring` da **`implementation`** de `RTTI.FPC.pas`; zero símbolo novo na interface.
- [ ] Comentário de `PropertyVisibility` não afirma que o `else` seria código morto; descreve o comportamento medido (sem erro, sem warning, ordinal 229/i386, 0 = `mvPrivate`/x86_64) como razão histórica.
- [ ] Comentário cita #51 e #60 como primeiro e segundo movimento da mesma decisão.
- [ ] XMLDoc de `TModernVisibility` (`RTTI.pas:79–85`) descreve o comportamento dos dois backends após as guardas; medição no passado; sem afirmação de exaustividade em compile-time no FPC.
- [ ] PR não afirma redução de warning (não havia warning no FPC antes da fix).
- [ ] PR declara que o ramo `else` é inalcançável por dado real e por quê.
- [ ] Suite FPC 3.2.2 x86_64 verde; contagem permanece 42.
- [ ] Backend Delphi intocado; `RTTI.Delphi.pas` sem diff.

## PR

**Título:** `fix(rtti-fpc): else raise EModernRTTIError no PropertyVisibility (issue #60)`

**Body verbatim:**
> Compilado em FPC 3.2.2 x86_64. i386 e os 4 alvos Delphi ficam com o autor.
>
> O ramo `else raise` é inalcançável por dado real: o valor vem de
> `TRttiProperty(AToken).Visibility`, RTTI real, não injetável. Não há
> redução de warning — o FPC 3.2.2 nunca emitiu warning para este padrão
> (Delphi emite W1035; FPC compila limpo). A guarda protege contra crescimento
> futuro de `TMemberVisibility`, não contra dado atual.

Sem checklist de combinações — caixas marcadas sem execução comprometem a
confiabilidade do PR (padrão derivado de D-62.4 / aefos-studio#375).

## Restrições críticas

1. **`SFPCUnknownVisibility` na `implementation`**, nunca na `interface`.
   Verificar no diff que a adição está após `SFPCNoParamType` (linha 193), dentro do bloco `implementation`.
2. **Simetria com o Delphi** — a string segue o padrão literal de
   `SDelphiUnknownVisibility` em `RTTI.Delphi.pas:163-165`, trocando apenas `#51` → `#60`.
3. **Não divergir do texto aprovado na investigação** — o XMLDoc e o comentário do FPC
   foram acordados palavra a palavra. Ver [plan](pipeline-plan.md) para o texto exato.
4. **Medição no passado** — o XMLDoc descreve o que *era* antes das guardas, não o que
   o compilador faz hoje. Não introduzir afirmação nova sobre exaustividade ou comportamento do FPC.

## Referências

- [task-input](pipeline-task-input.md)
- [esp](pipeline-esp.md)
- [adr](pipeline-adr.md)
- [plan](pipeline-plan.md)
