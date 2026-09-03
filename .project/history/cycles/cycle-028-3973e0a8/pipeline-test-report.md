---
type: test-report
kind: artifact
title: "Test Report — ciclo 028 — TModernInvoker.Invoke dinamico (issue #13) — 10a entrada"
description: "Suite FPC 3.2.2 x86_64-linux: 10/14. 4 ENotImplemented da RTL (SystemInvoke SysV AMD64 nao implementado no FPC 3.2.2). Codigo correto; AC-10 sem qualificacao de OS. 10a rejeicao identica."
cycle: "028"
agent: quality
workflow: equipe-feature
node: test
resource: aefos://run/3973e0a8a9fb319c0e20e1154e93d8d3
generated:
  by: "equipe-feature@node:test"
  at: "2026-09-03T00:00:00Z"
tags: [test-report, quality, fpc, rtti, linux, spec, issue-13, cycle-028, iteration-10]
---

# Test Report — ESP #13 — `TModernInvoker.Invoke` dinamico (10ª entrada)

## Ambiente de execução

| Item | Valor |
|------|-------|
| FPC | 3.2.2+dfsg-46 [2025/02/08] |
| Target | x86_64-linux (SysV AMD64 ABI) |
| Suite | `PTestInvoker --all` |
| Compilação | 21 linhas, 0 warnings, 0 errors |

## Resultado da execução

```
Time:00.000 N:14 E:4 F:0 I:0
  TInvokerTests Time:00.000 N:14 E:4 F:0 I:0
    Invoke_InstanceMethod_ReturnsValue               OK
    TypedMethod_CalledWithArgs_ReturnsExpected        OK
    Invoke_ClassMethod_Works                         OK
    Invoke_MethodNotFound_RaisesWithActionableMessage OK
    Invoke_NilInstance_Raises                        OK
    Invoke_PublicMethodWithoutMPlus_RaisesNotFound   OK
    Invoke_NonMethodSignature_Raises                 OK
    InvokeDynamic_ReturnsRecordIntegerAndString      Error: ENotImplemented
    InvokeDynamic_ReturnsDouble                      Error: ENotImplemented
    InvokeDynamic_ReturnsManagedString               Error: ENotImplemented
    InvokeDynamic_ProcedureVoid_SideEffect           Error: ENotImplemented
    InvokeDynamic_NilInstance_Raises                 OK
    InvokeDynamic_MethodNotFound_RaisesInstructive   OK
    InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC     OK
```

**10/14 pass | 4 Error | 0 Failures**

Mensagem dos 4 erros: `Invoke functionality is not implemented` (classe `ENotImplemented`).

## Diagnóstico

Os 4 testes que falham são os únicos que atingem `Rtti.Invoke` (função livre `rtti.pp:583`) em runtime.
Os 10 que passam incluem: todos os 7 originais do portável `Invoke<TSignature>` (regressão zero)
e os 3 novos que disparam guardas antes de chegar ao `Rtti.Invoke`.

Causa raiz (documentada desde a 1ª entrada, inalterada):
`SystemInvoke` no FPC 3.2.2 não está implementado para o target `x86_64-linux` (SysV AMD64 ABI).
Funciona em `x86_64-win64` (Microsoft x64 ABI) — onde o dono mediu.
A fábrica roda Linux; logo os 4 testes de invocação real falham com `ENotImplemented` da RTL.

## Checklist de critérios de aceitação

| # | Critério | Status | Nota |
|---|---------|--------|------|
| CA-1 | Declaração única `Invoke(AInstance, AName, AArgs, AResultType): TValue` na `interface`, sem `{$IFDEF}` em torno | ✅ | Linha 92-94 de `ModernSyntax.Invoker.pas` |
| CA-2 | `uses` da `interface` acrescenta `Rtti` | ✅ | Linha 53: `Rtti;` |
| CA-3 | Corpo dividido por `{$IFDEF FPC}` — FPC: MethodAddress + Rtti.Invoke | ✅ | Linhas 142-161 |
| CA-3b | Corpo Delphi: TRttiContext local com try/finally | ✅ | Linhas 163-185 |
| CA-4 | Três blocos do cabeçalho removidos, XMLDoc novo (D-13.8) | ✅ | Cabeçalho reescrito; XMLDoc linhas 63-91 |
| CA-5 | Portável `Invoke<TSignature>` não alterado | ✅ | Linhas 99-137 intocadas |
| CA-6 | Test Shared: `TDateAndTag`, funções `published` novas em TSubject, 7+ `Case_InvokeDynamic_*` | ✅ | 8 procedures novas declaradas e implementadas |
| CA-7 | FPC shell: 14 `published procedure InvokeDynamic_*` (7 orig + 7 novos) | ✅ | Contagem: 7 orig + 7 novos = 14 |
| CA-8 | Delphi shell: 14 `[Test] procedure InvokeDynamic_*` (7 orig + 7 novos) | ✅ | Contagem: 7 orig + 7 novos = 14 |
| CA-9 | Portável compila e passa 7/7 (regressão zero) | ✅ | Testes 1-7 todos OK |
| **CA-10** | **`PTestInvoker --all` passa integralmente no FPC 3.2.2 x86_64** | **❌** | **10/14 — 4 ENotImplemented (SysV AMD64)** |
| CA-11 | PR body com log FPC x86_64 e i386 | ⚠️ | Não verificável neste node |
| CA-12 | Sem warning novo além de `Unit "Rtti" is experimental` | ✅ | 0 warnings na compilação |

**Resultado: REJECTED** — AC-10 não satisfeito na fábrica `x86_64-linux`.

## Regras de negócio D-13.1..D-13.13

| Regra | Conformidade |
|-------|-------------|
| D-13.1 Assinatura pública idêntica | ✅ |
| D-13.2 Sem exceção "não suportado" como comportamento principal | ✅ (ENotImplemented vem da RTL, não da unit) |
| D-13.3 Alcance por compilador | ✅ |
| D-13.4 TRttiContext local try/finally | ✅ |
| D-13.5 TValueArray com Self primeiro | ✅ |
| D-13.6 ccReg | ✅ |
| D-13.7 Cabeçalho reescrito na mesma edição | ✅ |
| D-13.8 XMLDoc por compilador | ✅ |
| D-13.9 Guard AInstance=nil | ✅ |
| D-13.10 Guard LAddress=nil (mensagem reusada) | ✅ |
| D-13.11 Fixture com Integer+string e Double | ✅ |
| D-13.12 PR body com logs | ⚠️ Não verificável |
| D-13.13 Portável inalterado | ✅ |

## Edge cases verificados

- **Nil instance** — AC-9: guard `AInstance = nil` levanta antes de qualquer chamada RTTI ✅
- **Method not found** — guard `LAddress = nil` levanta com mensagem instrutiva ✅
- **Public sem {$M+}** — FPC levanta; assimetria Delphi documentada no Case_ ✅
- **Procedure void** — `AResultType = nil` aceito; retorno TValue.Empty ✅ (falha só em x86_64-linux por ENotImplemented)
- **String gerenciada** — retorno `string` via `v.AsString` ✅ (falha idem)
- **Regressão portável** — 7/7 do portável passam ✅

## Conclusão

A implementação está **tecnicamente correta** e conforme a D-13.1..D-13.13.
O AC-10 falha por limitação de ambiente (RTL do FPC 3.2.2 `x86_64-linux`
não implementa `SystemInvoke`), não por defeito de código.

O spec AC-10 tem dois problemas não corrigidos desde a 1ª rejeição:
1. Contagem "13/13" (errada — são 14).
2. Sem qualificação de OS — `x86_64` sem OS não distingue Linux de Windows.

**Esta é a 10ª rejeição consecutiva do node `test` com diagnóstico idêntico.**
Nenhuma alteração de código Pascal é indicada.
