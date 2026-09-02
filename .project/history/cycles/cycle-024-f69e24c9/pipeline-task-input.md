---
type: task-input
kind: artifact
title: "TASK-INPUT #62 — sete edições documentais em 4 arquivos Pascal"
description: "Handoff operacional: sete substituições de XMLDoc/comentário em quatro arquivos, um commit, PR com frase declarativa de fronteira de compilador."
cycle: 24
agent: architect
workflow: equipe-chore
node: architect
generated:
  by: equipe-chore@node:architect
  at: "2026-09-02T00:00:00Z"
tags: [cycle-024, issue-62, chore, documentation]
---

# TASK-INPUT — Issue #62

## Título do PR

`docs(rtti): corrigir XMLDoc TModernVisibility, remarks Attributes e comentários do cenário NilHandle (#62)`

## Tipo / Labels

`chore`, `documentation`

## Escopo

Sete substituições de texto (XMLDoc `///` e comentários `//`) em quatro arquivos
Pascal. **Nenhuma linha executável muda.**

## Arquivos impactados

| Arquivo | Edições |
|---|---|
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | 3 (itens 1, 2, 3) |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | 1 (item 4) |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | 1 (item 5) |
| `Source/ModernSyntax.RTTI.pas` | 2 (itens 6, 7) |

## Acceptance checklist (para o implementador)

- [ ] `UScenarios.RTTI.pas:145` — âncora `:1419-1422` substituída por `Scenario_SetType_ElementType`
- [ ] `UScenarios.RTTI.pas:318-320` — comentário da declaração: "seis", `Attributes` na lista, "é exatamente `Format(SModernRTTINilHandle, [<membro>])`"
- [ ] `UScenarios.RTTI.pas:1452-1457` — cabeçalho do corpo: mesmas duas correções do item anterior
- [ ] `UTestMS.RTTI.pas` (Delphi) `:171` — "nos cinco membros afetados" → "nos seis membros afetados"; `:97` intacto
- [ ] `UTestMS.RTTI.pas` (FPC) `:105` — idem; `:56` intacto
- [ ] `ModernSyntax.RTTI.pas:80-82` — `<summary>` de `TModernVisibility` substituído por texto verbatim da §1 da issue (com acentos, "Ver #60.")
- [ ] `ModernSyntax.RTTI.pas:427-433` — `<remarks>` de nil inserido para `Attributes`, cópia literal dos cinco irmãos
- [ ] **Nenhuma citação de linha nova** introduzida pelo PR
- [ ] Diff não contém re-encoding dos arquivos (apenas as linhas editadas mudam)
- [ ] FPC 3.2.2 x86_64 compila sem erro (nenhuma linha executável muda — regressão improvável)

## PR body (texto a usar, verbatim)

> Compilado em FPC 3.2.2 x86_64. i386 e os 4 alvos Delphi ficam com o mantenedor.

**Sem checklist de combinações** — ver ADR D-62.4 (aefos-studio#375).

## Restrições críticas

1. **Ordem de edição:** item 1 (âncora `:145`) primeiro, antes de qualquer edição que
   some ou remova linhas no mesmo arquivo.
2. **Âncora nas cascas:** substituir pela frase inteira *"nos cinco membros afetados"*
   — não a palavra "cinco" solta (dois "cinco" por casca; `:97`/`:56` é correto e não
   deve ser tocado).
3. **Encoding:** editar apenas as linhas-alvo; não reencodar os `.pas` (ambos UTF-8
   sem BOM).

## Referências

- Issue: [#62](https://github.com/isaquepinheiro/ModernSyntax/issues/62)
- Relatório de investigação: run `8810a78921ce945faf6e68362495134d`
- Spec: [esp](pipeline-esp.md)
- ADR: [adr](pipeline-adr.md)
- Plano: [plan](pipeline-plan.md)
