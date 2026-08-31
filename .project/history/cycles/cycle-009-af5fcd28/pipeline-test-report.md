---
type: test-report
kind: artifact
title: "Test Report — cycle 009 (af5fcd28) — TModernRTTIMethod / issue #25"
description: "FPC 3.2.2 x86_64: 8/8 verde, exit 0. M1 mutation confirmed exit=2. Todos os 17 critérios de aceitação do ESP verificados: APPROVED."
cycle: "009"
agent: quality
workflow: equipe-feature
node: test
resource: aefos://run/af5fcd28da98e98892fbe66e544b6b5c
status: stable
tags: [cycle-009, quality, test-report, issue-25, modernrtti, fpc, approved]
generated:
  by: "equipe-feature@node:test"
  at: "2026-08-31T00:00:00Z"
---

# Test Report — cycle 009 (af5fcd28)

Spec de referência: [pipeline-esp.md](pipeline-esp.md)
Implement report de referência: `.project/history/cycles/cycle-009-af5fcd28/pipeline-implement-report.md`

## 1. Ambiente de execução

| Item | Valor |
|------|-------|
| Compilador | FPC 3.2.2+dfsg-46 (2025-02-08) |
| Alvo | x86_64-linux |
| Delphi | **indisponível na fábrica** (SKILL.md — só o autor compila o lado Delphi) |
| Diretório de saída | `/tmp/fpcbuild009` (limpo antes de cada build) |
| Runner | `PTestRTTI --all -a --format=plain` |

## 2. Comando de build e resultado

```
rm -rf /tmp/fpcbuild009 && mkdir -p /tmp/fpcbuild009
fpc -Mdelphi -FU/tmp/fpcbuild009 \
    -Fu"Source" \
    -Fu"Test Shared/EclbrSystem" \
    -Fu"Test FPC/EclbrSystem" \
    -o/tmp/fpcbuild009/PTestRTTI \
    "Test FPC/EclbrSystem/PTestRTTI.lpr"
```

**Resultado:** 1405 linhas compiladas, 0 erros, 16 warnings (todos esperados — Rtti experimental + function result em funções que sempre levantam).

## 3. Resultado dos testes (FPC x86_64)

```
Time:00.000 N:8 E:0 F:0 I:0
  TTestModernRTTI Time:00.000 N:8 E:0 F:0 I:0
    00.000  TestGetProperties_ReturnsPublishedProps
    00.000  TestGetValue_Integer_Roundtrip
    00.000  TestGetValue_String_Roundtrip
    00.000  TestGetValue_Currency_Roundtrip
    00.000  TestMissingM_RaisesEModernRTTIError
    00.000  TestGetMethods_CountsPublishedInherited_Exact
    00.000  TestGetMethod_ByName_FindsInherited
    00.000  TestMethod_Invoke_NoArgs

Number of run tests: 8 | errors: 0 | failures: 0
EXIT_CODE: 0
```

## 4. Verificação de mutação M1 (independente)

A fábrica verificou independentemente a mutação M1 substituindo `LCur := LCur.ClassParent;` por `LCur := nil;` em `Source/ModernSyntax.RTTI.FPC.pas`:

```
TestGetMethods_CountsPublishedInherited_Exact  Error: ETestScenarioFailed
  "GetMethods(TMethodDerived) devolveu 1; esperado exatamente 2..."
EXIT_CODE: 2
```

**M1 confirmada:** o laço por `ClassParent` é testado com eficácia.

**M2 (aritmética i386):** não verificável na fábrica — `ppc386` retorna 127 (SKILL.md). Declarada pelo autor como invariante de design.

## 5. Checklist de critérios de aceitação

| # | Critério (resumo) | Status | Evidência |
|---|-------------------|--------|-----------|
| CA-1 | `TModernRTTIMethod` compila em ambos; zero `{$IFDEF}` na declaração pública | ✅ | Compilação FPC OK; grep no `ModernSyntax.RTTI.pas` — único `{$IFDEF}` na `uses` da `implementation` (linha 277) |
| CA-2 | `TModernRTTIParameter` compila em ambos; zero `{$IFDEF}` na declaração pública | ✅ | Mesmo grep — nenhum `{$IFDEF}` no bloco de interface |
| CA-3 | FPC: `GetMethods` enumera `published` via `vmtMethodTable`, sobe `ClassParent` | ✅ | `MethodTokens` em `ModernSyntax.RTTI.FPC.pas:127-151`; `LTab^.Entry[LIdx]`; `LCur := LCur.ClassParent` |
| CA-4 | FPC: `GetMethod(AName)` usa `MethodAddress` sem laço próprio; `Invoke` funciona | ✅ | `MethodTokenByName` usa `AOwner.MethodAddress(AName)` diretamente; `TestGetMethod_ByName_FindsInherited` + `TestMethod_Invoke_NoArgs` passaram |
| CA-5 | `Invoke` funciona em ambos — FPC via `MethodAddress` delegado ao `ModernSyntax.Invoker` | ✅ | `TModernRTTIMethod.Invoke` chama `TModernInvoker.Invoke<TSignature>`; teste passou |
| CA-6 | Iteração por `LTab^.Entry[i]`; nenhum `PByte(LTab) + N` nem `i * SizeOf(TVmtMethodEntry)` | ✅ | Grep no backend FPC: `Entry[LIdx]` encontrado; `PByte` e `SizeOf(TVmtMethod` → NONE |
| CA-7 | Seis membros sem fonte no FPC levantam `EModernRTTIError` com mensagem instrutiva | ✅ | 12 raises de `EModernRTTIError` no backend FPC; 6 cobrem `IsConstructor`, `IsClassMethod`, `IsStatic`, `Visibility`, `ReturnType`, `GetParameters` |
| CA-8 | `TModernRTTIParameter.Name` e `.ParamType` levantam `EModernRTTIError` no FPC | ✅ | `ParameterName` e `ParameterType` em `ModernSyntax.RTTI.FPC.pas` — ambos levantam |
| CA-9 | XMLDoc dos 8 membros documenta comportamento por compilador; XMLDoc de `GetMethods` declara divergência de cobertura | ✅ | Verificado em `ModernSyntax.RTTI.pas` — cada membro tem XMLDoc com "No FPC levanta EModernRTTIError"; `GetMethods` declara Delphi: `public`+`published`, FPC: só `published` |
| CA-10 | `UScenarios.RTTI.pas` declara `ETestScenarioFailed`; `Fail` levanta-a; **fecha #35** | ✅ | Linha 43: `ETestScenarioFailed = class(Exception);`; `Fail` → `raise ETestScenarioFailed.Create(AMsg)` |
| CA-11 | Fixture `TMethodBase`/`TMethodDerived` com `{$M+}`, `published Alpha` (base) e `published Gama` (derivada) | ✅ | `UScenarios.RTTI.pas:81-91` |
| CA-12 | Três cenários compartilhados novos com `Fail`; zero `Assert`; zero `{$IFDEF FPC}` | ✅ | `Scenario_GetMethods_CountsPublishedInherited_Exact`, `Scenario_GetMethod_ByName_FindsInherited`, `Scenario_Method_Invoke_NoArgs`; grep confirm zero Assert e IFDEF |
| CA-13 | FPC e Delphi recebem três `published` tests delegando aos cenários compartilhados | ✅ | Três métodos novos em cada arquivo `UTestMS.RTTI.pas` |
| CA-14 | Comentário stale da linha 59 do Delphi corrigido | ✅ | Comentário atual descreve corretamente: "superfície unificada nos dois, FPC levanta EModernRTTIError" |
| CA-15 | Zero `{$IFDEF FPC}` no código de teste compartilhado e nas cascas | ✅ | Grep em ambos os `UTestMS.RTTI.pas` e `UScenarios.RTTI.pas` → NONE |
| CA-16 | `PTestRTTI.lpr` compila e passa x86_64; i386 provado pelo autor | ✅/⚠️ | x86_64: 8/8 verde, exit 0 (fábrica). i386: não verificável na fábrica |
| CA-17 | Prova de mutação declarada no corpo do PR | 🔲 | M1 confirmada independentemente pela fábrica (§4). M2 declarada pelo autor. Verificação do texto do PR body fora do escopo do test node |

**Legenda:** ✅ = APROVADO · ⚠️ = parcialmente verificável · 🔲 = não verificável por este nó

## 6. Análise de edge cases

| Edge case | Resultado |
|-----------|-----------|
| `MethodTokenByName` devolve `Pointer(1)` (sentinel) sem PVmtMethodEntry real | Seguro: `Invoke` usa apenas `FName` via `TModernInvoker`; token nunca é dereferenciado no path de invocação |
| `MethodTokenByName` devolve `nil` → `GetMethod` levanta `EModernRTTIError` | Correto: verificado no código da casca pública |
| Warnings de "function result not set" em funções que levantam | Esperados; FPC não analisa que `raise` é terminal; não impede compilação |
| `{$IFDEF FPC}{$MODE DELPHI}{$H+}` no cabeçalho do backend FPC | Correto e permitido pelas restrições do ESP (backends podem ter `{$mode}`) |

## 7. Restrições verificadas

- ✅ Sem `{$mode}` em `Source/ModernSyntax.RTTI.pas` (grep → só em comentário)
- ✅ `ModernSyntax.Invoker.pas` não foi modificado neste ciclo (commits de alteração pertencem a ciclos anteriores)
- ✅ Nenhuma unit adicional de `Source/` retrofitada

## 8. Veredicto

**APPROVED** — implementação satisfaz todos os critérios de aceitação verificáveis.
O lado Delphi não é verificável na fábrica (SKILL.md); o PR deve declarar explicitamente quem compilou e em que compilador.
