---
type: cycle-report
kind: report
title: "REPORT-architect — cycle 021 — issue #56 (Attributes nil-handle)"
description: "Architect produziu esp/adr/plan/task-input para issue #56: guarda de nil em PropAttributes, uniformizacao dos seis blocos de assert (Pos para igualdade estrita), sexto bloco no cenario compartilhado. Scope: fits, slice unico, dois arquivos."
cycle: "021"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/09743779c7c9860b5fa380f6979d94ca
tags: [cycle-report, issue-56, modernrtti, nil-handle, architect, fpc, bug]
generated:
  by: "equipe-bug@node:architect"
  at: "2026-09-02T15:40:00Z"
---

# REPORT-architect — Cycle 021 — Issue #56

## Demanda

Issue #56: `TModernRTTIType.Attributes` ficou fora do contrato de
nil-handle da #49. `PropAttributes` devolve vazio silenciosamente quando
`FType = nil` (via `if (FType is TRttiInstanceType)` que retorna `False`
sem AV), tornando o estado indistinguivel de "o tipo nao tem atributos".

## Fonte de decisao

O relatorio de investigacao (run `c85a5115026d0a220da0a27064774fdd`) esta
PRESENT com status **settled** — duas voltas de discussao entre arquiteto
e mantenedor. O [adr](pipeline-adr.md) deriva integralmente desse relatorio.

## Artefatos produzidos

| Artefato | Descricao |
|----------|-----------|
| [esp](pipeline-esp.md) | Especificacao formal: objetivo, escopo, regras de negocio, criterios de aceite, restricoes, riscos |
| [adr](pipeline-adr.md) | Seis decisoes derivadas do relatorio de investigacao (D-56.1 a D-56.6) |
| [plan](pipeline-plan.md) | Slice unico: guarda + uniformizacao + sexto bloco. Verdict: fits |
| [task-input](pipeline-task-input.md) | Handoff operacional com checklist, linhas exatas, armadilhas |

## Decisoes-chave (resumo)

- **D-56.1** — Guarda `if FType = nil then raise` como primeira instrucao
  visivel de `PropAttributes` (antes do comentario `// Issue #27:`).
- **D-56.2** — Uniformizar os **seis** blocos de assert, nao so `GetMethod`;
  dois estilos no mesmo procedimento sem justificativa visivel no codigo.
- **D-56.3** — Trocar `Pos → <>` obriga a reescrever as cinco mensagens
  de `Fail` para `'Mensagem de X incorreta: "%s"'`.
- **D-56.4** — Sexto bloco em ordem **cronologica** (append apos linha 1534);
  documenta que `Attributes` foi o residuo da #49.
- **D-56.5** — **Commit unico** com os tres passos; separar cria ruido no bisect.
- **D-56.6** — PR declara so o que a fabrica rodou: FPC x86_64. i386 e
  Delphi (3 alvos) ficam com o mantenedor — padrao da serie #43–#49.

## Scope assessment

**`fits`** — dois arquivos, nenhuma decisao de design nova, nenhuma string
nova (`SModernRTTINilHandle` ja existe em linha 892), ~30 linhas de
alteracao total. Os tres passos dependem uns dos outros (nao ha dois slices
mergeaveis independentemente).

## Mudancas por arquivo

| Arquivo | Linha(s) | O que muda |
|---------|----------|-----------|
| `Source/ModernSyntax.RTTI.pas` | 1125 (inserir) | Guarda `if FType = nil then raise`; comentario `// Issue #27:` desce |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | 1461, 1462, 1478-1480, 1497-1498, 1514-1516, 1532-1534 | 5 blocos × 2 linhas: Pos → igualdade estrita + Fail reescrito |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | apos 1534, antes de 1535 | Sexto bloco (Attributes), append puro |

Nenhum outro arquivo muda.

## Fronteira de verificacao

A fabrica cobre FPC 3.2.2 x86_64 (1 de 4 do acceptance). FPC i386,
Delphi Win32, Delphi Win64 ficam com o mantenedor antes do merge.
