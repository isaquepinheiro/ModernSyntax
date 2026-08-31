---
type: flow-feedback
kind: report
title: "FLOW-FEEDBACK — Ciclo 007: convenção de prefixos ausente do checklist de verify"
description: "A convenção L+PascalCase de variáveis locais não é item verificável explícito no nó verify; o desvio do Invoker passou por três lentes de qualidade sem ser detectado."
status: stable
cycle: "007"
agent: architect
workflow: equipe-chore
node: architect
resource: aefos://run/3ac50e14ab113cabde9efa632dc2fccf
tags: [flow-feedback, process, naming-convention, verify, quality]
generated:
  by: "equipe-chore@node:architect"
  at: "2026-08-28T00:00:00Z"
---

# FLOW-FEEDBACK — Ciclo 007

## Problema

A convenção de prefixos de variáveis locais (`L`+PascalCase) **não está
no checklist explícito do nó `verify`** do pipeline. Hoje ela só é
detectada quando o arquiteto lembra de citá-la no ADR do ciclo.

**Evidência medida:** `ModernSyntax.Invoker.pas` foi entregue no Pilar 3
com 4 variáveis locais não conformes (`addr`, `m`). O ADR do ciclo do
Pilar 3 não mencionou a convenção. As três lentes de qualidade
(review, verify, test) não flagraram o desvio. O defeito chegou à issue
#23 de um ciclo posterior — overhead de um ciclo de chore inteiro para
um rename mecânico.

Os ADRs dos outros três ciclos da ModernRTTI (Pilar 1, Pilar 2,
Transversal) citam a decisão de convenção explicitamente; o Pilar 3 não.
A detecção dependeu da atenção pontual do arquiteto, não de um processo.

## Sugestão de mudança no workflow

Adicionar ao prompt do nó `verify` um item de checklist explícito:

> **Nomes de variáveis locais:** grep no(s) arquivo(s) modificado(s) por
> locais sem prefixo `L` (`^\s*[a-z][a-zA-Z0-9]*\s*:` em bloco `var` de
> rotina). Zero ocorrências esperadas.

Alternativamente, adicionar um passo de lint automático (script bash)
que o nó `verify` execute antes de emitir o relatório de qualidade.

**Esta sugestão não modifica o workflow** — é registrada para revisão
humana conforme protocolo.

---

## Entrada 2 — developer (nó `implement`)

### Problema

A branch do ciclo 007 (`aefos/cycle-3ac50e14-…`) foi criada pela maestro
a partir de `origin/develop`, mas o arquivo alvo do chore
(`Source/ModernSyntax.Invoker.pas`) **não existe em `develop`** — só em
`main`, pelo PR #19 mergeado no ciclo 005. Sem o arquivo não há o que
renomear, e o implementador é forçado a fazer `merge origin/main` antes
de qualquer edição.

**Evidência:** `git ls-tree origin/develop -- Source/` não lista Invoker,
Callback, RTTI, Attributes; `git ls-tree origin/main -- Source/` lista
todos os quatro. O mesmo padrão apareceu nos ciclos 004, 005 e 006
(commits: *"merge: traz o main para a branch do X"*). É uma armadilha
recorrente.

### Sugestão de mudança no workflow

O nó de bootstrap da maestro deve escolher a base branch em função da
issue:

- Issue toca um arquivo que **só existe em `main`** → base = `main`.
- Issue toca um arquivo que **existe em `develop`** → base = `develop`.
- Na dúvida, consultar `git log --all -- <arquivo>` antes de criar a
  branch.

Alternativa: registrar em `.project/SKILL.md` uma seção *"Base branch
policy"* declarando que ciclos que tocam código-fonte devem partir de
`main`, e ciclos que tocam docs/bundle podem partir de `develop`.

**Esta sugestão não modifica o workflow** — registrada para revisão
humana.

