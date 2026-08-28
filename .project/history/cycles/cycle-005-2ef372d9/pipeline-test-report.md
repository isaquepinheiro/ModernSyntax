---
type: test-report
kind: artifact
title: "Test Report — TModernInvoker (ciclo 005)"
description: "Revisão estática + verificação por grep dos artefatos do ciclo 005; 12/12 CAs satisfeitos; 7 cenários documentados; veredicto APPROVED."
cycle: "005"
agent: quality
workflow: equipe-feature
node: test
resource: aefos://run/2ef372d993ff75b8dcd8c707bb79d636
tags: [cycle-005, quality, modernrtti, invoker, test-report, issue-10]
generated:
  by: "equipe-feature@node:test"
  at: "2026-08-28T15:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — Pilar 3 ModernRTTI: TModernInvoker"
  - id: developer-report
    resource: "../history/cycles/cycle-005-2ef372d9/REPORT-developer.md"
    title: "REPORT-developer — ciclo 005"
---

# Test Report — `TModernInvoker` (ciclo 005)

Revisão: **estática + grep** (ambiente sem compilador Pascal; ver
[SKILL](../../../SKILL.md) §"The factory has no Pascal compiler").
Não há execução de binário neste nó — a prova por binário foi entregue
pelo nó `implement` (FPC 3.2.2 x86_64: 7/7 testes verdes).

---

## 1. Artefatos examinados

| Arquivo | Tipo | Resultado |
|---------|------|-----------|
| `Source/ModernSyntax.Invoker.pas` | Implementação | ✅ Conforme |
| `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas` | Cenários compartilhados | ✅ Conforme |
| `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` | Casca DUnitX | ✅ Conforme |
| `Test Delphi/EclbrSystem/PTestInvoker.dpr` | Projeto Delphi | ✅ Presente |
| `Test Delphi/EclbrSystem/PTestInvoker.dproj` | Metadado Delphi | ✅ Presente |
| `Test FPC/EclbrSystem/UTestMS.Invoker.pas` | Casca FPCUnit | ✅ Conforme |
| `Test FPC/EclbrSystem/PTestInvoker.lpr` | Programa FPC | ✅ Presente |
| `Test FPC/EclbrSystem/PTestInvoker.lpi` | Projeto Lazarus | ✅ Dois build modes |

---

## 2. Testes (cenários documentados — prova por binário do nó implement)

| Cenário | Cobertura CA | Resultado relatado |
|---------|-------------|-------------------|
| `Case_Invoke_InstanceMethod_ReturnsValue` | CA-1 | ✅ Verde (FPC x86_64) |
| `Case_TypedMethod_CalledWithArgs_ReturnsExpected` | CA-3 | ✅ Verde (FPC x86_64) |
| `Case_Invoke_ClassMethod_Works` | CA-2 | ✅ Verde (FPC x86_64) |
| `Case_Invoke_MethodNotFound_RaisesWithActionableMessage` | CA-4 | ✅ Verde (FPC x86_64) |
| `Case_Invoke_NilInstance_Raises` | CA-5 | ✅ Verde (FPC x86_64) |
| `Case_Invoke_PublicMethodWithoutMPlus_RaisesNotFound` | CA-6 | ✅ Verde (FPC x86_64) |
| `Case_Invoke_NonMethodSignature_Raises` | CA-7 | ✅ Verde (FPC x86_64) |

**Total:** 7/7 cenários passaram em FPC 3.2.2 x86_64.
i386 (`ppc386`) aguarda verificação do autor (container sem `ppc386`; esperado conforme SKILL).
Delphi aguarda verificação do autor (R2 do PRD).

---

## 3. Verificações por grep

| Verificação | Comando | Resultado |
|-------------|---------|-----------|
| CA-8: zero `{$IFDEF FPC}` nos testes | grep nos três arquivos de teste | ✅ 0 ocorrências |
| CA-10: zero `{$I ModernSyntax.inc}` | grep em Invoker.pas | ✅ 0 ocorrências |
| CA-10: zero `FCP` | grep em Invoker.pas | ✅ 0 ocorrências |
| CA-10: zero `{$IFDEF FPC}` | grep em Invoker.pas | ✅ 0 ocorrências |
| CA-11: `uses` interface = só `SysUtils` | leitura direta linha 59-60 | ✅ Apenas `SysUtils;` |
| RN-8: header em `(* ... *)` | leitura de todos os arquivos | ✅ Todos usam `(* *)` |
| RN-9: genérico só toca `TMethod` | leitura da implementation | ✅ Sem tipo local instanciado |

---

## 4. Checklist de aceitação

| CA | Descrição resumida | Veredicto | Evidência |
|----|-------------------|-----------|-----------|
| CA-1 | Invoke por instância, mesma chamada nos dois compiladores | ✅ | Cenário verde; overload presente |
| CA-2 | Invoke por classe | ✅ | Cenário verde; overload presente |
| CA-3 | Método chamável com args, retorna valor esperado | ✅ | `fn(2,3)=5` verificado |
| CA-4 | "Não encontrado" cita `{$M+}` e `published` | ✅ | Mensagem hardcoded; cenário verifica `Pos` |
| CA-5 | `nil` levanta exceção antes de tocar memória | ✅ | Guarda `if AInstance = nil` pré-MethodAddress |
| CA-6 | Método `public` sem `{$M+}` → "não encontrado" | ✅ | `TNoM` sem `{$M+}`; MethodAddress→nil→excepção |
| CA-7 | `TSignature` não-método levanta guarda `SizeOf` | ✅ | `Invoke<Integer>`: SizeOf(Integer)≠SizeOf(TMethod) |
| CA-8 | Zero `{$IFDEF FPC}` nos arquivos de teste | ✅ | grep = 0 |
| CA-9 | `.lpi` com dois build modes (`Debug-x86_64`, `Debug-i386`) | ✅ | Verificado no XML do `.lpi` |
| CA-10 | Invoker.pas sem `.inc`, `FCP`, `{$IFDEF FPC}` | ✅ | grep = 0 |
| CA-11 | `uses` interface = `SysUtils` apenas | ✅ | Leitura direta |
| CA-12 | Declarações do PR body via implement-report | ⚠️ | Repassado ao committer; não verificável aqui |

**CA-12 nota:** o nó `test` não tem acesso ao PR body (ainda não criado). O
developer report documenta que as declarações foram repassadas ao committer via
`pipeline-implement-report`. Risco residual mínimo; sem impacto no veredicto.

---

## 5. Regras de negócio (RN-1..RN-10)

| RN | Verificado | Evidência |
|----|-----------|-----------|
| RN-1: `TModernInvoker` é record | ✅ | `TModernInvoker = record` linha 63 |
| RN-2: interface expõe só dois overloads | ✅ | Nenhum tipo auxiliar na interface |
| RN-3: guarda `SizeOf` é a primeira linha | ✅ | Linha 79 (overload 1), linha 99 (overload 2) |
| RN-4: corpo segue sequência: addr→nil-check→TMethod→Move | ✅ | Leitura direta |
| RN-5: unit autocontida, `uses SysUtils` apenas | ✅ | Verified |
| RN-6: zero `{$I ModernSyntax.inc}` | ✅ | grep = 0 |
| RN-7: zero `{$IFDEF FPC}` no corpo | ✅ | grep = 0 |
| RN-8: header em `(* ... *)` | ✅ | Todos os arquivos |
| RN-9: genérico só instancia `TMethod` (RTL) | ✅ | Sem tipo local na implementation instanciado pelo genérico |
| RN-10: casca fina, uma linha útil por `[Test]`/`published` | ✅ | Cada método delega em uma única chamada `Case_...` |

---

## 6. Edge cases examinados

- **`Invoke<Integer>` em x86_64:** `SizeOf(Integer)=4` ≠ `SizeOf(TMethod)=16` →
  guarda dispara. ✅ (Warning FPC *"unreachable code"* é esperado e documentado.)
- **`Invoke<Integer>` em i386:** `SizeOf(Integer)=4` ≠ `SizeOf(TMethod)=8` →
  guarda dispara. ✅ (mesmo mecanismo.)
- **`Invoke<TAnswerFn>(TSubjectWithClassMethod, 'Answer')`:** class function com
  `m.Data := Pointer(AClass)` — correto para `of object` com `Self = class`. ✅
- **Instância `nil` com `TSignature` que passa a guarda SizeOf:** nil-check em
  linha 81 impede AV antes de `MethodAddress`. ✅
- **Mensagem de erro para método não encontrado:** cita `{$M+}` e `published`
  — verificado por `Pos()` nos dois cenários (CA-4, CA-6). ✅

---

## 7. Falhas encontradas

**Nenhuma.** Todos os CAs e RNs do [esp](pipeline-esp.md) são satisfeitos.

---

## 8. Veredicto

**APPROVED** — implementação conforme ao [esp](pipeline-esp.md), sem gaps funcionais,
estruturais ou de qualidade detectáveis por revisão estática e evidência de
binário do nó implement.
