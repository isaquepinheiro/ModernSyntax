---
type: test-report
kind: artifact
title: "TEST-REPORT — TModernValue.AsType<T> (issue #26, cycle 011)"
description: "17/17 FPC x86_64 testes verdes; todos os CAs verificaveis aprovados; dois itens abertos por limitacao de ambiente (Delphi/i386)."
status: stable
cycle: "011"
agent: quality
workflow: equipe-feature
node: test
resource: aefos://run/38e3bcee8cdc184a2977006358812748
tags: [modernrtti, test-report, issue-26, fpc, tvalue, astype]
generated:
  by: "equipe-feature@node:test"
  at: "2026-08-31T00:00:00Z"
---

# TEST-REPORT — issue #26 (TModernValue.AsType<T>)

## Resumo

Implementação aprovada. **17/17 testes FPC x86_64 verdes**, exit=0.
Todos os critérios de aceitação verificáveis pela fábrica estão satisfeitos.
Dois itens não verificáveis na fábrica (Delphi build e i386) foram corretamente
sinalizados pelo desenvolvedor e são limitações de ambiente declaradas no ESP.

## Testes executados

### Comando

```
rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild
fpc -Mdelphi -Fu"Source" -Fu"Test Shared/EclbrSystem" \
    -Fu"Test FPC/EclbrSystem" \
    -FU/tmp/fpcbuild -FE/tmp/fpcbuild \
    "Test FPC/EclbrSystem/PTestRTTI.lpr"
/tmp/fpcbuild/PTestRTTI --all -a --format=plain
```

### Resultado

```
N:17  E:0  F:0  I:0  EXIT:0
  TestGetProperties_ReturnsPublishedProps        ✓
  TestGetValue_Integer_Roundtrip                 ✓  (regressão GetValue<T> — R2)
  TestGetValue_String_Roundtrip                  ✓  (regressão GetValue<T> — R2)
  TestGetValue_Currency_Roundtrip                ✓  (regressão GetValue<T> — R2)
  TestMissingM_RaisesEModernRTTIError            ✓
  TestGetFields_EnumeratesInheritedPublishedClassFields ✓
  TestGetMethods_CountsPublishedInherited_Exact  ✓
  TestGetMethod_ByName_FindsInherited            ✓
  TestMethod_Invoke_NoArgs                       ✓
  TestModernValue_AsType_String                  ✓
  TestModernValue_AsType_Integer                 ✓
  TestModernValue_AsType_Boolean                 ✓
  TestModernValue_AsType_Double                  ✓
  TestModernValue_AsType_Object                  ✓
  TestModernValue_AsType_Record                  ✓
  TestModernValue_AsType_Enum                    ✓
  TestModernValue_AsType_DifferentType_RaisesWithOriginAndDestination ✓
```

### Regressão de outros runners FPC

| Runner | Resultado |
|--------|-----------|
| `PTestInvoker.lpr` | 450 lines compiled, ok |
| `PTestModernCallback.lpr` | 513 lines compiled, ok |
| `PTestAttributes.lpr` | falha pré-existente (include file ausente) — **não introduzida por esta issue** |

## Checklist de critérios de aceitação

| # | Critério | Status |
|---|----------|--------|
| CA-1 | `TModernValue` declarado na `interface` com superfície mínima, zero `{$IFDEF}` | ✅ |
| CA-2 | Corpo de `AsType<T>` é uma linha, zero `{$IFDEF}` | ✅ |
| CA-3 | XMLDoc de `AsType<T>` declara divergência em voz alta | ✅ |
| CA-4 | `TValueOps` em `ModernSyntax.RTTI.Delphi.pas` com delegação pura | ✅ |
| CA-5 | `TValueOps` em `ModernSyntax.RTTI.FPC.pas` com `IsType(TypeInfo(T))` + `ExtractRawData` + raise via helper não-genérico | ✅ |
| CA-6 | Uma única `resourcestring SModernValueIncompatibleType` no backend FPC | ✅ |
| CA-7 | `GetValue<T>` reescrito em uma linha; bloco `{$IFDEF FPC}` removido | ✅ |
| CA-8 | `TModernRTTIField.GetValue<T>` não tocado | ✅ |
| CA-9 | `AsType<T>` funciona para `string`, `Integer`, `Boolean`, `Double`, `TObject` | ✅ |
| CA-10 | `AsType<T>` funciona para `record` e `enum` | ✅ |
| CA-11 | FPC: tipo diferente levanta `EModernRTTIError` com nome de origem e destino | ✅ |
| CA-12 | 7 cenários compartilhados com `Fail(...)`, zero `Assert`, zero `{$IFDEF}` | ✅ |
| CA-13 | `grep -c "IFDEF" UScenarios.RTTI.pas` = 0 (CA-5 preservado) | ✅ (count=0) |
| CA-14 | FPC runner: 7 published + 1 `published` local para exceção | ✅ |
| CA-15 | Delphi runner: 7 `[Test]`, sem equivalente do teste de exceção FPC | ✅ |
| CA-16 | Teste usa `TModernValue.AsType<T>` sem `{$IFDEF FPC}` no código de teste | ✅ |
| CA-17 | `PTestRTTI.lpr` compila e passa em x86_64 | ✅ (17/0/0) |
| CA-18 | Compilação Delphi confirmada pelo autor | ⚠️ ABERTO — limitação de ambiente (fábrica sem dcc32/DUnitX, SKILL.md:16-27); declarado sem suavizar no implement-report; evidência por analogia forte (6 padrões análogos no repo) |
| CA-19 | Prova de mutação declarada no corpo do PR | ⚠️ ABERTO — substantivamente satisfeito (implement-report: exit=2 sob mutação, revertida); formalização no PR é etapa pós-test |

## Casos extremos exercitados

| Caso | Como foi testado | Resultado |
|------|-----------------|-----------|
| Record (`TPonto`) | `Scenario_ModernValue_AsType_Record` | ✅ |
| Enum middle-value (`clGreen`) | `Scenario_ModernValue_AsType_Enum` — nem primeiro nem último | ✅ |
| Object identity + state | `Scenario_ModernValue_AsType_Object` — mesma referência + Tag=7 | ✅ |
| Double epsilon | `Scenario_ModernValue_AsType_Double` — `SameValue` por Extended→Double | ✅ |
| Tipo diferente FPC | `TestModernValue_AsType_DifferentType_...` — `Pos('TPonto',...)` + `Pos('AnsiString',...)` | ✅ |
| Regressão GetValue<T> (R2) | `TestGetValue_Integer/String/Currency_Roundtrip` via caminho refatorado | ✅ |
| Prova de mutação | Relatada no implement-report: `if False` → exit=2 | Declarada ✅ |

## Decisão de implementação notável

O backend FPC introduziu `class procedure TValueOps.RaiseIncompatible(...)` como
helper não-genérico no mesmo record (declarado na `interface`). Isso desarmou o
trap FPC 3.2.2 "Global Generic template references static symtable" — um método
genérico no `interface` não pode referenciar resourcestrings do `static symtable`
da `implementation` diretamente. A solução está documentada no implement-report
(D-IMPL-1) e nos comentários do backend FPC. Nenhuma decisão do ADR foi alterada.

## Veredicto

**APROVADO.** Todos os CAs verificáveis pela fábrica estão verdes. Os dois itens
abertos (CA-18 e CA-19) são limitações de ambiente e de etapa de pipeline, não
deficiências de implementação.

## Referências

- [esp](pipeline-esp.md) — critérios formais
- [implement-report](pipeline-implement-report.md) — o que foi implementado
- [plan](pipeline-plan.md) — ordem de execução
- [adr](pipeline-adr.md) — decisão e o que foi descartado
