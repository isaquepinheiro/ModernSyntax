---
type: cycle-report
kind: report
title: "REPORT-release — ciclo 005 (TModernInvoker)"
description: "Closing record for cycle 005: TModernInvoker delivered on branch aefos/cycle-2ef372d9-maestro-repo-isaquepinheiro-modernsyntax; all three quality lenses PASSED."
cycle: "005"
agent: release
workflow: equipe-feature
node: closing-record
resource: aefos://run/2ef372d993ff75b8dcd8c707bb79d636
tags: [cycle-005, release, modernrtti, invoker, issue-10]
generated:
  by: "equipe-feature@node:closing-record"
  at: "2026-08-28T15:30:00Z"
---

# REPORT-release — ciclo 005

## O que este ciclo entregou

O ciclo 005 implementa `TModernInvoker`, o record genérico que resolve o
Pilar 3 do PRD (CA-3): invocar um método pelo nome com a mesma chamada nos
dois compiladores suportados (Delphi e FPC), usando `TObject.MethodAddress`
como mecanismo comum onde a RTTI nova do FPC 3.2.2 x86_64 retorna zero
métodos mesmo com `{$M+}` e `published`.

A unidade de produção expõe exatamente dois overloads `class function
Invoke<TSignature>` — um recebendo instância (`TObject`), outro recebendo
classe (`TClass`) — sem nenhum tipo auxiliar vazado na interface, autocontida
em `uses SysUtils;`, sem directivas de compilador condicionais e sem inclusão
do arquivo de include compartilhado do repositório. A guarda `SizeOf` é a
primeira linha de cada overload; a guarda de `nil` é a segunda; a mensagem de
"não encontrado" cita explicitamente `{$M+}` e `published` para orientar o
desenvolvedor.

A suite de testes consiste em sete cenários procedurais compartilhados
(sem dependência de framework), com cascas finas para DUnitX (Delphi) e
FPCUnit (FPC). Cada casca delega em exatamente uma chamada ao cenário
correspondente. O projeto FPC carrega dois build modes (`Debug-x86_64`
default, `Debug-i386`). Todos os greps de aceitação retornam zero.

A API dinâmica no padrão da nova RTTI do Delphi
(`GetType(T).GetMethod('X').Invoke(obj,[args]): TValue`) foi explicitamente
descartada deste ciclo e anotada como issue irmã futura — ver
[pipeline-adr](pipeline-adr.md) D-A9. O PR body deve declarar esse limite.

## Ramo e base

- **Branch de trabalho:** `aefos/cycle-2ef372d9-maestro-repo-isaquepinheiro-modernsyntax`
- **Base:** `develop`

## Veredictos das três lentes de qualidade

| Lente | Nó | Veredicto |
|-------|----|-----------|
| Verify | verify | **PASSED** — 450 linhas compiladas, 0 erros, 7/7 testes verdes (FPC 3.2.2 x86_64) |
| Test | test | **APPROVED** — 12/12 CAs satisfeitos; 7 cenários documentados e verificados |
| Review | review | **APPROVED** — todos os CAs e RNs atendidos; zero issues críticas |

Os três warnings FPC `"unreachable code"` (linhas 80 e 100 de
`ModernSyntax.Invoker.pas`) são esperados e documentados: a guarda `SizeOf`
sempre dispara na instanciação `Invoke<Integer>` usada no cenário CA-7, o que
*valida* a guarda em vez de indicar um defeito.

FPC i386 e Delphi permanecem pendentes de verificação pelo autor (ambiente do
orquestrador não dispõe de `ppc386` nem de Delphi IDE — protocolo documentado
em `SKILL.md` §"The command" e §"Delphi").

## Rastreamento

- Issue de intake: [isaquepinheiro/ModernSyntax#10](https://github.com/isaquepinheiro/ModernSyntax/issues/10)
- Modo: MAESTRO MODE (`from_maestro: true`)
- Relatórios do ciclo: [REPORT-architect](REPORT-architect.md) · [REPORT-planner](REPORT-planner.md) · [REPORT-developer](REPORT-developer.md) · [REPORT-quality-verify](REPORT-quality-verify.md) · [REPORT-quality-test](REPORT-quality-test.md) · [REPORT-quality-review](REPORT-quality-review.md)
- Artefatos do pipeline: [pipeline-esp](pipeline-esp.md) · [pipeline-adr](pipeline-adr.md) · [pipeline-plan](pipeline-plan.md)
