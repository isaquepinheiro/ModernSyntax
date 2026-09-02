---
type: split-report
title: "SPLIT REPORT — Issue #29 dividida em cinco sub-issues (#42–#46)"
description: "Registro da decomposicao da issue #29 (tipos de categoria RTTI) em cinco sub-issues independentes via GitHub, com fechamento do parent e aplicacao de labels aefos:queue + enhancement."
status: done
cycle: "014"
agent: scope-splitter
workflow: equipe-feature
node: scope-splitter
resource: aefos://run/f42b5faad0107a1daea308f52bd50ed4
tags: [split, modernrtti, issue-29, backlog, fpc, delphi]
generated:
  by: "equipe-feature@node:scope-splitter"
  at: "2026-09-01T00:00:00Z"
---

# Split Report — Issue #29

## Canal

GitHub — `isaquepinheiro/ModernSyntax`

## Parent

| Campo | Valor |
|-------|-------|
| Issue | [#29](https://github.com/isaquepinheiro/ModernSyntax/issues/29) |
| Titulo | Os tipos de categoria: Record, Array, Enumeration, Set, IndexedProperty, Pointer e Visibility |
| Estado final | Fechada como `split into #42 #43 #44 #45 #46` |
| Label removida | `aefos:running` |

## Sub-issues criadas

| # | Issue | Titulo | Labels aplicadas |
|---|-------|--------|-----------------|
| 1 | [#42](https://github.com/isaquepinheiro/ModernSyntax/issues/42) | `TModernVisibility`: enum proprio, fecha vazamento `TMemberVisibility` em `Method.Visibility` e adiciona `Property.Visibility` | `aefos:queue`, `enhancement` |
| 2 | [#43](https://github.com/isaquepinheiro/ModernSyntax/issues/43) | `TModernRTTIEnumerationType`: nome, valores e nomes de constantes nos dois compiladores | `aefos:queue`, `enhancement` |
| 3 | [#44](https://github.com/isaquepinheiro/ModernSyntax/issues/44) | `TModernRTTIPointerType`: `ReferredType` nos dois compiladores; mutacao obrigatoria `RefType` → `RefTypeRef` | `aefos:queue`, `enhancement` |
| 4 | [#45](https://github.com/isaquepinheiro/ModernSyntax/issues/45) | `TModernRTTIRecordType`: `Name` + `Size` apenas nos dois compiladores; `GetFields` fica para issue propria | `aefos:queue`, `enhancement` |
| 5 | [#46](https://github.com/isaquepinheiro/ModernSyntax/issues/46) | `TModernRTTIArrayType` (`ElementType`, `Size`, `Length`, `IsDynamic`) + `TModernRTTISetType` (`ElementType`) nos dois compiladores; duas mutacoes obrigatorias | `aefos:queue`, `enhancement` |

## Acoes realizadas

1. Verificacao de idempotencia: nenhuma sub-issue preexistente ligada ao parent #29.
2. Criacao das cinco sub-issues com corpo contendo escopo completo, acceptance criteria e `Parte de #29`.
3. Comentario no parent: "Dividido em sub-issues: #42 #43 #44 #45 #46".
4. Remocao do label `aefos:running` do parent.
5. Fechamento do parent com comentario "split into #42 #43 #44 #45 #46".

## Proximos passos

As cinco sub-issues estao em `aefos:queue` (fila de investigacao). Cada uma deve ser promovida a `aefos:investigated` via `/investigate` antes de ser pega pelo issue-maestro.

**Nota:** A issue separada para `TModernRTTIIndexedProperty` (aguardar FPC 3.4) foi mencionada na proposta como "fora do split" e deve ser criada manualmente quando apropriado.
