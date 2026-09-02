---
type: task
kind: artifact
title: "TASK-023 — chore: quatro residuos de documentacao/teste dos ciclos #45 e #46 (issue #57)"
description: "Dois arquivos, quatro pontos cirurgicos, um commit: comentario TCor, comentario TRecordFixture45M, cenario 7 com assercao de identidade, remocao de comentario fantasma."
cycle: "023"
agent: planner
workflow: equipe-chore
node: task
resource: aefos://run/fdf49836e67b5746f5350a3fb741afd3
status: draft
tags: [task, modernrtti, issue-57, chore, rtti, fpc, cycle-023]
generated:
  by: "equipe-chore@node:task"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: task-input
    resource: "task-input.md"
    title: "TASK-INPUT — issue #57"
  - id: gh-57
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/57"
    title: "Issue #57 — Quatro residuos dos ciclos #45/#46"
---

# TASK-023 — Issue #57: Quatro residuos dos ciclos #45/#46

## Tracking

- **Modo:** MAESTRO MODE
- **Issue original:** [#57](https://github.com/isaquepinheiro/ModernSyntax/issues/57)
  (demanda criada pelo maestro — `aefos:running`)
- **Epic:** nenhum Epic preexistente identificado para este chore; nenhum criado (MAESTRO MODE)
- **Board:** issue #57 carrega `aefos:running` (sem card em project board)

## Demanda em uma linha

Quatro pontos cirurgicos em dois arquivos que ficaram imprecisos ou incompletos apos os
ciclos #45 e #46: um comentario que descreve comportamento nao mais verdadeiro (A), um
comentario que nao reflete a protecao real de bitness (B), um cenario 7 sem assercao de
identidade para `ElementType` (C), e duas linhas de comentario fantasma no backend FPC (D).

## Escopo

| # | Arquivo | Linhas | Mudanca |
|---|---------|--------|---------|
| A | `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | 143-145 | Ultima frase de `TCor` cita cenario 10 da #46 |
| B | `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | 1303-1304 | Comentario: managed so diverge em 64-bit; anti-constante vem da matriz |
| C | `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | 1326-1341 | Bloco reescrito espelhando :1249-1253; assercao de identidade acrescentada |
| D | `Source/ModernSyntax.RTTI.FPC.pas` | 708-709 | Duas linhas de comentario fantasma removidas |

## Detalhes de implementacao

### A — Comentario de `TCor` (:143-145)

Substituir *"nao ha cenario que o exercite"* por texto que cite o cenario 10 da #46
(`TSetCor46 = set of TCor`, assercao em `:1419-1422`). Corpo tecnico intacto.

### B — Comentario de `TRecordFixture45M` (:1303-1304)

Reescrever para dizer: managed so diverge em 64-bit (em 32-bit ambas medem 8, entao
constante `8` passa verde); a protecao anti-backend-constante vem da matriz de seis
alvos rodando nos dois bitness, nao da fixture isolada.

### C — Cenario 7 (:1326-1341)

1. **Comentario de bloco (:1326-1331):** espelhar a redacao de `:1249-1253` (cenario
   do ponteiro). Usar texto canonico ja existente no arquivo — nao inventar frase nova.
2. **Manter** `:1340-1341` (`if LArr.ElementType.IsNil then Fail(...)`) como pre-condicao.
3. **Acrescentar** logo abaixo:
   ```pascal
   if LArr.ElementType.Name <> TModernRTTI.GetType(TypeInfo(Integer)).Name then
     Fail('ElementType(TArr5Int46) nao e Integer — handle identico esperado.');
   ```
   Usar `TypeInfo(Integer)` — nao `TypeInfo(LongInt)`.

### D — Comentario fantasma (:708-709)

Remover as duas linhas inteiras. Nao adicionar `Result := 0`.

## O que NAO fazer

- Nao adicionar `Result := 0` em `ArrayTypeLength` (D-57.1).
- Nao usar `TypeInfo(LongInt)` no cenario 7 (D-57.3).
- Nao descartar o `IsNil` como redundante (D-57.2).
- Nao editar `cycle-019/pipeline-adr.md` (D-42.2 proibe editar ADR de ciclo anterior).
- Nao tocar aliasing em `Scenario_NilHandle_AllMembers_Raises` (escopo da #56).

## Checklist de acceptance

- [ ] **A:** bloco `:143-145` cita cenario 10 da #46; corpo tecnico intacto.
- [ ] **B:** comentario `:1303-1304` diz que managed so diverge em 64-bit e anti-constante vem da matriz.
- [ ] **C.1:** comentario `:1326-1331` espelha `:1249-1253` sem inventar.
- [ ] **C.2:** linhas `:1340-1341` (`IsNil`) mantidas como pre-condicao.
- [ ] **C.3:** assercao de identidade por `.Name` acrescentada logo abaixo do `IsNil`.
- [ ] **D:** linhas `:708-709` removidas; nenhum `Result := 0` adicionado.
- [ ] **Build FPC i386:** suite verde apos `rm -rf <out>` + compilacao limpa.
- [ ] **Build FPC x86_64:** suite verde apos `rm -rf <out>` + compilacao limpa.
- [ ] **Build Delphi:** declarado pelo autor no PR.
- [ ] **Mutacao (obrigatoria):** `GetTypeData(P)^.ArrayData.ElType => P` em `RTTI.FPC.pas:686` mata nos DOIS bitness. Log no PR.
- [ ] **Um commit** com os quatro itens.
- [ ] **Zero mudanca comportamental** em `Source/` alem da remocao de comentario do item D.
