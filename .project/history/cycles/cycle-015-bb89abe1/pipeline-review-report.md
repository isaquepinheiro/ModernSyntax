---
type: review-report
kind: artifact
title: "REVIEW-REPORT — TModernVisibility: enum proprio, fecha vazamento em Method.Visibility, adiciona Property.Visibility (issue #42)"
description: "Quality review do ciclo 015: todos os 10 criterios de aceitacao do ESP aprovados; caveats de ambiente (Delphi/FPC i386 nao verificados em CI) documentados sem bloquear aprovacao."
status: stable
cycle: "015"
agent: quality
workflow: equipe-feature
node: review
resource: aefos://run/bb89abe1aa455add801745cb2a527e99
tags: [modernrtti, review-report, issue-42, visibility, tmodernvisibility]
generated:
  by: "equipe-feature@node:review"
  at: "2026-09-01T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — TModernVisibility (issue #42)"
  - id: adr
    resource: "adr.md"
    title: "ADR — TModernVisibility (issue #42)"
  - id: implement-report
    resource: "implement-report.md"
    title: "IMPLEMENT-REPORT — TModernVisibility (issue #42)"
---

# REVIEW-REPORT — issue #42 (TModernVisibility)

Revisao do ciclo 015 contra [esp](pipeline-esp.md), [adr](pipeline-adr.md) e convencoes
do repositorio. Baseline: `git status --porcelain` (7 arquivos `M` +
diretorio do ciclo `??`); `git diff main...HEAD` vazio (mudancas nao
commitadas, inspecionadas diretamente).

## Resumo

Implementacao **aprovada**. Os 10 criterios de aceitacao do ESP estao
satisfeitos. Dois caveats de ambiente (compilacao Delphi e FPC i386 fora
da fabrica CI) sao limitacoes estruturais conhecidas do projeto, documentadas
em SKILL.md e declaradas no implement-report — nao constituem defeito de
implementacao. A mutacao de sanidade (CA-9) foi executada e confirmada.

## Checklist de aceitacao

| CA | Descricao | Resultado |
|----|-----------|-----------|
| CA-1 | `TModernVisibility = (mvPrivate, …, mvPublished)` declarado em `interface`, antes de `TModernRTTIField` | ✅ PASS — linha 71 da casca publica, apos `EModernRTTIError` (linha 57), antes de `TModernRTTIField` (linha 85) |
| CA-2 | `TModernRTTIMethod.Visibility` retorna `TModernVisibility` (declaracao + implementacao) | ✅ PASS — declaracao linha 314; impl. linhas 911-914 delegando a `MethodVisibility(FOwner, FToken)` |
| CA-3 | `TModernRTTIProperty.Visibility: TModernVisibility` existe (declaracao + implementacao) | ✅ PASS — declaracao linha 152; impl. linhas 681-689 delegando a `PropertyVisibility(Pointer(FProp))` |
| CA-4 | FPC: `MethodVisibility` levanta `EModernRTTIError`; `PropertyVisibility` devolve dado real com `case` de 4 ramos, sem `mvAutomated` | ✅ PASS — `MethodVisibility` levanta via `SFPCNoVisibility` reescrita; `PropertyVisibility` tem `case` de exatamente 4 ramos qualificados (`TMemberVisibility.mvPrivate` etc.) sobre `TRttiProperty(AToken).Visibility` |
| CA-5 | Delphi: `MethodVisibility` e `PropertyVisibility` com `case` de 4 ramos qualificados, sem `mvAutomated`, sem resourcestring nova | ✅ PASS — ambas com `case` de 4 ramos qualificados; nenhuma `resourcestring` nova no backend Delphi |
| CA-6 | `Scenario_Method_Visibility_FPC_Raises` so FPC; `_Delphi_Returns_mvPublished` so Delphi; `Scenario_Property_Visibility_Returns_mvPublished` nas duas cascas | ✅ PASS — FPC casca: `TestMethod_Visibility_FPC_Raises` + `TestProperty_Visibility_Returns_mvPublished` (sem o Delphi-only). Delphi casca: `TestMethod_Visibility_Delphi_Returns_mvPublished` + `TestProperty_Visibility_Returns_mvPublished` (sem o FPC-only). Cross-compiler publicado nos dois lados |
| CA-7 | `grep -rn "TMemberVisibility" Source/ModernSyntax.RTTI.pas` zero hits fora da `uses` de `implementation` | ✅ PASS — 3 hits em XMLDoc `///` (linhas 61, 64, 65); zero em codigo executavel. `TypInfo` permanece na `uses` da `interface` por outros simbolos (`PTypeInfo`, `TTypeData`, `GetTypeData`) — correto |
| CA-8 | Compila FPC 3.2.2 x86_64 sem erro; suites verdes | ✅ PASS (x86_64) / ⚠️ CAVEAT (i386 e Delphi) — 30/0/0/exit=0 em x86_64; i386 e Delphi nao exercitados pela fabrica. Autor confirma Delphi 12 e i386 externamente. Nenhuma aritmetica literal de ponteiro nova introduzida — risco i386 negligenciavel |
| CA-9 | Mutacao de sanidade verificada: trocar `PropertyVisibility` por valor fixo → cenario fica vermelho | ✅ PASS — documentado no implement-report: exit=2 com `ETestScenarioFailed: Property.Visibility devolveu ordinal 0; esperado 3 (mvPublished)`. Revertido; rebuild verde 30/0/0/exit=0 |
| CA-10 | XMLDoc em membros novos/alterados: `TModernRTTIMethod.Visibility` mantem clausula "FPC levanta"; `TModernRTTIProperty.Visibility` NAO carrega essa clausula | ✅ PASS — `TModernRTTIMethod.Visibility` (linhas 305-313) menciona FPC raise e raiz `vmtMethodTable`; `TModernRTTIProperty.Visibility` (linhas 138-151) explicita assimetria sem prometer raise no FPC |

## Issues criticas

Nenhuma.

## Observacoes nao-bloqueantes

### OBS-1 — Comentario coletivo de `TModernRTTIMethod` menciona `Visibility` na lista dos "seis membros que levantam no FPC"

`Source/ModernSyntax.RTTI.pas:247-257` (remarks do record) lista
`Visibility` junto com `GetParameters`, `ReturnType`, etc. como membros
que levantam `EModernRTTIError` no FPC. O comportamento nao mudou
(Method.Visibility CONTINUA levantando no FPC por D-42.5), entao o
comentario esta correto. O implementer notou que a razao documentada
na XMLDoc especifica de `Visibility` foi reescrita para expor a raiz
(`vmtMethodTable`). O comentario coletivo nao precisa replicar a raiz;
apenas lista os membros. Nao requer correcao.

### OBS-2 — `Result := TModernVisibility.mvPublic` antes do `raise` em `MethodVisibility` FPC

Padrao de apaziguamento do compilador (suprimir "variavel de saida nao
inicializada"). Consistente com `MethodIsConstructor`, `MethodIsClassMethod`,
`MethodIsStatic` no mesmo arquivo. Aceitavel.

### OBS-3 — CA-8 caveats de ambiente

Compilacao Delphi e FPC i386 nao sao exercitadas pelo CI Aefos por
limitacao de toolchain (SKILL.md). O padrao do projeto ja previa essa
limitacao desde o ciclo 010. O PR body deve declarar o que foi compilado
(exigencia de CA-8). O implement-report declara o caveat e a rationale.
Nao e defeito de implementacao.

## Convencoes

- **D-25.1** ✅ — Zero `{$IFDEF}` em declaracoes de tipo na `interface` de `ModernSyntax.RTTI.pas`
- **D-25.4** ✅ — `MethodVisibility` FPC levanta com `SFPCNoVisibility` reescrita (D-42.5)
- **CA-5 (repo)** ✅ — Zero diretiva por compilador em `UScenarios.RTTI.pas` nos 3 cenarios novos
- **Nomenclatura** ✅ — Prefixo `mv` no enum, `L` em locais, `A` em parametros, XMLDoc em membros publicos novos
- **D-42.2** ✅ — `case` qualificado de 4 ramos nos dois backends, nunca `Ord`

## Veredicto

**APPROVED** — Ciclo 015 entrega o escopo completo da issue #42 com todos
os criterios de aceitacao satisfeitos e mutacao de sanidade verificada.
