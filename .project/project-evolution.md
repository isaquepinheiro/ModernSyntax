---
type: board
title: "ModernSyntax — project-evolution board"
description: "Registro evolutivo das demandas do projeto: estado atual de cada ciclo rastreado."
tags: [board, modernrtti, pilar-1]
---

# ModernSyntax — project evolution board

Quadro de estado das demandas. Cada entrada referencia a issue GitHub
correspondente e o ciclo ativo.

| Ciclo | Issue | Demanda | Estado |
|-------|-------|---------|--------|
| 002 | [#8](https://github.com/isaquepinheiro/ModernSyntax/issues/8) | Implementar Pilar 1 — Leitura de RTTI (TModernRTTIType, TModernRTTIProperty, TModernRTTIField) | 📤 PR aberto — [#11](https://github.com/isaquepinheiro/ModernSyntax/pull/11) |
| 003 | [#7](https://github.com/isaquepinheiro/ModernSyntax/issues/7) | Implementar callbacks transversais — IModernFunc, IModernProc, IModernPredicate + factory Callback.Of | 📤 PR aberto — [#12](https://github.com/isaquepinheiro/ModernSyntax/pull/12) |
| 004 | [#9](https://github.com/isaquepinheiro/ModernSyntax/issues/9) | Implementar Pilar 2 — Atributos portáveis (ModernSyntax.Attributes.pas + cenários + cascas DUnitX e FPCUnit) | 📤 PR aberto — [#16](https://github.com/isaquepinheiro/ModernSyntax/pull/16) |
| 005 | [#10](https://github.com/isaquepinheiro/ModernSyntax/issues/10) | Implementar Pilar 3 — TModernInvoker (ModernSyntax.Invoker.pas + cenários + cascas DUnitX e FPCUnit) | 📤 PR aberto — [#19](https://github.com/isaquepinheiro/ModernSyntax/pull/19) |
| 006 | [#8](https://github.com/isaquepinheiro/ModernSyntax/issues/8) | Pilar 1 ModernRTTI — Source/ModernSyntax.RTTI.pas + cascas de teste (re-entrada pós plan-gate:on_reject) | 📤 PR aberto — [#20](https://github.com/isaquepinheiro/ModernSyntax/pull/20) |
| 004 | [#7](https://github.com/isaquepinheiro/ModernSyntax/issues/7) | Reimplementar callbacks transversais — nova iteração após plan-gate:on_reject (ciclo 003) | 📤 PR aberto — [#18](https://github.com/isaquepinheiro/ModernSyntax/pull/18) |
| 008 | [#21](https://github.com/isaquepinheiro/ModernSyntax/issues/21) | TModernRTTIField portável nos dois compiladores — mesmo tipo, dois mecanismos por dentro (FPC via vmtFieldTable, Delphi via TRttiField) | 📤 PR aberto — [#34](https://github.com/isaquepinheiro/ModernSyntax/pull/34) |
| 009 | [#25](https://github.com/isaquepinheiro/ModernSyntax/issues/25) | TModernRTTIMethod pela vmtMethodTable — GetMethods/GetMethod nos dois compiladores; split backends RTTI; TModernRTTIParameter; fechar #35 | 📤 PR aberto — [#36](https://github.com/isaquepinheiro/ModernSyntax/pull/36) |

## Legenda

- 🔄 in-pipeline — ciclo ativo; artefatos em produção
- 🔄 in-review — implementação entregue; aguardando review/test/verify
- 📤 PR aberto — branch commitada e PR aberto para revisão humana
- ✅ done — PR mergeado, ciclo encerrado
- ⏸ blocked — aguardando dependência externa
- ❌ rejected — descartado com registro de decisão

## Notas de rastreamento

**Ciclo 002** — MAESTRO MODE. A issue #8 foi criada pelo maestro como
`aefos:investigated` e é a demanda oficial deste ciclo. Nenhuma issue ou
Epic adicional foi criada. Label atual: `aefos:running, feature`.

**Ciclo 003** — MAESTRO MODE. A issue #7 é a demanda oficial deste ciclo
(intake do maestro). Nenhuma issue ou Epic adicional criada. Label atual:
`aefos:running, feature`. Entrega: `Source/ModernSyntax.Callback.pas` com
três interfaces genéricas e factory `Callback.Of`; unit de cenários em
`Test Shared/`; cascas finas DUnitX e FPCUnit.

**Ciclo 004** — MAESTRO MODE. A issue #9 é a demanda oficial deste ciclo
(intake do maestro). Nenhuma issue ou Epic adicional criada. Demanda:
implementar `Source/ModernSyntax.Attributes.pas` com `TModernAttribute` e
`ModernAttributes` (Register + GetAttributes + regra 2 do ADENDO), unit
compartilhada de cenários e duas cascas finas (DUnitX + FPCUnit).

**Ciclo 005** — MAESTRO MODE. A issue #10 é a demanda oficial deste ciclo
(intake do maestro). Nenhuma issue ou Epic adicional criada. Demanda:
implementar `Source/ModernSyntax.Invoker.pas` com `TModernInvoker` (record
com dois overloads `Invoke<TSignature>` sobre `TObject.MethodAddress`),
unit compartilhada de sete cenários e duas cascas finas (DUnitX + FPCUnit).

**Ciclo 006** — MAESTRO MODE. A issue #8 é a demanda oficial deste ciclo
(re-entrada da demanda Pilar 1 ModernRTTI, após plan-gate:on_reject nos
ciclos anteriores). Nenhuma issue ou Epic adicional criada. Demanda:
criar `Source/ModernSyntax.RTTI.pas` (TModernRTTI, TModernRTTIProperty
portável; TModernRTTIField Delphi-only em {$IFNDEF FPC}; EModernRTTIError),
unit compartilhada de cenários, cascas DUnitX + FPCUnit, runner Delphi e
PTestRTTI.lpr + .lpi standalone FPC (padrão commit 7114cdc). Compilar FPC
antes de entregar.

**Ciclo 008** — MAESTRO MODE. A issue #21 é a demanda oficial deste ciclo
(intake do maestro: `aefos:investigated`). Nenhuma issue ou Epic adicional
criada. Demanda: tornar `TModernRTTIField` e `TModernRTTIType.GetFields`
portáveis nos dois compiladores — declaração pública incondicional, factories
privadas `FromRaw` (FPC) / `FromRtti` (Delphi), loop de herança via
`vmtFieldTable` tipada no FPC, subindo por `ClassParent`. Três arquivos
modificados: `Source/ModernSyntax.RTTI.pas`, `Test Shared/EclbrSystem/UScenarios.RTTI.pas`,
`Test FPC/EclbrSystem/UTestMS.RTTI.pas`. Build FPC 3.2.2 x86_64 e i386 obrigatório.

**Ciclo 009** — MAESTRO MODE. A issue #25 é a demanda oficial deste ciclo
(intake do maestro: `aefos:investigated`). Nenhuma issue ou Epic adicional
criada. Demanda: adicionar `TModernRTTIMethod` (Name, Invoke, GetParameters,
ReturnType, IsConstructor, IsClassMethod, IsStatic, Visibility) e
`TModernRTTIParameter` (Name, ParamType); alimentar `GetMethods`/`GetMethod`
nos dois compiladores; split dos backends em `ModernSyntax.RTTI.Delphi.pas`
e `ModernSyntax.RTTI.FPC.pas`; migrar `TModernRTTIField` para o novo desenho;
fechar #35 (cirurgia do `Fail`). Build FPC 3.2.2 x86_64 e i386 obrigatório.
Seis arquivos impactados (dois novos).
