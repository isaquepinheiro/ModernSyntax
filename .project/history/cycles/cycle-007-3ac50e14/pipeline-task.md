---
type: task
kind: artifact
title: "Task — chore: renomear variáveis locais em ModernSyntax.Invoker.pas (issue #23)"
description: "Rename addr→LAddress e m→LMethod nos dois overloads de Invoke<TSignature>; build FPC 3.2.2 limpo — 7 testes, 0 falhas; diff limitado a Source/ModernSyntax.Invoker.pas."
cycle: "007"
agent: planner
workflow: equipe-chore
node: task
resource: aefos://run/3ac50e14ab113cabde9efa632dc2fccf
tags: [chore, naming-convention, invoker, issue-23, cycle-007]
generated:
  by: "equipe-chore@node:task"
  at: "2026-08-28T00:00:00Z"
sources:
  - id: task-input
    resource: "task-input.md"
    title: "Task Input — Renomear variáveis locais em ModernSyntax.Invoker.pas (issue #23)"
---

# Task — chore: renomear variáveis locais em ModernSyntax.Invoker.pas (issue #23)

## Tracking

**Modo:** MAESTRO MODE — from_maestro: true  
**Issue original:** [#23](https://github.com/isaquepinheiro/ModernSyntax/issues/23) —
*chore: fix local variable naming convention in ModernSyntax.Invoker* (esta issue É a
demanda deste ciclo; nenhuma issue ou Epic adicional foi criada).  
**Ciclo:** 007

## Briefing resumido

A demanda é um chore de renaming puro, escopo de arquivo único:
`Source/ModernSyntax.Invoker.pas`. O escopo completo está em
[task-input.md](pipeline-task-input.md).

### Arquivo impactado

| Arquivo | Tipo de mudança |
|---------|----------------|
| `Source/ModernSyntax.Invoker.pas` | Rename de 4 variáveis locais (2 por overload) |

### Nenhum outro arquivo deve ser modificado.

## Renames a aplicar

Nos **dois overloads** de `Invoke<TSignature>` (blocos `var` em ~linhas 75-77 e ~95-97):

| De | Para |
|----|------|
| `addr` | `LAddress` |
| `m` | `LMethod` |

Renomear declaração **e** todos os usos no corpo de cada overload.

## Critérios de aceitação

- [ ] `addr` e `m` não aparecem como variáveis locais em nenhum bloco `var` de rotina
      em `ModernSyntax.Invoker.pas`.
- [ ] `LAddress` e `LMethod` declarados e usados corretamente nos dois overloads.
- [ ] Build FPC 3.2.2 x86_64 limpo: **7 testes, 0 falhas**.
- [ ] `git diff --name-only` retorna somente `Source/ModernSyntax.Invoker.pas`.

## Comando de verificação

```sh
rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild
fpc -Mdelphi \
    -Fu"Source" \
    -Fu"Test Shared/EclbrSystem" \
    -Fu"Test FPC/EclbrSystem" \
    -FU/tmp/fpcbuild \
    -o/tmp/fpcbuild/PTestInvoker \
    "Test FPC/EclbrSystem/PTestInvoker.lpr"
/tmp/fpcbuild/PTestInvoker --all -a --format=plain
```

## Observação para o PR

O PR declara: *"compiled on FPC 3.2.2 x86_64; not compiled on Delphi"*
(compilação Delphi permanece com o autor humano).

## Modo de rastreamento

MAESTRO MODE (from_maestro: true). A issue #23 preexiste como intake do maestro.
Nenhuma issue ou Epic adicional criada neste ciclo. O board de estado está em
[../project-evolution.md](../../../project-evolution.md) marcado como 🔄 in-pipeline.
