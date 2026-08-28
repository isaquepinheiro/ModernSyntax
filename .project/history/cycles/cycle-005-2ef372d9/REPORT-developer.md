---
type: cycle-report
kind: report
title: "REPORT-developer — ciclo 005 (TModernInvoker)"
description: "Implementação de TModernInvoker (record com dois overloads Invoke<TSignature> sobre TObject.MethodAddress), unit de cenários compartilhada e duas cascas finas; 7/7 testes verdes em FPC 3.2.2 x86_64."
cycle: "005"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/2ef372d993ff75b8dcd8c707bb79d636
tags: [cycle-005, developer, modernrtti, invoker, issue-10]
generated:
  by: "equipe-feature@node:implement"
  at: "2026-08-28T14:30:00Z"
---

# REPORT-developer — ciclo 005

## O que foi entregue

Quatro fatias do plano executadas sem desvio (ver
[pipeline-plan](pipeline-plan.md)):

1. `Source/ModernSyntax.Invoker.pas` — `TModernInvoker` record com dois
   overloads `class function Invoke<TSignature>(TObject|TClass, string):
   TSignature; static;` sobre `TObject.MethodAddress`. Guarda `SizeOf`
   como primeira linha, guarda `nil` em seguida, mensagem de "não
   encontrado" citando `{$M+}` e `published`. `uses SysUtils;` apenas.
   Header em `(* ... *)`. Zero directive de compilador e zero inclusão
   do include compartilhado do repositório (ver [pipeline-adr](pipeline-adr.md)
   D-A6).
2. `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas` — sete cenários
   procedurais, classes-alvo locais, `{$M+}` só onde faz sentido.
3. `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` + `PTestInvoker.dpr` +
   `PTestInvoker.dproj` + `PTestInvoker.res` — casca fina DUnitX, 7
   `[Test]`, delegação em uma linha.
4. `Test FPC/EclbrSystem/UTestMS.Invoker.pas` + `PTestInvoker.lpr` +
   `PTestInvoker.lpi` — casca fina FPCUnit, 7 métodos `published`,
   `RegisterTest`, `.lpi` com dois build modes.

Board local avançou para `🔄 in-review` em
[project-evolution](../../project-evolution.md) (via [pipeline-implement-report](pipeline-implement-report.md)).

## Prova por binário

- **FPC 3.2.2 Linux x86_64:** compilou (450 linhas, 0 erros, 3 warnings
  esperados de *unreachable code* na instanciação `Invoke<Integer>` — a
  guarda `SizeOf` sempre triggera e o restante da função de fato é
  inalcançável). `PTestInvoker` executou com `NumberOfRunTests=7`,
  `NumberOfErrors=0`, `NumberOfFailures=0`.
- **FPC 3.2.2 i386:** `ppc386` ausente no container do orquestrador;
  fica com o autor conforme SKILL §"The command".
- **Delphi:** fica com o autor (R2 do PRD; SKILL §"Delphi"). O `.dproj`
  nasceu de cópia direta de `PTestObjects.dproj` com substituições
  mínimas (GUID novo, `MainSource`, `ProjectName`, `SanitizedProjectName`,
  três `DCCReference`).

## Gates de aceitação (grep)

Todos os greps do task-input §"Verificação por grep" retornam **0**:

- `{\$IFDEF FPC}` em qualquer um dos três arquivos de teste → 0.
- `{$I ModernSyntax.inc}` em `Source/ModernSyntax.Invoker.pas` → 0.
- `FCP` em `Source/ModernSyntax.Invoker.pas` → 0.
- `{\$IFDEF` em `Source/ModernSyntax.Invoker.pas` → 0.
- `DUnitX` em `Test FPC/EclbrSystem/*.pas` e `.lpr` → 0.
- `^uses` em `Source/ModernSyntax.Invoker.pas` → 1 (apenas `uses SysUtils;`
  na interface).

## Fidelidade a esp/adr/plan

- **CA-1..CA-7 do [pipeline-esp](pipeline-esp.md)** — cobertos por um
  cenário cada, todos verdes no binário FPC.
- **CA-8 (`grep '{\$IFDEF FPC}'` = 0)** — verificado.
- **CA-9 (`.lpi` com dois build modes)** — presente
  (`Debug-x86_64` default, `Debug-i386`); FPC constrói com o comando
  canônico da SKILL.
- **CA-10 (Invoker sem `.inc`, `FCP`, `{$IFDEF FPC}`)** — verificado.
- **CA-11 (`uses` = `SysUtils` apenas)** — verificado.
- **CA-12 (declarações do PR body)** — repassado ao committer via
  [pipeline-implement-report](pipeline-implement-report.md) §"Escopo do
  PR body a declarar".
- **RN-1..RN-10 do [pipeline-esp](pipeline-esp.md)** — todos respeitados
  (record, dois overloads, guarda `SizeOf` primeira linha, mensagem
  acionável, autocontenção, header `(* ... *)`, corpo do genérico só
  toca `TMethod`, casca com uma linha útil por teste).
- **D-A1..D-A10 do [pipeline-adr](pipeline-adr.md)** — todos aplicados;
  o rename D-A10 (`Case_TypedMethod_CalledWithArgs_ReturnsExpected`) é o
  nome do cenário e do `[Test]` correspondente nas duas cascas.

## Notas para o próximo agente

- O warning FPC *"unreachable code"* na instanciação `Invoke<Integer>`
  não é bug — valida a guarda `SizeOf`. Se o revisor pedir zero
  warnings, alternativa é `{$WARN 5024 OFF}` local, mas o arquiteto
  preferiu deixar a evidência visível.
- O `Cases.pas` compila em Delphi por convenção (evita `{$mode delphi}`
  para não emitir warning de unknown directive em Delphi antigo). O
  compilador FPC recebe `-Mdelphi` na linha de comando canônica (SKILL
  §"The command").
- **PR body / TestMSGroup / DCC.bat** ficam com o autor — mesma nota
  documentada na entrega da issue #9.
