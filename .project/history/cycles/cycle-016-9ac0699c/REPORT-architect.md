---
type: cycle-report
kind: report
title: "REPORT — architect (cycle 016, issue #43)"
description: "Design dossier para TModernRTTIEnumerationType: quatro artefatos escritos em .project/pipeline/ derivando o ADR do relatorio de investigacao (PRESENT, run b8a0a2127f0d65070d91cfa172df44ac); ESP/plan/task-input especificam a entrega ampliada (quatro cenarios, fixture TDia, guards de M-1/M-2 nos dois backends). Escopo julgado 'fits'."
status: stable
cycle: "016"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/9ac0699c1b65c18950220f022dfbb179
tags: [modernrtti, architect, cycle-report, issue-43, fits]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-01T00:00:00Z"
---

# REPORT — architect (cycle 016)

## Demanda

Issue #43 do parent #29 (categoria RTTI Enumeration). Sub-issue segunda
do parent (primeira foi #42, Visibility, entregue no cycle 015).

## Insumos

- **Relatorio de investigacao (PRESENT)** — run
  `b8a0a2127f0d65070d91cfa172df44ac`, uma volta com o autor. Quatro
  medicoes M-1..M-4 do FPC 3.2.2 nos dois bitness que definem o
  contrato de erros e a forma da fixture. Absorvido integralmente pelo
  ADR desta cycle sem divergencia de merito.
- **Analise do bundle** (`.project/analysis/*`, `.project/SKILL.md`).
- **Ciclos anteriores relevantes:** #42 (cycle 015 — D-1, D-2 vieram
  dali), #25 (cycle 010 — D-4).

## Artefatos produzidos

Todos em `.project/pipeline/`:

- [pipeline-esp.md](pipeline-esp.md) — escopo por arquivo, 14
  criterios de aceitacao, 4 riscos, 5 restricoes. Deriva da issue
  (nao do relatorio); reflete a ampliacao acordada (dois cenarios ->
  quatro, `TCor` -> `TCor + TDia`).
- [pipeline-adr.md](pipeline-adr.md) — nove decisoes numeradas
  D-43.1..D-43.9 restatando a conversa; secao "Descartado" com sete
  alternativas rejeitadas por medicao (M-1, M-2, M-4, M-3). Derivado
  do relatorio verbatim.
- [pipeline-plan.md](pipeline-plan.md) — tres slices sequenciais
  interdependentes (nao mergeaveis isoladamente), portao de
  compilacao FPC nos dois bitness.
- [pipeline-task-input.md](pipeline-task-input.md) — handoff para
  o implementador com checklist de 20 itens, convencoes governantes,
  notas para PR (mutacao obrigatoria + alarme M-3).

## Verdict do split guard

**`fits`** — 6 arquivos, ~250 linhas liquidas estimadas, 3 slices
tightly coupled. Test 1 (SIZE) passa dentro do orcamento de um
`implement`; Test 2 (INDEPENDENCE) falha (nenhuma slice deploya
sozinha). Sem `split-proposal.md`. Mesma forma do cycle 015 (issue
#42).

## Decisoes-chave (resumo)

1. **`FromTypeInfo` nao valida `Kind`** (D-43.1) — para manter a unit
   publica sem `resourcestring` nova (D-1). O guard vive nos seis
   metodos do backend (D-4).
2. **Guards de M-1/M-2 nos dois backends** (D-43.3, D-43.4, D-43.6) —
   paridade de contrato de erros por construcao (D-2). Sem isso, o
   cenario negativo seria FPC-only e a mutacao passaria verde no
   Delphi.
3. **Fixture `TDia` (7 elementos) obrigatoria no cenario de contagem**
   (D-43.7) — `TCor` (3 elementos) nao mata a mutacao `MaxValue-1`
   (M-4). `TCor` fica declarado mas nao exercitado hoje (D-43.9).
4. **M-3 vira alarme escrito no ADR** — se o FPC passar a emitir RTTI
   para enums descontinuos, o laco `MinValue..MaxValue` reintroduz o
   risco. O ADR e o "nao otimize" para o proximo agente.

## Convencoes reusadas

- D-1 (cycle 015): casca publica sem `{$IFDEF}` novo.
- D-2 (cycle 015): paridade de assinatura nos dois backends.
- D-4 (cycle 010): guarda por `Kind` no FPC, cada funcao.
- D-6 (padrao do repo): assertivas por relacao, nao por posicao.
- D-26 (do relatorio): nao devolver valor que tambem e resposta
  legitima.
- CA-5 (padrao do repo): zero `{$IFDEF}` em `UScenarios.RTTI.pas`.

## Perguntas em aberto

Nenhuma. O relatorio de investigacao fechou Q1 e Q3 na propria conversa
(volta 1).
