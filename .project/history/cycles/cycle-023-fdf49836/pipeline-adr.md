---
type: adr
kind: artifact
title: "ADR — Decisoes da issue #57 (quatro residuos dos ciclos #45/#46)"
description: "Registro das decisoes acordadas na investigacao: remover comentario fantasma em ArrayTypeLength, manter IsNil como pre-condicao no cenario 7, comparacao por referencia via TModernRTTI.GetType, e medicao FPC=LongInt/Delphi=Integer."
status: draft
cycle: "023"
agent: architect
workflow: equipe-chore
node: architect
resource: aefos://run/fdf49836e67b5746f5350a3fb741afd3
tags: [rtti, adr, issue-57, fpc, test-quality, chore]
generated:
  by: "equipe-chore@node:architect"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: investigation-57
    title: "Relatorio de investigacao — Issue #57 (run 1daaaf49674847d8b1dfce5ce677b694)"
  - id: esp
    resource: "esp.md"
    title: "ESP — Issue #57"
---

# ADR — Issue #57: Decisoes sobre os quatro residuos

> Este ADR DERIVA do relatorio de investigacao da issue #57
> (run `1daaaf49674847d8b1dfce5ce677b694`, status PRESENT).
> As decisoes aqui registradas foram acordadas em duas voltas de dialogo
> entre o Arquiteto e o humano antes deste ciclo de implementacao.
> Divergencias em relacao ao relatorio sao marcadas explicitamente;
> o que nao e marcado e reafirmacao fiel.

---

## D-57.1 — Remover comentario fantasma em `ArrayTypeLength:708-709`

**Contexto:** `Source/ModernSyntax.RTTI.FPC.pas:708-709` continha o comentario
*"`Result` default para silenciar o compilador — o raise ocorre em seguida."*
Medicao: `grep -c "Result := 0"` no corpo de `ArrayTypeLength` = **0**.
O default descrito nao existe. O comentario analogamente correto vive em
`:435-437`, onde `Result := TModernVisibility.mvPublic` de fato precede o raise.

**Decisao:** remover as duas linhas. Nao adicionar `Result := 0`.

**Motivo:** o compilador nao pediu. `main 4a2a606` compila 16/16 unidades-alvo
com 0 erros/0 warnings (Delphi 23.0/37.0 x Win32/Win64). Adicionar o default
seria codigo morto justificado por simetria estetica — e foi exatamente essa
simetria que produziu o comentario falso.

**Descartado:** adicionar `Result := 0` por simetria com `:435`. Base: o
compilador nao sinalizou necessidade; adicionar codigo nao solicitado para
satisfazer simetria estetica e o padrao que produziu o bug original.

---

## D-57.2 — Cenario 7: manter `IsNil` como pre-condicao e acrescentar identidade

**Contexto:** `UScenarios.RTTI.pas:1340-1341` so verificava `IsNil`, nao
a identidade do handle. Os cenarios 8, 9 e 10 da mesma leva (#46) comparam
`.Name` via `TModernRTTI.GetType`. O padrao local esta estabelecido em
`Scenario_PointerType_ReferredType_Matches:1256-1259` — `IsNil` como
pre-condicao seguido de assercao de identidade.

**Medicao de mutacao (Arquiteto, main 5a3d398):** trocar
`GetTypeData(P)^.ArrayData.ElType` por `P` em `RTTI.FPC.pas:686` (ramo estatico
de `ArrayTypeElementType`) devolve o proprio array — handle nao-nulo e errado.
Resultado: `[i386] PASSOU VERDE / [x86_64] PASSOU VERDE` com codigo errado.
O `IsNil` engole silenciosamente qualquer handle nao-nulo.

**Decisao (acordada na Volta 2):** MANTER `IsNil` como pre-condicao (mensagem
de diagnostico mais clara quando o handle vem nulo); ACRESCENTAR assercao de
identidade logo abaixo, espelhando `:1256-1259`.

**Forma acordada:**
```pascal
if LArr.ElementType.IsNil then
  Fail('ElementType(TArr5Int46) IsNil — esperava handle valido para Integer.');
if LArr.ElementType.Name <> TModernRTTI.GetType(TypeInfo(Integer)).Name then
  Fail('ElementType(TArr5Int46) nao e Integer — handle identico esperado.');
```

**Descartado (Volta 1, revertido na Volta 2):** descartar `IsNil` como
redundante. O vizinho `:1256-1259` mostra que a casa resolveu essa tensao
mantendo os dois; a pre-condicao da mensagem melhor quando o handle vem nulo.

**Reclassificacao:** o item 3 deixou de ser "aperto cosmetico" e passou a
"cobertura ausente". A assercao nova mata a mutacao; a antiga nao matava.

---

## D-57.3 — Comparacao por referencia via `TModernRTTI.GetType(TypeInfo(Integer))`

**Contexto:** ao fortalecer o cenario 7, surge a questao do literal correto:
`TypeInfo(Integer)` ou `TypeInfo(LongInt)`?

**Medicao (Arquiteto):**
- FPC 3.2.2, `array of Integer`: `elType2^.Name = 'LongInt'`
- Delphi, mesmo tipo: `ElementType = 'Integer'`

**Decisao:** usar `TModernRTTI.GetType(TypeInfo(Integer)).Name` em ambos os
lados da comparacao. Ambos os operandos passam pela mesma normalizacao —
no FPC compara `LongInt` com `LongInt`; no Delphi, `Integer` com `Integer`.
CA-5 preservado (zero `{$IFDEF FPC}` no arquivo de cenarios).

**Descartado:** trocar o literal por `TypeInfo(LongInt)`. Medido: quebraria
no Delphi. Trocar de literal so muda de lado.

**Comentario de bloco (:1326-1331):** espelhar a redacao existente em
`:1249-1253` do cenario do ponteiro. Nao inventar frase nova; o conhecimento
ja esta no arquivo.

---

## D-57.4 — Acceptance de mutacao obrigatoria para fechar o item 3

**Decisao:** apos o fix do cenario 7, executar a mutacao
`GetTypeData(P)^.ArrayData.ElType => P` em `Source/ModernSyntax.RTTI.FPC.pas:686`
nos DOIS bitness (i386 e x86_64) e confirmar que ambos ficam vermelhos.
Log da mutacao anexado ao corpo do PR — mesma disciplina da #46.

**Motivo:** sem esse log, a assercao nova e decorativa com sintaxe mais bonita;
nao ha evidencia de que ela mata o codigo errado.

---

## D-57.5 — Nao editar ADR de ciclo anterior; registrar medicao neste ciclo

**Contexto:** D-46.8 (comparacao por referencia) vive em
`cycle-019/pipeline-adr.md`. Ha pressao por registrar a medicao FPC=LongInt
/ Delphi=Integer la.

**Decisao:** registrar a medicao neste ciclo (D-57.3 acima), nao em
`cycle-019/pipeline-adr.md`.

**Motivo:** D-42.2 — registro de decisao que se edita deixa de ser registro.
Editar ADR de ciclo anterior violaria regra imposta pelo proprio Arquiteto.

**Descartado:**
- Opcao (a) editar `cycle-019/pipeline-adr.md` — viola D-42.2.
- Opcao (b) embutir so no comentario sem ADR — a medicao merece registro
  formal; apenas nota de comentario e insuficiente.

---

## D-57.6 — Um commit

**Decisao:** todos os quatro itens em um commit so. Quatro commits seriam
prosa e teatro de bisect.
