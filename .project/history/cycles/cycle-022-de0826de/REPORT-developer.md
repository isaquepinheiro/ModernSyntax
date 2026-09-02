---
type: cycle-report
kind: report
title: "REPORT-developer — cycle 022 (issue #51): implement node"
description: "Slice unico entregue nos 6 passos: resourcestring privada + else raise em MethodVisibility/PropertyVisibility + 2 comentarios reescritos + 1 XML-doc reescrito. FPC x86_64 verde (42/42); alvos Delphi ficam com o mantenedor."
cycle: "022"
agent: developer
workflow: equipe-bug
node: implement
resource: aefos://run/de0826deb51365cb442a8acd3e0fd103
tags: [cycle-report, developer, implement, issue-51, modernrtti, delphi, visibility]
generated:
  by: "equipe-bug@node:implement"
  at: "2026-09-02T00:00:00Z"
---

# REPORT-developer — cycle 022 (issue #51)

## Contexto

Ciclo 022, workflow `equipe-bug`, no `implement`. Entrada: task-input +
esp + plan + adr do arquiteto (ver [REPORT-architect](REPORT-architect.md)
e [REPORT-planner](REPORT-planner.md)). Escopo: fix de bug — `case sem
else` no backend Delphi devolvia lixo em runtime (W1035 medido nos 4
alvos com 3 valores distintos de lixo).

## O que fiz

Executei os 6 passos do [plan](pipeline-plan.md) sem desvio, todos no
mesmo slice/commit:

1. **Passo 0** — Adicionei `SDelphiUnknownVisibility` ao bloco
   `resourcestring` existente da `implementation` de `ModernSyntax.RTTI.
   Delphi.pas` (apos `SSetWrongKind`). Comentario documenta D-51.3 e
   contraste com PR #58 (`SModernRTTINilHandle` foi promovida porque
   um cenario externo comparava por igualdade — aqui nao ha).
2. **Passos 1 + 2** — Inseri `else raise EModernRTTIError.CreateFmt(
   SDelphiUnknownVisibility, [Ord(<Token>.Visibility), '<nome>'])` antes
   do `end;` em `MethodVisibility` e `PropertyVisibility`. `Ord(...)`
   usa o `TMemberVisibility` do RTL (via `.Visibility` do `TRttiMethod`/
   `TRttiProperty`), nao o `TModernVisibility` da casca — reporta o
   ordinal REAL que o RTL passou (mitigacao explicita de R-51.2 do ESP).
3. **Passos 3 + 4** — Reescrevi os dois comentarios. Substitui a
   afirmacao falsa ("o compilador acusa erro no primeiro build") por
   framing baseado no que foi MEDIDO na run
   `2e4913d83ea2e1f06b3d8e8589bcbc4f` (lixo 204/16/252/16, W1035 morre
   igualmente com cast e com raise, desempate por fail-loud vs.
   errado-em-silencio). Preservei: no `MethodVisibility` o paragrafo
   sobre qualificacao dos case labels; no `PropertyVisibility` a nota
   sobre `AOwner` ("seria ruido — AOwner ficaria morto") — atualizada
   para citar D-51.5 e amarrada explicitamente a escolha do `%s` na
   mensagem.
4. **Passo 5** — Reescrevi o XML-doc de `TModernVisibility` em
   `Source/ModernSyntax.RTTI.pas` linhas 71-83, trocando "o `case`
   explicito nos backends (D-42.2) acusa erro no primeiro build" por "o
   backend Delphi levanta `EModernRTTIError` no primeiro chamador
   (D-51.1 do ADR issue #51); o backend FPC valida exaustividade em
   compile-time — `case` de 4 ramos sem `else` e correto la (4 valores
   em `rtti.pp:308`)".

Avancei o quadro em `.project/project-evolution.md` de `🔄 in-pipeline`
para `🔄 in-review`.

## Validacoes

FPC 3.2.2 x86_64 na fabrica, seguindo a receita de
[pipeline-esp](pipeline-esp.md) §4 e SKILL.md (secoes agent-discovered
2026-08-28 e 2026-08-31):

```
rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild && \
fpc -Mdelphi \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -Fi"Test Shared/EclbrSystem" \
    -FU/tmp/fpcbuild -FE/tmp/fpcbuild \
    "Test FPC/EclbrSystem/PTestRTTI.lpr"
/tmp/fpcbuild/PTestRTTI --all -a --format=plain
```

- **Build:** `4622 lines compiled, 1.2 sec` — link OK. Warnings/notes
  emitidos sao os PRE-EXISTENTES do repo (unit `Rtti` experimental,
  managed result nao inicializado em `RTTI.FPC.pas:583/832` e
  `RTTI.pas:1081`, `unreachable code` em `Invoker.pas:80`, notas de
  `generics.collections`). Nenhum warning novo.
- **Testes:** 42 rodados, 0 erros, 0 falhas. Os dois cenarios de
  Visibility ativos no FPC (`TestMethod_Visibility_FPC_Raises` e
  `TestProperty_Visibility_Returns_mvPublished`) verdes.

## O que NAO foi validado aqui

- **4 alvos Delphi (Delphi 23.0 e 37.0 x Win32/Win64):** fabrica nao tem
  `dcc32`/`bcc32` (SKILL.md, agent-discovered 2026-08-28). O acceptance
  §1 do task-input ("W1035 zerado") fica com o mantenedor. Argumento
  registrado em D-51.2 do ADR: tanto `else cast` quanto `else raise`
  matam W1035 igualmente, e a forma implementada e a mesma medida.
- **FPC i386:** sem cross-compiler na fabrica (`ppc386` retorna 127).

O PR deve carregar a declaracao literal exigida pelo task-input §
"Checklist de acceptance".

## Handoff

Relatorio detalhado em [pipeline-implement-report](pipeline-implement-report.md).
Proximos nos: review / test / verify.

## Cross-links do bundle usados

- [pipeline-esp](pipeline-esp.md) — ESP da issue #51.
- [pipeline-plan](pipeline-plan.md) — Slice unico `fits`, 6 passos.
- [pipeline-adr](pipeline-adr.md) — D-51.1 (mecanismo) + D-51.2 a D-51.8.
- [pipeline-task-input](pipeline-task-input.md) — Handoff operacional
  do arquiteto.
- [pipeline-implement-report](pipeline-implement-report.md) — Relatorio
  operacional detalhado deste no.
- [REPORT-architect](REPORT-architect.md) e [REPORT-planner](REPORT-planner.md)
  — Reports dos nos anteriores neste ciclo.
