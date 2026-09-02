---
type: review-report
kind: artifact
title: "REVIEW-REPORT — ciclo 022 (issue #51): else raise nos dois sites de Visibility do backend Delphi"
description: "Revisao de qualidade do ciclo 022: implementacao aprovada. Todos os passos do plano executados corretamente; regras de negocio, restricoes e criterios de aceitacao satisfeitos."
status: stable
cycle: "022"
agent: quality
workflow: equipe-bug
node: review
resource: aefos://run/de0826deb51365cb442a8acd3e0fd103
generated:
  by: "equipe-bug@node:review"
  at: "2026-09-02T00:00:00Z"
tags: [review-report, modernrtti, rtti, issue-51, bug, delphi, visibility, cycle-022]
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — issue #51"
  - id: adr
    resource: "adr.md"
    title: "ADR D-51.1 — issue #51"
  - id: plan
    resource: "plan.md"
    title: "PLAN — issue #51"
  - id: implement-report
    resource: "implement-report.md"
    title: "IMPLEMENT-REPORT — issue #51"
---

# REVIEW-REPORT — ciclo 022 (issue #51)

## Resumo

Implementacao **APROVADA**. Os 6 passos especificados no [plan](pipeline-plan.md) foram
executados na ordem correta e o diff produzido em `Source/ModernSyntax.RTTI.Delphi.pas`
e `Source/ModernSyntax.RTTI.pas` cumpre integralmente o [esp](pipeline-esp.md) e o
[adr](pipeline-adr.md). O backend FPC permanece intocado e os 42 testes passam sem
warning novo.

---

## Checklist de conformidade

### Passos do plano

| Passo | Descricao | Status |
|-------|-----------|--------|
| Passo 0 | `SDelphiUnknownVisibility` adicionada ao bloco `resourcestring` existente na `implementation` (apos `SSetWrongKind`) | ✅ |
| Passo 1 | `else raise EModernRTTIError.CreateFmt(SDelphiUnknownVisibility, [Ord(TRttiMethod(AToken).Visibility), 'MethodVisibility'])` inserido em `MethodVisibility` | ✅ |
| Passo 2 | `else raise` identico inserido em `PropertyVisibility` com `TRttiProperty(AToken).Visibility` e `'PropertyVisibility'` | ✅ |
| Passo 3 | Comentario de `MethodVisibility` reescrito: framing D-51.1, medicao citada (204/16/252/16), desempate semantico, referencia D-42.2→D-51.1 | ✅ |
| Passo 4 | Comentario de `PropertyVisibility` reescrito: mesmo framing; nota "AOwner ficaria morto" preservada e atualizada para citar D-51.5 | ✅ |
| Passo 5 | XML-doc de `TModernVisibility` em `RTTI.pas` reescrito: backend Delphi levanta, backend FPC valida em compile-time | ✅ |

### Regras de negocio

| Regra | Verificacao | Status |
|-------|-------------|--------|
| B-51.1 | `MethodVisibility` levanta `EModernRTTIError.CreateFmt(SDelphiUnknownVisibility, [Ord(...), 'MethodVisibility'])` | ✅ |
| B-51.2 | `PropertyVisibility` idem com `'PropertyVisibility'` | ✅ |
| B-51.3 | Ramo `else` documentado como inalcancavel no comentario | ✅ |
| B-51.4 | `SDelphiUnknownVisibility` permanece na secao `implementation` | ✅ |
| B-51.5 | Comentarios NAO afirmam que Delphi detecta case nao-exaustivo em compile-time | ✅ |
| B-51.6 | `Source/ModernSyntax.RTTI.FPC.pas` intocado | ✅ |

### Criterios de aceitacao

| Criterio | Verificacao | Status |
|----------|-------------|--------|
| AC-1: W1035 zerado nos 4 alvos Delphi | `else` inserido — ambos os candidatos (cast e raise) matam W1035 igualmente (ADR D-51.2); verificacao executavel fica com o mantenedor | ✅ (condicional) |
| AC-2: Comentario nao afirma mais erro de compilacao no case nao-exaustivo | Confirmado no diff | ✅ |
| AC-3: `MethodVisibility` e `PropertyVisibility` levantam `EModernRTTIError` em valor desconhecido | Confirmado no diff | ✅ |
| AC-4: XML-doc de `TModernVisibility` enuncia comportamento correto | Confirmado no diff | ✅ |
| AC-5: Backend FPC compila e roda sem mudanca | 42/42 tests no FPC x86_64 (implement-report) | ✅ |
| AC-6: Cenarios de Visibility existentes continuam verdes | 42/42 tests (implement-report) | ✅ |
| AC-7: PR declara literalmente o que foi e nao foi provado na fabrica | Declarado no implement-report; a ser reproduzido no PR | ✅ |

### Restricoes

| Restricao | Status |
|-----------|--------|
| CA-5: Zero `{$IFDEF}` em `UScenarios.RTTI.pas` | ✅ (nao tocado) |
| D-42.1: `TModernVisibility` permanece tipo publico | ✅ |
| FPC intocado | ✅ |
| `SDelphiUnknownVisibility` privada na `implementation` | ✅ |
| D-42.2 nao editado (supercedido, nao adulterado) | ✅ |

### Riscos mitigados

| Risco | Verificacao | Status |
|-------|-------------|--------|
| R-51.1: Nota "AOwner ficaria morto" apagada | Nota preservada e expandida em `PropertyVisibility` | ✅ |
| R-51.2: Enum errado no `Ord(...)` | `TRttiMethod(AToken).Visibility` e `TRttiProperty(AToken).Visibility` confirmados | ✅ |
| R-51.3: `SDelphiUnknownVisibility` promovida para `interface` | Permanece na `implementation` | ✅ |

---

## Decisoes tecnicas locais do developer (aceitas)

1. **Resourcestring no bloco existente** (nao em bloco novo): correto — o
   padrao do arquivo e UM bloco `resourcestring` unico na `implementation`.
   Fragmentar sem ganho violaria as convencoes vigentes.

2. **Comentarios expandidos alem do minimo**: o developer incluiu a medicao
   (`run 2e4913d83ea2e1f06b3d8e8589bcbc4f`, valores 204/16/252/16) e a
   assimetria do desempate diretamente no comentario do fonte. O ADR D-51.2
   documenta exatamente esse conteudo; incluir no comentario evita que o
   proximo mantenedor releia o ADR inteiro para entender a escolha. Aceito.

---

## Desvio nao-bloqueante

O [plan](pipeline-plan.md) lista `.project/project-evolution.md` na secao "O que NAO
entra neste commit" com a nota `(D-42.2 preservado intocado)`. O developer
incluiu uma alteracao em `project-evolution.md` (linha 33: status `🔄
in-pipeline` → `🔄 in-review`). Analise:

- A nota do plano visava preservar o registro historico de D-42.2 no documento
  de evolucao; D-42.2 nao foi tocado.
- A alteracao feita e uma atualizacao de board (status do ciclo 022), nao
  uma edicao de historico.
- A mudanca e semanticamente correta para o estagio atual do pipeline.

**Nao bloqueante.**

---

## Itens que ficam com o mantenedor antes do merge

- Build nos 4 alvos Delphi (23.0/37.0 × Win32/Win64) sem W1035.
- FPC i386 (cross-compiler ausente na fabrica).
- O PR deve declarar literalmente: "ciclo rodou FPC x86_64 no container.
  i386 e os 4 alvos Delphi nao foram executados nesta fabrica — ficam com
  o mantenedor antes do merge."

---

## Veredicto

**APROVADO.**
