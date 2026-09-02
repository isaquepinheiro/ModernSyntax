---
type: cycle-report
kind: report
title: "REPORT-architect — ciclo 022 — issue #51 (else raise no backend Delphi)"
description: "Dossie arquitetural para a correcao da premissa falsa de D-42.2: else raise EModernRTTIError nos dois sites de Visibility do backend Delphi, zerando 2 W1035 e entregando fail-loud real."
cycle: "022"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/de0826deb51365cb442a8acd3e0fd103
tags: [report, cycle-022, issue-51, bug, delphi, visibility, emodernrttierror, d-51-1]
generated:
  by: "equipe-bug@node:architect"
  at: "2026-09-02T00:00:00Z"
---

# REPORT-architect — ciclo 022 / issue #51

## Demanda

Issue #51 — "O case de 4 ramos sem else no backend Delphi nao protege":
`MethodVisibility` e `PropertyVisibility` em `Source/ModernSyntax.RTTI.Delphi.pas`
geram W1035 e devolvem lixo em runtime (ordinal 204/16/252/16 nos 4 alvos,
variando por bitness). A premissa de D-42.2 ("o compilador acusa erro") e falsa
e medida.

## Decisao em vigor

O relatorio de investigacao (run `2e4913d83ea2e1f06b3d8e8589bcbc4f`) acordou
com o mantenedor a **opcao (a)** da issue: `else raise EModernRTTIError.CreateFmt`
nos dois sites do backend Delphi. O criterio de desempate nao e o W1035 (ambos
os candidatos — cast e raise — matam o warning igualmente); e o comportamento em
runtime quando o RTL crescer: fail-loud (raise) vs. errado-em-silencio (cast).

## Artefatos produzidos

| Artefato | Link |
|----------|------|
| Especificacao formal (ESP) | [pipeline-esp.md](pipeline-esp.md) |
| Decisoes arquiteturais (ADR D-51.1) | [pipeline-adr.md](pipeline-adr.md) |
| Plano de execucao | [pipeline-plan.md](pipeline-plan.md) |
| Handoff operacional | [pipeline-task-input.md](pipeline-task-input.md) |

## Sumario das decisoes

- **D-51.1** — `else raise EModernRTTIError.CreateFmt(SDelphiUnknownVisibility,
  [Ord(...), '<nome-da-funcao>'])` em `MethodVisibility` e `PropertyVisibility`.
- **D-51.2** — Criterio de desempate: fail-loud vs. errado-em-silencio (nao o
  W1035, que ambos os candidatos eliminam).
- **D-51.3** — `SDelphiUnknownVisibility` na secao `implementation` (privada),
  por contraste explicit com PR #58.
- **D-51.4** — Nome da funcao na mensagem (`%d` + `%s`), unico discriminante
  com `AOwner` fora.
- **D-51.5** — `AOwner` fora da mensagem: `PropertyVisibility` nao o recebe.
- **D-51.6** — D-42.2 intocado; supersecao parcial registrada por D-51.1.
- **D-51.7** — Ramo inalcancavel, sem teste novo.
- **D-51.8** — Backend FPC intocado.

## Escopo e veredicto

**`fits` — slice unico.** Dois arquivos, ~15 linhas alteradas. Nenhum subconjunto
e entregavel sozinho de forma coerente.

## Arquivos impactados

| Arquivo | Mudancas |
|---------|----------|
| `Source/ModernSyntax.RTTI.Delphi.pas` | resourcestring + else raise (x2) + reescrita de 2 comentarios |
| `Source/ModernSyntax.RTTI.pas` | reescrita XML-doc `TModernVisibility` |

Intocados: `ModernSyntax.RTTI.FPC.pas`, todos os arquivos de teste,
`.project/project-evolution.md`.
