---
type: spec
kind: artifact
title: "ESP — Quatro residuos de documentacao/teste dos ciclos #45 e #46 (issue #57)"
description: "Corrigir quatro residuos cirurgicos em dois arquivos: um comentario falso provado por mutacao, um comentario que descreve codigo inexistente, uma assercao fraca (IsNil sem identidade) e um comentario historico envelhecido."
status: draft
cycle: "023"
agent: architect
workflow: equipe-chore
node: architect
resource: aefos://run/fdf49836e67b5746f5350a3fb741afd3
tags: [rtti, chore, issue-57, fpc, test-quality, documentation]
generated:
  by: "equipe-chore@node:architect"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: issue-57
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/57"
    title: "Issue #57 — Quatro residuos de documentacao/teste dos ciclos #45 e #46"
  - id: investigation
    title: "Relatorio de investigacao — Issue #57 (run 1daaaf49674847d8b1dfce5ce677b694) — PRESENT"
  - id: adr
    resource: "adr.md"
    title: "ADR — issue #57"
  - id: plan
    resource: "plan.md"
    title: "PLAN — issue #57"
  - id: task-input
    resource: "task-input.md"
    title: "TASK-INPUT — issue #57"
---

# ESP — Issue #57: Quatro residuos de documentacao/teste (ciclos #45 e #46)

## 1. Objetivo

Eliminar quatro residuos deixados pelos ciclos anteriores em dois arquivos
(`Test Shared/EclbrSystem/UScenarios.RTTI.pas` e
`Source/ModernSyntax.RTTI.FPC.pas`) que enganam quem le o codigo hoje.
Nenhuma mudanca de comportamento de producao. Um commit so.

## 2. Escopo

| # | Item | Arquivo | Linhas | Natureza |
|---|------|---------|--------|----------|
| 1 | Comentario historico envelhecido sobre `TCor` | `UScenarios.RTTI.pas` | 143-145 | Atualizacao de comentario |
| 2 | Comentario falso sobre bitness de `TRecordFixture45M` | `UScenarios.RTTI.pas` | 1303-1304 | Reescrita de comentario |
| 3 | Assercao fraca no cenario 7 (so `IsNil`, sem identidade) | `UScenarios.RTTI.pas` | 1326-1341 | Reescrita de comentario de bloco + nova linha de assercao |
| 4 | Comentario descrevendo `Result := 0` inexistente | `Source/ModernSyntax.RTTI.FPC.pas` | 708-709 | Remocao de duas linhas de comentario |

## 3. Fora de escopo

- Qualquer mudanca de logica em `Source/` (alem da remocao do comentario do item 4).
- Adicionar `Result := 0` em `ArrayTypeLength` por simetria estetica com `:435`
  (o compilador nao pediu; `main 4a2a606` compila 16/16 unidades com 0 erros/0 warnings).
- Trocar `TypeInfo(Integer)` por `TypeInfo(LongInt)` no cenario 7
  (literal quebra num dos dois compiladores; a forma por referencia e a unica que absorve).
- Aliasing de substring nos asserts de `Scenario_NilHandle_AllMembers_Raises`
  (endereçado na issue #56).
- Edicao de ADR de ciclo anterior (`cycle-019/pipeline-adr.md`) — proibido por D-42.2.

## 4. Regras de negocio

**BR-1 — Zero regressao de comportamento:** nenhuma funcao, interface ou schema
muda. A unica mudanca em `Source/` e remocao de duas linhas de comentario.

**BR-2 — Assercao IsNil como pre-condicao:** o item 3 MANTEM a linha `IsNil`
como pre-condicao (diagnostico mais claro quando o handle vem nulo) e ACRESCENTA
a identidade por referencia logo abaixo, espelhando o padrao de
`Scenario_PointerType_ReferredType_Matches:1256-1259`.

**BR-3 — Comparacao por referencia via `TModernRTTI.GetType`:** FPC 3.2.2
devolve `LongInt`; Delphi devolve `Integer`. Literal quebra num dos lados;
a forma por referencia absorve porque ambos os operandos passam pela mesma
normalizacao. Nenhum `{$IFDEF FPC}` — CA-5 preservado.

**BR-4 — Comentario de bloco do cenario 7 espelha :1249-1253:** nao inventar
frase nova; a redacao canonica ja esta no arquivo no cenario do ponteiro.

**BR-5 — Um commit:** os quatro itens sao independentes, mas cabem num diff
pequeno. Quatro commits seriam prosa e teatro de bisect.

## 5. Criterios de aceitacao

- [ ] Comentario em `:143-145` atualizado citando o cenario 10 da #46
      (`TSetCor46 = set of TCor`, assercao em `:1419-1422`); corpo tecnico
      (D-43.9, off-by-one com 3 elementos) intacto.
- [ ] Comentario em `:1303-1304` reescrito: `TRecordFixture45M` (managed)
      so diverge em 64-bit; protecao anti-backend-constante vem da matriz de
      seis alvos rodando nos dois bitness.
- [ ] Cenario 7 (`Scenario_DynamicArrayType_ElementType`):
      - Linhas `:1340-1341` (`IsNil`) mantidas como pre-condicao.
      - Nova assercao de identidade acrescentada logo abaixo:
        `LArr.ElementType.Name <> TModernRTTI.GetType(TypeInfo(Integer)).Name`.
      - Comentario de bloco `:1326-1331` reescrito espelhando `:1249-1253`.
- [ ] Duas linhas de comentario em `RTTI.FPC.pas:708-709` removidas; nenhum
      `Result := 0` adicionado.
- [ ] Suite verde nos dois compiladores e nos dois bitness (FPC i386 e x86_64).
      (Delphi: declarado pelo autor; nao compilavel na factory.)
- [ ] **Acceptance de mutacao (obrigatoria para fechar o item 3):** apos o fix,
      a mutacao `GetTypeData(P)^.ArrayData.ElType -> P` em
      `Source/ModernSyntax.RTTI.FPC.pas:686` mata nos DOIS bitness (i386 e
      x86_64). Log da mutacao anexado ao corpo do PR — mesma disciplina das
      mutacoes obrigatorias da #46.
- [ ] Zero mudanca em `Source/` alem da remocao do comentario do item 4.

## 6. Restricoes

- **Compiladores:** FPC 3.2.2 (i386 e x86_64) exercitado pela factory.
  Delphi exercitado pelo autor e declarado explicitamente no PR.
- **Um commit:** conforme decidido na investigacao (Volta 1, Q5).
- **Sem `{$IFDEF FPC}`** no arquivo de cenarios — CA-5 do projeto.

## 7. Riscos

**R-1 — Assercao nova revela defeito real:** se o backend devolver handle
errado para `Integer` em qualquer bitness apos o fix, a suite ficara vermelha.
Nao e risco de regressao introduzida pelo PR — e defeito preexistente,
mascarado pela assercao fraca. A acceptance exige investigar antes de seguir.
Probabilidade: baixa (os cenarios 8, 9 e 10 da mesma leva ja passam com a
forma por referencia); impacto: bloqueante.
