---
type: task
kind: artifact
title: "TASK #66 — Corrigir remarks falso de TModernRTTIProperty.Visibility"
description: "2 edicoes documentais em RTTI.pas: reescrever remarks de Visibility (161-167) e atualizar citacao de ADR (987-990); zero linhas executaveis."
cycle: "026"
agent: planner
workflow: equipe-bug
node: task
resource: aefos://run/a2c4f4bd7a43e634bf43104b21a56468
generated:
  by: "equipe-bug@node:task"
  at: "2026-09-02T00:00:00Z"
tags: [task, rtti, xmldoc, documentation, bug, issue-66, modernrtti, cycle-026]
---

# TASK — Ciclo 026 / Issue #66

## Tracking

- **Modo:** MAESTRO MODE
- **Issue original:** [#66](https://github.com/isaquepinheiro/ModernSyntax/issues/66)
  (demanda criada pelo maestro — `aefos:running`)
- **Epic:** nenhum Epic existente — sem anexação (MAESTRO MODE)
- **Board local:** 🔄 in-pipeline

## Demanda em uma linha

Reescrever o `<remarks>` de `TModernRTTIProperty.Visibility` em `RTTI.pas:161-167`,
que afirmava `"aqui NAO ha raise no FPC"` — frase tornada falsa pelo PR #65
(ciclo 025, que inseriu `else raise` em `RTTI.FPC.pas:505-507`) — e alinhar
a citação de ADR em `:987-990`.

## Pré-condição crítica

**PR #65 (ciclo 025) deve estar mergeado** antes de abrir este PR.
Sem esse merge, os dois PRs conflitam em `RTTI.pas`.

## Escopo

| Arquivo | Linhas | Edição |
|---------|--------|--------|
| `Source/ModernSyntax.RTTI.pas` | 161–167 | Reescrita do `<remarks>` público de `TModernRTTIProperty.Visibility` |
| `Source/ModernSyntax.RTTI.pas` | 987–990 | Substituição `(D-42.2 do ADR issue #42)` → `(D-42.2/D-51.1/D-60.1 do ADR issues #42/#51/#60)` |

## Acceptance checklist

- [ ] `RTTI.pas:161-167` não afirma que o FPC não levanta; descreve a assimetria
  pelo motivo real: `TModernRTTIMethod.Visibility` levanta SEMPRE no FPC;
  `TModernRTTIProperty.Visibility` levanta APENAS no ramo `else`, inalcançável
  com o `TMemberVisibility` atual (4 valores, `rtti.pp:308`).
- [ ] Citação de ADR na forma canônica: `D-42.2/D-51.1/D-60.1 do ADR issues #42/#51/#60`.
- [ ] `RTTI.pas:987-990` atualizado com a mesma forma canônica.
- [ ] O `<remarks>` não cita `SFPCNoVisibility` nem qualquer símbolo interno do backend.
- [ ] Zero linha executável muda — diff mostra apenas linhas `///` e `//`.
- [ ] Varredura `grep -rn "NAO ha raise\|nao levanta\|nunca levanta\|sem raise" Source/` → zero linhas contaminadas.
- [ ] Suite FPC 3.2.2 x86_64 verde; contagem permanece 42.
- [ ] Backend Delphi intocado; `RTTI.Delphi.pas` sem diff.
- [ ] Achados fora do escopo registrados no PR como "Achado — nova issue"; não entram no diff.

## PR

**Título:** `docs(rtti): corrigir remarks falso de TModernRTTIProperty.Visibility (issue #66)`

**Body verbatim:**
> Correção exclusivamente documental: reescreve o `<remarks>` de
> `TModernRTTIProperty.Visibility` (`RTTI.pas:161-167`), que afirmava "aqui NAO ha
> raise no FPC" — frase que ficou falsa após o PR #65 inserir `else raise` em
> `RTTI.FPC.pas:505-507`. Alinha também a citação de ADR em `:987-990`.
>
> Zero linha executável muda. Nenhum teste novo.
>
> Compilado em FPC 3.2.2 x86_64. i386 e os 4 alvos Delphi ficam com o autor.

## Restrições críticas

1. **Não ampliar o diff** — achados externos de afirmação de ausência contaminada
   fora de `RTTI.pas:163` → registrar no PR como nova issue; não corrigir aqui.
2. **Texto estrutural, sem símbolo de backend** — o `<remarks>` descreve comportamento
   observável; não citar `resourcestring` internas.
3. **Forma canônica de citação** — `D-42.2/D-51.1/D-60.1 do ADR issues #42/#51/#60`;
   não usar colchetes nem separar por vírgula.
4. **`<summary>` não tocar** — `RTTI.pas:155-160` segue correto após PR #65.
5. **`RTTI.pas:168` não tocar** — assinatura pública.

## Referências

- [task-input](pipeline-task-input.md)
- [esp](pipeline-esp.md)
- [adr](pipeline-adr.md)
- [plan](pipeline-plan.md)
