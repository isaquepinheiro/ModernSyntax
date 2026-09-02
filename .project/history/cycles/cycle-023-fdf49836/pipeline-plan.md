---
type: plan
kind: artifact
title: "PLAN — issue #57: quatro residuos dos ciclos #45/#46 (slice unico)"
description: "Slice unico: quatro pontos cirurgicos em dois arquivos (comentarios + assercao) mais registro no ADR deste ciclo. Um commit. Verdict: fits."
status: draft
cycle: "023"
agent: architect
workflow: equipe-chore
node: architect
resource: aefos://run/fdf49836e67b5746f5350a3fb741afd3
tags: [rtti, plan, issue-57, chore, fpc]
generated:
  by: "equipe-chore@node:architect"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — Issue #57"
  - id: adr
    resource: "adr.md"
    title: "ADR — Issue #57"
---

# PLAN — Issue #57: Quatro residuos dos ciclos #45/#46

**Verdict:** `fits` — quatro mudancas cirurgicas de texto/assercao em dois
arquivos, totalmente independentes entre si mas inseparaveis como entrega
(sem item 3 fortalecido, a suite nao cobre a mutacao; sem item 4 removido,
um comentario mente sobre codigo inexistente). Cabem num commit so.

---

## Slice 1 (unico) — Quatro pontos cirurgicos, um commit

### Passo A — Comentario historico de `TCor` (UScenarios.RTTI.pas:143-145)

**O que fazer:** atualizar a ultima frase do bloco que descreve `TCor`,
`TDia`, D-43.9 e o off-by-one. A frase atual diz que nenhum cenario exerce
`TCor`. Hoje e falsa: o cenario 10 da #46 usa `TSetCor46 = set of TCor`
(assercao em `:1419-1422`).

**Mudanca:** reescrever apenas a ultima frase para citar o cenario 10 da #46.
O corpo tecnico (D-43.9, off-by-one com 3 elementos, motivo de `TDia` ter 7)
permanece intacto.

**Arquivo:** `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | Linhas 143-145

---

### Passo B — Comentario de `TRecordFixture45M` (UScenarios.RTTI.pas:1303-1304)

**O que fazer:** reescrever o comentario que afirma que nenhuma constante
passa nas quatro assercoes. Falso: em 32-bit ambas as fixtures medem 8,
entao a constante `8` passa verde no i386.

**Forma correta:** `TRecordFixture45M` (managed) so diverge em 64-bit; a
protecao anti-backend-constante nao vive na fixture isolada, mas na matriz
de seis alvos rodando nos dois bitness.

**Arquivo:** `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | Linhas 1303-1304

---

### Passo C — Cenario 7: comentario de bloco + assercao de identidade (UScenarios.RTTI.pas:1326-1341)

**O que fazer (tres partes encadeadas):**

1. **Reescrever o comentario de bloco** `:1326-1331` espelhando a redacao de
   `:1249-1253` (cenario do ponteiro — ja contem a medicao FPC/Delphi e CA-5).
   Nao inventar frase nova.

2. **Manter** as linhas `:1340-1341` (`if LArr.ElementType.IsNil then Fail(...)`)
   como pre-condicao de diagnostico.

3. **Acrescentar** logo abaixo a assercao de identidade:
   ```pascal
   if LArr.ElementType.Name <> TModernRTTI.GetType(TypeInfo(Integer)).Name then
     Fail('ElementType(TArr5Int46) nao e Integer — handle identico esperado.');
   ```
   Mesmo formato de `Scenario_PointerType_ReferredType_Matches:1256-1259`.

**Por que `TypeInfo(Integer)` e nao `TypeInfo(LongInt)`:** FPC 3.2.2 devolve
`LongInt`; Delphi devolve `Integer`. A forma por referencia absorve porque
ambos os operandos passam pela mesma normalizacao. Literal quebra num lado;
trocar so muda de lado. (D-57.3)

**Arquivo:** `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | Linhas 1326-1341

---

### Passo D — Remover comentario fantasma em ArrayTypeLength (RTTI.FPC.pas:708-709)

**O que fazer:** remover as duas linhas de comentario que descrevem um
`Result := 0` inexistente. Nao adicionar o default. (D-57.1)

**Arquivo:** `Source/ModernSyntax.RTTI.FPC.pas` | Linhas 708-709

---

### Commit e validacao

- **Um commit** com os quatro passos (A+B+C+D).
- **Build FPC:** `rm -rf <out> && fpc -Mdelphi -Fu"Source" -Fu"Test Shared/EclbrSystem" -FU<out> -FE<out> PTestRTTI.lpr` nos dois bitness (i386 e x86_64). Suite verde em ambos.
- **Build Delphi:** exercitado e declarado pelo autor no PR.
- **Acceptance de mutacao (item 3):** executar `GetTypeData(P)^.ArrayData.ElType => P` em `RTTI.FPC.pas:686` nos dois bitness apos o fix e confirmar que ambos ficam vermelhos. Log anexado ao PR. (D-57.4)

---

## Ordem de execucao sugerida

A, B, C, D — independentes entre si; ordem so facilita a leitura do diff
(comentarios de bloco antes, remocao de comentario de producao por ultimo).
