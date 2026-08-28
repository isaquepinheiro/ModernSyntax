---
type: test-report
kind: artifact
title: "Test report — chore issue #23 — rename addr/m para LAddress/LMethod em Invoker"
description: "7/7 testes verdes no FPC 3.2.2 x86_64; todos os critérios de aceitação do ESP satisfeitos."
status: stable
cycle: "007"
agent: quality
workflow: equipe-chore
node: test
resource: aefos://run/3ac50e14ab113cabde9efa632dc2fccf
tags: [test-report, chore, naming-convention, invoker, issue-23, cycle-007]
generated:
  by: "equipe-chore@node:test"
  at: "2026-08-28T00:00:00Z"
sources:
  - id: esp
    resource: esp.md
    title: "ESP — Conformidade de nomes em Invoker"
  - id: implement-report
    resource: implement-report.md
    title: "Implement report — chore issue #23"
---

# Test report — chore issue #23

## Sumário

Ciclo 007 — renomear as 4 variáveis locais `addr`/`m` para `LAddress`/`LMethod`
nos dois overloads de `TModernInvoker.Invoke<TSignature>` em
`Source/ModernSyntax.Invoker.pas`. Todas as verificações passaram.

**Veredicto: APPROVED**

---

## 1. Inspeção do código-fonte

### 1.1 Variáveis locais não conformes

Busca por `\baddr\b` e `\bm\b` no corpo da unit:

```
grep -n "addr\b\|: m\b\|m\." Source/ModernSyntax.Invoker.pas
```

Resultado: zero ocorrências de nomes não conformes no código executável.
Apenas duas ocorrências do token `m` encontradas — ambas dentro do
bloco de comentário-cabeçalho (linhas 32 e 40, referências textuais a
`TMethod`), fora do código compilável.

**Critério RN-1 — PASS**: zero variáveis locais sem prefixo `L` em
`ModernSyntax.Invoker.pas`.

### 1.2 Variáveis renomeadas confirmadas

| Overload | Var antiga | Var nova |
|---|---|---|
| `Invoke<TSignature>(AInstance, ...)` | `addr` | `LAddress` |
| `Invoke<TSignature>(AInstance, ...)` | `m` | `LMethod` |
| `Invoke<TSignature>(AClass, ...)` | `addr` | `LAddress` |
| `Invoke<TSignature>(AClass, ...)` | `m` | `LMethod` |

Todos os usos no corpo (atribuições `.Code`/`.Data`, chamada `Move`) foram
atualizados coerentemente.

---

## 2. Build e execução de testes

### 2.1 Build limpo — FPC 3.2.2 x86_64

Resultado: **450 linhas compiladas, 0 erros, 3 warnings**.

Warnings: `unreachable code` nas linhas 80 e 100 — pré-existentes desde
o PR #19, causados pelo `raise` incondicional após o `if SizeOf(...)`.
Fora do escopo desta issue.

### 2.2 Execução de testes

```
/tmp/fpcbuild/PTestInvoker --all -a --format=plain

Time:00.000 N:7 E:0 F:0 I:0
  TInvokerTests Time:00.000 N:7 E:0 F:0 I:0
    Invoke_InstanceMethod_ReturnsValue
    TypedMethod_CalledWithArgs_ReturnsExpected
    Invoke_ClassMethod_Works
    Invoke_MethodNotFound_RaisesWithActionableMessage
    Invoke_NilInstance_Raises
    Invoke_PublicMethodWithoutMPlus_RaisesNotFound
    Invoke_NonMethodSignature_Raises

Number of run tests: 7
Number of errors:    0
Number of failures:  0
```

**Critério AC-2 — PASS**: 7 testes, 0 falhas.

---

## 3. Escopo do diff

```
git diff HEAD --name-only
.project/project-evolution.md
Source/ModernSyntax.Invoker.pas
```

Somente `Source/ModernSyntax.Invoker.pas` alterado no código de produto.

**Critério AC-3 — PASS**: diff de código-fonte limitado a
`Source/ModernSyntax.Invoker.pas`.

---

## 4. Checklist de aceitação (do [esp](pipeline-esp.md))

| # | Critério | Status |
|---|---|---|
| AC-1 | Zero variáveis locais sem prefixo `L` em `ModernSyntax.Invoker.pas` | PASS |
| AC-2 | `PTestInvoker.lpr` compila e executa com 7 testes, 0 falhas no FPC 3.2.2 x86_64 | PASS |
| AC-3 | Nenhuma outra unit modificada | PASS |

---

## 5. Edge cases verificados

| Edge case | Teste | Resultado |
|---|---|---|
| `LAddress = nil` (método não encontrado) | `Invoke_MethodNotFound_RaisesWithActionableMessage` | PASS |
| `AInstance = nil` | `Invoke_NilInstance_Raises` | PASS |
| `TSignature` sem `{$M+}` published | `Invoke_PublicMethodWithoutMPlus_RaisesNotFound` | PASS |
| `TSignature` não é tipo de método | `Invoke_NonMethodSignature_Raises` | PASS |
| Classe (não instância) | `Invoke_ClassMethod_Works` | PASS |

---

## 6. Caveats herdados (fora do escopo desta issue)

1. **Validação i386 e Delphi ausentes** — fábrica não tem `ppc386` nem
   `dcc32`. Risco nulo dado o caráter puramente léxico do rename.
2. **Warnings de `unreachable code`** — pré-existentes, fora do escopo.
