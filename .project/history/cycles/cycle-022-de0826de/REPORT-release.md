---
type: cycle-report
kind: report
title: "REPORT-release — ciclo 022 (issue #51): else raise no backend Delphi"
description: "Ciclo 022 entregou else raise em MethodVisibility e PropertyVisibility do backend Delphi, eliminando W1035 e protegendo contra TMemberVisibility desconhecido; 42/42 FPC verdes, todos os gate de qualidade APROVADOS."
cycle: "022"
agent: release
workflow: equipe-bug
node: closing-record
resource: aefos://run/de0826deb51365cb442a8acd3e0fd103
generated:
  by: "equipe-bug@node:closing-record"
  at: "2026-09-02T00:00:00Z"
tags: [release, cycle-022, issue-51, delphi, visibility, modernrtti]
---

# REPORT-release — ciclo 022 (issue #51)

## O que este ciclo entregou

Issue #51 identificou que os `case` de 4 ramos sem `else` em `MethodVisibility` e
`PropertyVisibility` no backend Delphi não protegiam contra valores desconhecidos de
`TMemberVisibility`: o compilador emitia W1035 e retornava lixo em runtime. A premissa
do ADR D-42.2 era falsa — o Delphi não acusa case não-exaustivo em compile-time para
esse tipo.

Este ciclo corrigiu os dois sites adicionando `else raise EModernRTTIError.CreateFmt`
com uma `resourcestring` privada `SDelphiUnknownVisibility` declarada na seção
`implementation` de `ModernSyntax.RTTI.Delphi.pas`. Os comentários dos dois sites
foram reescritos para refletir o framing correto (decisão de desempate semântico
fail-loud vs. errado-em-silêncio, referência D-51.1 substituindo D-42.2, medição
204/16/252/16 citada). O XML-doc de `TModernVisibility` em `ModernSyntax.RTTI.pas`
foi atualizado para enunciar que o backend Delphi levanta `EModernRTTIError` no
primeiro chamador e o backend FPC valida exaustividade em compile-time.

O backend FPC permaneceu intocado. Nenhum arquivo de teste foi alterado.

## Work branch

- **Branch:** `aefos/cycle-de0826de-maestro-repo-isaquepinheiro-modernsyntax`
- **Base:** `main`

## Verdicts dos três gates de qualidade

| Gate | Veredicto |
|------|-----------|
| Review ([REPORT-quality-review.md](REPORT-quality-review.md)) | **APROVADO** — todos os 6 passos do plano executados; regras de negócio, restrições e critérios de aceitação satisfeitos |
| Test ([REPORT-quality-test.md](REPORT-quality-test.md)) | **APROVADO** — 42/42 FPC x86_64 verdes, zero warnings novos, cenários de Visibility verdes |
| Verify ([REPORT-quality-verify.md](REPORT-quality-verify.md)) | **PASSED** — static analysis e test run sem regressões |

## Fronteira de verificação

O ciclo rodou FPC x86_64 no container. FPC i386 e os 4 alvos Delphi
(23.0/37.0 × Win32/Win64) não foram executados nesta fábrica — ficam com
o mantenedor antes do merge. O `else raise` elimina W1035 por design (ADR D-51.2).

## Artefatos do ciclo

- [pipeline-plan.md](pipeline-plan.md) — plano do slice único (2 arquivos, 6 passos)
- [pipeline-task.md](pipeline-task.md) — task com critérios de aceite
- [REPORT-developer.md](REPORT-developer.md) — implement-report com diff e evidência de build
- [REPORT-quality-review.md](REPORT-quality-review.md) — revisão de qualidade
- [REPORT-quality-test.md](REPORT-quality-test.md) — relatório de testes
- [REPORT-quality-verify.md](REPORT-quality-verify.md) — relatório de verificação estática
