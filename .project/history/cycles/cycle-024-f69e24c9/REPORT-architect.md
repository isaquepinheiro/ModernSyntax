---
type: cycle-report
kind: report
title: "REPORT-architect — Ciclo 24 (issue #62): correções documentais restantes da #57 + âncora PR #61"
description: "Dossier de arquitetura: sete edições de XMLDoc/comentário em 4 arquivos, scope=fits, slice único, um commit."
cycle: 24
agent: architect
workflow: equipe-chore
node: architect
resource: aefos://run/f69e24c9cc1b815b6d73589b1c79f193
generated:
  by: equipe-chore@node:architect
  at: "2026-09-02T00:00:00Z"
tags: [cycle-024, issue-62, chore, documentation, xmldoc, rtti]
---

# REPORT-architect — Ciclo 24 (issue #62)

## O que foi demandado

Issue #62: fechar os quatro itens documentais que o PR #61 não entregou da #57,
mais corrigir a âncora de linha que o próprio PR #61 introduziu errada em `:145`.
Resultado: sete edições de texto em quatro arquivos Pascal — todas em `///` (XMLDoc)
ou `//` (comentários de linha). Nenhuma linha executável muda.

## Decisão de scope

**`fits`** — documentação pura. Sete substituições de texto, custo real < $5, sem
superfície de teste executável. As sete edições compõem um único tema ("reconciliar
documentação com realidade medida") e não são independentes entre si — entregá-las
pela metade deixaria documentação interna contraditória.

## Artefatos produzidos

- [esp](pipeline-esp.md) — spec derivada da issue (critérios de aceite, fora de escopo,
  riscos)
- [adr](pipeline-adr.md) — decisões derivadas do relatório de investigação (run
  `8810a78921ce945faf6e68362495134d`), sete decisões em duas voltas com o mantenedor
- [plan](pipeline-plan.md) — slice único, sete edições em ordem determinada, um commit
- [task-input](pipeline-task-input.md) — handoff operacional com checklist e restrições críticas

## Decisões de arquitetura registradas

| ID | Decisão | Motivo |
|---|---|---|
| D-62.1 | Cascas Delphi e FPC entram no PR | Mesmo drift semântico, custo 2 linhas; omitir criaria nova issue como a #57→4/8 |
| D-62.2 | "é exatamente `Format(SModernRTTINilHandle, [<membro>])`" | Nomeia a expressão real; "byte a byte" seria impreciso para comparação de `string` |
| D-62.3 | `<remarks>` de `Attributes` copia literal dos 5 irmãos | Uniformidade de contrato público vale mais que diferenciação por `PropAttributes` |
| D-62.4 | PR body: frase declarativa, sem checklist | aefos-studio#375 — caixa marcada sem execução já comprometeu série #296-#300 |
| D-62.5 | Texto verbatim com acentos, só as linhas que mudam | Arquivos UTF-8 sem BOM (medido); reencodar `.pas` inteiro quebra silenciosamente |
| D-62.6 | Âncora `:145` editada primeiro | Evita recontagem de linhas nas edições seguintes no mesmo arquivo |
| D-62.7 | Âncora nas cascas pela frase inteira | Dois "cinco" por casca; `:97`/`:56` (for..in da #27) é correto e não deve ser tocado |

## Convenções que governam

- **D1** — XMLDoc `///` uniforme: `<summary>` + `<remarks>` idênticos para membros
  com o mesmo contrato de nil-handle.
- **D2** — Proibição de âncora de linha nova: ponteiros em comentários usam nome de
  símbolo (lição #169, acceptance #62 item 5).
- **D3** — Fronteira de compilador declarada, não simulada: PR afirma FPC x86_64;
  i386 e Delphi ficam com o mantenedor (`SKILL.md` §2).
- **D4** — Um cenário, duas cascas: drift "cinco → seis" corrigido nos três arquivos.

## O que este ciclo não toca

`case` de `PropertyVisibility` no backend FPC (→ #60); corpo do bloco `Attributes`
em `:1550-1565` (correto); `raise` em `:1138` (já existe); as duas published
`TestNilHandle_AllMembers_Raises`; comentários de `for..in` em `:97`/`:56`; encoding
dos arquivos `.pas`.
