---
type: plan
kind: artifact
title: "Plan — Renomear variáveis locais em ModernSyntax.Invoker.pas (issue #23)"
description: "Uma única fatia: rename mecânico de 4 variáveis locais em dois overloads, seguido de build limpo do PTestInvoker."
status: draft
cycle: "007"
agent: architect
workflow: equipe-chore
node: architect
resource: aefos://run/3ac50e14ab113cabde9efa632dc2fccf
tags: [plan, chore, naming-convention, invoker, issue-23]
generated:
  by: "equipe-chore@node:architect"
  at: "2026-08-28T00:00:00Z"
---

# Plan — Renomear variáveis locais em ModernSyntax.Invoker (issue #23)

**Escopo:** `fits` — mudança de uma linha por variável, em um único
arquivo, sem impacto em API ou testes. Não atinge o limiar de tamanho
nem de independência de fatias para justificar split.

## Fatia 1 — Rename e verificação (única fatia)

**Objetivo:** corrigir os 4 locais não conformes e provar que os testes
passam.

**Passos:**

1. Em `Source/ModernSyntax.Invoker.pas`, localizar os dois blocos `var`
   nos overloads de `Invoke<TSignature>` (linhas ~75-77 e ~95-97).
2. Substituir:
   - `addr: Pointer` → `LAddress: Pointer`
   - `m: TMethod` → `LMethod: TMethod`
   e todos os usos dessas variáveis no corpo de cada overload.
3. Build limpo do runner FPC:
   ```
   rm -rf /tmp/fpcbuild
   mkdir -p /tmp/fpcbuild
   fpc -Mdelphi \
       -Fu"Source" \
       -Fu"Test Shared/EclbrSystem" \
       -Fu"Test FPC/EclbrSystem" \
       -FU/tmp/fpcbuild \
       -o/tmp/fpcbuild/PTestInvoker \
       "Test FPC/EclbrSystem/PTestInvoker.lpr"
   /tmp/fpcbuild/PTestInvoker --all -a --format=plain
   ```
4. Confirmar: **7 testes, 0 falhas**.
5. Confirmar: `git diff --name-only` mostra somente
   `Source/ModernSyntax.Invoker.pas`.

**Arquivos impactados:**
- `Source/ModernSyntax.Invoker.pas` — único arquivo modificado.

**Critério de saída da fatia:** todos os critérios de aceitação do
[esp](pipeline-esp.md) satisfeitos.
