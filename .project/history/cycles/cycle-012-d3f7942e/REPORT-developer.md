---
type: cycle-report
kind: report
cycle: "012"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/d3f7942e59d0ba69094d93420fef84db
title: "REPORT-developer — Enumerators nas coleções (issue #27, cycle 012)"
description: "Slice 1 + Slice 2 entregues; PTestRTTI 23/23 verde x86_64; mutacao PropFields→nil derruba TestFields_ForIn_IteratesFields (exit=2); trap FPC de property helper com read <Metodo> mitigado com forwarders strict private; board flipado in-review."
tags: [modernrtti, cycle-012, issue-27, fpc, delphi, enumerators, developer]
generated:
  by: "equipe-feature@node:implement"
  at: "2026-08-31T00:00:00Z"
---

# REPORT — developer / cycle 012 / issue #27

## O que foi feito

Implementadas as duas slices do [plan](pipeline-plan.md) num unico
commit-set:

- **Slice 1 — unit publica.** `Source/ModernSyntax.RTTI.pas` recebe
  `ModernSyntax.Attributes` na `uses` da `interface`, quatro properties
  publicas no `TModernRTTITypeHelper` (`Fields`, `Properties`, `Methods`,
  `Attributes`) e uma property publica em `TModernRTTIMethod`
  (`Parameters`) com XMLDoc D-6 declarando literal a divergencia FPC.
- **Slice 2 — cenarios + cascas + mutacao.** `UScenarios.RTTI.pas` recebe
  sete cenarios novos (cinco comuns + par distinto para `Parameters`) e
  as fixtures que faltavam (`TAttrForIn`+`TAlvoForInAttrs`,
  `TEmptyForIn`, `TMethodWithParams`). Cascas FPC e Delphi recebem seis
  wrappers cada, com o par `Parameters` divergindo em qual cenario cada
  casca publica (padrao "dois cenarios distintos + duas cascas" da #25).
  ZERO `{$IFDEF}` no shared. Prova de mutacao executada (`PropFields` →
  `Result := nil` faz `TestFields_ForIn_IteratesFields` cair; exit=2) e
  revertida antes do handoff.

Board atualizado: ciclo 012 flip `in-pipeline` → `in-review` em
`.project/project-evolution.md`.

## Como foi validado

- `PTestRTTI` (FPC 3.2.2 x86_64-linux): **23/23 verde, exit=0**
  (baseline era 17 — os sete cenarios novos foram absorvidos pelos seis
  wrappers da casca FPC + o teste local `_DifferentType_...` da #26 que
  ja existia).
- Regressao verde: `PTestAttributes` (545 linhas), `PTestInvoker`
  (450), `PTestModernCallback` (513) — sem quebras por causa do
  novo `uses` na interface de `RTTI.pas` (R1 do ESP validado empiricamente).
- `grep -c "IFDEF" "Test Shared/EclbrSystem/UScenarios.RTTI.pas"` = 0.
- `grep -n "{\$IFDEF" Source/ModernSyntax.RTTI.pas` (fora de comentario) =
  apenas o `{$IFDEF FPC}` da `uses` da `implementation` — nao regride
  o ganho da #26.
- `grep -rn "AssertException" "Test Shared/" "Test FPC/" "Test Delphi/"`
  = vazio (padrao try/except + `Fail(...)` respeitado).

## Decisao tecnica principal (recem-medida)

**Trap FPC 3.2.2:** property de record helper com `read <Nome>` nao
resolve `<Nome>` contra metodos do tipo alvo — o compilador recusa com
`Unknown class field or method identifier "GetFields"`. Solucao, dentro
do escopo do plan: tres forwarders **strict private** no helper
(`PropFields`, `PropProperties`, `PropAttributes`) que delegam via
`Self.GetFields`, `Self.GetProperties` e
`ModernAttributes.GetAttributes(TRttiInstanceType(FType).MetaclassType)`.
As quatro properties publicas ficam com a superficie que o consumidor
espera (`LType.Fields`, etc.). O Delphi 12 provavelmente aceita
`read GetFields` direto tambem, mas o codigo com forwarders compila
identico nos dois. Detalhes em D-IMPL-1 do
[implement-report](pipeline-implement-report.md).

## Referencias

- [pipeline-esp](pipeline-esp.md) — criterios formais.
- [pipeline-adr](pipeline-adr.md) — decisao e o que foi descartado.
- [pipeline-plan](pipeline-plan.md) — ordem de execucao.
- [pipeline-task-input](pipeline-task-input.md) — handoff operacional.
- [pipeline-implement-report](pipeline-implement-report.md) — detalhes tecnicos, tabela de arquivos, validacoes.
