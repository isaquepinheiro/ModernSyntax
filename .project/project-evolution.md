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
| 004 | [#8](https://github.com/isaquepinheiro/ModernSyntax/issues/8) | Implementar Source/ModernSyntax.RTTI.pas + cenários compartilhados + cascas de teste (Pilar 1 da ModernRTTI) | 🔄 in-review |

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

**Ciclo 004** — MAESTRO MODE. A issue #8 é a demanda oficial deste ciclo
(retomada do ciclo 002 após PR #11 fechado sem merge). Nenhuma issue ou Epic
adicional criada. Label atual: `aefos:running, feature`. Escopo: criar
`Source/ModernSyntax.RTTI.pas` (TModernRTTI, TModernRTTIType,
TModernRTTIProperty, TModernRTTIField, EModernRTTIError), cenários
compartilhados em `Test Shared/EclbrSystem/UScenarios.RTTI.pas`, casca
DUnitX em `Test Delphi/`, runner Delphi + groupproj/DCC.bat, e casca
FPCUnit em `Test FPC/` registrada no .lpi da #7.
