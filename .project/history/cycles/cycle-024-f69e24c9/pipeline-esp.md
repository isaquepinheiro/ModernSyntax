---
type: spec
kind: artifact
title: "ESP #62 — Corrigir 4 itens documentais restantes da #57 + âncora de linha do PR #61"
description: Especificação formal das sete edições de XMLDoc/comentários em 4 arquivos Pascal — nenhuma linha executável muda.
cycle: 24
agent: architect
workflow: equipe-chore
node: architect
generated:
  by: equipe-chore@node:architect
  at: "2026-09-02T00:00:00Z"
tags: [cycle-024, issue-62, chore, documentation, xmldoc, rtti]
---

# ESP — Issue #62: Restam 4 itens da #57 + âncora do PR #61

## 1. Objetivo

Fechar os quatro itens documentais que o PR #61 não entregou (da #57)
e corrigir a âncora de linha que o próprio PR #61 introduziu errada.
**Nenhuma linha executável é alterada.**

## 2. Escopo

Sete edições de texto em quatro arquivos Pascal — todas em `///` (XMLDoc) ou
`//` (comentários de linha):

| # | Arquivo | Ponto de mudança |
|---|---|---|
| 1 | `Test Shared/EclbrSystem/UScenarios.RTTI.pas:145` | Âncora `:1419-1422` → nome `Scenario_SetType_ElementType` |
| 2 | `Test Shared/EclbrSystem/UScenarios.RTTI.pas:318-320` | Comentário da declaração: "cinco" → "seis" + `Attributes`; "cita" → igualdade estrita |
| 3 | `Test Shared/EclbrSystem/UScenarios.RTTI.pas:1452-1457` | Cabeçalho do corpo: mesmas duas correções do item 2 |
| 4 | `Test Delphi/EclbrSystem/UTestMS.RTTI.pas:171` | "nos cinco membros afetados" → "nos seis membros afetados" |
| 5 | `Test FPC/EclbrSystem/UTestMS.RTTI.pas:105` | Idem ao item 4 |
| 6 | `Source/ModernSyntax.RTTI.pas:80-82` | `<summary>` de `TModernVisibility`: texto verbatim da §1 da issue (com acentos, "Ver #60.") |
| 7 | `Source/ModernSyntax.RTTI.pas:427-433` | Property `Attributes`: inserir `<remarks>` de nil idêntico aos cinco irmãos |

## 3. Fora de escopo

- O `case` sem `else` de `PropertyVisibility` no backend FPC — é a **#60**, com
  medição própria.
- Qualquer linha executável (assinaturas, corpos de método, `raise`, contratos de API).
- Re-encoding dos arquivos `.pas` — ambos são UTF-8 sem BOM e devem permanecer assim.
- As duas published `TestNilHandle_AllMembers_Raises` (delegam com uma linha, sem mudança).
- Comentários de `for..in` em `:97`/`:56` das cascas (corretos — são da #27).
- Corpo do bloco `Attributes` em `:1550-1565` (já está correto).

## 4. Regras de negócio / Convenções vigentes

**D1 — XMLDoc `///` uniforme.** Documento público: `<summary>` + `<remarks>` idênticos
para membros com o mesmo contrato. Os seis membros de nil-handle devem ter a mesma
cláusula `<remarks>`.

**D2 — Proibição de âncora de linha nova.** Todo ponteiro para código usa nome de
símbolo, nunca número de linha — lição registrada na #169 e no acceptance da #62.

**D3 — Fronteira de compilador declarada, não simulada.** O PR body afirma o que foi
executado (`FPC 3.2.2 x86_64`); i386 e os 4 alvos Delphi ficam explicitamente com o
mantenedor. Nenhuma caixa não executada é marcada.

**D4 — Um cenário, duas cascas.** Quando `UScenarios.RTTI.pas` (shared) documenta N
membros, as cascas `UTestMS.RTTI.pas` (Delphi e FPC) replicam o mesmo comentário.
O drift "cinco → seis" existe nos três arquivos e deve ser corrigido nos três.

## 5. Critérios de aceite

Derivados diretamente do acceptance da issue #62:

- [ ] O XMLDoc de `TModernVisibility` não afirma nenhuma garantia de compilador não
      medida, e nomeia o que **cada** compilador de fato faz.
- [ ] Os comentários de `Scenario_NilHandle_AllMembers_Raises` dizem **seis** membros
      e **igualdade estrita** (não "cita").
- [ ] `Attributes` ganha a mesma cláusula `<remarks>` de nil dos cinco irmãos.
- [ ] `UScenarios.RTTI.pas:145` cita `Scenario_SetType_ElementType` por **nome**, não
      por número de linha.
- [ ] **Nenhuma citação de linha nova** é introduzida pelo PR.
- [ ] Verde nos dois compiladores e nos dois bitness (FPC x86_64 coberto pelo ciclo;
      i386 e 4 alvos Delphi declarados como fronteira do mantenedor, não simulados).

## 6. Restrições

- Editar **apenas as linhas que mudam** — não reencodar os arquivos `.pas`.
- A troca da âncora (item 1) é aplicada **antes** das demais edições.
- A substituição em cada casca usa a frase inteira "nos cinco membros afetados" como
  âncora — nunca a palavra "cinco" solta (dois "cinco" distintos por arquivo).

## 7. Riscos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| Substituição cega de "cinco" em cascas corrompe comentário correto | Média | Ancorar pela frase inteira — `:97`/`:56` é correto e não deve ser tocado |
| Re-encoding inadvertido do `.pas` | Baixa | Editar só as linhas-alvo, verificar diff |
| Nova âncora de linha introduzida acidentalmente | Baixa | Proibição explícita no acceptance (D2) |
| Erro de compilação | Muito baixa | Nenhuma linha executável muda |
