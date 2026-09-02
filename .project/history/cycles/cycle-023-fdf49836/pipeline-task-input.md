---
type: task-input
kind: artifact
title: "TASK-INPUT — issue #57: quatro residuos dos ciclos #45/#46"
description: "Handoff operacional para o implementador: quatro pontos cirurgicos em dois arquivos (comentarios + uma assercao nova), um commit, acceptance de mutacao obrigatoria para o item 3."
status: draft
cycle: "023"
agent: architect
workflow: equipe-chore
node: architect
resource: aefos://run/fdf49836e67b5746f5350a3fb741afd3
tags: [rtti, task-input, issue-57, chore, fpc]
generated:
  by: "equipe-chore@node:architect"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — Issue #57"
  - id: plan
    resource: "plan.md"
    title: "PLAN — Issue #57"
  - id: adr
    resource: "adr.md"
    title: "ADR — Issue #57"
---

# TASK-INPUT — Issue #57: Quatro residuos dos ciclos #45/#46

## Titulo

`chore: corrige quatro residuos de documentacao/teste dos ciclos #45 e #46 (#57)`

## Tipo e labels

- **type:** `chore`
- **labels:** `chore`, `test-quality`, `documentation`, `rtti`, `fpc`

## Escopo

Dois arquivos, quatro pontos cirurgicos, um commit:

| # | Arquivo | Linhas | Mudanca |
|---|---------|--------|---------|
| A | `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | 143-145 | Ultima frase do bloco `TCor` atualizada para citar cenario 10 da #46 |
| B | `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | 1303-1304 | Comentario reescrito: managed so diverge em 64-bit; anti-constante vem da matriz |
| C | `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | 1326-1341 | Bloco reescrito espelhando :1249-1253; `IsNil` mantido como pre-condicao; assercao de identidade acrescentada |
| D | `Source/ModernSyntax.RTTI.FPC.pas` | 708-709 | Duas linhas de comentario fantasma removidas |

## Detalhes de implementacao

### A — Comentario de `TCor` (:143-145)

Apenas a ultima frase do bloco muda. Substituir *"nao ha cenario que o exercite"*
por texto que cite o cenario 10 da #46 (`TSetCor46 = set of TCor`, assercao
em `:1419-1422`). O corpo tecnico (D-43.9, off-by-one com 3 elementos, `TDia`
de 7) permanece.

### B — Comentario de `TRecordFixture45M` (:1303-1304)

Reescrever para dizer: `TRecordFixture45M` (managed) so diverge em 64-bit
(em 32-bit ambas as fixtures medem 8, entao constante `8` passa verde); a
protecao anti-backend-constante vem da matriz de seis alvos rodando nos dois
bitness, nao da fixture isolada.

### C — Cenario 7 (:1326-1341)

1. **Comentario de bloco (:1326-1331):** espelhar a redacao de `:1249-1253`
   (cenario do ponteiro). Nao inventar frase nova — o texto canonico ja existe
   no arquivo.

2. **Manter** `:1340-1341` (`if LArr.ElementType.IsNil then Fail(...)`) como
   pre-condicao.

3. **Acrescentar** logo abaixo:
   ```pascal
   if LArr.ElementType.Name <> TModernRTTI.GetType(TypeInfo(Integer)).Name then
     Fail('ElementType(TArr5Int46) nao e Integer — handle identico esperado.');
   ```
   Usar `TypeInfo(Integer)` — nao `TypeInfo(LongInt)`. A forma por referencia
   absorve a divergencia FPC=LongInt/Delphi=Integer; literal quebra num dos lados.

### D — Comentario fantasma (:708-709)

Remover as duas linhas inteiras. Nao adicionar `Result := 0`.

## Checklist de acceptance

- [ ] **A:** bloco `:143-145` cita o cenario 10 da #46; corpo tecnico intacto.
- [ ] **B:** comentario `:1303-1304` diz que managed so diverge em 64-bit e
      que anti-constante vem da matriz de seis alvos.
- [ ] **C.1:** comentario de bloco `:1326-1331` espelha `:1249-1253` (sem inventar).
- [ ] **C.2:** linhas `:1340-1341` (`IsNil`) mantidas como pre-condicao.
- [ ] **C.3:** assercao de identidade por `.Name` acrescentada logo abaixo do `IsNil`.
- [ ] **D:** linhas `:708-709` removidas; nenhum `Result := 0` adicionado.
- [ ] **Build FPC i386:** suite verde apos `rm -rf <out>` + compilacao limpa.
- [ ] **Build FPC x86_64:** suite verde apos `rm -rf <out>` + compilacao limpa.
- [ ] **Build Delphi:** declarado pelo autor no PR (nao compilavel na factory).
- [ ] **Mutacao (obrigatoria):** apos o fix, `GetTypeData(P)^.ArrayData.ElType => P`
      em `RTTI.FPC.pas:686` mata nos DOIS bitness. Log da mutacao no corpo do PR.
- [ ] **Um commit** com os quatro itens.
- [ ] **Zero mudanca comportamental** em `Source/` alem da remocao de comentario do item D.

## Arquivos provavelmente impactados

```
Test Shared/EclbrSystem/UScenarios.RTTI.pas   (tres pontos: A, B, C)
Source/ModernSyntax.RTTI.FPC.pas              (um ponto: D)
```

## O que NAO fazer

- Nao adicionar `Result := 0` em `ArrayTypeLength` (compilador nao pediu; D-57.1).
- Nao usar `TypeInfo(LongInt)` no cenario 7 (quebraria no Delphi; D-57.3).
- Nao descartar o `IsNil` como redundante (pre-condicao da mensagem melhor; D-57.2).
- Nao editar `cycle-019/pipeline-adr.md` (D-42.2 proibe editar ADR de ciclo anterior).
- Nao tocar aliasing em `Scenario_NilHandle_AllMembers_Raises` (escopo da #56).
