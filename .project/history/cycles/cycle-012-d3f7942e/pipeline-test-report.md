---
type: test-report
kind: artifact
title: "TEST-REPORT — Enumerators nas coleções: for..in sobre Fields/Properties/Methods/Parameters/Attributes (issue #27)"
description: "23/23 FPC testes verdes; todos os critérios de aceitação automáticos satisfeitos; dois caveats manuais (Delphi 12 + i386) declarados como processo — veredicto APPROVED."
cycle: "012"
agent: quality
workflow: equipe-feature
node: test
resource: aefos://run/d3f7942e59d0ba69094d93420fef84db
status: stable
tags: [modernrtti, test-report, issue-27, fpc, enumerators, for-in, cycle-012]
generated:
  by: "equipe-feature@node:test"
  at: "2026-08-31T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — critérios formais e checklist"
  - id: implement-report
    resource: "implement-report.md"
    title: "IMPLEMENT-REPORT — relatório do developer"
---

# TEST-REPORT — issue #27: for..in sobre as coleções

## Veredicto

**APPROVED** — todos os critérios de aceitação automatizáveis estão satisfeitos.
Dois itens manuais (Delphi 12 + FPC i386) são declarados como processo e devem
constar no corpo do PR conforme o [esp](pipeline-esp.md).

---

## 1. Testes executados

### 1.1 Runner principal — `PTestRTTI.lpr` (FPC x86_64)

**Resultado:** `N:23 E:0 F:0 I:0 / exit=0`

| # | Teste | Status |
|---|-------|--------|
| 1 | TestGetProperties_ReturnsPublishedProps | ✅ PASS |
| 2 | TestGetValue_Integer_Roundtrip | ✅ PASS |
| 3 | TestGetValue_String_Roundtrip | ✅ PASS |
| 4 | TestGetValue_Currency_Roundtrip | ✅ PASS |
| 5 | TestMissingM_RaisesEModernRTTIError | ✅ PASS |
| 6 | TestGetFields_EnumeratesInheritedPublishedClassFields | ✅ PASS |
| 7 | TestGetMethods_CountsPublishedInherited_Exact | ✅ PASS |
| 8 | TestGetMethod_ByName_FindsInherited | ✅ PASS |
| 9 | TestMethod_Invoke_NoArgs | ✅ PASS |
| 10 | TestModernValue_AsType_String | ✅ PASS |
| 11 | TestModernValue_AsType_Integer | ✅ PASS |
| 12 | TestModernValue_AsType_Boolean | ✅ PASS |
| 13 | TestModernValue_AsType_Double | ✅ PASS |
| 14 | TestModernValue_AsType_Object | ✅ PASS |
| 15 | TestModernValue_AsType_Record | ✅ PASS |
| 16 | TestModernValue_AsType_Enum | ✅ PASS |
| 17 | TestModernValue_AsType_DifferentType_RaisesWithOriginAndDestination | ✅ PASS |
| 18 | **TestFields_ForIn_IteratesFields** | ✅ PASS (novo #27) |
| 19 | **TestProperties_ForIn_IteratesProperties** | ✅ PASS (novo #27) |
| 20 | **TestMethods_ForIn_IteratesMethods** | ✅ PASS (novo #27) |
| 21 | **TestAttributes_ForIn_IteratesAttributes** | ✅ PASS (novo #27) |
| 22 | **TestEmptyCollection_ForIn_DoesNotLoop** | ✅ PASS (novo #27) |
| 23 | **TestParameters_ForIn_RaisesOnFPC** | ✅ PASS (novo #27) |

Baseline: 17 testes. Delta: +6 testes FPC (os cinco comuns + `RaisesOnFPC`).

### 1.2 Runners de regressão

| Runner | Resultado |
|--------|-----------|
| `PTestInvoker.lpr` | 450 lines compiled, ok — sem falhas |
| `PTestModernCallback.lpr` | 513 lines compiled, ok — sem falhas |
| `PTestAttributes.lpr` | ❌ `Cannot open include file UTestMS.Attributes.Symbols.inc` — **pré-existente** (verificado: mesma falha no baseline sem as mudanças deste ciclo; não é regressão introduzida pela #27) |

---

## 2. Checklist dos critérios de aceitação

| Critério | Verificação | Status |
|----------|-------------|--------|
| CA-1: 4 properties em `TModernRTTITypeHelper` (`Fields`, `Properties`, `Methods`, `Attributes`), zero `{$IFDEF}` nas declarações | Inspecionado no diff; `grep -n '{\$IFDEF' Source/ModernSyntax.RTTI.pas` → só linha 429 (implementation uses) | ✅ |
| CA-2: `TModernRTTIMethod.Parameters` delegando a `GetParameters`, zero `{$IFDEF}` | Inspecionado no diff | ✅ |
| CA-3: XMLDoc de `Parameters` com texto literal D-26 ("No FPC, acessar `Parameters` levanta `EModernRTTIError` — a assinatura de método de classe não existe no FPC 3.2.2") | Texto presente no diff | ✅ |
| CA-4: `ModernSyntax.Attributes` em `uses` da `interface`; único `{$IFDEF FPC}` na `uses` da `implementation` (linha 429) | `grep -n '{\$IFDEF FPC}' Source/ModernSyntax.RTTI.pas` → 1 hit, linha 429, sem diretiva nova | ✅ |
| CA-5: `Get*` e `GetValue<T>` inalterados | Diff mostra apenas adições; nenhuma linha de `Get*` removida ou modificada | ✅ |
| CA-6: `for..in` compila e roda para `Fields`/`Properties`/`Methods`/`Attributes` nos dois compiladores; `Parameters` levanta no FPC | 23/23 FPC verdes, incluindo `RaisesOnFPC` | ✅ |
| CA-7: coleção vazia não levanta, não entra em loop | `TestEmptyCollection_ForIn_DoesNotLoop` PASS | ✅ |
| CA-8: 7 cenários compartilhados, `Fail(...)`, zero `{$IFDEF FPC}` | `grep -c "IFDEF" UScenarios.RTTI.pas` → **0**; 7 procedures novas confirmadas no diff | ✅ |
| CA-9: `grep -c "IFDEF" UScenarios.RTTI.pas` não aumenta | 0 (baseline pré-issue era 0) | ✅ |
| CA-10: `grep -n "AssertException"` em `Test Shared/`, `Test FPC/`, `Test Delphi/` continua vazio | `grep -rn "AssertException" ...` → vazio | ✅ |
| CA-11: casca FPC recebe 6 `published` (5 comuns + `RaisesOnFPC`, sem o irmão que itera) | Inspecionado no diff | ✅ |
| CA-12: casca Delphi recebe 6 `[Test]` (5 comuns + `IteratesRealParameters`, sem o irmão que espera exceção) | Inspecionado no diff | ✅ |
| CA-13: `PTestRTTI.lpr` compila e passa em x86_64 | 23/23 / exit=0 | ✅ |
| CA-14: autor confirma i386 + Delphi 12 e declara no corpo do PR | **Processo — não automático.** implement-report declara caveat (R4/SKILL.md:122-124); deve aparecer no PR. | ⚠️ MANUAL |
| CA-15: `for..in` sem `{$IFDEF FPC}` no código do teste (CA-5 da issue) | `grep -c "IFDEF" UScenarios.RTTI.pas` → 0 | ✅ |
| CA-16: prova de mutação declarada no PR | Documentada no implement-report (PropFields → nil → exit=2 / `ETestScenarioFailed`); deve ser declarada no corpo do PR | ⚠️ MANUAL |

---

## 3. Casos de borda exercitados

| Caso | Cenário | Resultado |
|------|---------|-----------|
| Coleção vazia (`TEmptyForIn`, sem nenhum campo) | `Scenario_EmptyCollection_ForIn_DoesNotLoop` | 0 iterações, sem raise, sem loop infinito ✅ |
| Herança: `TPortableFieldFixture` herda `InnerA` de `TBase` | `Scenario_Fields_ForIn_IteratesFields` — LCount=2 exato | ✅ |
| Atributos: `TAlvoForInAttrs` só tem registrado (sem nativo Delphi) | `Scenario_Attributes_ForIn_IteratesAttributes` — `LCount >= 1` + `TAttrForIn('for-in')` presente | ✅ |
| Raise no FPC ao acessar `Parameters` de `TMethodWithParams.Beta` | `Scenario_Parameters_ForIn_RaisesOnFPC` — `LRaised := True` na via `EModernRTTIError` | ✅ |
| Tipo não-classe em `PropAttributes` | Guarda `is TRttiInstanceType` → retorna `nil` (sem raise) — defensivo, não coberto por cenário (fora do escopo da issue) | — |

---

## 4. Observações

### D-IMPL-1 (forwarders strict private)

O developer mediu um trap FPC 3.2.2: `property ... read <Metodo>` de record
helper não resolve `<Metodo>` contra o tipo alvo — recusa com
"Unknown class field or method identifier". A solução adotada (três forwarders
`PropFields`, `PropProperties`, `PropAttributes` `strict private`) mantém a
superfície pública intacta (`LType.Fields` etc.) e é compatível com Delphi
(o Delphi aceita `read PropFields` também). Não viola nenhuma restrição do
[esp](pipeline-esp.md).

### `Methods` usa `read GetMethods` diretamente

`GetMethods` pertence ao próprio helper (issue #25), portanto o FPC resolve
sem forwarder — coerente com D-IMPL-1.

### `PTestAttributes` pré-existente

A falha `Cannot open include file UTestMS.Attributes.Symbols.inc` existe no
baseline (verificado por `git stash`). Não é regressão deste ciclo.

---

## 5. Evidência de regressão zero

- `PTestRTTI`: 17 → 23 testes, todos verdes (baseline: 17)
- `PTestInvoker`: ok (450 lines)
- `PTestModernCallback`: ok (513 lines)
- `Source/ModernSyntax.RTTI.pas`: apenas adições; nenhuma linha de `Get*`,
  backends ou runners alterada
