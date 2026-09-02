---
type: cycle-report
kind: report
title: "REPORT-planner — cycle 021 — issue #56 (Attributes nil-handle)"
description: "Planner formalizou a demanda #56 como task.md, registrou ciclo 021 no board e confirmou tracking MAESTRO MODE sem criacao de issue ou Epic."
cycle: "021"
agent: planner
workflow: equipe-bug
node: task
resource: aefos://run/09743779c7c9860b5fa380f6979d94ca
tags: [cycle-report, planner, issue-56, modernrtti, nil-handle, attributes, cycle-021]
generated:
  by: "equipe-bug@node:task"
  at: "2026-09-02T15:41:00Z"
---

# REPORT-planner — Cycle 021 — Issue #56

## Demanda

Issue #56: `TModernRTTIType.Attributes` ficou fora do contrato de nil-handle
uniformizado pela #49 (PR #55). `PropAttributes` devolve vazio silenciosamente
quando `FType = nil` via `if (FType is TRttiInstanceType)` que retorna `False`
sem AV — indistinguivel de "o tipo nao tem atributos".

## Fontes consultadas

- [REPORT-architect](REPORT-architect.md) — investigacao e artefatos do ciclo
- [pipeline-task-input](pipeline-task-input.md) — handoff operacional do arquiteto
- Issue #56 no GitHub (lida via `gh issue view 56`)

## Decisoes de tracking

**Modo: MAESTRO MODE** (`from_maestro: true`).

- Issue #56 ja existe e carrega `aefos:running` — demanda oficial deste ciclo.
- Nenhuma issue nova criada (evitaria duplicata orfao).
- Nenhum Epic criado — nao ha Epic preexistente com titulo/label `epic`
  obviamente relacionado; epics sao ferramenta do mantenedor.
- Board: issue #56 ja marcada `aefos:running`; nenhuma movimentacao adicional
  necessaria.

## Artefatos produzidos

| Arquivo | Descricao |
|---------|-----------|
| [pipeline-task.md](pipeline-task.md) | Task formalizada para o implementador com tres passos, criterios de aceite e armadilhas |
| `project-evolution.md` | Entrada do ciclo 021 adicionada na tabela e na secao de notas |

## Scope confirmado

Dois arquivos, commit unico, nenhuma `resourcestring` nova:

| Arquivo | O que muda |
|---------|-----------|
| `Source/ModernSyntax.RTTI.pas` | Guarda de 2 linhas em `PropAttributes` (:1124), antes do `// Issue #27:` |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | 5 blocos x 2 linhas (Pos para igualdade estrita) + sexto bloco Attributes (~18 linhas) |

`SModernRTTINilHandle` ja existe em `:892` — nao ha string nova.

Cascas de teste FPC e Delphi nao mudam.

## Decisoes criticas para o implementador

1. **Posicao da guarda**: inserir como PRIMEIRA instrucao de `PropAttributes`,
   antes do comentario `// Issue #27:` e antes do `if (FType is TRttiInstanceType)`.
   `is` sobre `nil` retorna `False` sem AV — a guarda depois do `is` nao seria
   alcancada no caminho de nil.
2. **Nao-regressao**: `Attributes` sobre handle valido nao-classe (record, enum)
   deve continuar devolvendo vazio — o `else Result := nil` permanece intacto.
3. **Igualdade estrita**: todos os seis blocos do cenario usam
   `LMsg <> Format(SModernRTTINilHandle, [<nome>])` — nenhum usa `Pos`.
4. **Variaveis de escopo**: `LRaised` e `LMsg` ja existem no procedimento;
   o sexto bloco as reutiliza sem redeclarar.
5. **Commit unico**: os tres passos (guarda + uniformizacao + sexto bloco)
   vao em um unico commit — separar cria ruido no bisect.

## Fronteira de verificacao

A fabrica cobre FPC 3.2.2 x86_64 (1 de 4). FPC i386, Delphi Win32 e
Delphi Win64 ficam com o mantenedor antes do merge — padrao herdado da
serie #43-#49.
