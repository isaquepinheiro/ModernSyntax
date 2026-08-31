---
type: task-input
kind: artifact
title: "Task input — Renomear variáveis locais em ModernSyntax.Invoker.pas (issue #23)"
description: "Handoff operacional: rename de addr/m para LAddress/LMethod nos dois overloads de Invoke<TSignature>; build limpo de PTestInvoker; nenhuma outra unit tocada."
status: draft
cycle: "007"
agent: architect
workflow: equipe-chore
node: architect
resource: aefos://run/3ac50e14ab113cabde9efa632dc2fccf
tags: [task-input, chore, naming-convention, invoker, issue-23]
generated:
  by: "equipe-chore@node:architect"
  at: "2026-08-28T00:00:00Z"
---

# Task input — Rename de variáveis locais em ModernSyntax.Invoker

## Título da issue / PR

`chore: fix local variable naming convention in ModernSyntax.Invoker (#23)`

## Tipo e labels

- Tipo: `chore`
- Labels: `chore`, `naming-convention`, `modernrtti`

## Escopo

Arquivo único: `Source/ModernSyntax.Invoker.pas`.

Nenhum outro arquivo deve ser modificado.

## O que fazer — passo a passo

1. Abrir `Source/ModernSyntax.Invoker.pas`.

2. Nos **dois overloads** de `Invoke<TSignature>`, localizar os blocos
   `var` (linhas ~75-77 e ~95-97) e aplicar os renames:

   | Local | De | Para |
   |---|---|---|
   | Declaração + usos, overload 1 | `addr` | `LAddress` |
   | Declaração + usos, overload 1 | `m` | `LMethod` |
   | Declaração + usos, overload 2 | `addr` | `LAddress` |
   | Declaração + usos, overload 2 | `m` | `LMethod` |

   Renomear **todos os usos** de cada variável no corpo do overload,
   não só a declaração.

3. Executar o build de verificação (build limpo obrigatório — sem limpar
   o diretório de saída, o FPC pode reportar verde sobre `.ppu` antigos):

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

4. Confirmar resultado: **7 testes, 0 falhas**.

5. Confirmar escopo: `git diff --name-only` retorna somente
   `Source/ModernSyntax.Invoker.pas`.

## Checklist de aceitação

- [ ] `addr` e `m` não aparecem como variáveis locais em nenhum bloco
      `var` de rotina em `ModernSyntax.Invoker.pas`.
- [ ] `LAddress` e `LMethod` declarados e usados corretamente nos dois
      overloads.
- [ ] Build FPC 3.2.2 x86_64 limpo: 7 testes, 0 falhas.
- [ ] Diff limitado a `Source/ModernSyntax.Invoker.pas`.

## Observação para o PR

O PR declara: *"compiled on FPC 3.2.2 x86_64; not compiled on Delphi"*
(compilação Delphi permanece com o autor humano — ver [SKILL](/SKILL.md)).

## Arquivos provavelmente impactados

| Arquivo | Tipo de mudança |
|---|---|
| `Source/ModernSyntax.Invoker.pas` | Rename de 4 variáveis locais |
