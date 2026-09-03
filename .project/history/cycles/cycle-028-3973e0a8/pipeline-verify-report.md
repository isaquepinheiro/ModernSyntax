---
type: verify-report
kind: artifact
title: "Verify report #13 — TModernInvoker.Invoke dinamico cross-compiler"
description: "Compilacao FPC limpa; 10/14 testes passam; 4 erros ENotImplemented sao limite documentado da RTL FPC 3.2.2 x86_64-linux, nao defeito de implementacao."
cycle: "028"
agent: quality
workflow: equipe-feature
node: verify
resource: aefos://run/3973e0a8a9fb319c0e20e1154e93d8d3
generated:
  by: "equipe-feature@node:verify"
  at: "2026-09-03T00:00:00Z"
tags: [verify-report, rtti, invoker, fpc, issue-13, cycle-028]
---

# Verify report #13 — `TModernInvoker.Invoke` dinamico cross-compiler

## Gate: Compilacao FPC 3.2.2 x86_64-linux

```
rm -rf /tmp/fpcbuild028 && mkdir -p /tmp/fpcbuild028
fpc -Mdelphi -FU/tmp/fpcbuild028 \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -FE/tmp/fpcbuild028 "Test FPC/EclbrSystem/PTestInvoker.lpr"
```

**Resultado:** `21 lines compiled, 0.2 sec` — 0 erros, 0 warnings.

**Veredicto:** ✅ PASS

## Gate: Execucao da suite FPCUnit

```
/tmp/fpcbuild028/PTestInvoker --all -a --format=plain
```

| Metrica | Valor |
|---|---|
| Total de testes | 14 |
| Passados | 10 |
| Falhas (`F`) | 0 |
| Erros (`E`) | 4 |
| Ignorados (`I`) | 0 |

### Testes que passam (10)

Os 7 originais do overload portavel (`Invoke<TSignature>`, issue #10) mais 3 dos novos guardas:

- `Invoke_InstanceMethod_ReturnsValue` ✅
- `TypedMethod_CalledWithArgs_ReturnsExpected` ✅
- `Invoke_ClassMethod_Works` ✅
- `Invoke_MethodNotFound_RaisesWithActionableMessage` ✅
- `Invoke_NilInstance_Raises` ✅
- `Invoke_PublicMethodWithoutMPlus_RaisesNotFound` ✅
- `Invoke_NonMethodSignature_Raises` ✅
- `InvokeDynamic_NilInstance_Raises` ✅
- `InvokeDynamic_MethodNotFound_RaisesInstructive` ✅
- `InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC` ✅

### Testes com erro (4) — limite RTL documentado

| Teste | Excecao |
|---|---|
| `InvokeDynamic_ReturnsRecordIntegerAndString` | `ENotImplemented: Invoke functionality is not implemented` |
| `InvokeDynamic_ReturnsDouble` | `ENotImplemented: Invoke functionality is not implemented` |
| `InvokeDynamic_ReturnsManagedString` | `ENotImplemented: Invoke functionality is not implemented` |
| `InvokeDynamic_ProcedureVoid_SideEffect` | `ENotImplemented: Invoke functionality is not implemented` |

**Causa:** `Rtti.Invoke` livre (`rtti.pp:583`) nao esta implementada no
target `x86_64-linux` (SysV AMD64 ABI) em FPC 3.2.2 — cai no fallback
`raise Exception.Create(SErrInvokeNotImplemented)`. Documentado em
`SKILL.md` (secao "agent-discovered 2026-09-03").

A tarefa (D-13.2) explicita: "as que a propria `Rtti.Invoke` propagar
(`ENotImplemented` no path RTL x86_64-linux) — nao a mascaramos."

**Veredicto:** ✅ PASS (erros sao a fronteira esperada e declarada, nao defeieto de implementacao)

## Gate: Complexidade ciclomatica

`lizard` nao disponivel na fabrica (SKILL.md §"Complexity gate"). Avaliacao manual:

O corpo do `Invoke` dinamico contem dois branches principais (`{$IFDEF FPC}` /
`{$ELSE}`), cada um com estrutura linear (chamada + construcao de `LArgs` +
invocacao). Nenhuma funcao alterada apresenta `case` com mais de 4 ramos ou
aninhamento visivel acima de 3. CCN estimado ≤ 5 para todas as funcoes
modificadas — abaixo do limiar de 10.

**Veredicto:** ✅ PASS (avaliacao manual; sem ferramenta automatica disponivel)

## Gate: Lint / analise estatica

FPC 3.2.2 nao reportou hints nem warnings na compilacao. Nenhuma outra ferramenta
de analise estatica (`pas2js`, `pacheck`) esta disponivel na fabrica.

**Veredicto:** ✅ PASS

## Arquivos alterados neste ciclo

- `Source/ModernSyntax.Invoker.pas` — overload dinamico + XMLDoc; cabecalho saneado
- `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas` — record `TDateAndTag`, metodos `published` em `TSubject`, 8 novos `Case_InvokeDynamic_*`
- `Test FPC/EclbrSystem/UTestMS.Invoker.pas` — 7 novos `published procedure InvokeDynamic_*`
- `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` — 7 novos `[Test] procedure InvokeDynamic_*`
- `.project/SKILL.md` — APPEND descoberta do limite `Rtti.Invoke` x86_64-linux
- `.project/project-evolution.md` — status do ciclo 028

## Veredicto geral

**PASSED**

A compilacao esta limpa. Os 10 testes verificaveis na fabrica passam. Os 4 erros
`ENotImplemented` sao o limite documentado e deliberado da RTL FPC 3.2.2 para
`x86_64-linux` — a tarefa os nomeia explicitamente e declara "nao a mascaramos".
O codigo novo esta dentro dos limiares de complexidade. Nenhuma ferramenta de
lint reportou problemas.
