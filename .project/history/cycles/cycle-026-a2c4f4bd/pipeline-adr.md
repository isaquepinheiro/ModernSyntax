---
type: adr
kind: artifact
title: "ADR D-66 — Reescrita do remarks publico de TModernRTTIProperty.Visibility (issue #66)"
description: "Decisoes acordadas na investigacao da issue #66: forma canonica de citacao, descricao estrutural da assimetria, ancora externa rtti.pp:308, commit unico, varredura em Source/."
cycle: "026"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/a2c4f4bd7a43e634bf43104b21a56468
generated:
  by: "equipe-bug@node:architect"
  at: "2026-09-02T00:00:00Z"
tags: [adr, rtti, xmldoc, documentation, bug, issue-66, modernrtti, cycle-026, d-66]
sources:
  - id: investigation-66
    resource: "aefos://run/815396d406c2e93390d527508f06e778"
    title: "Relatorio de investigacao — Issue #66 (run 815396d406c2e93390d527508f06e778)"
  - id: adr-60
    resource: "/history/cycles/cycle-025-4c9ae8e8/pipeline-adr.md"
    title: "ADR D-60 — else raise no PropertyVisibility do backend FPC (ciclo 025)"
---

> **Fonte:** este ADR deriva do relatório de investigação da issue #66
> (run `815396d406c2e93390d527508f06e778`), acordado com o mantenedor em
> 1 volta de discussão (5 questões). Onde este documento diverge do
> relatório, a divergência é declarada explicitamente.
>
> **Não há divergência.** Todas as decisões abaixo refletem o que foi
> acordado na investigação, sem acréscimo nem omissão.

# ADR D-66 — Reescrita do `<remarks>` público de `TModernRTTIProperty.Visibility`

## Contexto

O PR #65 (issue #60, ADR D-60[^adr-60]) inseriu `else raise EModernRTTIError.CreateFmt`
no `PropertyVisibility` do backend FPC (`RTTI.FPC.pas:505-507`). Esse código é correto.

O bloco `<remarks>` de `TModernRTTIProperty.Visibility` em `RTTI.pas:161-167` —
não tocado pelo PR #65 — continua afirmando literalmente *"aqui NAO ha raise no FPC"*.
Essa frase era verdadeira antes do PR #65; depois dele, é falsa. O mesmo arquivo já
descreve, em `RTTI.pas:79-81` (editado pelo PR #65), que ambos os backends levantam
`EModernRTTIError` — criando contradição dentro da mesma `interface` pública.

A contradição importa porque o consumidor lê o `<remarks>` para decidir se precisa
de `try/except` no FPC.

A causa raiz — ponto cego de varredura — é que `RTTI.pas:163` não cita número de
issue nem palavra-chave de exaustividade, então grep por `#60` ou `exaustividade`
não a encontra. O gatilho correto, acordado na investigação: quando um backend ganha
um `raise` novo, varrer a casca pública por toda afirmação de **ausência**
(`NAO ha raise`, `nao levanta`, `nunca levanta`, `sem raise`).[^investigation-66]

---

## D-66.1 — Forma canônica de citação de ADR: barra, sem colchetes (agreed, volta 1, Q1)

A citação de ADR no `<remarks>` e no comentário de implementação usa a forma
`D-42.2/D-51.1/D-60.1`, com as issues nomeadas uma única vez ao final como
`do ADR issues #42/#51/#60`.

**Medido no repo:** `grep` em `Source/*.pas` encontra a forma com barra 5×
(`D-43.5/D-43.6`, `D-45.5/D-45.7`, `D-46.3/D-46.4/D-46.5`, `D-51.1 do ADR issue #51`
4×, `D-42.2 do ADR issue #42` 3×). A forma com colchetes `[ADR #42] +` não existe
no repositório; usar seria introduzir padrão novo sem precedente.

**Descartado:** forma `[ADR #42] +` — sem precedente no repo.[^investigation-66]

---

## D-66.2 — `<remarks>` descreve a assimetria estruturalmente; sem símbolo de backend (agreed, volta 1, Q2)

O `<remarks>` público **não cita** `SFPCNoVisibility` nem qualquer outro símbolo
interno do backend. A assimetria é descrita estruturalmente:

- **`TModernRTTIMethod.Visibility`** levanta **SEMPRE** no FPC — o dado não existe
  no `vmtMethodTable`.
- **`TModernRTTIProperty.Visibility`** levanta **APENAS** no ramo `else`,
  inalcançável com o `TMemberVisibility` atual (4 valores, `rtti.pp:308`).

**Medido no repo:** das centenas de linhas `///` de `RTTI.pas`, apenas uma cita
símbolo de backend (`RTTI.pas:569`, `SModernRTTIError_EmptyRegistry`) — é exceção
declarada, não padrão. O consumidor lê o header público para saber o comportamento
observável, não o nome interno da string.[^investigation-66]

**Descartado:** citar `SFPCNoVisibility` no header público — sem precedente
como padrão; seria replicar a exceção de `:569` sem justificativa equivalente.

---

## D-66.3 — Âncora `rtti.pp:308` é permitida no `<remarks>` público (agreed, volta 1, Q3)

A âncora externa `rtti.pp:308` para o número de valores atuais de `TMemberVisibility`
é incluída no `<remarks>`. Precedente estabelecido: `RTTI.pas:157` (`rtti.pp:340,3776`),
`RTTI.pas:280` (`typinfo.pp:388-396`), `RTTI.pas:335` (`rtti.pp:317`).

Código externo (FPC RTL) não se desloca com os PRs do próprio repo — ao contrário de
citar linha interna, que é o defeito que gerou a issue #64.[^investigation-66]

**Risco declarado e aceito:** se o FPC mover a linha 308, o comentário envelhece.
Mesmo risco dos precedentes existentes; aceitável pelo mantenedor.

---

## D-66.4 — Um único commit para as duas edições (agreed, volta 1, Q4)

As edições em `RTTI.pas:161-167` (bloqueante) e `RTTI.pas:987-990` (free-ride)
vão no mesmo commit. As duas tocam o mesmo `<remarks>` conceitual da propriedade
`Visibility`; reverter uma sem a outra deixaria o bloco ADR-citation incoerente.

**Descartado:** dois commits separados — granularidade que não se paga; as edições
são inseparáveis sem deixar estado incoerente.[^investigation-66]

---

## D-66.5 — Varredura em `Source/` inteira; diff restrito aos dois pontos (agreed, volta 1, Q5)

A varredura de aceitação por afirmações de ausência (`NAO ha raise`, `nao levanta`,
`nunca levanta`, `sem raise`) cobre **toda a `Source/`**, não só `RTTI.pas` e
`RTTI.FPC.pas`.

Resultado já medido na investigação: `RTTI.pas:163` é a **única** linha contaminada.
As linhas sadias já identificadas (`RTTI.pas:536`, `:578`, `:675`, `RTTI.FPC.pas:868`)
tratam de outros membros e permanecem verdadeiras — o alvo de aceitação pós-edição é
**zero** linhas contaminadas.[^investigation-66]

Qualquer achado fora do escopo desta issue entra no **corpo do PR** como "Achado —
nova issue" e não amplia o diff. Precedente: issue #64 nasceu de achado ao consertar
outra unit; ampliar o diff ali custou uma issue inteira de revert.

**Descartado:** varredura restrita a `RTTI.pas` + `RTTI.FPC.pas` — barato ampliar;
endereça a classe do defeito, não só a instância.[^investigation-66]

---

## Convenção registrada por esta issue

**Gatilho de varredura por ausência:** quando um backend ganha um `raise` novo,
a casca pública deve ser varrida por toda afirmação de **ausência de raise**
(`NAO ha raise`, `nao levanta`, `nunca levanta`, `sem raise`). Grep por número de
issue ou por palavra-chave de exaustividade não detecta este padrão.

Esta é a armadilha de varredura descrita na investigação como "achado reutilizável"
— o point-blank que fez `RTTI.pas:163` passar despercebido no ciclo 025.[^investigation-66]

---

## Convenções governantes

| ID | Fonte | O que governa nesta issue |
|----|-------|--------------------------|
| D-60.5 | [^adr-60] | XMLDoc entra no PR, não como follow-up — essa decisão foi cumprida para `RTTI.pas:79-85` no PR #65 mas não para `:161-167` (blind spot). Esta issue paga essa dívida. |
| D-42.2 | ADR issue #42 | `case` de 4 ramos — parcialmente supersedido para o sítio `PropertyVisibility` por D-51.1 e D-60.1, que adicionaram `else raise`. Daí a citação incluir todos os três. |
| D-51.1 | ADR issue #51 | Primeiro movimento (`else raise` no Delphi). |
| D-60.1 | [^adr-60] | Segundo movimento (`else raise` no FPC). |

## Consequências

- `RTTI.pas:161-167` deixa de ser contraditório com `RTTI.pas:79-81`.
- O consumidor pode confiar no `<remarks>` para decidir se precisa de `try/except`
  no FPC: a assimetria real é descrita (Method levanta sempre; Property levanta só
  no ramo `else`, inalcançável por dado real hoje).
- Contratos, assinaturas e comportamento observável de `TModernRTTIProperty.Visibility`
  permanecem idênticos — zero regressão possível.
- A citação de ADR em `:987-990` alinha-se ao estado real: D-42.2 foi parcialmente
  supersedido por D-51.1 e D-60.1 para este sítio.
- A convenção de varredura por afirmação de ausência é registrada para ciclos futuros.
