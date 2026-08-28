---
type: adr
kind: artifact
title: "ADR — Convenção de nomes de variáveis locais em ModernSyntax.Invoker.pas (issue #23)"
description: "Nenhuma nova decisão arquitetural é necessária; a convenção L+PascalCase já está estabelecida. Registra-se o desvio e a lacuna de processo detectada."
status: draft
cycle: "007"
agent: architect
workflow: equipe-chore
node: architect
resource: aefos://run/3ac50e14ab113cabde9efa632dc2fccf
tags: [adr, naming-convention, invoker, modernrtti, process, issue-23]
generated:
  by: "equipe-chore@node:architect"
  at: "2026-08-28T00:00:00Z"
sources:
  - id: conventions
    resource: "/analysis/05-conventions.md"
    title: "05 Conventions — ModernSyntax"
---

# ADR — Convenção L+PascalCase em variáveis locais (issue #23)

> Relatório de investigação: **NONE**. Não houve investigação prévia na
> issue. Este ADR decide de forma autônoma, conforme o protocolo.

## Contexto

`Source/ModernSyntax.Invoker.pas` foi entregue nos ciclos do Pilar 3 da
ModernRTTI com 4 variáveis locais (`addr`, `m`) que violam a convenção
`L`+PascalCase documentada em [05-conventions](/analysis/05-conventions.md)
§1.3 e evidenciada em todas as demais units do projeto.

Medido na issue: das quatro units novas da ModernRTTI, Invoker é a única
com o desvio — 4 locais fora do padrão, 0% de conformidade nessa categoria.

A issue aponta também uma **lacuna de processo**: o ADR do ciclo do Pilar 3
não menciona a convenção de prefixos, ao contrário dos ADRs dos outros três
ciclos. As três lentes de qualidade (review, verify, test) não capturaram
o desvio.

## Decisão

### D-1 — Sem nova decisão arquitetural; aplicar convenção existente

A convenção `L`+PascalCase para variáveis locais é um **fato estabelecido**
do projeto, medido em `Source/ModernSyntax.Objects.pas` e em 15 das 16
units de produção. Não há escolha de design a fazer: o desvio é corrigido
mecanicamente.

Renomear:

| Localização | Antes | Depois |
|---|---|---|
| `Invoke<TSignature>` — overload 1, linhas ~75-77 | `addr: Pointer` | `LAddress: Pointer` |
| `Invoke<TSignature>` — overload 1, linhas ~75-77 | `m: TMethod` | `LMethod: TMethod` |
| `Invoke<TSignature>` — overload 2, linhas ~95-97 | `addr: Pointer` | `LAddress: Pointer` |
| `Invoke<TSignature>` — overload 2, linhas ~95-97 | `m: TMethod` | `LMethod: TMethod` |

**Descartado — manter os nomes curtos por brevidade:** o padrão do projeto
é consistente e documentado. Exceção criaria precedente inconsistente.

**Descartado — renomear para outros nomes descritivos sem prefixo `L`:**
o prefixo é obrigatório pela RN-1 do [esp](pipeline-esp.md).

### D-2 — Lacuna de processo: a convenção de nomes deve ser item verificável

A issue demonstra que a convenção de prefixos depende hoje de o arquiteto
lembrar de citá-la no ADR — e no Pilar 3 isso não aconteceu. As três lentes
de qualidade tampouco detectaram o desvio.

**Esta decisão não modifica o workflow** (proibido ao arquiteto). O fato
é registrado aqui para que o nó de qualidade `verify` possa incorporar a
verificação em issue de processo futura. Um entry em FLOW-FEEDBACK.md
acompanha este ciclo.

## Consequências

- `Source/ModernSyntax.Invoker.pas` passa a estar 100% conforme com a
  convenção de nomes do projeto.
- Nenhuma API pública, assinatura ou teste é alterado.
- A lacuna de processo (ausência da convenção de prefixos no checklist de
  `verify`) permanece aberta para resolução em issue separada.
