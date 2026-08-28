---
type: cycle-report
kind: report
title: "REPORT — developer (ciclo 004, issue #7 callbacks transversais)"
description: "Implementacao entregue nas 4 fatias do plan; FPC 3.2.2 x86_64 verde e 4/4 testes passaram; caveats: Callback.&Of (Of e reservada), i386/Delphi ficam com o autor."
cycle: "004"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/24c962dcc2be1819336ca1fea18ae949
tags: [report, cycle-004, developer, callbacks, issue-7, modernrtti]
generated:
  by: "equipe-feature@node:implement"
  at: "2026-08-28T15:30:00Z"
---

# REPORT — developer (ciclo 004)

## O que entreguei

As 4 fatias do plano ([plan](pipeline-plan.md)):

1. **`Source/ModernSyntax.Callback.pas`** — unit autocontida, `uses
   SysUtils` so, cabecalho `(* ... *)`, sem `{$I ModernSyntax.inc}`,
   sem token `FCP`. Tres interfaces sem GUID
   (`IModernFunc<T,R>`, `IModernProc<T>`, `IModernPredicate<T>`) +
   factory `Callback` (record) com 3 sobrecargas `&Of` para metodo de
   objeto + 3 wrappers `TxxxOfObjectWrapper` **na `interface`** (D-A13
   do [adr](pipeline-adr.md)).
2. **`Test Shared/EclbrSystem/UTestMS.Callback.Scenarios.pas`** —
   diretorio novo. Cenarios sem framework; `TAccumulator` e `THost`
   declarados como exemplo canonico. Sem `{$IFDEF}`.
3. **Casca DUnitX + `.dpr` + `.dproj` + `.res`** em
   `Test Delphi/EclbrSystem/`. Uma linha util por metodo. `.dproj`
   clonado de `PTestOption.dproj` com search path para
   `..\..\Test Shared\EclbrSystem` (Q2 do relatorio de investigacao).
4. **Casca FPCUnit + `.lpr` + `.lpi`** em `Test FPC/EclbrSystem/`
   (diretorio novo). Dois build modes (`Debug-x86_64` e `Debug-i386`);
   `<OtherUnitFiles>` = `..\..\Source;..\..\Test Shared\EclbrSystem`;
   `<RequiredPackages>` = `FCL`.

Detalhe completo, decisoes tecnicas e caveats no
[implement-report](pipeline-implement-report.md).

## Validacoes que rodei

- `fpc 3.2.2 x86_64-linux` compilou:
  - `Source/ModernSyntax.Callback.pas` isolado.
  - `Test Shared/EclbrSystem/UTestMS.Callback.Scenarios.pas` com as
    dependencias.
  - `Test FPC/EclbrSystem/PTestModernCallback.lpr` end-to-end (`.lpr` +
    casca FPCUnit + cenarios + unit).
- Binario rodou: **4/4 casos passaram** (`N:4 E:0 F:0 I:0`).
- Todos os greps do checklist do
  [task-input](pipeline-task-input.md): 0. Ver
  [implement-report](pipeline-implement-report.md) para a tabela
  completa.

## Divergencia declarada

`Callback.Of` (do ADR D-A3) foi implementado como `Callback.&Of` — `of`
e palavra reservada em Pascal e a declaracao literal do ADR nao compila
em nenhum dos dois compiladores. A fuga `&` preserva o nome do simbolo
`Of` e e aceita nos dois. Consumidor chama `Callback.&Of(Self.MinhaProc)`.
Discussao completa e alternativas em **DT-1** do
[implement-report](pipeline-implement-report.md).

## O que nao rodei aqui

- **i386 no FPC.** `ppc386` nao disponivel na fabrica; build
  `Debug-i386` configurado no `.lpi` para o autor rodar.
- **`lazbuild`.** Nao instalado na fabrica. `.lpi` no formato Lazarus
  canonico; validado indiretamente via `fpc -Mdelphi` com as mesmas
  paths de search declaradas no `.lpi`.
- **Delphi (`dcc32`/`bcc32`).** Fica com o autor por design
  (R2 do PRD, CA-7 do [esp](pipeline-esp.md)).

## Auto-enriquecimento do bundle

- **Criei `.project/SKILL.md`** (nao existia — o REPORT-planner do
  ciclo 004 registrou o bloqueio decorrente). Conteudo minimo:
  cabecalho descritivo + secao `Toolchain & quality commands
  (agent-discovered 2026-08-28)` com as tres formas de invocar o FPC
  descobertas no ciclo, e a nota de ausencia de `ppc386`/`lazbuild`.
  Apend-only para agentes futuros.

## Board

- **`.project/project-evolution.md`** — ciclo 004 movido de
  `🔄 in-pipeline` para `🔄 in-review`.
- **GitHub** — nao movi programaticamente. Bloqueio herdado do
  ciclo 004 (planner registrou). Com o SKILL.md criado agora, uma
  nova tentativa pode passar; se nao, o autor move.
