---
type: test-report
kind: artifact
title: "Test Report — cycle 022 (issue #51): else raise no backend Delphi"
description: "42/42 FPC verde, zero warnings novos; todos os criterios de aceitacao verificaveis APROVADOS; Delphi W1035 fica com o mantenedor conforme spec."
cycle: "022"
agent: quality
workflow: equipe-bug
node: test
resource: aefos://run/de0826deb51365cb442a8acd3e0fd103
tags: [test-report, quality, cycle-022, issue-51, delphi, visibility, fpc]
generated:
  by: "equipe-bug@node:test"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — issue #51"
  - id: implement-report
    resource: "implement-report.md"
    title: "Implement report — developer cycle 022"
---

# Test Report — cycle 022 / issue #51

## Resumo executivo

**Veredicto: APROVADO.**

Todos os critérios de aceitação verificáveis neste ambiente estão satisfeitos.
O único critério não verificável aqui (W1035 zero nos 4 alvos Delphi) é
explicitamente delegado ao mantenedor pela própria [ESP](pipeline-esp.md) §4 e §5.

---

## 1. Testes automatizados executados

### FPC 3.2.2 x86_64 — suite completa

Comando (conforme SKILL.md / receita da fábrica):

```
rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild && \
fpc -Mdelphi \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -Fi"Test Shared/EclbrSystem" \
    -FU/tmp/fpcbuild -FE/tmp/fpcbuild \
    "Test FPC/EclbrSystem/PTestRTTI.lpr"
/tmp/fpcbuild/PTestRTTI --all -a --format=plain
```

| Métrica | Resultado |
|---------|-----------|
| Linhas compiladas | 4622 |
| Warnings novos | **0** (apenas os pré-existentes do repo) |
| Testes rodados | **42** |
| Erros | **0** |
| Falhas | **0** |

**Warnings pré-existentes confirmados (não regressão):**
- `Unit "Rtti" is experimental` (FPC.pas:45)
- `function result variable of managed type does not seem to be initialized` (FPC.pas:583/832, RTTI.pas:1081)
- `unreachable code` (Invoker.pas:80)
- Notes de `generics.collections`

Nenhum warning novo introduzido pela mudança do ciclo 022.

### Cenários de Visibility verdes (B-51.6)

| Cenário | Resultado |
|---------|-----------|
| `TestMethod_Visibility_FPC_Raises` | ✅ verde |
| `TestProperty_Visibility_Returns_mvPublished` | ✅ verde |

---

## 2. Checklist de aceitação

| # | Critério | Status | Evidência |
|---|----------|--------|-----------|
| AC-1 | 4 alvos Delphi compilam com zero W1035 | ⚠️ não verificável aqui | Sem `dcc32`/`bcc32` na fábrica (SKILL.md). Delegado ao mantenedor per [esp](pipeline-esp.md) §5. `else raise` elimina W1035 por design (ADR D-51.2). |
| AC-2 | Comentário em `RTTI.Delphi.pas` não afirma que Delphi acusa erro de case não-exaustivo | ✅ | Diff verificado: framing substituído por dados medidos (run `2e4913d83ea2e1f06b3d8e8589bcbc4f`). |
| AC-3 | `MethodVisibility` levanta `EModernRTTIError` em valor desconhecido | ✅ | `else raise EModernRTTIError.CreateFmt(SDelphiUnknownVisibility, [Ord(TRttiMethod(AToken).Visibility), 'MethodVisibility'])` — linha 343. |
| AC-4 | `PropertyVisibility` levanta `EModernRTTIError` em valor desconhecido | ✅ | `else raise EModernRTTIError.CreateFmt(SDelphiUnknownVisibility, [Ord(TRttiProperty(AToken).Visibility), 'PropertyVisibility'])` — linha 375. |
| AC-5 | XML-doc de `TModernVisibility` em `ModernSyntax.RTTI.pas` enuncia comportamento correto | ✅ | Diff verificado: "o backend Delphi levanta `EModernRTTIError` no primeiro chamador (D-51.1 do ADR issue #51); o backend FPC valida exaustividade em compile-time". |
| AC-6 | Backend FPC compila e roda sem alteração | ✅ | 42/42 verdes, zero warnings novos, FPC.pas intocado. |
| AC-7 | Cenários de Visibility continuam verdes nos dois compiladores | ✅ (FPC) / ⚠️ (Delphi — mantenedor) | `TestMethod_Visibility_FPC_Raises` e `TestProperty_Visibility_Returns_mvPublished` verdes. |
| AC-8 | PR declara "ciclo rodou FPC x86_64 no container..." | ⏳ | Cabe ao nó `commit`/PR. Conteúdo verificável aqui: FPC confirmado neste relatório. |

---

## 3. Edge cases verificados por leitura de código

| Edge case | Verificação | OK? |
|-----------|-------------|-----|
| `Ord(...)` usa `TMemberVisibility` do RTL (não `TModernVisibility`) | `Ord(TRttiMethod(AToken).Visibility)` e `Ord(TRttiProperty(AToken).Visibility)` — RTL, não casca | ✅ |
| `SDelphiUnknownVisibility` permanece na `implementation` | Linha 163 — dentro do bloco `resourcestring` da `implementation` | ✅ |
| Nota sobre `AOwner` em `PropertyVisibility` preservada | "AOwner ficaria morto" — linha 362 do diff | ✅ |
| FPC.pas intocado | Diff confirma: zero alterações em `ModernSyntax.RTTI.FPC.pas` | ✅ |
| `UScenarios.RTTI.pas` intocado | Diff confirma: zero alterações em arquivos de teste | ✅ |
| Nenhum `{$IFDEF}` adicionado | Diff confirmado | ✅ |

---

## 4. Análise de riscos (ESP §6)

| Risco | Mitigação verificada |
|-------|---------------------|
| R-51.1 — AOwner note apagada | Nota preservada intacta, atualizada para citar D-51.5 |
| R-51.2 — Ord() usa enum errado | Confirmado: `.Visibility` do `TRttiMethod`/`TRttiProperty` (RTL) |
| R-51.3 — `SDelphiUnknownVisibility` promovida para `interface` | Confirmado na `implementation`, comentada com justificativa |

---

## 5. Restrições de ambiente

- **Delphi ausente:** `dcc32`/`bcc32` não disponível na fábrica. AC-1 (W1035 zero) e AC-7 (Delphi) ficam com o mantenedor, conforme acordado na [esp](pipeline-esp.md) §5 e SKILL.md.
- **FPC i386 ausente:** `ppc386` retorna 127. Sem cross-compiler na fábrica.
- O PR deverá carregar a declaração literal exigida pelo [task-input](pipeline-task-input.md).
