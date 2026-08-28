---
type: cycle-report
kind: report
cycle: "003"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/92fccbce1ddb8c2d37df799793017636
title: "Cycle 003 — architect report (issue #7, ModernRTTI callbacks foundation)"
description: "Especificação, decisões e plano para a unit ModernSyntax.Callback (três interfaces sem GUID + factory Callback.Of), com renomeação para IModern* decidida no gate e a convenção FPCUnit + Test Shared + duas cascas finas fixada como padrão da família ModernRTTI."
status: stable
tags: [architect, cycle-report, modernrtti, callbacks, issue-7]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-28T10:40:00Z"
---

# Architect — cycle 003 (issue #7)

Demanda: **[maestro repo=isaquepinheiro/ModernSyntax issue=7]** —
implementar a fundação de callbacks da camada ModernRTTI. Investigação
para esta issue: **PRESENT** (run `d8638f50`, comentário no issue).

## O que foi produzido neste ciclo

Quatro artefatos em `.project/pipeline/`:

- [pipeline-esp](pipeline-esp.md) — especificação formal (objetivo,
  escopo, RN, critérios, restrições, riscos).
- [pipeline-adr](pipeline-adr.md) — decisões arquiteturais, derivadas
  do relatório de investigação; onde o ADR **estende** o relatório está
  dito com todas as letras.
- [pipeline-plan](pipeline-plan.md) — quatro fatias sequenciais no
  mesmo ciclo (`scope = fits`).
- [pipeline-task-input](pipeline-task-input.md) — handoff operacional
  para o implementador com checklist de aceite e verificação de PR.

## Decisões que este ciclo fecha

1. **Nome dos três contratos** — decidido no gate (D-A9 do ADR):
   `IModernFunc<T,R>`, `IModernProc<T>`, `IModernPredicate<T>`. Diverge
   do texto da issue e do PRD (que dizem `IMS*`) por medição — em 9
   interfaces públicas do repositório apenas 1 usa `IMS` e é código
   morto (`IMSObserver`); o padrão vivo é `IModern*`. Divergência
   **declarada**, não silenciosa; o PR anuncia.
2. **Convenção de teste da família ModernRTTI** — herdada do relatório
   (D-1, D-2): `Test FPC/EclbrSystem/` como novo diretório espelhado;
   FPCUnit no lado FPC (nativo, medido), DUnitX no lado Delphi (não
   vendorizado, medido); lógica dos cenários **uma vez** em
   `Test Shared/EclbrSystem/`; cascas finas com uma linha útil por
   caso. Consequência anotada no ADR (D-A7): a issue #8, que foi
   despachada sem investigação e planeja rodar DUnitX no lado FPC, tem
   um problema **hoje** — e este é o único lugar onde essa medição está
   escrita.
3. **Escopo do factory `Callback.Of`** — só método de objeto neste
   ciclo (D-A6 do ADR, seguindo D-4 do relatório). Sem `TFunc<T,R>` sob
   `{$IFNDEF FPC}` — a alternativa cria armadilha pior que a ausência.
4. **`uses` da unit** — apenas `SysUtils` (D-A1 do ADR). Qualquer outra
   unit da biblioteca reintroduz `reference to` ou o `.inc` bugado
   (`{$IFDEF FCP}`, R3 do PRD).
5. **Correção de medição** — o PRD e o issue dizem 451 usos de
   `TProc`/`TFunc`; o relatório mediu **415**. Registrado no ADR
   (D-A10) para não repetir o número errado a jusante.

## Scope estimate

`scope = fits`, quatro fatias sequenciais.

- **Test 1 (SIZE):** unit enxuta (três interfaces + factory + três
  wrappers privados) mais três projetos de teste (dois já são
  espelhados dos existentes; um é novo diretório Lazarus). Cabe em um
  orçamento normal de implementação.
- **Test 2 (INDEPENDENCE):** nenhuma fatia é mergeável sozinha. Sem
  cenários compartilhados, a casca não roda; sem casca FPC, CA-6 do
  PRD falha; sem a unit, os cenários não compilam. Split violaria a
  fundação.

## Riscos relevantes elevados no dossiê

- **RSK-1** (esp): cascas divergindo em silêncio. Mitigação: lógica
  única em `Test Shared/`; cascas com **até uma linha útil** por caso
  (proibido `if/then` de asserção na casca).
- **RSK-2** (esp): nome dos contratos — **resolvido** neste gate.
- **RSK-3/4** (esp): search path do `.dproj` para `Test Shared/` e
  formato de saída do FPCUnit para CI. Não medidos; RSK-3 resolvido em
  implementação (adiciona uma linha); RSK-4 não bloqueia esta entrega.

## Cross-links (do bundle)

- [analysis intake](/analysis/00-intake.md) — stack Object Pascal Delphi
  XE+, ModernSyntax, DUnitX em `Test Delphi/`.
- [analysis architecture](/analysis/03-architecture.md) — padrão
  `TRttiContext` compartilhado em `Objects.pas:191-201` (referência
  para futuros pilares; não usado nesta unit por RN-5 do esp).
- [PRD ModernRTTI](/strategy/2026-08-27-modernrtti/PRD.md) — D2, D3,
  D4, R2, R3, CA-4, CA-5, CA-6, CA-7.
- [Study ModernRTTI](/strategy/2026-08-27-modernrtti/STUDY.md) —
  medições de FPC 3.2.2 e do bug `{$IFDEF FCP}`.
