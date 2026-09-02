---
type: adr
kind: artifact
title: "ADR #62 — Decisões de implementação: correções documentais restantes da #57"
description: Registra as decisões acordadas na investigação (run 8810a78921ce945faf6e68362495134d) sobre formulações, escopo das cascas e formato do PR.
cycle: 24
agent: architect
workflow: equipe-chore
node: architect
generated:
  by: equipe-chore@node:architect
  at: "2026-09-02T00:00:00Z"
tags: [cycle-024, issue-62, chore, documentation, xmldoc, rtti]
sources:
  - id: investigate-run
    resource: "aefos://run/8810a78921ce945faf6e68362495134d"
    title: "Relatório da investigação — Issue #62 (comment na issue)"
---

# ADR — Issue #62: Decisões de implementação

**Este ADR deriva do relatório de investigação (run `8810a78921ce945faf6e68362495134d`)**,
fechado em duas voltas com o mantenedor. Cada decisão está ancorada na volta em que
foi tomada e reproduz os motivos registrados no relatório.[^investigate-run]

## D-62.1 — As duas cascas entram no PR (Volta 1)

**Contexto:** O acceptance da issue nomeia "os comentários de `Scenario_NilHandle_AllMembers_Raises`".
O corpo da issue nomeia apenas os dois pontos do shared — ambiguidade sobre as cascas.

**Decisão:** As duas cascas (`Test Delphi/EclbrSystem/UTestMS.RTTI.pas:171` e
`Test FPC/EclbrSystem/UTestMS.RTTI.pas:105`) **entram no PR** como itens 4 e 5 do plano.

**Motivo registrado:** É o mesmo drift semântico ("cinco → seis"). Deixá-las de fora
criaria uma terceira issue para o mesmo drift — exatamente como a #57 virou 4 de 8.
O custo é 2 linhas.

**Descartado:** Omitir as cascas por interpretação restrita do corpo da issue.

---

## D-62.2 — Formulação da igualdade estrita no comentário (Volta 1)

**Contexto:** O comentário diz "cita o nome do membro chamado" — correto sob `Pos(...)`.
O PR #58 trocou para `LMsg <> Format(SModernRTTINilHandle, [...])`. Qual formulação?

**Decisão:** *"é exatamente `Format(SModernRTTINilHandle, [<membro>])`"* — nomeia a
expressão real que o leitor vai procurar no código.

**Descartado:** "byte a byte" — a comparação é de `string` Pascal, não de bytes;
a formulação ficaria imprecisa no comentário que existe para acabar com imprecisão.

---

## D-62.3 — `<remarks>` de `Attributes` é cópia literal dos cinco irmãos (Volta 1)

**Contexto:** `Attributes` (`:426-431`) não tem a cláusula `<remarks>` de nil. `PropAttributes`
é `strict private` — deve o `<remarks>` mencionar isso?

**Decisão:** Cópia **literal** dos cinco irmãos, sem mencionar `PropAttributes` nem
`strict private`.

**Motivo registrado:** Isso é contexto de issue, não de consumidor. Quem lê o XMLDoc
quer saber *o que acontece*. Uniformidade dos seis vale mais que diferenciação interna.

---

## D-62.4 — PR body é frase declarativa, não checklist (Volta 1)

**Contexto:** Série #296–#300 (aefos-studio#375): checklist de combinações marcadas
sem execução comprometeu a confiabilidade dos PRs.

**Decisão:** PR body carrega frase declarativa — "compilado em FPC 3.2.2 x86_64;
i386 e os 4 alvos Delphi ficam com o mantenedor" — **sem checklist de combinações**.

**Descartado:** Checklist de compiladores/bitnesses — caixa marcada sem execução
difícil de distinguir de dado verdadeiro e já mordeu esta série.

---

## D-62.5 — Texto do `<summary>` de `TModernVisibility` verbatim, com acentos (Volta 1)

**Contexto:** O texto proposto na §1 da issue tem acentuação. Os arquivos `.pas` são
UTF-8 sem BOM (medido pelo mantenedor).

**Decisão:** Texto **verbatim** da §1 da issue, com acentos e com "Ver #60." ao final.
Editar **só as linhas 80-82** — não reencodar o arquivo.

**Descartado:** Reencodar o `.pas` inteiro — forma de estragar arquivo Pascal sem
ninguém notar até o próximo diff.

---

## D-62.6 — Âncora de linha sai primeiro na ordem de edição (Volta 1, reafirmada na 2)

**Contexto:** A troca da âncora em `:145` e as edições em `:318-320`/`:1452-1457`
estão no mesmo arquivo. Edições de corpo que somem/removem linhas deslocam a âncora.

**Decisão:** Item 1 (âncora `:145` → `Scenario_SetType_ElementType`) é aplicado
**primeiro**, antes de qualquer outra edição no arquivo.

---

## D-62.7 — Âncora nas cascas é a frase inteira, nunca a palavra solta (Volta 2, com medição)

**Contexto:** Cada casca tem dois "cinco": `:171`/`:105` é o drift (corrigir);
`:97`/`:56` é sobre `for..in` da #27 (correto — não tocar). Medição confirmada
na Volta 2 com `grep -n "cinco"` nas duas cascas.

**Decisão:** Substituição ancorada pela frase inteira *"nos cinco membros afetados"*,
nunca pela palavra "cinco" solta.

**Descartado:** Substituição cega de "cinco" — corromperia o comentário correto de `:97`/`:56`.

---

## Convenções governantes

| ID | Fonte | O que governa |
|---|---|---|
| D1 — XMLDoc `///` uniforme | `05-conventions.md` §4.3 | Itens 6 e 7 (summary + remarks) |
| D2 — Proibição de âncora de linha nova | #169 + acceptance #62 item 5 | Item 1 (troca por nome de símbolo) |
| D3 — Fronteira declarada, não simulada | `SKILL.md` §2 + aefos-studio#375 | PR body (frase declarativa) |
| D4 — Um cenário, duas cascas | Padrão geral do projeto | Itens 4-5 (cascas entram) |

## O que este ADR não decide

Itens fora de escopo confirmados na consolidação da Volta 2: `case` de `PropertyVisibility`
no backend FPC (#60); corpo do bloco `Attributes` em `:1550-1565`; `raise` em `:1138`;
as duas published `TestNilHandle_AllMembers_Raises`; comentários de `for..in` em
`:97`/`:56`; nome do cenário; declarações de `TCor`/`TDia`.
