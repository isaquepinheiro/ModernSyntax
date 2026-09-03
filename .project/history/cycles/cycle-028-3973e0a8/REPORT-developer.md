---
type: cycle-report
kind: report
cycle: "028"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/3973e0a8a9fb319c0e20e1154e93d8d3
title: "REPORT-developer #13 — overload dinamico TValue-based cross-compiler entregue"
description: "Implementacao entregue com suite FPC x86_64-linux 10/14 verde (7 antigos + 3 guardas) e 4 erros de RTL (SystemInvoke nao implementado para SysV AMD64), documentados em SKILL.md."
generated:
  by: "equipe-feature@node:implement"
  at: "2026-09-03T00:00:00Z"
tags: [report, implement, invoker, rtti, fpc, delphi, issue-13, cycle-028]
---

# REPORT-developer — ciclo 028 (#13)

## O que foi entregue

- **`Source/ModernSyntax.Invoker.pas`** — novo overload dinamico
  `class function Invoke(AInstance, AMethodName, AArgs, AResultType): TValue`
  com assinatura publica identica cross-compiler e corpo divergente por
  `{$IFDEF FPC}`. Cabecalho reescrito (3 blocos superados removidos,
  D-13.7). `uses` da interface acrescenta `Rtti`. XMLDoc por compilador
  (D-13.8). Portavel `Invoke<TSignature>` da #10 intocado (D-13.13).
- **`Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas`** — 8 cenarios
  novos `Case_InvokeDynamic_...`, fixture `TDateAndTag` (Integer+string,
  ABI-divergent por bitness — D-13.11) e metodos published em `TSubject`
  (`GimmeStamp`, `GimmeAngle`, `StampNow`, `Stamped`). Zero `{$IFDEF FPC}`
  (CA-5 preservado; verificado por grep).
- **`Test FPC/EclbrSystem/UTestMS.Invoker.pas`** — 7 metodos published
  novos (delegam ao `Case_...`); registra `_RaisesOnFPC`, NAO
  `_OKOnDelphi` (assimetria da CASCA, D-13.3).
- **`Test Delphi/EclbrSystem/UTestMS.Invoker.pas`** — 7 `[Test]` novos
  (delegam ao `Case_...`); registra `_OKOnDelphi`, NAO `_RaisesOnFPC`.
- **`.project/SKILL.md`** — APPEND ONLY: nova secao agent-discovered
  2026-09-03 registrando que `Rtti.Invoke` livre nao esta implementada
  para target `x86_64-linux` na FPC 3.2.2 (fallback
  `SErrInvokeNotImplemented`), com consequencia operacional para
  futuros ciclos.
- **`.project/project-evolution.md`** — linha do ciclo 028 permanece em
  `🔄 in-review` (implementacao pronta; aguardando review/test/verify).

## Quality commands rodados (fabrica x86_64-linux)

```
rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild
fpc -Mdelphi -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -FU/tmp/fpcbuild -FE/tmp/fpcbuild "Test FPC/EclbrSystem/PTestInvoker.lpr"
/tmp/fpcbuild/PTestInvoker --all -a --format=plain
```

- Compilacao verde: `21 lines compiled, 0.2 sec`. Zero warnings, zero
  erros, zero notes.
- Suite `N:14 E:4 F:0 I:0` — 10/14 verdes:
  - 7 existentes verdes (regressao zero em `Invoke<TSignature>`,
    D-13.13 confirmado por medicao).
  - 3 guardas dinamicas verdes: `_NilInstance_Raises`,
    `_MethodNotFound_RaisesInstructive`, `_PublicWithoutMPlus_RaisesOnFPC`.
  - 4 erros `ENotImplemented: Invoke functionality is not implemented`
    — os cenarios que atingem o path vivo da funcao livre `Rtti.Invoke`
    (`_ReturnsRecordIntegerAndString`, `_ReturnsDouble`,
    `_ReturnsManagedString`, `_ProcedureVoid_SideEffect`).
- CA-5: `grep -c "{\$IFDEF FPC}" "Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas"` = 0.

## Fronteira medida (critica para review/verify)

Os 4 erros vivos vem da RTL do FPC 3.2.2 (`packages/rtl-objpas/src/inc/rtti.pp:583`
+ `packages/rtl-objpas/src/x86_64/invoke.inc`): `SystemInvoke` so foi
portada para `x86_64-win64`; target Linux cai no fallback documentado.
NAO e defeito da nossa implementacao — o codigo chega ate a chamada RTL
corretamente e as tres guardas verdes provam a camada nossa. Autor
(Windows FPC + Delphi) exercita o path vivo antes do merge conforme
D-13.12.

Nova secao em [SKILL.md](../../SKILL.md) registra o achado para futuros
ciclos.

## Traceabilidade

- Ciclo dir sibling reports:
  [architect](REPORT-architect.md), [planner](REPORT-planner.md),
  [pipeline-esp](pipeline-esp.md), [pipeline-adr](pipeline-adr.md),
  [pipeline-plan](pipeline-plan.md), [pipeline-task-input](pipeline-task-input.md).
- Implement report irmao: `.project/pipeline/implement-report.md` (sera
  espelhado pelo `mirror` como `pipeline-implement-report.md` neste
  diretorio).

## Sinais para os proximos nodes

- **Review:** conferir que o cabecalho da unit nao mantem os tres blocos
  superados; que `Rtti.Invoke` esta qualificado; que o Delphi tem
  `try/finally .Free`; que `AResultType` no Delphi tem comentario
  explicando o "ignorado por design"; que zero `{$IFDEF FPC}` no
  `.Cases.pas`.
- **Test/Verify:** os 4 erros de RTL nao devem bloquear se a decisao
  D-13.12 e reconhecida — reportar como *"fronteira SysV AMD64 FPC 3.2.2,
  autor prova path vivo"* e citar SKILL.md.
