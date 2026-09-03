---
type: task
kind: artifact
title: "Task #13 — TModernInvoker.Invoke dinamico cross-compiler"
description: "Entregar overload dinamico TValue-based de TModernInvoker com assinatura identica cross-compiler, backends divergentes por IFDEF, 8 novos cenarios e cascas assimétricas."
cycle: "028"
agent: planner
workflow: equipe-feature
node: task
resource: aefos://run/3973e0a8a9fb319c0e20e1154e93d8d3
generated:
  by: "equipe-feature@node:task"
  at: "2026-09-03T00:00:00Z"
tags: [task, rtti, invoker, fpc, delphi, dynamic-invoke, tvalue, issue-13, cycle-028]
---

# Task #13 — `TModernInvoker.Invoke` dinamico cross-compiler

## Tracking

**Modo:** MAESTRO MODE  
**Issue GitHub:** [#13](https://github.com/isaquepinheiro/ModernSyntax/issues/13)  
**Ciclo:** 028 (`cycle-028-3973e0a8`)  
**Estado:** 🔄 in-pipeline

A issue #13 é a demanda oficial deste ciclo — criada pelo maestro como
`aefos:investigated` e é o intake canônico. Nenhuma issue ou Epic adicional
foi criada.

## Briefing

Entregar o overload dinâmico:

```pascal
class function Invoke(const AInstance: TObject; const AMethodName: string;
  const AArgs: array of TValue;
  const AResultType: PTypeInfo = nil): TValue; overload; static;
```

com **assinatura pública idêntica** em Delphi e FPC 3.2.2, sem `{$IFDEF}` na
superfície, e mecanismo interno divergente por `{$IFDEF FPC}`:

- **FPC 3.2.2**: `TObject.MethodAddress` + `Rtti.Invoke` livre (`rtti.pp:583`),
  alcance `published` apenas.
- **Delphi**: `TRttiContext.GetType.GetMethod.Invoke`, alcance `public` + `published`.

O overload portátil `Invoke<TSignature>` da issue #10 **não muda** (D-13.13).

## Arquivos impactados

| Arquivo | Mudança |
|---------|---------|
| `Source/ModernSyntax.Invoker.pas` | Novo overload dinâmico; `uses` += `Rtti`; corpo por `{$IFDEF FPC}`; cabeçalho reescrito — 3 blocos superados removidos |
| `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas` | `TDateAndTag` record + métodos `published` em `TSubject`; 8 novos `Case_InvokeDynamic_*` |
| `Test FPC/EclbrSystem/UTestMS.Invoker.pas` | 7 `published procedure InvokeDynamic_*` (total 7→14); registra `_RaisesOnFPC`, não `_OKOnDelphi` |
| `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` | 7 `[Test] procedure InvokeDynamic_*` (total 7→14); registra `_OKOnDelphi`, não `_RaisesOnFPC` |

## Decisões fechadas (pré-condições)

- **D-13.1**: Assinatura única, sem `{$IFDEF}` na declaração.
- **D-13.3**: Alcance por compilador — FPC: `published`; Delphi: `public` + `published`.
- **D-13.5**: Self como `[0]` da `TValueArray` no FPC.
- **D-13.6 / D-13.8**: `ccReg` apenas; XMLDoc documenta fronteiras.
- **D-13.9 / D-13.10**: Mensagens de guarda reusadas do portável da #10.
- **D-13.11**: Fixture `Integer+string` (record ABI-divergente) e `Double`.
- **D-13.12**: i386 e alvos Delphi ficam com o autor; fábrica cobre FPC x86_64.
- **D-13.13**: Overloads genéricos byte-por-byte idênticos após a edição.

## Checklist de aceitação resumido

- [ ] `ModernSyntax.Invoker.pas`: cabeçalho reescrito, `uses Rtti`, 1 novo overload, implementação `{$IFDEF FPC}`.
- [ ] `UTestMS.Invoker.Cases.pas`: `TDateAndTag`, novos métodos `TSubject`, 8 Cases; zero `{$IFDEF}` (CA-5).
- [ ] Casca FPC: 7→14 métodos, registra `_RaisesOnFPC`.
- [ ] Casca Delphi: 7→14 métodos, registra `_OKOnDelphi`.
- [ ] FPC 3.2.2 x86_64 compila limpo (único warning `Unit "Rtti" is experimental`); `--all` passa 14/14.
- [ ] PR body com log de execução FPC e referências obrigatórias.
- [ ] Commit único no formato do plano.

## Referências

- ESP: [esp.md](pipeline-esp.md)
- ADR (13 decisões D-13.1..D-13.13): [adr.md](pipeline-adr.md)
- Task-input completo: [task-input.md](pipeline-task-input.md)
- Toolchain: [SKILL.md](../../../SKILL.md)
- Issue: https://github.com/isaquepinheiro/ModernSyntax/issues/13
