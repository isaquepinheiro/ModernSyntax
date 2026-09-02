---
type: retrospective
kind: report
title: "REPORT-retrospective — ciclo 021 (issue #56)"
description: "Ciclo limpo, zero reworks; uma fricção de spec (resourcestring privada) resolvida inline pelo developer sem rejeição de qualidade."
cycle: "021"
agent: retrospective
workflow: equipe-bug
node: retrospective
resource: aefos://run/09743779c7c9860b5fa380f6979d94ca
tags: [retrospective, cycle-021, issue-56, nil-handle, flow-feedback]
generated:
  by: "equipe-bug@node:retrospective"
  at: "2026-09-02T17:30:00Z"
---

# REPORT-retrospective — Ciclo 021

## Status geral

**Ciclo limpo. Zero reworks. Custo de qualidade mínimo (uma passagem única por todos os lenses).**

Todos os REPORT-*.md esperados estão presentes no diretório do ciclo:
[REPORT-planner](REPORT-planner.md) · [REPORT-architect](REPORT-architect.md) ·
[REPORT-developer](REPORT-developer.md) · [REPORT-quality-verify](REPORT-quality-verify.md) ·
[REPORT-quality-test](REPORT-quality-test.md) · [REPORT-quality-review](REPORT-quality-review.md) ·
[REPORT-release](REPORT-release.md).

Não há `decisions-review.md`, `decisions-test.md` nem `decisions-verify.md` — ausência esperada e correta: nenhuma rejeição ocorreu.

---

## Iterações por lens

| Lens    | Rejeições | Veredicto final |
|---------|-----------|-----------------|
| verify  | 0         | PASSED          |
| test    | 0         | APPROVED        |
| review  | 0         | APPROVED        |

---

## Rework analysis

**Nenhum rework.** Não há causas a classificar nem nodes a culpar.

---

## Fricção operacional (não bloqueante)

Embora não tenha gerado rejeição de qualidade, o ciclo registrou uma fricção de spec documentada em
[FLOW-FEEDBACK](FLOW-FEEDBACK.md):

**Causa raiz:** o ESP/ADR/plan especificavam `Format(SModernRTTINilHandle, ...)` no cenário compartilhado
(`UScenarios.RTTI.pas`) sem verificar que `SModernRTTINilHandle` estava declarada em `implementation`
(privada). O primeiro build falhou com seis erros `Identifier not found`.

**Classificação:** `spec` — a especificação não mapeou a visibilidade do símbolo antes de prescrevê-lo
ao consumidor. Node blamed: `architect` (ESP §2.2 + ADR D-56.2/D-56.3 + plan §Passo 1 são de
responsabilidade do architect).

**Resolução:** o developer promoveu `SModernRTTINilHandle` para o `interface` (opção coerente com o
ADR), preencheu o FLOW-FEEDBACK, e todos os três lenses de qualidade aprovaram sem objeção bloqueante.

**Impacto de custo:** como a fricção foi absorvida no próprio node `implement` (sem rework), não gerou
passes extras de qualidade. Custo zero em termos de loops de pipeline. Se a mesma classe de defeito
ocorrer em issues com múltiplos símbolos escondidos em `implementation`, o custo pode crescer — mas
neste ciclo não foi o caso.

**Causa dominante neste ciclo:** `spec` (não `model`). Um modelo mais forte no node `architect` não
teria necessariamente prevenido o defeito — a checklist de visibilidade de símbolo simplesmente não
estava no template. A alavanca correta é um fix de processo/spec, não upgrade de modelo.

---

## Nota sobre o PR

O PR [#58](https://github.com/isaquepinheiro/ModernSyntax/pull/58) foi aberto pelo committer ao final
do ciclo. Uma seção **## Rework analysis** seria pertinente no corpo desse PR para contextualizar a
decisão de promoção de `SModernRTTINilHandle` ao `interface`. Esta análise vive neste relatório —
o PR não foi emendado (o committer já encerrou o ciclo).

---

## Recomendação (uma, concreta, sugestão apenas)

**Adicionar ao template de ESP/ADR do node `architect` uma checklist de visibilidade de símbolo:**

> Para cada símbolo de `Source/` referenciado por `Test Shared/EclbrSystem/*.pas`, verificar com
> `grep` se ele está no bloco `interface`. Se estiver em `implementation`, decidir no ADR: promoção
> ou literal duplicado — não deixar a decisão para o `implement`.

Custo: dois `grep` por símbolo novo. Benefício: elimina a decisão ad-hoc de superfície pública no
node `implement`, que excede o papel do developer.

Esta recomendação é uma sugestão para o humano responsável pelo pipeline — não foi auto-aplicada.
